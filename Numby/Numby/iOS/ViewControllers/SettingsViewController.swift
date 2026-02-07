#if os(iOS) || os(visionOS)
import UIKit

class SettingsViewController: UIViewController {

    // MARK: - Properties

    private enum Section: Int, CaseIterable {
        case language
        case appearance
        case numbers
        case currency
        case about

        var title: String {
            switch self {
            case .language: return NSLocalizedString("settings.language.section", comment: "")
            case .appearance: return NSLocalizedString("settings.appearance.section", comment: "")
            case .numbers: return NSLocalizedString("settings.number.section", comment: "")
            case .currency: return NSLocalizedString("settings.currency.section", comment: "")
            case .about: return NSLocalizedString("settings.about.section", comment: "")
            }
        }
    }

    private var lastCurrencyUpdate: Date?
    private var apiRatesDate: String?
    private var isUpdatingCurrency = false
    private var showUpdateSuccess = false
    private let numbyWrapper = NumbyWrapper()
    private var lastConfigSnapshot = Configuration.shared.config

    private enum AppearanceRow: Equatable {
        case theme
        case fontSize
        case font
        case syntaxHighlighting
        case activeLineHighlight
        case activeLineIntensity
        case activeLineIntensityHint
    }

    private enum NumberRow: Equatable {
        case numberFormat
        case maxDecimals
        case maxDecimalsHint
        case preview
    }

    private var appearanceRows: [AppearanceRow] {
        var rows: [AppearanceRow] = [
            .theme,
            .fontSize,
            .font,
            .syntaxHighlighting,
            .activeLineHighlight,
        ]
        if Configuration.shared.config.activeLineHighlight {
            rows.append(.activeLineIntensity)
            rows.append(.activeLineIntensityHint)
        }
        return rows
    }

    private var numberRows: [NumberRow] {
        var rows: [NumberRow] = [
            .numberFormat
        ]
        if Configuration.shared.config.numberFormat == "precision" {
            rows.append(.maxDecimals)
            rows.append(.maxDecimalsHint)
        }
        rows.append(.preview)
        return rows
    }

    // MARK: - UI Components

    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.delegate = self
        table.dataSource = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "SettingCell")
        table.register(SliderCell.self, forCellReuseIdentifier: "SliderCell")
        table.register(SwitchCell.self, forCellReuseIdentifier: "SwitchCell")
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("settings.title", comment: "")
        setupUI()
        setupNavigationBar()
        updateTheme()
        registerForTraitChangesIfAvailable()
        loadCurrencyUpdateTime()
        lastConfigSnapshot = Configuration.shared.config

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(themeDidChange),
            name: NSNotification.Name("ThemeDidChange"),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(configDidChange),
            name: NSNotification.Name("ConfigurationDidChange"),
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(dismissSettings)
        )
    }

    @objc private func dismissSettings() {
        dismiss(animated: true)
    }

    // MARK: - Currency Update

    private func loadCurrencyUpdateTime() {
        if let timestamp = UserDefaults.standard.object(forKey: "lastCurrencyUpdate") as? Date {
            lastCurrencyUpdate = timestamp
        }

        // Load API rates date
        apiRatesDate = numbyWrapper.getApiRatesDate()
    }

    private func updateCurrencyRates() {
        isUpdatingCurrency = true
        UIView.performWithoutAnimation {
            tableView.reloadSections(IndexSet(integer: Section.currency.rawValue), with: .none)
        }

        // Use native URLSession for all platforms (works on visionOS)
        numbyWrapper.updateCurrencyRatesNative { [weak self] success in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isUpdatingCurrency = false

                if success {
                    // Show success indicator briefly
                    self.showUpdateSuccess = true
                    // Hide success indicator after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.showUpdateSuccess = false
                        UIView.performWithoutAnimation {
                            self.tableView.reloadSections(IndexSet(integer: Section.currency.rawValue), with: .none)
                        }
                    }

                    self.lastCurrencyUpdate = Date()
                    UserDefaults.standard.set(Date(), forKey: "lastCurrencyUpdate")

                    // Update API rates date
                    self.apiRatesDate = self.numbyWrapper.getApiRatesDate()
                } else {
                    let alert = UIAlertController(
                        title: NSLocalizedString("alert.updateFailed", comment: ""),
                        message: NSLocalizedString("alert.currencyUpdateError", comment: ""),
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: NSLocalizedString("alert.ok", comment: ""), style: .default))
                    self.present(alert, animated: true)
                }

                UIView.performWithoutAnimation {
                    self.tableView.reloadSections(IndexSet(integer: Section.currency.rawValue), with: .none)
                }
            }
        }
    }

    private func isCurrencyDataStale() -> Bool {
        return numbyWrapper.areCurrencyRatesStale()
    }

    // MARK: - Theme

    @objc private func themeDidChange() {
        updateTheme()
    }

    @objc private func configDidChange() {
        let config = Configuration.shared.config
        let previous = lastConfigSnapshot
        lastConfigSnapshot = config

        if config.numberFormat != previous.numberFormat || config.numberMaxDecimals != previous.numberMaxDecimals {
            _ = numbyWrapper.setNumberFormat(
                config.numberFormat,
                maxDecimals: config.numberMaxDecimals
            )
        }

        var sectionsToReload = IndexSet()
        var rowsToReload: [IndexPath] = []

        if config.numberFormat != previous.numberFormat {
            sectionsToReload.insert(Section.numbers.rawValue)
        } else if config.numberMaxDecimals != previous.numberMaxDecimals {
            if let previewIndex = numberRows.firstIndex(of: .preview) {
                rowsToReload.append(IndexPath(row: previewIndex, section: Section.numbers.rawValue))
            }
        }

        if config.activeLineHighlight != previous.activeLineHighlight {
            sectionsToReload.insert(Section.appearance.rawValue)
        } else if config.activeLineHighlightIntensity != previous.activeLineHighlightIntensity {
            if let intensityIndex = appearanceRows.firstIndex(of: .activeLineIntensity) {
                rowsToReload.append(IndexPath(row: intensityIndex, section: Section.appearance.rawValue))
            }
        }

        if !sectionsToReload.isEmpty {
            UIView.performWithoutAnimation {
                tableView.reloadSections(sectionsToReload, with: .none)
            }
            return
        }

        if !rowsToReload.isEmpty {
            UIView.performWithoutAnimation {
                tableView.reloadRows(at: rowsToReload, with: .none)
            }
        }
    }

    private func updateTheme() {
        // Always use dark mode
        overrideUserInterfaceStyle = .dark

        view.backgroundColor = .systemGroupedBackground
        tableView.backgroundColor = .systemGroupedBackground
        tableView.separatorColor = .separator
        tableView.indicatorStyle = .default
    }

    private func registerForTraitChangesIfAvailable() {
        if #available(iOS 17.0, visionOS 1.0, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self]) { [weak self] (_: SettingsViewController, _: UITraitCollection) in
                self?.updateTheme()
            }
        }
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension SettingsViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section) else { return 0 }

        switch section {
        case .language:
            return 1 // Locale picker
        case .appearance:
            return appearanceRows.count
        case .numbers:
            return numberRows.count
        case .currency:
            return 4 // API date, Last update, Update button, API info
        case .about:
            return 2 // Version, GitHub
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Section(rawValue: section)?.title
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = Section(rawValue: indexPath.section) else {
            return tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath)
        }

        switch section {
        case .language:
            return languageCell(for: indexPath)
        case .appearance:
            return appearanceCell(for: indexPath)
        case .numbers:
            return numberCell(for: indexPath)
        case .currency:
            return currencyCell(for: indexPath)
        case .about:
            return aboutCell(for: indexPath)
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let section = Section(rawValue: indexPath.section) else { return }

        switch section {
        case .language:
            if indexPath.row == 0 { openSystemSettings() }
        case .appearance:
            let row = appearanceRows[indexPath.row]
            switch row {
            case .theme:
                showThemeSelector()
            case .font:
                showFontSelector()
            case .fontSize, .syntaxHighlighting, .activeLineHighlight, .activeLineIntensity, .activeLineIntensityHint:
                break
            }
        case .numbers:
            let row = numberRows[indexPath.row]
            switch row {
            case .numberFormat:
                showNumberFormatSelector()
            case .maxDecimals, .maxDecimalsHint, .preview:
                break
            }
        case .currency:
            if indexPath.row == 2 { updateCurrencyRates() }
        case .about:
            if indexPath.row == 1 {
                if let url = URL(string: "https://github.com/vivy-company/numby") {
                    UIApplication.shared.open(url)
                }
            }
        }
    }

    // MARK: - Cell Builders

    private func languageCell(for indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath)
        var config = cell.defaultContentConfiguration()
        config.image = UIImage(systemName: "globe")
        config.text = NSLocalizedString("settings.language.picker", comment: "")
        config.secondaryText = NSLocalizedString("settings.language.openSettings", comment: "")
        cell.contentConfiguration = config
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    private func appearanceCell(for indexPath: IndexPath) -> UITableViewCell {
        let config = Configuration.shared.config
        let row = appearanceRows[indexPath.row]

        switch row {
        case .theme:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath)
            var cellConfig = cell.defaultContentConfiguration()
            cellConfig.image = UIImage(systemName: "paintbrush.fill")
            cellConfig.text = NSLocalizedString("settings.appearance.theme", comment: "")
            cellConfig.secondaryText = Theme.current.name
            cell.contentConfiguration = cellConfig
            cell.accessoryType = .disclosureIndicator
            return cell

        case .fontSize:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "SliderCell", for: indexPath) as? SliderCell else {
                return UITableViewCell()
            }
            cell.configure(
                title: NSLocalizedString("settings.appearance.fontSize", comment: ""),
                value: Float(config.fontSize),
                min: 10,
                max: 24,
                icon: "textformat.size",
                onChange: { value in
                    Configuration.shared.config.fontSize = Double(value)
                },
                onCommit: { _ in
                    Configuration.shared.save()
                    NotificationCenter.default.post(name: NSNotification.Name("ThemeDidChange"), object: nil)
                }
            )
            return cell

        case .font:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath)
            var cellConfig = cell.defaultContentConfiguration()
            cellConfig.image = UIImage(systemName: "textformat")
            cellConfig.text = NSLocalizedString("settings.appearance.font", comment: "")
            cellConfig.secondaryText = config.fontName ?? "SFMono-Regular"
            cell.contentConfiguration = cellConfig
            cell.accessoryType = .disclosureIndicator
            return cell

        case .syntaxHighlighting:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath) as? SwitchCell else {
                return UITableViewCell()
            }
            cell.configure(
                title: NSLocalizedString("settings.appearance.syntaxHighlighting", comment: ""),
                isOn: config.syntaxHighlighting,
                icon: "highlighter",
                onChange: { isOn in
                    Configuration.shared.config.syntaxHighlighting = isOn
                    Configuration.shared.save()
                    NotificationCenter.default.post(name: NSNotification.Name("ThemeDidChange"), object: nil)
                }
            )
            return cell

        case .activeLineHighlight:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath) as? SwitchCell else {
                return UITableViewCell()
            }
            cell.configure(
                title: NSLocalizedString("settings.appearance.activeLineHighlight", comment: ""),
                isOn: config.activeLineHighlight,
                icon: "line.horizontal.3",
                onChange: { isOn in
                    Configuration.shared.config.activeLineHighlight = isOn
                    Configuration.shared.save()
                    UIView.performWithoutAnimation {
                        self.tableView.reloadSections(IndexSet(integer: Section.appearance.rawValue), with: .none)
                    }
                }
            )
            return cell

        case .activeLineIntensity:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "SliderCell", for: indexPath) as? SliderCell else {
                return UITableViewCell()
            }
            cell.configure(
                title: NSLocalizedString("settings.appearance.activeLineIntensity", comment: ""),
                value: Float(config.activeLineHighlightIntensity * 100),
                min: 2,
                max: 20,
                icon: "circle.lefthalf.filled",
                onChange: { value in
                    Configuration.shared.config.activeLineHighlightIntensity = Double(value) / 100.0
                    NotificationCenter.default.post(name: NSNotification.Name("ActiveLineHighlightDidChange"), object: nil)
                },
                onCommit: { _ in
                    Configuration.shared.save()
                }
            )
            return cell

        case .activeLineIntensityHint:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath)
            var cellConfig = cell.defaultContentConfiguration()
            cellConfig.text = NSLocalizedString("settings.appearance.activeLineIntensityHint", comment: "")
            cellConfig.textProperties.color = .secondaryLabel
            cell.contentConfiguration = cellConfig
            cell.accessoryType = .none
            cell.selectionStyle = .none
            return cell
        }
    }

    private func numberCell(for indexPath: IndexPath) -> UITableViewCell {
        let config = Configuration.shared.config
        let row = numberRows[indexPath.row]

        switch row {
        case .numberFormat:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath)
            var cellConfig = cell.defaultContentConfiguration()
            cellConfig.image = UIImage(systemName: "number")
            cellConfig.text = NSLocalizedString("settings.number.format", comment: "")
            let formatLabel = config.numberFormat == "precision"
                ? NSLocalizedString("settings.number.format.precision", comment: "")
                : NSLocalizedString("settings.number.format.pretty", comment: "")
            cellConfig.secondaryText = formatLabel
            cell.contentConfiguration = cellConfig
            cell.accessoryType = .disclosureIndicator
            return cell

        case .maxDecimals:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "SliderCell", for: indexPath) as? SliderCell else {
                return UITableViewCell()
            }
            cell.configure(
                title: NSLocalizedString("settings.number.maxDecimals", comment: ""),
                value: Float(config.numberMaxDecimals),
                min: 0,
                max: 15,
                icon: "number.circle",
                onChange: { value in
                    Configuration.shared.config.numberMaxDecimals = Int(value)
                    _ = self.numbyWrapper.setNumberFormat(
                        Configuration.shared.config.numberFormat,
                        maxDecimals: Configuration.shared.config.numberMaxDecimals
                    )
                    self.updateNumberPreviewCell()
                },
                onCommit: { _ in
                    Configuration.shared.save()
                }
            )
            return cell

        case .maxDecimalsHint:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath)
            var cellConfig = cell.defaultContentConfiguration()
            cellConfig.text = NSLocalizedString("settings.number.maxDecimalsHint", comment: "")
            cellConfig.textProperties.color = .secondaryLabel
            cell.contentConfiguration = cellConfig
            cell.accessoryType = .none
            cell.selectionStyle = .none
            return cell

        case .preview:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath)
            var cellConfig = cell.defaultContentConfiguration()
            cellConfig.image = UIImage(systemName: "eye")
            cellConfig.text = NSLocalizedString("settings.number.preview", comment: "")
            let previewExpression = config.numberFormat == "precision" ? "1/3" : "1234567.89"
            let preview = numbyWrapper.evaluate(previewExpression).formatted ?? "—"
            cellConfig.secondaryText = preview
            cell.contentConfiguration = cellConfig
            cell.accessoryType = .none
            cell.selectionStyle = .none
            return cell
        }
    }

    private func updateNumberPreviewCell() {
        guard let previewIndex = numberRows.firstIndex(of: .preview) else { return }
        let indexPath = IndexPath(row: previewIndex, section: Section.numbers.rawValue)
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        var cellConfig = cell.defaultContentConfiguration()
        cellConfig.image = UIImage(systemName: "eye")
        cellConfig.text = NSLocalizedString("settings.number.preview", comment: "")
        let previewExpression = Configuration.shared.config.numberFormat == "precision" ? "1/3" : "1234567.89"
        let preview = numbyWrapper.evaluate(previewExpression).formatted ?? "—"
        cellConfig.secondaryText = preview
        cell.contentConfiguration = cellConfig
        cell.accessoryType = .none
        cell.selectionStyle = .none
    }


    private func currencyCell(for indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath)
        var config = cell.defaultContentConfiguration()

        switch indexPath.row {
        case 0: // API Rates Date
            config.image = UIImage(systemName: "calendar.circle")
            config.text = NSLocalizedString("settings.currency.apiDate", comment: "")
            if let apiDate = apiRatesDate {
                config.secondaryText = apiDate
                config.secondaryTextProperties.color = .secondaryLabel
            } else {
                config.secondaryText = NSLocalizedString("settings.currency.unknown", comment: "")
                config.secondaryTextProperties.color = .secondaryLabel
            }
            cell.accessoryType = .none

        case 1: // Last update timestamp
            config.image = UIImage(systemName: "clock.circle")
            config.text = NSLocalizedString("settings.currency.lastUpdated", comment: "")
            if let lastUpdate = lastCurrencyUpdate {
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                formatter.timeStyle = .short
                config.secondaryText = formatter.string(from: lastUpdate)

                if isCurrencyDataStale() {
                    config.secondaryTextProperties.color = .systemRed
                }
            } else {
                config.secondaryText = NSLocalizedString("settings.currency.never", comment: "")
                config.secondaryTextProperties.color = .systemRed
            }
            cell.accessoryType = .none

        case 2: // Update button
            config.image = UIImage(systemName: "arrow.clockwise")
            if isUpdatingCurrency {
                config.text = NSLocalizedString("settings.currency.updating", comment: "")
            } else if showUpdateSuccess {
                config.text = NSLocalizedString("settings.currency.updated", comment: "")
                config.textProperties.color = .systemGreen
            } else {
                config.text = NSLocalizedString("settings.currency.update", comment: "")
                config.textProperties.color = .systemBlue
            }
            cell.accessoryType = (isUpdatingCurrency || showUpdateSuccess) ? .none : .disclosureIndicator

        case 3: // API Info
            config.image = UIImage(systemName: "info.circle")
            config.text = NSLocalizedString("settings.currency.apiInfo", comment: "")
            config.textProperties.font = .systemFont(ofSize: 12)
            config.textProperties.color = .secondaryLabel
            config.textProperties.numberOfLines = 0
            cell.accessoryType = .none

        default:
            break
        }

        cell.contentConfiguration = config
        return cell
    }

    private func aboutCell(for indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath)
        var config = cell.defaultContentConfiguration()

        switch indexPath.row {
        case 0: // Version
            config.image = UIImage(systemName: "info.circle")
            config.text = NSLocalizedString("settings.about.version", comment: "")
            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                config.secondaryText = version
            }

        case 1: // GitHub
            config.image = UIImage(systemName: "link")
            config.text = NSLocalizedString("settings.about.github", comment: "")
            config.secondaryText = "github.com/vivy-company/numby"
            cell.accessoryType = .disclosureIndicator

        default:
            break
        }

        cell.contentConfiguration = config
        return cell
    }

    // MARK: - Actions

    private func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private func showThemeSelector() {
        let themeNames = Theme.allThemes.map { $0.name }

        let picker = SearchablePickerViewController(
            title: NSLocalizedString("settings.theme.select", comment: ""),
            items: themeNames,
            selectedItem: Theme.current.name
        ) { [weak self] selectedThemeName in
            if let theme = Theme.allThemes.first(where: { $0.name == selectedThemeName }) {
                Theme.current = theme
                if let self {
                    UIView.performWithoutAnimation {
                        self.tableView.reloadSections(IndexSet(integer: Section.appearance.rawValue), with: .none)
                    }
                }
                NotificationCenter.default.post(name: NSNotification.Name("ThemeDidChange"), object: nil)
            }
        }

        let nav = UINavigationController(rootViewController: picker)
        nav.overrideUserInterfaceStyle = .dark
        #if !os(visionOS)
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.custom { _ in 500 }]
            sheet.prefersGrabberVisible = true
        }
        #endif
        present(nav, animated: true)
    }

    private func showFontSelector() {
        // Get all available monospaced system fonts
        let fontFamilies = UIFont.familyNames.sorted()
        var monospacedFonts: [String] = []

        for family in fontFamilies {
            let fontNames = UIFont.fontNames(forFamilyName: family)
            for fontName in fontNames {
                // Check if font is monospaced
                if let font = UIFont(name: fontName, size: 12.0) {
                    let attributes: [NSAttributedString.Key: Any] = [.font: font]
                    let iWidth = ("i" as NSString).size(withAttributes: attributes).width
                    let mWidth = ("m" as NSString).size(withAttributes: attributes).width
                    if abs(iWidth - mWidth) < 0.1 {
                        monospacedFonts.append(fontName)
                    }
                }
            }
        }

        // Fallback to common fonts if none found
        if monospacedFonts.isEmpty {
            monospacedFonts = ["Menlo-Regular", "Courier", "Monaco"]
        }

        let picker = SearchablePickerViewController(
            title: NSLocalizedString("settings.font.select", comment: ""),
            items: monospacedFonts.sorted(),
            selectedItem: Configuration.shared.config.fontName
        ) { [weak self] selectedFont in
            Configuration.shared.config.fontName = selectedFont
            Configuration.shared.save()
            NotificationCenter.default.post(name: NSNotification.Name("ThemeDidChange"), object: nil)
            if let self {
                UIView.performWithoutAnimation {
                    self.tableView.reloadSections(IndexSet(integer: Section.appearance.rawValue), with: .none)
                }
            }
        }

        let nav = UINavigationController(rootViewController: picker)
        nav.overrideUserInterfaceStyle = .dark
        #if !os(visionOS)
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.custom { _ in 500 }]
            sheet.prefersGrabberVisible = true
        }
        #endif
        present(nav, animated: true)
    }

    private func showNumberFormatSelector() {
        let title = NSLocalizedString("settings.number.format", comment: "")
        let prettyTitle = NSLocalizedString("settings.number.format.pretty", comment: "")
        let precisionTitle = NSLocalizedString("settings.number.format.precision", comment: "")

        let alert = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        let applyFormat: (String) -> Void = { [weak self] format in
            Configuration.shared.config.numberFormat = format
            Configuration.shared.save()
            _ = self?.numbyWrapper.setNumberFormat(
                format,
                maxDecimals: Configuration.shared.config.numberMaxDecimals
            )
        }

        alert.addAction(UIAlertAction(title: prettyTitle, style: .default) { _ in
            applyFormat("pretty")
        })
        alert.addAction(UIAlertAction(title: precisionTitle, style: .default) { _ in
            applyFormat("precision")
        })
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("alert.cancel", comment: ""),
            style: .cancel
        ))

        if let popover = alert.popoverPresentationController,
           let rowIndex = numberRows.firstIndex(of: .numberFormat),
           let cell = tableView.cellForRow(
            at: IndexPath(row: rowIndex, section: Section.numbers.rawValue)
           ) {
            popover.sourceView = cell
            popover.sourceRect = cell.bounds
        } else if let popover = alert.popoverPresentationController {
            popover.sourceView = tableView
            popover.sourceRect = tableView.bounds
        }

        present(alert, animated: true)
    }
}

// MARK: - Custom Cells

class SliderCell: UITableViewCell {
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let slider = UISlider()
    private var onChange: ((Float) -> Void)?
    private var onCommit: ((Float) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.tintColor = .systemBlue

        titleLabel.font = .systemFont(ofSize: 17)
        titleLabel.textColor = .label
        valueLabel.font = .systemFont(ofSize: 17)
        valueLabel.textColor = .secondaryLabel
        valueLabel.textAlignment = .right
        valueLabel.setContentHuggingPriority(.required, for: .horizontal)
        valueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        slider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
        slider.addTarget(self, action: #selector(sliderEditingEnded), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        slider.minimumTrackTintColor = .systemBlue
        slider.maximumTrackTintColor = .systemGray4
        slider.translatesAutoresizingMaskIntoConstraints = false

        let topStack = UIStackView(arrangedSubviews: [iconView, titleLabel, valueLabel])
        topStack.axis = .horizontal
        topStack.spacing = 12
        topStack.alignment = .center
        topStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(topStack)
        contentView.addSubview(slider)

        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 28),
            iconView.heightAnchor.constraint(equalToConstant: 28),

            topStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 11),
            topStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            topStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            slider.topAnchor.constraint(equalTo: topStack.bottomAnchor, constant: 8),
            slider.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            slider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            slider.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -11)
        ])
    }

    func configure(
        title: String,
        value: Float,
        min: Float,
        max: Float,
        icon: String? = nil,
        onChange: @escaping (Float) -> Void,
        onCommit: ((Float) -> Void)? = nil
    ) {
        titleLabel.text = title
        slider.minimumValue = min
        slider.maximumValue = max
        slider.value = value
        self.onChange = onChange
        self.onCommit = onCommit

        if let icon = icon {
            iconView.image = UIImage(systemName: icon)
            iconView.isHidden = false
        } else {
            iconView.isHidden = true
        }

        updateValueLabel()
    }

    @objc private func sliderChanged() {
        updateValueLabel()
        onChange?(slider.value)
    }

    @objc private func sliderEditingEnded() {
        onCommit?(slider.value)
    }

    private func updateValueLabel() {
        valueLabel.text = String(format: "%.0f", slider.value)
    }
}

class SwitchCell: UITableViewCell {
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let toggle = UISwitch()
    private var onChange: ((Bool) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.tintColor = .systemBlue

        titleLabel.font = .systemFont(ofSize: 17)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        toggle.addTarget(self, action: #selector(toggleChanged), for: .valueChanged)
        toggle.translatesAutoresizingMaskIntoConstraints = false
        toggle.onTintColor = .systemBlue
        toggle.thumbTintColor = .white

        contentView.addSubview(iconView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(toggle)

        NSLayoutConstraint.activate([
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),

            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 28),
            iconView.heightAnchor.constraint(equalToConstant: 28),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 11),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -11),

            toggle.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            toggle.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    func configure(title: String, isOn: Bool, icon: String? = nil, onChange: @escaping (Bool) -> Void) {
        titleLabel.text = title
        toggle.isOn = isOn
        self.onChange = onChange

        if let icon = icon {
            iconView.image = UIImage(systemName: icon)
            iconView.isHidden = false
        } else {
            iconView.isHidden = true
        }
    }

    @objc private func toggleChanged() {
        onChange?(toggle.isOn)
    }
}
#endif
