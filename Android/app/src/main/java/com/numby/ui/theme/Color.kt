package com.numby.ui.theme

import androidx.compose.ui.graphics.Color

/**
 * Syntax highlighting colors - matches iOS SyntaxColors structure
 */
data class SyntaxColors(
    val text: Color,
    val background: Color,
    val number: Color,
    val operator: Color,
    val keyword: Color,
    val function: Color,
    val constant: Color,
    val variable: Color,
    val variableUsage: Color,
    val assignment: Color,
    val currency: Color,
    val unit: Color,
    val results: Color,
    val comment: Color
)

/**
 * Theme definition - matches iOS Theme structure
 */
data class NumbyTheme(
    val name: String,
    val syntax: SyntaxColors
) {
    val isDark: Boolean
        get() {
            // Calculate luminance of background to determine if dark
            val r = syntax.background.red
            val g = syntax.background.green
            val b = syntax.background.blue
            val luminance = 0.299 * r + 0.587 * g + 0.114 * b
            return luminance < 0.5
        }
}

// Helper to create Color from hex string
fun String.toColor(): Color {
    val hex = this.removePrefix("#")
    return Color(
        red = hex.substring(0, 2).toInt(16) / 255f,
        green = hex.substring(2, 4).toInt(16) / 255f,
        blue = hex.substring(4, 6).toInt(16) / 255f
    )
}

// Catppuccin base colors (kept for backward compatibility)
object CatppuccinLatte {
    val Rosewater = Color(0xFFdc8a78)
    val Flamingo = Color(0xFFdd7878)
    val Pink = Color(0xFFea76cb)
    val Mauve = Color(0xFF8839ef)
    val Red = Color(0xFFd20f39)
    val Maroon = Color(0xFFe64553)
    val Peach = Color(0xFFfe640b)
    val Yellow = Color(0xFFdf8e1d)
    val Green = Color(0xFF40a02b)
    val Teal = Color(0xFF179299)
    val Sky = Color(0xFF04a5e5)
    val Sapphire = Color(0xFF209fb5)
    val Blue = Color(0xFF1e66f5)
    val Lavender = Color(0xFF7287fd)
    val Text = Color(0xFF4c4f69)
    val Subtext1 = Color(0xFF5c5f77)
    val Subtext0 = Color(0xFF6c6f85)
    val Overlay2 = Color(0xFF7c7f93)
    val Overlay1 = Color(0xFF8c8fa1)
    val Overlay0 = Color(0xFF9ca0b0)
    val Surface2 = Color(0xFFacb0be)
    val Surface1 = Color(0xFFbcc0cc)
    val Surface0 = Color(0xFFccd0da)
    val Base = Color(0xFFeff1f5)
    val Mantle = Color(0xFFe6e9ef)
    val Crust = Color(0xFFdce0e8)
}

object CatppuccinFrappe {
    val Rosewater = Color(0xFFf2d5cf)
    val Flamingo = Color(0xFFeebebe)
    val Pink = Color(0xFFf4b8e4)
    val Mauve = Color(0xFFca9ee6)
    val Red = Color(0xFFe78284)
    val Maroon = Color(0xFFea999c)
    val Peach = Color(0xFFef9f76)
    val Yellow = Color(0xFFe5c890)
    val Green = Color(0xFFa6d189)
    val Teal = Color(0xFF81c8be)
    val Sky = Color(0xFF99d1db)
    val Sapphire = Color(0xFF85c1dc)
    val Blue = Color(0xFF8caaee)
    val Lavender = Color(0xFFbabbf1)
    val Text = Color(0xFFc6d0f5)
    val Subtext1 = Color(0xFFb5bfe2)
    val Subtext0 = Color(0xFFa5adce)
    val Overlay2 = Color(0xFF949cbb)
    val Overlay1 = Color(0xFF838ba7)
    val Overlay0 = Color(0xFF737994)
    val Surface2 = Color(0xFF626880)
    val Surface1 = Color(0xFF51576d)
    val Surface0 = Color(0xFF414559)
    val Base = Color(0xFF303446)
    val Mantle = Color(0xFF292c3c)
    val Crust = Color(0xFF232634)
}

object CatppuccinMacchiato {
    val Rosewater = Color(0xFFf4dbd6)
    val Flamingo = Color(0xFFf0c6c6)
    val Pink = Color(0xFFf5bde6)
    val Mauve = Color(0xFFc6a0f6)
    val Red = Color(0xFFed8796)
    val Maroon = Color(0xFFee99a0)
    val Peach = Color(0xFFf5a97f)
    val Yellow = Color(0xFFeed49f)
    val Green = Color(0xFFa6da95)
    val Teal = Color(0xFF8bd5ca)
    val Sky = Color(0xFF91d7e3)
    val Sapphire = Color(0xFF7dc4e4)
    val Blue = Color(0xFF8aadf4)
    val Lavender = Color(0xFFb7bdf8)
    val Text = Color(0xFFcad3f5)
    val Subtext1 = Color(0xFFb8c0e0)
    val Subtext0 = Color(0xFFa5adcb)
    val Overlay2 = Color(0xFF939ab7)
    val Overlay1 = Color(0xFF8087a2)
    val Overlay0 = Color(0xFF6e738d)
    val Surface2 = Color(0xFF5b6078)
    val Surface1 = Color(0xFF494d64)
    val Surface0 = Color(0xFF363a4f)
    val Base = Color(0xFF24273a)
    val Mantle = Color(0xFF1e2030)
    val Crust = Color(0xFF181926)
}

object CatppuccinMocha {
    val Rosewater = Color(0xFFf5e0dc)
    val Flamingo = Color(0xFFf2cdcd)
    val Pink = Color(0xFFf5c2e7)
    val Mauve = Color(0xFFcba6f7)
    val Red = Color(0xFFf38ba8)
    val Maroon = Color(0xFFeba0ac)
    val Peach = Color(0xFFfab387)
    val Yellow = Color(0xFFf9e2af)
    val Green = Color(0xFFa6e3a1)
    val Teal = Color(0xFF94e2d5)
    val Sky = Color(0xFF89dceb)
    val Sapphire = Color(0xFF74c7ec)
    val Blue = Color(0xFF89b4fa)
    val Lavender = Color(0xFFb4befe)
    val Text = Color(0xFFcdd6f4)
    val Subtext1 = Color(0xFFbac2de)
    val Subtext0 = Color(0xFFa6adc8)
    val Overlay2 = Color(0xFF9399b2)
    val Overlay1 = Color(0xFF7f849c)
    val Overlay0 = Color(0xFF6c7086)
    val Surface2 = Color(0xFF585b70)
    val Surface1 = Color(0xFF45475a)
    val Surface0 = Color(0xFF313244)
    val Base = Color(0xFF1e1e2e)
    val Mantle = Color(0xFF181825)
    val Crust = Color(0xFF11111b)
}

// Syntax colors for each theme variant
val LatteSyntax = SyntaxColors(
    text = CatppuccinLatte.Text,
    background = CatppuccinLatte.Base,
    number = CatppuccinLatte.Peach,
    operator = CatppuccinLatte.Sky,
    keyword = CatppuccinLatte.Mauve,
    function = CatppuccinLatte.Blue,
    constant = CatppuccinLatte.Peach,
    variable = CatppuccinLatte.Flamingo,
    variableUsage = CatppuccinLatte.Text,
    assignment = CatppuccinLatte.Teal,
    currency = CatppuccinLatte.Green,
    unit = CatppuccinLatte.Yellow,
    results = CatppuccinLatte.Green,
    comment = CatppuccinLatte.Overlay1
)

val FrappeSyntax = SyntaxColors(
    text = CatppuccinFrappe.Text,
    background = CatppuccinFrappe.Base,
    number = CatppuccinFrappe.Peach,
    operator = CatppuccinFrappe.Sky,
    keyword = CatppuccinFrappe.Mauve,
    function = CatppuccinFrappe.Blue,
    constant = CatppuccinFrappe.Peach,
    variable = CatppuccinFrappe.Flamingo,
    variableUsage = CatppuccinFrappe.Text,
    assignment = CatppuccinFrappe.Teal,
    currency = CatppuccinFrappe.Green,
    unit = CatppuccinFrappe.Yellow,
    results = CatppuccinFrappe.Green,
    comment = CatppuccinFrappe.Overlay1
)

val MacchiatoSyntax = SyntaxColors(
    text = CatppuccinMacchiato.Text,
    background = CatppuccinMacchiato.Base,
    number = CatppuccinMacchiato.Peach,
    operator = CatppuccinMacchiato.Sky,
    keyword = CatppuccinMacchiato.Mauve,
    function = CatppuccinMacchiato.Blue,
    constant = CatppuccinMacchiato.Peach,
    variable = CatppuccinMacchiato.Flamingo,
    variableUsage = CatppuccinMacchiato.Text,
    assignment = CatppuccinMacchiato.Teal,
    currency = CatppuccinMacchiato.Green,
    unit = CatppuccinMacchiato.Yellow,
    results = CatppuccinMacchiato.Green,
    comment = CatppuccinMacchiato.Overlay1
)

val MochaSyntax = SyntaxColors(
    text = CatppuccinMocha.Text,
    background = CatppuccinMocha.Base,
    number = CatppuccinMocha.Peach,
    operator = CatppuccinMocha.Sky,
    keyword = CatppuccinMocha.Mauve,
    function = CatppuccinMocha.Blue,
    constant = CatppuccinMocha.Peach,
    variable = CatppuccinMocha.Flamingo,
    variableUsage = CatppuccinMocha.Text,
    assignment = CatppuccinMocha.Teal,
    currency = CatppuccinMocha.Green,
    unit = CatppuccinMocha.Yellow,
    results = CatppuccinMocha.Green,
    comment = CatppuccinMocha.Overlay1
)
