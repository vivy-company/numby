#if os(iOS)
import UIKit

class CalculatorViewController: UIViewController {

    // MARK: - Properties

    private let numbyWrapper = NumbyWrapper()
    private var inputText: String = "" {
        didSet {
            evaluateInput()
            applySyntaxHighlighting()
        }
    }
    private var results: [String] = []

    // MARK: - UI Components

    private lazy var containerStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fill
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var inputTextView: UITextView = {
        let textView = UITextView()
        textView.isEditable = true
        textView.isScrollEnabled = true
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        textView.smartQuotesType = .no
        textView.smartDashesType = .no
        textView.spellCheckingType = .no
        textView.keyboardType = .default
        textView.delegate = self
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        textView.translatesAutoresizingMaskIntoConstraints = false

        // Custom cursor width
        textView.tintColor = Theme.current.textColor

        return textView
    }()

    private lazy var resultsTextView: UITextView = {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = true
        textView.isUserInteractionEnabled = false
        textView.textAlignment = .right
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 8, bottom: 16, right: 16)
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()

    private lazy var dividerView: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private var inputWidthConstraint: NSLayoutConstraint!
    private var resultsWidthConstraint: NSLayoutConstraint!
    private var splitRatio: CGFloat = 0.8
    private var isDraggingDivider = false

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateTheme()

        // Keyboard notifications for scroll sync
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(themeDidChange),
            name: NSNotification.Name("ThemeDidChange"),
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // Respond to system dark mode changes
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateTheme()
        }
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(inputTextView)
        view.addSubview(dividerView)
        view.addSubview(resultsTextView)

        inputWidthConstraint = inputTextView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: splitRatio)
        resultsWidthConstraint = resultsTextView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1 - splitRatio)

        NSLayoutConstraint.activate([
            inputTextView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            inputTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputTextView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            inputWidthConstraint,

            dividerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            dividerView.leadingAnchor.constraint(equalTo: inputTextView.trailingAnchor),
            dividerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            dividerView.widthAnchor.constraint(equalToConstant: 1),

            resultsTextView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            resultsTextView.leadingAnchor.constraint(equalTo: dividerView.trailingAnchor),
            resultsTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            resultsTextView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            resultsWidthConstraint
        ])

        // Add pan gesture to divider for dragging
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleDividerPan(_:)))
        dividerView.addGestureRecognizer(panGesture)

        // Make divider hit area larger
        let tapArea = UIView()
        tapArea.backgroundColor = .clear
        tapArea.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(tapArea, aboveSubview: dividerView)

        NSLayoutConstraint.activate([
            tapArea.topAnchor.constraint(equalTo: dividerView.topAnchor),
            tapArea.bottomAnchor.constraint(equalTo: dividerView.bottomAnchor),
            tapArea.centerXAnchor.constraint(equalTo: dividerView.centerXAnchor),
            tapArea.widthAnchor.constraint(equalToConstant: 44)
        ])

        tapArea.addGestureRecognizer(panGesture)

        // Add swipe down gesture to dismiss keyboard
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        swipeGesture.direction = .down
        inputTextView.addGestureRecognizer(swipeGesture)
    }

    @objc private func dismissKeyboard() {
        inputTextView.resignFirstResponder()
    }

    @objc private func handleDividerPan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: view)
        let viewWidth = view.bounds.width

        switch gesture.state {
        case .began:
            isDraggingDivider = true
            inputTextView.resignFirstResponder()

        case .changed:
            // Calculate new ratio (constrain between 30% and 90%)
            let newRatio = location.x / viewWidth
            splitRatio = max(0.3, min(0.9, newRatio))

            // Update constraints
            inputWidthConstraint.isActive = false
            resultsWidthConstraint.isActive = false

            inputWidthConstraint = inputTextView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: splitRatio)
            resultsWidthConstraint = resultsTextView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1 - splitRatio)

            inputWidthConstraint.isActive = true
            resultsWidthConstraint.isActive = true

            view.layoutIfNeeded()

        case .ended, .cancelled:
            isDraggingDivider = false

        default:
            break
        }
    }

    // MARK: - Keyboard Handling

    @objc private func keyboardWillShow(_ notification: Notification) {
        // Sync scroll if needed
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        // Handle keyboard hide if needed
    }

    // MARK: - Evaluation

    private func evaluateInput() {
        let lines = inputText.components(separatedBy: .newlines)
        results = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("//") || trimmed.hasPrefix("#") {
                results.append("")
            } else {
                let result = numbyWrapper.evaluate(trimmed)
                if let formatted = result.formatted {
                    results.append(formatted)

                    // Save to history
                    Persistence.shared.addHistoryEntry(expression: trimmed, result: formatted)
                } else {
                    results.append("")
                }
            }
        }

        updateResultsDisplay()
    }

    private func updateResultsDisplay() {
        let config = Configuration.shared.config
        let fontSize = config.fontSize
        let fontName = config.fontName ?? "Menlo-Regular"
        let font = UIFont(name: fontName, size: fontSize) ?? .monospacedSystemFont(ofSize: fontSize, weight: .regular)

        let paragraph = NSMutableParagraphStyle()
        paragraph.lineHeightMultiple = 1.0
        paragraph.paragraphSpacing = 0
        paragraph.lineSpacing = 8
        paragraph.alignment = .right

        let resultsText = results.joined(separator: "\n")
        let attributedString = NSMutableAttributedString(string: resultsText)
        let fullRange = NSRange(location: 0, length: attributedString.length)

        attributedString.addAttribute(.foregroundColor, value: Theme.current.syntaxColor(for: .results), range: fullRange)
        attributedString.addAttribute(.font, value: font, range: fullRange)
        attributedString.addAttribute(.paragraphStyle, value: paragraph, range: fullRange)

        resultsTextView.attributedText = attributedString
    }

    // MARK: - Syntax Highlighting

    private func applySyntaxHighlighting() {
        guard Configuration.shared.config.syntaxHighlighting else {
            // No highlighting, just apply basic styling
            let config = Configuration.shared.config
            let fontSize = config.fontSize
            let fontName = config.fontName ?? "Menlo-Regular"
            let font = UIFont(name: fontName, size: fontSize) ?? .monospacedSystemFont(ofSize: fontSize, weight: .regular)

            inputTextView.font = font
            inputTextView.textColor = Theme.current.textColor
            return
        }

        let config = Configuration.shared.config
        let fontSize = config.fontSize
        let fontName = config.fontName ?? "Menlo-Regular"
        let font = UIFont(name: fontName, size: fontSize) ?? .monospacedSystemFont(ofSize: fontSize, weight: .regular)

        let paragraph = NSMutableParagraphStyle()
        paragraph.lineHeightMultiple = 1.0
        paragraph.paragraphSpacing = 0
        paragraph.lineSpacing = 8

        let attributedString = NSMutableAttributedString(string: inputText)
        let fullRange = NSRange(location: 0, length: attributedString.length)

        // Reset to base styling with system label color
        attributedString.addAttribute(.foregroundColor, value: UIColor.label, range: fullRange)
        attributedString.addAttribute(.font, value: font, range: fullRange)
        attributedString.addAttribute(.paragraphStyle, value: paragraph, range: fullRange)

        let theme = Theme.current

        // Apply syntax patterns (same order as macOS)
        applySyntaxPattern(attributedString, pattern: "\\b\\d+(\\.\\d+)?\\b", colorType: .numbers)
        applySyntaxPattern(attributedString, pattern: "[+\\-*/()^%]", colorType: .operators)
        applySyntaxPattern(attributedString, pattern: "\\b(USD|EUR|JPY|GBP|CNY|CHF|AUD|CAD|NZD|SEK|NOK|DKK|PLN|CZK|HUF|RON|BGN|HRK|RUB|TRY|BRL|MXN|ARS|CLP|COP|PEN|INR|IDR|MYR|PHP|THB|VND|KRW|TWD|HKD|SGD|ZAR|EGP|NGN|KES|GHS|XOF|XAF|MAD|TND|AED|SAR|QAR|KWD|BHD|OMR|ILS|JOD|LBP|IQD|IRR|AFN|PKR|BDT|NPR|LKR|MMK|KHR|LAK|MNT|KZT|UZS|TJS|KGS|TMT|GEL|AZN|AMD|BYN|MDL|UAH|RSD|MKD|ALL|BAM|ISK)\\b", colorType: .currency, options: .caseInsensitive)
        applySyntaxPattern(attributedString, pattern: "\\b(km|mi|m|cm|mm|ft|in|yd|kg|g|mg|lb|oz|ton|L|mL|gal|qt|pt|cup|tbsp|tsp|°C|°F|K|ms|s|min|h|day|week|month|year|Hz|kHz|MHz|GHz|b|B|KB|MB|GB|TB|W|kW|MW|V|A|mA|Ω|J|cal|kcal|Pa|bar|atm|psi|mph|kmh|kph)\\b", colorType: .units, options: .caseInsensitive)
        applySyntaxPattern(attributedString, pattern: "\\b(in|to|as|of|per|from)\\b", colorType: .keywords, options: .caseInsensitive)
        applySyntaxPattern(attributedString, pattern: "\\b(sin|cos|tan|asin|acos|atan|sinh|cosh|tanh|sqrt|cbrt|ln|log|log10|log2|exp|abs|ceil|floor|round|min|max|pow|mod|gcd|lcm|factorial|rand|random)\\b", colorType: .functions, options: .caseInsensitive)
        applySyntaxPattern(attributedString, pattern: "\\b(pi|e|phi|tau|true|false)\\b", colorType: .constants, options: .caseInsensitive)

        // Variables (assignment pattern)
        if let regex = try? NSRegularExpression(pattern: "\\b([a-zA-Z_][a-zA-Z0-9_]*)\\s*=") {
            regex.enumerateMatches(in: inputText, range: fullRange) { match, _, _ in
                if let range = match?.range(at: 1) {
                    attributedString.addAttribute(.foregroundColor, value: theme.syntaxColor(for: .variables), range: range)
                }
            }
        }

        // Variable usage
        if let regex = try? NSRegularExpression(pattern: "\\b([a-zA-Z_][a-zA-Z0-9_]*)\\b") {
            regex.enumerateMatches(in: inputText, range: fullRange) { match, _, _ in
                if let range = match?.range {
                    let currentColor = attributedString.attribute(.foregroundColor, at: range.location, effectiveRange: nil) as? UIColor
                    if currentColor == UIColor.label {
                        attributedString.addAttribute(.foregroundColor, value: theme.syntaxColor(for: .variableUsage), range: range)
                    }
                }
            }
        }

        // Assignment operator
        applySyntaxPattern(attributedString, pattern: "\\s(=)\\s", colorType: .assignment, captureGroup: 1)

        // Comments (must be last to override other colors)
        applySyntaxPattern(attributedString, pattern: "(//|#).*$", colorType: .comments, options: .anchorsMatchLines)

        // Preserve cursor position
        let selectedRange = inputTextView.selectedRange
        inputTextView.attributedText = attributedString
        inputTextView.selectedRange = selectedRange

        // Keep cursor color matching text color
        inputTextView.tintColor = theme.textColor
    }

    private func applySyntaxPattern(_ attributedString: NSMutableAttributedString,
                                   pattern: String,
                                   colorType: SyntaxColorType,
                                   options: NSRegularExpression.Options = [],
                                   captureGroup: Int = 0) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return }

        let fullRange = NSRange(location: 0, length: attributedString.length)
        let color = Theme.current.syntaxColor(for: colorType)

        regex.enumerateMatches(in: inputText, range: fullRange) { match, _, _ in
            var range: NSRange?
            if captureGroup > 0, let matchRange = match?.range(at: captureGroup) {
                range = matchRange
            } else if let matchRange = match?.range {
                range = matchRange
            }

            if let range = range {
                attributedString.addAttribute(.foregroundColor, value: color, range: range)
            }
        }
    }

    // MARK: - Theme

    @objc private func themeDidChange() {
        updateTheme()
    }

    private func updateTheme() {
        let theme = Theme.current

        // Always use dark mode
        overrideUserInterfaceStyle = .dark

        // Use system background colors
        view.backgroundColor = .systemBackground
        inputTextView.backgroundColor = .systemBackground
        resultsTextView.backgroundColor = .systemBackground

        // Text colors from system
        inputTextView.textColor = .label
        inputTextView.tintColor = .label
        inputTextView.keyboardAppearance = .dark

        resultsTextView.textColor = theme.syntaxColor(for: .results)

        // Reapply syntax highlighting with theme colors
        applySyntaxHighlighting()
        updateResultsDisplay()
    }
}

// MARK: - UITextViewDelegate

extension CalculatorViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        inputText = textView.text
    }
}
#endif
