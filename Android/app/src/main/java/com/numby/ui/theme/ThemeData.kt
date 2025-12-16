package com.numby.ui.theme

import androidx.compose.ui.graphics.Color

/**
 * Extended theme collection (300+ themes from iTerm2, Ghostty, etc.)
 * Popular themes included, with search functionality
 */

// Theme helper to create from hex
private fun hex(value: String): Color {
    val hex = value.removePrefix("#")
    return Color(
        red = hex.substring(0, 2).toInt(16) / 255f,
        green = hex.substring(2, 4).toInt(16) / 255f,
        blue = hex.substring(4, 6).toInt(16) / 255f
    )
}

// All available themes
val AllThemes: List<NumbyTheme> = listOf(
    // Catppuccin themes (built-in)
    NumbyTheme("Catppuccin Latte", LatteSyntax),
    NumbyTheme("Catppuccin Frappé", FrappeSyntax),
    NumbyTheme("Catppuccin Macchiato", MacchiatoSyntax),
    NumbyTheme("Catppuccin Mocha", MochaSyntax),

    // Popular dark themes
    NumbyTheme(
        name = "Dracula",
        syntax = SyntaxColors(
            text = hex("#f8f8f2"),
            background = hex("#282a36"),
            number = hex("#bd93f9"),
            operator = hex("#ff5555"),
            keyword = hex("#ff79c6"),
            function = hex("#f1fa8c"),
            constant = hex("#bd93f9"),
            variable = hex("#8be9fd"),
            variableUsage = hex("#ff79c6"),
            assignment = hex("#ff5555"),
            currency = hex("#50fa7b"),
            unit = hex("#8be9fd"),
            results = hex("#50fa7b"),
            comment = hex("#6272a4")
        )
    ),
    NumbyTheme(
        name = "Nord",
        syntax = SyntaxColors(
            text = hex("#d8dee9"),
            background = hex("#2e3440"),
            number = hex("#81a1c1"),
            operator = hex("#bf616a"),
            keyword = hex("#b48ead"),
            function = hex("#ebcb8b"),
            constant = hex("#81a1c1"),
            variable = hex("#88c0d0"),
            variableUsage = hex("#b48ead"),
            assignment = hex("#bf616a"),
            currency = hex("#a3be8c"),
            unit = hex("#88c0d0"),
            results = hex("#a3be8c"),
            comment = hex("#596377")
        )
    ),
    NumbyTheme(
        name = "TokyoNight",
        syntax = SyntaxColors(
            text = hex("#c0caf5"),
            background = hex("#1a1b26"),
            number = hex("#7aa2f7"),
            operator = hex("#f7768e"),
            keyword = hex("#bb9af7"),
            function = hex("#e0af68"),
            constant = hex("#7aa2f7"),
            variable = hex("#7dcfff"),
            variableUsage = hex("#bb9af7"),
            assignment = hex("#f7768e"),
            currency = hex("#9ece6a"),
            unit = hex("#7dcfff"),
            results = hex("#9ece6a"),
            comment = hex("#414868")
        )
    ),
    NumbyTheme(
        name = "TokyoNight Storm",
        syntax = SyntaxColors(
            text = hex("#c0caf5"),
            background = hex("#24283b"),
            number = hex("#7aa2f7"),
            operator = hex("#f7768e"),
            keyword = hex("#bb9af7"),
            function = hex("#e0af68"),
            constant = hex("#7aa2f7"),
            variable = hex("#7dcfff"),
            variableUsage = hex("#bb9af7"),
            assignment = hex("#f7768e"),
            currency = hex("#9ece6a"),
            unit = hex("#7dcfff"),
            results = hex("#9ece6a"),
            comment = hex("#4e5575")
        )
    ),
    NumbyTheme(
        name = "TokyoNight Moon",
        syntax = SyntaxColors(
            text = hex("#c8d3f5"),
            background = hex("#222436"),
            number = hex("#82aaff"),
            operator = hex("#ff757f"),
            keyword = hex("#c099ff"),
            function = hex("#ffc777"),
            constant = hex("#82aaff"),
            variable = hex("#86e1fc"),
            variableUsage = hex("#c099ff"),
            assignment = hex("#ff757f"),
            currency = hex("#c3e88d"),
            unit = hex("#86e1fc"),
            results = hex("#c3e88d"),
            comment = hex("#444a73")
        )
    ),
    NumbyTheme(
        name = "TokyoNight Day",
        syntax = SyntaxColors(
            text = hex("#3760bf"),
            background = hex("#e1e2e7"),
            number = hex("#2e7de9"),
            operator = hex("#f52a65"),
            keyword = hex("#9854f1"),
            function = hex("#8c6c3e"),
            constant = hex("#2e7de9"),
            variable = hex("#007197"),
            variableUsage = hex("#9854f1"),
            assignment = hex("#f52a65"),
            currency = hex("#587539"),
            unit = hex("#007197"),
            results = hex("#587539"),
            comment = hex("#a1a6c5")
        )
    ),
    NumbyTheme(
        name = "Gruvbox Dark",
        syntax = SyntaxColors(
            text = hex("#ebdbb2"),
            background = hex("#282828"),
            number = hex("#458588"),
            operator = hex("#cc241d"),
            keyword = hex("#b16286"),
            function = hex("#d79921"),
            constant = hex("#458588"),
            variable = hex("#689d6a"),
            variableUsage = hex("#b16286"),
            assignment = hex("#cc241d"),
            currency = hex("#98971a"),
            unit = hex("#689d6a"),
            results = hex("#98971a"),
            comment = hex("#928374")
        )
    ),
    NumbyTheme(
        name = "Gruvbox Light",
        syntax = SyntaxColors(
            text = hex("#3c3836"),
            background = hex("#fbf1c7"),
            number = hex("#458588"),
            operator = hex("#cc241d"),
            keyword = hex("#b16286"),
            function = hex("#d79921"),
            constant = hex("#458588"),
            variable = hex("#689d6a"),
            variableUsage = hex("#b16286"),
            assignment = hex("#cc241d"),
            currency = hex("#98971a"),
            unit = hex("#689d6a"),
            results = hex("#98971a"),
            comment = hex("#928374")
        )
    ),
    NumbyTheme(
        name = "Gruvbox Material Dark",
        syntax = SyntaxColors(
            text = hex("#d4be98"),
            background = hex("#282828"),
            number = hex("#7daea3"),
            operator = hex("#ea6962"),
            keyword = hex("#d3869b"),
            function = hex("#d8a657"),
            constant = hex("#7daea3"),
            variable = hex("#89b482"),
            variableUsage = hex("#d3869b"),
            assignment = hex("#ea6962"),
            currency = hex("#a9b665"),
            unit = hex("#89b482"),
            results = hex("#a9b665"),
            comment = hex("#7c6f64")
        )
    ),
    NumbyTheme(
        name = "GitHub Dark",
        syntax = SyntaxColors(
            text = hex("#8b949e"),
            background = hex("#101216"),
            number = hex("#6ca4f8"),
            operator = hex("#f78166"),
            keyword = hex("#db61a2"),
            function = hex("#e3b341"),
            constant = hex("#6ca4f8"),
            variable = hex("#2b7489"),
            variableUsage = hex("#db61a2"),
            assignment = hex("#f78166"),
            currency = hex("#56d364"),
            unit = hex("#2b7489"),
            results = hex("#56d364"),
            comment = hex("#4d4d4d")
        )
    ),
    NumbyTheme(
        name = "GitHub Dark Default",
        syntax = SyntaxColors(
            text = hex("#e6edf3"),
            background = hex("#0d1117"),
            number = hex("#58a6ff"),
            operator = hex("#ff7b72"),
            keyword = hex("#bc8cff"),
            function = hex("#d29922"),
            constant = hex("#58a6ff"),
            variable = hex("#39c5cf"),
            variableUsage = hex("#bc8cff"),
            assignment = hex("#ff7b72"),
            currency = hex("#3fb950"),
            unit = hex("#39c5cf"),
            results = hex("#3fb950"),
            comment = hex("#6e7681")
        )
    ),
    NumbyTheme(
        name = "GitHub Light",
        syntax = SyntaxColors(
            text = hex("#3e3e3e"),
            background = hex("#f4f4f4"),
            number = hex("#003e8a"),
            operator = hex("#970b16"),
            keyword = hex("#e94691"),
            function = hex("#c5bb94"),
            constant = hex("#003e8a"),
            variable = hex("#7cc4df"),
            variableUsage = hex("#e94691"),
            assignment = hex("#970b16"),
            currency = hex("#07962a"),
            unit = hex("#7cc4df"),
            results = hex("#07962a"),
            comment = hex("#666666")
        )
    ),
    NumbyTheme(
        name = "GitHub Light Default",
        syntax = SyntaxColors(
            text = hex("#1f2328"),
            background = hex("#ffffff"),
            number = hex("#0969da"),
            operator = hex("#cf222e"),
            keyword = hex("#8250df"),
            function = hex("#4d2d00"),
            constant = hex("#0969da"),
            variable = hex("#1b7c83"),
            variableUsage = hex("#8250df"),
            assignment = hex("#cf222e"),
            currency = hex("#116329"),
            unit = hex("#1b7c83"),
            results = hex("#116329"),
            comment = hex("#57606a")
        )
    ),
    NumbyTheme(
        name = "Atom One Dark",
        syntax = SyntaxColors(
            text = hex("#abb2bf"),
            background = hex("#21252b"),
            number = hex("#61afef"),
            operator = hex("#e06c75"),
            keyword = hex("#c678dd"),
            function = hex("#e5c07b"),
            constant = hex("#61afef"),
            variable = hex("#56b6c2"),
            variableUsage = hex("#c678dd"),
            assignment = hex("#e06c75"),
            currency = hex("#98c379"),
            unit = hex("#56b6c2"),
            results = hex("#98c379"),
            comment = hex("#767676")
        )
    ),
    NumbyTheme(
        name = "Atom One Light",
        syntax = SyntaxColors(
            text = hex("#2a2c33"),
            background = hex("#f9f9f9"),
            number = hex("#2f5af3"),
            operator = hex("#de3e35"),
            keyword = hex("#950095"),
            function = hex("#d2b67c"),
            constant = hex("#2f5af3"),
            variable = hex("#3f953a"),
            variableUsage = hex("#950095"),
            assignment = hex("#de3e35"),
            currency = hex("#3f953a"),
            unit = hex("#3f953a"),
            results = hex("#3f953a"),
            comment = hex("#000000")
        )
    ),
    NumbyTheme(
        name = "Ayu",
        syntax = SyntaxColors(
            text = hex("#bfbdb6"),
            background = hex("#0b0e14"),
            number = hex("#53bdfa"),
            operator = hex("#ea6c73"),
            keyword = hex("#cda1fa"),
            function = hex("#f9af4f"),
            constant = hex("#53bdfa"),
            variable = hex("#90e1c6"),
            variableUsage = hex("#cda1fa"),
            assignment = hex("#ea6c73"),
            currency = hex("#7fd962"),
            unit = hex("#90e1c6"),
            results = hex("#7fd962"),
            comment = hex("#686868")
        )
    ),
    NumbyTheme(
        name = "Ayu Light",
        syntax = SyntaxColors(
            text = hex("#5c6166"),
            background = hex("#f8f9fa"),
            number = hex("#3199e1"),
            operator = hex("#ea6c6d"),
            keyword = hex("#9e75c7"),
            function = hex("#eca944"),
            constant = hex("#3199e1"),
            variable = hex("#46ba94"),
            variableUsage = hex("#9e75c7"),
            assignment = hex("#ea6c6d"),
            currency = hex("#6cbf43"),
            unit = hex("#46ba94"),
            results = hex("#6cbf43"),
            comment = hex("#686868")
        )
    ),
    NumbyTheme(
        name = "Ayu Mirage",
        syntax = SyntaxColors(
            text = hex("#cccac2"),
            background = hex("#1f2430"),
            number = hex("#6dcbfa"),
            operator = hex("#ed8274"),
            keyword = hex("#dabafa"),
            function = hex("#facc6e"),
            constant = hex("#6dcbfa"),
            variable = hex("#90e1c6"),
            variableUsage = hex("#dabafa"),
            assignment = hex("#ed8274"),
            currency = hex("#87d96c"),
            unit = hex("#90e1c6"),
            results = hex("#87d96c"),
            comment = hex("#686868")
        )
    ),
    NumbyTheme(
        name = "Aura",
        syntax = SyntaxColors(
            text = hex("#edecee"),
            background = hex("#15141b"),
            number = hex("#a277ff"),
            operator = hex("#ff6767"),
            keyword = hex("#a277ff"),
            function = hex("#ffca85"),
            constant = hex("#a277ff"),
            variable = hex("#61ffca"),
            variableUsage = hex("#a277ff"),
            assignment = hex("#ff6767"),
            currency = hex("#61ffca"),
            unit = hex("#61ffca"),
            results = hex("#61ffca"),
            comment = hex("#4d4d4d")
        )
    ),
    NumbyTheme(
        name = "3024 Day",
        syntax = SyntaxColors(
            text = hex("#4a4543"),
            background = hex("#f7f7f7"),
            number = hex("#01a0e4"),
            operator = hex("#db2d20"),
            keyword = hex("#a16a94"),
            function = hex("#caba00"),
            constant = hex("#01a0e4"),
            variable = hex("#8fbece"),
            variableUsage = hex("#a16a94"),
            assignment = hex("#db2d20"),
            currency = hex("#01a252"),
            unit = hex("#8fbece"),
            results = hex("#01a252"),
            comment = hex("#5c5855")
        )
    ),
    NumbyTheme(
        name = "3024 Night",
        syntax = SyntaxColors(
            text = hex("#a5a2a2"),
            background = hex("#090300"),
            number = hex("#01a0e4"),
            operator = hex("#db2d20"),
            keyword = hex("#a16a94"),
            function = hex("#fded02"),
            constant = hex("#01a0e4"),
            variable = hex("#b5e4f4"),
            variableUsage = hex("#a16a94"),
            assignment = hex("#db2d20"),
            currency = hex("#01a252"),
            unit = hex("#b5e4f4"),
            results = hex("#01a252"),
            comment = hex("#5c5855")
        )
    ),
    NumbyTheme(
        name = "Afterglow",
        syntax = SyntaxColors(
            text = hex("#d0d0d0"),
            background = hex("#212121"),
            number = hex("#6c99bb"),
            operator = hex("#ac4142"),
            keyword = hex("#9f4e85"),
            function = hex("#e5b567"),
            constant = hex("#6c99bb"),
            variable = hex("#7dd6cf"),
            variableUsage = hex("#9f4e85"),
            assignment = hex("#ac4142"),
            currency = hex("#7e8e50"),
            unit = hex("#7dd6cf"),
            results = hex("#7e8e50"),
            comment = hex("#505050")
        )
    ),
    NumbyTheme(
        name = "Alabaster",
        syntax = SyntaxColors(
            text = hex("#000000"),
            background = hex("#f7f7f7"),
            number = hex("#325cc0"),
            operator = hex("#aa3731"),
            keyword = hex("#7a3e9d"),
            function = hex("#cb9000"),
            constant = hex("#325cc0"),
            variable = hex("#0083b2"),
            variableUsage = hex("#7a3e9d"),
            assignment = hex("#aa3731"),
            currency = hex("#448c27"),
            unit = hex("#0083b2"),
            results = hex("#448c27"),
            comment = hex("#777777")
        )
    ),
    NumbyTheme(
        name = "Andromeda",
        syntax = SyntaxColors(
            text = hex("#e5e5e5"),
            background = hex("#262a33"),
            number = hex("#2472c8"),
            operator = hex("#cd3131"),
            keyword = hex("#bc3fbc"),
            function = hex("#e5e512"),
            constant = hex("#2472c8"),
            variable = hex("#0fa8cd"),
            variableUsage = hex("#bc3fbc"),
            assignment = hex("#cd3131"),
            currency = hex("#05bc79"),
            unit = hex("#0fa8cd"),
            results = hex("#05bc79"),
            comment = hex("#666666")
        )
    ),
    NumbyTheme(
        name = "Bluloco Dark",
        syntax = SyntaxColors(
            text = hex("#b9c0cb"),
            background = hex("#282c34"),
            number = hex("#3476ff"),
            operator = hex("#fc2f52"),
            keyword = hex("#7a82da"),
            function = hex("#ff936a"),
            constant = hex("#3476ff"),
            variable = hex("#4483aa"),
            variableUsage = hex("#7a82da"),
            assignment = hex("#fc2f52"),
            currency = hex("#25a45c"),
            unit = hex("#4483aa"),
            results = hex("#25a45c"),
            comment = hex("#8f9aae")
        )
    ),
    NumbyTheme(
        name = "Bluloco Light",
        syntax = SyntaxColors(
            text = hex("#373a41"),
            background = hex("#f9f9f9"),
            number = hex("#275fe4"),
            operator = hex("#d52753"),
            keyword = hex("#823ff1"),
            function = hex("#df631c"),
            constant = hex("#275fe4"),
            variable = hex("#27618d"),
            variableUsage = hex("#823ff1"),
            assignment = hex("#d52753"),
            currency = hex("#23974a"),
            unit = hex("#27618d"),
            results = hex("#23974a"),
            comment = hex("#6e7a8a")
        )
    ),
    NumbyTheme(
        name = "Argonaut",
        syntax = SyntaxColors(
            text = hex("#fffaf4"),
            background = hex("#0e1019"),
            number = hex("#008df8"),
            operator = hex("#ff000f"),
            keyword = hex("#6d43a6"),
            function = hex("#ffb900"),
            constant = hex("#008df8"),
            variable = hex("#00d8eb"),
            variableUsage = hex("#6d43a6"),
            assignment = hex("#ff000f"),
            currency = hex("#8ce10b"),
            unit = hex("#00d8eb"),
            results = hex("#8ce10b"),
            comment = hex("#444444")
        )
    ),
    NumbyTheme(
        name = "Adventure",
        syntax = SyntaxColors(
            text = hex("#feffff"),
            background = hex("#040404"),
            number = hex("#417ab3"),
            operator = hex("#d84a33"),
            keyword = hex("#e5c499"),
            function = hex("#eebb6e"),
            constant = hex("#417ab3"),
            variable = hex("#bdcfe5"),
            variableUsage = hex("#e5c499"),
            assignment = hex("#d84a33"),
            currency = hex("#5da602"),
            unit = hex("#bdcfe5"),
            results = hex("#5da602"),
            comment = hex("#685656")
        )
    ),
    NumbyTheme(
        name = "Adwaita Dark",
        syntax = SyntaxColors(
            text = hex("#ffffff"),
            background = hex("#1d1d20"),
            number = hex("#1e78e4"),
            operator = hex("#c01c28"),
            keyword = hex("#9841bb"),
            function = hex("#f5c211"),
            constant = hex("#1e78e4"),
            variable = hex("#0ab9dc"),
            variableUsage = hex("#9841bb"),
            assignment = hex("#c01c28"),
            currency = hex("#2ec27e"),
            unit = hex("#0ab9dc"),
            results = hex("#2ec27e"),
            comment = hex("#5e5c64")
        )
    ),
    NumbyTheme(
        name = "Adwaita",
        syntax = SyntaxColors(
            text = hex("#000000"),
            background = hex("#ffffff"),
            number = hex("#1e78e4"),
            operator = hex("#c01c28"),
            keyword = hex("#9841bb"),
            function = hex("#e8b504"),
            constant = hex("#1e78e4"),
            variable = hex("#0ab9dc"),
            variableUsage = hex("#9841bb"),
            assignment = hex("#c01c28"),
            currency = hex("#2ec27e"),
            unit = hex("#0ab9dc"),
            results = hex("#2ec27e"),
            comment = hex("#5e5c64")
        )
    ),
    NumbyTheme(
        name = "Blue Matrix",
        syntax = SyntaxColors(
            text = hex("#00a2ff"),
            background = hex("#101116"),
            number = hex("#00b0ff"),
            operator = hex("#ff5680"),
            keyword = hex("#d57bff"),
            function = hex("#fffc58"),
            constant = hex("#00b0ff"),
            variable = hex("#76c1ff"),
            variableUsage = hex("#d57bff"),
            assignment = hex("#ff5680"),
            currency = hex("#00ff9c"),
            unit = hex("#76c1ff"),
            results = hex("#00ff9c"),
            comment = hex("#686868")
        )
    ),
    NumbyTheme(
        name = "Banana Blueberry",
        syntax = SyntaxColors(
            text = hex("#cccccc"),
            background = hex("#191323"),
            number = hex("#22e8df"),
            operator = hex("#ff6b7f"),
            keyword = hex("#dc396a"),
            function = hex("#e6c62f"),
            constant = hex("#22e8df"),
            variable = hex("#56b6c2"),
            variableUsage = hex("#dc396a"),
            assignment = hex("#ff6b7f"),
            currency = hex("#00bd9c"),
            unit = hex("#56b6c2"),
            results = hex("#00bd9c"),
            comment = hex("#495162")
        )
    ),
    NumbyTheme(
        name = "Blazer",
        syntax = SyntaxColors(
            text = hex("#d9e6f2"),
            background = hex("#0d1926"),
            number = hex("#7a7ab8"),
            operator = hex("#b87a7a"),
            keyword = hex("#b87ab8"),
            function = hex("#b8b87a"),
            constant = hex("#7a7ab8"),
            variable = hex("#7ab8b8"),
            variableUsage = hex("#b87ab8"),
            assignment = hex("#b87a7a"),
            currency = hex("#7ab87a"),
            unit = hex("#7ab8b8"),
            results = hex("#7ab87a"),
            comment = hex("#4c4c4c")
        )
    ),
    NumbyTheme(
        name = "Birds Of Paradise",
        syntax = SyntaxColors(
            text = hex("#e0dbb7"),
            background = hex("#2a1f1d"),
            number = hex("#5a86ad"),
            operator = hex("#be2d26"),
            keyword = hex("#ac80a6"),
            function = hex("#e99d2a"),
            constant = hex("#5a86ad"),
            variable = hex("#74a6ad"),
            variableUsage = hex("#ac80a6"),
            assignment = hex("#be2d26"),
            currency = hex("#6ba18a"),
            unit = hex("#74a6ad"),
            results = hex("#6ba18a"),
            comment = hex("#9b6c4a")
        )
    ),
    NumbyTheme(
        name = "Arthur",
        syntax = SyntaxColors(
            text = hex("#ddeedd"),
            background = hex("#1c1c1c"),
            number = hex("#6495ed"),
            operator = hex("#cd5c5c"),
            keyword = hex("#deb887"),
            function = hex("#e8ae5b"),
            constant = hex("#6495ed"),
            variable = hex("#b0c4de"),
            variableUsage = hex("#deb887"),
            assignment = hex("#cd5c5c"),
            currency = hex("#86af80"),
            unit = hex("#b0c4de"),
            results = hex("#86af80"),
            comment = hex("#554444")
        )
    ),
    NumbyTheme(
        name = "Aurora",
        syntax = SyntaxColors(
            text = hex("#ffca28"),
            background = hex("#23262e"),
            number = hex("#102ee4"),
            operator = hex("#f0266f"),
            keyword = hex("#ee5d43"),
            function = hex("#ffe66d"),
            constant = hex("#102ee4"),
            variable = hex("#03d6b8"),
            variableUsage = hex("#ee5d43"),
            assignment = hex("#f0266f"),
            currency = hex("#8fd46d"),
            unit = hex("#03d6b8"),
            results = hex("#8fd46d"),
            comment = hex("#4f545e")
        )
    ),
    // === Additional themes from iOS (300+) ===
    NumbyTheme(
        name = "Midnight In Mojave",
        syntax = SyntaxColors(
            text = hex("#ffffff"),
            background = hex("#1e1e1e"),
            number = hex("#0a84ff"),
            operator = hex("#ff453a"),
            keyword = hex("#bf5af2"),
            function = hex("#ffd60a"),
            constant = hex("#0a84ff"),
            variable = hex("#5ac8fa"),
            variableUsage = hex("#bf5af2"),
            assignment = hex("#ff453a"),
            currency = hex("#32d74b"),
            unit = hex("#5ac8fa"),
            results = hex("#32d74b"),
            comment = hex("#515151")
        )
    ),
    NumbyTheme(
        name = "Mirage",
        syntax = SyntaxColors(
            text = hex("#a6b2c0"),
            background = hex("#1b2738"),
            number = hex("#7fb5ff"),
            operator = hex("#ff9999"),
            keyword = hex("#ddb3ff"),
            function = hex("#ffd700"),
            constant = hex("#7fb5ff"),
            variable = hex("#21c7a8"),
            variableUsage = hex("#ddb3ff"),
            assignment = hex("#ff9999"),
            currency = hex("#85cc95"),
            unit = hex("#21c7a8"),
            results = hex("#85cc95"),
            comment = hex("#575656")
        )
    ),
    NumbyTheme(
        name = "Monokai Classic",
        syntax = SyntaxColors(
            text = hex("#fdfff1"),
            background = hex("#272822"),
            number = hex("#fd971f"),
            operator = hex("#f92672"),
            keyword = hex("#ae81ff"),
            function = hex("#e6db74"),
            constant = hex("#fd971f"),
            variable = hex("#66d9ef"),
            variableUsage = hex("#ae81ff"),
            assignment = hex("#f92672"),
            currency = hex("#a6e22e"),
            unit = hex("#66d9ef"),
            results = hex("#a6e22e"),
            comment = hex("#6e7066")
        )
    ),
    NumbyTheme(
        name = "Monokai Pro",
        syntax = SyntaxColors(
            text = hex("#fcfcfa"),
            background = hex("#2d2a2e"),
            number = hex("#fc9867"),
            operator = hex("#ff6188"),
            keyword = hex("#ab9df2"),
            function = hex("#ffd866"),
            constant = hex("#fc9867"),
            variable = hex("#78dce8"),
            variableUsage = hex("#ab9df2"),
            assignment = hex("#ff6188"),
            currency = hex("#a9dc76"),
            unit = hex("#78dce8"),
            results = hex("#a9dc76"),
            comment = hex("#727072")
        )
    ),
    NumbyTheme(
        name = "Monokai Pro Light",
        syntax = SyntaxColors(
            text = hex("#29242a"),
            background = hex("#faf4f2"),
            number = hex("#e16032"),
            operator = hex("#e14775"),
            keyword = hex("#7058be"),
            function = hex("#cc7a0a"),
            constant = hex("#e16032"),
            variable = hex("#1c8ca8"),
            variableUsage = hex("#7058be"),
            assignment = hex("#e14775"),
            currency = hex("#269d69"),
            unit = hex("#1c8ca8"),
            results = hex("#269d69"),
            comment = hex("#a59fa0")
        )
    ),
    NumbyTheme(
        name = "Monokai Pro Machine",
        syntax = SyntaxColors(
            text = hex("#f2fffc"),
            background = hex("#273136"),
            number = hex("#ffb270"),
            operator = hex("#ff6d7e"),
            keyword = hex("#baa0f8"),
            function = hex("#ffed72"),
            constant = hex("#ffb270"),
            variable = hex("#7cd5f1"),
            variableUsage = hex("#baa0f8"),
            assignment = hex("#ff6d7e"),
            currency = hex("#a2e57b"),
            unit = hex("#7cd5f1"),
            results = hex("#a2e57b"),
            comment = hex("#6b7678")
        )
    ),
    NumbyTheme(
        name = "Monokai Pro Octagon",
        syntax = SyntaxColors(
            text = hex("#eaf2f1"),
            background = hex("#282a3a"),
            number = hex("#ff9b5e"),
            operator = hex("#ff657a"),
            keyword = hex("#c39ac9"),
            function = hex("#ffd76d"),
            constant = hex("#ff9b5e"),
            variable = hex("#9cd1bb"),
            variableUsage = hex("#c39ac9"),
            assignment = hex("#ff657a"),
            currency = hex("#bad761"),
            unit = hex("#9cd1bb"),
            results = hex("#bad761"),
            comment = hex("#696d77")
        )
    ),
    NumbyTheme(
        name = "Monokai Pro Ristretto",
        syntax = SyntaxColors(
            text = hex("#fff1f3"),
            background = hex("#2c2525"),
            number = hex("#f38d70"),
            operator = hex("#fd6883"),
            keyword = hex("#a8a9eb"),
            function = hex("#f9cc6c"),
            constant = hex("#f38d70"),
            variable = hex("#85dacc"),
            variableUsage = hex("#a8a9eb"),
            assignment = hex("#fd6883"),
            currency = hex("#adda78"),
            unit = hex("#85dacc"),
            results = hex("#adda78"),
            comment = hex("#72696a")
        )
    ),
    NumbyTheme(
        name = "Monokai Pro Spectrum",
        syntax = SyntaxColors(
            text = hex("#f7f1ff"),
            background = hex("#222222"),
            number = hex("#fd9353"),
            operator = hex("#fc618d"),
            keyword = hex("#948ae3"),
            function = hex("#fce566"),
            constant = hex("#fd9353"),
            variable = hex("#5ad4e6"),
            variableUsage = hex("#948ae3"),
            assignment = hex("#fc618d"),
            currency = hex("#7bd88f"),
            unit = hex("#5ad4e6"),
            results = hex("#7bd88f"),
            comment = hex("#69676c")
        )
    ),
    NumbyTheme(
        name = "Monokai Vivid",
        syntax = SyntaxColors(
            text = hex("#f9f9f9"),
            background = hex("#121212"),
            number = hex("#0443ff"),
            operator = hex("#fa2934"),
            keyword = hex("#f800f8"),
            function = hex("#fff30a"),
            constant = hex("#0443ff"),
            variable = hex("#01b6ed"),
            variableUsage = hex("#f800f8"),
            assignment = hex("#fa2934"),
            currency = hex("#98e123"),
            unit = hex("#01b6ed"),
            results = hex("#98e123"),
            comment = hex("#838383")
        )
    ),
    NumbyTheme(
        name = "Moonfly",
        syntax = SyntaxColors(
            text = hex("#bdbdbd"),
            background = hex("#080808"),
            number = hex("#80a0ff"),
            operator = hex("#ff5454"),
            keyword = hex("#cf87e8"),
            function = hex("#e3c78a"),
            constant = hex("#80a0ff"),
            variable = hex("#79dac8"),
            variableUsage = hex("#cf87e8"),
            assignment = hex("#ff5454"),
            currency = hex("#8cc85f"),
            unit = hex("#79dac8"),
            results = hex("#8cc85f"),
            comment = hex("#949494")
        )
    ),
    NumbyTheme(
        name = "Night Owl",
        syntax = SyntaxColors(
            text = hex("#d6deeb"),
            background = hex("#011627"),
            number = hex("#82aaff"),
            operator = hex("#ef5350"),
            keyword = hex("#c792ea"),
            function = hex("#addb67"),
            constant = hex("#82aaff"),
            variable = hex("#21c7a8"),
            variableUsage = hex("#c792ea"),
            assignment = hex("#ef5350"),
            currency = hex("#22da6e"),
            unit = hex("#21c7a8"),
            results = hex("#22da6e"),
            comment = hex("#575656")
        )
    ),
    NumbyTheme(
        name = "Night Owlish Light",
        syntax = SyntaxColors(
            text = hex("#403f53"),
            background = hex("#ffffff"),
            number = hex("#4876d6"),
            operator = hex("#d3423e"),
            keyword = hex("#403f53"),
            function = hex("#daaa01"),
            constant = hex("#4876d6"),
            variable = hex("#08916a"),
            variableUsage = hex("#403f53"),
            assignment = hex("#d3423e"),
            currency = hex("#2aa298"),
            unit = hex("#08916a"),
            results = hex("#2aa298"),
            comment = hex("#7a8181")
        )
    ),
    NumbyTheme(
        name = "Nightfox",
        syntax = SyntaxColors(
            text = hex("#cdcecf"),
            background = hex("#192330"),
            number = hex("#719cd6"),
            operator = hex("#c94f6d"),
            keyword = hex("#9d79d6"),
            function = hex("#dbc074"),
            constant = hex("#719cd6"),
            variable = hex("#63cdcf"),
            variableUsage = hex("#9d79d6"),
            assignment = hex("#c94f6d"),
            currency = hex("#81b29a"),
            unit = hex("#63cdcf"),
            results = hex("#81b29a"),
            comment = hex("#575860")
        )
    ),
    NumbyTheme(
        name = "Nord Light",
        syntax = SyntaxColors(
            text = hex("#414858"),
            background = hex("#e5e9f0"),
            number = hex("#81a1c1"),
            operator = hex("#bf616a"),
            keyword = hex("#b48ead"),
            function = hex("#c5a565"),
            constant = hex("#81a1c1"),
            variable = hex("#7bb3c3"),
            variableUsage = hex("#b48ead"),
            assignment = hex("#bf616a"),
            currency = hex("#96b17f"),
            unit = hex("#7bb3c3"),
            results = hex("#96b17f"),
            comment = hex("#4c566a")
        )
    ),
    NumbyTheme(
        name = "One Half Dark",
        syntax = SyntaxColors(
            text = hex("#dcdfe4"),
            background = hex("#282c34"),
            number = hex("#61afef"),
            operator = hex("#e06c75"),
            keyword = hex("#c678dd"),
            function = hex("#e5c07b"),
            constant = hex("#61afef"),
            variable = hex("#56b6c2"),
            variableUsage = hex("#c678dd"),
            assignment = hex("#e06c75"),
            currency = hex("#98c379"),
            unit = hex("#56b6c2"),
            results = hex("#98c379"),
            comment = hex("#5d677a")
        )
    ),
    NumbyTheme(
        name = "One Half Light",
        syntax = SyntaxColors(
            text = hex("#383a42"),
            background = hex("#fafafa"),
            number = hex("#0184bc"),
            operator = hex("#e45649"),
            keyword = hex("#a626a4"),
            function = hex("#c18401"),
            constant = hex("#0184bc"),
            variable = hex("#0997b3"),
            variableUsage = hex("#a626a4"),
            assignment = hex("#e45649"),
            currency = hex("#50a14f"),
            unit = hex("#0997b3"),
            results = hex("#50a14f"),
            comment = hex("#4f525e")
        )
    ),
    NumbyTheme(
        name = "Oxocarbon",
        syntax = SyntaxColors(
            text = hex("#f2f4f8"),
            background = hex("#161616"),
            number = hex("#00c15a"),
            operator = hex("#00dfdb"),
            keyword = hex("#c693ff"),
            function = hex("#ff4297"),
            constant = hex("#00c15a"),
            variable = hex("#ff74b8"),
            variableUsage = hex("#c693ff"),
            assignment = hex("#00dfdb"),
            currency = hex("#00b4ff"),
            unit = hex("#ff74b8"),
            results = hex("#00b4ff"),
            comment = hex("#585858")
        )
    ),
    NumbyTheme(
        name = "Rose Pine",
        syntax = SyntaxColors(
            text = hex("#e0def4"),
            background = hex("#191724"),
            number = hex("#9ccfd8"),
            operator = hex("#eb6f92"),
            keyword = hex("#c4a7e7"),
            function = hex("#f6c177"),
            constant = hex("#9ccfd8"),
            variable = hex("#ebbcba"),
            variableUsage = hex("#c4a7e7"),
            assignment = hex("#eb6f92"),
            currency = hex("#31748f"),
            unit = hex("#ebbcba"),
            results = hex("#31748f"),
            comment = hex("#6e6a86")
        )
    ),
    NumbyTheme(
        name = "Rose Pine Dawn",
        syntax = SyntaxColors(
            text = hex("#575279"),
            background = hex("#faf4ed"),
            number = hex("#56949f"),
            operator = hex("#b4637a"),
            keyword = hex("#907aa9"),
            function = hex("#ea9d34"),
            constant = hex("#56949f"),
            variable = hex("#d7827e"),
            variableUsage = hex("#907aa9"),
            assignment = hex("#b4637a"),
            currency = hex("#286983"),
            unit = hex("#d7827e"),
            results = hex("#286983"),
            comment = hex("#9893a5")
        )
    ),
    NumbyTheme(
        name = "Rose Pine Moon",
        syntax = SyntaxColors(
            text = hex("#e0def4"),
            background = hex("#232136"),
            number = hex("#9ccfd8"),
            operator = hex("#eb6f92"),
            keyword = hex("#c4a7e7"),
            function = hex("#f6c177"),
            constant = hex("#9ccfd8"),
            variable = hex("#ea9a97"),
            variableUsage = hex("#c4a7e7"),
            assignment = hex("#eb6f92"),
            currency = hex("#3e8fb0"),
            unit = hex("#ea9a97"),
            results = hex("#3e8fb0"),
            comment = hex("#6e6a86")
        )
    ),
    NumbyTheme(
        name = "Seti",
        syntax = SyntaxColors(
            text = hex("#cacecd"),
            background = hex("#111213"),
            number = hex("#43a5d5"),
            operator = hex("#c22832"),
            keyword = hex("#8b57b5"),
            function = hex("#e0c64f"),
            constant = hex("#43a5d5"),
            variable = hex("#8ec43d"),
            variableUsage = hex("#8b57b5"),
            assignment = hex("#c22832"),
            currency = hex("#8ec43d"),
            unit = hex("#8ec43d"),
            results = hex("#8ec43d"),
            comment = hex("#3f3f3f")
        )
    ),
    NumbyTheme(
        name = "Shades Of Purple",
        syntax = SyntaxColors(
            text = hex("#ffffff"),
            background = hex("#1e1d40"),
            number = hex("#6943ff"),
            operator = hex("#d90429"),
            keyword = hex("#ff2c70"),
            function = hex("#ffe700"),
            constant = hex("#6943ff"),
            variable = hex("#00c5c7"),
            variableUsage = hex("#ff2c70"),
            assignment = hex("#d90429"),
            currency = hex("#3ad900"),
            unit = hex("#00c5c7"),
            results = hex("#3ad900"),
            comment = hex("#686868")
        )
    ),
    NumbyTheme(
        name = "Snazzy",
        syntax = SyntaxColors(
            text = hex("#ebece6"),
            background = hex("#1e1f29"),
            number = hex("#49baff"),
            operator = hex("#fc4346"),
            keyword = hex("#fc4cb4"),
            function = hex("#f0fb8c"),
            constant = hex("#49baff"),
            variable = hex("#8be9fe"),
            variableUsage = hex("#fc4cb4"),
            assignment = hex("#fc4346"),
            currency = hex("#50fb7c"),
            unit = hex("#8be9fe"),
            results = hex("#50fb7c"),
            comment = hex("#555555")
        )
    ),
    NumbyTheme(
        name = "Sonokai",
        syntax = SyntaxColors(
            text = hex("#e2e2e3"),
            background = hex("#2c2e34"),
            number = hex("#76cce0"),
            operator = hex("#fc5d7c"),
            keyword = hex("#b39df3"),
            function = hex("#e7c664"),
            constant = hex("#76cce0"),
            variable = hex("#f39660"),
            variableUsage = hex("#b39df3"),
            assignment = hex("#fc5d7c"),
            currency = hex("#9ed072"),
            unit = hex("#f39660"),
            results = hex("#9ed072"),
            comment = hex("#7f8490")
        )
    ),
    NumbyTheme(
        name = "Spacedust",
        syntax = SyntaxColors(
            text = hex("#ecf0c1"),
            background = hex("#0a1e24"),
            number = hex("#0f548b"),
            operator = hex("#e35b00"),
            keyword = hex("#e35b00"),
            function = hex("#e3cd7b"),
            constant = hex("#0f548b"),
            variable = hex("#06afc7"),
            variableUsage = hex("#e35b00"),
            assignment = hex("#e35b00"),
            currency = hex("#5cab96"),
            unit = hex("#06afc7"),
            results = hex("#5cab96"),
            comment = hex("#684c31")
        )
    ),
    NumbyTheme(
        name = "Spacegray",
        syntax = SyntaxColors(
            text = hex("#b3b8c3"),
            background = hex("#20242d"),
            number = hex("#7d8fa4"),
            operator = hex("#b04b57"),
            keyword = hex("#a47996"),
            function = hex("#e5c179"),
            constant = hex("#7d8fa4"),
            variable = hex("#85a7a5"),
            variableUsage = hex("#a47996"),
            assignment = hex("#b04b57"),
            currency = hex("#87b379"),
            unit = hex("#85a7a5"),
            results = hex("#87b379"),
            comment = hex("#4c4c4c")
        )
    ),
    NumbyTheme(
        name = "Synthwave",
        syntax = SyntaxColors(
            text = hex("#dad9c7"),
            background = hex("#000000"),
            number = hex("#2186ec"),
            operator = hex("#f6188f"),
            keyword = hex("#f85a21"),
            function = hex("#fdf834"),
            constant = hex("#2186ec"),
            variable = hex("#12c3e2"),
            variableUsage = hex("#f85a21"),
            assignment = hex("#f6188f"),
            currency = hex("#1ebb2b"),
            unit = hex("#12c3e2"),
            results = hex("#1ebb2b"),
            comment = hex("#7f7094")
        )
    ),
    NumbyTheme(
        name = "Synthwave Everything",
        syntax = SyntaxColors(
            text = hex("#f0eff1"),
            background = hex("#2a2139"),
            number = hex("#6d77b3"),
            operator = hex("#f97e72"),
            keyword = hex("#c792ea"),
            function = hex("#fede5d"),
            constant = hex("#6d77b3"),
            variable = hex("#f772e0"),
            variableUsage = hex("#c792ea"),
            assignment = hex("#f97e72"),
            currency = hex("#72f1b8"),
            unit = hex("#f772e0"),
            results = hex("#72f1b8"),
            comment = hex("#fefefe")
        )
    ),
    NumbyTheme(
        name = "Tomorrow",
        syntax = SyntaxColors(
            text = hex("#4d4d4c"),
            background = hex("#ffffff"),
            number = hex("#4271ae"),
            operator = hex("#c82829"),
            keyword = hex("#8959a8"),
            function = hex("#eab700"),
            constant = hex("#4271ae"),
            variable = hex("#3e999f"),
            variableUsage = hex("#8959a8"),
            assignment = hex("#c82829"),
            currency = hex("#718c00"),
            unit = hex("#3e999f"),
            results = hex("#718c00"),
            comment = hex("#000000")
        )
    ),
    NumbyTheme(
        name = "Tomorrow Night",
        syntax = SyntaxColors(
            text = hex("#c5c8c6"),
            background = hex("#1d1f21"),
            number = hex("#81a2be"),
            operator = hex("#cc6666"),
            keyword = hex("#b294bb"),
            function = hex("#f0c674"),
            constant = hex("#81a2be"),
            variable = hex("#8abeb7"),
            variableUsage = hex("#b294bb"),
            assignment = hex("#cc6666"),
            currency = hex("#b5bd68"),
            unit = hex("#8abeb7"),
            results = hex("#b5bd68"),
            comment = hex("#4c4c4c")
        )
    ),
    NumbyTheme(
        name = "Tomorrow Night Blue",
        syntax = SyntaxColors(
            text = hex("#ffffff"),
            background = hex("#002451"),
            number = hex("#bbdaff"),
            operator = hex("#ff9da4"),
            keyword = hex("#ebbbff"),
            function = hex("#ffeead"),
            constant = hex("#bbdaff"),
            variable = hex("#99ffff"),
            variableUsage = hex("#ebbbff"),
            assignment = hex("#ff9da4"),
            currency = hex("#d1f1a9"),
            unit = hex("#99ffff"),
            results = hex("#d1f1a9"),
            comment = hex("#4c4c4c")
        )
    ),
    NumbyTheme(
        name = "Tomorrow Night Bright",
        syntax = SyntaxColors(
            text = hex("#eaeaea"),
            background = hex("#000000"),
            number = hex("#7aa6da"),
            operator = hex("#d54e53"),
            keyword = hex("#c397d8"),
            function = hex("#e7c547"),
            constant = hex("#7aa6da"),
            variable = hex("#70c0b1"),
            variableUsage = hex("#c397d8"),
            assignment = hex("#d54e53"),
            currency = hex("#b9ca4a"),
            unit = hex("#70c0b1"),
            results = hex("#b9ca4a"),
            comment = hex("#404040")
        )
    ),
    NumbyTheme(
        name = "Tomorrow Night Eighties",
        syntax = SyntaxColors(
            text = hex("#cccccc"),
            background = hex("#2d2d2d"),
            number = hex("#6699cc"),
            operator = hex("#f2777a"),
            keyword = hex("#cc99cc"),
            function = hex("#ffcc66"),
            constant = hex("#6699cc"),
            variable = hex("#66cccc"),
            variableUsage = hex("#cc99cc"),
            assignment = hex("#f2777a"),
            currency = hex("#99cc99"),
            unit = hex("#66cccc"),
            results = hex("#99cc99"),
            comment = hex("#595959")
        )
    ),
    NumbyTheme(
        name = "Ubuntu",
        syntax = SyntaxColors(
            text = hex("#eeeeec"),
            background = hex("#300a24"),
            number = hex("#3465a4"),
            operator = hex("#cc0000"),
            keyword = hex("#75507b"),
            function = hex("#c4a000"),
            constant = hex("#3465a4"),
            variable = hex("#06989a"),
            variableUsage = hex("#75507b"),
            assignment = hex("#cc0000"),
            currency = hex("#4e9a06"),
            unit = hex("#06989a"),
            results = hex("#4e9a06"),
            comment = hex("#555753")
        )
    ),
    NumbyTheme(
        name = "Vercel",
        syntax = SyntaxColors(
            text = hex("#fafafa"),
            background = hex("#101010"),
            number = hex("#006aff"),
            operator = hex("#fc0036"),
            keyword = hex("#f32882"),
            function = hex("#ffae00"),
            constant = hex("#006aff"),
            variable = hex("#00ac96"),
            variableUsage = hex("#f32882"),
            assignment = hex("#fc0036"),
            currency = hex("#29a948"),
            unit = hex("#00ac96"),
            results = hex("#29a948"),
            comment = hex("#a8a8a8")
        )
    ),
    NumbyTheme(
        name = "Vesper",
        syntax = SyntaxColors(
            text = hex("#ffffff"),
            background = hex("#101010"),
            number = hex("#aca1cf"),
            operator = hex("#f5a191"),
            keyword = hex("#e29eca"),
            function = hex("#e6b99d"),
            constant = hex("#aca1cf"),
            variable = hex("#ea83a5"),
            variableUsage = hex("#e29eca"),
            assignment = hex("#f5a191"),
            currency = hex("#90b99f"),
            unit = hex("#ea83a5"),
            results = hex("#90b99f"),
            comment = hex("#7e7e7e")
        )
    ),
    NumbyTheme(
        name = "Vibrant Ink",
        syntax = SyntaxColors(
            text = hex("#ffffff"),
            background = hex("#000000"),
            number = hex("#44b4cc"),
            operator = hex("#ff6600"),
            keyword = hex("#9933cc"),
            function = hex("#ffcc00"),
            constant = hex("#44b4cc"),
            variable = hex("#44b4cc"),
            variableUsage = hex("#9933cc"),
            assignment = hex("#ff6600"),
            currency = hex("#ccff04"),
            unit = hex("#44b4cc"),
            results = hex("#ccff04"),
            comment = hex("#555555")
        )
    ),
    NumbyTheme(
        name = "Whimsy",
        syntax = SyntaxColors(
            text = hex("#b3b0d6"),
            background = hex("#29283b"),
            number = hex("#65aef7"),
            operator = hex("#ef6487"),
            keyword = hex("#aa7ff0"),
            function = hex("#fdd877"),
            constant = hex("#65aef7"),
            variable = hex("#43c1be"),
            variableUsage = hex("#aa7ff0"),
            assignment = hex("#ef6487"),
            currency = hex("#5eca89"),
            unit = hex("#43c1be"),
            results = hex("#5eca89"),
            comment = hex("#535178")
        )
    ),
    NumbyTheme(
        name = "Wild Cherry",
        syntax = SyntaxColors(
            text = hex("#dafaff"),
            background = hex("#1f1726"),
            number = hex("#883cdc"),
            operator = hex("#d94085"),
            keyword = hex("#ececec"),
            function = hex("#ffd16f"),
            constant = hex("#883cdc"),
            variable = hex("#c1b8b7"),
            variableUsage = hex("#ececec"),
            assignment = hex("#d94085"),
            currency = hex("#2ab250"),
            unit = hex("#c1b8b7"),
            results = hex("#2ab250"),
            comment = hex("#009cc9")
        )
    ),
    NumbyTheme(
        name = "Wombat",
        syntax = SyntaxColors(
            text = hex("#dedacf"),
            background = hex("#171717"),
            number = hex("#5da9f6"),
            operator = hex("#ff615a"),
            keyword = hex("#e86aff"),
            function = hex("#ebd99c"),
            constant = hex("#5da9f6"),
            variable = hex("#82fff7"),
            variableUsage = hex("#e86aff"),
            assignment = hex("#ff615a"),
            currency = hex("#b1e969"),
            unit = hex("#82fff7"),
            results = hex("#b1e969"),
            comment = hex("#4b4b4b")
        )
    ),
    NumbyTheme(
        name = "Xcode Dark",
        syntax = SyntaxColors(
            text = hex("#dfdfe0"),
            background = hex("#292a30"),
            number = hex("#4eb0cc"),
            operator = hex("#ff8170"),
            keyword = hex("#ff7ab2"),
            function = hex("#d9c97c"),
            constant = hex("#4eb0cc"),
            variable = hex("#b281eb"),
            variableUsage = hex("#ff7ab2"),
            assignment = hex("#ff8170"),
            currency = hex("#78c2b3"),
            unit = hex("#b281eb"),
            results = hex("#78c2b3"),
            comment = hex("#7f8c98")
        )
    ),
    NumbyTheme(
        name = "Xcode Light",
        syntax = SyntaxColors(
            text = hex("#262626"),
            background = hex("#ffffff"),
            number = hex("#0f68a0"),
            operator = hex("#d12f1b"),
            keyword = hex("#ad3da4"),
            function = hex("#78492a"),
            constant = hex("#0f68a0"),
            variable = hex("#804fb8"),
            variableUsage = hex("#ad3da4"),
            assignment = hex("#d12f1b"),
            currency = hex("#3e8087"),
            unit = hex("#804fb8"),
            results = hex("#3e8087"),
            comment = hex("#8a99a6")
        )
    ),
    NumbyTheme(
        name = "Zenburn",
        syntax = SyntaxColors(
            text = hex("#dcdccc"),
            background = hex("#3f3f3f"),
            number = hex("#5d6d7d"),
            operator = hex("#7d5d5d"),
            keyword = hex("#dc8cc3"),
            function = hex("#f0dfaf"),
            constant = hex("#5d6d7d"),
            variable = hex("#8cd0d3"),
            variableUsage = hex("#dc8cc3"),
            assignment = hex("#7d5d5d"),
            currency = hex("#60b48a"),
            unit = hex("#8cd0d3"),
            results = hex("#60b48a"),
            comment = hex("#709080")
        )
    ),
    NumbyTheme(
        name = "Zenbones Dark",
        syntax = SyntaxColors(
            text = hex("#b4bdc3"),
            background = hex("#1c1917"),
            number = hex("#6099c0"),
            operator = hex("#de6e7c"),
            keyword = hex("#b279a7"),
            function = hex("#b77e64"),
            constant = hex("#6099c0"),
            variable = hex("#66a5ad"),
            variableUsage = hex("#b279a7"),
            assignment = hex("#de6e7c"),
            currency = hex("#819b69"),
            unit = hex("#66a5ad"),
            results = hex("#819b69"),
            comment = hex("#4d4540")
        )
    ),
    NumbyTheme(
        name = "Zenbones Light",
        syntax = SyntaxColors(
            text = hex("#2c363c"),
            background = hex("#f0edec"),
            number = hex("#286486"),
            operator = hex("#a8334c"),
            keyword = hex("#88507d"),
            function = hex("#944927"),
            constant = hex("#286486"),
            variable = hex("#3b8992"),
            variableUsage = hex("#88507d"),
            assignment = hex("#a8334c"),
            currency = hex("#4f6c31"),
            unit = hex("#3b8992"),
            results = hex("#4f6c31"),
            comment = hex("#b5a7a0")
        )
    ),
    NumbyTheme(
        name = "iTerm2 Solarized Dark",
        syntax = SyntaxColors(
            text = hex("#839496"),
            background = hex("#002b36"),
            number = hex("#268bd2"),
            operator = hex("#dc322f"),
            keyword = hex("#d33682"),
            function = hex("#b58900"),
            constant = hex("#268bd2"),
            variable = hex("#2aa198"),
            variableUsage = hex("#d33682"),
            assignment = hex("#dc322f"),
            currency = hex("#859900"),
            unit = hex("#2aa198"),
            results = hex("#859900"),
            comment = hex("#335e69")
        )
    ),
    NumbyTheme(
        name = "iTerm2 Solarized Light",
        syntax = SyntaxColors(
            text = hex("#657b83"),
            background = hex("#fdf6e3"),
            number = hex("#268bd2"),
            operator = hex("#dc322f"),
            keyword = hex("#d33682"),
            function = hex("#b58900"),
            constant = hex("#268bd2"),
            variable = hex("#2aa198"),
            variableUsage = hex("#d33682"),
            assignment = hex("#dc322f"),
            currency = hex("#859900"),
            unit = hex("#2aa198"),
            results = hex("#859900"),
            comment = hex("#002b36")
        )
    ),
    NumbyTheme(
        name = "Raycast Dark",
        syntax = SyntaxColors(
            text = hex("#ffffff"),
            background = hex("#1a1a1a"),
            number = hex("#56c2ff"),
            operator = hex("#ff5360"),
            keyword = hex("#cf2f98"),
            function = hex("#ffc531"),
            constant = hex("#56c2ff"),
            variable = hex("#52eee5"),
            variableUsage = hex("#cf2f98"),
            assignment = hex("#ff5360"),
            currency = hex("#59d499"),
            unit = hex("#52eee5"),
            results = hex("#59d499"),
            comment = hex("#4c4c4c")
        )
    ),
    NumbyTheme(
        name = "Raycast Light",
        syntax = SyntaxColors(
            text = hex("#000000"),
            background = hex("#ffffff"),
            number = hex("#138af2"),
            operator = hex("#b12424"),
            keyword = hex("#9a1b6e"),
            function = hex("#f8a300"),
            constant = hex("#138af2"),
            variable = hex("#3eb8bf"),
            variableUsage = hex("#9a1b6e"),
            assignment = hex("#b12424"),
            currency = hex("#006b4f"),
            unit = hex("#3eb8bf"),
            results = hex("#006b4f"),
            comment = hex("#000000")
        )
    ),
    NumbyTheme(
        name = "Oceanic Next",
        syntax = SyntaxColors(
            text = hex("#c0c5ce"),
            background = hex("#162c35"),
            number = hex("#6699cc"),
            operator = hex("#ec5f67"),
            keyword = hex("#c594c5"),
            function = hex("#fac863"),
            constant = hex("#6699cc"),
            variable = hex("#5fb3b3"),
            variableUsage = hex("#c594c5"),
            assignment = hex("#ec5f67"),
            currency = hex("#99c794"),
            unit = hex("#5fb3b3"),
            results = hex("#99c794"),
            comment = hex("#65737e")
        )
    ),
    NumbyTheme(
        name = "Pencil Dark",
        syntax = SyntaxColors(
            text = hex("#f1f1f1"),
            background = hex("#212121"),
            number = hex("#008ec4"),
            operator = hex("#c30771"),
            keyword = hex("#5f4986"),
            function = hex("#a89c14"),
            constant = hex("#008ec4"),
            variable = hex("#20a5ba"),
            variableUsage = hex("#5f4986"),
            assignment = hex("#c30771"),
            currency = hex("#10a778"),
            unit = hex("#20a5ba"),
            results = hex("#10a778"),
            comment = hex("#4f4f4f")
        )
    ),
    NumbyTheme(
        name = "Pencil Light",
        syntax = SyntaxColors(
            text = hex("#424242"),
            background = hex("#f1f1f1"),
            number = hex("#008ec4"),
            operator = hex("#c30771"),
            keyword = hex("#523c79"),
            function = hex("#a89c14"),
            constant = hex("#008ec4"),
            variable = hex("#20a5ba"),
            variableUsage = hex("#523c79"),
            assignment = hex("#c30771"),
            currency = hex("#10a778"),
            unit = hex("#20a5ba"),
            results = hex("#10a778"),
            comment = hex("#424242")
        )
    ),
    NumbyTheme(
        name = "Purple Rain",
        syntax = SyntaxColors(
            text = hex("#fffbf6"),
            background = hex("#21084a"),
            number = hex("#00a2fa"),
            operator = hex("#ff260e"),
            keyword = hex("#815bb5"),
            function = hex("#ffc400"),
            constant = hex("#00a2fa"),
            variable = hex("#00deef"),
            variableUsage = hex("#815bb5"),
            assignment = hex("#ff260e"),
            currency = hex("#9be205"),
            unit = hex("#00deef"),
            results = hex("#9be205"),
            comment = hex("#565656")
        )
    ),
    NumbyTheme(
        name = "Material",
        syntax = SyntaxColors(
            text = hex("#eeffff"),
            background = hex("#263238"),
            number = hex("#82aaff"),
            operator = hex("#f07178"),
            keyword = hex("#c792ea"),
            function = hex("#ffcb6b"),
            constant = hex("#82aaff"),
            variable = hex("#89ddff"),
            variableUsage = hex("#c792ea"),
            assignment = hex("#f07178"),
            currency = hex("#c3e88d"),
            unit = hex("#89ddff"),
            results = hex("#c3e88d"),
            comment = hex("#546e7a")
        )
    ),
    NumbyTheme(
        name = "Material Darker",
        syntax = SyntaxColors(
            text = hex("#eeffff"),
            background = hex("#212121"),
            number = hex("#82aaff"),
            operator = hex("#f07178"),
            keyword = hex("#c792ea"),
            function = hex("#ffcb6b"),
            constant = hex("#82aaff"),
            variable = hex("#89ddff"),
            variableUsage = hex("#c792ea"),
            assignment = hex("#f07178"),
            currency = hex("#c3e88d"),
            unit = hex("#89ddff"),
            results = hex("#c3e88d"),
            comment = hex("#4f4f4f")
        )
    ),
    NumbyTheme(
        name = "Material Lighter",
        syntax = SyntaxColors(
            text = hex("#80cbc4"),
            background = hex("#fafafa"),
            number = hex("#6182b8"),
            operator = hex("#e53935"),
            keyword = hex("#7c4dff"),
            function = hex("#f6a434"),
            constant = hex("#6182b8"),
            variable = hex("#39adb5"),
            variableUsage = hex("#7c4dff"),
            assignment = hex("#e53935"),
            currency = hex("#91b859"),
            unit = hex("#39adb5"),
            results = hex("#91b859"),
            comment = hex("#9e9e9e")
        )
    ),
    NumbyTheme(
        name = "Material Ocean",
        syntax = SyntaxColors(
            text = hex("#8f93a2"),
            background = hex("#0f111a"),
            number = hex("#82aaff"),
            operator = hex("#f07178"),
            keyword = hex("#c792ea"),
            function = hex("#ffcb6b"),
            constant = hex("#82aaff"),
            variable = hex("#89ddff"),
            variableUsage = hex("#c792ea"),
            assignment = hex("#f07178"),
            currency = hex("#c3e88d"),
            unit = hex("#89ddff"),
            results = hex("#c3e88d"),
            comment = hex("#464b5d")
        )
    ),
    NumbyTheme(
        name = "Material Palenight",
        syntax = SyntaxColors(
            text = hex("#a6accd"),
            background = hex("#292d3e"),
            number = hex("#82aaff"),
            operator = hex("#f07178"),
            keyword = hex("#c792ea"),
            function = hex("#ffcb6b"),
            constant = hex("#82aaff"),
            variable = hex("#89ddff"),
            variableUsage = hex("#c792ea"),
            assignment = hex("#f07178"),
            currency = hex("#c3e88d"),
            unit = hex("#89ddff"),
            results = hex("#c3e88d"),
            comment = hex("#676e95")
        )
    ),
    NumbyTheme(
        name = "Cobalt2",
        syntax = SyntaxColors(
            text = hex("#ffffff"),
            background = hex("#132738"),
            number = hex("#ff9d00"),
            operator = hex("#f92672"),
            keyword = hex("#ff9d00"),
            function = hex("#ffe11a"),
            constant = hex("#ff9d00"),
            variable = hex("#ffc600"),
            variableUsage = hex("#ff9d00"),
            assignment = hex("#f92672"),
            currency = hex("#3ad900"),
            unit = hex("#ffc600"),
            results = hex("#3ad900"),
            comment = hex("#0088ff")
        )
    ),
    NumbyTheme(
        name = "Cobalt Neon",
        syntax = SyntaxColors(
            text = hex("#ffffff"),
            background = hex("#142838"),
            number = hex("#74e5f2"),
            operator = hex("#e66f6e"),
            keyword = hex("#d38dea"),
            function = hex("#fbe95d"),
            constant = hex("#74e5f2"),
            variable = hex("#9ced98"),
            variableUsage = hex("#d38dea"),
            assignment = hex("#e66f6e"),
            currency = hex("#9ced98"),
            unit = hex("#9ced98"),
            results = hex("#9ced98"),
            comment = hex("#5f6a7e")
        )
    ),
    NumbyTheme(
        name = "Kanagawa",
        syntax = SyntaxColors(
            text = hex("#dcd7ba"),
            background = hex("#1f1f28"),
            number = hex("#7e9cd8"),
            operator = hex("#c34043"),
            keyword = hex("#957fb8"),
            function = hex("#dca561"),
            constant = hex("#7e9cd8"),
            variable = hex("#7fb4ca"),
            variableUsage = hex("#957fb8"),
            assignment = hex("#c34043"),
            currency = hex("#98bb6c"),
            unit = hex("#7fb4ca"),
            results = hex("#98bb6c"),
            comment = hex("#727169")
        )
    ),
    NumbyTheme(
        name = "Kanagawa Wave",
        syntax = SyntaxColors(
            text = hex("#dcd7ba"),
            background = hex("#1f1f28"),
            number = hex("#7e9cd8"),
            operator = hex("#c34043"),
            keyword = hex("#957fb8"),
            function = hex("#e6c384"),
            constant = hex("#7e9cd8"),
            variable = hex("#7fb4ca"),
            variableUsage = hex("#957fb8"),
            assignment = hex("#c34043"),
            currency = hex("#98bb6c"),
            unit = hex("#7fb4ca"),
            results = hex("#98bb6c"),
            comment = hex("#727169")
        )
    ),
    NumbyTheme(
        name = "Kanagawa Dragon",
        syntax = SyntaxColors(
            text = hex("#c5c9c5"),
            background = hex("#181616"),
            number = hex("#7fb4ca"),
            operator = hex("#c4746e"),
            keyword = hex("#a292a3"),
            function = hex("#c4b28a"),
            constant = hex("#7fb4ca"),
            variable = hex("#9cabca"),
            variableUsage = hex("#a292a3"),
            assignment = hex("#c4746e"),
            currency = hex("#87a987"),
            unit = hex("#9cabca"),
            results = hex("#87a987"),
            comment = hex("#8a8980")
        )
    ),
    NumbyTheme(
        name = "Kanagawa Lotus",
        syntax = SyntaxColors(
            text = hex("#545464"),
            background = hex("#f2ecbc"),
            number = hex("#4d699b"),
            operator = hex("#c84053"),
            keyword = hex("#766b90"),
            function = hex("#de9800"),
            constant = hex("#4d699b"),
            variable = hex("#597b75"),
            variableUsage = hex("#766b90"),
            assignment = hex("#c84053"),
            currency = hex("#6f894e"),
            unit = hex("#597b75"),
            results = hex("#6f894e"),
            comment = hex("#8a8a8a")
        )
    ),
    NumbyTheme(
        name = "Horizon Dark",
        syntax = SyntaxColors(
            text = hex("#e0e0e0"),
            background = hex("#1c1e26"),
            number = hex("#fab38e"),
            operator = hex("#eb6f92"),
            keyword = hex("#b877db"),
            function = hex("#e95678"),
            constant = hex("#fab38e"),
            variable = hex("#25b0bc"),
            variableUsage = hex("#b877db"),
            assignment = hex("#eb6f92"),
            currency = hex("#27d796"),
            unit = hex("#25b0bc"),
            results = hex("#27d796"),
            comment = hex("#6c6f93")
        )
    ),
    NumbyTheme(
        name = "Horizon Bright",
        syntax = SyntaxColors(
            text = hex("#1c1c1c"),
            background = hex("#fdf0ed"),
            number = hex("#da103f"),
            operator = hex("#f7939b"),
            keyword = hex("#1eb980"),
            function = hex("#e95678"),
            constant = hex("#da103f"),
            variable = hex("#26bbd9"),
            variableUsage = hex("#1eb980"),
            assignment = hex("#f7939b"),
            currency = hex("#1eb980"),
            unit = hex("#26bbd9"),
            results = hex("#1eb980"),
            comment = hex("#8a8a8a")
        )
    ),
    NumbyTheme(
        name = "Everforest Dark",
        syntax = SyntaxColors(
            text = hex("#d3c6aa"),
            background = hex("#2d353b"),
            number = hex("#7fbbb3"),
            operator = hex("#e67e80"),
            keyword = hex("#d699b6"),
            function = hex("#dbbc7f"),
            constant = hex("#7fbbb3"),
            variable = hex("#83c092"),
            variableUsage = hex("#d699b6"),
            assignment = hex("#e67e80"),
            currency = hex("#a7c080"),
            unit = hex("#83c092"),
            results = hex("#a7c080"),
            comment = hex("#859289")
        )
    ),
    NumbyTheme(
        name = "Everforest Light",
        syntax = SyntaxColors(
            text = hex("#5c6a72"),
            background = hex("#fdf6e3"),
            number = hex("#3a94c5"),
            operator = hex("#f85552"),
            keyword = hex("#df69ba"),
            function = hex("#dfa000"),
            constant = hex("#3a94c5"),
            variable = hex("#35a77c"),
            variableUsage = hex("#df69ba"),
            assignment = hex("#f85552"),
            currency = hex("#8da101"),
            unit = hex("#35a77c"),
            results = hex("#8da101"),
            comment = hex("#939f91")
        )
    ),
    NumbyTheme(
        name = "Palenight",
        syntax = SyntaxColors(
            text = hex("#a6accd"),
            background = hex("#292d3e"),
            number = hex("#f78c6c"),
            operator = hex("#89ddff"),
            keyword = hex("#c792ea"),
            function = hex("#ffcb6b"),
            constant = hex("#f78c6c"),
            variable = hex("#89ddff"),
            variableUsage = hex("#c792ea"),
            assignment = hex("#89ddff"),
            currency = hex("#c3e88d"),
            unit = hex("#89ddff"),
            results = hex("#c3e88d"),
            comment = hex("#676e95")
        )
    ),
    NumbyTheme(
        name = "One Dark",
        syntax = SyntaxColors(
            text = hex("#abb2bf"),
            background = hex("#282c34"),
            number = hex("#61afef"),
            operator = hex("#e06c75"),
            keyword = hex("#c678dd"),
            function = hex("#e5c07b"),
            constant = hex("#61afef"),
            variable = hex("#56b6c2"),
            variableUsage = hex("#c678dd"),
            assignment = hex("#e06c75"),
            currency = hex("#98c379"),
            unit = hex("#56b6c2"),
            results = hex("#98c379"),
            comment = hex("#5c6370")
        )
    ),
    NumbyTheme(
        name = "One Light",
        syntax = SyntaxColors(
            text = hex("#383a42"),
            background = hex("#fafafa"),
            number = hex("#4078f2"),
            operator = hex("#e45649"),
            keyword = hex("#a626a4"),
            function = hex("#986801"),
            constant = hex("#4078f2"),
            variable = hex("#0184bc"),
            variableUsage = hex("#a626a4"),
            assignment = hex("#e45649"),
            currency = hex("#50a14f"),
            unit = hex("#0184bc"),
            results = hex("#50a14f"),
            comment = hex("#a0a1a7")
        )
    ),
    NumbyTheme(
        name = "Panda",
        syntax = SyntaxColors(
            text = hex("#e6e6e6"),
            background = hex("#292a2b"),
            number = hex("#ffb86c"),
            operator = hex("#ff2c6d"),
            keyword = hex("#ff9ac1"),
            function = hex("#e6e6e6"),
            constant = hex("#ffb86c"),
            variable = hex("#19f9d8"),
            variableUsage = hex("#ff9ac1"),
            assignment = hex("#ff2c6d"),
            currency = hex("#19f9d8"),
            unit = hex("#19f9d8"),
            results = hex("#19f9d8"),
            comment = hex("#676b79")
        )
    ),
    NumbyTheme(
        name = "Flatland",
        syntax = SyntaxColors(
            text = hex("#93979b"),
            background = hex("#1d1f21"),
            number = hex("#72aaca"),
            operator = hex("#e55e5f"),
            keyword = hex("#b85f66"),
            function = hex("#f0c547"),
            constant = hex("#72aaca"),
            variable = hex("#00bdba"),
            variableUsage = hex("#b85f66"),
            assignment = hex("#e55e5f"),
            currency = hex("#98c653"),
            unit = hex("#00bdba"),
            results = hex("#98c653"),
            comment = hex("#49505a")
        )
    ),
    NumbyTheme(
        name = "Molokai",
        syntax = SyntaxColors(
            text = hex("#bbbbbb"),
            background = hex("#121212"),
            number = hex("#1080d0"),
            operator = hex("#fa2573"),
            keyword = hex("#8700ff"),
            function = hex("#dfd460"),
            constant = hex("#1080d0"),
            variable = hex("#43a8d0"),
            variableUsage = hex("#8700ff"),
            assignment = hex("#fa2573"),
            currency = hex("#98e123"),
            unit = hex("#43a8d0"),
            results = hex("#98e123"),
            comment = hex("#555555")
        )
    ),
    NumbyTheme(
        name = "Neon",
        syntax = SyntaxColors(
            text = hex("#00fffc"),
            background = hex("#14161a"),
            number = hex("#0f15d8"),
            operator = hex("#ff3045"),
            keyword = hex("#f924e7"),
            function = hex("#fffc7e"),
            constant = hex("#0f15d8"),
            variable = hex("#00fffc"),
            variableUsage = hex("#f924e7"),
            assignment = hex("#ff3045"),
            currency = hex("#5ffa74"),
            unit = hex("#00fffc"),
            results = hex("#5ffa74"),
            comment = hex("#686868")
        )
    ),
    NumbyTheme(
        name = "Retro",
        syntax = SyntaxColors(
            text = hex("#13a10e"),
            background = hex("#000000"),
            number = hex("#13a10e"),
            operator = hex("#13a10e"),
            keyword = hex("#13a10e"),
            function = hex("#13a10e"),
            constant = hex("#13a10e"),
            variable = hex("#13a10e"),
            variableUsage = hex("#13a10e"),
            assignment = hex("#13a10e"),
            currency = hex("#13a10e"),
            unit = hex("#13a10e"),
            results = hex("#13a10e"),
            comment = hex("#16ba10")
        )
    ),
    NumbyTheme(
        name = "Twilight",
        syntax = SyntaxColors(
            text = hex("#ffffd4"),
            background = hex("#141414"),
            number = hex("#44474a"),
            operator = hex("#c06d44"),
            keyword = hex("#b4be7c"),
            function = hex("#c2a86c"),
            constant = hex("#44474a"),
            variable = hex("#778385"),
            variableUsage = hex("#b4be7c"),
            assignment = hex("#c06d44"),
            currency = hex("#afb97a"),
            unit = hex("#778385"),
            results = hex("#afb97a"),
            comment = hex("#404040")
        )
    ),
    NumbyTheme(
        name = "Rebecca",
        syntax = SyntaxColors(
            text = hex("#e8e6ed"),
            background = hex("#292a44"),
            number = hex("#7aa5ff"),
            operator = hex("#dd7755"),
            keyword = hex("#bf9cf9"),
            function = hex("#f2e7b7"),
            constant = hex("#7aa5ff"),
            variable = hex("#56d3c2"),
            variableUsage = hex("#bf9cf9"),
            assignment = hex("#dd7755"),
            currency = hex("#04dbb5"),
            unit = hex("#56d3c2"),
            results = hex("#04dbb5"),
            comment = hex("#666699")
        )
    ),
    NumbyTheme(
        name = "Paraiso Dark",
        syntax = SyntaxColors(
            text = hex("#a39e9b"),
            background = hex("#2f1e2e"),
            number = hex("#06b6ef"),
            operator = hex("#ef6155"),
            keyword = hex("#815ba4"),
            function = hex("#fec418"),
            constant = hex("#06b6ef"),
            variable = hex("#5bc4bf"),
            variableUsage = hex("#815ba4"),
            assignment = hex("#ef6155"),
            currency = hex("#48b685"),
            unit = hex("#5bc4bf"),
            results = hex("#48b685"),
            comment = hex("#776e71")
        )
    ),
    NumbyTheme(
        name = "Ultra Violent",
        syntax = SyntaxColors(
            text = hex("#c1c1c1"),
            background = hex("#242728"),
            number = hex("#47e0fb"),
            operator = hex("#ff0090"),
            keyword = hex("#d731ff"),
            function = hex("#fff727"),
            constant = hex("#47e0fb"),
            variable = hex("#0effbb"),
            variableUsage = hex("#d731ff"),
            assignment = hex("#ff0090"),
            currency = hex("#b6ff00"),
            unit = hex("#0effbb"),
            results = hex("#b6ff00"),
            comment = hex("#636667")
        )
    ),
    NumbyTheme(
        name = "Selenized Dark",
        syntax = SyntaxColors(
            text = hex("#adbcbc"),
            background = hex("#103c48"),
            number = hex("#4695f7"),
            operator = hex("#fa5750"),
            keyword = hex("#f275be"),
            function = hex("#dbb32d"),
            constant = hex("#4695f7"),
            variable = hex("#41c7b9"),
            variableUsage = hex("#f275be"),
            assignment = hex("#fa5750"),
            currency = hex("#75b938"),
            unit = hex("#41c7b9"),
            results = hex("#75b938"),
            comment = hex("#396775")
        )
    ),
    NumbyTheme(
        name = "Selenized Light",
        syntax = SyntaxColors(
            text = hex("#53676d"),
            background = hex("#fbf3db"),
            number = hex("#0072d4"),
            operator = hex("#d2212d"),
            keyword = hex("#ca4898"),
            function = hex("#ad8900"),
            constant = hex("#0072d4"),
            variable = hex("#009c8f"),
            variableUsage = hex("#ca4898"),
            assignment = hex("#d2212d"),
            currency = hex("#489100"),
            unit = hex("#009c8f"),
            results = hex("#489100"),
            comment = hex("#bbb39c")
        )
    ),
    NumbyTheme(
        name = "Srcery",
        syntax = SyntaxColors(
            text = hex("#fce8c3"),
            background = hex("#1c1b19"),
            number = hex("#2c78bf"),
            operator = hex("#ef2f27"),
            keyword = hex("#e02c6d"),
            function = hex("#fbb829"),
            constant = hex("#2c78bf"),
            variable = hex("#0aaeb3"),
            variableUsage = hex("#e02c6d"),
            assignment = hex("#ef2f27"),
            currency = hex("#519f50"),
            unit = hex("#0aaeb3"),
            results = hex("#519f50"),
            comment = hex("#918175")
        )
    ),
    NumbyTheme(
        name = "Soft Server",
        syntax = SyntaxColors(
            text = hex("#99a3a2"),
            background = hex("#242626"),
            number = hex("#6b8fa3"),
            operator = hex("#a2686a"),
            keyword = hex("#6a71a3"),
            function = hex("#a3906a"),
            constant = hex("#6b8fa3"),
            variable = hex("#6ba58f"),
            variableUsage = hex("#6a71a3"),
            assignment = hex("#a2686a"),
            currency = hex("#9aa56a"),
            unit = hex("#6ba58f"),
            results = hex("#9aa56a"),
            comment = hex("#666c6c")
        )
    ),
    NumbyTheme(
        name = "Obsidian",
        syntax = SyntaxColors(
            text = hex("#cdcdcd"),
            background = hex("#283033"),
            number = hex("#3a9bdb"),
            operator = hex("#b30d0e"),
            keyword = hex("#bb00bb"),
            function = hex("#fecd22"),
            constant = hex("#3a9bdb"),
            variable = hex("#00bbbb"),
            variableUsage = hex("#bb00bb"),
            assignment = hex("#b30d0e"),
            currency = hex("#00bb00"),
            unit = hex("#00bbbb"),
            results = hex("#00bb00"),
            comment = hex("#555555")
        )
    ),
    NumbyTheme(
        name = "Neopolitan",
        syntax = SyntaxColors(
            text = hex("#ffffff"),
            background = hex("#271f19"),
            number = hex("#324883"),
            operator = hex("#9a1a1a"),
            keyword = hex("#ff0080"),
            function = hex("#fbde2d"),
            constant = hex("#324883"),
            variable = hex("#8da6ce"),
            variableUsage = hex("#ff0080"),
            assignment = hex("#9a1a1a"),
            currency = hex("#61ce3c"),
            unit = hex("#8da6ce"),
            results = hex("#61ce3c"),
            comment = hex("#4c4c4c")
        )
    ),
    NumbyTheme(
        name = "Powershell",
        syntax = SyntaxColors(
            text = hex("#f6f6f7"),
            background = hex("#052454"),
            number = hex("#403fc2"),
            operator = hex("#971921"),
            keyword = hex("#d33682"),
            function = hex("#c4a000"),
            constant = hex("#403fc2"),
            variable = hex("#0e807f"),
            variableUsage = hex("#d33682"),
            assignment = hex("#971921"),
            currency = hex("#098003"),
            unit = hex("#0e807f"),
            results = hex("#098003"),
            comment = hex("#808080")
        )
    ),
    NumbyTheme(
        name = "Tin",
        syntax = SyntaxColors(
            text = hex("#c0c0c0"),
            background = hex("#272727"),
            number = hex("#7cafc2"),
            operator = hex("#ab4642"),
            keyword = hex("#ba8baf"),
            function = hex("#f7ca88"),
            constant = hex("#7cafc2"),
            variable = hex("#86c1b9"),
            variableUsage = hex("#ba8baf"),
            assignment = hex("#ab4642"),
            currency = hex("#a1b56c"),
            unit = hex("#86c1b9"),
            results = hex("#a1b56c"),
            comment = hex("#585858")
        )
    ),
    NumbyTheme(
        name = "Ivory",
        syntax = SyntaxColors(
            text = hex("#2e2e2e"),
            background = hex("#fffff8"),
            number = hex("#2176c7"),
            operator = hex("#d11c24"),
            keyword = hex("#c61c6f"),
            function = hex("#a57706"),
            constant = hex("#2176c7"),
            variable = hex("#259286"),
            variableUsage = hex("#c61c6f"),
            assignment = hex("#d11c24"),
            currency = hex("#738a05"),
            unit = hex("#259286"),
            results = hex("#738a05"),
            comment = hex("#93a1a1")
        )
    ),
    NumbyTheme(
        name = "Monochrome",
        syntax = SyntaxColors(
            text = hex("#ffffff"),
            background = hex("#000000"),
            number = hex("#ffffff"),
            operator = hex("#ffffff"),
            keyword = hex("#ffffff"),
            function = hex("#ffffff"),
            constant = hex("#ffffff"),
            variable = hex("#ffffff"),
            variableUsage = hex("#ffffff"),
            assignment = hex("#ffffff"),
            currency = hex("#ffffff"),
            unit = hex("#ffffff"),
            results = hex("#ffffff"),
            comment = hex("#888888")
        )
    ),
    NumbyTheme(
        name = "0x96f",
        syntax = SyntaxColors(
            text = hex("#fcfcfa"),
            background = hex("#262427"),
            number = hex("#00cde8"),
            operator = hex("#ff666d"),
            keyword = hex("#a392e8"),
            function = hex("#ffc739"),
            constant = hex("#00cde8"),
            variable = hex("#9deaf6"),
            variableUsage = hex("#a392e8"),
            assignment = hex("#ff666d"),
            currency = hex("#b3e03a"),
            unit = hex("#9deaf6"),
            results = hex("#b3e03a"),
            comment = hex("#545452")
        )
    ),
    NumbyTheme(
        name = "12-bit Rainbow",
        syntax = SyntaxColors(
            text = hex("#feffff"),
            background = hex("#040404"),
            number = hex("#3060b0"),
            operator = hex("#a03050"),
            keyword = hex("#603090"),
            function = hex("#e09040"),
            constant = hex("#3060b0"),
            variable = hex("#0090c0"),
            variableUsage = hex("#603090"),
            assignment = hex("#a03050"),
            currency = hex("#40d080"),
            unit = hex("#0090c0"),
            results = hex("#40d080"),
            comment = hex("#685656")
        )
    ),
    NumbyTheme(
        name = "Aardvark Blue",
        syntax = SyntaxColors(
            text = hex("#dddddd"),
            background = hex("#102040"),
            number = hex("#1370d3"),
            operator = hex("#aa342e"),
            keyword = hex("#c43ac3"),
            function = hex("#dbba00"),
            constant = hex("#1370d3"),
            variable = hex("#008eb0"),
            variableUsage = hex("#c43ac3"),
            assignment = hex("#aa342e"),
            currency = hex("#4b8c0f"),
            unit = hex("#008eb0"),
            results = hex("#4b8c0f"),
            comment = hex("#525252")
        )
    ),
    NumbyTheme(
        name = "Abernathy",
        syntax = SyntaxColors(
            text = hex("#eeeeec"),
            background = hex("#111416"),
            number = hex("#1093f5"),
            operator = hex("#cd0000"),
            keyword = hex("#cd00cd"),
            function = hex("#cdcd00"),
            constant = hex("#1093f5"),
            variable = hex("#00cdcd"),
            variableUsage = hex("#cd00cd"),
            assignment = hex("#cd0000"),
            currency = hex("#00cd00"),
            unit = hex("#00cdcd"),
            results = hex("#00cd00"),
            comment = hex("#404040")
        )
    ),
    NumbyTheme(
        name = "Adventure Time",
        syntax = SyntaxColors(
            text = hex("#f8dcc0"),
            background = hex("#1f1d45"),
            number = hex("#0f4ac6"),
            operator = hex("#bd0013"),
            keyword = hex("#665993"),
            function = hex("#e7741e"),
            constant = hex("#0f4ac6"),
            variable = hex("#70a598"),
            variableUsage = hex("#665993"),
            assignment = hex("#bd0013"),
            currency = hex("#4ab118"),
            unit = hex("#70a598"),
            results = hex("#4ab118"),
            comment = hex("#4e7cbf")
        )
    ),
    NumbyTheme(
        name = "Alien Blood",
        syntax = SyntaxColors(
            text = hex("#637d75"),
            background = hex("#0f1610"),
            number = hex("#2f6a7f"),
            operator = hex("#7f2b27"),
            keyword = hex("#47587f"),
            function = hex("#717f24"),
            constant = hex("#2f6a7f"),
            variable = hex("#327f77"),
            variableUsage = hex("#47587f"),
            assignment = hex("#7f2b27"),
            currency = hex("#2f7e25"),
            unit = hex("#327f77"),
            results = hex("#2f7e25"),
            comment = hex("#3c4812")
        )
    ),
    NumbyTheme(
        name = "Apple Classic",
        syntax = SyntaxColors(
            text = hex("#d5a200"),
            background = hex("#2c2b2b"),
            number = hex("#1c3fe1"),
            operator = hex("#c91b00"),
            keyword = hex("#ca30c7"),
            function = hex("#c7c400"),
            constant = hex("#1c3fe1"),
            variable = hex("#00c5c7"),
            variableUsage = hex("#ca30c7"),
            assignment = hex("#c91b00"),
            currency = hex("#00c200"),
            unit = hex("#00c5c7"),
            results = hex("#00c200"),
            comment = hex("#686868")
        )
    ),
    NumbyTheme(
        name = "Apple System Colors",
        syntax = SyntaxColors(
            text = hex("#ffffff"),
            background = hex("#1e1e1e"),
            number = hex("#0869cb"),
            operator = hex("#cc372e"),
            keyword = hex("#9647bf"),
            function = hex("#cdac08"),
            constant = hex("#0869cb"),
            variable = hex("#479ec2"),
            variableUsage = hex("#9647bf"),
            assignment = hex("#cc372e"),
            currency = hex("#26a439"),
            unit = hex("#479ec2"),
            results = hex("#26a439"),
            comment = hex("#464646")
        )
    ),
    NumbyTheme(
        name = "Apple System Colors Light",
        syntax = SyntaxColors(
            text = hex("#000000"),
            background = hex("#feffff"),
            number = hex("#0869cb"),
            operator = hex("#cc372e"),
            keyword = hex("#9647bf"),
            function = hex("#cdac08"),
            constant = hex("#0869cb"),
            variable = hex("#479ec2"),
            variableUsage = hex("#9647bf"),
            assignment = hex("#cc372e"),
            currency = hex("#26a439"),
            unit = hex("#479ec2"),
            results = hex("#26a439"),
            comment = hex("#464646")
        )
    ),
    NumbyTheme(
        name = "Arcoiris",
        syntax = SyntaxColors(
            text = hex("#eee4d9"),
            background = hex("#201f1e"),
            number = hex("#518bfc"),
            operator = hex("#da2700"),
            keyword = hex("#e37bd9"),
            function = hex("#ffc656"),
            constant = hex("#518bfc"),
            variable = hex("#63fad5"),
            variableUsage = hex("#e37bd9"),
            assignment = hex("#da2700"),
            currency = hex("#12c258"),
            unit = hex("#63fad5"),
            results = hex("#12c258"),
            comment = hex("#777777")
        )
    ),
    NumbyTheme(
        name = "Ardoise",
        syntax = SyntaxColors(
            text = hex("#eaeaea"),
            background = hex("#1e1e1e"),
            number = hex("#2465c2"),
            operator = hex("#d3322d"),
            keyword = hex("#7332b4"),
            function = hex("#fca93a"),
            constant = hex("#2465c2"),
            variable = hex("#64e1b8"),
            variableUsage = hex("#7332b4"),
            assignment = hex("#d3322d"),
            currency = hex("#588b35"),
            unit = hex("#64e1b8"),
            results = hex("#588b35"),
            comment = hex("#535353")
        )
    ),
    NumbyTheme(
        name = "Atelier Sulphurpool",
        syntax = SyntaxColors(
            text = hex("#979db4"),
            background = hex("#202746"),
            number = hex("#3d8fd1"),
            operator = hex("#c94922"),
            keyword = hex("#6679cc"),
            function = hex("#c08b30"),
            constant = hex("#3d8fd1"),
            variable = hex("#22a2c9"),
            variableUsage = hex("#6679cc"),
            assignment = hex("#c94922"),
            currency = hex("#ac9739"),
            unit = hex("#22a2c9"),
            results = hex("#ac9739"),
            comment = hex("#6b7394")
        )
    ),
    NumbyTheme(
        name = "Atom",
        syntax = SyntaxColors(
            text = hex("#c5c8c6"),
            background = hex("#161719"),
            number = hex("#85befd"),
            operator = hex("#fd5ff1"),
            keyword = hex("#b9b6fc"),
            function = hex("#ffd7b1"),
            constant = hex("#85befd"),
            variable = hex("#85befd"),
            variableUsage = hex("#b9b6fc"),
            assignment = hex("#fd5ff1"),
            currency = hex("#87c38a"),
            unit = hex("#85befd"),
            results = hex("#87c38a"),
            comment = hex("#4c4c4c")
        )
    ),
    NumbyTheme(
        name = "Batman",
        syntax = SyntaxColors(
            text = hex("#6f6f6f"),
            background = hex("#1b1d1e"),
            number = hex("#737174"),
            operator = hex("#e6dc44"),
            keyword = hex("#747271"),
            function = hex("#f4fd22"),
            constant = hex("#737174"),
            variable = hex("#62605f"),
            variableUsage = hex("#747271"),
            assignment = hex("#e6dc44"),
            currency = hex("#c8be46"),
            unit = hex("#62605f"),
            results = hex("#c8be46"),
            comment = hex("#505354")
        )
    ),
    NumbyTheme(
        name = "Belafonte Day",
        syntax = SyntaxColors(
            text = hex("#45373c"),
            background = hex("#d5ccba"),
            number = hex("#426a79"),
            operator = hex("#be100e"),
            keyword = hex("#97522c"),
            function = hex("#d08b30"),
            constant = hex("#426a79"),
            variable = hex("#989a9c"),
            variableUsage = hex("#97522c"),
            assignment = hex("#be100e"),
            currency = hex("#858162"),
            unit = hex("#989a9c"),
            results = hex("#858162"),
            comment = hex("#5e5252")
        )
    ),
    NumbyTheme(
        name = "Belafonte Night",
        syntax = SyntaxColors(
            text = hex("#968c83"),
            background = hex("#20111b"),
            number = hex("#426a79"),
            operator = hex("#be100e"),
            keyword = hex("#97522c"),
            function = hex("#eaa549"),
            constant = hex("#426a79"),
            variable = hex("#989a9c"),
            variableUsage = hex("#97522c"),
            assignment = hex("#be100e"),
            currency = hex("#858162"),
            unit = hex("#989a9c"),
            results = hex("#858162"),
            comment = hex("#5e5252")
        )
    ),
    NumbyTheme(
        name = "Black Metal",
        syntax = SyntaxColors(
            text = hex("#c1c1c1"),
            background = hex("#000000"),
            number = hex("#888888"),
            operator = hex("#486e6f"),
            keyword = hex("#999999"),
            function = hex("#a06666"),
            constant = hex("#888888"),
            variable = hex("#aaaaaa"),
            variableUsage = hex("#999999"),
            assignment = hex("#486e6f"),
            currency = hex("#dd9999"),
            unit = hex("#aaaaaa"),
            results = hex("#dd9999"),
            comment = hex("#3f3f3f")
        )
    ),
    NumbyTheme(
        name = "Black Metal (Bathory)",
        syntax = SyntaxColors(
            text = hex("#c1c1c1"),
            background = hex("#000000"),
            number = hex("#888888"),
            operator = hex("#5f8787"),
            keyword = hex("#999999"),
            function = hex("#e78a53"),
            constant = hex("#888888"),
            variable = hex("#aaaaaa"),
            variableUsage = hex("#999999"),
            assignment = hex("#5f8787"),
            currency = hex("#fbcb97"),
            unit = hex("#aaaaaa"),
            results = hex("#fbcb97"),
            comment = hex("#3f3f3f")
        )
    ),
    NumbyTheme(
        name = "Black Metal (Burzum)",
        syntax = SyntaxColors(
            text = hex("#c1c1c1"),
            background = hex("#000000"),
            number = hex("#888888"),
            operator = hex("#5f8787"),
            keyword = hex("#999999"),
            function = hex("#99bbaa"),
            constant = hex("#888888"),
            variable = hex("#aaaaaa"),
            variableUsage = hex("#999999"),
            assignment = hex("#5f8787"),
            currency = hex("#ddeecc"),
            unit = hex("#aaaaaa"),
            results = hex("#ddeecc"),
            comment = hex("#3f3f3f")
        )
    ),
    NumbyTheme(
        name = "Black Metal (Dark Funeral)",
        syntax = SyntaxColors(
            text = hex("#c1c1c1"),
            background = hex("#000000"),
            number = hex("#888888"),
            operator = hex("#5f8787"),
            keyword = hex("#999999"),
            function = hex("#5f81a5"),
            constant = hex("#888888"),
            variable = hex("#aaaaaa"),
            variableUsage = hex("#999999"),
            assignment = hex("#5f8787"),
            currency = hex("#d0dfee"),
            unit = hex("#aaaaaa"),
            results = hex("#d0dfee"),
            comment = hex("#3f3f3f")
        )
    ),
    NumbyTheme(
        name = "Black Metal (Gorgoroth)",
        syntax = SyntaxColors(
            text = hex("#c1c1c1"),
            background = hex("#000000"),
            number = hex("#888888"),
            operator = hex("#5f8787"),
            keyword = hex("#999999"),
            function = hex("#8c7f70"),
            constant = hex("#888888"),
            variable = hex("#aaaaaa"),
            variableUsage = hex("#999999"),
            assignment = hex("#5f8787"),
            currency = hex("#9b8d7f"),
            unit = hex("#aaaaaa"),
            results = hex("#9b8d7f"),
            comment = hex("#3f3f3f")
        )
    ),
    NumbyTheme(
        name = "Black Metal (Immortal)",
        syntax = SyntaxColors(
            text = hex("#c1c1c1"),
            background = hex("#000000"),
            number = hex("#888888"),
            operator = hex("#5f8787"),
            keyword = hex("#999999"),
            function = hex("#556677"),
            constant = hex("#888888"),
            variable = hex("#aaaaaa"),
            variableUsage = hex("#999999"),
            assignment = hex("#5f8787"),
            currency = hex("#7799bb"),
            unit = hex("#aaaaaa"),
            results = hex("#7799bb"),
            comment = hex("#3f3f3f")
        )
    ),
    NumbyTheme(
        name = "Black Metal (Khold)",
        syntax = SyntaxColors(
            text = hex("#c1c1c1"),
            background = hex("#000000"),
            number = hex("#888888"),
            operator = hex("#5f8787"),
            keyword = hex("#999999"),
            function = hex("#974b46"),
            constant = hex("#888888"),
            variable = hex("#aaaaaa"),
            variableUsage = hex("#999999"),
            assignment = hex("#5f8787"),
            currency = hex("#eceee3"),
            unit = hex("#aaaaaa"),
            results = hex("#eceee3"),
            comment = hex("#3f3f3f")
        )
    ),
    NumbyTheme(
        name = "Black Metal (Marduk)",
        syntax = SyntaxColors(
            text = hex("#c1c1c1"),
            background = hex("#000000"),
            number = hex("#888888"),
            operator = hex("#5f8787"),
            keyword = hex("#999999"),
            function = hex("#626b67"),
            constant = hex("#888888"),
            variable = hex("#aaaaaa"),
            variableUsage = hex("#999999"),
            assignment = hex("#5f8787"),
            currency = hex("#a5aaa7"),
            unit = hex("#aaaaaa"),
            results = hex("#a5aaa7"),
            comment = hex("#3f3f3f")
        )
    ),
    NumbyTheme(
        name = "Black Metal (Mayhem)",
        syntax = SyntaxColors(
            text = hex("#c1c1c1"),
            background = hex("#000000"),
            number = hex("#888888"),
            operator = hex("#5f8787"),
            keyword = hex("#999999"),
            function = hex("#eecc6c"),
            constant = hex("#888888"),
            variable = hex("#aaaaaa"),
            variableUsage = hex("#999999"),
            assignment = hex("#5f8787"),
            currency = hex("#f3ecd4"),
            unit = hex("#aaaaaa"),
            results = hex("#f3ecd4"),
            comment = hex("#3f3f3f")
        )
    ),
    NumbyTheme(
        name = "Black Metal (Nile)",
        syntax = SyntaxColors(
            text = hex("#c1c1c1"),
            background = hex("#000000"),
            number = hex("#888888"),
            operator = hex("#5f8787"),
            keyword = hex("#999999"),
            function = hex("#777755"),
            constant = hex("#888888"),
            variable = hex("#aaaaaa"),
            variableUsage = hex("#999999"),
            assignment = hex("#5f8787"),
            currency = hex("#aa9988"),
            unit = hex("#aaaaaa"),
            results = hex("#aa9988"),
            comment = hex("#3f3f3f")
        )
    ),
    NumbyTheme(
        name = "Black Metal (Venom)",
        syntax = SyntaxColors(
            text = hex("#c1c1c1"),
            background = hex("#000000"),
            number = hex("#888888"),
            operator = hex("#5f8787"),
            keyword = hex("#999999"),
            function = hex("#79241f"),
            constant = hex("#888888"),
            variable = hex("#aaaaaa"),
            variableUsage = hex("#999999"),
            assignment = hex("#5f8787"),
            currency = hex("#f8f7f2"),
            unit = hex("#aaaaaa"),
            results = hex("#f8f7f2"),
            comment = hex("#3f3f3f")
        )
    ),
    NumbyTheme(
        name = "Blue Berry Pie",
        syntax = SyntaxColors(
            text = hex("#babab9"),
            background = hex("#1c0c28"),
            number = hex("#90a5bd"),
            operator = hex("#99246e"),
            keyword = hex("#9d54a7"),
            function = hex("#eab9a8"),
            constant = hex("#90a5bd"),
            variable = hex("#7e83cc"),
            variableUsage = hex("#9d54a7"),
            assignment = hex("#99246e"),
            currency = hex("#5cb1b3"),
            unit = hex("#7e83cc"),
            results = hex("#5cb1b3"),
            comment = hex("#463d5d")
        )
    ),
    NumbyTheme(
        name = "Blue Dolphin",
        syntax = SyntaxColors(
            text = hex("#c5f2ff"),
            background = hex("#006984"),
            number = hex("#82aaff"),
            operator = hex("#ff8288"),
            keyword = hex("#e9c1ff"),
            function = hex("#f4d69f"),
            constant = hex("#82aaff"),
            variable = hex("#89ebff"),
            variableUsage = hex("#e9c1ff"),
            assignment = hex("#ff8288"),
            currency = hex("#b4e88d"),
            unit = hex("#89ebff"),
            results = hex("#b4e88d"),
            comment = hex("#838798")
        )
    ),
    NumbyTheme(
        name = "Borland",
        syntax = SyntaxColors(
            text = hex("#ffff4e"),
            background = hex("#0000a4"),
            number = hex("#96cbfe"),
            operator = hex("#ff6c60"),
            keyword = hex("#ff73fd"),
            function = hex("#ffffb6"),
            constant = hex("#96cbfe"),
            variable = hex("#c6c5fe"),
            variableUsage = hex("#ff73fd"),
            assignment = hex("#ff6c60"),
            currency = hex("#a8ff60"),
            unit = hex("#c6c5fe"),
            results = hex("#a8ff60"),
            comment = hex("#7c7c7c")
        )
    ),
    NumbyTheme(
        name = "Box",
        syntax = SyntaxColors(
            text = hex("#9fef00"),
            background = hex("#141d2b"),
            number = hex("#0d73cc"),
            operator = hex("#cc0403"),
            keyword = hex("#cb1ed1"),
            function = hex("#cecb00"),
            constant = hex("#0d73cc"),
            variable = hex("#0dcdcd"),
            variableUsage = hex("#cb1ed1"),
            assignment = hex("#cc0403"),
            currency = hex("#19cb00"),
            unit = hex("#0dcdcd"),
            results = hex("#19cb00"),
            comment = hex("#767676")
        )
    ),
    NumbyTheme(
        name = "Breadog",
        syntax = SyntaxColors(
            text = hex("#362c24"),
            background = hex("#f1ebe6"),
            number = hex("#005cb4"),
            operator = hex("#b10b00"),
            keyword = hex("#9b0097"),
            function = hex("#8b4c00"),
            constant = hex("#005cb4"),
            variable = hex("#006a78"),
            variableUsage = hex("#9b0097"),
            assignment = hex("#b10b00"),
            currency = hex("#007232"),
            unit = hex("#006a78"),
            results = hex("#007232"),
            comment = hex("#514337")
        )
    ),
    NumbyTheme(
        name = "Breeze",
        syntax = SyntaxColors(
            text = hex("#eff0f1"),
            background = hex("#31363b"),
            number = hex("#1d99f3"),
            operator = hex("#ed1515"),
            keyword = hex("#9b59b6"),
            function = hex("#f67400"),
            constant = hex("#1d99f3"),
            variable = hex("#1abc9c"),
            variableUsage = hex("#9b59b6"),
            assignment = hex("#ed1515"),
            currency = hex("#11d116"),
            unit = hex("#1abc9c"),
            results = hex("#11d116"),
            comment = hex("#7f8c8d")
        )
    ),
    NumbyTheme(
        name = "Bright Lights",
        syntax = SyntaxColors(
            text = hex("#b3c9d7"),
            background = hex("#191919"),
            number = hex("#76d4ff"),
            operator = hex("#ff355b"),
            keyword = hex("#ba76e7"),
            function = hex("#ffc251"),
            constant = hex("#76d4ff"),
            variable = hex("#6cbfb5"),
            variableUsage = hex("#ba76e7"),
            assignment = hex("#ff355b"),
            currency = hex("#b7e876"),
            unit = hex("#6cbfb5"),
            results = hex("#b7e876"),
            comment = hex("#4c4c4c")
        )
    ),
    NumbyTheme(
        name = "Broadcast",
        syntax = SyntaxColors(
            text = hex("#e6e1dc"),
            background = hex("#2b2b2b"),
            number = hex("#6d9cbe"),
            operator = hex("#da4939"),
            keyword = hex("#d0d0ff"),
            function = hex("#ffd24a"),
            constant = hex("#6d9cbe"),
            variable = hex("#6e9cbe"),
            variableUsage = hex("#d0d0ff"),
            assignment = hex("#da4939"),
            currency = hex("#519f50"),
            unit = hex("#6e9cbe"),
            results = hex("#519f50"),
            comment = hex("#585858")
        )
    ),
    NumbyTheme(
        name = "Brogrammer",
        syntax = SyntaxColors(
            text = hex("#d6dbe5"),
            background = hex("#131313"),
            number = hex("#2a84d2"),
            operator = hex("#f81118"),
            keyword = hex("#4e5ab7"),
            function = hex("#ecba0f"),
            constant = hex("#2a84d2"),
            variable = hex("#1081d6"),
            variableUsage = hex("#4e5ab7"),
            assignment = hex("#f81118"),
            currency = hex("#2dc55e"),
            unit = hex("#1081d6"),
            results = hex("#2dc55e"),
            comment = hex("#d6dbe5")
        )
    ),
    NumbyTheme(
        name = "Builtin Dark",
        syntax = SyntaxColors(
            text = hex("#bbbbbb"),
            background = hex("#000000"),
            number = hex("#0d0dc8"),
            operator = hex("#bb0000"),
            keyword = hex("#bb00bb"),
            function = hex("#bbbb00"),
            constant = hex("#0d0dc8"),
            variable = hex("#00bbbb"),
            variableUsage = hex("#bb00bb"),
            assignment = hex("#bb0000"),
            currency = hex("#00bb00"),
            unit = hex("#00bbbb"),
            results = hex("#00bb00"),
            comment = hex("#555555")
        )
    ),
    NumbyTheme(
        name = "Builtin Light",
        syntax = SyntaxColors(
            text = hex("#000000"),
            background = hex("#ffffff"),
            number = hex("#0000bb"),
            operator = hex("#bb0000"),
            keyword = hex("#bb00bb"),
            function = hex("#bbbb00"),
            constant = hex("#0000bb"),
            variable = hex("#00bbbb"),
            variableUsage = hex("#bb00bb"),
            assignment = hex("#bb0000"),
            currency = hex("#00bb00"),
            unit = hex("#00bbbb"),
            results = hex("#00bb00"),
            comment = hex("#555555")
        )
    ),
    NumbyTheme(
        name = "Builtin Pastel Dark",
        syntax = SyntaxColors(
            text = hex("#bbbbbb"),
            background = hex("#000000"),
            number = hex("#96cbfe"),
            operator = hex("#ff6c60"),
            keyword = hex("#ff73fd"),
            function = hex("#ffffb6"),
            constant = hex("#96cbfe"),
            variable = hex("#c6c5fe"),
            variableUsage = hex("#ff73fd"),
            assignment = hex("#ff6c60"),
            currency = hex("#a8ff60"),
            unit = hex("#c6c5fe"),
            results = hex("#a8ff60"),
            comment = hex("#7c7c7c")
        )
    ),
    NumbyTheme(
        name = "Builtin Solarized Dark",
        syntax = SyntaxColors(
            text = hex("#839496"),
            background = hex("#002b36"),
            number = hex("#268bd2"),
            operator = hex("#dc322f"),
            keyword = hex("#d33682"),
            function = hex("#b58900"),
            constant = hex("#268bd2"),
            variable = hex("#2aa198"),
            variableUsage = hex("#d33682"),
            assignment = hex("#dc322f"),
            currency = hex("#859900"),
            unit = hex("#2aa198"),
            results = hex("#859900"),
            comment = hex("#335e69")
        )
    ),
    NumbyTheme(
        name = "Builtin Solarized Light",
        syntax = SyntaxColors(
            text = hex("#657b83"),
            background = hex("#fdf6e3"),
            number = hex("#268bd2"),
            operator = hex("#dc322f"),
            keyword = hex("#d33682"),
            function = hex("#b58900"),
            constant = hex("#268bd2"),
            variable = hex("#2aa198"),
            variableUsage = hex("#d33682"),
            assignment = hex("#dc322f"),
            currency = hex("#859900"),
            unit = hex("#2aa198"),
            results = hex("#859900"),
            comment = hex("#002b36")
        )
    ),
    NumbyTheme(
        name = "Builtin Tango Dark",
        syntax = SyntaxColors(
            text = hex("#ffffff"),
            background = hex("#000000"),
            number = hex("#3465a4"),
            operator = hex("#cc0000"),
            keyword = hex("#75507b"),
            function = hex("#c4a000"),
            constant = hex("#3465a4"),
            variable = hex("#06989a"),
            variableUsage = hex("#75507b"),
            assignment = hex("#cc0000"),
            currency = hex("#4e9a06"),
            unit = hex("#06989a"),
            results = hex("#4e9a06"),
            comment = hex("#555753")
        )
    ),
    NumbyTheme(
        name = "Builtin Tango Light",
        syntax = SyntaxColors(
            text = hex("#000000"),
            background = hex("#ffffff"),
            number = hex("#3465a4"),
            operator = hex("#cc0000"),
            keyword = hex("#75507b"),
            function = hex("#c4a000"),
            constant = hex("#3465a4"),
            variable = hex("#06989a"),
            variableUsage = hex("#75507b"),
            assignment = hex("#cc0000"),
            currency = hex("#4e9a06"),
            unit = hex("#06989a"),
            results = hex("#4e9a06"),
            comment = hex("#555753")
        )
    ),
    NumbyTheme(
        name = "C64",
        syntax = SyntaxColors(
            text = hex("#7869c4"),
            background = hex("#40318d"),
            number = hex("#6657b3"),
            operator = hex("#a2534c"),
            keyword = hex("#984ca3"),
            function = hex("#bfce72"),
            constant = hex("#6657b3"),
            variable = hex("#67b6bd"),
            variableUsage = hex("#984ca3"),
            assignment = hex("#a2534c"),
            currency = hex("#55a049"),
            unit = hex("#67b6bd"),
            results = hex("#55a049"),
            comment = hex("#000000")
        )
    ),
    NumbyTheme(
        name = "CGA",
        syntax = SyntaxColors(
            text = hex("#aaaaaa"),
            background = hex("#000000"),
            number = hex("#0d0db7"),
            operator = hex("#aa0000"),
            keyword = hex("#aa00aa"),
            function = hex("#aa5500"),
            constant = hex("#0d0db7"),
            variable = hex("#00aaaa"),
            variableUsage = hex("#aa00aa"),
            assignment = hex("#aa0000"),
            currency = hex("#00aa00"),
            unit = hex("#00aaaa"),
            results = hex("#00aa00"),
            comment = hex("#555555")
        )
    ),
    NumbyTheme(
        name = "CLRS",
        syntax = SyntaxColors(
            text = hex("#262626"),
            background = hex("#ffffff"),
            number = hex("#135cd0"),
            operator = hex("#f8282a"),
            keyword = hex("#9f00bd"),
            function = hex("#fa701d"),
            constant = hex("#135cd0"),
            variable = hex("#33c3c1"),
            variableUsage = hex("#9f00bd"),
            assignment = hex("#f8282a"),
            currency = hex("#328a5d"),
            unit = hex("#33c3c1"),
            results = hex("#328a5d"),
            comment = hex("#555753")
        )
    ),
    NumbyTheme(
        name = "Calamity",
        syntax = SyntaxColors(
            text = hex("#d5ced9"),
            background = hex("#2f2833"),
            number = hex("#3b79c7"),
            operator = hex("#fc644d"),
            keyword = hex("#f92672"),
            function = hex("#e9d7a5"),
            constant = hex("#3b79c7"),
            variable = hex("#74d3de"),
            variableUsage = hex("#f92672"),
            assignment = hex("#fc644d"),
            currency = hex("#a5f69c"),
            unit = hex("#74d3de"),
            results = hex("#a5f69c"),
            comment = hex("#7e6c88")
        )
    ),
    NumbyTheme(
        name = "Carbonfox",
        syntax = SyntaxColors(
            text = hex("#f2f4f8"),
            background = hex("#161616"),
            number = hex("#78a9ff"),
            operator = hex("#ee5396"),
            keyword = hex("#be95ff"),
            function = hex("#08bdba"),
            constant = hex("#78a9ff"),
            variable = hex("#33b1ff"),
            variableUsage = hex("#be95ff"),
            assignment = hex("#ee5396"),
            currency = hex("#25be6a"),
            unit = hex("#33b1ff"),
            results = hex("#25be6a"),
            comment = hex("#484848")
        )
    ),
    NumbyTheme(
        name = "Chalk",
        syntax = SyntaxColors(
            text = hex("#d2d8d9"),
            background = hex("#2b2d2e"),
            number = hex("#2a7fac"),
            operator = hex("#b23a52"),
            keyword = hex("#bd4f5a"),
            function = hex("#b9ac4a"),
            constant = hex("#2a7fac"),
            variable = hex("#44a799"),
            variableUsage = hex("#bd4f5a"),
            assignment = hex("#b23a52"),
            currency = hex("#789b6a"),
            unit = hex("#44a799"),
            results = hex("#789b6a"),
            comment = hex("#888888")
        )
    ),
    NumbyTheme(
        name = "Chalkboard",
        syntax = SyntaxColors(
            text = hex("#d9e6f2"),
            background = hex("#29262f"),
            number = hex("#7372c3"),
            operator = hex("#c37372"),
            keyword = hex("#c372c2"),
            function = hex("#c2c372"),
            constant = hex("#7372c3"),
            variable = hex("#72c2c3"),
            variableUsage = hex("#c372c2"),
            assignment = hex("#c37372"),
            currency = hex("#72c373"),
            unit = hex("#72c2c3"),
            results = hex("#72c373"),
            comment = hex("#585858")
        )
    ),
    NumbyTheme(
        name = "Challenger Deep",
        syntax = SyntaxColors(
            text = hex("#cbe1e7"),
            background = hex("#1e1c31"),
            number = hex("#65b2ff"),
            operator = hex("#ff5458"),
            keyword = hex("#906cff"),
            function = hex("#ffb378"),
            constant = hex("#65b2ff"),
            variable = hex("#63f2f1"),
            variableUsage = hex("#906cff"),
            assignment = hex("#ff5458"),
            currency = hex("#62d196"),
            unit = hex("#63f2f1"),
            results = hex("#62d196"),
            comment = hex("#565575")
        )
    ),
    NumbyTheme(
        name = "Chester",
        syntax = SyntaxColors(
            text = hex("#ffffff"),
            background = hex("#2c3643"),
            number = hex("#288ad6"),
            operator = hex("#fa5e5b"),
            keyword = hex("#d34590"),
            function = hex("#ffc83f"),
            constant = hex("#288ad6"),
            variable = hex("#28ddde"),
            variableUsage = hex("#d34590"),
            assignment = hex("#fa5e5b"),
            currency = hex("#16c98d"),
            unit = hex("#28ddde"),
            results = hex("#16c98d"),
            comment = hex("#6f6b68")
        )
    ),
    NumbyTheme(
        name = "Ciapre",
        syntax = SyntaxColors(
            text = hex("#aea47a"),
            background = hex("#191c27"),
            number = hex("#576d8c"),
            operator = hex("#8e0d16"),
            keyword = hex("#724d7c"),
            function = hex("#cc8b3f"),
            constant = hex("#576d8c"),
            variable = hex("#5c4f4b"),
            variableUsage = hex("#724d7c"),
            assignment = hex("#8e0d16"),
            currency = hex("#48513b"),
            unit = hex("#5c4f4b"),
            results = hex("#48513b"),
            comment = hex("#555555")
        )
    ),
    NumbyTheme(
        name = "Citruszest",
        syntax = SyntaxColors(
            text = hex("#bfbfbf"),
            background = hex("#121212"),
            number = hex("#00bfff"),
            operator = hex("#ff5454"),
            keyword = hex("#ff90fe"),
            function = hex("#ffd400"),
            constant = hex("#00bfff"),
            variable = hex("#48d1cc"),
            variableUsage = hex("#ff90fe"),
            assignment = hex("#ff5454"),
            currency = hex("#00cc7a"),
            unit = hex("#48d1cc"),
            results = hex("#00cc7a"),
            comment = hex("#808080")
        )
    ),
    NumbyTheme(
        name = "Cobalt Next",
        syntax = SyntaxColors(
            text = hex("#d7deea"),
            background = hex("#162c35"),
            number = hex("#409dd4"),
            operator = hex("#ff527b"),
            keyword = hex("#cba3c7"),
            function = hex("#ffc64c"),
            constant = hex("#409dd4"),
            variable = hex("#37b5b4"),
            variableUsage = hex("#cba3c7"),
            assignment = hex("#ff527b"),
            currency = hex("#8cc98f"),
            unit = hex("#37b5b4"),
            results = hex("#8cc98f"),
            comment = hex("#62747f")
        )
    ),
    NumbyTheme(
        name = "Cobalt Next Dark",
        syntax = SyntaxColors(
            text = hex("#d7deea"),
            background = hex("#0b1c24"),
            number = hex("#409dd4"),
            operator = hex("#f94967"),
            keyword = hex("#cba3c7"),
            function = hex("#ffc64c"),
            constant = hex("#409dd4"),
            variable = hex("#37b5b4"),
            variableUsage = hex("#cba3c7"),
            assignment = hex("#f94967"),
            currency = hex("#8cc98f"),
            unit = hex("#37b5b4"),
            results = hex("#8cc98f"),
            comment = hex("#62747f")
        )
    ),
    NumbyTheme(
        name = "Cobalt Next Minimal",
        syntax = SyntaxColors(
            text = hex("#d7deea"),
            background = hex("#0b1c24"),
            number = hex("#409dd4"),
            operator = hex("#ff657a"),
            keyword = hex("#cba3c7"),
            function = hex("#ffc64c"),
            constant = hex("#409dd4"),
            variable = hex("#37b5b4"),
            variableUsage = hex("#cba3c7"),
            assignment = hex("#ff657a"),
            currency = hex("#8cc98f"),
            unit = hex("#37b5b4"),
            results = hex("#8cc98f"),
            comment = hex("#62747f")
        )
    ),
    NumbyTheme(
        name = "Coffee Theme",
        syntax = SyntaxColors(
            text = hex("#000000"),
            background = hex("#f5deb3"),
            number = hex("#0225c7"),
            operator = hex("#c91b00"),
            keyword = hex("#ca30c7"),
            function = hex("#aeab00"),
            constant = hex("#0225c7"),
            variable = hex("#00b9bb"),
            variableUsage = hex("#ca30c7"),
            assignment = hex("#c91b00"),
            currency = hex("#00c200"),
            unit = hex("#00b9bb"),
            results = hex("#00c200"),
            comment = hex("#686868")
        )
    ),
    NumbyTheme(
        name = "Crayon Pony Fish",
        syntax = SyntaxColors(
            text = hex("#68525a"),
            background = hex("#150707"),
            number = hex("#8c87b0"),
            operator = hex("#91002b"),
            keyword = hex("#692f50"),
            function = hex("#ab311b"),
            constant = hex("#8c87b0"),
            variable = hex("#e8a866"),
            variableUsage = hex("#692f50"),
            assignment = hex("#91002b"),
            currency = hex("#579524"),
            unit = hex("#e8a866"),
            results = hex("#579524"),
            comment = hex("#49373b")
        )
    ),
    NumbyTheme(
        name = "Cursor Dark",
        syntax = SyntaxColors(
            text = hex("#ffffff"),
            background = hex("#141414"),
            number = hex("#81a1c1"),
            operator = hex("#bf616a"),
            keyword = hex("#b48ead"),
            function = hex("#ebcb8b"),
            constant = hex("#81a1c1"),
            variable = hex("#88c0d0"),
            variableUsage = hex("#b48ead"),
            assignment = hex("#bf616a"),
            currency = hex("#a3be8c"),
            unit = hex("#88c0d0"),
            results = hex("#a3be8c"),
            comment = hex("#505050")
        )
    ),
    NumbyTheme(
        name = "Cutie Pro",
        syntax = SyntaxColors(
            text = hex("#d5d0c9"),
            background = hex("#181818"),
            number = hex("#42d9c5"),
            operator = hex("#f56e7f"),
            keyword = hex("#d286b7"),
            function = hex("#f58669"),
            constant = hex("#42d9c5"),
            variable = hex("#37cb8a"),
            variableUsage = hex("#d286b7"),
            assignment = hex("#f56e7f"),
            currency = hex("#bec975"),
            unit = hex("#37cb8a"),
            results = hex("#bec975"),
            comment = hex("#88847f")
        )
    ),
    NumbyTheme(
        name = "Cyberdyne",
        syntax = SyntaxColors(
            text = hex("#00ff92"),
            background = hex("#151144"),
            number = hex("#0071cf"),
            operator = hex("#ff8373"),
            keyword = hex("#ff90fe"),
            function = hex("#d2a700"),
            constant = hex("#0071cf"),
            variable = hex("#6bffdd"),
            variableUsage = hex("#ff90fe"),
            assignment = hex("#ff8373"),
            currency = hex("#00c172"),
            unit = hex("#6bffdd"),
            results = hex("#00c172"),
            comment = hex("#474747")
        )
    ),
    NumbyTheme(
        name = "Cyberpunk",
        syntax = SyntaxColors(
            text = hex("#e5e5e5"),
            background = hex("#332a57"),
            number = hex("#00bfff"),
            operator = hex("#ff7092"),
            keyword = hex("#df95ff"),
            function = hex("#fffa6a"),
            constant = hex("#00bfff"),
            variable = hex("#86cbfe"),
            variableUsage = hex("#df95ff"),
            assignment = hex("#ff7092"),
            currency = hex("#00fbac"),
            unit = hex("#86cbfe"),
            results = hex("#00fbac"),
            comment = hex("#595959")
        )
    ),
    NumbyTheme(
        name = "Cyberpunk Scarlet Protocol",
        syntax = SyntaxColors(
            text = hex("#e41951"),
            background = hex("#101116"),
            number = hex("#0271b6"),
            operator = hex("#ff0051"),
            keyword = hex("#c930c7"),
            function = hex("#faf945"),
            constant = hex("#0271b6"),
            variable = hex("#00c5c7"),
            variableUsage = hex("#c930c7"),
            assignment = hex("#ff0051"),
            currency = hex("#01dc84"),
            unit = hex("#00c5c7"),
            results = hex("#01dc84"),
            comment = hex("#686868")
        )
    ),
    NumbyTheme(
        name = "Dark Modern",
        syntax = SyntaxColors(
            text = hex("#cccccc"),
            background = hex("#1f1f1f"),
            number = hex("#0078d4"),
            operator = hex("#f74949"),
            keyword = hex("#d01273"),
            function = hex("#9e6a03"),
            constant = hex("#0078d4"),
            variable = hex("#1db4d6"),
            variableUsage = hex("#d01273"),
            assignment = hex("#f74949"),
            currency = hex("#2ea043"),
            unit = hex("#1db4d6"),
            results = hex("#2ea043"),
            comment = hex("#5d5d5d")
        )
    ),
    NumbyTheme(
        name = "Dark Pastel",
        syntax = SyntaxColors(
            text = hex("#ffffff"),
            background = hex("#000000"),
            number = hex("#5555ff"),
            operator = hex("#ff5555"),
            keyword = hex("#ff55ff"),
            function = hex("#ffff55"),
            constant = hex("#5555ff"),
            variable = hex("#55ffff"),
            variableUsage = hex("#ff55ff"),
            assignment = hex("#ff5555"),
            currency = hex("#55ff55"),
            unit = hex("#55ffff"),
            results = hex("#55ff55"),
            comment = hex("#555555")
        )
    ),
    NumbyTheme(
        name = "Dark+",
        syntax = SyntaxColors(
            text = hex("#cccccc"),
            background = hex("#1e1e1e"),
            number = hex("#2472c8"),
            operator = hex("#cd3131"),
            keyword = hex("#bc3fbc"),
            function = hex("#e5e510"),
            constant = hex("#2472c8"),
            variable = hex("#11a8cd"),
            variableUsage = hex("#bc3fbc"),
            assignment = hex("#cd3131"),
            currency = hex("#0dbc79"),
            unit = hex("#11a8cd"),
            results = hex("#0dbc79"),
            comment = hex("#666666")
        )
    ),
    NumbyTheme(
        name = "Darkermatrix",
        syntax = SyntaxColors(
            text = hex("#35451a"),
            background = hex("#070c0e"),
            number = hex("#00cb6b"),
            operator = hex("#1a4832"),
            keyword = hex("#4e375a"),
            function = hex("#595900"),
            constant = hex("#00cb6b"),
            variable = hex("#125459"),
            variableUsage = hex("#4e375a"),
            assignment = hex("#1a4832"),
            currency = hex("#6fa64c"),
            unit = hex("#125459"),
            results = hex("#6fa64c"),
            comment = hex("#404040")
        )
    ),
    NumbyTheme(
        name = "Darkmatrix",
        syntax = SyntaxColors(
            text = hex("#3e5715"),
            background = hex("#070c0e"),
            number = hex("#2c9a84"),
            operator = hex("#006536"),
            keyword = hex("#523a60"),
            function = hex("#7e8000"),
            constant = hex("#2c9a84"),
            variable = hex("#114d53"),
            variableUsage = hex("#523a60"),
            assignment = hex("#006536"),
            currency = hex("#6fa64c"),
            unit = hex("#114d53"),
            results = hex("#6fa64c"),
            comment = hex("#404040")
        )
    ),
    NumbyTheme(
        name = "Darkside",
        syntax = SyntaxColors(
            text = hex("#bababa"),
            background = hex("#222324"),
            number = hex("#1c98e8"),
            operator = hex("#e8341c"),
            keyword = hex("#8e69c9"),
            function = hex("#f2d42c"),
            constant = hex("#1c98e8"),
            variable = hex("#1c98e8"),
            variableUsage = hex("#8e69c9"),
            assignment = hex("#e8341c"),
            currency = hex("#68c256"),
            unit = hex("#1c98e8"),
            results = hex("#68c256"),
            comment = hex("#4c4c4c")
        )
    ),
    NumbyTheme(
        name = "Dawnfox",
        syntax = SyntaxColors(
            text = hex("#575279"),
            background = hex("#faf4ed"),
            number = hex("#286983"),
            operator = hex("#b4637a"),
            keyword = hex("#907aa9"),
            function = hex("#ea9d34"),
            constant = hex("#286983"),
            variable = hex("#56949f"),
            variableUsage = hex("#907aa9"),
            assignment = hex("#b4637a"),
            currency = hex("#618774"),
            unit = hex("#56949f"),
            results = hex("#618774"),
            comment = hex("#5f5695")
        )
    ),
    NumbyTheme(
        name = "Dayfox",
        syntax = SyntaxColors(
            text = hex("#3d2b5a"),
            background = hex("#f6f2ee"),
            number = hex("#2848a9"),
            operator = hex("#a5222f"),
            keyword = hex("#6e33ce"),
            function = hex("#ac5402"),
            constant = hex("#2848a9"),
            variable = hex("#287980"),
            variableUsage = hex("#6e33ce"),
            assignment = hex("#a5222f"),
            currency = hex("#396847"),
            unit = hex("#287980"),
            results = hex("#396847"),
            comment = hex("#534c45")
        )
    ),
    NumbyTheme(
        name = "Deep",
        syntax = SyntaxColors(
            text = hex("#cdcdcd"),
            background = hex("#090909"),
            number = hex("#5665ff"),
            operator = hex("#d70005"),
            keyword = hex("#b052da"),
            function = hex("#d9bd26"),
            constant = hex("#5665ff"),
            variable = hex("#50d2da"),
            variableUsage = hex("#b052da"),
            assignment = hex("#d70005"),
            currency = hex("#1cd915"),
            unit = hex("#50d2da"),
            results = hex("#1cd915"),
            comment = hex("#535353")
        )
    ),
    NumbyTheme(
        name = "Desert",
        syntax = SyntaxColors(
            text = hex("#ffffff"),
            background = hex("#333333"),
            number = hex("#cd853f"),
            operator = hex("#ff2b2b"),
            keyword = hex("#ffdead"),
            function = hex("#f0e68c"),
            constant = hex("#cd853f"),
            variable = hex("#ffa0a0"),
            variableUsage = hex("#ffdead"),
            assignment = hex("#ff2b2b"),
            currency = hex("#98fb98"),
            unit = hex("#ffa0a0"),
            results = hex("#98fb98"),
            comment = hex("#626262")
        )
    ),
    NumbyTheme(
        name = "Detuned",
        syntax = SyntaxColors(
            text = hex("#c7c7c7"),
            background = hex("#000000"),
            number = hex("#0094d9"),
            operator = hex("#fe4386"),
            keyword = hex("#9b37ff"),
            function = hex("#e6da73"),
            constant = hex("#0094d9"),
            variable = hex("#50b7d9"),
            variableUsage = hex("#9b37ff"),
            assignment = hex("#fe4386"),
            currency = hex("#a6e32d"),
            unit = hex("#50b7d9"),
            results = hex("#a6e32d"),
            comment = hex("#686868")
        )
    ),
    NumbyTheme(
        name = "Dimidium",
        syntax = SyntaxColors(
            text = hex("#bab7b6"),
            background = hex("#141414"),
            number = hex("#0575d8"),
            operator = hex("#cf494c"),
            keyword = hex("#af5ed2"),
            function = hex("#db9c11"),
            constant = hex("#0575d8"),
            variable = hex("#1db6bb"),
            variableUsage = hex("#af5ed2"),
            assignment = hex("#cf494c"),
            currency = hex("#60b442"),
            unit = hex("#1db6bb"),
            results = hex("#60b442"),
            comment = hex("#817e7e")
        )
    ),
    NumbyTheme(
        name = "Dimmed Monokai",
        syntax = SyntaxColors(
            text = hex("#b9bcba"),
            background = hex("#1f1f1f"),
            number = hex("#4f76a1"),
            operator = hex("#be3f48"),
            keyword = hex("#855c8d"),
            function = hex("#c5a635"),
            constant = hex("#4f76a1"),
            variable = hex("#578fa4"),
            variableUsage = hex("#855c8d"),
            assignment = hex("#be3f48"),
            currency = hex("#879a3b"),
            unit = hex("#578fa4"),
            results = hex("#879a3b"),
            comment = hex("#888987")
        )
    ),
    NumbyTheme(
        name = "Django",
        syntax = SyntaxColors(
            text = hex("#f8f8f8"),
            background = hex("#0b2f20"),
            number = hex("#315d3f"),
            operator = hex("#fd6209"),
            keyword = hex("#f8f8f8"),
            function = hex("#ffe862"),
            constant = hex("#315d3f"),
            variable = hex("#9df39f"),
            variableUsage = hex("#f8f8f8"),
            assignment = hex("#fd6209"),
            currency = hex("#41a83e"),
            unit = hex("#9df39f"),
            results = hex("#41a83e"),
            comment = hex("#585858")
        )
    ),
    NumbyTheme(
        name = "Django Reborn Again",
        syntax = SyntaxColors(
            text = hex("#dadedc"),
            background = hex("#051f14"),
            number = hex("#245032"),
            operator = hex("#fd6209"),
            keyword = hex("#f8f8f8"),
            function = hex("#ffe862"),
            constant = hex("#245032"),
            variable = hex("#9df39f"),
            variableUsage = hex("#f8f8f8"),
            assignment = hex("#fd6209"),
            currency = hex("#41a83e"),
            unit = hex("#9df39f"),
            results = hex("#41a83e"),
            comment = hex("#4c4c4c")
        )
    ),
    NumbyTheme(
        name = "Django Smooth",
        syntax = SyntaxColors(
            text = hex("#f8f8f8"),
            background = hex("#245032"),
            number = hex("#989898"),
            operator = hex("#fd6209"),
            keyword = hex("#f8f8f8"),
            function = hex("#ffe862"),
            constant = hex("#989898"),
            variable = hex("#9df39f"),
            variableUsage = hex("#f8f8f8"),
            assignment = hex("#fd6209"),
            currency = hex("#41a83e"),
            unit = hex("#9df39f"),
            results = hex("#41a83e"),
            comment = hex("#727272")
        )
    ),
    NumbyTheme(
        name = "Doom One",
        syntax = SyntaxColors(
            text = hex("#bbc2cf"),
            background = hex("#282c34"),
            number = hex("#a9a1e1"),
            operator = hex("#ff6c6b"),
            keyword = hex("#c678dd"),
            function = hex("#ecbe7b"),
            constant = hex("#a9a1e1"),
            variable = hex("#51afef"),
            variableUsage = hex("#c678dd"),
            assignment = hex("#ff6c6b"),
            currency = hex("#98be65"),
            unit = hex("#51afef"),
            results = hex("#98be65"),
            comment = hex("#595959")
        )
    ),
    NumbyTheme(
        name = "Doom Peacock",
        syntax = SyntaxColors(
            text = hex("#ede0ce"),
            background = hex("#2b2a27"),
            number = hex("#2a6cc6"),
            operator = hex("#cb4b16"),
            keyword = hex("#a9a1e1"),
            function = hex("#bcd42a"),
            constant = hex("#2a6cc6"),
            variable = hex("#5699af"),
            variableUsage = hex("#a9a1e1"),
            assignment = hex("#cb4b16"),
            currency = hex("#26a6a6"),
            unit = hex("#5699af"),
            results = hex("#26a6a6"),
            comment = hex("#51504d")
        )
    ),
    NumbyTheme(
        name = "Dot Gov",
        syntax = SyntaxColors(
            text = hex("#ebebeb"),
            background = hex("#262c35"),
            number = hex("#17b2e0"),
            operator = hex("#bf091d"),
            keyword = hex("#7830b0"),
            function = hex("#f6bb34"),
            constant = hex("#17b2e0"),
            variable = hex("#8bd2ed"),
            variableUsage = hex("#7830b0"),
            assignment = hex("#bf091d"),
            currency = hex("#3d9751"),
            unit = hex("#8bd2ed"),
            results = hex("#3d9751"),
            comment = hex("#595959")
        )
    ),
    NumbyTheme(
        name = "Dracula+",
        syntax = SyntaxColors(
            text = hex("#f8f8f2"),
            background = hex("#212121"),
            number = hex("#82aaff"),
            operator = hex("#ff5555"),
            keyword = hex("#c792ea"),
            function = hex("#ffcb6b"),
            constant = hex("#82aaff"),
            variable = hex("#8be9fd"),
            variableUsage = hex("#c792ea"),
            assignment = hex("#ff5555"),
            currency = hex("#50fa7b"),
            unit = hex("#8be9fd"),
            results = hex("#50fa7b"),
            comment = hex("#545454")
        )
    ),
    NumbyTheme(
        name = "Duckbones",
        syntax = SyntaxColors(
            text = hex("#ebefc0"),
            background = hex("#0e101a"),
            number = hex("#00a3cb"),
            operator = hex("#e03600"),
            keyword = hex("#795ccc"),
            function = hex("#e39500"),
            constant = hex("#00a3cb"),
            variable = hex("#00a3cb"),
            variableUsage = hex("#795ccc"),
            assignment = hex("#e03600"),
            currency = hex("#5dcd97"),
            unit = hex("#00a3cb"),
            results = hex("#5dcd97"),
            comment = hex("#454860")
        )
    ),
    NumbyTheme(
        name = "Duotone Dark",
        syntax = SyntaxColors(
            text = hex("#b7a1ff"),
            background = hex("#1f1d27"),
            number = hex("#ffc284"),
            operator = hex("#d9393e"),
            keyword = hex("#de8d40"),
            function = hex("#d9b76e"),
            constant = hex("#ffc284"),
            variable = hex("#2488ff"),
            variableUsage = hex("#de8d40"),
            assignment = hex("#d9393e"),
            currency = hex("#2dcd73"),
            unit = hex("#2488ff"),
            results = hex("#2dcd73"),
            comment = hex("#4f4b60")
        )
    ),
    NumbyTheme(
        name = "Duskfox",
        syntax = SyntaxColors(
            text = hex("#e0def4"),
            background = hex("#232136"),
            number = hex("#569fba"),
            operator = hex("#eb6f92"),
            keyword = hex("#c4a7e7"),
            function = hex("#f6c177"),
            constant = hex("#569fba"),
            variable = hex("#9ccfd8"),
            variableUsage = hex("#c4a7e7"),
            assignment = hex("#eb6f92"),
            currency = hex("#a3be8c"),
            unit = hex("#9ccfd8"),
            results = hex("#a3be8c"),
            comment = hex("#544d8a")
        )
    ),
    NumbyTheme(
        name = "ENCOM",
        syntax = SyntaxColors(
            text = hex("#00a595"),
            background = hex("#000000"),
            number = hex("#0081ff"),
            operator = hex("#9f0000"),
            keyword = hex("#bc00ca"),
            function = hex("#ffd000"),
            constant = hex("#0081ff"),
            variable = hex("#008b8b"),
            variableUsage = hex("#bc00ca"),
            assignment = hex("#9f0000"),
            currency = hex("#008b00"),
            unit = hex("#008b8b"),
            results = hex("#008b00"),
            comment = hex("#555555")
        )
    ),
    NumbyTheme(
        name = "Earthsong",
        syntax = SyntaxColors(
            text = hex("#e5c7a9"),
            background = hex("#292520"),
            number = hex("#1398b9"),
            operator = hex("#c94234"),
            keyword = hex("#d0633d"),
            function = hex("#f5ae2e"),
            constant = hex("#1398b9"),
            variable = hex("#509552"),
            variableUsage = hex("#d0633d"),
            assignment = hex("#c94234"),
            currency = hex("#85c54c"),
            unit = hex("#509552"),
            results = hex("#85c54c"),
            comment = hex("#675f54")
        )
    ),
    NumbyTheme(
        name = "Electron Highlighter",
        syntax = SyntaxColors(
            text = hex("#a5b6d4"),
            background = hex("#23283d"),
            number = hex("#77abff"),
            operator = hex("#ff6c8d"),
            keyword = hex("#daa4f4"),
            function = hex("#ffd7a9"),
            constant = hex("#77abff"),
            variable = hex("#00fdff"),
            variableUsage = hex("#daa4f4"),
            assignment = hex("#ff6c8d"),
            currency = hex("#00ffc3"),
            unit = hex("#00fdff"),
            results = hex("#00ffc3"),
            comment = hex("#4a6789")
        )
    ),
    NumbyTheme(
        name = "Elegant",
        syntax = SyntaxColors(
            text = hex("#ced2d6"),
            background = hex("#292b31"),
            number = hex("#8dabe1"),
            operator = hex("#ff0257"),
            keyword = hex("#c792eb"),
            function = hex("#ffcb8b"),
            constant = hex("#8dabe1"),
            variable = hex("#78ccf0"),
            variableUsage = hex("#c792eb"),
            assignment = hex("#ff0257"),
            currency = hex("#85cc95"),
            unit = hex("#78ccf0"),
            results = hex("#85cc95"),
            comment = hex("#575656")
        )
    ),
    NumbyTheme(
        name = "Elemental",
        syntax = SyntaxColors(
            text = hex("#807a74"),
            background = hex("#22211d"),
            number = hex("#497f7d"),
            operator = hex("#98290f"),
            keyword = hex("#7f4e2f"),
            function = hex("#7f7111"),
            constant = hex("#497f7d"),
            variable = hex("#387f58"),
            variableUsage = hex("#7f4e2f"),
            assignment = hex("#98290f"),
            currency = hex("#479a43"),
            unit = hex("#387f58"),
            results = hex("#479a43"),
            comment = hex("#555445")
        )
    ),
    NumbyTheme(
        name = "Elementary",
        syntax = SyntaxColors(
            text = hex("#efefef"),
            background = hex("#181818"),
            number = hex("#124799"),
            operator = hex("#d71c15"),
            keyword = hex("#e40038"),
            function = hex("#fdb40c"),
            constant = hex("#124799"),
            variable = hex("#2595e1"),
            variableUsage = hex("#e40038"),
            assignment = hex("#d71c15"),
            currency = hex("#5aa513"),
            unit = hex("#2595e1"),
            results = hex("#5aa513"),
            comment = hex("#4b4b4b")
        )
    ),
    NumbyTheme(
        name = "Embark",
        syntax = SyntaxColors(
            text = hex("#eeffff"),
            background = hex("#1e1c31"),
            number = hex("#57c7ff"),
            operator = hex("#f0719b"),
            keyword = hex("#c792ea"),
            function = hex("#ffe9aa"),
            constant = hex("#57c7ff"),
            variable = hex("#87dfeb"),
            variableUsage = hex("#c792ea"),
            assignment = hex("#f0719b"),
            currency = hex("#a1efd3"),
            unit = hex("#87dfeb"),
            results = hex("#a1efd3"),
            comment = hex("#585273")
        )
    ),
    NumbyTheme(
        name = "Embers Dark",
        syntax = SyntaxColors(
            text = hex("#a39a90"),
            background = hex("#16130f"),
            number = hex("#6d5782"),
            operator = hex("#826d57"),
            keyword = hex("#82576d"),
            function = hex("#6d8257"),
            constant = hex("#6d5782"),
            variable = hex("#576d82"),
            variableUsage = hex("#82576d"),
            assignment = hex("#826d57"),
            currency = hex("#57826d"),
            unit = hex("#576d82"),
            results = hex("#57826d"),
            comment = hex("#5a5047")
        )
    ),
    NumbyTheme(
        name = "Espresso",
        syntax = SyntaxColors(
            text = hex("#ffffff"),
            background = hex("#323232"),
            number = hex("#6c99bb"),
            operator = hex("#d25252"),
            keyword = hex("#d197d9"),
            function = hex("#ffc66d"),
            constant = hex("#6c99bb"),
            variable = hex("#bed6ff"),
            variableUsage = hex("#d197d9"),
            assignment = hex("#d25252"),
            currency = hex("#a5c261"),
            unit = hex("#bed6ff"),
            results = hex("#a5c261"),
            comment = hex("#606060")
        )
    ),
    NumbyTheme(
        name = "Espresso Libre",
        syntax = SyntaxColors(
            text = hex("#b8a898"),
            background = hex("#2a211c"),
            number = hex("#0066ff"),
            operator = hex("#cc0000"),
            keyword = hex("#c5656b"),
            function = hex("#f0e53a"),
            constant = hex("#0066ff"),
            variable = hex("#06989a"),
            variableUsage = hex("#c5656b"),
            assignment = hex("#cc0000"),
            currency = hex("#1a921c"),
            unit = hex("#06989a"),
            results = hex("#1a921c"),
            comment = hex("#555753")
        )
    ),
    NumbyTheme(
        name = "Everblush",
        syntax = SyntaxColors(
            text = hex("#dadada"),
            background = hex("#141b1e"),
            number = hex("#67b0e8"),
            operator = hex("#e57474"),
            keyword = hex("#c47fd5"),
            function = hex("#e5c76b"),
            constant = hex("#67b0e8"),
            variable = hex("#6cbfbf"),
            variableUsage = hex("#c47fd5"),
            assignment = hex("#e57474"),
            currency = hex("#8ccf7e"),
            unit = hex("#6cbfbf"),
            results = hex("#8ccf7e"),
            comment = hex("#464e50")
        )
    ),
    NumbyTheme(
        name = "Everforest Dark Hard",
        syntax = SyntaxColors(
            text = hex("#d3c6aa"),
            background = hex("#1e2326"),
            number = hex("#7fbbb3"),
            operator = hex("#e67e80"),
            keyword = hex("#d699b6"),
            function = hex("#dbbc7f"),
            constant = hex("#7fbbb3"),
            variable = hex("#83c092"),
            variableUsage = hex("#d699b6"),
            assignment = hex("#e67e80"),
            currency = hex("#a7c080"),
            unit = hex("#83c092"),
            results = hex("#a7c080"),
            comment = hex("#a6b0a0")
        )
    ),
    NumbyTheme(
        name = "Everforest Light Med",
        syntax = SyntaxColors(
            text = hex("#5c6a72"),
            background = hex("#efebd4"),
            number = hex("#7fbbb3"),
            operator = hex("#e67e80"),
            keyword = hex("#d699b6"),
            function = hex("#c1a266"),
            constant = hex("#7fbbb3"),
            variable = hex("#83c092"),
            variableUsage = hex("#d699b6"),
            assignment = hex("#e67e80"),
            currency = hex("#9ab373"),
            unit = hex("#83c092"),
            results = hex("#9ab373"),
            comment = hex("#a6b0a0")
        )
    ),
    NumbyTheme(
        name = "Fahrenheit",
        syntax = SyntaxColors(
            text = hex("#ffffce"),
            background = hex("#000000"),
            number = hex("#7f0e0e"),
            operator = hex("#cda074"),
            keyword = hex("#734c4d"),
            function = hex("#fecf75"),
            constant = hex("#7f0e0e"),
            variable = hex("#979797"),
            variableUsage = hex("#734c4d"),
            assignment = hex("#cda074"),
            currency = hex("#9e744d"),
            unit = hex("#979797"),
            results = hex("#9e744d"),
            comment = hex("#404040")
        )
    ),
    NumbyTheme(
        name = "Fairyfloss",
        syntax = SyntaxColors(
            text = hex("#f8f8f2"),
            background = hex("#5a5475"),
            number = hex("#c2ffdf"),
            operator = hex("#f92672"),
            keyword = hex("#ffb8d1"),
            function = hex("#e6c000"),
            constant = hex("#c2ffdf"),
            variable = hex("#c5a3ff"),
            variableUsage = hex("#ffb8d1"),
            assignment = hex("#f92672"),
            currency = hex("#c2ffdf"),
            unit = hex("#c5a3ff"),
            results = hex("#c2ffdf"),
            comment = hex("#6090cb")
        )
    ),
    NumbyTheme(
        name = "Farmhouse Dark",
        syntax = SyntaxColors(
            text = hex("#e8e4e1"),
            background = hex("#1d2027"),
            number = hex("#0049e6"),
            operator = hex("#ba0004"),
            keyword = hex("#9f1b61"),
            function = hex("#c87300"),
            constant = hex("#0049e6"),
            variable = hex("#1fb65c"),
            variableUsage = hex("#9f1b61"),
            assignment = hex("#ba0004"),
            currency = hex("#549d00"),
            unit = hex("#1fb65c"),
            results = hex("#549d00"),
            comment = hex("#464d54")
        )
    ),
    NumbyTheme(
        name = "Farmhouse Light",
        syntax = SyntaxColors(
            text = hex("#1d2027"),
            background = hex("#e8e4e1"),
            number = hex("#092ccd"),
            operator = hex("#8d0003"),
            keyword = hex("#820046"),
            function = hex("#a95600"),
            constant = hex("#092ccd"),
            variable = hex("#229256"),
            variableUsage = hex("#820046"),
            assignment = hex("#8d0003"),
            currency = hex("#3a7d00"),
            unit = hex("#229256"),
            results = hex("#3a7d00"),
            comment = hex("#394047")
        )
    ),
    NumbyTheme(
        name = "Fideloper",
        syntax = SyntaxColors(
            text = hex("#dbdae0"),
            background = hex("#292f33"),
            number = hex("#2e78c2"),
            operator = hex("#cb1e2d"),
            keyword = hex("#c0236f"),
            function = hex("#b7ab9b"),
            constant = hex("#2e78c2"),
            variable = hex("#309186"),
            variableUsage = hex("#c0236f"),
            assignment = hex("#cb1e2d"),
            currency = hex("#edb8ac"),
            unit = hex("#309186"),
            results = hex("#edb8ac"),
            comment = hex("#496068")
        )
    ),
    NumbyTheme(
        name = "Firefly Traditional",
        syntax = SyntaxColors(
            text = hex("#f5f5f5"),
            background = hex("#000000"),
            number = hex("#5a63ff"),
            operator = hex("#c23720"),
            keyword = hex("#d53ad2"),
            function = hex("#afad24"),
            constant = hex("#5a63ff"),
            variable = hex("#33bbc7"),
            variableUsage = hex("#d53ad2"),
            assignment = hex("#c23720"),
            currency = hex("#33bc26"),
            unit = hex("#33bbc7"),
            results = hex("#33bc26"),
            comment = hex("#828282")
        )
    ),
    NumbyTheme(
        name = "Firefox Dev",
        syntax = SyntaxColors(
            text = hex("#7c8fa4"),
            background = hex("#0e1011"),
            number = hex("#359ddf"),
            operator = hex("#e63853"),
            keyword = hex("#d75cff"),
            function = hex("#a57706"),
            constant = hex("#359ddf"),
            variable = hex("#4b73a2"),
            variableUsage = hex("#d75cff"),
            assignment = hex("#e63853"),
            currency = hex("#5eb83c"),
            unit = hex("#4b73a2"),
            results = hex("#5eb83c"),
            comment = hex("#26444d")
        )
    ),
    NumbyTheme(
        name = "Firewatch",
        syntax = SyntaxColors(
            text = hex("#9ba2b2"),
            background = hex("#1e2027"),
            number = hex("#4d89c4"),
            operator = hex("#d95360"),
            keyword = hex("#d55119"),
            function = hex("#dfb563"),
            constant = hex("#4d89c4"),
            variable = hex("#44a8b6"),
            variableUsage = hex("#d55119"),
            assignment = hex("#d95360"),
            currency = hex("#5ab977"),
            unit = hex("#44a8b6"),
            results = hex("#5ab977"),
            comment = hex("#585f6d")
        )
    ),
    NumbyTheme(
        name = "Fish Tank",
        syntax = SyntaxColors(
            text = hex("#ecf0fe"),
            background = hex("#232537"),
            number = hex("#525fb8"),
            operator = hex("#c6004a"),
            keyword = hex("#986f82"),
            function = hex("#fecd5e"),
            constant = hex("#525fb8"),
            variable = hex("#968763"),
            variableUsage = hex("#986f82"),
            assignment = hex("#c6004a"),
            currency = hex("#acf157"),
            unit = hex("#968763"),
            results = hex("#acf157"),
            comment = hex("#6c5b30")
        )
    ),
    NumbyTheme(
        name = "Flat",
        syntax = SyntaxColors(
            text = hex("#2cc55d"),
            background = hex("#002240"),
            number = hex("#3167ac"),
            operator = hex("#a82320"),
            keyword = hex("#781aa0"),
            function = hex("#e58d11"),
            constant = hex("#3167ac"),
            variable = hex("#2c9370"),
            variableUsage = hex("#781aa0"),
            assignment = hex("#a82320"),
            currency = hex("#32a548"),
            unit = hex("#2c9370"),
            results = hex("#32a548"),
            comment = hex("#475262")
        )
    ),
    NumbyTheme(
        name = "Flexoki Dark",
        syntax = SyntaxColors(
            text = hex("#cecdc3"),
            background = hex("#100f0f"),
            number = hex("#4385be"),
            operator = hex("#d14d41"),
            keyword = hex("#ce5d97"),
            function = hex("#d0a215"),
            constant = hex("#4385be"),
            variable = hex("#3aa99f"),
            variableUsage = hex("#ce5d97"),
            assignment = hex("#d14d41"),
            currency = hex("#879a39"),
            unit = hex("#3aa99f"),
            results = hex("#879a39"),
            comment = hex("#575653")
        )
    ),
    NumbyTheme(
        name = "Flexoki Light",
        syntax = SyntaxColors(
            text = hex("#100f0f"),
            background = hex("#fffcf0"),
            number = hex("#205ea6"),
            operator = hex("#af3029"),
            keyword = hex("#a02f6f"),
            function = hex("#ad8301"),
            constant = hex("#205ea6"),
            variable = hex("#24837b"),
            variableUsage = hex("#a02f6f"),
            assignment = hex("#af3029"),
            currency = hex("#66800b"),
            unit = hex("#24837b"),
            results = hex("#66800b"),
            comment = hex("#b7b5ac")
        )
    ),
    NumbyTheme(
        name = "Floraverse",
        syntax = SyntaxColors(
            text = hex("#dbd1b9"),
            background = hex("#0e0d15"),
            number = hex("#1d6da1"),
            operator = hex("#7e1a46"),
            keyword = hex("#b7077e"),
            function = hex("#cd751c"),
            constant = hex("#1d6da1"),
            variable = hex("#42a38c"),
            variableUsage = hex("#b7077e"),
            assignment = hex("#7e1a46"),
            currency = hex("#5d731a"),
            unit = hex("#42a38c"),
            results = hex("#5d731a"),
            comment = hex("#4c3866")
        )
    ),
    NumbyTheme(
        name = "Forest Blue",
        syntax = SyntaxColors(
            text = hex("#e2d8cd"),
            background = hex("#051519"),
            number = hex("#8ed0ce"),
            operator = hex("#f8818e"),
            keyword = hex("#5e468c"),
            function = hex("#1a8e63"),
            constant = hex("#8ed0ce"),
            variable = hex("#31658c"),
            variableUsage = hex("#5e468c"),
            assignment = hex("#f8818e"),
            currency = hex("#92d3a2"),
            unit = hex("#31658c"),
            results = hex("#92d3a2"),
            comment = hex("#4a4a4a")
        )
    ),
    NumbyTheme(
        name = "Framer",
        syntax = SyntaxColors(
            text = hex("#777777"),
            background = hex("#111111"),
            number = hex("#00aaff"),
            operator = hex("#ff5555"),
            keyword = hex("#aa88ff"),
            function = hex("#ffcc33"),
            constant = hex("#00aaff"),
            variable = hex("#88ddff"),
            variableUsage = hex("#aa88ff"),
            assignment = hex("#ff5555"),
            currency = hex("#98ec65"),
            unit = hex("#88ddff"),
            results = hex("#98ec65"),
            comment = hex("#414141")
        )
    ),
    NumbyTheme(
        name = "Front End Delight",
        syntax = SyntaxColors(
            text = hex("#adadad"),
            background = hex("#1b1c1d"),
            number = hex("#2c70b7"),
            operator = hex("#f8511b"),
            keyword = hex("#f02e4f"),
            function = hex("#fa771d"),
            constant = hex("#2c70b7"),
            variable = hex("#3ca1a6"),
            variableUsage = hex("#f02e4f"),
            assignment = hex("#f8511b"),
            currency = hex("#565747"),
            unit = hex("#3ca1a6"),
            results = hex("#565747"),
            comment = hex("#5fac6d")
        )
    ),
    NumbyTheme(
        name = "Fun Forrest",
        syntax = SyntaxColors(
            text = hex("#dec165"),
            background = hex("#251200"),
            number = hex("#4699a3"),
            operator = hex("#d6262b"),
            keyword = hex("#8d4331"),
            function = hex("#be8a13"),
            constant = hex("#4699a3"),
            variable = hex("#da8213"),
            variableUsage = hex("#8d4331"),
            assignment = hex("#d6262b"),
            currency = hex("#919c00"),
            unit = hex("#da8213"),
            results = hex("#919c00"),
            comment = hex("#7f6a55")
        )
    ),
    NumbyTheme(
        name = "Galaxy",
        syntax = SyntaxColors(
            text = hex("#ffffff"),
            background = hex("#1d2837"),
            number = hex("#589df6"),
            operator = hex("#f9555f"),
            keyword = hex("#944d95"),
            function = hex("#fef02a"),
            constant = hex("#589df6"),
            variable = hex("#1f9ee7"),
            variableUsage = hex("#944d95"),
            assignment = hex("#f9555f"),
            currency = hex("#21b089"),
            unit = hex("#1f9ee7"),
            results = hex("#21b089"),
            comment = hex("#555555")
        )
    ),
    NumbyTheme(
        name = "Galizur",
        syntax = SyntaxColors(
            text = hex("#ddeeff"),
            background = hex("#071317"),
            number = hex("#2255cc"),
            operator = hex("#aa1122"),
            keyword = hex("#7755aa"),
            function = hex("#ccaa22"),
            constant = hex("#2255cc"),
            variable = hex("#22bbdd"),
            variableUsage = hex("#7755aa"),
            assignment = hex("#aa1122"),
            currency = hex("#33aa11"),
            unit = hex("#22bbdd"),
            results = hex("#33aa11"),
            comment = hex("#556677")
        )
    ),
    NumbyTheme(
        name = "Default Dark Style",
        syntax = SyntaxColors(
            text = hex("#ffffff"),
            background = hex("#282c34"),
            number = hex("#82a2be"),
            operator = hex("#cc6566"),
            keyword = hex("#b294bb"),
            function = hex("#f0c674"),
            constant = hex("#82a2be"),
            variable = hex("#8abeb7"),
            variableUsage = hex("#b294bb"),
            assignment = hex("#cc6566"),
            currency = hex("#b6bd68"),
            unit = hex("#8abeb7"),
            results = hex("#b6bd68"),
            comment = hex("#666666")
        )
    ),
    NumbyTheme(
        name = "GitHub",
        syntax = SyntaxColors(
            text = hex("#3e3e3e"),
            background = hex("#f4f4f4"),
            number = hex("#003e8a"),
            operator = hex("#970b16"),
            keyword = hex("#e94691"),
            function = hex("#c5bb94"),
            constant = hex("#003e8a"),
            variable = hex("#7cc4df"),
            variableUsage = hex("#e94691"),
            assignment = hex("#970b16"),
            currency = hex("#07962a"),
            unit = hex("#7cc4df"),
            results = hex("#07962a"),
            comment = hex("#666666")
        )
    ),
    NumbyTheme(
        name = "GitHub Dark Colorblind",
        syntax = SyntaxColors(
            text = hex("#c9d1d9"),
            background = hex("#0d1117"),
            number = hex("#58a6ff"),
            operator = hex("#ec8e2c"),
            keyword = hex("#bc8cff"),
            function = hex("#d29922"),
            constant = hex("#58a6ff"),
            variable = hex("#39c5cf"),
            variableUsage = hex("#bc8cff"),
            assignment = hex("#ec8e2c"),
            currency = hex("#58a6ff"),
            unit = hex("#39c5cf"),
            results = hex("#58a6ff"),
            comment = hex("#6e7681")
        )
    ),
    NumbyTheme(
        name = "GitHub Dark Dimmed",
        syntax = SyntaxColors(
            text = hex("#adbac7"),
            background = hex("#22272e"),
            number = hex("#539bf5"),
            operator = hex("#f47067"),
            keyword = hex("#b083f0"),
            function = hex("#c69026"),
            constant = hex("#539bf5"),
            variable = hex("#39c5cf"),
            variableUsage = hex("#b083f0"),
            assignment = hex("#f47067"),
            currency = hex("#57ab5a"),
            unit = hex("#39c5cf"),
            results = hex("#57ab5a"),
            comment = hex("#636e7b")
        )
    ),
    NumbyTheme(
        name = "GitHub Dark High Contrast",
        syntax = SyntaxColors(
            text = hex("#f0f3f6"),
            background = hex("#0a0c10"),
            number = hex("#71b7ff"),
            operator = hex("#ff9492"),
            keyword = hex("#cb9eff"),
            function = hex("#f0b72f"),
            constant = hex("#71b7ff"),
            variable = hex("#39c5cf"),
            variableUsage = hex("#cb9eff"),
            assignment = hex("#ff9492"),
            currency = hex("#26cd4d"),
            unit = hex("#39c5cf"),
            results = hex("#26cd4d"),
            comment = hex("#9ea7b3")
        )
    ),
    NumbyTheme(
        name = "GitHub Light Colorblind",
        syntax = SyntaxColors(
            text = hex("#24292f"),
            background = hex("#ffffff"),
            number = hex("#0969da"),
            operator = hex("#b35900"),
            keyword = hex("#8250df"),
            function = hex("#4d2d00"),
            constant = hex("#0969da"),
            variable = hex("#1b7c83"),
            variableUsage = hex("#8250df"),
            assignment = hex("#b35900"),
            currency = hex("#0550ae"),
            unit = hex("#1b7c83"),
            results = hex("#0550ae"),
            comment = hex("#57606a")
        )
    ),
    NumbyTheme(
        name = "GitHub Light High Contrast",
        syntax = SyntaxColors(
            text = hex("#0e1116"),
            background = hex("#ffffff"),
            number = hex("#0349b4"),
            operator = hex("#a0111f"),
            keyword = hex("#622cbc"),
            function = hex("#3f2200"),
            constant = hex("#0349b4"),
            variable = hex("#1b7c83"),
            variableUsage = hex("#622cbc"),
            assignment = hex("#a0111f"),
            currency = hex("#024c1a"),
            unit = hex("#1b7c83"),
            results = hex("#024c1a"),
            comment = hex("#4b535d")
        )
    ),
    NumbyTheme(
        name = "GitLab Dark",
        syntax = SyntaxColors(
            text = hex("#ffffff"),
            background = hex("#28262b"),
            number = hex("#7fb6ed"),
            operator = hex("#f57f6c"),
            keyword = hex("#f88aaf"),
            function = hex("#d99530"),
            constant = hex("#7fb6ed"),
            variable = hex("#32c5d2"),
            variableUsage = hex("#f88aaf"),
            assignment = hex("#f57f6c"),
            currency = hex("#52b87a"),
            unit = hex("#32c5d2"),
            results = hex("#52b87a"),
            comment = hex("#666666")
        )
    ),
    NumbyTheme(
        name = "GitLab Dark Grey",
        syntax = SyntaxColors(
            text = hex("#ffffff"),
            background = hex("#222222"),
            number = hex("#7fb6ed"),
            operator = hex("#f57f6c"),
            keyword = hex("#f88aaf"),
            function = hex("#d99530"),
            constant = hex("#7fb6ed"),
            variable = hex("#32c5d2"),
            variableUsage = hex("#f88aaf"),
            assignment = hex("#f57f6c"),
            currency = hex("#52b87a"),
            unit = hex("#32c5d2"),
            results = hex("#52b87a"),
            comment = hex("#666666")
        )
    ),
    NumbyTheme(
        name = "GitLab Light",
        syntax = SyntaxColors(
            text = hex("#303030"),
            background = hex("#fafaff"),
            number = hex("#006cd8"),
            operator = hex("#a31700"),
            keyword = hex("#583cac"),
            function = hex("#af551d"),
            constant = hex("#006cd8"),
            variable = hex("#00798a"),
            variableUsage = hex("#583cac"),
            assignment = hex("#a31700"),
            currency = hex("#0a7f3d"),
            unit = hex("#00798a"),
            results = hex("#0a7f3d"),
            comment = hex("#303030")
        )
    ),
    NumbyTheme(
        name = "Glacier",
        syntax = SyntaxColors(
            text = hex("#ffffff"),
            background = hex("#0c1115"),
            number = hex("#1f5872"),
            operator = hex("#bd0f2f"),
            keyword = hex("#bd2523"),
            function = hex("#fb9435"),
            constant = hex("#1f5872"),
            variable = hex("#778397"),
            variableUsage = hex("#bd2523"),
            assignment = hex("#bd0f2f"),
            currency = hex("#35a770"),
            unit = hex("#778397"),
            results = hex("#35a770"),
            comment = hex("#404a55")
        )
    ),
    NumbyTheme(
        name = "Grape",
        syntax = SyntaxColors(
            text = hex("#9f9fa1"),
            background = hex("#171423"),
            number = hex("#487df4"),
            operator = hex("#ed2261"),
            keyword = hex("#8d35c9"),
            function = hex("#8ddc20"),
            constant = hex("#487df4"),
            variable = hex("#3bdeed"),
            variableUsage = hex("#8d35c9"),
            assignment = hex("#ed2261"),
            currency = hex("#1fa91b"),
            unit = hex("#3bdeed"),
            results = hex("#1fa91b"),
            comment = hex("#59516a")
        )
    ),
    NumbyTheme(
        name = "Grass",
        syntax = SyntaxColors(
            text = hex("#fff0a5"),
            background = hex("#13773d"),
            number = hex("#0000a3"),
            operator = hex("#ff5959"),
            keyword = hex("#ee59bb"),
            function = hex("#e7b000"),
            constant = hex("#0000a3"),
            variable = hex("#00bbbb"),
            variableUsage = hex("#ee59bb"),
            assignment = hex("#ff5959"),
            currency = hex("#00bb00"),
            unit = hex("#00bbbb"),
            results = hex("#00bb00"),
            comment = hex("#959595")
        )
    ),
    NumbyTheme(
        name = "Grey Green",
        syntax = SyntaxColors(
            text = hex("#ffffff"),
            background = hex("#002a1a"),
            number = hex("#00deff"),
            operator = hex("#fe1414"),
            keyword = hex("#ff00f0"),
            function = hex("#f1ff01"),
            constant = hex("#00deff"),
            variable = hex("#00ffbc"),
            variableUsage = hex("#ff00f0"),
            assignment = hex("#fe1414"),
            currency = hex("#74ff00"),
            unit = hex("#00ffbc"),
            results = hex("#74ff00"),
            comment = hex("#666666")
        )
    ),
    NumbyTheme(
        name = "Gruber Darker",
        syntax = SyntaxColors(
            text = hex("#e4e4e4"),
            background = hex("#181818"),
            number = hex("#92a7cb"),
            operator = hex("#ff0a36"),
            keyword = hex("#a095cb"),
            function = hex("#ffdb00"),
            constant = hex("#92a7cb"),
            variable = hex("#90aa9e"),
            variableUsage = hex("#a095cb"),
            assignment = hex("#ff0a36"),
            currency = hex("#42dc00"),
            unit = hex("#90aa9e"),
            results = hex("#42dc00"),
            comment = hex("#54494e")
        )
    ),
    NumbyTheme(
        name = "Gruvbox Dark Hard",
        syntax = SyntaxColors(
            text = hex("#ebdbb2"),
            background = hex("#1d2021"),
            number = hex("#458588"),
            operator = hex("#cc241d"),
            keyword = hex("#b16286"),
            function = hex("#d79921"),
            constant = hex("#458588"),
            variable = hex("#689d6a"),
            variableUsage = hex("#b16286"),
            assignment = hex("#cc241d"),
            currency = hex("#98971a"),
            unit = hex("#689d6a"),
            results = hex("#98971a"),
            comment = hex("#928374")
        )
    ),
    NumbyTheme(
        name = "Gruvbox Light Hard",
        syntax = SyntaxColors(
            text = hex("#3c3836"),
            background = hex("#f9f5d7"),
            number = hex("#458588"),
            operator = hex("#cc241d"),
            keyword = hex("#b16286"),
            function = hex("#d79921"),
            constant = hex("#458588"),
            variable = hex("#689d6a"),
            variableUsage = hex("#b16286"),
            assignment = hex("#cc241d"),
            currency = hex("#98971a"),
            unit = hex("#689d6a"),
            results = hex("#98971a"),
            comment = hex("#928374")
        )
    ),
    NumbyTheme(
        name = "Gruvbox Material",
        syntax = SyntaxColors(
            text = hex("#d4be98"),
            background = hex("#1d2021"),
            number = hex("#6da3ec"),
            operator = hex("#ea6926"),
            keyword = hex("#fd9bc1"),
            function = hex("#eecf75"),
            constant = hex("#6da3ec"),
            variable = hex("#fe9d6e"),
            variableUsage = hex("#fd9bc1"),
            assignment = hex("#ea6926"),
            currency = hex("#c1d041"),
            unit = hex("#fe9d6e"),
            results = hex("#c1d041"),
            comment = hex("#4c4c4c")
        )
    ),
    NumbyTheme(
        name = "Gruvbox Material Light",
        syntax = SyntaxColors(
            text = hex("#654735"),
            background = hex("#fbf1c7"),
            number = hex("#45707a"),
            operator = hex("#c14a4a"),
            keyword = hex("#945e80"),
            function = hex("#b47109"),
            constant = hex("#45707a"),
            variable = hex("#4c7a5d"),
            variableUsage = hex("#945e80"),
            assignment = hex("#c14a4a"),
            currency = hex("#6c782e"),
            unit = hex("#4c7a5d"),
            results = hex("#6c782e"),
            comment = hex("#a89984")
        )
    ),
    NumbyTheme(
        name = "Guezwhoz",
        syntax = SyntaxColors(
            text = hex("#d9d9d9"),
            background = hex("#1d1d1d"),
            number = hex("#5aa0d6"),
            operator = hex("#e85181"),
            keyword = hex("#9a90e0"),
            function = hex("#b7d074"),
            constant = hex("#5aa0d6"),
            variable = hex("#58d6ce"),
            variableUsage = hex("#9a90e0"),
            assignment = hex("#e85181"),
            currency = hex("#7ad694"),
            unit = hex("#58d6ce"),
            results = hex("#7ad694"),
            comment = hex("#808080")
        )
    ),
    NumbyTheme(
        name = "HaX0R Blue",
        syntax = SyntaxColors(
            text = hex("#11b7ff"),
            background = hex("#010515"),
            number = hex("#10b6ff"),
            operator = hex("#10b6ff"),
            keyword = hex("#10b6ff"),
            function = hex("#10b6ff"),
            constant = hex("#10b6ff"),
            variable = hex("#10b6ff"),
            variableUsage = hex("#10b6ff"),
            assignment = hex("#10b6ff"),
            currency = hex("#10b6ff"),
            unit = hex("#10b6ff"),
            results = hex("#10b6ff"),
            comment = hex("#484157")
        )
    ),
    NumbyTheme(
        name = "HaX0R Gr33N",
        syntax = SyntaxColors(
            text = hex("#16b10e"),
            background = hex("#020f01"),
            number = hex("#15d00d"),
            operator = hex("#15d00d"),
            keyword = hex("#15d00d"),
            function = hex("#15d00d"),
            constant = hex("#15d00d"),
            variable = hex("#15d00d"),
            variableUsage = hex("#15d00d"),
            assignment = hex("#15d00d"),
            currency = hex("#15d00d"),
            unit = hex("#15d00d"),
            results = hex("#15d00d"),
            comment = hex("#334843")
        )
    ),
    NumbyTheme(
        name = "HaX0R R3D",
        syntax = SyntaxColors(
            text = hex("#b10e0e"),
            background = hex("#200101"),
            number = hex("#b00d0d"),
            operator = hex("#b00d0d"),
            keyword = hex("#b00d0d"),
            function = hex("#b00d0d"),
            constant = hex("#b00d0d"),
            variable = hex("#b00d0d"),
            variableUsage = hex("#b00d0d"),
            assignment = hex("#b00d0d"),
            currency = hex("#b00d0d"),
            unit = hex("#b00d0d"),
            results = hex("#b00d0d"),
            comment = hex("#554040")
        )
    ),
    NumbyTheme(
        name = "Hacktober",
        syntax = SyntaxColors(
            text = hex("#c9c9c9"),
            background = hex("#141414"),
            number = hex("#206ec5"),
            operator = hex("#b34538"),
            keyword = hex("#864651"),
            function = hex("#d08949"),
            constant = hex("#206ec5"),
            variable = hex("#ac9166"),
            variableUsage = hex("#864651"),
            assignment = hex("#b34538"),
            currency = hex("#587744"),
            unit = hex("#ac9166"),
            results = hex("#587744"),
            comment = hex("#464444")
        )
    ),
    NumbyTheme(
        name = "Hardcore",
        syntax = SyntaxColors(
            text = hex("#a0a0a0"),
            background = hex("#121212"),
            number = hex("#66d9ef"),
            operator = hex("#f92672"),
            keyword = hex("#9e6ffe"),
            function = hex("#fd971f"),
            constant = hex("#66d9ef"),
            variable = hex("#5e7175"),
            variableUsage = hex("#9e6ffe"),
            assignment = hex("#f92672"),
            currency = hex("#a6e22e"),
            unit = hex("#5e7175"),
            results = hex("#a6e22e"),
            comment = hex("#505354")
        )
    ),
    NumbyTheme(
        name = "Harper",
        syntax = SyntaxColors(
            text = hex("#a8a49d"),
            background = hex("#010101"),
            number = hex("#489e48"),
            operator = hex("#f8b63f"),
            keyword = hex("#b296c6"),
            function = hex("#d6da25"),
            constant = hex("#489e48"),
            variable = hex("#f5bfd7"),
            variableUsage = hex("#b296c6"),
            assignment = hex("#f8b63f"),
            currency = hex("#7fb5e1"),
            unit = hex("#f5bfd7"),
            results = hex("#7fb5e1"),
            comment = hex("#726e6a")
        )
    ),
    NumbyTheme(
        name = "Havn Daggry",
        syntax = SyntaxColors(
            text = hex("#3b4a7a"),
            background = hex("#f8f9fb"),
            number = hex("#3a577d"),
            operator = hex("#985248"),
            keyword = hex("#7c5c97"),
            function = hex("#be6b00"),
            constant = hex("#3a577d"),
            variable = hex("#925780"),
            variableUsage = hex("#7c5c97"),
            assignment = hex("#985248"),
            currency = hex("#577159"),
            unit = hex("#925780"),
            results = hex("#577159"),
            comment = hex("#1f2842")
        )
    ),
    NumbyTheme(
        name = "Havn Skumring",
        syntax = SyntaxColors(
            text = hex("#d6dbeb"),
            background = hex("#111522"),
            number = hex("#596cf7"),
            operator = hex("#ea563e"),
            keyword = hex("#7c719e"),
            function = hex("#f8b330"),
            constant = hex("#596cf7"),
            variable = hex("#d588c1"),
            variableUsage = hex("#7c719e"),
            assignment = hex("#ea563e"),
            currency = hex("#6ead7b"),
            unit = hex("#d588c1"),
            results = hex("#6ead7b"),
            comment = hex("#36425e")
        )
    ),
    NumbyTheme(
        name = "Heeler",
        syntax = SyntaxColors(
            text = hex("#fdfdfd"),
            background = hex("#211f46"),
            number = hex("#5ba5f2"),
            operator = hex("#e44c2e"),
            keyword = hex("#ff95c2"),
            function = hex("#f4ce65"),
            constant = hex("#5ba5f2"),
            variable = hex("#ff9763"),
            variableUsage = hex("#ff95c2"),
            assignment = hex("#e44c2e"),
            currency = hex("#bdd100"),
            unit = hex("#ff9763"),
            results = hex("#bdd100"),
            comment = hex("#4d4c4c")
        )
    ),
    NumbyTheme(
        name = "Highway",
        syntax = SyntaxColors(
            text = hex("#ededed"),
            background = hex("#222225"),
            number = hex("#006bb3"),
            operator = hex("#d00e18"),
            keyword = hex("#773482"),
            function = hex("#ffcb3e"),
            constant = hex("#006bb3"),
            variable = hex("#455271"),
            variableUsage = hex("#773482"),
            assignment = hex("#d00e18"),
            currency = hex("#138034"),
            unit = hex("#455271"),
            results = hex("#138034"),
            comment = hex("#5d504a")
        )
    ),
    NumbyTheme(
        name = "Hipster Green",
        syntax = SyntaxColors(
            text = hex("#84c138"),
            background = hex("#100b05"),
            number = hex("#246eb2"),
            operator = hex("#b6214a"),
            keyword = hex("#b200b2"),
            function = hex("#bfbf00"),
            constant = hex("#246eb2"),
            variable = hex("#00a6b2"),
            variableUsage = hex("#b200b2"),
            assignment = hex("#b6214a"),
            currency = hex("#00a600"),
            unit = hex("#00a6b2"),
            results = hex("#00a600"),
            comment = hex("#666666")
        )
    ),
    NumbyTheme(
        name = "Hivacruz",
        syntax = SyntaxColors(
            text = hex("#ede4e4"),
            background = hex("#132638"),
            number = hex("#3d8fd1"),
            operator = hex("#c94922"),
            keyword = hex("#6679cc"),
            function = hex("#c08b30"),
            constant = hex("#3d8fd1"),
            variable = hex("#22a2c9"),
            variableUsage = hex("#6679cc"),
            assignment = hex("#c94922"),
            currency = hex("#ac9739"),
            unit = hex("#22a2c9"),
            results = hex("#ac9739"),
            comment = hex("#6b7394")
        )
    ),
    NumbyTheme(
        name = "Homebrew",
        syntax = SyntaxColors(
            text = hex("#00ff00"),
            background = hex("#000000"),
            number = hex("#0d0dbf"),
            operator = hex("#990000"),
            keyword = hex("#b200b2"),
            function = hex("#999900"),
            constant = hex("#0d0dbf"),
            variable = hex("#00a6b2"),
            variableUsage = hex("#b200b2"),
            assignment = hex("#990000"),
            currency = hex("#00a600"),
            unit = hex("#00a6b2"),
            results = hex("#00a600"),
            comment = hex("#666666")
        )
    ),
    NumbyTheme(
        name = "Hopscotch",
        syntax = SyntaxColors(
            text = hex("#b9b5b8"),
            background = hex("#322931"),
            number = hex("#1290bf"),
            operator = hex("#dd464c"),
            keyword = hex("#c85e7c"),
            function = hex("#fdcc59"),
            constant = hex("#1290bf"),
            variable = hex("#149b93"),
            variableUsage = hex("#c85e7c"),
            assignment = hex("#dd464c"),
            currency = hex("#8fc13e"),
            unit = hex("#149b93"),
            results = hex("#8fc13e"),
            comment = hex("#797379")
        )
    ),
    NumbyTheme(
        name = "Hopscotch.256",
        syntax = SyntaxColors(
            text = hex("#b9b5b8"),
            background = hex("#322931"),
            number = hex("#1290bf"),
            operator = hex("#dd464c"),
            keyword = hex("#c85e7c"),
            function = hex("#fdcc59"),
            constant = hex("#1290bf"),
            variable = hex("#149b93"),
            variableUsage = hex("#c85e7c"),
            assignment = hex("#dd464c"),
            currency = hex("#8fc13e"),
            unit = hex("#149b93"),
            results = hex("#8fc13e"),
            comment = hex("#797379")
        )
    ),
    NumbyTheme(
        name = "Horizon",
        syntax = SyntaxColors(
            text = hex("#d5d8da"),
            background = hex("#1c1e26"),
            number = hex("#26bbd9"),
            operator = hex("#e95678"),
            keyword = hex("#ee64ac"),
            function = hex("#fab795"),
            constant = hex("#26bbd9"),
            variable = hex("#59e1e3"),
            variableUsage = hex("#ee64ac"),
            assignment = hex("#e95678"),
            currency = hex("#29d398"),
            unit = hex("#59e1e3"),
            results = hex("#29d398"),
            comment = hex("#666666")
        )
    ),
    NumbyTheme(
        name = "Hot Dog Stand",
        syntax = SyntaxColors(
            text = hex("#ffffff"),
            background = hex("#ea3323"),
            number = hex("#000000"),
            operator = hex("#ffff54"),
            keyword = hex("#ffff54"),
            function = hex("#ffff54"),
            constant = hex("#000000"),
            variable = hex("#ffffff"),
            variableUsage = hex("#ffff54"),
            assignment = hex("#ffff54"),
            currency = hex("#ffff54"),
            unit = hex("#ffffff"),
            results = hex("#ffff54"),
            comment = hex("#000000")
        )
    ),
    NumbyTheme(
        name = "Hot Dog Stand (Mustard)",
        syntax = SyntaxColors(
            text = hex("#000000"),
            background = hex("#ffff54"),
            number = hex("#000000"),
            operator = hex("#ea3323"),
            keyword = hex("#ea3323"),
            function = hex("#ea3323"),
            constant = hex("#000000"),
            variable = hex("#000000"),
            variableUsage = hex("#ea3323"),
            assignment = hex("#ea3323"),
            currency = hex("#ea3323"),
            unit = hex("#000000"),
            results = hex("#ea3323"),
            comment = hex("#000000")
        )
    ),
    NumbyTheme(
        name = "Hurtado",
        syntax = SyntaxColors(
            text = hex("#dbdbdb"),
            background = hex("#000000"),
            number = hex("#496487"),
            operator = hex("#ff1b00"),
            keyword = hex("#fd5ff1"),
            function = hex("#fbe74a"),
            constant = hex("#496487"),
            variable = hex("#86e9fe"),
            variableUsage = hex("#fd5ff1"),
            assignment = hex("#ff1b00"),
            currency = hex("#a5e055"),
            unit = hex("#86e9fe"),
            results = hex("#a5e055"),
            comment = hex("#3f3f3f")
        )
    ),
    NumbyTheme(
        name = "Hybrid",
        syntax = SyntaxColors(
            text = hex("#b7bcba"),
            background = hex("#161719"),
            number = hex("#6e90b0"),
            operator = hex("#b84d51"),
            keyword = hex("#a17eac"),
            function = hex("#e4b55e"),
            constant = hex("#6e90b0"),
            variable = hex("#7fbfb4"),
            variableUsage = hex("#a17eac"),
            assignment = hex("#b84d51"),
            currency = hex("#b3bf5a"),
            unit = hex("#7fbfb4"),
            results = hex("#b3bf5a"),
            comment = hex("#444548")
        )
    ),
    NumbyTheme(
        name = "IBM 5153 CGA",
        syntax = SyntaxColors(
            text = hex("#d6d6d6"),
            background = hex("#262626"),
            number = hex("#3333db"),
            operator = hex("#db3333"),
            keyword = hex("#db33db"),
            function = hex("#db9833"),
            constant = hex("#3333db"),
            variable = hex("#33dbdb"),
            variableUsage = hex("#db33db"),
            assignment = hex("#db3333"),
            currency = hex("#33db33"),
            unit = hex("#33dbdb"),
            results = hex("#33db33"),
            comment = hex("#4e4e4e")
        )
    ),
    NumbyTheme(
        name = "IBM 5153 CGA (Black)",
        syntax = SyntaxColors(
            text = hex("#c4c4c4"),
            background = hex("#000000"),
            number = hex("#0000c4"),
            operator = hex("#c40000"),
            keyword = hex("#c400c4"),
            function = hex("#c47e00"),
            constant = hex("#0000c4"),
            variable = hex("#00c4c4"),
            variableUsage = hex("#c400c4"),
            assignment = hex("#c40000"),
            currency = hex("#00c400"),
            unit = hex("#00c4c4"),
            results = hex("#00c400"),
            comment = hex("#4e4e4e")
        )
    ),
    NumbyTheme(
        name = "IC Green PPL",
        syntax = SyntaxColors(
            text = hex("#e0f1dc"),
            background = hex("#2c2c2c"),
            number = hex("#2ec3b9"),
            operator = hex("#ff2736"),
            keyword = hex("#50a096"),
            function = hex("#76a831"),
            constant = hex("#2ec3b9"),
            variable = hex("#3ca078"),
            variableUsage = hex("#50a096"),
            assignment = hex("#ff2736"),
            currency = hex("#41a638"),
            unit = hex("#3ca078"),
            results = hex("#41a638"),
            comment = hex("#106910")
        )
    ),
    NumbyTheme(
        name = "IC Orange PPL",
        syntax = SyntaxColors(
            text = hex("#ffcb83"),
            background = hex("#262626"),
            number = hex("#bd6d00"),
            operator = hex("#c13900"),
            keyword = hex("#fc5e00"),
            function = hex("#caaf00"),
            constant = hex("#bd6d00"),
            variable = hex("#f79500"),
            variableUsage = hex("#fc5e00"),
            assignment = hex("#c13900"),
            currency = hex("#a4a900"),
            unit = hex("#f79500"),
            results = hex("#a4a900"),
            comment = hex("#6a4f2a")
        )
    ),
    NumbyTheme(
        name = "IR Black",
        syntax = SyntaxColors(
            text = hex("#f1f1f1"),
            background = hex("#000000"),
            number = hex("#96cafe"),
            operator = hex("#fa6c60"),
            keyword = hex("#fa73fd"),
            function = hex("#fffeb7"),
            constant = hex("#96cafe"),
            variable = hex("#c6c5fe"),
            variableUsage = hex("#fa73fd"),
            assignment = hex("#fa6c60"),
            currency = hex("#a8ff60"),
            unit = hex("#c6c5fe"),
            results = hex("#a8ff60"),
            comment = hex("#7b7b7b")
        )
    ),
    NumbyTheme(
        name = "IRIX Console",
        syntax = SyntaxColors(
            text = hex("#f2f2f2"),
            background = hex("#0c0c0c"),
            number = hex("#0739e2"),
            operator = hex("#d42426"),
            keyword = hex("#911f9c"),
            function = hex("#c29d28"),
            constant = hex("#0739e2"),
            variable = hex("#4497df"),
            variableUsage = hex("#911f9c"),
            assignment = hex("#d42426"),
            currency = hex("#37a327"),
            unit = hex("#4497df"),
            results = hex("#37a327"),
            comment = hex("#767676")
        )
    ),
    NumbyTheme(
        name = "IRIX Terminal",
        syntax = SyntaxColors(
            text = hex("#f2f2f2"),
            background = hex("#000043"),
            number = hex("#0004ff"),
            operator = hex("#ff2b1e"),
            keyword = hex("#ff2cff"),
            function = hex("#ffff44"),
            constant = hex("#0004ff"),
            variable = hex("#56ffff"),
            variableUsage = hex("#ff2cff"),
            assignment = hex("#ff2b1e"),
            currency = hex("#57ff3d"),
            unit = hex("#56ffff"),
            results = hex("#57ff3d"),
            comment = hex("#ffff44")
        )
    ),
    NumbyTheme(
        name = "Iceberg Dark",
        syntax = SyntaxColors(
            text = hex("#c6c8d1"),
            background = hex("#161821"),
            number = hex("#84a0c6"),
            operator = hex("#e27878"),
            keyword = hex("#a093c7"),
            function = hex("#e2a478"),
            constant = hex("#84a0c6"),
            variable = hex("#89b8c2"),
            variableUsage = hex("#a093c7"),
            assignment = hex("#e27878"),
            currency = hex("#b4be82"),
            unit = hex("#89b8c2"),
            results = hex("#b4be82"),
            comment = hex("#6b7089")
        )
    ),
    NumbyTheme(
        name = "Iceberg Light",
        syntax = SyntaxColors(
            text = hex("#33374c"),
            background = hex("#e8e9ec"),
            number = hex("#2d539e"),
            operator = hex("#cc517a"),
            keyword = hex("#7759b4"),
            function = hex("#c57339"),
            constant = hex("#2d539e"),
            variable = hex("#3f83a6"),
            variableUsage = hex("#7759b4"),
            assignment = hex("#cc517a"),
            currency = hex("#668e3d"),
            unit = hex("#3f83a6"),
            results = hex("#668e3d"),
            comment = hex("#8389a3")
        )
    ),
    NumbyTheme(
        name = "Idea",
        syntax = SyntaxColors(
            text = hex("#adadad"),
            background = hex("#202020"),
            number = hex("#437ee7"),
            operator = hex("#fc5256"),
            keyword = hex("#9d74b0"),
            function = hex("#ccb444"),
            constant = hex("#437ee7"),
            variable = hex("#248887"),
            variableUsage = hex("#9d74b0"),
            assignment = hex("#fc5256"),
            currency = hex("#98b61c"),
            unit = hex("#248887"),
            results = hex("#98b61c"),
            comment = hex("#ffffff")
        )
    ),
    NumbyTheme(
        name = "Idle Toes",
        syntax = SyntaxColors(
            text = hex("#ffffff"),
            background = hex("#323232"),
            number = hex("#4099ff"),
            operator = hex("#d25252"),
            keyword = hex("#f680ff"),
            function = hex("#ffc66d"),
            constant = hex("#4099ff"),
            variable = hex("#bed6ff"),
            variableUsage = hex("#f680ff"),
            assignment = hex("#d25252"),
            currency = hex("#7fe173"),
            unit = hex("#bed6ff"),
            results = hex("#7fe173"),
            comment = hex("#606060")
        )
    ),
    NumbyTheme(
        name = "Jackie Brown",
        syntax = SyntaxColors(
            text = hex("#ffcc2f"),
            background = hex("#2c1d16"),
            number = hex("#246eb2"),
            operator = hex("#ef5734"),
            keyword = hex("#d05ec1"),
            function = hex("#bebf00"),
            constant = hex("#246eb2"),
            variable = hex("#00acee"),
            variableUsage = hex("#d05ec1"),
            assignment = hex("#ef5734"),
            currency = hex("#2baf2b"),
            unit = hex("#00acee"),
            results = hex("#2baf2b"),
            comment = hex("#666666")
        )
    ),
    NumbyTheme(
        name = "Japanesque",
        syntax = SyntaxColors(
            text = hex("#f7f6ec"),
            background = hex("#1e1e1e"),
            number = hex("#4c9ad4"),
            operator = hex("#cf3f61"),
            keyword = hex("#a57fc4"),
            function = hex("#e9b32a"),
            constant = hex("#4c9ad4"),
            variable = hex("#389aad"),
            variableUsage = hex("#a57fc4"),
            assignment = hex("#cf3f61"),
            currency = hex("#7bb75b"),
            unit = hex("#389aad"),
            results = hex("#7bb75b"),
            comment = hex("#595b59")
        )
    ),
    NumbyTheme(
        name = "Jellybeans",
        syntax = SyntaxColors(
            text = hex("#dedede"),
            background = hex("#121212"),
            number = hex("#97bedc"),
            operator = hex("#e27373"),
            keyword = hex("#e1c0fa"),
            function = hex("#ffba7b"),
            constant = hex("#97bedc"),
            variable = hex("#00988e"),
            variableUsage = hex("#e1c0fa"),
            assignment = hex("#e27373"),
            currency = hex("#94b979"),
            unit = hex("#00988e"),
            results = hex("#94b979"),
            comment = hex("#bdbdbd")
        )
    ),
    NumbyTheme(
        name = "JetBrains Darcula",
        syntax = SyntaxColors(
            text = hex("#adadad"),
            background = hex("#202020"),
            number = hex("#4581eb"),
            operator = hex("#fa5355"),
            keyword = hex("#fa54ff"),
            function = hex("#c2c300"),
            constant = hex("#4581eb"),
            variable = hex("#33c2c1"),
            variableUsage = hex("#fa54ff"),
            assignment = hex("#fa5355"),
            currency = hex("#126e00"),
            unit = hex("#33c2c1"),
            results = hex("#126e00"),
            comment = hex("#555555")
        )
    ),
    NumbyTheme(
        name = "Jubi",
        syntax = SyntaxColors(
            text = hex("#c3d3de"),
            background = hex("#262b33"),
            number = hex("#576ea6"),
            operator = hex("#cf7b98"),
            keyword = hex("#bc4f68"),
            function = hex("#6ebfc0"),
            constant = hex("#576ea6"),
            variable = hex("#75a7d2"),
            variableUsage = hex("#bc4f68"),
            assignment = hex("#cf7b98"),
            currency = hex("#90a94b"),
            unit = hex("#75a7d2"),
            results = hex("#90a94b"),
            comment = hex("#a874ce")
        )
    ),
    NumbyTheme(
        name = "Kanagawabones",
        syntax = SyntaxColors(
            text = hex("#ddd8bb"),
            background = hex("#1f1f28"),
            number = hex("#7eb3c9"),
            operator = hex("#e46a78"),
            keyword = hex("#957fb8"),
            function = hex("#e5c283"),
            constant = hex("#7eb3c9"),
            variable = hex("#7eb3c9"),
            variableUsage = hex("#957fb8"),
            assignment = hex("#e46a78"),
            currency = hex("#98bc6d"),
            unit = hex("#7eb3c9"),
            results = hex("#98bc6d"),
            comment = hex("#49495e")
        )
    ),
    NumbyTheme(
        name = "Kibble",
        syntax = SyntaxColors(
            text = hex("#f7f7f7"),
            background = hex("#0e100a"),
            number = hex("#3449d1"),
            operator = hex("#c70031"),
            keyword = hex("#8400ff"),
            function = hex("#d8e30e"),
            constant = hex("#3449d1"),
            variable = hex("#0798ab"),
            variableUsage = hex("#8400ff"),
            assignment = hex("#c70031"),
            currency = hex("#29cf13"),
            unit = hex("#0798ab"),
            results = hex("#29cf13"),
            comment = hex("#5a5a5a")
        )
    ),
    NumbyTheme(
        name = "Kitty Default",
        syntax = SyntaxColors(
            text = hex("#dddddd"),
            background = hex("#000000"),
            number = hex("#0d73cc"),
            operator = hex("#cc0403"),
            keyword = hex("#cb1ed1"),
            function = hex("#cecb00"),
            constant = hex("#0d73cc"),
            variable = hex("#0dcdcd"),
            variableUsage = hex("#cb1ed1"),
            assignment = hex("#cc0403"),
            currency = hex("#19cb00"),
            unit = hex("#0dcdcd"),
            results = hex("#19cb00"),
            comment = hex("#767676")
        )
    ),
    NumbyTheme(
        name = "Kitty Low Contrast",
        syntax = SyntaxColors(
            text = hex("#ffffff"),
            background = hex("#333333"),
            number = hex("#0d73cc"),
            operator = hex("#cc0403"),
            keyword = hex("#cb1ed1"),
            function = hex("#cecb00"),
            constant = hex("#0d73cc"),
            variable = hex("#0dcdcd"),
            variableUsage = hex("#cb1ed1"),
            assignment = hex("#cc0403"),
            currency = hex("#19cb00"),
            unit = hex("#0dcdcd"),
            results = hex("#19cb00"),
            comment = hex("#767676")
        )
    ),
    NumbyTheme(
        name = "Kolorit",
        syntax = SyntaxColors(
            text = hex("#efecec"),
            background = hex("#1d1a1e"),
            number = hex("#5db4ee"),
            operator = hex("#ff5b82"),
            keyword = hex("#da6cda"),
            function = hex("#e8e562"),
            constant = hex("#5db4ee"),
            variable = hex("#57e9eb"),
            variableUsage = hex("#da6cda"),
            assignment = hex("#ff5b82"),
            currency = hex("#47d7a1"),
            unit = hex("#57e9eb"),
            results = hex("#47d7a1"),
            comment = hex("#504d51")
        )
    ),
    NumbyTheme(
        name = "Konsolas",
        syntax = SyntaxColors(
            text = hex("#c8c1c1"),
            background = hex("#060606"),
            number = hex("#2323a5"),
            operator = hex("#aa1717"),
            keyword = hex("#ad1edc"),
            function = hex("#ebae1f"),
            constant = hex("#2323a5"),
            variable = hex("#42b0c8"),
            variableUsage = hex("#ad1edc"),
            assignment = hex("#aa1717"),
            currency = hex("#18b218"),
            unit = hex("#42b0c8"),
            results = hex("#18b218"),
            comment = hex("#7b716e")
        )
    ),
    NumbyTheme(
        name = "Kurokula",
        syntax = SyntaxColors(
            text = hex("#e0cfc2"),
            background = hex("#141515"),
            number = hex("#5c91dd"),
            operator = hex("#c35a52"),
            keyword = hex("#8b79a6"),
            function = hex("#e1b917"),
            constant = hex("#5c91dd"),
            variable = hex("#867268"),
            variableUsage = hex("#8b79a6"),
            assignment = hex("#c35a52"),
            currency = hex("#78b3a9"),
            unit = hex("#867268"),
            results = hex("#78b3a9"),
            comment = hex("#515151")
        )
    ),
    NumbyTheme(
        name = "Lab Fox",
        syntax = SyntaxColors(
            text = hex("#ffffff"),
            background = hex("#2e2e2e"),
            number = hex("#db3b21"),
            operator = hex("#fc6d26"),
            keyword = hex("#6b40a8"),
            function = hex("#fca121"),
            constant = hex("#db3b21"),
            variable = hex("#6e49cb"),
            variableUsage = hex("#6b40a8"),
            assignment = hex("#fc6d26"),
            currency = hex("#3eb383"),
            unit = hex("#6e49cb"),
            results = hex("#3eb383"),
            comment = hex("#5f5f5f")
        )
    ),
    NumbyTheme(
        name = "Laser",
        syntax = SyntaxColors(
            text = hex("#f106e3"),
            background = hex("#030d18"),
            number = hex("#fed300"),
            operator = hex("#ff8373"),
            keyword = hex("#ff90fe"),
            function = hex("#09b4bd"),
            constant = hex("#fed300"),
            variable = hex("#d1d1fe"),
            variableUsage = hex("#ff90fe"),
            assignment = hex("#ff8373"),
            currency = hex("#b4fb73"),
            unit = hex("#d1d1fe"),
            results = hex("#b4fb73"),
            comment = hex("#8f8f8f")
        )
    ),
    NumbyTheme(
        name = "Later This Evening",
        syntax = SyntaxColors(
            text = hex("#959595"),
            background = hex("#222222"),
            number = hex("#a0bad6"),
            operator = hex("#d45a60"),
            keyword = hex("#c092d6"),
            function = hex("#e5d289"),
            constant = hex("#a0bad6"),
            variable = hex("#91bfb7"),
            variableUsage = hex("#c092d6"),
            assignment = hex("#d45a60"),
            currency = hex("#afba67"),
            unit = hex("#91bfb7"),
            results = hex("#afba67"),
            comment = hex("#515454")
        )
    ),
    NumbyTheme(
        name = "Lavandula",
        syntax = SyntaxColors(
            text = hex("#736e7d"),
            background = hex("#050014"),
            number = hex("#4f4a7f"),
            operator = hex("#7d1625"),
            keyword = hex("#5a3f7f"),
            function = hex("#7f6f49"),
            constant = hex("#4f4a7f"),
            variable = hex("#58777f"),
            variableUsage = hex("#5a3f7f"),
            assignment = hex("#7d1625"),
            currency = hex("#337e6f"),
            unit = hex("#58777f"),
            results = hex("#337e6f"),
            comment = hex("#443a53")
        )
    ),
    NumbyTheme(
        name = "Light Owl",
        syntax = SyntaxColors(
            text = hex("#403f53"),
            background = hex("#fbfbfb"),
            number = hex("#288ed7"),
            operator = hex("#de3d3b"),
            keyword = hex("#d6438a"),
            function = hex("#e0af02"),
            constant = hex("#288ed7"),
            variable = hex("#2aa298"),
            variableUsage = hex("#d6438a"),
            assignment = hex("#de3d3b"),
            currency = hex("#08916a"),
            unit = hex("#2aa298"),
            results = hex("#08916a"),
            comment = hex("#989fb1")
        )
    ),
    NumbyTheme(
        name = "Liquid Carbon",
        syntax = SyntaxColors(
            text = hex("#afc2c2"),
            background = hex("#303030"),
            number = hex("#0099cc"),
            operator = hex("#ff3030"),
            keyword = hex("#cc69c8"),
            function = hex("#ccac00"),
            constant = hex("#0099cc"),
            variable = hex("#7ac4cc"),
            variableUsage = hex("#cc69c8"),
            assignment = hex("#ff3030"),
            currency = hex("#559a70"),
            unit = hex("#7ac4cc"),
            results = hex("#559a70"),
            comment = hex("#595959")
        )
    ),
    NumbyTheme(
        name = "Liquid Carbon Transparent",
        syntax = SyntaxColors(
            text = hex("#afc2c2"),
            background = hex("#000000"),
            number = hex("#0099cc"),
            operator = hex("#ff3030"),
            keyword = hex("#cc69c8"),
            function = hex("#ccac00"),
            constant = hex("#0099cc"),
            variable = hex("#7ac4cc"),
            variableUsage = hex("#cc69c8"),
            assignment = hex("#ff3030"),
            currency = hex("#559a70"),
            unit = hex("#7ac4cc"),
            results = hex("#559a70"),
            comment = hex("#404040")
        )
    ),
    NumbyTheme(
        name = "Lovelace",
        syntax = SyntaxColors(
            text = hex("#fdfdfd"),
            background = hex("#1d1f28"),
            number = hex("#8897f4"),
            operator = hex("#f37f97"),
            keyword = hex("#c574dd"),
            function = hex("#f2a272"),
            constant = hex("#8897f4"),
            variable = hex("#79e6f3"),
            variableUsage = hex("#c574dd"),
            assignment = hex("#f37f97"),
            currency = hex("#5adecd"),
            unit = hex("#79e6f3"),
            results = hex("#5adecd"),
            comment = hex("#4e5165")
        )
    ),
    NumbyTheme(
        name = "Man Page",
        syntax = SyntaxColors(
            text = hex("#000000"),
            background = hex("#fef49c"),
            number = hex("#0000b2"),
            operator = hex("#cc0000"),
            keyword = hex("#b200b2"),
            function = hex("#999900"),
            constant = hex("#0000b2"),
            variable = hex("#00a6b2"),
            variableUsage = hex("#b200b2"),
            assignment = hex("#cc0000"),
            currency = hex("#00a600"),
            unit = hex("#00a6b2"),
            results = hex("#00a600"),
            comment = hex("#666666")
        )
    ),
    NumbyTheme(
        name = "Mariana",
        syntax = SyntaxColors(
            text = hex("#d8dee9"),
            background = hex("#343d46"),
            number = hex("#6699cc"),
            operator = hex("#ec5f66"),
            keyword = hex("#c695c6"),
            function = hex("#f9ae58"),
            constant = hex("#6699cc"),
            variable = hex("#5fb4b4"),
            variableUsage = hex("#c695c6"),
            assignment = hex("#ec5f66"),
            currency = hex("#99c794"),
            unit = hex("#5fb4b4"),
            results = hex("#99c794"),
            comment = hex("#666666")
        )
    ),
    NumbyTheme(
        name = "Material Dark",
        syntax = SyntaxColors(
            text = hex("#e5e5e5"),
            background = hex("#232322"),
            number = hex("#134eb2"),
            operator = hex("#b7141f"),
            keyword = hex("#6f1aa1"),
            function = hex("#f6981e"),
            constant = hex("#134eb2"),
            variable = hex("#0e717c"),
            variableUsage = hex("#6f1aa1"),
            assignment = hex("#b7141f"),
            currency = hex("#457b24"),
            unit = hex("#0e717c"),
            results = hex("#457b24"),
            comment = hex("#4f4f4f")
        )
    ),
    NumbyTheme(
        name = "Material Design Colors",
        syntax = SyntaxColors(
            text = hex("#e7ebed"),
            background = hex("#1d262a"),
            number = hex("#37b6ff"),
            operator = hex("#fc3841"),
            keyword = hex("#fc226e"),
            function = hex("#fed032"),
            constant = hex("#37b6ff"),
            variable = hex("#59ffd1"),
            variableUsage = hex("#fc226e"),
            assignment = hex("#fc3841"),
            currency = hex("#5cf19e"),
            unit = hex("#59ffd1"),
            results = hex("#5cf19e"),
            comment = hex("#a1b0b8")
        )
    ),
    NumbyTheme(
        name = "Mathias",
        syntax = SyntaxColors(
            text = hex("#bbbbbb"),
            background = hex("#000000"),
            number = hex("#c48dff"),
            operator = hex("#e52222"),
            keyword = hex("#fa2573"),
            function = hex("#fc951e"),
            constant = hex("#c48dff"),
            variable = hex("#67d9f0"),
            variableUsage = hex("#fa2573"),
            assignment = hex("#e52222"),
            currency = hex("#a6e32d"),
            unit = hex("#67d9f0"),
            results = hex("#a6e32d"),
            comment = hex("#555555")
        )
    ),
    NumbyTheme(
        name = "Matrix",
        syntax = SyntaxColors(
            text = hex("#426644"),
            background = hex("#0f191c"),
            number = hex("#3f5242"),
            operator = hex("#23755a"),
            keyword = hex("#409931"),
            function = hex("#ffd700"),
            constant = hex("#3f5242"),
            variable = hex("#50b45a"),
            variableUsage = hex("#409931"),
            assignment = hex("#23755a"),
            currency = hex("#82d967"),
            unit = hex("#50b45a"),
            results = hex("#82d967"),
            comment = hex("#688060")
        )
    ),
    NumbyTheme(
        name = "Matte Black",
        syntax = SyntaxColors(
            text = hex("#bebebe"),
            background = hex("#121212"),
            number = hex("#e68e0d"),
            operator = hex("#d35f5f"),
            keyword = hex("#d35f5f"),
            function = hex("#b91c1c"),
            constant = hex("#e68e0d"),
            variable = hex("#bebebe"),
            variableUsage = hex("#d35f5f"),
            assignment = hex("#d35f5f"),
            currency = hex("#ffc107"),
            unit = hex("#bebebe"),
            results = hex("#ffc107"),
            comment = hex("#8a8a8d")
        )
    ),
    NumbyTheme(
        name = "Medallion",
        syntax = SyntaxColors(
            text = hex("#cac296"),
            background = hex("#1d1908"),
            number = hex("#616bb0"),
            operator = hex("#b64c00"),
            keyword = hex("#8c5a90"),
            function = hex("#d3bd26"),
            constant = hex("#616bb0"),
            variable = hex("#916c25"),
            variableUsage = hex("#8c5a90"),
            assignment = hex("#b64c00"),
            currency = hex("#7c8b16"),
            unit = hex("#916c25"),
            results = hex("#7c8b16"),
            comment = hex("#5e5219")
        )
    ),
    NumbyTheme(
        name = "Melange Dark",
        syntax = SyntaxColors(
            text = hex("#ece1d7"),
            background = hex("#292522"),
            number = hex("#7f91b2"),
            operator = hex("#bd8183"),
            keyword = hex("#b380b0"),
            function = hex("#e49b5d"),
            constant = hex("#7f91b2"),
            variable = hex("#7b9695"),
            variableUsage = hex("#b380b0"),
            assignment = hex("#bd8183"),
            currency = hex("#78997a"),
            unit = hex("#7b9695"),
            results = hex("#78997a"),
            comment = hex("#867462")
        )
    ),
    NumbyTheme(
        name = "Melange Light",
        syntax = SyntaxColors(
            text = hex("#54433a"),
            background = hex("#f1f1f1"),
            number = hex("#7892bd"),
            operator = hex("#c77b8b"),
            keyword = hex("#be79bb"),
            function = hex("#bc5c00"),
            constant = hex("#7892bd"),
            variable = hex("#739797"),
            variableUsage = hex("#be79bb"),
            assignment = hex("#c77b8b"),
            currency = hex("#6e9b72"),
            unit = hex("#739797"),
            results = hex("#6e9b72"),
            comment = hex("#a98a78")
        )
    ),
    NumbyTheme(
        name = "Mellifluous",
        syntax = SyntaxColors(
            text = hex("#dadada"),
            background = hex("#1a1a1a"),
            number = hex("#a8a1be"),
            operator = hex("#d29393"),
            keyword = hex("#b39fb0"),
            function = hex("#cbaa89"),
            constant = hex("#a8a1be"),
            variable = hex("#c0af8c"),
            variableUsage = hex("#b39fb0"),
            assignment = hex("#d29393"),
            currency = hex("#b3b393"),
            unit = hex("#c0af8c"),
            results = hex("#b3b393"),
            comment = hex("#5b5b5b")
        )
    ),
    NumbyTheme(
        name = "Mellow",
        syntax = SyntaxColors(
            text = hex("#c9c7cd"),
            background = hex("#161617"),
            number = hex("#aca1cf"),
            operator = hex("#f5a191"),
            keyword = hex("#e29eca"),
            function = hex("#e6b99d"),
            constant = hex("#aca1cf"),
            variable = hex("#ea83a5"),
            variableUsage = hex("#e29eca"),
            assignment = hex("#f5a191"),
            currency = hex("#90b99f"),
            unit = hex("#ea83a5"),
            results = hex("#90b99f"),
            comment = hex("#424246")
        )
    ),
    NumbyTheme(
        name = "Miasma",
        syntax = SyntaxColors(
            text = hex("#c2c2b0"),
            background = hex("#222222"),
            number = hex("#78824b"),
            operator = hex("#685742"),
            keyword = hex("#bb7744"),
            function = hex("#b36d43"),
            constant = hex("#78824b"),
            variable = hex("#c9a554"),
            variableUsage = hex("#bb7744"),
            assignment = hex("#685742"),
            currency = hex("#5f875f"),
            unit = hex("#c9a554"),
            results = hex("#5f875f"),
            comment = hex("#666666")
        )
    ),
    NumbyTheme(
        name = "Misterioso",
        syntax = SyntaxColors(
            text = hex("#e1e1e0"),
            background = hex("#2d3743"),
            number = hex("#338f86"),
            operator = hex("#ff4242"),
            keyword = hex("#9414e6"),
            function = hex("#ffad29"),
            constant = hex("#338f86"),
            variable = hex("#23d7d7"),
            variableUsage = hex("#9414e6"),
            assignment = hex("#ff4242"),
            currency = hex("#74af68"),
            unit = hex("#23d7d7"),
            results = hex("#74af68"),
            comment = hex("#626262")
        )
    ),
    NumbyTheme(
        name = "Mona Lisa",
        syntax = SyntaxColors(
            text = hex("#f7d66a"),
            background = hex("#120b0d"),
            number = hex("#515c5d"),
            operator = hex("#9b291c"),
            keyword = hex("#9b1d29"),
            function = hex("#c36e28"),
            constant = hex("#515c5d"),
            variable = hex("#588056"),
            variableUsage = hex("#9b1d29"),
            assignment = hex("#9b291c"),
            currency = hex("#636232"),
            unit = hex("#588056"),
            results = hex("#636232"),
            comment = hex("#874228")
        )
    ),
    NumbyTheme(
        name = "Monokai Pro Light Sun",
        syntax = SyntaxColors(
            text = hex("#2c232e"),
            background = hex("#f8efe7"),
            number = hex("#d4572b"),
            operator = hex("#ce4770"),
            keyword = hex("#6851a2"),
            function = hex("#b16803"),
            constant = hex("#d4572b"),
            variable = hex("#2473b6"),
            variableUsage = hex("#6851a2"),
            assignment = hex("#ce4770"),
            currency = hex("#218871"),
            unit = hex("#2473b6"),
            results = hex("#218871"),
            comment = hex("#a59c9c")
        )
    ),
    NumbyTheme(
        name = "Monokai Remastered",
        syntax = SyntaxColors(
            text = hex("#d9d9d9"),
            background = hex("#0c0c0c"),
            number = hex("#9d65ff"),
            operator = hex("#f4005f"),
            keyword = hex("#f4005f"),
            function = hex("#fd971f"),
            constant = hex("#9d65ff"),
            variable = hex("#58d1eb"),
            variableUsage = hex("#f4005f"),
            assignment = hex("#f4005f"),
            currency = hex("#98e024"),
            unit = hex("#58d1eb"),
            results = hex("#98e024"),
            comment = hex("#625e4c")
        )
    ),
    NumbyTheme(
        name = "Monokai Soda",
        syntax = SyntaxColors(
            text = hex("#c4c5b5"),
            background = hex("#1a1a1a"),
            number = hex("#9d65ff"),
            operator = hex("#f4005f"),
            keyword = hex("#f4005f"),
            function = hex("#fa8419"),
            constant = hex("#9d65ff"),
            variable = hex("#58d1eb"),
            variableUsage = hex("#f4005f"),
            assignment = hex("#f4005f"),
            currency = hex("#98e024"),
            unit = hex("#58d1eb"),
            results = hex("#98e024"),
            comment = hex("#625e4c")
        )
    ),
    NumbyTheme(
        name = "N0Tch2K",
        syntax = SyntaxColors(
            text = hex("#a0a0a0"),
            background = hex("#222222"),
            number = hex("#657d3e"),
            operator = hex("#a95551"),
            keyword = hex("#767676"),
            function = hex("#a98051"),
            constant = hex("#657d3e"),
            variable = hex("#c9c9c9"),
            variableUsage = hex("#767676"),
            assignment = hex("#a95551"),
            currency = hex("#666666"),
            unit = hex("#c9c9c9"),
            results = hex("#666666"),
            comment = hex("#545454")
        )
    ),
    NumbyTheme(
        name = "Neobones Dark",
        syntax = SyntaxColors(
            text = hex("#c6d5cf"),
            background = hex("#0f191f"),
            number = hex("#8190d4"),
            operator = hex("#de6e7c"),
            keyword = hex("#b279a7"),
            function = hex("#b77e64"),
            constant = hex("#8190d4"),
            variable = hex("#66a5ad"),
            variableUsage = hex("#b279a7"),
            assignment = hex("#de6e7c"),
            currency = hex("#90ff6b"),
            unit = hex("#66a5ad"),
            results = hex("#90ff6b"),
            comment = hex("#334652")
        )
    ),
    NumbyTheme(
        name = "Neobones Light",
        syntax = SyntaxColors(
            text = hex("#202e18"),
            background = hex("#e5ede6"),
            number = hex("#286486"),
            operator = hex("#a8334c"),
            keyword = hex("#88507d"),
            function = hex("#944927"),
            constant = hex("#286486"),
            variable = hex("#3b8992"),
            variableUsage = hex("#88507d"),
            assignment = hex("#a8334c"),
            currency = hex("#567a30"),
            unit = hex("#3b8992"),
            results = hex("#567a30"),
            comment = hex("#99ac9c")
        )
    ),
    NumbyTheme(
        name = "Neutron",
        syntax = SyntaxColors(
            text = hex("#e6e8ef"),
            background = hex("#1c1e22"),
            number = hex("#6a7c93"),
            operator = hex("#b54036"),
            keyword = hex("#a4799d"),
            function = hex("#deb566"),
            constant = hex("#6a7c93"),
            variable = hex("#3f94a8"),
            variableUsage = hex("#a4799d"),
            assignment = hex("#b54036"),
            currency = hex("#5ab977"),
            unit = hex("#3f94a8"),
            results = hex("#5ab977"),
            comment = hex("#494c51")
        )
    ),
    NumbyTheme(
        name = "Night Lion V1",
        syntax = SyntaxColors(
            text = hex("#bbbbbb"),
            background = hex("#000000"),
            number = hex("#276bd8"),
            operator = hex("#bb0000"),
            keyword = hex("#bb00bb"),
            function = hex("#f3f167"),
            constant = hex("#276bd8"),
            variable = hex("#00dadf"),
            variableUsage = hex("#bb00bb"),
            assignment = hex("#bb0000"),
            currency = hex("#5fde8f"),
            unit = hex("#00dadf"),
            results = hex("#5fde8f"),
            comment = hex("#555555")
        )
    ),
    NumbyTheme(
        name = "Night Lion V2",
        syntax = SyntaxColors(
            text = hex("#bbbbbb"),
            background = hex("#171717"),
            number = hex("#64d0f0"),
            operator = hex("#bb0000"),
            keyword = hex("#ce6fdb"),
            function = hex("#f3f167"),
            constant = hex("#64d0f0"),
            variable = hex("#00dadf"),
            variableUsage = hex("#ce6fdb"),
            assignment = hex("#bb0000"),
            currency = hex("#04f623"),
            unit = hex("#00dadf"),
            results = hex("#04f623"),
            comment = hex("#555555")
        )
    ),
    NumbyTheme(
        name = "Niji",
        syntax = SyntaxColors(
            text = hex("#ffffff"),
            background = hex("#141515"),
            number = hex("#2ab9ff"),
            operator = hex("#d23e08"),
            keyword = hex("#ff50da"),
            function = hex("#fff700"),
            constant = hex("#2ab9ff"),
            variable = hex("#1ef9f5"),
            variableUsage = hex("#ff50da"),
            assignment = hex("#d23e08"),
            currency = hex("#54ca74"),
            unit = hex("#1ef9f5"),
            results = hex("#54ca74"),
            comment = hex("#515151")
        )
    ),
    NumbyTheme(
        name = "Nocturnal Winter",
        syntax = SyntaxColors(
            text = hex("#e6e5e5"),
            background = hex("#0d0d17"),
            number = hex("#3182e0"),
            operator = hex("#f12d52"),
            keyword = hex("#ff2b6d"),
            function = hex("#f5f17a"),
            constant = hex("#3182e0"),
            variable = hex("#09c87a"),
            variableUsage = hex("#ff2b6d"),
            assignment = hex("#f12d52"),
            currency = hex("#09cd7e"),
            unit = hex("#09c87a"),
            results = hex("#09cd7e"),
            comment = hex("#808080")
        )
    ),
    NumbyTheme(
        name = "Nord Wave",
        syntax = SyntaxColors(
            text = hex("#d8dee9"),
            background = hex("#212121"),
            number = hex("#81a1c1"),
            operator = hex("#bf616a"),
            keyword = hex("#b48ead"),
            function = hex("#ebcb8b"),
            constant = hex("#81a1c1"),
            variable = hex("#88c0d0"),
            variableUsage = hex("#b48ead"),
            assignment = hex("#bf616a"),
            currency = hex("#a3be8c"),
            unit = hex("#88c0d0"),
            results = hex("#a3be8c"),
            comment = hex("#4c566a")
        )
    ),
    NumbyTheme(
        name = "Nordfox",
        syntax = SyntaxColors(
            text = hex("#cdcecf"),
            background = hex("#2e3440"),
            number = hex("#81a1c1"),
            operator = hex("#bf616a"),
            keyword = hex("#b48ead"),
            function = hex("#ebcb8b"),
            constant = hex("#81a1c1"),
            variable = hex("#88c0d0"),
            variableUsage = hex("#b48ead"),
            assignment = hex("#bf616a"),
            currency = hex("#a3be8c"),
            unit = hex("#88c0d0"),
            results = hex("#a3be8c"),
            comment = hex("#53648d")
        )
    ),
    NumbyTheme(
        name = "Novel",
        syntax = SyntaxColors(
            text = hex("#3b2322"),
            background = hex("#dfdbc3"),
            number = hex("#0000cc"),
            operator = hex("#cc0000"),
            keyword = hex("#cc00cc"),
            function = hex("#d06b00"),
            constant = hex("#0000cc"),
            variable = hex("#0087cc"),
            variableUsage = hex("#cc00cc"),
            assignment = hex("#cc0000"),
            currency = hex("#009600"),
            unit = hex("#0087cc"),
            results = hex("#009600"),
            comment = hex("#808080")
        )
    ),
    NumbyTheme(
        name = "Nvim Dark",
        syntax = SyntaxColors(
            text = hex("#e0e2ea"),
            background = hex("#14161b"),
            number = hex("#a6dbff"),
            operator = hex("#ffc0b9"),
            keyword = hex("#ffcaff"),
            function = hex("#fce094"),
            constant = hex("#a6dbff"),
            variable = hex("#8cf8f7"),
            variableUsage = hex("#ffcaff"),
            assignment = hex("#ffc0b9"),
            currency = hex("#b3f6c0"),
            unit = hex("#8cf8f7"),
            results = hex("#b3f6c0"),
            comment = hex("#4f5258")
        )
    ),
    NumbyTheme(
        name = "Nvim Light",
        syntax = SyntaxColors(
            text = hex("#14161b"),
            background = hex("#e0e2ea"),
            number = hex("#004c73"),
            operator = hex("#590008"),
            keyword = hex("#470045"),
            function = hex("#6b5300"),
            constant = hex("#004c73"),
            variable = hex("#007373"),
            variableUsage = hex("#470045"),
            assignment = hex("#590008"),
            currency = hex("#005523"),
            unit = hex("#007373"),
            results = hex("#005523"),
            comment = hex("#4f5258")
        )
    ),
    NumbyTheme(
        name = "Ocean",
        syntax = SyntaxColors(
            text = hex("#ffffff"),
            background = hex("#224fbc"),
            number = hex("#0000b2"),
            operator = hex("#e64c4c"),
            keyword = hex("#d826d8"),
            function = hex("#999900"),
            constant = hex("#0000b2"),
            variable = hex("#00a6b2"),
            variableUsage = hex("#d826d8"),
            assignment = hex("#e64c4c"),
            currency = hex("#00a600"),
            unit = hex("#00a6b2"),
            results = hex("#00a600"),
            comment = hex("#808080")
        )
    ),
    NumbyTheme(
        name = "Oceanic Material",
        syntax = SyntaxColors(
            text = hex("#c2c8d7"),
            background = hex("#1c262b"),
            number = hex("#1e80f0"),
            operator = hex("#ee2b2a"),
            keyword = hex("#8800a0"),
            function = hex("#ffea2e"),
            constant = hex("#1e80f0"),
            variable = hex("#16afca"),
            variableUsage = hex("#8800a0"),
            assignment = hex("#ee2b2a"),
            currency = hex("#40a33f"),
            unit = hex("#16afca"),
            results = hex("#40a33f"),
            comment = hex("#777777")
        )
    ),
    NumbyTheme(
        name = "Ollie",
        syntax = SyntaxColors(
            text = hex("#8a8dae"),
            background = hex("#222125"),
            number = hex("#2d57ac"),
            operator = hex("#ac2e31"),
            keyword = hex("#b08528"),
            function = hex("#ac4300"),
            constant = hex("#2d57ac"),
            variable = hex("#1fa6ac"),
            variableUsage = hex("#b08528"),
            assignment = hex("#ac2e31"),
            currency = hex("#31ac61"),
            unit = hex("#1fa6ac"),
            results = hex("#31ac61"),
            comment = hex("#674432")
        )
    ),
    NumbyTheme(
        name = "One Double Dark",
        syntax = SyntaxColors(
            text = hex("#dbdfe5"),
            background = hex("#282c34"),
            number = hex("#3fb1f5"),
            operator = hex("#f16372"),
            keyword = hex("#d373e3"),
            function = hex("#ecbe70"),
            constant = hex("#3fb1f5"),
            variable = hex("#17b9c4"),
            variableUsage = hex("#d373e3"),
            assignment = hex("#f16372"),
            currency = hex("#8cc570"),
            unit = hex("#17b9c4"),
            results = hex("#8cc570"),
            comment = hex("#525d6f")
        )
    ),
    NumbyTheme(
        name = "One Double Light",
        syntax = SyntaxColors(
            text = hex("#383a43"),
            background = hex("#fafafa"),
            number = hex("#0087c1"),
            operator = hex("#f74840"),
            keyword = hex("#b50da9"),
            function = hex("#cc8100"),
            constant = hex("#0087c1"),
            variable = hex("#009ab7"),
            variableUsage = hex("#b50da9"),
            assignment = hex("#f74840"),
            currency = hex("#25a343"),
            unit = hex("#009ab7"),
            results = hex("#25a343"),
            comment = hex("#0e131f")
        )
    ),
    NumbyTheme(
        name = "Operator Mono Dark",
        syntax = SyntaxColors(
            text = hex("#c3cac2"),
            background = hex("#191919"),
            number = hex("#4387cf"),
            operator = hex("#ca372d"),
            keyword = hex("#b86cb4"),
            function = hex("#d4d697"),
            constant = hex("#4387cf"),
            variable = hex("#72d5c6"),
            variableUsage = hex("#b86cb4"),
            assignment = hex("#ca372d"),
            currency = hex("#4d7b3a"),
            unit = hex("#72d5c6"),
            results = hex("#4d7b3a"),
            comment = hex("#9a9b99")
        )
    ),
    NumbyTheme(
        name = "Overnight Slumber",
        syntax = SyntaxColors(
            text = hex("#ced2d6"),
            background = hex("#0e1729"),
            number = hex("#8dabe1"),
            operator = hex("#ffa7c4"),
            keyword = hex("#c792eb"),
            function = hex("#ffcb8b"),
            constant = hex("#8dabe1"),
            variable = hex("#78ccf0"),
            variableUsage = hex("#c792eb"),
            assignment = hex("#ffa7c4"),
            currency = hex("#85cc95"),
            unit = hex("#78ccf0"),
            results = hex("#85cc95"),
            comment = hex("#575656")
        )
    ),
    NumbyTheme(
        name = "Pale Night Hc",
        syntax = SyntaxColors(
            text = hex("#cccccc"),
            background = hex("#3e4251"),
            number = hex("#82aaff"),
            operator = hex("#f07178"),
            keyword = hex("#c792ea"),
            function = hex("#ffcb6b"),
            constant = hex("#82aaff"),
            variable = hex("#89ddff"),
            variableUsage = hex("#c792ea"),
            assignment = hex("#f07178"),
            currency = hex("#c3e88d"),
            unit = hex("#89ddff"),
            results = hex("#c3e88d"),
            comment = hex("#737373")
        )
    ),
    NumbyTheme(
        name = "Pandora",
        syntax = SyntaxColors(
            text = hex("#e1e1e1"),
            background = hex("#141e43"),
            number = hex("#338f86"),
            operator = hex("#ff4242"),
            keyword = hex("#9414e6"),
            function = hex("#ffad29"),
            constant = hex("#338f86"),
            variable = hex("#23d7d7"),
            variableUsage = hex("#9414e6"),
            assignment = hex("#ff4242"),
            currency = hex("#74af68"),
            unit = hex("#23d7d7"),
            results = hex("#74af68"),
            comment = hex("#3f5648")
        )
    ),
    NumbyTheme(
        name = "Paul Millr",
        syntax = SyntaxColors(
            text = hex("#f2f2f2"),
            background = hex("#000000"),
            number = hex("#396bd7"),
            operator = hex("#ff0000"),
            keyword = hex("#b449be"),
            function = hex("#e7bf00"),
            constant = hex("#396bd7"),
            variable = hex("#66ccff"),
            variableUsage = hex("#b449be"),
            assignment = hex("#ff0000"),
            currency = hex("#79ff0f"),
            unit = hex("#66ccff"),
            results = hex("#79ff0f"),
            comment = hex("#666666")
        )
    ),
    NumbyTheme(
        name = "Peppermint",
        syntax = SyntaxColors(
            text = hex("#c8c8c8"),
            background = hex("#000000"),
            number = hex("#449fd0"),
            operator = hex("#e74669"),
            keyword = hex("#da62dc"),
            function = hex("#dab853"),
            constant = hex("#449fd0"),
            variable = hex("#65aaaf"),
            variableUsage = hex("#da62dc"),
            assignment = hex("#e74669"),
            currency = hex("#89d287"),
            unit = hex("#65aaaf"),
            results = hex("#89d287"),
            comment = hex("#535353")
        )
    ),
    NumbyTheme(
        name = "Phala Green Dark",
        syntax = SyntaxColors(
            text = hex("#c1fc03"),
            background = hex("#000000"),
            number = hex("#0223c0"),
            operator = hex("#ab1500"),
            keyword = hex("#c22ec0"),
            function = hex("#a9a700"),
            constant = hex("#0223c0"),
            variable = hex("#00b4c0"),
            variableUsage = hex("#c22ec0"),
            assignment = hex("#ab1500"),
            currency = hex("#00b100"),
            unit = hex("#00b4c0"),
            results = hex("#00b100"),
            comment = hex("#797979")
        )
    ),
    NumbyTheme(
        name = "Piatto Light",
        syntax = SyntaxColors(
            text = hex("#414141"),
            background = hex("#ffffff"),
            number = hex("#3c5ea8"),
            operator = hex("#b23771"),
            keyword = hex("#a454b2"),
            function = hex("#cd6f34"),
            constant = hex("#3c5ea8"),
            variable = hex("#66781e"),
            variableUsage = hex("#a454b2"),
            assignment = hex("#b23771"),
            currency = hex("#66781e"),
            unit = hex("#66781e"),
            results = hex("#66781e"),
            comment = hex("#3f3f3f")
        )
    ),
    NumbyTheme(
        name = "Pnevma",
        syntax = SyntaxColors(
            text = hex("#d0d0d0"),
            background = hex("#1c1c1c"),
            number = hex("#7fa5bd"),
            operator = hex("#a36666"),
            keyword = hex("#c79ec4"),
            function = hex("#d7af87"),
            constant = hex("#7fa5bd"),
            variable = hex("#8adbb4"),
            variableUsage = hex("#c79ec4"),
            assignment = hex("#a36666"),
            currency = hex("#90a57d"),
            unit = hex("#8adbb4"),
            results = hex("#90a57d"),
            comment = hex("#4a4845")
        )
    ),
    NumbyTheme(
        name = "Popping And Locking",
        syntax = SyntaxColors(
            text = hex("#ebdbb2"),
            background = hex("#181921"),
            number = hex("#458588"),
            operator = hex("#cc241d"),
            keyword = hex("#b16286"),
            function = hex("#d79921"),
            constant = hex("#458588"),
            variable = hex("#689d6a"),
            variableUsage = hex("#b16286"),
            assignment = hex("#cc241d"),
            currency = hex("#98971a"),
            unit = hex("#689d6a"),
            results = hex("#98971a"),
            comment = hex("#928374")
        )
    ),
    NumbyTheme(
        name = "Primary",
        syntax = SyntaxColors(
            text = hex("#000000"),
            background = hex("#ffffff"),
            number = hex("#4285f4"),
            operator = hex("#db4437"),
            keyword = hex("#db4437"),
            function = hex("#f4b400"),
            constant = hex("#4285f4"),
            variable = hex("#4285f4"),
            variableUsage = hex("#db4437"),
            assignment = hex("#db4437"),
            currency = hex("#0f9d58"),
            unit = hex("#4285f4"),
            results = hex("#0f9d58"),
            comment = hex("#000000")
        )
    ),
    NumbyTheme(
        name = "Pro",
        syntax = SyntaxColors(
            text = hex("#f2f2f2"),
            background = hex("#000000"),
            number = hex("#2009db"),
            operator = hex("#990000"),
            keyword = hex("#b200b2"),
            function = hex("#999900"),
            constant = hex("#2009db"),
            variable = hex("#00a6b2"),
            variableUsage = hex("#b200b2"),
            assignment = hex("#990000"),
            currency = hex("#00a600"),
            unit = hex("#00a6b2"),
            results = hex("#00a600"),
            comment = hex("#666666")
        )
    ),
    NumbyTheme(
        name = "Pro Light",
        syntax = SyntaxColors(
            text = hex("#191919"),
            background = hex("#ffffff"),
            number = hex("#3b75ff"),
            operator = hex("#e5492b"),
            keyword = hex("#ed66e8"),
            function = hex("#c6c440"),
            constant = hex("#3b75ff"),
            variable = hex("#4ed2de"),
            variableUsage = hex("#ed66e8"),
            assignment = hex("#e5492b"),
            currency = hex("#50d148"),
            unit = hex("#4ed2de"),
            results = hex("#50d148"),
            comment = hex("#9f9f9f")
        )
    ),
    NumbyTheme(
        name = "Purplepeter",
        syntax = SyntaxColors(
            text = hex("#ece7fa"),
            background = hex("#2a1a4a"),
            number = hex("#66d9ef"),
            operator = hex("#ff796d"),
            keyword = hex("#e78fcd"),
            function = hex("#efdfac"),
            constant = hex("#66d9ef"),
            variable = hex("#ba8cff"),
            variableUsage = hex("#e78fcd"),
            assignment = hex("#ff796d"),
            currency = hex("#99b481"),
            unit = hex("#ba8cff"),
            results = hex("#99b481"),
            comment = hex("#504b63")
        )
    ),
    NumbyTheme(
        name = "Rapture",
        syntax = SyntaxColors(
            text = hex("#c0c9e5"),
            background = hex("#111e2a"),
            number = hex("#6c9bf5"),
            operator = hex("#fc644d"),
            keyword = hex("#ff4fa1"),
            function = hex("#fff09b"),
            constant = hex("#6c9bf5"),
            variable = hex("#64e0ff"),
            variableUsage = hex("#ff4fa1"),
            assignment = hex("#fc644d"),
            currency = hex("#7afde1"),
            unit = hex("#64e0ff"),
            results = hex("#7afde1"),
            comment = hex("#304b66")
        )
    ),
    NumbyTheme(
        name = "Red Alert",
        syntax = SyntaxColors(
            text = hex("#ffffff"),
            background = hex("#762423"),
            number = hex("#489bee"),
            operator = hex("#d62e4e"),
            keyword = hex("#e979d7"),
            function = hex("#beb86b"),
            constant = hex("#489bee"),
            variable = hex("#6bbeb8"),
            variableUsage = hex("#e979d7"),
            assignment = hex("#d62e4e"),
            currency = hex("#71be6b"),
            unit = hex("#6bbeb8"),
            results = hex("#71be6b"),
            comment = hex("#666666")
        )
    ),
    NumbyTheme(
        name = "Red Planet",
        syntax = SyntaxColors(
            text = hex("#c2b790"),
            background = hex("#222222"),
            number = hex("#69819e"),
            operator = hex("#8c3432"),
            keyword = hex("#896492"),
            function = hex("#e8bf6a"),
            constant = hex("#69819e"),
            variable = hex("#5b8390"),
            variableUsage = hex("#896492"),
            assignment = hex("#8c3432"),
            currency = hex("#728271"),
            unit = hex("#5b8390"),
            results = hex("#728271"),
            comment = hex("#676767")
        )
    ),
    NumbyTheme(
        name = "Red Sands",
        syntax = SyntaxColors(
            text = hex("#d7c9a7"),
            background = hex("#7a251e"),
            number = hex("#0072ff"),
            operator = hex("#ff3f00"),
            keyword = hex("#bb00bb"),
            function = hex("#e7b000"),
            constant = hex("#0072ff"),
            variable = hex("#00bbbb"),
            variableUsage = hex("#bb00bb"),
            assignment = hex("#ff3f00"),
            currency = hex("#00bb00"),
            unit = hex("#00bbbb"),
            results = hex("#00bb00"),
            comment = hex("#6e6e6e")
        )
    ),
    NumbyTheme(
        name = "Relaxed",
        syntax = SyntaxColors(
            text = hex("#d9d9d9"),
            background = hex("#353a44"),
            number = hex("#6a8799"),
            operator = hex("#bc5653"),
            keyword = hex("#b06698"),
            function = hex("#ebc17a"),
            constant = hex("#6a8799"),
            variable = hex("#c9dfff"),
            variableUsage = hex("#b06698"),
            assignment = hex("#bc5653"),
            currency = hex("#909d63"),
            unit = hex("#c9dfff"),
            results = hex("#909d63"),
            comment = hex("#636363")
        )
    ),
    NumbyTheme(
        name = "Retro Legends",
        syntax = SyntaxColors(
            text = hex("#45eb45"),
            background = hex("#0d0d0d"),
            number = hex("#4066f2"),
            operator = hex("#de5454"),
            keyword = hex("#bf4cf2"),
            function = hex("#f7bf2b"),
            constant = hex("#4066f2"),
            variable = hex("#40d9e6"),
            variableUsage = hex("#bf4cf2"),
            assignment = hex("#de5454"),
            currency = hex("#45eb45"),
            unit = hex("#40d9e6"),
            results = hex("#45eb45"),
            comment = hex("#4c594c")
        )
    ),
    NumbyTheme(
        name = "Rippedcasts",
        syntax = SyntaxColors(
            text = hex("#ffffff"),
            background = hex("#2b2b2b"),
            number = hex("#75a5b0"),
            operator = hex("#cdaf95"),
            keyword = hex("#ff73fd"),
            function = hex("#bfbb1f"),
            constant = hex("#75a5b0"),
            variable = hex("#5a647e"),
            variableUsage = hex("#ff73fd"),
            assignment = hex("#cdaf95"),
            currency = hex("#a8ff60"),
            unit = hex("#5a647e"),
            results = hex("#a8ff60"),
            comment = hex("#666666")
        )
    ),
    NumbyTheme(
        name = "Rouge 2",
        syntax = SyntaxColors(
            text = hex("#a2a3aa"),
            background = hex("#17182b"),
            number = hex("#6e94b9"),
            operator = hex("#c6797e"),
            keyword = hex("#4c4e78"),
            function = hex("#dbcdab"),
            constant = hex("#6e94b9"),
            variable = hex("#8ab6c1"),
            variableUsage = hex("#4c4e78"),
            assignment = hex("#c6797e"),
            currency = hex("#969e92"),
            unit = hex("#8ab6c1"),
            results = hex("#969e92"),
            comment = hex("#616274")
        )
    ),
    NumbyTheme(
        name = "Royal",
        syntax = SyntaxColors(
            text = hex("#514968"),
            background = hex("#100815"),
            number = hex("#6580b0"),
            operator = hex("#91284c"),
            keyword = hex("#674d96"),
            function = hex("#b49d27"),
            constant = hex("#6580b0"),
            variable = hex("#8aaabe"),
            variableUsage = hex("#674d96"),
            assignment = hex("#91284c"),
            currency = hex("#23801c"),
            unit = hex("#8aaabe"),
            results = hex("#23801c"),
            comment = hex("#3e3a49")
        )
    ),
    NumbyTheme(
        name = "Ryuuko",
        syntax = SyntaxColors(
            text = hex("#ececec"),
            background = hex("#2c3941"),
            number = hex("#6a8e95"),
            operator = hex("#865f5b"),
            keyword = hex("#b18a73"),
            function = hex("#b1a990"),
            constant = hex("#6a8e95"),
            variable = hex("#88b2ac"),
            variableUsage = hex("#b18a73"),
            assignment = hex("#865f5b"),
            currency = hex("#66907d"),
            unit = hex("#88b2ac"),
            results = hex("#66907d"),
            comment = hex("#5d7079")
        )
    ),
    NumbyTheme(
        name = "Sakura",
        syntax = SyntaxColors(
            text = hex("#dd7bdc"),
            background = hex("#18131e"),
            number = hex("#6964ab"),
            operator = hex("#d52370"),
            keyword = hex("#c71fbf"),
            function = hex("#bc7053"),
            constant = hex("#6964ab"),
            variable = hex("#939393"),
            variableUsage = hex("#c71fbf"),
            assignment = hex("#d52370"),
            currency = hex("#41af1a"),
            unit = hex("#939393"),
            results = hex("#41af1a"),
            comment = hex("#786d69")
        )
    ),
    NumbyTheme(
        name = "Scarlet Protocol",
        syntax = SyntaxColors(
            text = hex("#e41951"),
            background = hex("#1c153d"),
            number = hex("#0271b6"),
            operator = hex("#ff0051"),
            keyword = hex("#ca30c7"),
            function = hex("#faf945"),
            constant = hex("#0271b6"),
            variable = hex("#00c5c7"),
            variableUsage = hex("#ca30c7"),
            assignment = hex("#ff0051"),
            currency = hex("#00dc84"),
            unit = hex("#00c5c7"),
            results = hex("#00dc84"),
            comment = hex("#686868")
        )
    ),
    NumbyTheme(
        name = "Sea Shells",
        syntax = SyntaxColors(
            text = hex("#deb88d"),
            background = hex("#09141b"),
            number = hex("#1e4950"),
            operator = hex("#d15123"),
            keyword = hex("#68d4f1"),
            function = hex("#fca02f"),
            constant = hex("#1e4950"),
            variable = hex("#50a3b5"),
            variableUsage = hex("#68d4f1"),
            assignment = hex("#d15123"),
            currency = hex("#027c9b"),
            unit = hex("#50a3b5"),
            results = hex("#027c9b"),
            comment = hex("#434b53")
        )
    ),
    NumbyTheme(
        name = "Seafoam Pastel",
        syntax = SyntaxColors(
            text = hex("#d4e7d4"),
            background = hex("#243435"),
            number = hex("#4d7b82"),
            operator = hex("#825d4d"),
            keyword = hex("#8a7267"),
            function = hex("#ada16d"),
            constant = hex("#4d7b82"),
            variable = hex("#729494"),
            variableUsage = hex("#8a7267"),
            assignment = hex("#825d4d"),
            currency = hex("#728c62"),
            unit = hex("#729494"),
            results = hex("#728c62"),
            comment = hex("#8a8a8a")
        )
    ),
    NumbyTheme(
        name = "Seoulbones Dark",
        syntax = SyntaxColors(
            text = hex("#dddddd"),
            background = hex("#4b4b4b"),
            number = hex("#97bdde"),
            operator = hex("#e388a3"),
            keyword = hex("#a5a6c5"),
            function = hex("#ffdf9b"),
            constant = hex("#97bdde"),
            variable = hex("#6fbdbe"),
            variableUsage = hex("#a5a6c5"),
            assignment = hex("#e388a3"),
            currency = hex("#98bd99"),
            unit = hex("#6fbdbe"),
            results = hex("#98bd99"),
            comment = hex("#797172")
        )
    ),
    NumbyTheme(
        name = "Seoulbones Light",
        syntax = SyntaxColors(
            text = hex("#555555"),
            background = hex("#e2e2e2"),
            number = hex("#0084a3"),
            operator = hex("#dc5284"),
            keyword = hex("#896788"),
            function = hex("#c48562"),
            constant = hex("#0084a3"),
            variable = hex("#008586"),
            variableUsage = hex("#896788"),
            assignment = hex("#dc5284"),
            currency = hex("#628562"),
            unit = hex("#008586"),
            results = hex("#628562"),
            comment = hex("#a5a0a1")
        )
    ),
    NumbyTheme(
        name = "Shaman",
        syntax = SyntaxColors(
            text = hex("#405555"),
            background = hex("#001015"),
            number = hex("#449a86"),
            operator = hex("#b2302d"),
            keyword = hex("#00599d"),
            function = hex("#5e8baa"),
            constant = hex("#449a86"),
            variable = hex("#5d7e19"),
            variableUsage = hex("#00599d"),
            assignment = hex("#b2302d"),
            currency = hex("#00a941"),
            unit = hex("#5d7e19"),
            results = hex("#00a941"),
            comment = hex("#384451")
        )
    ),
    NumbyTheme(
        name = "Slate",
        syntax = SyntaxColors(
            text = hex("#35b1d2"),
            background = hex("#222222"),
            number = hex("#325856"),
            operator = hex("#e2a8bf"),
            keyword = hex("#a481d3"),
            function = hex("#c4c9c0"),
            constant = hex("#325856"),
            variable = hex("#15ab9c"),
            variableUsage = hex("#a481d3"),
            assignment = hex("#e2a8bf"),
            currency = hex("#81d778"),
            unit = hex("#15ab9c"),
            results = hex("#81d778"),
            comment = hex("#ffffff")
        )
    ),
    NumbyTheme(
        name = "Sleepy Hollow",
        syntax = SyntaxColors(
            text = hex("#af9a91"),
            background = hex("#121214"),
            number = hex("#5f63b4"),
            operator = hex("#ba3934"),
            keyword = hex("#a17c7b"),
            function = hex("#b55600"),
            constant = hex("#5f63b4"),
            variable = hex("#8faea9"),
            variableUsage = hex("#a17c7b"),
            assignment = hex("#ba3934"),
            currency = hex("#91773f"),
            unit = hex("#8faea9"),
            results = hex("#91773f"),
            comment = hex("#4e4b61")
        )
    ),
    NumbyTheme(
        name = "Smyck",
        syntax = SyntaxColors(
            text = hex("#f7f7f7"),
            background = hex("#1b1b1b"),
            number = hex("#62a3c4"),
            operator = hex("#b84131"),
            keyword = hex("#ba8acc"),
            function = hex("#c4a500"),
            constant = hex("#62a3c4"),
            variable = hex("#207383"),
            variableUsage = hex("#ba8acc"),
            assignment = hex("#b84131"),
            currency = hex("#7da900"),
            unit = hex("#207383"),
            results = hex("#7da900"),
            comment = hex("#7a7a7a")
        )
    ),
    NumbyTheme(
        name = "Snazzy Soft",
        syntax = SyntaxColors(
            text = hex("#eff0eb"),
            background = hex("#282a36"),
            number = hex("#57c7ff"),
            operator = hex("#ff5c57"),
            keyword = hex("#ff6ac1"),
            function = hex("#f3f99d"),
            constant = hex("#57c7ff"),
            variable = hex("#9aedfe"),
            variableUsage = hex("#ff6ac1"),
            assignment = hex("#ff5c57"),
            currency = hex("#5af78e"),
            unit = hex("#9aedfe"),
            results = hex("#5af78e"),
            comment = hex("#686868")
        )
    ),
    NumbyTheme(
        name = "Solarized Darcula",
        syntax = SyntaxColors(
            text = hex("#d2d8d9"),
            background = hex("#3d3f41"),
            number = hex("#2075c7"),
            operator = hex("#f24840"),
            keyword = hex("#797fd4"),
            function = hex("#b68800"),
            constant = hex("#2075c7"),
            variable = hex("#15968d"),
            variableUsage = hex("#797fd4"),
            assignment = hex("#f24840"),
            currency = hex("#629655"),
            unit = hex("#15968d"),
            results = hex("#629655"),
            comment = hex("#65696a")
        )
    ),
    NumbyTheme(
        name = "Solarized Dark Higher Contrast",
        syntax = SyntaxColors(
            text = hex("#9cc2c3"),
            background = hex("#001e27"),
            number = hex("#2176c7"),
            operator = hex("#d11c24"),
            keyword = hex("#c61c6f"),
            function = hex("#a57706"),
            constant = hex("#2176c7"),
            variable = hex("#259286"),
            variableUsage = hex("#c61c6f"),
            assignment = hex("#d11c24"),
            currency = hex("#6cbe6c"),
            unit = hex("#259286"),
            results = hex("#6cbe6c"),
            comment = hex("#006488")
        )
    ),
    NumbyTheme(
        name = "Solarized Dark Patched",
        syntax = SyntaxColors(
            text = hex("#708284"),
            background = hex("#001e27"),
            number = hex("#2176c7"),
            operator = hex("#d11c24"),
            keyword = hex("#c61c6f"),
            function = hex("#a57706"),
            constant = hex("#2176c7"),
            variable = hex("#259286"),
            variableUsage = hex("#c61c6f"),
            assignment = hex("#d11c24"),
            currency = hex("#738a05"),
            unit = hex("#259286"),
            results = hex("#738a05"),
            comment = hex("#475b62")
        )
    ),
    NumbyTheme(
        name = "Solarized Osaka Night",
        syntax = SyntaxColors(
            text = hex("#c0caf5"),
            background = hex("#1a1b26"),
            number = hex("#7aa2f7"),
            operator = hex("#f7768e"),
            keyword = hex("#bb9af7"),
            function = hex("#e0af68"),
            constant = hex("#7aa2f7"),
            variable = hex("#7dcfff"),
            variableUsage = hex("#bb9af7"),
            assignment = hex("#f7768e"),
            currency = hex("#9ece6a"),
            unit = hex("#7dcfff"),
            results = hex("#9ece6a"),
            comment = hex("#414868")
        )
    ),
    NumbyTheme(
        name = "Spacegray Bright",
        syntax = SyntaxColors(
            text = hex("#f3f3f3"),
            background = hex("#2a2e3a"),
            number = hex("#7baec1"),
            operator = hex("#bc5553"),
            keyword = hex("#b98aae"),
            function = hex("#f6c987"),
            constant = hex("#7baec1"),
            variable = hex("#85c9b8"),
            variableUsage = hex("#b98aae"),
            assignment = hex("#bc5553"),
            currency = hex("#a0b56c"),
            unit = hex("#85c9b8"),
            results = hex("#a0b56c"),
            comment = hex("#626262")
        )
    ),
    NumbyTheme(
        name = "Spacegray Eighties",
        syntax = SyntaxColors(
            text = hex("#bdbaae"),
            background = hex("#222222"),
            number = hex("#5486c0"),
            operator = hex("#ec5f67"),
            keyword = hex("#bf83c1"),
            function = hex("#fec254"),
            constant = hex("#5486c0"),
            variable = hex("#57c2c1"),
            variableUsage = hex("#bf83c1"),
            assignment = hex("#ec5f67"),
            currency = hex("#81a764"),
            unit = hex("#57c2c1"),
            results = hex("#81a764"),
            comment = hex("#555555")
        )
    ),
    NumbyTheme(
        name = "Spacegray Eighties Dull",
        syntax = SyntaxColors(
            text = hex("#c9c6bc"),
            background = hex("#222222"),
            number = hex("#7c8fa5"),
            operator = hex("#b24a56"),
            keyword = hex("#a5789e"),
            function = hex("#c6735a"),
            constant = hex("#7c8fa5"),
            variable = hex("#80cdcb"),
            variableUsage = hex("#a5789e"),
            assignment = hex("#b24a56"),
            currency = hex("#92b477"),
            unit = hex("#80cdcb"),
            results = hex("#92b477"),
            comment = hex("#555555")
        )
    ),
    NumbyTheme(
        name = "Spiderman",
        syntax = SyntaxColors(
            text = hex("#e3e3e3"),
            background = hex("#1b1d1e"),
            number = hex("#2c3fff"),
            operator = hex("#e60813"),
            keyword = hex("#2435db"),
            function = hex("#e24756"),
            constant = hex("#2c3fff"),
            variable = hex("#3256ff"),
            variableUsage = hex("#2435db"),
            assignment = hex("#e60813"),
            currency = hex("#e22928"),
            unit = hex("#3256ff"),
            results = hex("#e22928"),
            comment = hex("#505354")
        )
    ),
    NumbyTheme(
        name = "Spring",
        syntax = SyntaxColors(
            text = hex("#4d4d4c"),
            background = hex("#ffffff"),
            number = hex("#1dd3ee"),
            operator = hex("#ff4d83"),
            keyword = hex("#8959a8"),
            function = hex("#1fc95b"),
            constant = hex("#1dd3ee"),
            variable = hex("#3e999f"),
            variableUsage = hex("#8959a8"),
            assignment = hex("#ff4d83"),
            currency = hex("#1f8c3b"),
            unit = hex("#3e999f"),
            results = hex("#1f8c3b"),
            comment = hex("#000000")
        )
    ),
    NumbyTheme(
        name = "Square",
        syntax = SyntaxColors(
            text = hex("#acacab"),
            background = hex("#1a1a1a"),
            number = hex("#a9cdeb"),
            operator = hex("#e9897c"),
            keyword = hex("#75507b"),
            function = hex("#ecebbe"),
            constant = hex("#a9cdeb"),
            variable = hex("#c9caec"),
            variableUsage = hex("#75507b"),
            assignment = hex("#e9897c"),
            currency = hex("#b6377d"),
            unit = hex("#c9caec"),
            results = hex("#b6377d"),
            comment = hex("#474747")
        )
    ),
    NumbyTheme(
        name = "Squirrelsong Dark",
        syntax = SyntaxColors(
            text = hex("#b19b89"),
            background = hex("#372920"),
            number = hex("#4395c6"),
            operator = hex("#ba4138"),
            keyword = hex("#855fb8"),
            function = hex("#d4b139"),
            constant = hex("#4395c6"),
            variable = hex("#2f9794"),
            variableUsage = hex("#855fb8"),
            assignment = hex("#ba4138"),
            currency = hex("#468336"),
            unit = hex("#2f9794"),
            results = hex("#468336"),
            comment = hex("#704f39")
        )
    ),
    NumbyTheme(
        name = "Starlight",
        syntax = SyntaxColors(
            text = hex("#ffffff"),
            background = hex("#242424"),
            number = hex("#24acd4"),
            operator = hex("#f62b5a"),
            keyword = hex("#f2affd"),
            function = hex("#e3c401"),
            constant = hex("#24acd4"),
            variable = hex("#13c299"),
            variableUsage = hex("#f2affd"),
            assignment = hex("#f62b5a"),
            currency = hex("#47b413"),
            unit = hex("#13c299"),
            results = hex("#47b413"),
            comment = hex("#616161")
        )
    ),
    NumbyTheme(
        name = "Sublette",
        syntax = SyntaxColors(
            text = hex("#ccced0"),
            background = hex("#202535"),
            number = hex("#5588ff"),
            operator = hex("#ee5577"),
            keyword = hex("#ff77cc"),
            function = hex("#ffdd88"),
            constant = hex("#5588ff"),
            variable = hex("#44eeee"),
            variableUsage = hex("#ff77cc"),
            assignment = hex("#ee5577"),
            currency = hex("#55ee77"),
            unit = hex("#44eeee"),
            results = hex("#55ee77"),
            comment = hex("#405570")
        )
    ),
    NumbyTheme(
        name = "Subliminal",
        syntax = SyntaxColors(
            text = hex("#d4d4d4"),
            background = hex("#282c35"),
            number = hex("#6699cc"),
            operator = hex("#e15a60"),
            keyword = hex("#f1a5ab"),
            function = hex("#ffe2a9"),
            constant = hex("#6699cc"),
            variable = hex("#5fb3b3"),
            variableUsage = hex("#f1a5ab"),
            assignment = hex("#e15a60"),
            currency = hex("#a9cfa4"),
            unit = hex("#5fb3b3"),
            results = hex("#a9cfa4"),
            comment = hex("#7f7f7f")
        )
    ),
    NumbyTheme(
        name = "Sugarplum",
        syntax = SyntaxColors(
            text = hex("#db7ddd"),
            background = hex("#111147"),
            number = hex("#db7ddd"),
            operator = hex("#5ca8dc"),
            keyword = hex("#d0beee"),
            function = hex("#249a84"),
            constant = hex("#db7ddd"),
            variable = hex("#f9f3f9"),
            variableUsage = hex("#d0beee"),
            assignment = hex("#5ca8dc"),
            currency = hex("#53b397"),
            unit = hex("#f9f3f9"),
            results = hex("#53b397"),
            comment = hex("#44447a")
        )
    ),
    NumbyTheme(
        name = "Sundried",
        syntax = SyntaxColors(
            text = hex("#c9c9c9"),
            background = hex("#1a1818"),
            number = hex("#485b98"),
            operator = hex("#a7463d"),
            keyword = hex("#864651"),
            function = hex("#9d602a"),
            constant = hex("#485b98"),
            variable = hex("#9c814f"),
            variableUsage = hex("#864651"),
            assignment = hex("#a7463d"),
            currency = hex("#587744"),
            unit = hex("#9c814f"),
            results = hex("#587744"),
            comment = hex("#4d4e48")
        )
    ),
    NumbyTheme(
        name = "Symfonic",
        syntax = SyntaxColors(
            text = hex("#ffffff"),
            background = hex("#000000"),
            number = hex("#0084d4"),
            operator = hex("#dc322f"),
            keyword = hex("#b729d9"),
            function = hex("#ff8400"),
            constant = hex("#0084d4"),
            variable = hex("#ccccff"),
            variableUsage = hex("#b729d9"),
            assignment = hex("#dc322f"),
            currency = hex("#56db3a"),
            unit = hex("#ccccff"),
            results = hex("#56db3a"),
            comment = hex("#414347")
        )
    ),
    NumbyTheme(
        name = "Synthwave Alpha",
        syntax = SyntaxColors(
            text = hex("#f2f2e3"),
            background = hex("#241b30"),
            number = hex("#6e29ad"),
            operator = hex("#e60a70"),
            keyword = hex("#b300ad"),
            function = hex("#adad3e"),
            constant = hex("#6e29ad"),
            variable = hex("#00b0b1"),
            variableUsage = hex("#b300ad"),
            assignment = hex("#e60a70"),
            currency = hex("#00986c"),
            unit = hex("#00b0b1"),
            results = hex("#00986c"),
            comment = hex("#7f7094")
        )
    ),
    NumbyTheme(
        name = "Tango Adapted",
        syntax = SyntaxColors(
            text = hex("#000000"),
            background = hex("#ffffff"),
            number = hex("#00a2ff"),
            operator = hex("#ff0000"),
            keyword = hex("#c17ecc"),
            function = hex("#e3be00"),
            constant = hex("#00a2ff"),
            variable = hex("#00d0d6"),
            variableUsage = hex("#c17ecc"),
            assignment = hex("#ff0000"),
            currency = hex("#59d600"),
            unit = hex("#00d0d6"),
            results = hex("#59d600"),
            comment = hex("#8f928b")
        )
    ),
    NumbyTheme(
        name = "Tango Half Adapted",
        syntax = SyntaxColors(
            text = hex("#000000"),
            background = hex("#ffffff"),
            number = hex("#008ef6"),
            operator = hex("#ff0000"),
            keyword = hex("#a96cb3"),
            function = hex("#e2c000"),
            constant = hex("#008ef6"),
            variable = hex("#00bdc3"),
            variableUsage = hex("#a96cb3"),
            assignment = hex("#ff0000"),
            currency = hex("#4cc300"),
            unit = hex("#00bdc3"),
            results = hex("#4cc300"),
            comment = hex("#797d76")
        )
    ),
    NumbyTheme(
        name = "Tearout",
        syntax = SyntaxColors(
            text = hex("#f4d2ae"),
            background = hex("#34392d"),
            number = hex("#b5955e"),
            operator = hex("#cc967b"),
            keyword = hex("#c9a554"),
            function = hex("#6c9861"),
            constant = hex("#b5955e"),
            variable = hex("#d7c483"),
            variableUsage = hex("#c9a554"),
            assignment = hex("#cc967b"),
            currency = hex("#97976d"),
            unit = hex("#d7c483"),
            results = hex("#97976d"),
            comment = hex("#74634e")
        )
    ),
    NumbyTheme(
        name = "Teerb",
        syntax = SyntaxColors(
            text = hex("#d0d0d0"),
            background = hex("#262626"),
            number = hex("#86aed6"),
            operator = hex("#d68686"),
            keyword = hex("#d6aed6"),
            function = hex("#d7af87"),
            constant = hex("#86aed6"),
            variable = hex("#8adbb4"),
            variableUsage = hex("#d6aed6"),
            assignment = hex("#d68686"),
            currency = hex("#aed686"),
            unit = hex("#8adbb4"),
            results = hex("#aed686"),
            comment = hex("#4f4f4f")
        )
    ),
    NumbyTheme(
        name = "Terafox",
        syntax = SyntaxColors(
            text = hex("#e6eaea"),
            background = hex("#152528"),
            number = hex("#5a93aa"),
            operator = hex("#e85c51"),
            keyword = hex("#ad5c7c"),
            function = hex("#fda47f"),
            constant = hex("#5a93aa"),
            variable = hex("#a1cdd8"),
            variableUsage = hex("#ad5c7c"),
            assignment = hex("#e85c51"),
            currency = hex("#7aa4a1"),
            unit = hex("#a1cdd8"),
            results = hex("#7aa4a1"),
            comment = hex("#4e5157")
        )
    ),
    NumbyTheme(
        name = "Terminal Basic",
        syntax = SyntaxColors(
            text = hex("#000000"),
            background = hex("#ffffff"),
            number = hex("#0000b2"),
            operator = hex("#990000"),
            keyword = hex("#b200b2"),
            function = hex("#999900"),
            constant = hex("#0000b2"),
            variable = hex("#00a6b2"),
            variableUsage = hex("#b200b2"),
            assignment = hex("#990000"),
            currency = hex("#00a600"),
            unit = hex("#00a6b2"),
            results = hex("#00a600"),
            comment = hex("#666666")
        )
    ),
    NumbyTheme(
        name = "Terminal Basic Dark",
        syntax = SyntaxColors(
            text = hex("#ffffff"),
            background = hex("#1d1e1d"),
            number = hex("#6444ed"),
            operator = hex("#c65339"),
            keyword = hex("#d357db"),
            function = hex("#b8b74a"),
            constant = hex("#6444ed"),
            variable = hex("#69c1cf"),
            variableUsage = hex("#d357db"),
            assignment = hex("#c65339"),
            currency = hex("#6ac44b"),
            unit = hex("#69c1cf"),
            results = hex("#6ac44b"),
            comment = hex("#909090")
        )
    ),
    NumbyTheme(
        name = "Thayer Bright",
        syntax = SyntaxColors(
            text = hex("#f8f8f8"),
            background = hex("#1b1d1e"),
            number = hex("#2757d6"),
            operator = hex("#f92672"),
            keyword = hex("#8c54fe"),
            function = hex("#f4fd22"),
            constant = hex("#2757d6"),
            variable = hex("#38c8b5"),
            variableUsage = hex("#8c54fe"),
            assignment = hex("#f92672"),
            currency = hex("#4df840"),
            unit = hex("#38c8b5"),
            results = hex("#4df840"),
            comment = hex("#505354")
        )
    ),
    NumbyTheme(
        name = "The Hulk",
        syntax = SyntaxColors(
            text = hex("#b5b5b5"),
            background = hex("#1b1d1e"),
            number = hex("#2525f5"),
            operator = hex("#269d1b"),
            keyword = hex("#712c80"),
            function = hex("#63e457"),
            constant = hex("#2525f5"),
            variable = hex("#378ca9"),
            variableUsage = hex("#712c80"),
            assignment = hex("#269d1b"),
            currency = hex("#13ce30"),
            unit = hex("#378ca9"),
            results = hex("#13ce30"),
            comment = hex("#505354")
        )
    ),
    NumbyTheme(
        name = "Tinacious Design Dark",
        syntax = SyntaxColors(
            text = hex("#cbcbf0"),
            background = hex("#1d1d26"),
            number = hex("#00cbff"),
            operator = hex("#ff3399"),
            keyword = hex("#cc66ff"),
            function = hex("#ffcc66"),
            constant = hex("#00cbff"),
            variable = hex("#00ceca"),
            variableUsage = hex("#cc66ff"),
            assignment = hex("#ff3399"),
            currency = hex("#00d364"),
            unit = hex("#00ceca"),
            results = hex("#00d364"),
            comment = hex("#636667")
        )
    ),
    NumbyTheme(
        name = "Tinacious Design Light",
        syntax = SyntaxColors(
            text = hex("#1d1d26"),
            background = hex("#f8f8ff"),
            number = hex("#00cbff"),
            operator = hex("#ff3399"),
            keyword = hex("#cc66ff"),
            function = hex("#e5b34d"),
            constant = hex("#00cbff"),
            variable = hex("#00ceca"),
            variableUsage = hex("#cc66ff"),
            assignment = hex("#ff3399"),
            currency = hex("#00d364"),
            unit = hex("#00ceca"),
            results = hex("#00d364"),
            comment = hex("#636667")
        )
    ),
    NumbyTheme(
        name = "TokyoNight Night",
        syntax = SyntaxColors(
            text = hex("#c0caf5"),
            background = hex("#1a1b26"),
            number = hex("#7aa2f7"),
            operator = hex("#f7768e"),
            keyword = hex("#bb9af7"),
            function = hex("#e0af68"),
            constant = hex("#7aa2f7"),
            variable = hex("#7dcfff"),
            variableUsage = hex("#bb9af7"),
            assignment = hex("#f7768e"),
            currency = hex("#9ece6a"),
            unit = hex("#7dcfff"),
            results = hex("#9ece6a"),
            comment = hex("#414868")
        )
    ),
    NumbyTheme(
        name = "Tomorrow Night Burns",
        syntax = SyntaxColors(
            text = hex("#a1b0b8"),
            background = hex("#151515"),
            number = hex("#fc595f"),
            operator = hex("#832e31"),
            keyword = hex("#df9395"),
            function = hex("#d3494e"),
            constant = hex("#fc595f"),
            variable = hex("#ba8586"),
            variableUsage = hex("#df9395"),
            assignment = hex("#832e31"),
            currency = hex("#a63c40"),
            unit = hex("#ba8586"),
            results = hex("#a63c40"),
            comment = hex("#5d6f71")
        )
    ),
    NumbyTheme(
        name = "Toy Chest",
        syntax = SyntaxColors(
            text = hex("#31d07b"),
            background = hex("#24364b"),
            number = hex("#325d96"),
            operator = hex("#be2d26"),
            keyword = hex("#8a5edc"),
            function = hex("#db8e27"),
            constant = hex("#325d96"),
            variable = hex("#35a08f"),
            variableUsage = hex("#8a5edc"),
            assignment = hex("#be2d26"),
            currency = hex("#1a9172"),
            unit = hex("#35a08f"),
            results = hex("#1a9172"),
            comment = hex("#336889")
        )
    ),
    NumbyTheme(
        name = "Treehouse",
        syntax = SyntaxColors(
            text = hex("#786b53"),
            background = hex("#191919"),
            number = hex("#58859a"),
            operator = hex("#b2270e"),
            keyword = hex("#97363d"),
            function = hex("#aa820c"),
            constant = hex("#58859a"),
            variable = hex("#b25a1e"),
            variableUsage = hex("#97363d"),
            assignment = hex("#b2270e"),
            currency = hex("#44a900"),
            unit = hex("#b25a1e"),
            results = hex("#44a900"),
            comment = hex("#504332")
        )
    ),
    NumbyTheme(
        name = "Ultra Dark",
        syntax = SyntaxColors(
            text = hex("#ffffff"),
            background = hex("#000000"),
            number = hex("#82aaff"),
            operator = hex("#f07178"),
            keyword = hex("#c792ea"),
            function = hex("#ffcb6b"),
            constant = hex("#82aaff"),
            variable = hex("#89ddff"),
            variableUsage = hex("#c792ea"),
            assignment = hex("#f07178"),
            currency = hex("#c3e88d"),
            unit = hex("#89ddff"),
            results = hex("#c3e88d"),
            comment = hex("#404040")
        )
    ),
    NumbyTheme(
        name = "Under The Sea",
        syntax = SyntaxColors(
            text = hex("#ffffff"),
            background = hex("#011116"),
            number = hex("#459a86"),
            operator = hex("#b2302d"),
            keyword = hex("#00599d"),
            function = hex("#59819c"),
            constant = hex("#459a86"),
            variable = hex("#5d7e19"),
            variableUsage = hex("#00599d"),
            assignment = hex("#b2302d"),
            currency = hex("#00a941"),
            unit = hex("#5d7e19"),
            results = hex("#00a941"),
            comment = hex("#384451")
        )
    ),
    NumbyTheme(
        name = "Unikitty",
        syntax = SyntaxColors(
            text = hex("#0b0b0b"),
            background = hex("#ff8cd9"),
            number = hex("#145fcd"),
            operator = hex("#a80f20"),
            keyword = hex("#ffe9ff"),
            function = hex("#fff965"),
            constant = hex("#145fcd"),
            variable = hex("#9effef"),
            variableUsage = hex("#ffe9ff"),
            assignment = hex("#a80f20"),
            currency = hex("#c7ff98"),
            unit = hex("#9effef"),
            results = hex("#c7ff98"),
            comment = hex("#434343")
        )
    ),
    NumbyTheme(
        name = "Urple",
        syntax = SyntaxColors(
            text = hex("#877a9b"),
            background = hex("#1b1b23"),
            number = hex("#564d9b"),
            operator = hex("#b0425b"),
            keyword = hex("#6c3ca1"),
            function = hex("#ad5c42"),
            constant = hex("#564d9b"),
            variable = hex("#808080"),
            variableUsage = hex("#6c3ca1"),
            assignment = hex("#b0425b"),
            currency = hex("#37a415"),
            unit = hex("#808080"),
            results = hex("#37a415"),
            comment = hex("#693e32")
        )
    ),
    NumbyTheme(
        name = "Vague",
        syntax = SyntaxColors(
            text = hex("#cdcdcd"),
            background = hex("#141415"),
            number = hex("#7e98e8"),
            operator = hex("#df6882"),
            keyword = hex("#c3c3d5"),
            function = hex("#f3be7c"),
            constant = hex("#7e98e8"),
            variable = hex("#9bb4bc"),
            variableUsage = hex("#c3c3d5"),
            assignment = hex("#df6882"),
            currency = hex("#8cb66d"),
            unit = hex("#9bb4bc"),
            results = hex("#8cb66d"),
            comment = hex("#878787")
        )
    ),
    NumbyTheme(
        name = "Vaughn",
        syntax = SyntaxColors(
            text = hex("#dcdccc"),
            background = hex("#25234f"),
            number = hex("#5555ff"),
            operator = hex("#705050"),
            keyword = hex("#f08cc3"),
            function = hex("#dfaf8f"),
            constant = hex("#5555ff"),
            variable = hex("#8cd0d3"),
            variableUsage = hex("#f08cc3"),
            assignment = hex("#705050"),
            currency = hex("#60b48a"),
            unit = hex("#8cd0d3"),
            results = hex("#60b48a"),
            comment = hex("#709080")
        )
    ),
    NumbyTheme(
        name = "Vimbones",
        syntax = SyntaxColors(
            text = hex("#353535"),
            background = hex("#f0f0ca"),
            number = hex("#286486"),
            operator = hex("#a8334c"),
            keyword = hex("#88507d"),
            function = hex("#944927"),
            constant = hex("#286486"),
            variable = hex("#3b8992"),
            variableUsage = hex("#88507d"),
            assignment = hex("#a8334c"),
            currency = hex("#4f6c31"),
            unit = hex("#3b8992"),
            results = hex("#4f6c31"),
            comment = hex("#acac89")
        )
    ),
    NumbyTheme(
        name = "Violet Dark",
        syntax = SyntaxColors(
            text = hex("#708284"),
            background = hex("#1c1d1f"),
            number = hex("#2e8bce"),
            operator = hex("#c94c22"),
            keyword = hex("#d13a82"),
            function = hex("#b4881d"),
            constant = hex("#2e8bce"),
            variable = hex("#32a198"),
            variableUsage = hex("#d13a82"),
            assignment = hex("#c94c22"),
            currency = hex("#85981c"),
            unit = hex("#32a198"),
            results = hex("#85981c"),
            comment = hex("#45484b")
        )
    ),
    NumbyTheme(
        name = "Violet Light",
        syntax = SyntaxColors(
            text = hex("#536870"),
            background = hex("#fcf4dc"),
            number = hex("#2e8bce"),
            operator = hex("#c94c22"),
            keyword = hex("#d13a82"),
            function = hex("#b4881d"),
            constant = hex("#2e8bce"),
            variable = hex("#32a198"),
            variableUsage = hex("#d13a82"),
            assignment = hex("#c94c22"),
            currency = hex("#85981c"),
            unit = hex("#32a198"),
            results = hex("#85981c"),
            comment = hex("#45484b")
        )
    ),
    NumbyTheme(
        name = "Violite",
        syntax = SyntaxColors(
            text = hex("#eef4f6"),
            background = hex("#241c36"),
            number = hex("#a979ec"),
            operator = hex("#ec7979"),
            keyword = hex("#ec79ec"),
            function = hex("#ece279"),
            constant = hex("#a979ec"),
            variable = hex("#79ecec"),
            variableUsage = hex("#ec79ec"),
            assignment = hex("#ec7979"),
            currency = hex("#79ecb3"),
            unit = hex("#79ecec"),
            results = hex("#79ecb3"),
            comment = hex("#554379")
        )
    ),
    NumbyTheme(
        name = "Warm Neon",
        syntax = SyntaxColors(
            text = hex("#afdab6"),
            background = hex("#404040"),
            number = hex("#4261c5"),
            operator = hex("#e24346"),
            keyword = hex("#f920fb"),
            function = hex("#dae145"),
            constant = hex("#4261c5"),
            variable = hex("#2abbd4"),
            variableUsage = hex("#f920fb"),
            assignment = hex("#e24346"),
            currency = hex("#39b13a"),
            unit = hex("#2abbd4"),
            results = hex("#39b13a"),
            comment = hex("#fefcfc")
        )
    ),
    NumbyTheme(
        name = "Wez",
        syntax = SyntaxColors(
            text = hex("#b3b3b3"),
            background = hex("#000000"),
            number = hex("#5555cc"),
            operator = hex("#cc5555"),
            keyword = hex("#cc55cc"),
            function = hex("#cdcd55"),
            constant = hex("#5555cc"),
            variable = hex("#7acaca"),
            variableUsage = hex("#cc55cc"),
            assignment = hex("#cc5555"),
            currency = hex("#55cc55"),
            unit = hex("#7acaca"),
            results = hex("#55cc55"),
            comment = hex("#555555")
        )
    ),
    NumbyTheme(
        name = "Wilmersdorf",
        syntax = SyntaxColors(
            text = hex("#c6c6c6"),
            background = hex("#282b33"),
            number = hex("#a6c1e0"),
            operator = hex("#e06383"),
            keyword = hex("#e1c1ee"),
            function = hex("#cccccc"),
            constant = hex("#a6c1e0"),
            variable = hex("#5b94ab"),
            variableUsage = hex("#e1c1ee"),
            assignment = hex("#e06383"),
            currency = hex("#7ebebd"),
            unit = hex("#5b94ab"),
            results = hex("#7ebebd"),
            comment = hex("#50545d")
        )
    ),
    NumbyTheme(
        name = "Wryan",
        syntax = SyntaxColors(
            text = hex("#999993"),
            background = hex("#101010"),
            number = hex("#395573"),
            operator = hex("#8c4665"),
            keyword = hex("#5e468c"),
            function = hex("#7c7c99"),
            constant = hex("#395573"),
            variable = hex("#31658c"),
            variableUsage = hex("#5e468c"),
            assignment = hex("#8c4665"),
            currency = hex("#287373"),
            unit = hex("#31658c"),
            results = hex("#287373"),
            comment = hex("#3d3d3d")
        )
    ),
    NumbyTheme(
        name = "Xcode Dark hc",
        syntax = SyntaxColors(
            text = hex("#ffffff"),
            background = hex("#1f1f24"),
            number = hex("#4ec4e6"),
            operator = hex("#ff8a7a"),
            keyword = hex("#ff85b8"),
            function = hex("#d9c668"),
            constant = hex("#4ec4e6"),
            variable = hex("#cda1ff"),
            variableUsage = hex("#ff85b8"),
            assignment = hex("#ff8a7a"),
            currency = hex("#83c9bc"),
            unit = hex("#cda1ff"),
            results = hex("#83c9bc"),
            comment = hex("#838991")
        )
    ),
    NumbyTheme(
        name = "Xcode Light hc",
        syntax = SyntaxColors(
            text = hex("#000000"),
            background = hex("#ffffff"),
            number = hex("#0058a1"),
            operator = hex("#ad1805"),
            keyword = hex("#9c2191"),
            function = hex("#78492a"),
            constant = hex("#0058a1"),
            variable = hex("#703daa"),
            variableUsage = hex("#9c2191"),
            assignment = hex("#ad1805"),
            currency = hex("#355d61"),
            unit = hex("#703daa"),
            results = hex("#355d61"),
            comment = hex("#8a99a6")
        )
    ),
    NumbyTheme(
        name = "Xcode WWDC",
        syntax = SyntaxColors(
            text = hex("#e7e8eb"),
            background = hex("#292c36"),
            number = hex("#8884c5"),
            operator = hex("#bb383a"),
            keyword = hex("#b73999"),
            function = hex("#d28e5d"),
            constant = hex("#8884c5"),
            variable = hex("#00aba4"),
            variableUsage = hex("#b73999"),
            assignment = hex("#bb383a"),
            currency = hex("#94c66e"),
            unit = hex("#00aba4"),
            results = hex("#94c66e"),
            comment = hex("#7f869e")
        )
    ),
    NumbyTheme(
        name = "Zenbones",
        syntax = SyntaxColors(
            text = hex("#2c363c"),
            background = hex("#f0edec"),
            number = hex("#286486"),
            operator = hex("#a8334c"),
            keyword = hex("#88507d"),
            function = hex("#944927"),
            constant = hex("#286486"),
            variable = hex("#3b8992"),
            variableUsage = hex("#88507d"),
            assignment = hex("#a8334c"),
            currency = hex("#4f6c31"),
            unit = hex("#3b8992"),
            results = hex("#4f6c31"),
            comment = hex("#b5a7a0")
        )
    ),
    NumbyTheme(
        name = "Zenburned",
        syntax = SyntaxColors(
            text = hex("#f0e4cf"),
            background = hex("#404040"),
            number = hex("#6099c0"),
            operator = hex("#e3716e"),
            keyword = hex("#b279a7"),
            function = hex("#b77e64"),
            constant = hex("#6099c0"),
            variable = hex("#66a5ad"),
            variableUsage = hex("#b279a7"),
            assignment = hex("#e3716e"),
            currency = hex("#819b69"),
            unit = hex("#66a5ad"),
            results = hex("#819b69"),
            comment = hex("#6f6768")
        )
    ),
    NumbyTheme(
        name = "Zenwritten Dark",
        syntax = SyntaxColors(
            text = hex("#bbbbbb"),
            background = hex("#191919"),
            number = hex("#6099c0"),
            operator = hex("#de6e7c"),
            keyword = hex("#b279a7"),
            function = hex("#b77e64"),
            constant = hex("#6099c0"),
            variable = hex("#66a5ad"),
            variableUsage = hex("#b279a7"),
            assignment = hex("#de6e7c"),
            currency = hex("#819b69"),
            unit = hex("#66a5ad"),
            results = hex("#819b69"),
            comment = hex("#4a4546")
        )
    ),
    NumbyTheme(
        name = "Zenwritten Light",
        syntax = SyntaxColors(
            text = hex("#353535"),
            background = hex("#eeeeee"),
            number = hex("#286486"),
            operator = hex("#a8334c"),
            keyword = hex("#88507d"),
            function = hex("#944927"),
            constant = hex("#286486"),
            variable = hex("#3b8992"),
            variableUsage = hex("#88507d"),
            assignment = hex("#a8334c"),
            currency = hex("#4f6c31"),
            unit = hex("#3b8992"),
            results = hex("#4f6c31"),
            comment = hex("#aca9a9")
        )
    ),
    NumbyTheme(
        name = "iTerm2 Dark Background",
        syntax = SyntaxColors(
            text = hex("#c7c7c7"),
            background = hex("#000000"),
            number = hex("#0225c7"),
            operator = hex("#c91b00"),
            keyword = hex("#ca30c7"),
            function = hex("#c7c400"),
            constant = hex("#0225c7"),
            variable = hex("#00c5c7"),
            variableUsage = hex("#ca30c7"),
            assignment = hex("#c91b00"),
            currency = hex("#00c200"),
            unit = hex("#00c5c7"),
            results = hex("#00c200"),
            comment = hex("#686868")
        )
    ),
    NumbyTheme(
        name = "iTerm2 Default",
        syntax = SyntaxColors(
            text = hex("#ffffff"),
            background = hex("#000000"),
            number = hex("#2225c4"),
            operator = hex("#c91b00"),
            keyword = hex("#ca30c7"),
            function = hex("#c7c400"),
            constant = hex("#2225c4"),
            variable = hex("#00c5c7"),
            variableUsage = hex("#ca30c7"),
            assignment = hex("#c91b00"),
            currency = hex("#00c200"),
            unit = hex("#00c5c7"),
            results = hex("#00c200"),
            comment = hex("#686868")
        )
    ),
    NumbyTheme(
        name = "iTerm2 Light Background",
        syntax = SyntaxColors(
            text = hex("#000000"),
            background = hex("#ffffff"),
            number = hex("#0225c7"),
            operator = hex("#c91b00"),
            keyword = hex("#ca30c7"),
            function = hex("#c7c400"),
            constant = hex("#0225c7"),
            variable = hex("#00c5c7"),
            variableUsage = hex("#ca30c7"),
            assignment = hex("#c91b00"),
            currency = hex("#00c200"),
            unit = hex("#00c5c7"),
            results = hex("#00c200"),
            comment = hex("#686868")
        )
    ),
    NumbyTheme(
        name = "iTerm2 Pastel Dark Background",
        syntax = SyntaxColors(
            text = hex("#c7c7c7"),
            background = hex("#000000"),
            number = hex("#a5d5fe"),
            operator = hex("#ff8373"),
            keyword = hex("#ff90fe"),
            function = hex("#fffdc3"),
            constant = hex("#a5d5fe"),
            variable = hex("#d1d1fe"),
            variableUsage = hex("#ff90fe"),
            assignment = hex("#ff8373"),
            currency = hex("#b4fb73"),
            unit = hex("#d1d1fe"),
            results = hex("#b4fb73"),
            comment = hex("#8f8f8f")
        )
    ),
    NumbyTheme(
        name = "iTerm2 Smoooooth",
        syntax = SyntaxColors(
            text = hex("#dcdcdc"),
            background = hex("#15191f"),
            number = hex("#2744c7"),
            operator = hex("#b43c2a"),
            keyword = hex("#c040be"),
            function = hex("#c7c400"),
            constant = hex("#2744c7"),
            variable = hex("#00c5c7"),
            variableUsage = hex("#c040be"),
            assignment = hex("#b43c2a"),
            currency = hex("#00c200"),
            unit = hex("#00c5c7"),
            results = hex("#00c200"),
            comment = hex("#686868")
        )
    ),
    NumbyTheme(
        name = "iTerm2 Tango Dark",
        syntax = SyntaxColors(
            text = hex("#ffffff"),
            background = hex("#000000"),
            number = hex("#427ab3"),
            operator = hex("#d81e00"),
            keyword = hex("#89658e"),
            function = hex("#cfae00"),
            constant = hex("#427ab3"),
            variable = hex("#00a7aa"),
            variableUsage = hex("#89658e"),
            assignment = hex("#d81e00"),
            currency = hex("#5ea702"),
            unit = hex("#00a7aa"),
            results = hex("#5ea702"),
            comment = hex("#686a66")
        )
    ),
    NumbyTheme(
        name = "iTerm2 Tango Light",
        syntax = SyntaxColors(
            text = hex("#000000"),
            background = hex("#ffffff"),
            number = hex("#427ab3"),
            operator = hex("#d81e00"),
            keyword = hex("#89658e"),
            function = hex("#cfae00"),
            constant = hex("#427ab3"),
            variable = hex("#00a7aa"),
            variableUsage = hex("#89658e"),
            assignment = hex("#d81e00"),
            currency = hex("#5ea702"),
            unit = hex("#00a7aa"),
            results = hex("#5ea702"),
            comment = hex("#686a66")
        )
    )
)

// Popular themes for quick access
val PopularThemes = AllThemes.take(20)

// Search themes by name
fun searchThemes(query: String): List<NumbyTheme> {
    if (query.isBlank()) return AllThemes
    val lowerQuery = query.lowercase()
    return AllThemes.filter { it.name.lowercase().contains(lowerQuery) }
}

// Get theme by name
fun getThemeByName(name: String): NumbyTheme? {
    return AllThemes.find { it.name.equals(name, ignoreCase = true) }
}

// Light themes
val LightThemes = AllThemes.filter { !it.isDark }

// Dark themes
val DarkThemes = AllThemes.filter { it.isDark }
