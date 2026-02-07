#if os(iOS) || os(visionOS)
import UIKit

extension UIColor {
    var isDark: Bool {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        // Calculate relative luminance
        let luminance = 0.2126 * red + 0.7152 * green + 0.0722 * blue
        return luminance < 0.5
    }

    func blended(with color: UIColor, fraction: CGFloat) -> UIColor {
        let clamped = max(0, min(1, fraction))
        var r1: CGFloat = 0
        var g1: CGFloat = 0
        var b1: CGFloat = 0
        var a1: CGFloat = 0
        var r2: CGFloat = 0
        var g2: CGFloat = 0
        var b2: CGFloat = 0
        var a2: CGFloat = 0

        guard getRed(&r1, green: &g1, blue: &b1, alpha: &a1),
              color.getRed(&r2, green: &g2, blue: &b2, alpha: &a2) else {
            return self
        }

        return UIColor(
            red: r1 + (r2 - r1) * clamped,
            green: g1 + (g2 - g1) * clamped,
            blue: b1 + (b2 - b1) * clamped,
            alpha: a1 + (a2 - a1) * clamped
        )
    }
}
#endif
