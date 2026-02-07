//
//  CalculatorSurfaceView.swift
//  Numby
//
//  Individual calculator surface - renders one calculator instance with input/results panels
//

#if os(macOS)
import SwiftUI
import Combine

private let calculatorLineSpacing: CGFloat = 8

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
    @State private var activeGroupStart: Int = 0
    @State private var activeGroupEnd: Int = 0
    @State private var inputContentHeight: CGFloat = 0

    private var activeLineHighlightColor: NSColor? {
        guard configManager.config.activeLineHighlight else { return nil }
        let base = configManager.config.backgroundColor ?? NSColor.textBackgroundColor
        let intensity = min(max(configManager.config.activeLineHighlightIntensity, 0.0), 0.3)
        let overlay: NSColor = base.isDark ? .white : .black
        return base.blended(with: overlay, fraction: CGFloat(intensity))
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    ZStack(alignment: .topLeading) {
                        Color(configManager.config.backgroundColor ?? NSColor.textBackgroundColor)
                            .ignoresSafeArea()

                        HStack(spacing: 0) {
                            // Left panel - Input (80%)
                            InputTextView(
                                text: $instance.inputText,
                                cursorPosition: $instance.cursorPosition,
                                activeLine: $instance.activeLine,
                                lineCount: $instance.lineCount,
                                activeGroupStart: $activeGroupStart,
                                activeGroupEnd: $activeGroupEnd,
                                contentHeight: $inputContentHeight,
                                numby: instance.numby,
                                backgroundColor: configManager.config.backgroundColor ?? NSColor.textBackgroundColor,
                                textColor: Theme.current.syntaxColor(for: .text),
                                fontSize: configManager.config.fontSize,
                                fontName: configManager.config.fontName ?? "SFMono-Regular",
                                syntaxHighlighting: configManager.config.syntaxHighlighting,
                                activeLineHighlightColor: activeLineHighlightColor,
                                activeLineHighlightEnabled: configManager.config.activeLineHighlight,
                                minHeight: geometry.size.height,
                                updateTrigger: updateTrigger
                            )
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            .frame(width: geometry.size.width * 0.8)

                            // Right panel - Results (20%)
                            ResultsTextView(
                                results: instance.results,
                                textColor: Theme.current.syntaxColor(for: .results),
                                backgroundColor: configManager.config.backgroundColor ?? NSColor.textBackgroundColor,
                                fontSize: configManager.config.fontSize,
                                fontName: configManager.config.fontName ?? "SFMono-Regular",
                                activeLine: instance.activeLine,
                                lineCount: instance.lineCount,
                                activeLineHighlightColor: activeLineHighlightColor,
                                activeLineHighlightEnabled: configManager.config.activeLineHighlight,
                                activeGroupStart: activeGroupStart,
                                activeGroupEnd: activeGroupEnd,
                                minHeight: max(geometry.size.height, inputContentHeight)
                            )
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                            .frame(width: geometry.size.width * 0.20)
                        }
                        .frame(minHeight: geometry.size.height)
                    }
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
                ShareMenuButton(
                    backgroundColor: configManager.config.backgroundColor ?? NSColor.textBackgroundColor,
                    showCopiedFeedback: showCopiedFeedback,
                    onCopyAsText: copyAsText,
                    onCopyAsImage: copyAsImage,
                    onCopyAsLink: copyAsLink
                )
                .frame(width: 32, height: 32)
                .padding(12)
            }

                // Copied toast notification
                if showCopiedFeedback {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                        Text("Copied!")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.75))
                    .clipShape(Capsule())
                    .transition(.scale.combined(with: .opacity))
                }
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
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showCopiedFeedback = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.2)) {
                showCopiedFeedback = false
            }
        }
    }
}

// MARK: - Share Menu Button (NSViewRepresentable for full size control)

struct ShareMenuButton: NSViewRepresentable {
    let backgroundColor: NSColor
    let showCopiedFeedback: Bool
    let onCopyAsText: () -> Void
    let onCopyAsImage: () -> Void
    let onCopyAsLink: () -> Void

    func makeNSView(context: Context) -> NSButton {
        let button = NSButton()
        button.bezelStyle = .regularSquare
        button.isBordered = false
        button.wantsLayer = true
        button.layer?.cornerRadius = 6
        button.layer?.backgroundColor = backgroundColor.withAlphaComponent(0.95).cgColor

        updateButtonImage(button, showCheckmark: showCopiedFeedback)

        button.target = context.coordinator
        button.action = #selector(Coordinator.showMenu(_:))

        return button
    }

    func updateNSView(_ button: NSButton, context: Context) {
        button.layer?.backgroundColor = backgroundColor.withAlphaComponent(0.95).cgColor
        updateButtonImage(button, showCheckmark: showCopiedFeedback)
        context.coordinator.parent = self
    }

    private func updateButtonImage(_ button: NSButton, showCheckmark: Bool) {
        let symbolName = showCheckmark ? "checkmark" : "square.and.arrow.up"
        let config = NSImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Share")?
            .withSymbolConfiguration(config) {
            button.image = image
            button.contentTintColor = NSColor.secondaryLabelColor
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: ShareMenuButton

        init(_ parent: ShareMenuButton) {
            self.parent = parent
        }

        @objc func showMenu(_ sender: NSButton) {
            let menu = NSMenu()

            let textItem = NSMenuItem(title: "Copy as Text", action: #selector(copyAsText), keyEquivalent: "")
            textItem.target = self
            textItem.image = NSImage(systemSymbolName: "doc.on.doc", accessibilityDescription: nil)
            menu.addItem(textItem)

            let imageItem = NSMenuItem(title: "Copy as Image", action: #selector(copyAsImage), keyEquivalent: "")
            imageItem.target = self
            imageItem.image = NSImage(systemSymbolName: "photo", accessibilityDescription: nil)
            menu.addItem(imageItem)

            let linkItem = NSMenuItem(title: "Copy as Link", action: #selector(copyAsLink), keyEquivalent: "")
            linkItem.target = self
            linkItem.image = NSImage(systemSymbolName: "link", accessibilityDescription: nil)
            menu.addItem(linkItem)

            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.height), in: sender)
        }

        @objc func copyAsText() {
            parent.onCopyAsText()
        }

        @objc func copyAsImage() {
            parent.onCopyAsImage()
        }

        @objc func copyAsLink() {
            parent.onCopyAsLink()
        }
    }
}

// MARK: - Custom NSTextView with fixed cursor width

class ActiveLineTextView: NSTextView {
    var activeLineIndex: Int = 0 { didSet { needsDisplay = true } }
    var activeLineHighlightColor: NSColor? { didSet { needsDisplay = true } }
    var isActiveLineHighlightEnabled: Bool = false { didSet { needsDisplay = true } }
    var activeLineStart: Int = 0 { didSet { needsDisplay = true } }
    var activeLineEnd: Int = 0 { didSet { needsDisplay = true } }
    var minimumContentHeight: CGFloat = 1 {
        didSet {
            if oldValue != minimumContentHeight {
                invalidateIntrinsicContentSize()
            }
        }
    }

    override var intrinsicContentSize: NSSize {
        guard let layoutManager = layoutManager, let textContainer = textContainer else {
            return super.intrinsicContentSize
        }
        let used = layoutManager.usedRect(for: textContainer)
        var height = ceil(used.height + textContainerInset.height * 2)
        let extra = layoutManager.extraLineFragmentRect
        if extra.height > 0 {
            height += ceil(extra.height)
        }
        let minHeight = max(1, minimumContentHeight)
        return NSSize(width: NSView.noIntrinsicMetric, height: max(height, minHeight))
    }

    override func didChangeText() {
        super.didChangeText()
        invalidateIntrinsicContentSize()
    }

    override func draw(_ dirtyRect: NSRect) {
        if isActiveLineHighlightEnabled, let color = activeLineHighlightColor {
            drawActiveLineBackground(color)
        }
        super.draw(dirtyRect)
    }

    private func drawActiveLineBackground(_ color: NSColor) {
        guard let layoutManager = layoutManager,
              let textStorage = textStorage else {
            return
        }

        let text = textStorage.string as NSString
        let startLine = min(activeLineStart, activeLineEnd)
        let endLine = max(activeLineStart, activeLineEnd)
        guard startLine >= 0, endLine >= 0 else { return }

        let font = self.font ?? .monospacedSystemFont(ofSize: 14, weight: .regular)
        let lineHeight = layoutManager.defaultLineHeight(for: font) + calculatorLineSpacing

        for lineIndex in startLine...endLine {
            guard let lineRange = lineRange(for: lineIndex, in: text) else { continue }
            let glyphRange = layoutManager.glyphRange(forCharacterRange: lineRange, actualCharacterRange: nil)

            if glyphRange.length == 0 {
                if lineRange.location == text.length {
                    let extraRect = layoutManager.extraLineFragmentRect
                    if !extraRect.isEmpty {
                        var highlightRect = extraRect
                        let origin = textContainerOrigin
                        highlightRect.origin.y += origin.y
                        highlightRect.origin.x = 0
                        highlightRect.size.width = bounds.width
                        highlightRect.size.height = max(highlightRect.height, lineHeight)
                        color.setFill()
                        highlightRect.fill()
                    }
                }
                continue
            }

            layoutManager.enumerateLineFragments(forGlyphRange: glyphRange) { rect, _, _, fragmentGlyphRange, _ in
                var highlightRect = layoutManager.lineFragmentUsedRect(
                    forGlyphAt: fragmentGlyphRange.location,
                    effectiveRange: nil
                )
                if highlightRect.height == 0 { highlightRect = rect }
                highlightRect.size.height = max(highlightRect.height, lineHeight)
                let origin = self.textContainerOrigin
                highlightRect.origin.y += origin.y
                highlightRect.origin.x = 0
                highlightRect.size.width = self.bounds.width
                color.setFill()
                highlightRect.fill()
            }
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

class CustomNSTextView: ActiveLineTextView {
    override func drawInsertionPoint(in rect: NSRect, color: NSColor, turnedOn flag: Bool) {
        var customRect = rect
        customRect.size.width = 2
        super.drawInsertionPoint(in: customRect, color: color, turnedOn: flag)
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
    let activeLine: Int
    let lineCount: Int
    let activeLineHighlightColor: NSColor?
    let activeLineHighlightEnabled: Bool
    let activeGroupStart: Int
    let activeGroupEnd: Int
    let minHeight: CGFloat

    func makeNSView(context: Context) -> ActiveLineTextView {
        let textView = ActiveLineTextView()
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
        textView.layer?.backgroundColor = NSColor.clear.cgColor
        textView.drawsBackground = false
        textView.isRichText = false
        textView.textContainerInset = NSSize(width: 16, height: 16)
        textView.minimumContentHeight = minHeight

        // Match input text view paragraph style exactly
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineHeightMultiple = 1.0
        paragraph.paragraphSpacing = 0
        paragraph.lineSpacing = 0
        let baseLineHeight = textView.layoutManager?.defaultLineHeight(for: font) ?? font.ascender - font.descender
        let lineHeight = baseLineHeight + calculatorLineSpacing
        paragraph.minimumLineHeight = lineHeight
        paragraph.maximumLineHeight = lineHeight
        paragraph.alignment = .right
        let baselineOffset = (lineHeight - baseLineHeight) / 2
        textView.defaultParagraphStyle = paragraph
        textView.typingAttributes = [
            .font: font,
            .paragraphStyle: paragraph,
            .baselineOffset: baselineOffset
        ]

        return textView
    }

    func updateNSView(_ textView: ActiveLineTextView, context: Context) {
        let font = NSFont(name: fontName, size: fontSize) ?? .monospacedSystemFont(ofSize: fontSize, weight: .regular)
        textView.font = font
        textView.textColor = textColor
        textView.wantsLayer = true
        textView.layer?.backgroundColor = NSColor.clear.cgColor
        textView.activeLineIndex = activeLine
        textView.activeLineStart = activeGroupStart
        textView.activeLineEnd = activeGroupEnd
        textView.activeLineHighlightColor = activeLineHighlightColor
        textView.isActiveLineHighlightEnabled = activeLineHighlightEnabled
        textView.textContainerInset = NSSize(width: 16, height: 16)
        textView.minimumContentHeight = minHeight

        // Update paragraph style
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineHeightMultiple = 1.0
        paragraph.paragraphSpacing = 0
        paragraph.lineSpacing = 0
        let baseLineHeight = textView.layoutManager?.defaultLineHeight(for: font) ?? font.ascender - font.descender
        let lineHeight = baseLineHeight + calculatorLineSpacing
        paragraph.minimumLineHeight = lineHeight
        paragraph.maximumLineHeight = lineHeight
        paragraph.alignment = .right
        let baselineOffset = (lineHeight - baseLineHeight) / 2
        textView.defaultParagraphStyle = paragraph

        // Build results text (pad to input line count for sync)
        let desiredCount = max(lineCount, results.count)
        var paddedResults = results.map { $0 ?? "" }
        if paddedResults.count < desiredCount {
            paddedResults.append(contentsOf: Array(repeating: "", count: desiredCount - paddedResults.count))
        }
        let resultsText = paddedResults.joined(separator: "\n")
        if let storage = textView.textStorage {
            let textChanged = storage.string != resultsText
            if textChanged {
                let attributed = NSMutableAttributedString(string: resultsText)
                attributed.addAttribute(.foregroundColor, value: textColor, range: NSRange(location: 0, length: attributed.length))
                attributed.addAttribute(.font, value: font, range: NSRange(location: 0, length: attributed.length))
                attributed.addAttribute(.paragraphStyle, value: paragraph, range: NSRange(location: 0, length: attributed.length))
                attributed.addAttribute(.baselineOffset, value: baselineOffset, range: NSRange(location: 0, length: attributed.length))
                storage.setAttributedString(attributed)
            } else {
                let fullRange = NSRange(location: 0, length: storage.length)
                storage.addAttribute(.foregroundColor, value: textColor, range: fullRange)
                storage.addAttribute(.font, value: font, range: fullRange)
                storage.addAttribute(.paragraphStyle, value: paragraph, range: fullRange)
                storage.addAttribute(.baselineOffset, value: baselineOffset, range: fullRange)
            }
        }
    }
}

// MARK: - Input Text View with Syntax Highlighting

struct InputTextView: NSViewRepresentable {
    @Binding var text: String
    @Binding var cursorPosition: Int
    @Binding var activeLine: Int
    @Binding var lineCount: Int
    @Binding var activeGroupStart: Int
    @Binding var activeGroupEnd: Int
    @Binding var contentHeight: CGFloat
    let numby: NumbyWrapper
    let backgroundColor: NSColor
    let textColor: NSColor
    let fontSize: Double
    let fontName: String
    let syntaxHighlighting: Bool
    let activeLineHighlightColor: NSColor?
    let activeLineHighlightEnabled: Bool
    let minHeight: CGFloat
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
        textView.layer?.backgroundColor = NSColor.clear.cgColor
        textView.drawsBackground = false
        textView.isRichText = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.delegate = context.coordinator
        textView.textContainerInset = NSSize(width: 16, height: 16)
        textView.minimumContentHeight = minHeight
        textView.allowsUndo = true
        // NSTextView manages its own undo manager; it will integrate with SwiftUI automatically.

        // Match SwiftUI text line spacing exactly
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineHeightMultiple = 1.0
        paragraph.paragraphSpacing = 0
        paragraph.lineSpacing = 0
        let baseLineHeight = textView.layoutManager?.defaultLineHeight(for: font) ?? font.ascender - font.descender
        let lineHeight = baseLineHeight + calculatorLineSpacing
        paragraph.minimumLineHeight = lineHeight
        paragraph.maximumLineHeight = lineHeight
        let baselineOffset = (lineHeight - baseLineHeight) / 2
        textView.defaultParagraphStyle = paragraph
        textView.typingAttributes = [
            .font: font,
            .paragraphStyle: paragraph,
            .baselineOffset: baselineOffset
        ]

        textView.activeLineIndex = activeLine
        textView.activeLineStart = activeGroupStart
        textView.activeLineEnd = activeGroupEnd
        textView.activeLineHighlightColor = activeLineHighlightColor
        textView.isActiveLineHighlightEnabled = activeLineHighlightEnabled

        return textView
    }

    func updateNSView(_ textView: CustomNSTextView, context: Context) {
        context.coordinator.isUpdatingView = true
        defer { context.coordinator.isUpdatingView = false }

        // Update font
        let font = NSFont(name: fontName, size: fontSize) ?? .monospacedSystemFont(ofSize: fontSize, weight: .regular)
        let fontChanged = textView.font != font
        if fontChanged {
            textView.font = font

            // Update paragraph style when font changes
            let paragraph = NSMutableParagraphStyle()
            paragraph.lineHeightMultiple = 1.0
            paragraph.paragraphSpacing = 0
            paragraph.lineSpacing = 0
            let baseLineHeight = textView.layoutManager?.defaultLineHeight(for: font) ?? font.ascender - font.descender
            let lineHeight = baseLineHeight + calculatorLineSpacing
            paragraph.minimumLineHeight = lineHeight
            paragraph.maximumLineHeight = lineHeight
            let baselineOffset = (lineHeight - baseLineHeight) / 2
            textView.defaultParagraphStyle = paragraph
            textView.typingAttributes = [
                .font: font,
                .paragraphStyle: paragraph,
                .baselineOffset: baselineOffset
            ]
        }

        // Update colors using layer-based approach
        let colorChanged = textView.textColor != textColor
        textView.textColor = textColor
        textView.wantsLayer = true
        textView.layer?.backgroundColor = NSColor.clear.cgColor
        textView.drawsBackground = false
        textView.activeLineIndex = activeLine
        textView.activeLineHighlightColor = activeLineHighlightColor
        textView.isActiveLineHighlightEnabled = activeLineHighlightEnabled
        textView.minimumContentHeight = minHeight

        let textChanged = textView.string != text
        // Update text and reapply highlighting
        if textChanged {
            textView.string = text
            context.coordinator.updateLineCountAsync(for: text)
        }
        let forceHighlight = fontChanged
            || colorChanged
            || (context.coordinator.lastSyntaxHighlighting != syntaxHighlighting)
        context.coordinator.applyHighlightIfNeeded(for: textView, force: forceHighlight)
        context.coordinator.updateActiveLineRange(for: textView)
        context.coordinator.updateContentHeight(for: textView)
    }

    static func dismantleNSView(_ textView: CustomNSTextView, coordinator: Coordinator) {
        // Clean up NSTextView delegate to prevent ViewBridge issues
        textView.delegate = nil
        textView.string = ""  // Clear text content
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

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

    private func applySyntaxHighlighting(to textView: NSTextView) {
        guard syntaxHighlighting else { return }

        let storage = textView.textStorage!
        let fullRange = NSRange(location: 0, length: storage.length)

        // Preserve paragraph style for consistent line spacing
        let font = textView.font ?? NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineHeightMultiple = 1.0
        paragraph.paragraphSpacing = 0
        paragraph.lineSpacing = 0
        let baseLineHeight = textView.layoutManager?.defaultLineHeight(for: font) ?? font.ascender - font.descender
        let lineHeight = baseLineHeight + calculatorLineSpacing
        paragraph.minimumLineHeight = lineHeight
        paragraph.maximumLineHeight = lineHeight

        // Reset to theme text color and paragraph style
        storage.addAttribute(.foregroundColor, value: textColor, range: fullRange)
        storage.addAttribute(.paragraphStyle, value: paragraph, range: fullRange)
        storage.addAttribute(.font, value: font, range: fullRange)
        let baselineOffset = (lineHeight - baseLineHeight) / 2
        storage.addAttribute(.baselineOffset, value: baselineOffset, range: fullRange)

        let text = storage.string
        let theme = Theme.current
        let spans = numby.highlightSpans(for: text)
        applyHighlightSpans(spans, to: textView, theme: theme)
    }

    private func applyHighlightSpans(
        _ spans: [NumbyHighlightSpan],
        to textView: NSTextView,
        theme: Theme
    ) {
        guard let storage = textView.textStorage else { return }
        let fullRange = NSRange(location: 0, length: storage.length)

        let font = textView.font ?? NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineHeightMultiple = 1.0
        paragraph.paragraphSpacing = 0
        paragraph.lineSpacing = 0
        let baseLineHeight = textView.layoutManager?.defaultLineHeight(for: font) ?? font.ascender - font.descender
        let lineHeight = baseLineHeight + calculatorLineSpacing
        paragraph.minimumLineHeight = lineHeight
        paragraph.maximumLineHeight = lineHeight
        let baselineOffset = (lineHeight - baseLineHeight) / 2

        storage.beginEditing()
        storage.addAttribute(.foregroundColor, value: textColor, range: fullRange)
        storage.addAttribute(.paragraphStyle, value: paragraph, range: fullRange)
        storage.addAttribute(.font, value: font, range: fullRange)
        storage.addAttribute(.baselineOffset, value: baselineOffset, range: fullRange)

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
    }

    private func applyBaseAttributes(to textView: NSTextView) {
        guard let storage = textView.textStorage else { return }
        let fullRange = NSRange(location: 0, length: storage.length)
        let font = textView.font ?? NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineHeightMultiple = 1.0
        paragraph.paragraphSpacing = 0
        paragraph.lineSpacing = 0
        let baseLineHeight = textView.layoutManager?.defaultLineHeight(for: font) ?? font.ascender - font.descender
        let lineHeight = baseLineHeight + calculatorLineSpacing
        paragraph.minimumLineHeight = lineHeight
        paragraph.maximumLineHeight = lineHeight
        let baselineOffset = (lineHeight - baseLineHeight) / 2
        storage.beginEditing()
        storage.addAttribute(.foregroundColor, value: textColor, range: fullRange)
        storage.addAttribute(.paragraphStyle, value: paragraph, range: fullRange)
        storage.addAttribute(.font, value: font, range: fullRange)
        storage.addAttribute(.baselineOffset, value: baselineOffset, range: fullRange)
        storage.endEditing()
    }
    private func colorForHighlightKind(_ kindValue: UInt8, theme: Theme) -> NSColor {
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

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: InputTextView
        private weak var textView: NSTextView?
        var isUpdatingView: Bool = false
        private var lastHighlightedText: String = ""
        private var didApplyPlainAttributesForLargeText: Bool = false
        private let highlightCharLimit: Int = 200000
        private let syncHighlightCharLimit: Int = 8000
        private let highlightQueue = DispatchQueue(label: "numby.highlight", qos: .userInitiated)
        private var highlightToken: Int = 0
        var lastSyntaxHighlighting: Bool?

        init(_ parent: InputTextView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            guard !isUpdatingView else { return }
            self.textView = textView
            parent.text = textView.string
            parent.cursorPosition = textView.selectedRange().location
            parent.activeLine = parent.lineIndex(for: textView.string, cursorPosition: textView.selectedRange().location)
            parent.lineCount = parent.totalLineCount(for: textView.string)
            if let activeView = textView as? ActiveLineTextView {
                activeView.activeLineIndex = parent.activeLine
            }
            updateActiveLineRange(for: textView)
            updateContentHeight(for: textView)
            applyHighlightIfNeeded(for: textView, force: true)
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            guard !isUpdatingView else { return }
            self.textView = textView
            parent.cursorPosition = textView.selectedRange().location
            parent.activeLine = parent.lineIndex(for: textView.string, cursorPosition: textView.selectedRange().location)
            if let activeView = textView as? ActiveLineTextView {
                activeView.activeLineIndex = parent.activeLine
            }
            updateActiveLineRange(for: textView)
            updateContentHeight(for: textView)
        }

        func updateLineCountAsync(for text: String) {
            let count = parent.totalLineCount(for: text)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if self.parent.lineCount != count {
                    self.parent.lineCount = count
                }
            }
        }

        func applyHighlightIfNeeded(for textView: NSTextView, force: Bool) {
            let text = textView.string
            let syntaxEnabled = parent.syntaxHighlighting
            if !force,
               lastSyntaxHighlighting == syntaxEnabled,
               lastHighlightedText == text {
                return
            }
            lastHighlightedText = text
            lastSyntaxHighlighting = syntaxEnabled

            if !syntaxEnabled {
                parent.applyBaseAttributes(to: textView)
                return
            }

            if text.count > highlightCharLimit {
                parent.applyBaseAttributes(to: textView)
                didApplyPlainAttributesForLargeText = true
                return
            }

            didApplyPlainAttributesForLargeText = false

            if text.count <= syncHighlightCharLimit {
                let theme = Theme.current
                let spans = parent.numby.highlightSpans(for: text)
                parent.applyHighlightSpans(spans, to: textView, theme: theme)
                return
            }

            highlightToken &+= 1
            let token = highlightToken
            let theme = Theme.current
            highlightQueue.async { [weak self, weak textView] in
                guard let self = self else { return }
                let spans = self.parent.numby.highlightSpans(for: text)
                DispatchQueue.main.async {
                    guard let textView = textView else { return }
                    guard token == self.highlightToken else { return }
                    guard textView.string == text else { return }
                    self.parent.applyHighlightSpans(spans, to: textView, theme: theme)
                }
            }
        }

        deinit {
            // Clean up text view delegate to prevent dangling references
            textView?.delegate = nil
        }

        func updateActiveLineRange(for textView: NSTextView) {
            let cursor = textView.selectedRange().location
            let group = parent
                .numby
                .groupBounds(for: textView.string, cursorUTF16: cursor)
                ?? (start: parent.activeLine, end: parent.activeLine)
            let start = max(0, group.start)
            let end = max(start, group.end)

            if let activeView = textView as? ActiveLineTextView {
                activeView.activeLineStart = start
                activeView.activeLineEnd = end
            }

            if isUpdatingView {
                DispatchQueue.main.async { [weak self] in
                    self?.parent.activeGroupStart = start
                    self?.parent.activeGroupEnd = end
                }
            } else {
                parent.activeGroupStart = start
                parent.activeGroupEnd = end
            }
        }

        func updateContentHeight(for textView: NSTextView) {
            guard let layoutManager = textView.layoutManager,
                  let textContainer = textView.textContainer else {
                return
            }
            let used = layoutManager.usedRect(for: textContainer)
            var height = ceil(used.height + textView.textContainerInset.height * 2)
            let extra = layoutManager.extraLineFragmentRect
            if extra.height > 0 {
                height += ceil(extra.height)
            }
            if isUpdatingView {
                DispatchQueue.main.async { [weak self] in
                    self?.parent.contentHeight = height
                }
            } else {
                parent.contentHeight = height
            }
        }
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

    private func totalLineCount(for text: String) -> Int {
        max(1, text.filter { $0 == "\n" }.count + 1)
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
