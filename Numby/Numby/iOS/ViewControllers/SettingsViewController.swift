#if os(iOS) || os(visionOS)
import UIKit

class SettingsViewController: UIViewController {

    // MARK: - Properties

    private enum Section: Int, CaseIterable {
        case language
        case appearance
        case currency
        case about

        var title: String {
            switch self {
            case .language: return NSLocalizedString("settings.language.section", comment: "")
            case .appearance: return NSLocalizedString("settings.appearance.section", comment: "")
            case .currency: return NSLocalizedString("settings.currency.section", comment: "")
            case .about: return NSLocalizedString("settings.about.section", comment: "")
            }
        }
    }

    private var lastCurrencyUpdate: Date?
    private var isUpdatingCurrency = false
    private let numbyWrapper = NumbyWrapper()

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
        loadCurrencyUpdateTime()

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

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateTheme()
        }
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
    }

    private func updateCurrencyRates() {
        isUpdatingCurrency = true
        tableView.reloadSections(IndexSet(integer: Section.currency.rawValue), with: .automatic)

        // Use native URLSession for all platforms (works on visionOS)
        numbyWrapper.updateCurrencyRatesNative { [weak self] success in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isUpdatingCurrency = false

                if success {
                    self.lastCurrencyUpdate = Date()
                    UserDefaults.standard.set(Date(), forKey: "lastCurrencyUpdate")
                } else {
                    let alert = UIAlertController(
                        title: NSLocalizedString("alert.updateFailed", comment: ""),
                        message: NSLocalizedString("alert.currencyUpdateError", comment: ""),
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: NSLocalizedString("alert.ok", comment: ""), style: .default))
                    self.present(alert, animated: true)
                }

                self.tableView.reloadSections(IndexSet(integer: Section.currency.rawValue), with: .automatic)
            }
        }
    }

    private func isCurrencyDataStale() -> Bool {
        guard let lastUpdate = lastCurrencyUpdate else { return true }
        let hoursSinceUpdate = Date().timeIntervalSince(lastUpdate) / 3600
        return hoursSinceUpdate > 24
    }

    // MARK: - Theme

    @objc private func themeDidChange() {
        updateTheme()
        tableView.reloadData()
    }

    @objc private func configDidChange() {
        tableView.reloadData()
    }

    private func updateTheme() {
        // Always use dark mode
        overrideUserInterfaceStyle = .dark

        view.backgroundColor = .systemGroupedBackground
        tableView.backgroundColor = .systemGroupedBackground
        tableView.separatorColor = .separator
        tableView.indicatorStyle = .default
        tableView.reloadData()
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
            return 4 // Theme, Font Size, Font, Syntax Highlighting
        case .currency:
            return 2 // Last update, Update button
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
            if indexPath.row == 0 { showThemeSelector() }
            else if indexPath.row == 1 { return } // Font size slider
            else if indexPath.row == 2 { showFontSelector() }
        case .currency:
            if indexPath.row == 1 { updateCurrencyRates() }
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

        switch indexPath.row {
        case 0: // Theme
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath)
            var cellConfig = cell.defaultContentConfiguration()
            cellConfig.image = UIImage(systemName: "paintbrush.fill")
            cellConfig.text = NSLocalizedString("settings.appearance.theme", comment: "")
            cellConfig.secondaryText = Theme.current.name
            cell.contentConfiguration = cellConfig
            cell.accessoryType = .disclosureIndicator
            return cell

        case 1: // Font Size Slider
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
                    Configuration.shared.save()
                    NotificationCenter.default.post(name: NSNotification.Name("ThemeDidChange"), object: nil)
                }
            )
            return cell

        case 2: // Font
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath)
            var cellConfig = cell.defaultContentConfiguration()
            cellConfig.image = UIImage(systemName: "textformat")
            cellConfig.text = NSLocalizedString("settings.appearance.font", comment: "")
            cellConfig.secondaryText = config.fontName ?? "SFMono-Regular"
            cell.contentConfiguration = cellConfig
            cell.accessoryType = .disclosureIndicator
            return cell

        case 3: // Syntax Highlighting Switch
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

        default:
            return UITableViewCell()
        }
    }


    private func currencyCell(for indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath)
        var config = cell.defaultContentConfiguration()

        switch indexPath.row {
        case 0: // Last update timestamp
            config.image = UIImage(systemName: "dollarsign.circle")
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

        case 1: // Update button
            config.image = UIImage(systemName: "arrow.clockwise")
            config.text = isUpdatingCurrency ? NSLocalizedString("settings.currency.updating", comment: "") : NSLocalizedString("settings.currency.update", comment: "")
            config.textProperties.color = .systemBlue
            cell.accessoryType = isUpdatingCurrency ? .none : .disclosureIndicator

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
                self?.tableView.reloadData()
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
            self?.tableView.reloadData()
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
}

// MARK: - Custom Cells

class SliderCell: UITableViewCell {
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let slider = UISlider()
    private var onChange: ((Float) -> Void)?

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

        slider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
        slider.minimumTrackTintColor = .systemBlue
        slider.maximumTrackTintColor = .systemGray4

        let topStack = UIStackView(arrangedSubviews: [iconView, titleLabel, valueLabel])
        topStack.axis = .horizontal
        topStack.spacing = 12
        topStack.alignment = .center

        let mainStack = UIStackView(arrangedSubviews: [topStack, slider])
        mainStack.axis = .vertical
        mainStack.spacing = 8
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(mainStack)

        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 28),
            iconView.heightAnchor.constraint(equalToConstant: 28),

            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 11),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -11)
        ])
    }

    func configure(title: String, value: Float, min: Float, max: Float, icon: String? = nil, onChange: @escaping (Float) -> Void) {
        titleLabel.text = title
        slider.minimumValue = min
        slider.maximumValue = max
        slider.value = value
        self.onChange = onChange

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
