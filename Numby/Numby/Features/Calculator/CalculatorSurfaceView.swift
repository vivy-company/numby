//
//  CalculatorSurfaceView.swift
//  Numby
//
//  Individual calculator surface - renders one calculator instance with input/results panels
//

#if os(macOS)
import SwiftUI
import Combine

/// View for a single calculator instance with split input/results panels
struct CalculatorSurfaceView: View {
    @ObservedObject var instance: CalculatorInstance
    let leafId: SplitLeafID
    let isFocused: Bool

    // Theme is now accessed via Theme.current static property
    @EnvironmentObject var configManager: Configuration

    @State private var updateTrigger: Int = 0
    @FocusState private var isViewFocused: Bool

    @State private var showCopiedFeedback = false

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    HStack(spacing: 0) {
                        // Left panel - Input (80%)
                        ZStack {
                            Color(configManager.config.backgroundColor ?? NSColor.textBackgroundColor)
                                .ignoresSafeArea()

                            InputTextView(
                                text: $instance.inputText,
                                backgroundColor: configManager.config.backgroundColor ?? NSColor.textBackgroundColor,
                                textColor: Theme.current.syntaxColor(for: .text),
                                fontSize: configManager.config.fontSize,
                                fontName: configManager.config.fontName ?? "SFMono-Regular",
                                syntaxHighlighting: configManager.config.syntaxHighlighting,
                                updateTrigger: updateTrigger
                            )
                        }
                        .frame(width: geometry.size.width * 0.8)

                        // Right panel - Results (20%)
                        ZStack(alignment: .topTrailing) {
                            Color(configManager.config.backgroundColor ?? NSColor.textBackgroundColor)
                                .ignoresSafeArea()

                            ResultsTextView(
                                results: instance.results,
                                textColor: Theme.current.syntaxColor(for: .results),
                                backgroundColor: configManager.config.backgroundColor ?? NSColor.textBackgroundColor,
                                fontSize: configManager.config.fontSize,
                                fontName: configManager.config.fontName ?? "SFMono-Regular"
                            )
                            .padding(.top, 16)
                            .padding(.trailing, 16)
                        }
                        .frame(width: geometry.size.width * 0.20)
                    }
                    .frame(minHeight: geometry.size.height)
                }
                .focusable()
                .focused($isViewFocused)
                .focusedValue(\.calculatorLeafId, leafId)
                .onAppear {
                    if isFocused {
                        isViewFocused = true
                    }
                }

                // Share button overlay with menu
                Menu {
                    Button(action: copyAsText) {
                        Label("Copy as Text", systemImage: "doc.on.doc")
                    }
                    Button(action: copyAsImage) {
                        Label("Copy as Image", systemImage: "photo")
                    }
                    Button(action: copyAsLink) {
                        Label("Copy as Link", systemImage: "link")
                    }
                } label: {
                    ZStack {
                        if showCopiedFeedback {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .medium))
                        } else {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 12, weight: .medium))
                        }
                    }
                    .foregroundColor(Color(nsColor: Theme.current.textColor).opacity(0.6))
                    .frame(width: 28, height: 28)
                    .background(Color(nsColor: Theme.current.backgroundColor).opacity(0.85))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(nsColor: Theme.current.textColor).opacity(0.15), lineWidth: 0.5))
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .padding(12)
                .help("Share calculation")
            }
        }
        .onChange(of: Theme.current) { _ in
            updateTrigger += 1
        }
        .onChange(of: configManager.config.backgroundColorHex) { _ in
            updateTrigger += 1
        }
    }

    private func getShareableLines() -> [(expression: String, result: String)] {
        let lines = instance.inputText.components(separatedBy: "\n")
        var imageLines: [(expression: String, result: String)] = []

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty && index < instance.results.count {
                let result = instance.results[index] ?? ""
                if !result.isEmpty {
                    imageLines.append((expression: trimmed, result: result))
                }
            }
        }

        return imageLines
    }

    private func copyAsText() {
        let imageLines = getShareableLines()
        guard !imageLines.isEmpty else { return }

        let text = ShareURLGenerator.generateText(lines: imageLines)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        showFeedback()
    }

    private func copyAsImage() {
        let imageLines = getShareableLines()
        guard !imageLines.isEmpty else { return }

        guard let image = CalculatorImageRenderer.render(
            lines: imageLines,
            theme: Theme.current,
            fontSize: configManager.config.fontSize,
            fontName: configManager.config.fontName ?? "SFMono-Regular"
        ) else { return }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])

        showFeedback()
    }

    private func copyAsLink() {
        let imageLines = getShareableLines()
        guard !imageLines.isEmpty else { return }

        let url = ShareURLGenerator.generate(lines: imageLines, theme: Theme.current.name)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(url.absoluteString, forType: .string)

        showFeedback()
    }

    private func showFeedback() {
        withAnimation {
            showCopiedFeedback = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showCopiedFeedback = false
            }
        }
    }
}

// MARK: - Custom NSTextView with fixed cursor width

class CustomNSTextView: NSTextView {
    override func drawInsertionPoint(in rect: NSRect, color: NSColor, turnedOn flag: Bool) {
        var customRect = rect
        customRect.size.width = 2
        super.drawInsertionPoint(in: customRect, color: color, turnedOn: flag)
    }

    override func setNeedsDisplay(_ rect: NSRect, avoidAdditionalLayout flag: Bool) {
        var customRect = rect
        if customRect.size.width > 2 {
            customRect.size.width = 2
        }
        super.setNeedsDisplay(customRect, avoidAdditionalLayout: flag)
    }

    // Remove focus ring
    override var focusRingType: NSFocusRingType {
        get { .none }
        set { }
    }


    // Handle Shift+Tab for unindent
    override func keyDown(with event: NSEvent) {
        // Check for backtab (Shift+Tab) using character interpretation
        if event.charactersIgnoringModifiers == "\t" && event.modifierFlags.contains(.shift) {
            unindentSelection()
            return
        }

        super.keyDown(with: event)
    }

    // Handle backtab command from system
    @objc override func insertBacktab(_ sender: Any?) {
        unindentSelection()
    }

    private func unindentSelection() {
        guard let textStorage = textStorage,
              let selectedRange = selectedRanges.first?.rangeValue else { return }

        let string = textStorage.string as NSString

        // Get the range of lines that contain the selection
        let lineRange = string.lineRange(for: selectedRange)

        var linesToProcess: [NSRange] = []
        var currentLocation = lineRange.location

        // Collect all line ranges
        while currentLocation < lineRange.upperBound {
            let thisLineRange = string.lineRange(for: NSRange(location: currentLocation, length: 0))
            linesToProcess.append(thisLineRange)
            currentLocation = thisLineRange.upperBound
        }

        // Process lines in reverse to maintain correct ranges
        textStorage.beginEditing()

        var totalRemoved = 0
        for lineRange in linesToProcess.reversed() {
            let line = string.substring(with: lineRange)

            // Determine how many characters to remove
            var charsToRemove = 0
            if line.hasPrefix("\t") {
                charsToRemove = 1
            } else if line.hasPrefix("    ") {
                charsToRemove = 4
            } else if line.hasPrefix("  ") {
                charsToRemove = 2
            } else if line.hasPrefix(" ") {
                charsToRemove = 1
            }

            if charsToRemove > 0 {
                let removeRange = NSRange(location: lineRange.location, length: charsToRemove)
                if shouldChangeText(in: removeRange, replacementString: "") {
                    textStorage.replaceCharacters(in: removeRange, with: "")
                    totalRemoved += charsToRemove
                }
            }
        }

        textStorage.endEditing()

        // Update selection to maintain position
        if totalRemoved > 0 {
            let newLocation = max(0, selectedRange.location - totalRemoved)
            setSelectedRange(NSRange(location: newLocation, length: 0))
        }

        didChangeText()
    }
}

// MARK: - Results Text View

struct ResultsTextView: NSViewRepresentable {
    let results: [String?]
    let textColor: NSColor
    let backgroundColor: NSColor
    let fontSize: Double
    let fontName: String

    func makeNSView(context: Context) -> NSTextView {
        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width, .height]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)

        let font = NSFont(name: fontName, size: fontSize) ?? .monospacedSystemFont(ofSize: fontSize, weight: .regular)
        textView.font = font
        textView.textColor = textColor
        textView.alignment = .right

        textView.wantsLayer = true
        textView.layer?.backgroundColor = backgroundColor.cgColor
        textView.drawsBackground = false
        textView.isRichText = false
        textView.textContainerInset = NSSize(width: 0, height: 0)

        // Match input text view paragraph style exactly
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineHeightMultiple = 1.0
        paragraph.paragraphSpacing = 0
        paragraph.lineSpacing = 8
        paragraph.alignment = .right
        textView.defaultParagraphStyle = paragraph

        return textView
    }

    func updateNSView(_ textView: NSTextView, context: Context) {
        let font = NSFont(name: fontName, size: fontSize) ?? .monospacedSystemFont(ofSize: fontSize, weight: .regular)
        textView.font = font
        textView.textColor = textColor
        textView.wantsLayer = true
        textView.layer?.backgroundColor = backgroundColor.cgColor

        // Update paragraph style
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineHeightMultiple = 1.0
        paragraph.paragraphSpacing = 0
        paragraph.lineSpacing = 8
        paragraph.alignment = .right
        textView.defaultParagraphStyle = paragraph

        // Build results text
        let resultsText = results.map { $0 ?? "" }.joined(separator: "\n")
        textView.string = resultsText

        // Apply text attributes
        let storage = textView.textStorage!
        let fullRange = NSRange(location: 0, length: storage.length)
        storage.addAttribute(.foregroundColor, value: textColor, range: fullRange)
        storage.addAttribute(.font, value: font, range: fullRange)
        storage.addAttribute(.paragraphStyle, value: paragraph, range: fullRange)
    }
}

// MARK: - Input Text View with Syntax Highlighting

struct InputTextView: NSViewRepresentable {
    @Binding var text: String
    let backgroundColor: NSColor
    let textColor: NSColor
    let fontSize: Double
    let fontName: String
    let syntaxHighlighting: Bool
    let updateTrigger: Int

    func makeNSView(context: Context) -> CustomNSTextView {
        let textView = CustomNSTextView()
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width, .height]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)

        let font = NSFont(name: fontName, size: fontSize) ?? .monospacedSystemFont(ofSize: fontSize, weight: .regular)

        textView.font = font
        textView.textColor = textColor

        // Use layer-based background instead of drawsBackground
        textView.wantsLayer = true
        textView.layer?.backgroundColor = backgroundColor.cgColor
        textView.drawsBackground = false
        textView.isRichText = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.delegate = context.coordinator
        textView.textContainerInset = NSSize(width: 16, height: 16)

        // Match SwiftUI text line spacing exactly
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineHeightMultiple = 1.0
        paragraph.paragraphSpacing = 0
        paragraph.lineSpacing = 8
        textView.defaultParagraphStyle = paragraph
        textView.typingAttributes = [
            .font: font,
            .paragraphStyle: paragraph
        ]

        return textView
    }

    func updateNSView(_ textView: CustomNSTextView, context: Context) {
        // Update font
        let font = NSFont(name: fontName, size: fontSize) ?? .monospacedSystemFont(ofSize: fontSize, weight: .regular)
        if textView.font != font {
            textView.font = font

            // Update paragraph style when font changes
            let paragraph = NSMutableParagraphStyle()
            paragraph.lineHeightMultiple = 1.0
            paragraph.paragraphSpacing = 0
            paragraph.lineSpacing = 8
            textView.defaultParagraphStyle = paragraph
            textView.typingAttributes = [
                .font: font,
                .paragraphStyle: paragraph
            ]
        }

        // Update colors using layer-based approach
        textView.textColor = textColor
        textView.wantsLayer = true
        textView.layer?.backgroundColor = backgroundColor.cgColor
        textView.drawsBackground = false

        // Update text and reapply highlighting
        if textView.string != text {
            textView.string = text
        }
        applySyntaxHighlighting(to: textView)
    }

    static func dismantleNSView(_ textView: CustomNSTextView, coordinator: Coordinator) {
        // Clean up NSTextView delegate to prevent ViewBridge issues
        textView.delegate = nil
        textView.string = ""  // Clear text content
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private func applySyntaxHighlighting(to textView: NSTextView) {
        guard syntaxHighlighting else { return }

        let storage = textView.textStorage!
        let fullRange = NSRange(location: 0, length: storage.length)

        // Preserve paragraph style for consistent line spacing
        let font = textView.font ?? NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineHeightMultiple = 1.0
        paragraph.paragraphSpacing = 0
        paragraph.lineSpacing = 8

        // Reset to theme text color and paragraph style
        storage.addAttribute(.foregroundColor, value: textColor, range: fullRange)
        storage.addAttribute(.paragraphStyle, value: paragraph, range: fullRange)
        storage.addAttribute(.font, value: font, range: fullRange)

        let text = storage.string
        let theme = Theme.current

        // Highlight numbers
        let numberPattern = "\\b\\d+(\\.\\d+)?\\b"
        if let regex = try? NSRegularExpression(pattern: numberPattern) {
            regex.enumerateMatches(in: text, range: fullRange) { match, _, _ in
                if let range = match?.range {
                    storage.addAttribute(.foregroundColor, value: theme.syntaxColor(for: .numbers), range: range)
                }
            }
        }

        // Highlight operators (symbols)
        let operatorPattern = "[+\\-*/()^%]"
        if let regex = try? NSRegularExpression(pattern: operatorPattern) {
            regex.enumerateMatches(in: text, range: fullRange) { match, _, _ in
                if let range = match?.range {
                    storage.addAttribute(.foregroundColor, value: theme.syntaxColor(for: .operators), range: range)
                }
            }
        }

        // Highlight word operators
        let wordOperatorPattern = "\\b(plus|minus|times|multiplied by|divided by|divide by|subtract|and|with)\\b"
        if let regex = try? NSRegularExpression(pattern: wordOperatorPattern, options: .caseInsensitive) {
            regex.enumerateMatches(in: text, range: fullRange) { match, _, _ in
                if let range = match?.range {
                    storage.addAttribute(.foregroundColor, value: theme.syntaxColor(for: .operators), range: range)
                }
            }
        }

        // Highlight currency units (including crypto)
        let currencyPattern = "\\b(USD|EUR|JPY|GBP|CNY|CHF|AUD|CAD|NZD|SEK|NOK|DKK|PLN|CZK|HUF|RON|BGN|HRK|RUB|TRY|BRL|MXN|ARS|CLP|COP|PEN|INR|IDR|MYR|PHP|THB|VND|KRW|TWD|HKD|SGD|ZAR|EGP|NGN|KES|GHS|XOF|XAF|MAD|TND|AED|SAR|QAR|KWD|BHD|OMR|ILS|JOD|LBP|IQD|IRR|AFN|PKR|BDT|NPR|LKR|MMK|KHR|LAK|MNT|KZT|UZS|TJS|KGS|TMT|GEL|AZN|AMD|BYN|MDL|UAH|RSD|MKD|ALL|BAM|ISK|BTC|ETH|BNB)\\b"
        if let regex = try? NSRegularExpression(pattern: currencyPattern, options: .caseInsensitive) {
            regex.enumerateMatches(in: text, range: fullRange) { match, _, _ in
                if let range = match?.range {
                    storage.addAttribute(.foregroundColor, value: theme.syntaxColor(for: .currency), range: range)
                }
            }
        }

        // Highlight measurement units (extended)
        let unitPattern = "\\b(km|mi|m|cm|mm|ft|in|yd|kg|g|mg|lb|oz|ton|L|mL|gal|qt|pt|cup|tbsp|tsp|°C|°F|K|ms|s|min|h|day|week|month|year|Hz|kHz|MHz|GHz|b|B|KB|MB|GB|TB|W|kW|MW|V|A|mA|Ω|J|cal|kcal|Pa|bar|atm|psi|mph|kmh|kph|meter|meters|centimeter|centimeters|millimeter|millimeters|kilometer|kilometers|foot|feet|inch|inches|yard|yards|mile|miles|sec|second|seconds|minute|minutes|hour|hours|days|weeks|months|years|kelvin|kelvins|celsius|fahrenheit|liter|liters|milliliter|milliliters|pint|pints|quart|quarts|gallon|gallons|teaspoon|teaspoons|tablespoon|tablespoons|gram|grams|kilogram|kilograms|tonne|tonnes|carat|carats|pound|pounds|stone|stones|ounce|ounces|bit|bits|byte|bytes|knot|knots|radian|radians|degree|degrees)\\b"
        if let regex = try? NSRegularExpression(pattern: unitPattern, options: .caseInsensitive) {
            regex.enumerateMatches(in: text, range: fullRange) { match, _, _ in
                if let range = match?.range {
                    storage.addAttribute(.foregroundColor, value: theme.syntaxColor(for: .units), range: range)
                }
            }
        }

        // Highlight scales
        let scalePattern = "\\b(k|kilo|thousand|M|mega|million|G|giga|billion|T|tera)\\b"
        if let regex = try? NSRegularExpression(pattern: scalePattern, options: .caseInsensitive) {
            regex.enumerateMatches(in: text, range: fullRange) { match, _, _ in
                if let range = match?.range {
                    storage.addAttribute(.foregroundColor, value: theme.syntaxColor(for: .units), range: range)
                }
            }
        }

        // Highlight keywords
        let keywordPattern = "\\b(in|to|as|of|per|from)\\b"
        if let regex = try? NSRegularExpression(pattern: keywordPattern, options: .caseInsensitive) {
            regex.enumerateMatches(in: text, range: fullRange) { match, _, _ in
                if let range = match?.range {
                    storage.addAttribute(.foregroundColor, value: theme.syntaxColor(for: .keywords), range: range)
                }
            }
        }

        // Highlight datetime keywords
        let datetimePattern = "\\b(time|now|today|tomorrow|yesterday|ago|before|after|next|last|this|between)\\b"
        if let regex = try? NSRegularExpression(pattern: datetimePattern, options: .caseInsensitive) {
            regex.enumerateMatches(in: text, range: fullRange) { match, _, _ in
                if let range = match?.range {
                    storage.addAttribute(.foregroundColor, value: theme.syntaxColor(for: .keywords), range: range)
                }
            }
        }

        // Highlight functions
        let functionPattern = "\\b(sin|cos|tan|asin|acos|atan|arcsin|arccos|arctan|sinh|cosh|tanh|sqrt|cbrt|ln|log|log10|log2|exp|abs|ceil|floor|round|min|max|pow|mod|gcd|lcm|factorial|rand|random)\\b"
        if let regex = try? NSRegularExpression(pattern: functionPattern, options: .caseInsensitive) {
            regex.enumerateMatches(in: text, range: fullRange) { match, _, _ in
                if let range = match?.range {
                    storage.addAttribute(.foregroundColor, value: theme.syntaxColor(for: .functions), range: range)
                }
            }
        }

        // Highlight constants
        let constantPattern = "\\b(pi|e|phi|tau|true|false)\\b"
        if let regex = try? NSRegularExpression(pattern: constantPattern, options: .caseInsensitive) {
            regex.enumerateMatches(in: text, range: fullRange) { match, _, _ in
                if let range = match?.range {
                    storage.addAttribute(.foregroundColor, value: theme.syntaxColor(for: .constants), range: range)
                }
            }
        }

        // Highlight variables (assignment pattern: word = )
        let variablePattern = "\\b([a-zA-Z_][a-zA-Z0-9_]*)\\s*="
        if let regex = try? NSRegularExpression(pattern: variablePattern) {
            regex.enumerateMatches(in: text, range: fullRange) { match, _, _ in
                if let range = match?.range(at: 1) {
                    storage.addAttribute(.foregroundColor, value: theme.syntaxColor(for: .variables), range: range)
                }
            }
        }

        // Highlight variable usage (words that are not numbers or keywords)
        let varUsagePattern = "\\b([a-zA-Z_][a-zA-Z0-9_]*)\\b"
        if let regex = try? NSRegularExpression(pattern: varUsagePattern) {
            regex.enumerateMatches(in: text, range: fullRange) { match, _, _ in
                if let range = match?.range {
                    // Only color if it's not already colored by other patterns
                    let currentColor = storage.attribute(.foregroundColor, at: range.location, effectiveRange: nil) as? NSColor
                    if currentColor == theme.syntaxColor(for: .text) {
                        storage.addAttribute(.foregroundColor, value: theme.syntaxColor(for: .variableUsage), range: range)
                    }
                }
            }
        }

        // Highlight equals sign in assignments
        let assignmentPattern = "\\s(=)\\s"
        if let regex = try? NSRegularExpression(pattern: assignmentPattern) {
            regex.enumerateMatches(in: text, range: fullRange) { match, _, _ in
                if let range = match?.range(at: 1) {
                    storage.addAttribute(.foregroundColor, value: theme.syntaxColor(for: .assignment), range: range)
                }
            }
        }

        // Highlight comments (both // and # styles) - MUST BE LAST to override other colors
        let commentPattern = "(//|#).*$"
        if let regex = try? NSRegularExpression(pattern: commentPattern, options: .anchorsMatchLines) {
            regex.enumerateMatches(in: text, range: fullRange) { match, _, _ in
                if let range = match?.range {
                    storage.addAttribute(.foregroundColor, value: theme.syntaxColor(for: .comments), range: range)
                }
            }
        }
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: InputTextView
        private weak var textView: NSTextView?

        init(_ parent: InputTextView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            self.textView = textView
            parent.text = textView.string
            parent.applySyntaxHighlighting(to: textView)
        }

        deinit {
            // Clean up text view delegate to prevent dangling references
            textView?.delegate = nil
        }
    }
}

// MARK: - FocusedValue Support

extension FocusedValues {
    var calculatorLeafId: SplitLeafID? {
        get { self[CalculatorLeafIDKey.self] }
        set { self[CalculatorLeafIDKey.self] = newValue }
    }

    struct CalculatorLeafIDKey: FocusedValueKey {
        typealias Value = SplitLeafID
    }
}
#endif
