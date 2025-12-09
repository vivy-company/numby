//
//  CalculatorImageRenderer.swift
//  Numby
//
//  Renders calculator content as a styled image with macOS window frame
//

import Foundation

#if os(macOS)
import AppKit
typealias RendererImage = NSImage
typealias RendererFont = NSFont
#elseif os(iOS) || os(visionOS)
import UIKit
typealias RendererImage = UIImage
typealias RendererFont = UIFont
#endif

struct CalculatorImageRenderer {

    // MARK: - Constants

    private static let titleBarHeight: CGFloat = 32
    private static let cornerRadius: CGFloat = 12
    private static let contentPadding: CGFloat = 20
    private static let trafficLightSize: CGFloat = 12
    private static let trafficLightSpacing: CGFloat = 8
    private static let lineSpacing: CGFloat = 6
    private static let minWidth: CGFloat = 350
    private static let maxWidth: CGFloat = 700

    // MARK: - Public API

    static func render(
        lines: [(expression: String, result: String)],
        theme: Theme,
        fontSize: CGFloat,
        fontName: String
    ) -> RendererImage? {
        guard !lines.isEmpty else { return nil }

        let scale: CGFloat = 2.0 // Retina
        let font = RendererFont(name: fontName, size: fontSize) ?? RendererFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)

        #if os(macOS)
        let titleFont = NSFont.systemFont(ofSize: 13, weight: .medium)
        #else
        let titleFont = UIFont.systemFont(ofSize: 13, weight: .medium)
        #endif

        // Build content
        let expressionLines = buildExpressionLines(lines: lines, theme: theme, font: font)
        let resultLines = buildResultLines(lines: lines, theme: theme, font: font)

        // Calculate sizes
        var maxExprWidth: CGFloat = 0
        var maxResultWidth: CGFloat = 0
        for (expr, res) in zip(expressionLines, resultLines) {
            let exprSize = expr.boundingRect(with: CGSize(width: 10000, height: 1000), options: [.usesLineFragmentOrigin], context: nil).size
            let resSize = res.boundingRect(with: CGSize(width: 10000, height: 1000), options: [.usesLineFragmentOrigin], context: nil).size
            maxExprWidth = max(maxExprWidth, exprSize.width)
            maxResultWidth = max(maxResultWidth, resSize.width)
        }

        let lineHeight = calculateLineHeight(font: font)
        let totalTextHeight = lineHeight * CGFloat(lines.count)
        let gapBetween: CGFloat = 40

        let frameWidth = max(minWidth, min(maxExprWidth + gapBetween + maxResultWidth + contentPadding * 2, maxWidth))
        let frameHeight = titleBarHeight + totalTextHeight + contentPadding * 2
        let shadowPadding: CGFloat = 24

        let totalWidth = frameWidth + shadowPadding * 2
        let totalHeight = frameHeight + shadowPadding * 2

        // Render
        #if os(macOS)
        let image = NSImage(size: CGSize(width: totalWidth * scale, height: totalHeight * scale))
        image.lockFocus()

        let transform = NSAffineTransform()
        transform.scale(by: scale)
        transform.concat()

        drawFrameMacOS(
            frameRect: CGRect(x: shadowPadding, y: shadowPadding, width: frameWidth, height: frameHeight),
            theme: theme,
            titleFont: titleFont,
            expressionLines: expressionLines,
            resultLines: resultLines,
            lineHeight: lineHeight
        )

        image.unlockFocus()
        return image

        #elseif os(iOS) || os(visionOS)
        let size = CGSize(width: totalWidth, height: totalHeight)
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { rendererContext in
            let context = rendererContext.cgContext

            drawFrameIOS(
                context: context,
                frameRect: CGRect(x: shadowPadding, y: shadowPadding, width: frameWidth, height: frameHeight),
                theme: theme,
                titleFont: titleFont,
                expressionLines: expressionLines,
                resultLines: resultLines,
                lineHeight: lineHeight
            )
        }
        return image
        #endif
    }

    // MARK: - Text Building

    private static func buildExpressionLines(
        lines: [(expression: String, result: String)],
        theme: Theme,
        font: RendererFont
    ) -> [NSAttributedString] {
        var result: [NSAttributedString] = []
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = lineSpacing

        for line in lines {
            let lineAttr = NSMutableAttributedString(string: line.expression)
            let fullRange = NSRange(location: 0, length: lineAttr.length)

            lineAttr.addAttribute(.font, value: font, range: fullRange)
            lineAttr.addAttribute(.foregroundColor, value: theme.textColor, range: fullRange)
            lineAttr.addAttribute(.paragraphStyle, value: paragraph, range: fullRange)

            applySyntaxHighlighting(to: lineAttr, in: fullRange, theme: theme)
            result.append(lineAttr)
        }

        return result
    }

    private static func buildResultLines(
        lines: [(expression: String, result: String)],
        theme: Theme,
        font: RendererFont
    ) -> [NSAttributedString] {
        var result: [NSAttributedString] = []
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = lineSpacing
        paragraph.alignment = .right

        for line in lines {
            let lineAttr = NSMutableAttributedString(string: line.result)
            let fullRange = NSRange(location: 0, length: lineAttr.length)

            lineAttr.addAttribute(.font, value: font, range: fullRange)
            lineAttr.addAttribute(.foregroundColor, value: theme.syntaxColor(for: .results), range: fullRange)
            lineAttr.addAttribute(.paragraphStyle, value: paragraph, range: fullRange)

            result.append(lineAttr)
        }

        return result
    }

    private static func calculateLineHeight(font: RendererFont) -> CGFloat {
        let testStr = NSAttributedString(string: "Xy", attributes: [.font: font])
        return testStr.boundingRect(with: CGSize(width: 1000, height: 1000), options: [.usesLineFragmentOrigin], context: nil).height + lineSpacing
    }

    // MARK: - macOS Drawing

    #if os(macOS)
    private static func drawFrameMacOS(
        frameRect: CGRect,
        theme: Theme,
        titleFont: NSFont,
        expressionLines: [NSAttributedString],
        resultLines: [NSAttributedString],
        lineHeight: CGFloat
    ) {
        // Shadow
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.3)
        shadow.shadowOffset = NSSize(width: 0, height: -8)
        shadow.shadowBlurRadius = 20
        shadow.set()

        // Frame background
        let framePath = NSBezierPath(roundedRect: frameRect, xRadius: cornerRadius, yRadius: cornerRadius)
        theme.backgroundColor.setFill()
        framePath.fill()

        // Clear shadow for rest
        NSShadow().set()

        // Title bar
        let titleBarRect = CGRect(x: frameRect.minX, y: frameRect.maxY - titleBarHeight, width: frameRect.width, height: titleBarHeight)
        let titleBarPath = NSBezierPath()
        titleBarPath.move(to: CGPoint(x: titleBarRect.minX + cornerRadius, y: titleBarRect.maxY))
        titleBarPath.appendArc(from: CGPoint(x: titleBarRect.maxX, y: titleBarRect.maxY), to: CGPoint(x: titleBarRect.maxX, y: titleBarRect.minY), radius: cornerRadius)
        titleBarPath.line(to: CGPoint(x: titleBarRect.maxX, y: titleBarRect.minY))
        titleBarPath.line(to: CGPoint(x: titleBarRect.minX, y: titleBarRect.minY))
        titleBarPath.appendArc(from: CGPoint(x: titleBarRect.minX, y: titleBarRect.maxY), to: CGPoint(x: titleBarRect.minX + cornerRadius, y: titleBarRect.maxY), radius: cornerRadius)
        titleBarPath.close()

        adjustedColor(theme.backgroundColor, by: 0.08).setFill()
        titleBarPath.fill()

        // Separator
        theme.textColor.withAlphaComponent(0.1).setStroke()
        let sepPath = NSBezierPath()
        sepPath.move(to: CGPoint(x: frameRect.minX, y: titleBarRect.minY))
        sepPath.line(to: CGPoint(x: frameRect.maxX, y: titleBarRect.minY))
        sepPath.lineWidth = 0.5
        sepPath.stroke()

        // Traffic lights
        drawTrafficLights(in: titleBarRect, startX: frameRect.minX + 16)

        // Title
        let title = "Numby"
        let attrs: [NSAttributedString.Key: Any] = [.font: titleFont, .foregroundColor: theme.textColor]
        let titleSize = title.size(withAttributes: attrs)
        title.draw(at: CGPoint(x: frameRect.midX - titleSize.width / 2, y: titleBarRect.midY - titleSize.height / 2), withAttributes: attrs)

        // Content - draw expressions on left, results on right
        let contentTop = titleBarRect.minY - contentPadding
        let contentLeft = frameRect.minX + contentPadding
        let contentRight = frameRect.maxX - contentPadding

        for (index, (expr, result)) in zip(expressionLines, resultLines).enumerated() {
            let y = contentTop - lineHeight * CGFloat(index + 1)

            // Draw expression (left aligned)
            expr.draw(at: CGPoint(x: contentLeft, y: y))

            // Draw result (right aligned)
            let resultSize = result.boundingRect(with: CGSize(width: 10000, height: 1000), options: [.usesLineFragmentOrigin], context: nil).size
            result.draw(at: CGPoint(x: contentRight - resultSize.width, y: y))
        }
    }

    private static func drawTrafficLights(in titleBarRect: CGRect, startX: CGFloat) {
        let colors: [NSColor] = [
            NSColor(red: 1.0, green: 0.373, blue: 0.337, alpha: 1.0),
            NSColor(red: 1.0, green: 0.741, blue: 0.180, alpha: 1.0),
            NSColor(red: 0.153, green: 0.788, blue: 0.247, alpha: 1.0)
        ]

        for (i, color) in colors.enumerated() {
            let x = startX + CGFloat(i) * (trafficLightSize + trafficLightSpacing)
            let rect = CGRect(x: x, y: titleBarRect.midY - trafficLightSize / 2, width: trafficLightSize, height: trafficLightSize)
            color.setFill()
            NSBezierPath(ovalIn: rect).fill()
        }
    }
    #endif

    // MARK: - iOS/visionOS Drawing

    #if os(iOS) || os(visionOS)
    private static func drawFrameIOS(
        context: CGContext,
        frameRect: CGRect,
        theme: Theme,
        titleFont: UIFont,
        expressionLines: [NSAttributedString],
        resultLines: [NSAttributedString],
        lineHeight: CGFloat
    ) {
        // Shadow
        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: 8), blur: 20, color: UIColor.black.withAlphaComponent(0.3).cgColor)

        // Frame background
        let framePath = UIBezierPath(roundedRect: frameRect, cornerRadius: cornerRadius)
        context.addPath(framePath.cgPath)
        context.setFillColor(theme.backgroundColor.cgColor)
        context.fillPath()
        context.restoreGState()

        // Title bar at top
        let titleBarRect = CGRect(x: frameRect.minX, y: frameRect.minY, width: frameRect.width, height: titleBarHeight)

        let titleBarPath = UIBezierPath()
        titleBarPath.move(to: CGPoint(x: titleBarRect.minX, y: titleBarRect.maxY))
        titleBarPath.addLine(to: CGPoint(x: titleBarRect.maxX, y: titleBarRect.maxY))
        titleBarPath.addLine(to: CGPoint(x: titleBarRect.maxX, y: titleBarRect.minY + cornerRadius))
        titleBarPath.addArc(withCenter: CGPoint(x: titleBarRect.maxX - cornerRadius, y: titleBarRect.minY + cornerRadius), radius: cornerRadius, startAngle: 0, endAngle: -.pi / 2, clockwise: false)
        titleBarPath.addLine(to: CGPoint(x: titleBarRect.minX + cornerRadius, y: titleBarRect.minY))
        titleBarPath.addArc(withCenter: CGPoint(x: titleBarRect.minX + cornerRadius, y: titleBarRect.minY + cornerRadius), radius: cornerRadius, startAngle: -.pi / 2, endAngle: .pi, clockwise: false)
        titleBarPath.close()

        context.addPath(titleBarPath.cgPath)
        context.setFillColor(adjustedColorIOS(theme.backgroundColor, by: 0.08).cgColor)
        context.fillPath()

        // Separator
        context.setStrokeColor(theme.textColor.withAlphaComponent(0.1).cgColor)
        context.setLineWidth(0.5)
        context.move(to: CGPoint(x: frameRect.minX, y: titleBarRect.maxY))
        context.addLine(to: CGPoint(x: frameRect.maxX, y: titleBarRect.maxY))
        context.strokePath()

        // Traffic lights
        let trafficColors: [UIColor] = [
            UIColor(red: 1.0, green: 0.373, blue: 0.337, alpha: 1.0),
            UIColor(red: 1.0, green: 0.741, blue: 0.180, alpha: 1.0),
            UIColor(red: 0.153, green: 0.788, blue: 0.247, alpha: 1.0)
        ]

        for (i, color) in trafficColors.enumerated() {
            let x = frameRect.minX + 16 + CGFloat(i) * (trafficLightSize + trafficLightSpacing)
            let rect = CGRect(x: x, y: titleBarRect.midY - trafficLightSize / 2, width: trafficLightSize, height: trafficLightSize)
            context.setFillColor(color.cgColor)
            context.fillEllipse(in: rect)
        }

        // Title
        let title = "Numby"
        let attrs: [NSAttributedString.Key: Any] = [.font: titleFont, .foregroundColor: theme.textColor]
        let titleSize = title.size(withAttributes: attrs)
        let titlePoint = CGPoint(x: frameRect.midX - titleSize.width / 2, y: titleBarRect.midY - titleSize.height / 2)
        title.draw(at: titlePoint, withAttributes: attrs)

        // Content - draw expressions on left, results on right
        let contentTop = titleBarRect.maxY + contentPadding
        let contentLeft = frameRect.minX + contentPadding
        let contentRight = frameRect.maxX - contentPadding

        for (index, (expr, result)) in zip(expressionLines, resultLines).enumerated() {
            let y = contentTop + lineHeight * CGFloat(index)

            // Draw expression (left aligned)
            expr.draw(at: CGPoint(x: contentLeft, y: y))

            // Draw result (right aligned)
            let resultSize = result.boundingRect(with: CGSize(width: 10000, height: 1000), options: [.usesLineFragmentOrigin], context: nil).size
            result.draw(at: CGPoint(x: contentRight - resultSize.width, y: y))
        }
    }

    private static func adjustedColorIOS(_ color: UIColor, by amount: CGFloat) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        let avg = (r + g + b) / 3.0
        let adjust = avg > 0.5 ? -amount : amount
        return UIColor(red: max(0, min(1, r + adjust)), green: max(0, min(1, g + adjust)), blue: max(0, min(1, b + adjust)), alpha: a)
    }
    #endif

    // MARK: - Helpers

    #if os(macOS)
    private static func adjustedColor(_ color: NSColor, by amount: CGFloat) -> NSColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        (color.usingColorSpace(.deviceRGB) ?? color).getRed(&r, green: &g, blue: &b, alpha: &a)
        let avg = (r + g + b) / 3.0
        let adjust = avg > 0.5 ? -amount : amount
        return NSColor(red: max(0, min(1, r + adjust)), green: max(0, min(1, g + adjust)), blue: max(0, min(1, b + adjust)), alpha: a)
    }
    #endif

    // MARK: - Syntax Highlighting

    private static func applySyntaxHighlighting(to storage: NSMutableAttributedString, in range: NSRange, theme: Theme) {
        let text = storage.string

        applyPattern("\\b\\d+(\\.\\d+)?\\b", color: theme.syntaxColor(for: .numbers), to: storage, text: text, searchRange: range)
        applyPattern("[+\\-*/()^%]", color: theme.syntaxColor(for: .operators), to: storage, text: text, searchRange: range)
        applyPattern("\\b(USD|EUR|JPY|GBP|CNY|RUB|BYN|BTC|ETH)\\b", color: theme.syntaxColor(for: .currency), to: storage, text: text, searchRange: range, options: .caseInsensitive)
        applyPattern("\\b(km|m|cm|kg|g|lb|oz|mi|ft|in)\\b", color: theme.syntaxColor(for: .units), to: storage, text: text, searchRange: range, options: .caseInsensitive)
        applyPattern("\\b(in|to|as|of|per|from)\\b", color: theme.syntaxColor(for: .keywords), to: storage, text: text, searchRange: range, options: .caseInsensitive)
        applyPattern("\\b(sin|cos|tan|sqrt|ln|log|abs|round)\\b", color: theme.syntaxColor(for: .functions), to: storage, text: text, searchRange: range, options: .caseInsensitive)
        applyPattern("\\b(pi|e|true|false)\\b", color: theme.syntaxColor(for: .constants), to: storage, text: text, searchRange: range, options: .caseInsensitive)
        applyPattern("(//|#).*$", color: theme.syntaxColor(for: .comments), to: storage, text: text, searchRange: range, options: .anchorsMatchLines)
    }

    private static func applyPattern(_ pattern: String, color: PlatformColor, to storage: NSMutableAttributedString, text: String, searchRange: NSRange, options: NSRegularExpression.Options = []) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return }
        regex.enumerateMatches(in: text, range: searchRange) { match, _, _ in
            if let r = match?.range, r.location != NSNotFound {
                storage.addAttribute(.foregroundColor, value: color, range: r)
            }
        }
    }
}
