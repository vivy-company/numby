#if os(iOS) || os(visionOS)
import UIKit

class CalculatorViewController: UIViewController {

    #if !os(visionOS)
    // MARK: - Accessory Bar View

    private class AccessoryBarView: UIView {
        override var intrinsicContentSize: CGSize {
            CGSize(width: UIView.noIntrinsicMetric, height: 120)
        }
    }
    #endif

    // MARK: - Properties

    private var numbyWrapper = NumbyWrapper()
    private var results: [String] = []
    private var activeLineIndex: Int = 0
    private var activeLineGroupStart: Int = 0
    private var activeLineGroupEnd: Int = 0
    #if !os(visionOS)
    private var accessoryButtons: [UIButton] = []
    #endif

    private var autosaveWorkItem: DispatchWorkItem?
    private var lastAutosaveSignature: String = ""
    private var lastHistorySignature: String = ""
    private var lastHistorySnapshotDate: Date = .distantPast
    private let autosaveDebounce: TimeInterval = 0.8
    private let historySnapshotInterval: TimeInterval = 120
    private let autosaveKey = "numby.autosave.phone"

    private enum HighlightKind: UInt8 {
        case text = 0
        case number = 1
        case `operator` = 2
        case keyword = 3
        case function = 4
        case constant = 5
        case variable = 6
        case variableUsage = 7
        case assignment = 8
        case currency = 9
        case unit = 10
        case comment = 11
        case scale = 12
        case datetime = 13
    }

    // Reference to tab container (iPad only)
    weak var tabContainer: iPadTabContainerViewController?

    // Split view support (iPad)
    var leafId: SplitLeafID?
    weak var splitContainerDelegate: iPadCalculatorPaneDelegate?

    // MARK: - Tab State

    func saveState(to tab: CalculatorTab) {
        tab.text = textView.text ?? ""
        tab.results = results
    }

    func restoreState(from tab: CalculatorTab) {
        numbyWrapper = tab.numbyWrapper
        textView.text = tab.text
        results = tab.results
        scheduleHighlighting(force: true)
        updateResultsOverlay()
        updateActiveLine()
    }

    // MARK: - Split View State

    func saveToInstance(_ instance: iPadCalculatorInstance) {
        instance.inputText = textView.text ?? ""
        instance.results = results
        instance.cursorPosition = textView.selectedRange.location
    }

    func restoreFromInstance(_ instance: iPadCalculatorInstance) {
        numbyWrapper = instance.numbyWrapper
        textView.text = instance.inputText
        results = instance.results
        scheduleHighlighting(force: true)
        updateResultsOverlay()
        if instance.cursorPosition <= (textView.text?.count ?? 0) {
            textView.selectedRange = NSRange(location: instance.cursorPosition, length: 0)
        }
        updateActiveLine()
    }

    func focus() {
        textView.becomeFirstResponder()
    }

    // MARK: - UI Components

    private lazy var textView: ActiveLineTextView = {
        let tv = ActiveLineTextView()
        tv.isEditable = true
        tv.isScrollEnabled = true
        tv.alwaysBounceVertical = true
        tv.autocorrectionType = .no
        tv.autocapitalizationType = .none
        tv.smartQuotesType = .no
        tv.smartDashesType = .no
        tv.spellCheckingType = .no
        // Use asciiCapable to disable predictive text bar (iOS keyboard candidate generation causes lag)
        tv.keyboardType = .asciiCapable
        // Explicitly disable inline predictions (iOS 17+)
        if #available(iOS 17.0, *) {
            tv.inlinePredictionType = .no
        }
        tv.delegate = self
        tv.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private lazy var resultsOverlay: ResultsOverlayView = {
        let overlay = ResultsOverlayView()
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.backgroundColor = .clear
        overlay.isOpaque = false
        overlay.isUserInteractionEnabled = false
        return overlay
    }()

    #if !os(visionOS)
    private lazy var inputAccessoryBar: UIView = {
        let barHeight: CGFloat = 120
        let rowHeight: CGFloat = 32
        let buttonSpacing: CGFloat = 6
        let rowSpacing: CGFloat = 4
        let padding: CGFloat = 8

        let container = AccessoryBarView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: barHeight))
        container.autoresizingMask = [.flexibleWidth]

        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: barHeight))
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.addSubview(scrollView)

        // Row 1: Units + Currencies (top)
        let row1: [(String, String)] = [
            ("USD", "USD"), ("EUR", "EUR"), ("GBP", "GBP"), ("JPY", "JPY"),
            ("CNY", "CNY"), ("RUB", "RUB"), ("BYN", "BYN"),
            ("km", "km"), ("m", "m"), ("cm", "cm"), ("mi", "mi"),
            ("kg", "kg"), ("g", "g"), ("lb", "lb"), ("oz", "oz")
        ]

        // Row 2: Operators + Functions (middle)
        let row2: [(String, String)] = [
            ("+", "+"), ("−", "-"), ("×", "*"), ("÷", "/"), ("=", "="),
            ("^", "^"), ("%", "%"),
            ("sqrt", "sqrt("), ("sin", "sin("), ("cos", "cos("),
            ("tan", "tan("), ("ln", "ln("), ("log", "log(")
        ]

        // Row 3: Numbers (bottom, closest to keyboard)
        let row3: [(String, String)] = [
            ("1", "1"), ("2", "2"), ("3", "3"), ("4", "4"), ("5", "5"),
            ("6", "6"), ("7", "7"), ("8", "8"), ("9", "9"), ("0", "0"),
            (".", "."), ("(", "("), (")", ")")
        ]

        let rows = [row1, row2, row3]
        var maxWidth: CGFloat = 0

        for (rowIndex, rowData) in rows.enumerated() {
            var xOffset: CGFloat = padding
            let yOffset = padding + CGFloat(rowIndex) * (rowHeight + rowSpacing)

            for (title, insert) in rowData {
                let btn = UIButton(type: .system)
                btn.setTitle(title, for: .normal)
                btn.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
                btn.accessibilityIdentifier = insert
                btn.addTarget(self, action: #selector(accessoryButtonTapped(_:)), for: .touchUpInside)
                btn.layer.cornerRadius = 6

                let width: CGFloat = title.count > 2 ? 44 : 36
                btn.frame = CGRect(x: xOffset, y: yOffset, width: width, height: rowHeight)

                scrollView.addSubview(btn)
                accessoryButtons.append(btn)
                xOffset += width + buttonSpacing
            }
            maxWidth = max(maxWidth, xOffset)
        }

        scrollView.contentSize = CGSize(width: maxWidth, height: barHeight)
        return container
    }()

    @objc private func accessoryButtonTapped(_ sender: UIButton) {
        guard let text = sender.accessibilityIdentifier else { return }
        textView.insertText(text)
    }
    #endif

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateTheme()
        applyActiveLineAppearance()
        updateActiveLine()

        title = "Numby"

        // Defer navigation items setup to avoid constraint warnings
        DispatchQueue.main.async { [weak self] in
            self?.setupNavigationItems()
        }

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: NSNotification.Name("ThemeDidChange"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(configDidChange), name: NSNotification.Name("ConfigurationDidChange"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(activeLineHighlightDidChange), name: NSNotification.Name("ActiveLineHighlightDidChange"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loadHistoryEntry(_:)), name: NSNotification.Name("LoadHistoryEntry"), object: nil)

        applyNumberFormat()
        if UIDevice.current.userInterfaceIdiom == .phone {
            restoreAutosavedStateIfAvailable()
        }
    }

    private func setupNavigationItems() {
        let settingsButton = UIBarButtonItem(image: UIImage(systemName: "gear"), style: .plain, target: self, action: #selector(openSettings))
        let historyButton = UIBarButtonItem(image: UIImage(systemName: "clock"), style: .plain, target: self, action: #selector(openHistory))
        let newButton = UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(newCalculation))
        let shareButton = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"), style: .plain, target: self, action: #selector(shareResult))

        // Set explicit widths to avoid constraint conflicts
        [settingsButton, historyButton, newButton, shareButton].forEach { $0.width = 44 }

        navigationItem.leftBarButtonItems = [settingsButton, historyButton]
        navigationItem.rightBarButtonItems = [newButton, shareButton]
    }

    private var hasAppearedOnce = false

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !hasAppearedOnce {
            hasAppearedOnce = true
            // Only auto-focus if not in split view mode (leafId is set for split view panes)
            // Split view manages focus explicitly via focusCalculator()
            if leafId == nil {
                // Defer keyboard focus to avoid snapshotting warning
                DispatchQueue.main.async { [weak self] in
                    self?.textView.becomeFirstResponder()
                }
            }
        }
    }

    // MARK: - Keyboard Shortcuts (Undo/Redo)

    override var keyCommands: [UIKeyCommand]? {
        [
            UIKeyCommand(
                title: NSLocalizedString("menu.undo", comment: ""),
                action: #selector(handleUndo),
                input: "Z",
                modifierFlags: .command
            ),
            UIKeyCommand(
                title: NSLocalizedString("menu.redo", comment: ""),
                action: #selector(handleRedo),
                input: "Z",
                modifierFlags: [.command, .shift]
            ),
        ]
    }

    @objc private func handleUndo() {
        textView.undoManager?.undo()
    }

    @objc private func handleRedo() {
        textView.undoManager?.redo()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground
        view.addSubview(textView)
        view.addSubview(resultsOverlay)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            resultsOverlay.topAnchor.constraint(equalTo: textView.topAnchor),
            resultsOverlay.leadingAnchor.constraint(equalTo: textView.leadingAnchor),
            resultsOverlay.trailingAnchor.constraint(equalTo: textView.trailingAnchor),
            resultsOverlay.bottomAnchor.constraint(equalTo: textView.bottomAnchor)
        ])

        #if !os(visionOS)
        // Only set accessory bar on iPhone - iPad users typically use physical keyboards
        if UIDevice.current.userInterfaceIdiom == .phone {
            textView.inputAccessoryView = inputAccessoryBar
        }
        #endif

        // Add tap gesture to track focus in split view
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(textViewTapped))
        tapGesture.delegate = self
        textView.addGestureRecognizer(tapGesture)
    }

    @objc private func textViewTapped() {
        // Notify split container that this pane is now focused
        if let leafId = leafId {
            splitContainerDelegate?.paneTapped(leafId: leafId)
        }
    }

    // MARK: - Keyboard

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardFrame = frame.cgRectValue

        #if !os(visionOS)
        // On iPad, show accessory bar only when software keyboard is visible (height > 300)
        if UIDevice.current.userInterfaceIdiom == .pad {
            let hasSoftwareKeyboard = keyboardFrame.height > 300
            if hasSoftwareKeyboard && textView.inputAccessoryView == nil {
                textView.inputAccessoryView = inputAccessoryBar
                textView.reloadInputViews()
            } else if !hasSoftwareKeyboard && textView.inputAccessoryView != nil {
                textView.inputAccessoryView = nil
                textView.reloadInputViews()
            }
        }
        #endif

        let height = keyboardFrame.height - view.safeAreaInsets.bottom

        textView.contentInset.bottom = max(0, height)
        textView.verticalScrollIndicatorInsets.bottom = max(0, height)
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        textView.contentInset = .zero
        textView.verticalScrollIndicatorInsets = .zero
    }

    // MARK: - Debouncing

    private var evalWorkItem: DispatchWorkItem?
    private let evalQueue = DispatchQueue(label: "numby.eval", qos: .userInitiated)
    private let evalIDQueue = DispatchQueue(label: "numby.eval.id", qos: .userInitiated)
    private var _currentEvalID: Int = 0

    // Thread-safe eval ID access to avoid races between main and background queues
    private var currentEvalID: Int {
        evalIDQueue.sync { _currentEvalID }
    }

    private func nextEvalID() -> Int {
        evalIDQueue.sync {
            _currentEvalID += 1
            return _currentEvalID
        }
    }

    private func scheduleEvaluation() {
        evalWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.evaluate()
        }
        evalWorkItem = work
        // Increased debounce to 250ms
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: work)
    }

    private func evaluate() {
        let text = textView.text ?? ""
        let lines = text.components(separatedBy: .newlines)
        let evalID = nextEvalID()
        let lineStarts = lineStartUTF16Offsets(for: text)

        evalQueue.async { [weak self] in
            guard let self = self else { return }
            guard evalID == self.currentEvalID else { return }

            var newResults: [String] = Array(repeating: "", count: lines.count)
            var index = 0
            while index < lines.count {
                guard evalID == self.currentEvalID else { return }

                let cursor = index < lineStarts.count ? lineStarts[index] : text.utf16.count
                if let group = self.numbyWrapper.groupExpression(for: text, cursorUTF16: cursor) {
                    let start = max(0, min(group.start, lines.count - 1))
                    let end = max(start, min(group.end, lines.count - 1))

                    if start > index {
                        index += 1
                        continue
                    }

                    let expr = group.expr.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !expr.isEmpty {
                        let result = self.numbyWrapper.evaluate(expr).formatted?
                            .replacingOccurrences(of: "\n", with: "  ") ?? ""
                        if end < newResults.count {
                            newResults[end] = result
                        }
                    }

                    index = end + 1
                } else {
                    index += 1
                }
            }

            // Skip updating if stale
            guard evalID == self.currentEvalID else { return }

            DispatchQueue.main.async {
                guard evalID == self.currentEvalID else { return }
                self.results = newResults
                self.updateResultsOverlay()
            }
        }
    }

    private func updateResultsOverlay() {
        let font = textView.font ?? .monospacedSystemFont(ofSize: 16, weight: .regular)
        let highlightColor = activeLineHighlightColor()
        resultsOverlay.update(
            results: results,
            font: font,
            textColor: Theme.current.syntaxColor(for: .results),
            textView: textView,
            activeLineIndex: activeLineIndex,
            activeGroupStart: activeLineGroupStart,
            activeGroupEnd: activeLineGroupEnd,
            activeLineHighlightColor: highlightColor,
            activeLineHighlightEnabled: Configuration.shared.config.activeLineHighlight
        )
    }

    private func applyActiveLineAppearance() {
        let highlightColor = activeLineHighlightColor()
        textView.activeLineHighlightColor = highlightColor
        textView.isActiveLineHighlightEnabled = Configuration.shared.config.activeLineHighlight
        updateResultsOverlay()
    }

    private func updateActiveLine() {
        let text = textView.text ?? ""
        let cursor = textView.selectedRange.location
        activeLineIndex = lineIndex(for: text, cursorPosition: cursor)
        if let bounds = numbyWrapper.groupBounds(for: text, cursorUTF16: cursor) {
            activeLineGroupStart = bounds.start
            activeLineGroupEnd = bounds.end
        } else {
            activeLineGroupStart = activeLineIndex
            activeLineGroupEnd = activeLineIndex
        }
        textView.activeLineIndex = activeLineIndex
        textView.activeLineGroupStart = activeLineGroupStart
        textView.activeLineGroupEnd = activeLineGroupEnd
        updateResultsOverlay()
    }

    private func lineIndex(for text: String, cursorPosition: Int) -> Int {
        let utf16Count = text.utf16.count
        let clamped = max(0, min(cursorPosition, utf16Count))
        var lineIndex = 0
        var idx = 0
        for unit in text.utf16 {
            if idx >= clamped { break }
            if unit == 10 { lineIndex += 1 }
            idx += 1
        }
        return lineIndex
    }

    private func activeLineHighlightColor() -> UIColor? {
        let config = Configuration.shared.config
        guard config.activeLineHighlight else { return nil }
        let intensity = min(max(config.activeLineHighlightIntensity, 0.0), 0.3)
        let base = (textView.backgroundColor ?? Theme.current.backgroundColor).resolvedColor(with: traitCollection)
        let overlay: UIColor = base.isDark ? .white : .black
        return base.blended(with: overlay, fraction: CGFloat(intensity))
    }

    // MARK: - Autosave & History Snapshots

    private struct PhoneAutosaveState: Codable {
        let inputText: String
        let cursorPosition: Int
    }

    private func autosaveSignature(text: String) -> String {
        let cursor = textView.selectedRange.location
        let resultSignature = results.joined(separator: "\n")
        return "\(text)\n|\(cursor)|\n\(resultSignature)"
    }

    private func scheduleAutosave() {
        guard UIDevice.current.userInterfaceIdiom == .phone else { return }
        autosaveWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.performAutosaveIfNeeded()
        }
        autosaveWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + autosaveDebounce, execute: work)
    }

    private func performAutosaveIfNeeded() {
        let text = textView.text ?? ""
        let signature = autosaveSignature(text: text)
        guard signature != lastAutosaveSignature else { return }

        let state = PhoneAutosaveState(inputText: text, cursorPosition: textView.selectedRange.location)
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: autosaveKey)
            lastAutosaveSignature = signature
        }

        let now = Date()
        if now.timeIntervalSince(lastHistorySnapshotDate) >= historySnapshotInterval {
            let historySignature = signature
            if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               historySignature != lastHistorySignature {
                let resultText = results.filter { !$0.isEmpty }.joined(separator: "\n")
                Persistence.shared.addHistoryEntry(
                    expression: text,
                    result: resultText.isEmpty ? "No result" : resultText
                )
                NotificationCenter.default.post(name: NSNotification.Name("HistoryDidUpdate"), object: nil)
                lastHistorySignature = historySignature
                lastHistorySnapshotDate = now
            }
        }
    }

    private func restoreAutosavedStateIfAvailable() {
        guard let data = UserDefaults.standard.data(forKey: autosaveKey),
              let state = try? JSONDecoder().decode(PhoneAutosaveState.self, from: data) else {
            return
        }

        textView.text = state.inputText
        if state.cursorPosition <= (textView.text?.count ?? 0) {
            textView.selectedRange = NSRange(location: state.cursorPosition, length: 0)
        }
        scheduleHighlighting(force: true)
        updateActiveLine()
        scheduleEvaluation()
    }

    func autosaveNow() {
        guard UIDevice.current.userInterfaceIdiom == .phone else { return }
        performAutosaveIfNeeded()
    }

    private func lineStartUTF16Offsets(for text: String) -> [Int] {
        var offsets: [Int] = [0]
        offsets.reserveCapacity(max(1, text.filter { $0 == "\n" }.count + 1))
        var index = 0
        for unit in text.utf16 {
            if unit == 10 {
                offsets.append(index + 1)
            }
            index += 1
        }
        return offsets
    }

    // MARK: - Syntax Highlighting

    private var lastHighlightedText: String = ""
    private var didApplyPlainAttributesForLargeText = false
    private let highlightCharLimit: Int = 200000
    private let syncHighlightCharLimit: Int = 8000
    private let highlightQueue = DispatchQueue(label: "numby.highlight", qos: .userInitiated)
    private var highlightToken: Int = 0

    private func scheduleHighlighting(force: Bool = false) {
        applySyntaxHighlighting(force: force)
    }

    private func applySyntaxHighlighting(force: Bool = false) {
        guard Configuration.shared.config.syntaxHighlighting else { return }
        let storage = textView.textStorage

        let text = storage.string

        // Skip if text hasn't changed since last highlight
        if !force, text == lastHighlightedText {
            return
        }

        if text.count > highlightCharLimit {
            if !didApplyPlainAttributesForLargeText || force {
                applyBaseAttributes(storage: storage)
            }
            didApplyPlainAttributesForLargeText = true
            lastHighlightedText = text
            return
        }
        didApplyPlainAttributesForLargeText = false
        lastHighlightedText = text

        if text.count <= syncHighlightCharLimit {
            let spans = numbyWrapper.highlightSpans(for: text)
            applyHighlightSpans(spans, storage: storage)
            return
        }

        highlightToken &+= 1
        let token = highlightToken
        let snapshot = text
        highlightQueue.async { [weak self] in
            guard let self = self else { return }
            let spans = self.numbyWrapper.highlightSpans(for: snapshot)
            DispatchQueue.main.async {
                guard token == self.highlightToken else { return }
                guard self.textView.textStorage.string == snapshot else { return }
                self.applyHighlightSpans(spans, storage: self.textView.textStorage)
            }
        }
    }

    private func applyHighlightSpans(_ spans: [NumbyHighlightSpan], storage: NSTextStorage) {
        // Save cursor position before modifying storage
        let savedSelectedRange = textView.selectedRange

        let fullRange = NSRange(location: 0, length: storage.length)
        let theme = Theme.current
        let font = textView.font ?? .monospacedSystemFont(ofSize: 16, weight: .regular)

        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 8

        storage.beginEditing()
        storage.addAttribute(.foregroundColor, value: theme.textColor, range: fullRange)
        storage.addAttribute(.font, value: font, range: fullRange)
        storage.addAttribute(.paragraphStyle, value: paragraph, range: fullRange)
        for span in spans {
            let start = Int(span.start)
            let length = Int(span.len)
            guard start >= 0, length > 0 else { continue }
            guard start + length <= storage.length else { continue }
            let range = NSRange(location: start, length: length)
            let color = colorForHighlightKind(span.kind, theme: theme)
            storage.addAttribute(.foregroundColor, value: color, range: range)
        }
        storage.endEditing()

        // Restore cursor position after modifying storage
        textView.selectedRange = savedSelectedRange
    }

    private func applyBaseAttributes(storage: NSTextStorage) {
        let fullRange = NSRange(location: 0, length: storage.length)
        let theme = Theme.current
        let font = textView.font ?? .monospacedSystemFont(ofSize: 16, weight: .regular)
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 8

        storage.beginEditing()
        storage.addAttribute(.foregroundColor, value: theme.textColor, range: fullRange)
        storage.addAttribute(.font, value: font, range: fullRange)
        storage.addAttribute(.paragraphStyle, value: paragraph, range: fullRange)
        storage.endEditing()
    }

    private func colorForHighlightKind(_ kindValue: UInt8, theme: Theme) -> UIColor {
        let kind = HighlightKind(rawValue: kindValue) ?? .text
        switch kind {
        case .text:
            return theme.syntaxColor(for: .text)
        case .number:
            return theme.syntaxColor(for: .numbers)
        case .operator:
            return theme.syntaxColor(for: .operators)
        case .keyword:
            return theme.syntaxColor(for: .keywords)
        case .function:
            return theme.syntaxColor(for: .functions)
        case .constant:
            return theme.syntaxColor(for: .constants)
        case .variable:
            return theme.syntaxColor(for: .variables)
        case .variableUsage:
            return theme.syntaxColor(for: .variableUsage)
        case .assignment:
            return theme.syntaxColor(for: .assignment)
        case .currency:
            return theme.syntaxColor(for: .currency)
        case .unit:
            return theme.syntaxColor(for: .units)
        case .comment:
            return theme.syntaxColor(for: .comments)
        case .scale:
            return theme.syntaxColor(for: .units)
        case .datetime:
            return theme.syntaxColor(for: .keywords)
        }
    }

    // MARK: - Theme

    @objc private func themeDidChange() {
        updateTheme()
    }

    @objc private func configDidChange() {
        applyNumberFormat()
        scheduleEvaluation()
        applyActiveLineAppearance()
    }

    @objc private func activeLineHighlightDidChange() {
        applyActiveLineAppearance()
    }

    private func applyNumberFormat() {
        let config = Configuration.shared.config
        _ = numbyWrapper.setNumberFormat(
            config.numberFormat,
            maxDecimals: config.numberMaxDecimals
        )
    }

    private func updateTheme() {
        let theme = Theme.current
        let config = Configuration.shared.config
        let font = UIFont(name: config.fontName ?? "Menlo-Regular", size: config.fontSize) ?? .monospacedSystemFont(ofSize: config.fontSize, weight: .regular)

        overrideUserInterfaceStyle = .dark
        view.backgroundColor = theme.backgroundColor
        textView.backgroundColor = theme.backgroundColor
        textView.textColor = theme.textColor
        textView.tintColor = theme.textColor
        textView.font = font
        textView.keyboardAppearance = .dark

        #if !os(visionOS)
        // Update accessory bar
        inputAccessoryBar.backgroundColor = theme.backgroundColor
        let buttonBg = theme.textColor.withAlphaComponent(0.08)
        accessoryButtons.forEach {
            $0.setTitleColor(theme.textColor.withAlphaComponent(0.9), for: .normal)
            $0.backgroundColor = buttonBg
        }
        #endif

        if let nav = navigationController {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = theme.backgroundColor
            appearance.titleTextAttributes = [.foregroundColor: theme.textColor]
            appearance.shadowColor = .clear
            nav.navigationBar.standardAppearance = appearance
            nav.navigationBar.scrollEdgeAppearance = appearance
            nav.navigationBar.tintColor = theme.textColor
        }

        // Reset cache so highlighting re-applies with new theme/font
        lastHighlightedText = ""
        scheduleHighlighting(force: true)
        applyActiveLineAppearance()
    }

    // MARK: - Actions

    @objc private func openSettings() {
        textView.resignFirstResponder()
        let nav = UINavigationController(rootViewController: SettingsViewController())
        nav.modalPresentationStyle = .pageSheet
        present(nav, animated: true)
    }

    @objc private func openHistory() {
        textView.resignFirstResponder()
        let nav = UINavigationController(rootViewController: HistoryViewController())
        nav.modalPresentationStyle = .pageSheet
        present(nav, animated: true)
    }

    @objc private func newCalculation() {
        // On iPad with tab container, create a new tab
        if let container = tabContainer {
            container.createNewTab()
            return
        }

        // On iPhone, just clear and start fresh
        let text = textView.text ?? ""
        if !text.isEmpty {
            let result = results.filter { !$0.isEmpty }.joined(separator: "\n")
            Persistence.shared.addHistoryEntry(expression: text, result: result.isEmpty ? "No result" : result)
            NotificationCenter.default.post(name: NSNotification.Name("HistoryDidUpdate"), object: nil)
        }
        textView.text = ""
        results = []
        updateResultsOverlay()
    }

    @objc private func shareResult() {
        let text = textView.text ?? ""
        guard !text.isEmpty else { return }

        let lines = text.components(separatedBy: "\n")
        var imageLines: [(expression: String, result: String)] = []

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty && index < results.count && !results[index].isEmpty {
                imageLines.append((expression: trimmed, result: results[index]))
            }
        }

        guard !imageLines.isEmpty else { return }

        // Show custom share sheet
        let alert = UIAlertController(title: NSLocalizedString("share.title", comment: "Share"), message: nil, preferredStyle: .actionSheet)

        // Copy as Text
        alert.addAction(UIAlertAction(title: NSLocalizedString("share.copyText", comment: "Copy as Text"), style: .default) { [weak self] _ in
            let shareText = ShareURLGenerator.generateText(lines: imageLines)
            UIPasteboard.general.string = shareText
            self?.showCopiedFeedback()
        })

        // Copy as Image
        alert.addAction(UIAlertAction(title: NSLocalizedString("share.copyImage", comment: "Copy as Image"), style: .default) { [weak self] _ in
            let config = Configuration.shared.config
            if let image = CalculatorImageRenderer.render(
                lines: imageLines,
                theme: Theme.current,
                fontSize: config.fontSize,
                fontName: config.fontName ?? "Menlo-Regular"
            ) {
                UIPasteboard.general.image = image
                self?.showCopiedFeedback()
            }
        })

        // Copy as Link
        alert.addAction(UIAlertAction(title: NSLocalizedString("share.copyLink", comment: "Copy as Link"), style: .default) { [weak self] _ in
            let url = ShareURLGenerator.generate(lines: imageLines, theme: Theme.current.name)
            UIPasteboard.general.string = url.absoluteString
            self?.showCopiedFeedback()
        })

        alert.addAction(UIAlertAction(title: NSLocalizedString("nav.cancel", comment: "Cancel"), style: .cancel))

        // iPad popover
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItems?.last
        }

        present(alert, animated: true)
    }

    private func showCopiedFeedback() {
        #if !os(visionOS)
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)
        #endif

        // Show visual toast
        let toast = CopiedToastView()
        toast.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toast)

        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toast.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        toast.alpha = 0
        toast.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)

        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
            toast.alpha = 1
            toast.transform = .identity
        }

        UIView.animate(withDuration: 0.2, delay: 1.5, options: .curveEaseOut) {
            toast.alpha = 0
        } completion: { _ in
            toast.removeFromSuperview()
        }
    }

    @objc private func loadHistoryEntry(_ notification: Notification) {
        guard let expr = notification.userInfo?["expression"] as? String else { return }
        textView.text = expr
        textView.becomeFirstResponder()
        scheduleHighlighting(force: true)
        scheduleEvaluation()
    }
}

// MARK: - UITextViewDelegate

extension CalculatorViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard text == "\t", textView.markedTextRange == nil,
              let suffix = numbyWrapper.variableCompletion(in: textView.text ?? "", selection: range) else {
            return true
        }
        textView.insertText(suffix)
        return false
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        // Notify split container that this pane is now focused
        if let leafId = leafId {
            splitContainerDelegate?.paneTapped(leafId: leafId)
        }
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        // Notify split container when cursor moves - reliable focus indicator
        if let leafId = leafId {
            splitContainerDelegate?.paneTapped(leafId: leafId)
        }
        updateActiveLine()
    }

    func textViewDidChange(_ textView: UITextView) {
        // Apply syntax highlighting immediately for responsive feel
        scheduleHighlighting(force: true)
        updateActiveLine()
        // Debounce evaluation (expensive)
        scheduleEvaluation()
        // Debounce autosave + history snapshots
        scheduleAutosave()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateResultsOverlay()
    }
}

// MARK: - UIGestureRecognizerDelegate

extension CalculatorViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Allow tap gesture to work alongside text view's default gestures
        return true
    }
}

// MARK: - Active Line Text View

class ActiveLineTextView: UITextView {
    var activeLineIndex: Int = 0 { didSet { setNeedsDisplay() } }
    var activeLineGroupStart: Int = 0 { didSet { setNeedsDisplay() } }
    var activeLineGroupEnd: Int = 0 { didSet { setNeedsDisplay() } }
    var activeLineHighlightColor: UIColor? { didSet { setNeedsDisplay() } }
    var isActiveLineHighlightEnabled: Bool = false { didSet { setNeedsDisplay() } }

    override func draw(_ rect: CGRect) {
        if isActiveLineHighlightEnabled, let color = activeLineHighlightColor {
            drawActiveLineBackground(color)
        }
        super.draw(rect)
    }

    private func drawActiveLineBackground(_ color: UIColor) {
        let text = (self.text ?? "") as NSString
        let start = min(activeLineGroupStart, activeLineGroupEnd)
        let end = max(activeLineGroupStart, activeLineGroupEnd)
        var minY: CGFloat?
        var maxY: CGFloat?

        for lineIndex in start...end {
            guard let lineRange = lineRange(for: lineIndex, in: text) else { continue }
            if lineRange.length == 0 {
                if let position = position(from: beginningOfDocument, offset: lineRange.location) {
                    let caret = caretRect(for: position)
                    if !caret.isEmpty {
                        minY = min(minY ?? caret.minY, caret.minY)
                        maxY = max(maxY ?? caret.maxY, caret.maxY)
                    }
                }
                continue
            }

            guard let startPosition = position(from: beginningOfDocument, offset: lineRange.location),
                  let endPosition = position(from: startPosition, offset: lineRange.length),
                  let textRange = textRange(from: startPosition, to: endPosition) else {
                continue
            }

            let rects = selectionRects(for: textRange)
            for selectionRect in rects {
                let rect = selectionRect.rect
                if rect.isEmpty { continue }
                minY = min(minY ?? rect.minY, rect.minY)
                maxY = max(maxY ?? rect.maxY, rect.maxY)
            }
        }

        if let minY, let maxY {
            let highlightRect = CGRect(x: 0, y: minY, width: bounds.width, height: maxY - minY)
            color.setFill()
            UIRectFill(highlightRect)
        }
    }

    private func lineRange(for lineIndex: Int, in text: NSString) -> NSRange? {
        guard lineIndex >= 0 else { return nil }
        var currentLine = 0
        var searchIndex = 0
        while searchIndex <= text.length {
            let range = text.lineRange(for: NSRange(location: searchIndex, length: 0))
            if currentLine == lineIndex {
                return range
            }
            if range.length == 0 {
                break
            }
            searchIndex = range.upperBound
            currentLine += 1
        }
        return nil
    }
}

// MARK: - Results Overlay

class ResultsOverlayView: UIView {
    private var labels: [UILabel] = []
    private let activeLineHighlightView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        activeLineHighlightView.isUserInteractionEnabled = false
        activeLineHighlightView.isOpaque = false
        activeLineHighlightView.isHidden = true
        insertSubview(activeLineHighlightView, at: 0)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        isOpaque = false
        activeLineHighlightView.isUserInteractionEnabled = false
        activeLineHighlightView.isOpaque = false
        activeLineHighlightView.isHidden = true
        insertSubview(activeLineHighlightView, at: 0)
    }

    func update(
        results: [String],
        font: UIFont,
        textColor: UIColor,
        textView: UITextView,
        activeLineIndex: Int,
        activeGroupStart: Int,
        activeGroupEnd: Int,
        activeLineHighlightColor: UIColor?,
        activeLineHighlightEnabled: Bool
    ) {
        let rightPadding: CGFloat = 16

        let text = textView.text ?? ""
        let nsText = text as NSString
        let lines = text.components(separatedBy: "\n")
        let lineCount = max(lines.count, results.count)

        while labels.count < lineCount {
            let label = UILabel()
            label.textAlignment = .right
            addSubview(label)
            labels.append(label)
        }

        let lineSpacing: CGFloat = 8
        var fallbackY: CGFloat = textView.textContainerInset.top
        let fallbackHeight: CGFloat = font.lineHeight
        var highlightMinY: CGFloat?
        var highlightMaxY: CGFloat?
        var minResultX: CGFloat?

        for i in 0..<lineCount {
            let label = labels[i]
            let line = i < lines.count ? lines[i] : ""
            let result = i < results.count ? results[i] : ""
            let hasResult = !result.isEmpty
            let lineRect = lineRect(for: i, in: nsText, textView: textView)
            let lineMinY = lineRect?.minY ?? fallbackY
            let lineHeight = lineRect?.height ?? fallbackHeight

            if hasResult {
                label.text = result
                label.font = font
                label.textColor = textColor
                label.isHidden = false
                label.sizeToFit()

                let resultWidth = label.frame.width
                let availableWidth = bounds.width - rightPadding
                let resultX = availableWidth - resultWidth
                label.frame.origin = CGPoint(x: resultX, y: lineMinY)
                if i >= activeGroupStart && i <= activeGroupEnd {
                    minResultX = min(minResultX ?? resultX, resultX)
                }
            } else {
                label.isHidden = true
            }

            if i >= activeGroupStart && i <= activeGroupEnd {
                let lineMaxY = lineMinY + lineHeight
                highlightMinY = min(highlightMinY ?? lineMinY, lineMinY)
                highlightMaxY = max(highlightMaxY ?? lineMaxY, lineMaxY)
            }

            fallbackY = lineMinY + lineHeight + lineSpacing
        }

        for i in lineCount..<labels.count {
            labels[i].isHidden = true
        }

        if activeLineHighlightEnabled,
           let color = activeLineHighlightColor,
           let minY = highlightMinY,
           let maxY = highlightMaxY,
           let highlightStartX = minResultX {
            activeLineHighlightView.backgroundColor = color
            activeLineHighlightView.frame = CGRect(x: highlightStartX, y: minY, width: bounds.width - highlightStartX, height: maxY - minY)
            activeLineHighlightView.isHidden = false
        } else {
            activeLineHighlightView.isHidden = true
        }
    }

    private func lineRect(for lineIndex: Int, in text: NSString, textView: UITextView) -> CGRect? {
        guard let lineRange = lineRange(for: lineIndex, in: text) else { return nil }

        if lineRange.length == 0 {
            if let position = textView.position(from: textView.beginningOfDocument, offset: lineRange.location) {
                return textView.caretRect(for: position)
            }
            return nil
        }

        guard let startPosition = textView.position(from: textView.beginningOfDocument, offset: lineRange.location),
              let endPosition = textView.position(from: startPosition, offset: lineRange.length),
              let textRange = textView.textRange(from: startPosition, to: endPosition) else {
            return nil
        }

        let rects = textView.selectionRects(for: textRange).map { $0.rect }.filter { !$0.isEmpty }
        guard var unionRect = rects.first else { return nil }
        for rect in rects.dropFirst() {
            unionRect = unionRect.union(rect)
        }
        return unionRect
    }

    private func lineRange(for lineIndex: Int, in text: NSString) -> NSRange? {
        guard lineIndex >= 0 else { return nil }
        var currentLine = 0
        var searchIndex = 0
        while searchIndex <= text.length {
            let range = text.lineRange(for: NSRange(location: searchIndex, length: 0))
            if currentLine == lineIndex {
                return range
            }
            if range.length == 0 {
                break
            }
            searchIndex = range.upperBound
            currentLine += 1
        }
        return nil
    }
}

// MARK: - Copied Toast View

class CopiedToastView: UIView {
    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "checkmark.circle.fill")
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let label: UILabel = {
        let lbl = UILabel()
        lbl.text = NSLocalizedString("share.copied", comment: "Copied!")
        lbl.textColor = .white
        lbl.font = .systemFont(ofSize: 14, weight: .medium)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        backgroundColor = UIColor.black.withAlphaComponent(0.75)
        layer.cornerRadius = 20

        addSubview(iconView)
        addSubview(label)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 16),
            iconView.heightAnchor.constraint(equalToConstant: 16),

            label.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),

            heightAnchor.constraint(equalToConstant: 40)
        ])
    }
}
#endif
