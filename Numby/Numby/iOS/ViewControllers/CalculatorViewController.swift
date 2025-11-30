#if os(iOS) || os(visionOS)
import UIKit

class CalculatorViewController: UIViewController {

    // MARK: - Accessory Bar View

    private class AccessoryBarView: UIView {
        override var intrinsicContentSize: CGSize {
            CGSize(width: UIView.noIntrinsicMetric, height: 120)
        }
    }

    // MARK: - Properties

    private var numbyWrapper = NumbyWrapper()
    private var results: [String] = []
    private var accessoryButtons: [UIButton] = []

    // Reference to tab container (iPad only)
    weak var tabContainer: iPadTabContainerViewController?

    // MARK: - Tab State

    func saveState(to tab: CalculatorTab) {
        tab.text = textView.text ?? ""
        tab.results = results
    }

    func restoreState(from tab: CalculatorTab) {
        numbyWrapper = tab.numbyWrapper
        textView.text = tab.text
        results = tab.results
        applySyntaxHighlighting()
        updateResultsOverlay()
    }

    // MARK: - UI Components

    private lazy var textView: UITextView = {
        let tv = UITextView()
        tv.isEditable = true
        tv.isScrollEnabled = true
        tv.alwaysBounceVertical = true
        tv.autocorrectionType = .no
        tv.autocapitalizationType = .none
        tv.smartQuotesType = .no
        tv.smartDashesType = .no
        tv.spellCheckingType = .no
        tv.keyboardType = .default
        tv.delegate = self
        tv.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private lazy var resultsOverlay: ResultsOverlayView = {
        let overlay = ResultsOverlayView()
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.isUserInteractionEnabled = false
        return overlay
    }()

    private lazy var inputAccessoryBar: UIView = {
        let barHeight: CGFloat = 120
        let rowHeight: CGFloat = 32
        let buttonSpacing: CGFloat = 6
        let rowSpacing: CGFloat = 4
        let padding: CGFloat = 8

        let container = AccessoryBarView()

        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: container.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

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

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateTheme()

        title = "Numby"

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: NSNotification.Name("ThemeDidChange"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loadHistoryEntry(_:)), name: NSNotification.Name("LoadHistoryEntry"), object: nil)
    }

    private var hasAppearedOnce = false

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !hasAppearedOnce {
            // Set up navigation items after layout is ready
            navigationItem.leftBarButtonItems = [
                UIBarButtonItem(image: UIImage(systemName: "gear"), style: .plain, target: self, action: #selector(openSettings)),
                UIBarButtonItem(image: UIImage(systemName: "clock"), style: .plain, target: self, action: #selector(openHistory))
            ]
            navigationItem.rightBarButtonItems = [
                UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(newCalculation)),
                UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"), style: .plain, target: self, action: #selector(shareResult))
            ]
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !hasAppearedOnce {
            hasAppearedOnce = true
            textView.becomeFirstResponder()
        }
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
        textView.inputAccessoryView = inputAccessoryBar
        #endif
    }

    // MARK: - Keyboard

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardFrame = frame.cgRectValue
        let height = keyboardFrame.height - view.safeAreaInsets.bottom

        #if !os(visionOS)
        // Hide accessory bar when hardware keyboard is connected (keyboard height is small)
        // Hardware keyboard shows a small floating bar (~55pt), software keyboard is much taller
        let isHardwareKeyboard = keyboardFrame.height < 100
        textView.inputAccessoryView = isHardwareKeyboard ? nil : inputAccessoryBar
        textView.reloadInputViews()
        #endif

        textView.contentInset.bottom = max(0, height)
        textView.verticalScrollIndicatorInsets.bottom = max(0, height)
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        textView.contentInset = .zero
        textView.verticalScrollIndicatorInsets = .zero
    }

    // MARK: - Evaluation

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

        evalQueue.async { [weak self] in
            guard let self = self else { return }
            guard evalID == self.currentEvalID else { return }

            let newResults = lines.map { line -> String in
                // Check if cancelled
                guard evalID == self.currentEvalID else { return "" }

                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.isEmpty || trimmed.hasPrefix("//") || trimmed.hasPrefix("#") {
                    return ""
                }
                return self.numbyWrapper.evaluate(trimmed).formatted?.replacingOccurrences(of: "\n", with: "  ") ?? ""
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
        resultsOverlay.update(results: results, font: font, textColor: Theme.current.syntaxColor(for: .results), textView: textView)
    }

    // MARK: - Syntax Highlighting

    private func applySyntaxHighlighting() {
        guard Configuration.shared.config.syntaxHighlighting else { return }
        guard let storage = textView.textStorage as? NSTextStorage else { return }

        // Save cursor position before modifying storage
        let savedSelectedRange = textView.selectedRange

        let text = storage.string
        let fullRange = NSRange(location: 0, length: storage.length)
        let theme = Theme.current
        let font = textView.font ?? .monospacedSystemFont(ofSize: 16, weight: .regular)

        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 8

        storage.beginEditing()
        storage.addAttribute(.foregroundColor, value: theme.textColor, range: fullRange)
        storage.addAttribute(.font, value: font, range: fullRange)
        storage.addAttribute(.paragraphStyle, value: paragraph, range: fullRange)

        // Numbers
        applyPattern("\\b\\d+(\\.\\d+)?\\b", color: theme.syntaxColor(for: .numbers), to: storage, text: text)
        // Operators (symbols)
        applyPattern("[+\\-*/()^%]", color: theme.syntaxColor(for: .operators), to: storage, text: text)
        // Word operators
        applyPattern("\\b(plus|minus|times|multiplied by|divided by|divide by|subtract|and|with)\\b", color: theme.syntaxColor(for: .operators), to: storage, text: text, options: .caseInsensitive)
        // Currency (including crypto)
        applyPattern("\\b(USD|EUR|JPY|GBP|CNY|CHF|AUD|CAD|NZD|SEK|NOK|DKK|PLN|CZK|HUF|RON|BGN|HRK|RUB|TRY|BRL|MXN|ARS|CLP|COP|PEN|INR|IDR|MYR|PHP|THB|VND|KRW|TWD|HKD|SGD|ZAR|EGP|NGN|KES|GHS|XOF|XAF|MAD|TND|AED|SAR|QAR|KWD|BHD|OMR|ILS|JOD|LBP|IQD|IRR|AFN|PKR|BDT|NPR|LKR|MMK|KHR|LAK|MNT|KZT|UZS|TJS|KGS|TMT|GEL|AZN|AMD|BYN|MDL|UAH|RSD|MKD|ALL|BAM|ISK|BTC|ETH|BNB)\\b", color: theme.syntaxColor(for: .currency), to: storage, text: text, options: .caseInsensitive)
        // Units (extended)
        applyPattern("\\b(km|mi|m|cm|mm|ft|in|yd|kg|g|mg|lb|oz|ton|L|mL|gal|qt|pt|cup|tbsp|tsp|°C|°F|K|ms|s|min|h|day|week|month|year|Hz|kHz|MHz|GHz|b|B|KB|MB|GB|TB|W|kW|MW|V|A|mA|Ω|J|cal|kcal|Pa|bar|atm|psi|mph|kmh|kph|meter|meters|centimeter|centimeters|millimeter|millimeters|kilometer|kilometers|foot|feet|inch|inches|yard|yards|mile|miles|sec|second|seconds|minute|minutes|hour|hours|days|weeks|months|years|kelvin|kelvins|celsius|fahrenheit|liter|liters|milliliter|milliliters|pint|pints|quart|quarts|gallon|gallons|teaspoon|teaspoons|tablespoon|tablespoons|gram|grams|kilogram|kilograms|tonne|tonnes|carat|carats|pound|pounds|stone|stones|ounce|ounces|bit|bits|byte|bytes|knot|knots|radian|radians|degree|degrees)\\b", color: theme.syntaxColor(for: .units), to: storage, text: text, options: .caseInsensitive)
        // Scales
        applyPattern("\\b(k|kilo|thousand|M|mega|million|G|giga|billion|T|tera)\\b", color: theme.syntaxColor(for: .units), to: storage, text: text, options: .caseInsensitive)
        // Keywords
        applyPattern("\\b(in|to|as|of|per|from)\\b", color: theme.syntaxColor(for: .keywords), to: storage, text: text, options: .caseInsensitive)
        // DateTime keywords
        applyPattern("\\b(time|now|today|tomorrow|yesterday|ago|before|after|next|last|this|between)\\b", color: theme.syntaxColor(for: .keywords), to: storage, text: text, options: .caseInsensitive)
        // Functions
        applyPattern("\\b(sin|cos|tan|asin|acos|atan|arcsin|arccos|arctan|sinh|cosh|tanh|sqrt|cbrt|ln|log|log10|log2|exp|abs|ceil|floor|round|min|max|pow|mod|gcd|lcm|factorial|rand|random)\\b", color: theme.syntaxColor(for: .functions), to: storage, text: text, options: .caseInsensitive)
        // Constants
        applyPattern("\\b(pi|e|phi|tau|true|false)\\b", color: theme.syntaxColor(for: .constants), to: storage, text: text, options: .caseInsensitive)
        // Variables (assignment)
        if let regex = try? NSRegularExpression(pattern: "\\b([a-zA-Z_][a-zA-Z0-9_]*)\\s*=", options: []) {
            regex.enumerateMatches(in: text, range: fullRange) { match, _, _ in
                if let range = match?.range(at: 1) {
                    storage.addAttribute(.foregroundColor, value: theme.syntaxColor(for: .variables), range: range)
                }
            }
        }
        // Variable usage
        if let regex = try? NSRegularExpression(pattern: "\\b([a-zA-Z_][a-zA-Z0-9_]*)\\b", options: []) {
            regex.enumerateMatches(in: text, range: fullRange) { match, _, _ in
                if let range = match?.range {
                    let currentColor = storage.attribute(.foregroundColor, at: range.location, effectiveRange: nil) as? UIColor
                    if currentColor == theme.textColor {
                        storage.addAttribute(.foregroundColor, value: theme.syntaxColor(for: .variableUsage), range: range)
                    }
                }
            }
        }
        // Assignment equals
        applyPattern("\\s(=)\\s", color: theme.syntaxColor(for: .assignment), to: storage, text: text, captureGroup: 1)
        // Comments (last - overrides all)
        applyPattern("(//|#).*$", color: theme.syntaxColor(for: .comments), to: storage, text: text, options: .anchorsMatchLines)

        storage.endEditing()

        // Restore cursor position after modifying storage
        textView.selectedRange = savedSelectedRange
    }

    private func applyPattern(_ pattern: String, color: UIColor, to storage: NSTextStorage, text: String, options: NSRegularExpression.Options = [], captureGroup: Int = 0) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return }
        let range = NSRange(location: 0, length: text.utf16.count)
        regex.enumerateMatches(in: text, range: range) { match, _, _ in
            if let r = match?.range(at: captureGroup), r.location != NSNotFound {
                storage.addAttribute(.foregroundColor, value: color, range: r)
            }
        }
    }

    // MARK: - Theme

    @objc private func themeDidChange() {
        updateTheme()
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

        // Update accessory bar
        inputAccessoryBar.backgroundColor = theme.backgroundColor
        let buttonBg = theme.textColor.withAlphaComponent(0.08)
        accessoryButtons.forEach {
            $0.setTitleColor(theme.textColor.withAlphaComponent(0.9), for: .normal)
            $0.backgroundColor = buttonBg
        }

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

        applySyntaxHighlighting()
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
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)
    }

    @objc private func loadHistoryEntry(_ notification: Notification) {
        guard let expr = notification.userInfo?["expression"] as? String else { return }
        textView.text = expr
        textView.becomeFirstResponder()
        applySyntaxHighlighting()
        scheduleEvaluation()
    }
}

// MARK: - UITextViewDelegate

extension CalculatorViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        applySyntaxHighlighting()
        scheduleEvaluation()
    }
}

// MARK: - Results Overlay

class ResultsOverlayView: UIView {
    private var labels: [UILabel] = []

    func update(results: [String], font: UIFont, textColor: UIColor, textView: UITextView) {
        let layoutManager = textView.layoutManager
        let textContainer = textView.textContainer
        let textStorage = textView.textStorage
        let insets = textView.textContainerInset
        let rightPadding: CGFloat = 16

        while labels.count < results.count {
            let label = UILabel()
            label.textAlignment = .right
            addSubview(label)
            labels.append(label)
        }

        let text = textView.text ?? ""
        let lines = text.components(separatedBy: "\n")
        var charIndex = 0

        for (i, label) in labels.enumerated() {
            guard i < results.count && i < lines.count else {
                label.isHidden = true
                continue
            }

            let lineLength = lines[i].utf16.count
            let hasResult = !results[i].isEmpty

            if hasResult && charIndex < textStorage.length {
                label.text = results[i]
                label.font = font
                label.textColor = textColor
                label.isHidden = false
                label.sizeToFit()

                let lineRange = NSRange(location: charIndex, length: max(1, min(lineLength, textStorage.length - charIndex)))
                let glyphRange = layoutManager.glyphRange(forCharacterRange: lineRange, actualCharacterRange: nil)
                let lineRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)

                let resultWidth = label.frame.width
                let availableWidth = bounds.width - rightPadding
                let resultX = availableWidth - resultWidth

                // Check if line wraps (height > single line)
                let singleLineHeight = font.lineHeight + 8
                let lineY: CGFloat
                if lineRect.height > singleLineHeight * 1.5 {
                    // Line wraps - position result at the bottom-right of the wrapped block
                    lineY = insets.top + lineRect.maxY - font.lineHeight
                } else {
                    lineY = insets.top + lineRect.minY
                }

                label.frame.origin = CGPoint(x: resultX, y: lineY)
            } else {
                label.isHidden = true
            }

            charIndex += lineLength + 1
        }

        for i in results.count..<labels.count {
            labels[i].isHidden = true
        }
    }
}
#endif
