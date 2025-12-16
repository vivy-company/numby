package com.numby.ui.theme

import android.app.Activity
import androidx.compose.material3.ColorScheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

/**
 * Available Catppuccin themes
 */
enum class NumbyThemeVariant(val displayName: String) {
    LATTE("Latte"),
    FRAPPE("Frappé"),
    MACCHIATO("Macchiato"),
    MOCHA("Mocha")
}

// Composition local for current syntax colors
val LocalSyntaxColors = staticCompositionLocalOf { MochaSyntax }

// Latte Color Scheme (Light)
private val LatteColorScheme = lightColorScheme(
    primary = CatppuccinLatte.Blue,
    onPrimary = CatppuccinLatte.Base,
    primaryContainer = CatppuccinLatte.Lavender,
    onPrimaryContainer = CatppuccinLatte.Text,
    secondary = CatppuccinLatte.Mauve,
    onSecondary = CatppuccinLatte.Base,
    secondaryContainer = CatppuccinLatte.Surface0,
    onSecondaryContainer = CatppuccinLatte.Text,
    tertiary = CatppuccinLatte.Teal,
    onTertiary = CatppuccinLatte.Base,
    tertiaryContainer = CatppuccinLatte.Surface0,
    onTertiaryContainer = CatppuccinLatte.Text,
    error = CatppuccinLatte.Red,
    onError = CatppuccinLatte.Base,
    errorContainer = CatppuccinLatte.Maroon,
    onErrorContainer = CatppuccinLatte.Text,
    background = CatppuccinLatte.Base,
    onBackground = CatppuccinLatte.Text,
    surface = CatppuccinLatte.Base,
    onSurface = CatppuccinLatte.Text,
    surfaceVariant = CatppuccinLatte.Mantle,
    onSurfaceVariant = CatppuccinLatte.Subtext0,
    outline = CatppuccinLatte.Overlay0,
    outlineVariant = CatppuccinLatte.Surface1,
    scrim = CatppuccinLatte.Crust,
    inverseSurface = CatppuccinLatte.Text,
    inverseOnSurface = CatppuccinLatte.Base,
    inversePrimary = CatppuccinLatte.Sapphire,
    surfaceTint = CatppuccinLatte.Blue
)

// Frappé Color Scheme (Muted Dark)
private val FrappeColorScheme = darkColorScheme(
    primary = CatppuccinFrappe.Blue,
    onPrimary = CatppuccinFrappe.Crust,
    primaryContainer = CatppuccinFrappe.Surface0,
    onPrimaryContainer = CatppuccinFrappe.Lavender,
    secondary = CatppuccinFrappe.Mauve,
    onSecondary = CatppuccinFrappe.Crust,
    secondaryContainer = CatppuccinFrappe.Surface0,
    onSecondaryContainer = CatppuccinFrappe.Lavender,
    tertiary = CatppuccinFrappe.Teal,
    onTertiary = CatppuccinFrappe.Crust,
    tertiaryContainer = CatppuccinFrappe.Surface0,
    onTertiaryContainer = CatppuccinFrappe.Sky,
    error = CatppuccinFrappe.Red,
    onError = CatppuccinFrappe.Crust,
    errorContainer = CatppuccinFrappe.Surface0,
    onErrorContainer = CatppuccinFrappe.Red,
    background = CatppuccinFrappe.Base,
    onBackground = CatppuccinFrappe.Text,
    surface = CatppuccinFrappe.Base,
    onSurface = CatppuccinFrappe.Text,
    surfaceVariant = CatppuccinFrappe.Mantle,
    onSurfaceVariant = CatppuccinFrappe.Subtext0,
    outline = CatppuccinFrappe.Overlay0,
    outlineVariant = CatppuccinFrappe.Surface1,
    scrim = CatppuccinFrappe.Crust,
    inverseSurface = CatppuccinFrappe.Text,
    inverseOnSurface = CatppuccinFrappe.Base,
    inversePrimary = CatppuccinFrappe.Blue,
    surfaceTint = CatppuccinFrappe.Blue
)

// Macchiato Color Scheme (Darker)
private val MacchiatoColorScheme = darkColorScheme(
    primary = CatppuccinMacchiato.Blue,
    onPrimary = CatppuccinMacchiato.Crust,
    primaryContainer = CatppuccinMacchiato.Surface0,
    onPrimaryContainer = CatppuccinMacchiato.Lavender,
    secondary = CatppuccinMacchiato.Mauve,
    onSecondary = CatppuccinMacchiato.Crust,
    secondaryContainer = CatppuccinMacchiato.Surface0,
    onSecondaryContainer = CatppuccinMacchiato.Lavender,
    tertiary = CatppuccinMacchiato.Teal,
    onTertiary = CatppuccinMacchiato.Crust,
    tertiaryContainer = CatppuccinMacchiato.Surface0,
    onTertiaryContainer = CatppuccinMacchiato.Sky,
    error = CatppuccinMacchiato.Red,
    onError = CatppuccinMacchiato.Crust,
    errorContainer = CatppuccinMacchiato.Surface0,
    onErrorContainer = CatppuccinMacchiato.Red,
    background = CatppuccinMacchiato.Base,
    onBackground = CatppuccinMacchiato.Text,
    surface = CatppuccinMacchiato.Base,
    onSurface = CatppuccinMacchiato.Text,
    surfaceVariant = CatppuccinMacchiato.Mantle,
    onSurfaceVariant = CatppuccinMacchiato.Subtext0,
    outline = CatppuccinMacchiato.Overlay0,
    outlineVariant = CatppuccinMacchiato.Surface1,
    scrim = CatppuccinMacchiato.Crust,
    inverseSurface = CatppuccinMacchiato.Text,
    inverseOnSurface = CatppuccinMacchiato.Base,
    inversePrimary = CatppuccinMacchiato.Blue,
    surfaceTint = CatppuccinMacchiato.Blue
)

// Mocha Color Scheme (Darkest)
private val MochaColorScheme = darkColorScheme(
    primary = CatppuccinMocha.Blue,
    onPrimary = CatppuccinMocha.Crust,
    primaryContainer = CatppuccinMocha.Surface0,
    onPrimaryContainer = CatppuccinMocha.Lavender,
    secondary = CatppuccinMocha.Mauve,
    onSecondary = CatppuccinMocha.Crust,
    secondaryContainer = CatppuccinMocha.Surface0,
    onSecondaryContainer = CatppuccinMocha.Lavender,
    tertiary = CatppuccinMocha.Teal,
    onTertiary = CatppuccinMocha.Crust,
    tertiaryContainer = CatppuccinMocha.Surface0,
    onTertiaryContainer = CatppuccinMocha.Sky,
    error = CatppuccinMocha.Red,
    onError = CatppuccinMocha.Crust,
    errorContainer = CatppuccinMocha.Surface0,
    onErrorContainer = CatppuccinMocha.Red,
    background = CatppuccinMocha.Base,
    onBackground = CatppuccinMocha.Text,
    surface = CatppuccinMocha.Base,
    onSurface = CatppuccinMocha.Text,
    surfaceVariant = CatppuccinMocha.Mantle,
    onSurfaceVariant = CatppuccinMocha.Subtext0,
    outline = CatppuccinMocha.Overlay0,
    outlineVariant = CatppuccinMocha.Surface1,
    scrim = CatppuccinMocha.Crust,
    inverseSurface = CatppuccinMocha.Text,
    inverseOnSurface = CatppuccinMocha.Base,
    inversePrimary = CatppuccinMocha.Blue,
    surfaceTint = CatppuccinMocha.Blue
)

fun getColorScheme(variant: NumbyThemeVariant): ColorScheme {
    return when (variant) {
        NumbyThemeVariant.LATTE -> LatteColorScheme
        NumbyThemeVariant.FRAPPE -> FrappeColorScheme
        NumbyThemeVariant.MACCHIATO -> MacchiatoColorScheme
        NumbyThemeVariant.MOCHA -> MochaColorScheme
    }
}

fun getSyntaxColors(variant: NumbyThemeVariant): SyntaxColors {
    return when (variant) {
        NumbyThemeVariant.LATTE -> LatteSyntax
        NumbyThemeVariant.FRAPPE -> FrappeSyntax
        NumbyThemeVariant.MACCHIATO -> MacchiatoSyntax
        NumbyThemeVariant.MOCHA -> MochaSyntax
    }
}

fun getSyntaxColorsByName(themeName: String): SyntaxColors {
    // First check if it's a legacy Catppuccin theme name
    return when (themeName.lowercase()) {
        "latte" -> LatteSyntax
        "frappe" -> FrappeSyntax
        "macchiato" -> MacchiatoSyntax
        "mocha" -> MochaSyntax
        else -> {
            // Search in AllThemes
            getThemeByName(themeName)?.syntax ?: MochaSyntax
        }
    }
}

fun getColorSchemeByName(themeName: String): ColorScheme {
    val syntax = getSyntaxColorsByName(themeName)
    val theme = getThemeByName(themeName)
    val isDark = theme?.isDark ?: true

    return if (isDark) {
        darkColorScheme(
            primary = syntax.keyword,
            onPrimary = syntax.background,
            primaryContainer = syntax.function,
            onPrimaryContainer = syntax.text,
            secondary = syntax.function,
            onSecondary = syntax.background,
            secondaryContainer = syntax.comment,
            onSecondaryContainer = syntax.text,
            tertiary = syntax.currency,
            onTertiary = syntax.background,
            error = syntax.operator,
            onError = syntax.background,
            background = syntax.background,
            onBackground = syntax.text,
            surface = syntax.background,
            onSurface = syntax.text,
            surfaceVariant = syntax.comment,
            onSurfaceVariant = syntax.text,
            outline = syntax.comment
        )
    } else {
        lightColorScheme(
            primary = syntax.keyword,
            onPrimary = syntax.background,
            primaryContainer = syntax.function,
            onPrimaryContainer = syntax.text,
            secondary = syntax.function,
            onSecondary = syntax.background,
            secondaryContainer = syntax.comment,
            onSecondaryContainer = syntax.text,
            tertiary = syntax.currency,
            onTertiary = syntax.background,
            error = syntax.operator,
            onError = syntax.background,
            background = syntax.background,
            onBackground = syntax.text,
            surface = syntax.background,
            onSurface = syntax.text,
            surfaceVariant = syntax.comment,
            onSurfaceVariant = syntax.text,
            outline = syntax.comment
        )
    }
}

fun isDarkTheme(variant: NumbyThemeVariant): Boolean {
    return variant != NumbyThemeVariant.LATTE
}

@Composable
fun NumbyTheme(
    themeVariant: NumbyThemeVariant = NumbyThemeVariant.MOCHA,
    content: @Composable () -> Unit
) {
    val colorScheme = getColorScheme(themeVariant)
    val syntaxColors = getSyntaxColors(themeVariant)
    val darkTheme = isDarkTheme(themeVariant)

    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            @Suppress("DEPRECATION")
            window.statusBarColor = colorScheme.background.toArgb()
            @Suppress("DEPRECATION")
            window.navigationBarColor = colorScheme.background.toArgb()
            // Set decorView background to prevent flicker during navigation
            window.decorView.setBackgroundColor(colorScheme.background.toArgb())
            WindowCompat.getInsetsController(window, view).apply {
                isAppearanceLightStatusBars = !darkTheme
                isAppearanceLightNavigationBars = !darkTheme
            }
        }
    }

    CompositionLocalProvider(LocalSyntaxColors provides syntaxColors) {
        MaterialTheme(
            colorScheme = colorScheme,
            typography = Typography,
            content = content
        )
    }
}

// Legacy theme support for backward compatibility
@Composable
fun NumbyTheme(
    darkTheme: Boolean = true,
    content: @Composable () -> Unit
) {
    val variant = if (darkTheme) NumbyThemeVariant.MOCHA else NumbyThemeVariant.LATTE
    NumbyTheme(themeVariant = variant, content = content)
}

// Theme by name - supports all 300+ themes
@Composable
fun NumbyThemeByName(
    themeName: String = "Catppuccin Mocha",
    content: @Composable () -> Unit
) {
    val colorScheme = getColorSchemeByName(themeName)
    val syntaxColors = getSyntaxColorsByName(themeName)
    val theme = getThemeByName(themeName)
    val darkTheme = theme?.isDark ?: true

    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            @Suppress("DEPRECATION")
            window.statusBarColor = colorScheme.background.toArgb()
            @Suppress("DEPRECATION")
            window.navigationBarColor = colorScheme.background.toArgb()
            // Set decorView background to prevent flicker during navigation
            window.decorView.setBackgroundColor(colorScheme.background.toArgb())
            WindowCompat.getInsetsController(window, view).apply {
                isAppearanceLightStatusBars = !darkTheme
                isAppearanceLightNavigationBars = !darkTheme
            }
        }
    }

    CompositionLocalProvider(LocalSyntaxColors provides syntaxColors) {
        MaterialTheme(
            colorScheme = colorScheme,
            typography = Typography,
            content = content
        )
    }
}
