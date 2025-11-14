//
//  Theme.swift
//  Numby
//
//  Catppuccin themes for syntax highlighting and window appearance
//

import Foundation
import Combine
import AppKit
import SwiftUI

/// Color scheme for syntax highlighting
struct SyntaxColors: Codable, Hashable {
    let text: String
    let background: String
    let numbers: String
    let operators: String
    let keywords: String
    let functions: String
    let constants: String
    let variables: String
    let variableUsage: String
    let assignment: String
    let currency: String
    let units: String
    let results: String
    let comments: String
}

/// Theme definition
struct Theme: Codable, Hashable {
    let name: String
    let syntax: SyntaxColors
}

/// Catppuccin theme variants
enum CatppuccinTheme: String, CaseIterable, Codable {
    case latte = "Catppuccin Latte"
    case frappe = "Catppuccin Frappé"
    case macchiato = "Catppuccin Macchiato"
    case mocha = "Catppuccin Mocha"

    var theme: Theme {
        switch self {
        case .latte:
            return Theme(
                name: "Catppuccin Latte",
                syntax: SyntaxColors(
                    text: "#4C4F69",           // Base
                    background: "#EFF1F5",     // Base
                    numbers: "#04A5E5",        // Sapphire
                    operators: "#FE640B",      // Peach
                    keywords: "#8839EF",       // Mauve
                    functions: "#DF8E1D",      // Yellow
                    constants: "#1E66F5",      // Blue
                    variables: "#7287FD",      // Lavender
                    variableUsage: "#EA76CB",  // Pink
                    assignment: "#D20F39",     // Red
                    currency: "#40A02B",       // Green
                    units: "#179299",          // Teal
                    results: "#40A02B",        // Green
                    comments: "#9CA0B0"        // Overlay2 (gray for comments)
                )
            )

        case .frappe:
            return Theme(
                name: "Catppuccin Frappé",
                syntax: SyntaxColors(
                    text: "#C6D0F5",           // Text
                    background: "#303446",     // Base
                    numbers: "#85C1DC",        // Sapphire
                    operators: "#EF9F76",      // Peach
                    keywords: "#CA9EE6",       // Mauve
                    functions: "#E5C890",      // Yellow
                    constants: "#8CAAEE",      // Blue
                    variables: "#BABBF1",      // Lavender
                    variableUsage: "#F4B8E4",  // Pink
                    assignment: "#E78284",     // Red
                    currency: "#A6D189",       // Green
                    units: "#81C8BE",          // Teal
                    results: "#A6D189",        // Green
                    comments: "#838BA7"        // Overlay0 (gray for comments)
                )
            )

        case .macchiato:
            return Theme(
                name: "Catppuccin Macchiato",
                syntax: SyntaxColors(
                    text: "#CAD3F5",           // Text
                    background: "#24273A",     // Base
                    numbers: "#7DC4E4",        // Sapphire
                    operators: "#F5A97F",      // Peach
                    keywords: "#C6A0F6",       // Mauve
                    functions: "#EED49F",      // Yellow
                    constants: "#8AADF4",      // Blue
                    variables: "#B7BDF8",      // Lavender
                    variableUsage: "#F5BDE6",  // Pink
                    assignment: "#ED8796",     // Red
                    currency: "#A6DA95",       // Green
                    units: "#8BD5CA",          // Teal
                    results: "#A6DA95",        // Green
                    comments: "#6E738D"        // Overlay0 (gray for comments)
                )
            )

        case .mocha:
            return Theme(
                name: "Catppuccin Mocha",
                syntax: SyntaxColors(
                    text: "#CDD6F4",           // Text
                    background: "#1E1E2E",     // Base
                    numbers: "#74C7EC",        // Sapphire
                    operators: "#FAB387",      // Peach
                    keywords: "#CBA6F7",       // Mauve
                    functions: "#F9E2AF",      // Yellow
                    constants: "#89B4FA",      // Blue
                    variables: "#B4BEFE",      // Lavender
                    variableUsage: "#F5C2E7",  // Pink
                    assignment: "#F38BA8",     // Red
                    currency: "#A6E3A1",       // Green
                    units: "#94E2D5",          // Teal
                    results: "#A6E3A1",        // Green
                    comments: "#6C7086"        // Overlay0 (gray for comments)
                )
            )
        }
    }
}

/// Theme manager
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var currentTheme: Theme {
        didSet {
            saveTheme()
            applyTheme()
        }
    }

    private init() {
        // Load saved theme by name
        let savedThemeName = UserDefaults.standard.string(forKey: "selectedTheme")

        // Try to find the theme by name
        if let themeName = savedThemeName,
           let theme = Theme.allThemes.first(where: { $0.name == themeName }) {
            self.currentTheme = theme
        } else {
            // Default to Catppuccin Mocha
            self.currentTheme = CatppuccinTheme.mocha.theme
        }
    }

    private func saveTheme() {
        UserDefaults.standard.set(currentTheme.name, forKey: "selectedTheme")
    }

    func applyTheme() {
        let theme = currentTheme
        guard let bgColor = NSColor(hex: theme.syntax.background) else {
            return
        }

        // Update configuration (reassign to trigger @Published)
        var updatedConfig = ConfigurationManager.shared.config
        updatedConfig.backgroundColor = bgColor
        ConfigurationManager.shared.config = updatedConfig

        // Update all windows
        for window in NSApplication.shared.windows.compactMap({ $0 as? NumbyWindow }) {
            DispatchQueue.main.async { [weak window] in
                guard let window = window else { return }

                window.updateBackgroundColor(bgColor)

                window.controller?.objectWillChange.send()
                for (_, calculator) in window.controller?.calculators ?? [:] {
                    calculator.objectWillChange.send()
                }
            }
        }
    }

    func syntaxColor(for type: SyntaxColorType) -> NSColor {
        let theme = currentTheme
        let hex: String

        switch type {
        case .text: hex = theme.syntax.text
        case .background: hex = theme.syntax.background
        case .numbers: hex = theme.syntax.numbers
        case .operators: hex = theme.syntax.operators
        case .keywords: hex = theme.syntax.keywords
        case .functions: hex = theme.syntax.functions
        case .constants: hex = theme.syntax.constants
        case .variables: hex = theme.syntax.variables
        case .variableUsage: hex = theme.syntax.variableUsage
        case .assignment: hex = theme.syntax.assignment
        case .currency: hex = theme.syntax.currency
        case .units: hex = theme.syntax.units
        case .results: hex = theme.syntax.results
        case .comments: hex = theme.syntax.comments
        }

        return NSColor(hex: hex) ?? .textColor
    }
}

enum SyntaxColorType {
    case text, background, numbers, operators, keywords, functions
    case constants, variables, variableUsage, assignment, currency, units, results, comments
}

// MARK: - All Themes
extension Theme {
    static let allThemes: [Theme] = [
    Theme(
        name: "0x96f",
        syntax: SyntaxColors(
            text: "#fcfcfa",
            background: "#262427",
            numbers: "#00cde8",
            operators: "#ff666d",
            keywords: "#a392e8",
            functions: "#ffc739",
            constants: "#00cde8",
            variables: "#9deaf6",
            variableUsage: "#a392e8",
            assignment: "#ff666d",
            currency: "#b3e03a",
            units: "#9deaf6",
            results: "#b3e03a",
            comments: "#545452"
        )
    ),
    Theme(
        name: "12-bit Rainbow",
        syntax: SyntaxColors(
            text: "#feffff",
            background: "#040404",
            numbers: "#3060b0",
            operators: "#a03050",
            keywords: "#603090",
            functions: "#e09040",
            constants: "#3060b0",
            variables: "#0090c0",
            variableUsage: "#603090",
            assignment: "#a03050",
            currency: "#40d080",
            units: "#0090c0",
            results: "#40d080",
            comments: "#685656"
        )
    ),
    Theme(
        name: "3024 Day",
        syntax: SyntaxColors(
            text: "#4a4543",
            background: "#f7f7f7",
            numbers: "#01a0e4",
            operators: "#db2d20",
            keywords: "#a16a94",
            functions: "#caba00",
            constants: "#01a0e4",
            variables: "#8fbece",
            variableUsage: "#a16a94",
            assignment: "#db2d20",
            currency: "#01a252",
            units: "#8fbece",
            results: "#01a252",
            comments: "#5c5855"
        )
    ),
    Theme(
        name: "3024 Night",
        syntax: SyntaxColors(
            text: "#a5a2a2",
            background: "#090300",
            numbers: "#01a0e4",
            operators: "#db2d20",
            keywords: "#a16a94",
            functions: "#fded02",
            constants: "#01a0e4",
            variables: "#b5e4f4",
            variableUsage: "#a16a94",
            assignment: "#db2d20",
            currency: "#01a252",
            units: "#b5e4f4",
            results: "#01a252",
            comments: "#5c5855"
        )
    ),
    Theme(
        name: "Aardvark Blue",
        syntax: SyntaxColors(
            text: "#dddddd",
            background: "#102040",
            numbers: "#1370d3",
            operators: "#aa342e",
            keywords: "#c43ac3",
            functions: "#dbba00",
            constants: "#1370d3",
            variables: "#008eb0",
            variableUsage: "#c43ac3",
            assignment: "#aa342e",
            currency: "#4b8c0f",
            units: "#008eb0",
            results: "#4b8c0f",
            comments: "#525252"
        )
    ),
    Theme(
        name: "Abernathy",
        syntax: SyntaxColors(
            text: "#eeeeec",
            background: "#111416",
            numbers: "#1093f5",
            operators: "#cd0000",
            keywords: "#cd00cd",
            functions: "#cdcd00",
            constants: "#1093f5",
            variables: "#00cdcd",
            variableUsage: "#cd00cd",
            assignment: "#cd0000",
            currency: "#00cd00",
            units: "#00cdcd",
            results: "#00cd00",
            comments: "#404040"
        )
    ),
    Theme(
        name: "Adventure",
        syntax: SyntaxColors(
            text: "#feffff",
            background: "#040404",
            numbers: "#417ab3",
            operators: "#d84a33",
            keywords: "#e5c499",
            functions: "#eebb6e",
            constants: "#417ab3",
            variables: "#bdcfe5",
            variableUsage: "#e5c499",
            assignment: "#d84a33",
            currency: "#5da602",
            units: "#bdcfe5",
            results: "#5da602",
            comments: "#685656"
        )
    ),
    Theme(
        name: "Adventure Time",
        syntax: SyntaxColors(
            text: "#f8dcc0",
            background: "#1f1d45",
            numbers: "#0f4ac6",
            operators: "#bd0013",
            keywords: "#665993",
            functions: "#e7741e",
            constants: "#0f4ac6",
            variables: "#70a598",
            variableUsage: "#665993",
            assignment: "#bd0013",
            currency: "#4ab118",
            units: "#70a598",
            results: "#4ab118",
            comments: "#4e7cbf"
        )
    ),
    Theme(
        name: "Adwaita",
        syntax: SyntaxColors(
            text: "#000000",
            background: "#ffffff",
            numbers: "#1e78e4",
            operators: "#c01c28",
            keywords: "#9841bb",
            functions: "#e8b504",
            constants: "#1e78e4",
            variables: "#0ab9dc",
            variableUsage: "#9841bb",
            assignment: "#c01c28",
            currency: "#2ec27e",
            units: "#0ab9dc",
            results: "#2ec27e",
            comments: "#5e5c64"
        )
    ),
    Theme(
        name: "Adwaita Dark",
        syntax: SyntaxColors(
            text: "#ffffff",
            background: "#1d1d20",
            numbers: "#1e78e4",
            operators: "#c01c28",
            keywords: "#9841bb",
            functions: "#f5c211",
            constants: "#1e78e4",
            variables: "#0ab9dc",
            variableUsage: "#9841bb",
            assignment: "#c01c28",
            currency: "#2ec27e",
            units: "#0ab9dc",
            results: "#2ec27e",
            comments: "#5e5c64"
        )
    ),
    Theme(
        name: "Afterglow",
        syntax: SyntaxColors(
            text: "#d0d0d0",
            background: "#212121",
            numbers: "#6c99bb",
            operators: "#ac4142",
            keywords: "#9f4e85",
            functions: "#e5b567",
            constants: "#6c99bb",
            variables: "#7dd6cf",
            variableUsage: "#9f4e85",
            assignment: "#ac4142",
            currency: "#7e8e50",
            units: "#7dd6cf",
            results: "#7e8e50",
            comments: "#505050"
        )
    ),
    Theme(
        name: "Alabaster",
        syntax: SyntaxColors(
            text: "#000000",
            background: "#f7f7f7",
            numbers: "#325cc0",
            operators: "#aa3731",
            keywords: "#7a3e9d",
            functions: "#cb9000",
            constants: "#325cc0",
            variables: "#0083b2",
            variableUsage: "#7a3e9d",
            assignment: "#aa3731",
            currency: "#448c27",
            units: "#0083b2",
            results: "#448c27",
            comments: "#777777"
        )
    ),
    Theme(
        name: "Alien Blood",
        syntax: SyntaxColors(
            text: "#637d75",
            background: "#0f1610",
            numbers: "#2f6a7f",
            operators: "#7f2b27",
            keywords: "#47587f",
            functions: "#717f24",
            constants: "#2f6a7f",
            variables: "#327f77",
            variableUsage: "#47587f",
            assignment: "#7f2b27",
            currency: "#2f7e25",
            units: "#327f77",
            results: "#2f7e25",
            comments: "#3c4812"
        )
    ),
    Theme(
        name: "Andromeda",
        syntax: SyntaxColors(
            text: "#e5e5e5",
            background: "#262a33",
            numbers: "#2472c8",
            operators: "#cd3131",
            keywords: "#bc3fbc",
            functions: "#e5e512",
            constants: "#2472c8",
            variables: "#0fa8cd",
            variableUsage: "#bc3fbc",
            assignment: "#cd3131",
            currency: "#05bc79",
            units: "#0fa8cd",
            results: "#05bc79",
            comments: "#666666"
        )
    ),
    Theme(
        name: "Apple Classic",
        syntax: SyntaxColors(
            text: "#d5a200",
            background: "#2c2b2b",
            numbers: "#1c3fe1",
            operators: "#c91b00",
            keywords: "#ca30c7",
            functions: "#c7c400",
            constants: "#1c3fe1",
            variables: "#00c5c7",
            variableUsage: "#ca30c7",
            assignment: "#c91b00",
            currency: "#00c200",
            units: "#00c5c7",
            results: "#00c200",
            comments: "#686868"
        )
    ),
    Theme(
        name: "Apple System Colors",
        syntax: SyntaxColors(
            text: "#ffffff",
            background: "#1e1e1e",
            numbers: "#0869cb",
            operators: "#cc372e",
            keywords: "#9647bf",
            functions: "#cdac08",
            constants: "#0869cb",
            variables: "#479ec2",
            variableUsage: "#9647bf",
            assignment: "#cc372e",
            currency: "#26a439",
            units: "#479ec2",
            results: "#26a439",
            comments: "#464646"
        )
    ),
    Theme(
        name: "Apple System Colors Light",
        syntax: SyntaxColors(
            text: "#000000",
            background: "#feffff",
            numbers: "#0869cb",
            operators: "#cc372e",
            keywords: "#9647bf",
            functions: "#cdac08",
            constants: "#0869cb",
            variables: "#479ec2",
            variableUsage: "#9647bf",
            assignment: "#cc372e",
            currency: "#26a439",
            units: "#479ec2",
            results: "#26a439",
            comments: "#464646"
        )
    ),
    Theme(
        name: "Arcoiris",
        syntax: SyntaxColors(
            text: "#eee4d9",
            background: "#201f1e",
            numbers: "#518bfc",
            operators: "#da2700",
            keywords: "#e37bd9",
            functions: "#ffc656",
            constants: "#518bfc",
            variables: "#63fad5",
            variableUsage: "#e37bd9",
            assignment: "#da2700",
            currency: "#12c258",
            units: "#63fad5",
            results: "#12c258",
            comments: "#777777"
        )
    ),
    Theme(
        name: "Ardoise",
        syntax: SyntaxColors(
            text: "#eaeaea",
            background: "#1e1e1e",
            numbers: "#2465c2",
            operators: "#d3322d",
            keywords: "#7332b4",
            functions: "#fca93a",
            constants: "#2465c2",
            variables: "#64e1b8",
            variableUsage: "#7332b4",
            assignment: "#d3322d",
            currency: "#588b35",
            units: "#64e1b8",
            results: "#588b35",
            comments: "#535353"
        )
    ),
    Theme(
        name: "Argonaut",
        syntax: SyntaxColors(
            text: "#fffaf4",
            background: "#0e1019",
            numbers: "#008df8",
            operators: "#ff000f",
            keywords: "#6d43a6",
            functions: "#ffb900",
            constants: "#008df8",
            variables: "#00d8eb",
            variableUsage: "#6d43a6",
            assignment: "#ff000f",
            currency: "#8ce10b",
            units: "#00d8eb",
            results: "#8ce10b",
            comments: "#444444"
        )
    ),
    Theme(
        name: "Arthur",
        syntax: SyntaxColors(
            text: "#ddeedd",
            background: "#1c1c1c",
            numbers: "#6495ed",
            operators: "#cd5c5c",
            keywords: "#deb887",
            functions: "#e8ae5b",
            constants: "#6495ed",
            variables: "#b0c4de",
            variableUsage: "#deb887",
            assignment: "#cd5c5c",
            currency: "#86af80",
            units: "#b0c4de",
            results: "#86af80",
            comments: "#554444"
        )
    ),
    Theme(
        name: "Atelier Sulphurpool",
        syntax: SyntaxColors(
            text: "#979db4",
            background: "#202746",
            numbers: "#3d8fd1",
            operators: "#c94922",
            keywords: "#6679cc",
            functions: "#c08b30",
            constants: "#3d8fd1",
            variables: "#22a2c9",
            variableUsage: "#6679cc",
            assignment: "#c94922",
            currency: "#ac9739",
            units: "#22a2c9",
            results: "#ac9739",
            comments: "#6b7394"
        )
    ),
    Theme(
        name: "Atom",
        syntax: SyntaxColors(
            text: "#c5c8c6",
            background: "#161719",
            numbers: "#85befd",
            operators: "#fd5ff1",
            keywords: "#b9b6fc",
            functions: "#ffd7b1",
            constants: "#85befd",
            variables: "#85befd",
            variableUsage: "#b9b6fc",
            assignment: "#fd5ff1",
            currency: "#87c38a",
            units: "#85befd",
            results: "#87c38a",
            comments: "#4c4c4c"
        )
    ),
    Theme(
        name: "Atom One Dark",
        syntax: SyntaxColors(
            text: "#abb2bf",
            background: "#21252b",
            numbers: "#61afef",
            operators: "#e06c75",
            keywords: "#c678dd",
            functions: "#e5c07b",
            constants: "#61afef",
            variables: "#56b6c2",
            variableUsage: "#c678dd",
            assignment: "#e06c75",
            currency: "#98c379",
            units: "#56b6c2",
            results: "#98c379",
            comments: "#767676"
        )
    ),
    Theme(
        name: "Atom One Light",
        syntax: SyntaxColors(
            text: "#2a2c33",
            background: "#f9f9f9",
            numbers: "#2f5af3",
            operators: "#de3e35",
            keywords: "#950095",
            functions: "#d2b67c",
            constants: "#2f5af3",
            variables: "#3f953a",
            variableUsage: "#950095",
            assignment: "#de3e35",
            currency: "#3f953a",
            units: "#3f953a",
            results: "#3f953a",
            comments: "#000000"
        )
    ),
    Theme(
        name: "Aura",
        syntax: SyntaxColors(
            text: "#edecee",
            background: "#15141b",
            numbers: "#a277ff",
            operators: "#ff6767",
            keywords: "#a277ff",
            functions: "#ffca85",
            constants: "#a277ff",
            variables: "#61ffca",
            variableUsage: "#a277ff",
            assignment: "#ff6767",
            currency: "#61ffca",
            units: "#61ffca",
            results: "#61ffca",
            comments: "#4d4d4d"
        )
    ),
    Theme(
        name: "Aurora",
        syntax: SyntaxColors(
            text: "#ffca28",
            background: "#23262e",
            numbers: "#102ee4",
            operators: "#f0266f",
            keywords: "#ee5d43",
            functions: "#ffe66d",
            constants: "#102ee4",
            variables: "#03d6b8",
            variableUsage: "#ee5d43",
            assignment: "#f0266f",
            currency: "#8fd46d",
            units: "#03d6b8",
            results: "#8fd46d",
            comments: "#4f545e"
        )
    ),
    Theme(
        name: "Ayu",
        syntax: SyntaxColors(
            text: "#bfbdb6",
            background: "#0b0e14",
            numbers: "#53bdfa",
            operators: "#ea6c73",
            keywords: "#cda1fa",
            functions: "#f9af4f",
            constants: "#53bdfa",
            variables: "#90e1c6",
            variableUsage: "#cda1fa",
            assignment: "#ea6c73",
            currency: "#7fd962",
            units: "#90e1c6",
            results: "#7fd962",
            comments: "#686868"
        )
    ),
    Theme(
        name: "Ayu Light",
        syntax: SyntaxColors(
            text: "#5c6166",
            background: "#f8f9fa",
            numbers: "#3199e1",
            operators: "#ea6c6d",
            keywords: "#9e75c7",
            functions: "#eca944",
            constants: "#3199e1",
            variables: "#46ba94",
            variableUsage: "#9e75c7",
            assignment: "#ea6c6d",
            currency: "#6cbf43",
            units: "#46ba94",
            results: "#6cbf43",
            comments: "#686868"
        )
    ),
    Theme(
        name: "Ayu Mirage",
        syntax: SyntaxColors(
            text: "#cccac2",
            background: "#1f2430",
            numbers: "#6dcbfa",
            operators: "#ed8274",
            keywords: "#dabafa",
            functions: "#facc6e",
            constants: "#6dcbfa",
            variables: "#90e1c6",
            variableUsage: "#dabafa",
            assignment: "#ed8274",
            currency: "#87d96c",
            units: "#90e1c6",
            results: "#87d96c",
            comments: "#686868"
        )
    ),
    Theme(
        name: "Banana Blueberry",
        syntax: SyntaxColors(
            text: "#cccccc",
            background: "#191323",
            numbers: "#22e8df",
            operators: "#ff6b7f",
            keywords: "#dc396a",
            functions: "#e6c62f",
            constants: "#22e8df",
            variables: "#56b6c2",
            variableUsage: "#dc396a",
            assignment: "#ff6b7f",
            currency: "#00bd9c",
            units: "#56b6c2",
            results: "#00bd9c",
            comments: "#495162"
        )
    ),
    Theme(
        name: "Batman",
        syntax: SyntaxColors(
            text: "#6f6f6f",
            background: "#1b1d1e",
            numbers: "#737174",
            operators: "#e6dc44",
            keywords: "#747271",
            functions: "#f4fd22",
            constants: "#737174",
            variables: "#62605f",
            variableUsage: "#747271",
            assignment: "#e6dc44",
            currency: "#c8be46",
            units: "#62605f",
            results: "#c8be46",
            comments: "#505354"
        )
    ),
    Theme(
        name: "Belafonte Day",
        syntax: SyntaxColors(
            text: "#45373c",
            background: "#d5ccba",
            numbers: "#426a79",
            operators: "#be100e",
            keywords: "#97522c",
            functions: "#d08b30",
            constants: "#426a79",
            variables: "#989a9c",
            variableUsage: "#97522c",
            assignment: "#be100e",
            currency: "#858162",
            units: "#989a9c",
            results: "#858162",
            comments: "#5e5252"
        )
    ),
    Theme(
        name: "Belafonte Night",
        syntax: SyntaxColors(
            text: "#968c83",
            background: "#20111b",
            numbers: "#426a79",
            operators: "#be100e",
            keywords: "#97522c",
            functions: "#eaa549",
            constants: "#426a79",
            variables: "#989a9c",
            variableUsage: "#97522c",
            assignment: "#be100e",
            currency: "#858162",
            units: "#989a9c",
            results: "#858162",
            comments: "#5e5252"
        )
    ),
    Theme(
        name: "Birds Of Paradise",
        syntax: SyntaxColors(
            text: "#e0dbb7",
            background: "#2a1f1d",
            numbers: "#5a86ad",
            operators: "#be2d26",
            keywords: "#ac80a6",
            functions: "#e99d2a",
            constants: "#5a86ad",
            variables: "#74a6ad",
            variableUsage: "#ac80a6",
            assignment: "#be2d26",
            currency: "#6ba18a",
            units: "#74a6ad",
            results: "#6ba18a",
            comments: "#9b6c4a"
        )
    ),
    Theme(
        name: "Black Metal",
        syntax: SyntaxColors(
            text: "#c1c1c1",
            background: "#000000",
            numbers: "#888888",
            operators: "#486e6f",
            keywords: "#999999",
            functions: "#a06666",
            constants: "#888888",
            variables: "#aaaaaa",
            variableUsage: "#999999",
            assignment: "#486e6f",
            currency: "#dd9999",
            units: "#aaaaaa",
            results: "#dd9999",
            comments: "#3f3f3f"
        )
    ),
    Theme(
        name: "Black Metal (Bathory)",
        syntax: SyntaxColors(
            text: "#c1c1c1",
            background: "#000000",
            numbers: "#888888",
            operators: "#5f8787",
            keywords: "#999999",
            functions: "#e78a53",
            constants: "#888888",
            variables: "#aaaaaa",
            variableUsage: "#999999",
            assignment: "#5f8787",
            currency: "#fbcb97",
            units: "#aaaaaa",
            results: "#fbcb97",
            comments: "#3f3f3f"
        )
    ),
    Theme(
        name: "Black Metal (Burzum)",
        syntax: SyntaxColors(
            text: "#c1c1c1",
            background: "#000000",
            numbers: "#888888",
            operators: "#5f8787",
            keywords: "#999999",
            functions: "#99bbaa",
            constants: "#888888",
            variables: "#aaaaaa",
            variableUsage: "#999999",
            assignment: "#5f8787",
            currency: "#ddeecc",
            units: "#aaaaaa",
            results: "#ddeecc",
            comments: "#3f3f3f"
        )
    ),
    Theme(
        name: "Black Metal (Dark Funeral)",
        syntax: SyntaxColors(
            text: "#c1c1c1",
            background: "#000000",
            numbers: "#888888",
            operators: "#5f8787",
            keywords: "#999999",
            functions: "#5f81a5",
            constants: "#888888",
            variables: "#aaaaaa",
            variableUsage: "#999999",
            assignment: "#5f8787",
            currency: "#d0dfee",
            units: "#aaaaaa",
            results: "#d0dfee",
            comments: "#3f3f3f"
        )
    ),
    Theme(
        name: "Black Metal (Gorgoroth)",
        syntax: SyntaxColors(
            text: "#c1c1c1",
            background: "#000000",
            numbers: "#888888",
            operators: "#5f8787",
            keywords: "#999999",
            functions: "#8c7f70",
            constants: "#888888",
            variables: "#aaaaaa",
            variableUsage: "#999999",
            assignment: "#5f8787",
            currency: "#9b8d7f",
            units: "#aaaaaa",
            results: "#9b8d7f",
            comments: "#3f3f3f"
        )
    ),
    Theme(
        name: "Black Metal (Immortal)",
        syntax: SyntaxColors(
            text: "#c1c1c1",
            background: "#000000",
            numbers: "#888888",
            operators: "#5f8787",
            keywords: "#999999",
            functions: "#556677",
            constants: "#888888",
            variables: "#aaaaaa",
            variableUsage: "#999999",
            assignment: "#5f8787",
            currency: "#7799bb",
            units: "#aaaaaa",
            results: "#7799bb",
            comments: "#3f3f3f"
        )
    ),
    Theme(
        name: "Black Metal (Khold)",
        syntax: SyntaxColors(
            text: "#c1c1c1",
            background: "#000000",
            numbers: "#888888",
            operators: "#5f8787",
            keywords: "#999999",
            functions: "#974b46",
            constants: "#888888",
            variables: "#aaaaaa",
            variableUsage: "#999999",
            assignment: "#5f8787",
            currency: "#eceee3",
            units: "#aaaaaa",
            results: "#eceee3",
            comments: "#3f3f3f"
        )
    ),
    Theme(
        name: "Black Metal (Marduk)",
        syntax: SyntaxColors(
            text: "#c1c1c1",
            background: "#000000",
            numbers: "#888888",
            operators: "#5f8787",
            keywords: "#999999",
            functions: "#626b67",
            constants: "#888888",
            variables: "#aaaaaa",
            variableUsage: "#999999",
            assignment: "#5f8787",
            currency: "#a5aaa7",
            units: "#aaaaaa",
            results: "#a5aaa7",
            comments: "#3f3f3f"
        )
    ),
    Theme(
        name: "Black Metal (Mayhem)",
        syntax: SyntaxColors(
            text: "#c1c1c1",
            background: "#000000",
            numbers: "#888888",
            operators: "#5f8787",
            keywords: "#999999",
            functions: "#eecc6c",
            constants: "#888888",
            variables: "#aaaaaa",
            variableUsage: "#999999",
            assignment: "#5f8787",
            currency: "#f3ecd4",
            units: "#aaaaaa",
            results: "#f3ecd4",
            comments: "#3f3f3f"
        )
    ),
    Theme(
        name: "Black Metal (Nile)",
        syntax: SyntaxColors(
            text: "#c1c1c1",
            background: "#000000",
            numbers: "#888888",
            operators: "#5f8787",
            keywords: "#999999",
            functions: "#777755",
            constants: "#888888",
            variables: "#aaaaaa",
            variableUsage: "#999999",
            assignment: "#5f8787",
            currency: "#aa9988",
            units: "#aaaaaa",
            results: "#aa9988",
            comments: "#3f3f3f"
        )
    ),
    Theme(
        name: "Black Metal (Venom)",
        syntax: SyntaxColors(
            text: "#c1c1c1",
            background: "#000000",
            numbers: "#888888",
            operators: "#5f8787",
            keywords: "#999999",
            functions: "#79241f",
            constants: "#888888",
            variables: "#aaaaaa",
            variableUsage: "#999999",
            assignment: "#5f8787",
            currency: "#f8f7f2",
            units: "#aaaaaa",
            results: "#f8f7f2",
            comments: "#3f3f3f"
        )
    ),
    Theme(
        name: "Blazer",
        syntax: SyntaxColors(
            text: "#d9e6f2",
            background: "#0d1926",
            numbers: "#7a7ab8",
            operators: "#b87a7a",
            keywords: "#b87ab8",
            functions: "#b8b87a",
            constants: "#7a7ab8",
            variables: "#7ab8b8",
            variableUsage: "#b87ab8",
            assignment: "#b87a7a",
            currency: "#7ab87a",
            units: "#7ab8b8",
            results: "#7ab87a",
            comments: "#4c4c4c"
        )
    ),
    Theme(
        name: "Blue Berry Pie",
        syntax: SyntaxColors(
            text: "#babab9",
            background: "#1c0c28",
            numbers: "#90a5bd",
            operators: "#99246e",
            keywords: "#9d54a7",
            functions: "#eab9a8",
            constants: "#90a5bd",
            variables: "#7e83cc",
            variableUsage: "#9d54a7",
            assignment: "#99246e",
            currency: "#5cb1b3",
            units: "#7e83cc",
            results: "#5cb1b3",
            comments: "#463d5d"
        )
    ),
    Theme(
        name: "Blue Dolphin",
        syntax: SyntaxColors(
            text: "#c5f2ff",
            background: "#006984",
            numbers: "#82aaff",
            operators: "#ff8288",
            keywords: "#e9c1ff",
            functions: "#f4d69f",
            constants: "#82aaff",
            variables: "#89ebff",
            variableUsage: "#e9c1ff",
            assignment: "#ff8288",
            currency: "#b4e88d",
            units: "#89ebff",
            results: "#b4e88d",
            comments: "#838798"
        )
    ),
    Theme(
        name: "Blue Matrix",
        syntax: SyntaxColors(
            text: "#00a2ff",
            background: "#101116",
            numbers: "#00b0ff",
            operators: "#ff5680",
            keywords: "#d57bff",
            functions: "#fffc58",
            constants: "#00b0ff",
            variables: "#76c1ff",
            variableUsage: "#d57bff",
            assignment: "#ff5680",
            currency: "#00ff9c",
            units: "#76c1ff",
            results: "#00ff9c",
            comments: "#686868"
        )
    ),
    Theme(
        name: "Bluloco Dark",
        syntax: SyntaxColors(
            text: "#b9c0cb",
            background: "#282c34",
            numbers: "#3476ff",
            operators: "#fc2f52",
            keywords: "#7a82da",
            functions: "#ff936a",
            constants: "#3476ff",
            variables: "#4483aa",
            variableUsage: "#7a82da",
            assignment: "#fc2f52",
            currency: "#25a45c",
            units: "#4483aa",
            results: "#25a45c",
            comments: "#8f9aae"
        )
    ),
    Theme(
        name: "Bluloco Light",
        syntax: SyntaxColors(
            text: "#373a41",
            background: "#f9f9f9",
            numbers: "#275fe4",
            operators: "#d52753",
            keywords: "#823ff1",
            functions: "#df631c",
            constants: "#275fe4",
            variables: "#27618d",
            variableUsage: "#823ff1",
            assignment: "#d52753",
            currency: "#23974a",
            units: "#27618d",
            results: "#23974a",
            comments: "#676a77"
        )
    ),
    Theme(
        name: "Borland",
        syntax: SyntaxColors(
            text: "#ffff4e",
            background: "#0000a4",
            numbers: "#96cbfe",
            operators: "#ff6c60",
            keywords: "#ff73fd",
            functions: "#ffffb6",
            constants: "#96cbfe",
            variables: "#c6c5fe",
            variableUsage: "#ff73fd",
            assignment: "#ff6c60",
            currency: "#a8ff60",
            units: "#c6c5fe",
            results: "#a8ff60",
            comments: "#7c7c7c"
        )
    ),
    Theme(
        name: "Box",
        syntax: SyntaxColors(
            text: "#9fef00",
            background: "#141d2b",
            numbers: "#0d73cc",
            operators: "#cc0403",
            keywords: "#cb1ed1",
            functions: "#cecb00",
            constants: "#0d73cc",
            variables: "#0dcdcd",
            variableUsage: "#cb1ed1",
            assignment: "#cc0403",
            currency: "#19cb00",
            units: "#0dcdcd",
            results: "#19cb00",
            comments: "#767676"
        )
    ),
    Theme(
        name: "Breadog",
        syntax: SyntaxColors(
            text: "#362c24",
            background: "#f1ebe6",
            numbers: "#005cb4",
            operators: "#b10b00",
            keywords: "#9b0097",
            functions: "#8b4c00",
            constants: "#005cb4",
            variables: "#006a78",
            variableUsage: "#9b0097",
            assignment: "#b10b00",
            currency: "#007232",
            units: "#006a78",
            results: "#007232",
            comments: "#514337"
        )
    ),
    Theme(
        name: "Breeze",
        syntax: SyntaxColors(
            text: "#eff0f1",
            background: "#31363b",
            numbers: "#1d99f3",
            operators: "#ed1515",
            keywords: "#9b59b6",
            functions: "#f67400",
            constants: "#1d99f3",
            variables: "#1abc9c",
            variableUsage: "#9b59b6",
            assignment: "#ed1515",
            currency: "#11d116",
            units: "#1abc9c",
            results: "#11d116",
            comments: "#7f8c8d"
        )
    ),
    Theme(
        name: "Bright Lights",
        syntax: SyntaxColors(
            text: "#b3c9d7",
            background: "#191919",
            numbers: "#76d4ff",
            operators: "#ff355b",
            keywords: "#ba76e7",
            functions: "#ffc251",
            constants: "#76d4ff",
            variables: "#6cbfb5",
            variableUsage: "#ba76e7",
            assignment: "#ff355b",
            currency: "#b7e876",
            units: "#6cbfb5",
            results: "#b7e876",
            comments: "#4c4c4c"
        )
    ),
    Theme(
        name: "Broadcast",
        syntax: SyntaxColors(
            text: "#e6e1dc",
            background: "#2b2b2b",
            numbers: "#6d9cbe",
            operators: "#da4939",
            keywords: "#d0d0ff",
            functions: "#ffd24a",
            constants: "#6d9cbe",
            variables: "#6e9cbe",
            variableUsage: "#d0d0ff",
            assignment: "#da4939",
            currency: "#519f50",
            units: "#6e9cbe",
            results: "#519f50",
            comments: "#585858"
        )
    ),
    Theme(
        name: "Brogrammer",
        syntax: SyntaxColors(
            text: "#d6dbe5",
            background: "#131313",
            numbers: "#2a84d2",
            operators: "#f81118",
            keywords: "#4e5ab7",
            functions: "#ecba0f",
            constants: "#2a84d2",
            variables: "#1081d6",
            variableUsage: "#4e5ab7",
            assignment: "#f81118",
            currency: "#2dc55e",
            units: "#1081d6",
            results: "#2dc55e",
            comments: "#d6dbe5"
        )
    ),
    Theme(
        name: "Builtin Dark",
        syntax: SyntaxColors(
            text: "#bbbbbb",
            background: "#000000",
            numbers: "#0d0dc8",
            operators: "#bb0000",
            keywords: "#bb00bb",
            functions: "#bbbb00",
            constants: "#0d0dc8",
            variables: "#00bbbb",
            variableUsage: "#bb00bb",
            assignment: "#bb0000",
            currency: "#00bb00",
            units: "#00bbbb",
            results: "#00bb00",
            comments: "#555555"
        )
    ),
    Theme(
        name: "Builtin Light",
        syntax: SyntaxColors(
            text: "#000000",
            background: "#ffffff",
            numbers: "#0000bb",
            operators: "#bb0000",
            keywords: "#bb00bb",
            functions: "#bbbb00",
            constants: "#0000bb",
            variables: "#00bbbb",
            variableUsage: "#bb00bb",
            assignment: "#bb0000",
            currency: "#00bb00",
            units: "#00bbbb",
            results: "#00bb00",
            comments: "#555555"
        )
    ),
    Theme(
        name: "Builtin Pastel Dark",
        syntax: SyntaxColors(
            text: "#bbbbbb",
            background: "#000000",
            numbers: "#96cbfe",
            operators: "#ff6c60",
            keywords: "#ff73fd",
            functions: "#ffffb6",
            constants: "#96cbfe",
            variables: "#c6c5fe",
            variableUsage: "#ff73fd",
            assignment: "#ff6c60",
            currency: "#a8ff60",
            units: "#c6c5fe",
            results: "#a8ff60",
            comments: "#7c7c7c"
        )
    ),
    Theme(
        name: "Builtin Solarized Dark",
        syntax: SyntaxColors(
            text: "#839496",
            background: "#002b36",
            numbers: "#268bd2",
            operators: "#dc322f",
            keywords: "#d33682",
            functions: "#b58900",
            constants: "#268bd2",
            variables: "#2aa198",
            variableUsage: "#d33682",
            assignment: "#dc322f",
            currency: "#859900",
            units: "#2aa198",
            results: "#859900",
            comments: "#335e69"
        )
    ),
    Theme(
        name: "Builtin Solarized Light",
        syntax: SyntaxColors(
            text: "#657b83",
            background: "#fdf6e3",
            numbers: "#268bd2",
            operators: "#dc322f",
            keywords: "#d33682",
            functions: "#b58900",
            constants: "#268bd2",
            variables: "#2aa198",
            variableUsage: "#d33682",
            assignment: "#dc322f",
            currency: "#859900",
            units: "#2aa198",
            results: "#859900",
            comments: "#002b36"
        )
    ),
    Theme(
        name: "Builtin Tango Dark",
        syntax: SyntaxColors(
            text: "#ffffff",
            background: "#000000",
            numbers: "#3465a4",
            operators: "#cc0000",
            keywords: "#75507b",
            functions: "#c4a000",
            constants: "#3465a4",
            variables: "#06989a",
            variableUsage: "#75507b",
            assignment: "#cc0000",
            currency: "#4e9a06",
            units: "#06989a",
            results: "#4e9a06",
            comments: "#555753"
        )
    ),
    Theme(
        name: "Builtin Tango Light",
        syntax: SyntaxColors(
            text: "#000000",
            background: "#ffffff",
            numbers: "#3465a4",
            operators: "#cc0000",
            keywords: "#75507b",
            functions: "#c4a000",
            constants: "#3465a4",
            variables: "#06989a",
            variableUsage: "#75507b",
            assignment: "#cc0000",
            currency: "#4e9a06",
            units: "#06989a",
            results: "#4e9a06",
            comments: "#555753"
        )
    ),
    Theme(
        name: "C64",
        syntax: SyntaxColors(
            text: "#7869c4",
            background: "#40318d",
            numbers: "#6657b3",
            operators: "#a2534c",
            keywords: "#984ca3",
            functions: "#bfce72",
            constants: "#6657b3",
            variables: "#67b6bd",
            variableUsage: "#984ca3",
            assignment: "#a2534c",
            currency: "#55a049",
            units: "#67b6bd",
            results: "#55a049",
            comments: "#000000"
        )
    ),
    Theme(
        name: "CGA",
        syntax: SyntaxColors(
            text: "#aaaaaa",
            background: "#000000",
            numbers: "#0d0db7",
            operators: "#aa0000",
            keywords: "#aa00aa",
            functions: "#aa5500",
            constants: "#0d0db7",
            variables: "#00aaaa",
            variableUsage: "#aa00aa",
            assignment: "#aa0000",
            currency: "#00aa00",
            units: "#00aaaa",
            results: "#00aa00",
            comments: "#555555"
        )
    ),
    Theme(
        name: "CLRS",
        syntax: SyntaxColors(
            text: "#262626",
            background: "#ffffff",
            numbers: "#135cd0",
            operators: "#f8282a",
            keywords: "#9f00bd",
            functions: "#fa701d",
            constants: "#135cd0",
            variables: "#33c3c1",
            variableUsage: "#9f00bd",
            assignment: "#f8282a",
            currency: "#328a5d",
            units: "#33c3c1",
            results: "#328a5d",
            comments: "#555753"
        )
    ),
    Theme(
        name: "Calamity",
        syntax: SyntaxColors(
            text: "#d5ced9",
            background: "#2f2833",
            numbers: "#3b79c7",
            operators: "#fc644d",
            keywords: "#f92672",
            functions: "#e9d7a5",
            constants: "#3b79c7",
            variables: "#74d3de",
            variableUsage: "#f92672",
            assignment: "#fc644d",
            currency: "#a5f69c",
            units: "#74d3de",
            results: "#a5f69c",
            comments: "#7e6c88"
        )
    ),
    Theme(
        name: "Carbonfox",
        syntax: SyntaxColors(
            text: "#f2f4f8",
            background: "#161616",
            numbers: "#78a9ff",
            operators: "#ee5396",
            keywords: "#be95ff",
            functions: "#08bdba",
            constants: "#78a9ff",
            variables: "#33b1ff",
            variableUsage: "#be95ff",
            assignment: "#ee5396",
            currency: "#25be6a",
            units: "#33b1ff",
            results: "#25be6a",
            comments: "#484848"
        )
    ),
    Theme(
        name: "Chalk",
        syntax: SyntaxColors(
            text: "#d2d8d9",
            background: "#2b2d2e",
            numbers: "#2a7fac",
            operators: "#b23a52",
            keywords: "#bd4f5a",
            functions: "#b9ac4a",
            constants: "#2a7fac",
            variables: "#44a799",
            variableUsage: "#bd4f5a",
            assignment: "#b23a52",
            currency: "#789b6a",
            units: "#44a799",
            results: "#789b6a",
            comments: "#888888"
        )
    ),
    Theme(
        name: "Chalkboard",
        syntax: SyntaxColors(
            text: "#d9e6f2",
            background: "#29262f",
            numbers: "#7372c3",
            operators: "#c37372",
            keywords: "#c372c2",
            functions: "#c2c372",
            constants: "#7372c3",
            variables: "#72c2c3",
            variableUsage: "#c372c2",
            assignment: "#c37372",
            currency: "#72c373",
            units: "#72c2c3",
            results: "#72c373",
            comments: "#585858"
        )
    ),
    Theme(
        name: "Challenger Deep",
        syntax: SyntaxColors(
            text: "#cbe1e7",
            background: "#1e1c31",
            numbers: "#65b2ff",
            operators: "#ff5458",
            keywords: "#906cff",
            functions: "#ffb378",
            constants: "#65b2ff",
            variables: "#63f2f1",
            variableUsage: "#906cff",
            assignment: "#ff5458",
            currency: "#62d196",
            units: "#63f2f1",
            results: "#62d196",
            comments: "#565575"
        )
    ),
    Theme(
        name: "Chester",
        syntax: SyntaxColors(
            text: "#ffffff",
            background: "#2c3643",
            numbers: "#288ad6",
            operators: "#fa5e5b",
            keywords: "#d34590",
            functions: "#ffc83f",
            constants: "#288ad6",
            variables: "#28ddde",
            variableUsage: "#d34590",
            assignment: "#fa5e5b",
            currency: "#16c98d",
            units: "#28ddde",
            results: "#16c98d",
            comments: "#6f6b68"
        )
    ),
    Theme(
        name: "Ciapre",
        syntax: SyntaxColors(
            text: "#aea47a",
            background: "#191c27",
            numbers: "#576d8c",
            operators: "#8e0d16",
            keywords: "#724d7c",
            functions: "#cc8b3f",
            constants: "#576d8c",
            variables: "#5c4f4b",
            variableUsage: "#724d7c",
            assignment: "#8e0d16",
            currency: "#48513b",
            units: "#5c4f4b",
            results: "#48513b",
            comments: "#555555"
        )
    ),
    Theme(
        name: "Citruszest",
        syntax: SyntaxColors(
            text: "#bfbfbf",
            background: "#121212",
            numbers: "#00bfff",
            operators: "#ff5454",
            keywords: "#ff90fe",
            functions: "#ffd400",
            constants: "#00bfff",
            variables: "#48d1cc",
            variableUsage: "#ff90fe",
            assignment: "#ff5454",
            currency: "#00cc7a",
            units: "#48d1cc",
            results: "#00cc7a",
            comments: "#808080"
        )
    ),
    Theme(
        name: "Cobalt Neon",
        syntax: SyntaxColors(
            text: "#8ff586",
            background: "#142838",
            numbers: "#8ff586",
            operators: "#ff2320",
            keywords: "#781aa0",
            functions: "#e9e75c",
            constants: "#8ff586",
            variables: "#8ff586",
            variableUsage: "#781aa0",
            assignment: "#ff2320",
            currency: "#3ba5ff",
            units: "#8ff586",
            results: "#3ba5ff",
            comments: "#fff688"
        )
    ),
    Theme(
        name: "Cobalt Next",
        syntax: SyntaxColors(
            text: "#d7deea",
            background: "#162c35",
            numbers: "#409dd4",
            operators: "#ff527b",
            keywords: "#cba3c7",
            functions: "#ffc64c",
            constants: "#409dd4",
            variables: "#37b5b4",
            variableUsage: "#cba3c7",
            assignment: "#ff527b",
            currency: "#8cc98f",
            units: "#37b5b4",
            results: "#8cc98f",
            comments: "#62747f"
        )
    ),
    Theme(
        name: "Cobalt Next Dark",
        syntax: SyntaxColors(
            text: "#d7deea",
            background: "#0b1c24",
            numbers: "#409dd4",
            operators: "#f94967",
            keywords: "#cba3c7",
            functions: "#ffc64c",
            constants: "#409dd4",
            variables: "#37b5b4",
            variableUsage: "#cba3c7",
            assignment: "#f94967",
            currency: "#8cc98f",
            units: "#37b5b4",
            results: "#8cc98f",
            comments: "#62747f"
        )
    ),
    Theme(
        name: "Cobalt Next Minimal",
        syntax: SyntaxColors(
            text: "#d7deea",
            background: "#0b1c24",
            numbers: "#409dd4",
            operators: "#ff657a",
            keywords: "#cba3c7",
            functions: "#ffc64c",
            constants: "#409dd4",
            variables: "#37b5b4",
            variableUsage: "#cba3c7",
            assignment: "#ff657a",
            currency: "#8cc98f",
            units: "#37b5b4",
            results: "#8cc98f",
            comments: "#62747f"
        )
    ),
    Theme(
        name: "Cobalt2",
        syntax: SyntaxColors(
            text: "#ffffff",
            background: "#132738",
            numbers: "#1460d2",
            operators: "#ff0000",
            keywords: "#ff005d",
            functions: "#ffe50a",
            constants: "#1460d2",
            variables: "#00bbbb",
            variableUsage: "#ff005d",
            assignment: "#ff0000",
            currency: "#38de21",
            units: "#00bbbb",
            results: "#38de21",
            comments: "#555555"
        )
    ),
    Theme(
        name: "Coffee Theme",
        syntax: SyntaxColors(
            text: "#000000",
            background: "#f5deb3",
            numbers: "#0225c7",
            operators: "#c91b00",
            keywords: "#ca30c7",
            functions: "#aeab00",
            constants: "#0225c7",
            variables: "#00b9bb",
            variableUsage: "#ca30c7",
            assignment: "#c91b00",
            currency: "#00c200",
            units: "#00b9bb",
            results: "#00c200",
            comments: "#686868"
        )
    ),
    Theme(
        name: "Crayon Pony Fish",
        syntax: SyntaxColors(
            text: "#68525a",
            background: "#150707",
            numbers: "#8c87b0",
            operators: "#91002b",
            keywords: "#692f50",
            functions: "#ab311b",
            constants: "#8c87b0",
            variables: "#e8a866",
            variableUsage: "#692f50",
            assignment: "#91002b",
            currency: "#579524",
            units: "#e8a866",
            results: "#579524",
            comments: "#49373b"
        )
    ),
    Theme(
        name: "Cursor Dark",
        syntax: SyntaxColors(
            text: "#ffffff",
            background: "#141414",
            numbers: "#81a1c1",
            operators: "#bf616a",
            keywords: "#b48ead",
            functions: "#ebcb8b",
            constants: "#81a1c1",
            variables: "#88c0d0",
            variableUsage: "#b48ead",
            assignment: "#bf616a",
            currency: "#a3be8c",
            units: "#88c0d0",
            results: "#a3be8c",
            comments: "#505050"
        )
    ),
    Theme(
        name: "Cutie Pro",
        syntax: SyntaxColors(
            text: "#d5d0c9",
            background: "#181818",
            numbers: "#42d9c5",
            operators: "#f56e7f",
            keywords: "#d286b7",
            functions: "#f58669",
            constants: "#42d9c5",
            variables: "#37cb8a",
            variableUsage: "#d286b7",
            assignment: "#f56e7f",
            currency: "#bec975",
            units: "#37cb8a",
            results: "#bec975",
            comments: "#88847f"
        )
    ),
    Theme(
        name: "Cyberdyne",
        syntax: SyntaxColors(
            text: "#00ff92",
            background: "#151144",
            numbers: "#0071cf",
            operators: "#ff8373",
            keywords: "#ff90fe",
            functions: "#d2a700",
            constants: "#0071cf",
            variables: "#6bffdd",
            variableUsage: "#ff90fe",
            assignment: "#ff8373",
            currency: "#00c172",
            units: "#6bffdd",
            results: "#00c172",
            comments: "#474747"
        )
    ),
    Theme(
        name: "Cyberpunk",
        syntax: SyntaxColors(
            text: "#e5e5e5",
            background: "#332a57",
            numbers: "#00bfff",
            operators: "#ff7092",
            keywords: "#df95ff",
            functions: "#fffa6a",
            constants: "#00bfff",
            variables: "#86cbfe",
            variableUsage: "#df95ff",
            assignment: "#ff7092",
            currency: "#00fbac",
            units: "#86cbfe",
            results: "#00fbac",
            comments: "#595959"
        )
    ),
    Theme(
        name: "Cyberpunk Scarlet Protocol",
        syntax: SyntaxColors(
            text: "#e41951",
            background: "#101116",
            numbers: "#0271b6",
            operators: "#ff0051",
            keywords: "#c930c7",
            functions: "#faf945",
            constants: "#0271b6",
            variables: "#00c5c7",
            variableUsage: "#c930c7",
            assignment: "#ff0051",
            currency: "#01dc84",
            units: "#00c5c7",
            results: "#01dc84",
            comments: "#686868"
        )
    ),
    Theme(
        name: "Dark Modern",
        syntax: SyntaxColors(
            text: "#cccccc",
            background: "#1f1f1f",
            numbers: "#0078d4",
            operators: "#f74949",
            keywords: "#d01273",
            functions: "#9e6a03",
            constants: "#0078d4",
            variables: "#1db4d6",
            variableUsage: "#d01273",
            assignment: "#f74949",
            currency: "#2ea043",
            units: "#1db4d6",
            results: "#2ea043",
            comments: "#5d5d5d"
        )
    ),
    Theme(
        name: "Dark Pastel",
        syntax: SyntaxColors(
            text: "#ffffff",
            background: "#000000",
            numbers: "#5555ff",
            operators: "#ff5555",
            keywords: "#ff55ff",
            functions: "#ffff55",
            constants: "#5555ff",
            variables: "#55ffff",
            variableUsage: "#ff55ff",
            assignment: "#ff5555",
            currency: "#55ff55",
            units: "#55ffff",
            results: "#55ff55",
            comments: "#555555"
        )
    ),
    Theme(
        name: "Dark+",
        syntax: SyntaxColors(
            text: "#cccccc",
            background: "#1e1e1e",
            numbers: "#2472c8",
            operators: "#cd3131",
            keywords: "#bc3fbc",
            functions: "#e5e510",
            constants: "#2472c8",
            variables: "#11a8cd",
            variableUsage: "#bc3fbc",
            assignment: "#cd3131",
            currency: "#0dbc79",
            units: "#11a8cd",
            results: "#0dbc79",
            comments: "#666666"
        )
    ),
    Theme(
        name: "Darkermatrix",
        syntax: SyntaxColors(
            text: "#35451a",
            background: "#070c0e",
            numbers: "#00cb6b",
            operators: "#1a4832",
            keywords: "#4e375a",
            functions: "#595900",
            constants: "#00cb6b",
            variables: "#125459",
            variableUsage: "#4e375a",
            assignment: "#1a4832",
            currency: "#6fa64c",
            units: "#125459",
            results: "#6fa64c",
            comments: "#404040"
        )
    ),
    Theme(
        name: "Darkmatrix",
        syntax: SyntaxColors(
            text: "#3e5715",
            background: "#070c0e",
            numbers: "#2c9a84",
            operators: "#006536",
            keywords: "#523a60",
            functions: "#7e8000",
            constants: "#2c9a84",
            variables: "#114d53",
            variableUsage: "#523a60",
            assignment: "#006536",
            currency: "#6fa64c",
            units: "#114d53",
            results: "#6fa64c",
            comments: "#404040"
        )
    ),
    Theme(
        name: "Darkside",
        syntax: SyntaxColors(
            text: "#bababa",
            background: "#222324",
            numbers: "#1c98e8",
            operators: "#e8341c",
            keywords: "#8e69c9",
            functions: "#f2d42c",
            constants: "#1c98e8",
            variables: "#1c98e8",
            variableUsage: "#8e69c9",
            assignment: "#e8341c",
            currency: "#68c256",
            units: "#1c98e8",
            results: "#68c256",
            comments: "#4c4c4c"
        )
    ),
    Theme(
        name: "Dawnfox",
        syntax: SyntaxColors(
            text: "#575279",
            background: "#faf4ed",
            numbers: "#286983",
            operators: "#b4637a",
            keywords: "#907aa9",
            functions: "#ea9d34",
            constants: "#286983",
            variables: "#56949f",
            variableUsage: "#907aa9",
            assignment: "#b4637a",
            currency: "#618774",
            units: "#56949f",
            results: "#618774",
            comments: "#5f5695"
        )
    ),
    Theme(
        name: "Dayfox",
        syntax: SyntaxColors(
            text: "#3d2b5a",
            background: "#f6f2ee",
            numbers: "#2848a9",
            operators: "#a5222f",
            keywords: "#6e33ce",
            functions: "#ac5402",
            constants: "#2848a9",
            variables: "#287980",
            variableUsage: "#6e33ce",
            assignment: "#a5222f",
            currency: "#396847",
            units: "#287980",
            results: "#396847",
            comments: "#534c45"
        )
    ),
    Theme(
        name: "Deep",
        syntax: SyntaxColors(
            text: "#cdcdcd",
            background: "#090909",
            numbers: "#5665ff",
            operators: "#d70005",
            keywords: "#b052da",
            functions: "#d9bd26",
            constants: "#5665ff",
            variables: "#50d2da",
            variableUsage: "#b052da",
            assignment: "#d70005",
            currency: "#1cd915",
            units: "#50d2da",
            results: "#1cd915",
            comments: "#535353"
        )
    ),
    Theme(
        name: "Desert",
        syntax: SyntaxColors(
            text: "#ffffff",
            background: "#333333",
            numbers: "#cd853f",
            operators: "#ff2b2b",
            keywords: "#ffdead",
            functions: "#f0e68c",
            constants: "#cd853f",
            variables: "#ffa0a0",
            variableUsage: "#ffdead",
            assignment: "#ff2b2b",
            currency: "#98fb98",
            units: "#ffa0a0",
            results: "#98fb98",
            comments: "#626262"
        )
    ),
    Theme(
        name: "Detuned",
        syntax: SyntaxColors(
            text: "#c7c7c7",
            background: "#000000",
            numbers: "#0094d9",
            operators: "#fe4386",
            keywords: "#9b37ff",
            functions: "#e6da73",
            constants: "#0094d9",
            variables: "#50b7d9",
            variableUsage: "#9b37ff",
            assignment: "#fe4386",
            currency: "#a6e32d",
            units: "#50b7d9",
            results: "#a6e32d",
            comments: "#686868"
        )
    ),
    Theme(
        name: "Dimidium",
        syntax: SyntaxColors(
            text: "#bab7b6",
            background: "#141414",
            numbers: "#0575d8",
            operators: "#cf494c",
            keywords: "#af5ed2",
            functions: "#db9c11",
            constants: "#0575d8",
            variables: "#1db6bb",
            variableUsage: "#af5ed2",
            assignment: "#cf494c",
            currency: "#60b442",
            units: "#1db6bb",
            results: "#60b442",
            comments: "#817e7e"
        )
    ),
    Theme(
        name: "Dimmed Monokai",
        syntax: SyntaxColors(
            text: "#b9bcba",
            background: "#1f1f1f",
            numbers: "#4f76a1",
            operators: "#be3f48",
            keywords: "#855c8d",
            functions: "#c5a635",
            constants: "#4f76a1",
            variables: "#578fa4",
            variableUsage: "#855c8d",
            assignment: "#be3f48",
            currency: "#879a3b",
            units: "#578fa4",
            results: "#879a3b",
            comments: "#888987"
        )
    ),
    Theme(
        name: "Django",
        syntax: SyntaxColors(
            text: "#f8f8f8",
            background: "#0b2f20",
            numbers: "#315d3f",
            operators: "#fd6209",
            keywords: "#f8f8f8",
            functions: "#ffe862",
            constants: "#315d3f",
            variables: "#9df39f",
            variableUsage: "#f8f8f8",
            assignment: "#fd6209",
            currency: "#41a83e",
            units: "#9df39f",
            results: "#41a83e",
            comments: "#585858"
        )
    ),
    Theme(
        name: "Django Reborn Again",
        syntax: SyntaxColors(
            text: "#dadedc",
            background: "#051f14",
            numbers: "#245032",
            operators: "#fd6209",
            keywords: "#f8f8f8",
            functions: "#ffe862",
            constants: "#245032",
            variables: "#9df39f",
            variableUsage: "#f8f8f8",
            assignment: "#fd6209",
            currency: "#41a83e",
            units: "#9df39f",
            results: "#41a83e",
            comments: "#4c4c4c"
        )
    ),
    Theme(
        name: "Django Smooth",
        syntax: SyntaxColors(
            text: "#f8f8f8",
            background: "#245032",
            numbers: "#989898",
            operators: "#fd6209",
            keywords: "#f8f8f8",
            functions: "#ffe862",
            constants: "#989898",
            variables: "#9df39f",
            variableUsage: "#f8f8f8",
            assignment: "#fd6209",
            currency: "#41a83e",
            units: "#9df39f",
            results: "#41a83e",
            comments: "#727272"
        )
    ),
    Theme(
        name: "Doom One",
        syntax: SyntaxColors(
            text: "#bbc2cf",
            background: "#282c34",
            numbers: "#a9a1e1",
            operators: "#ff6c6b",
            keywords: "#c678dd",
            functions: "#ecbe7b",
            constants: "#a9a1e1",
            variables: "#51afef",
            variableUsage: "#c678dd",
            assignment: "#ff6c6b",
            currency: "#98be65",
            units: "#51afef",
            results: "#98be65",
            comments: "#595959"
        )
    ),
    Theme(
        name: "Doom Peacock",
        syntax: SyntaxColors(
            text: "#ede0ce",
            background: "#2b2a27",
            numbers: "#2a6cc6",
            operators: "#cb4b16",
            keywords: "#a9a1e1",
            functions: "#bcd42a",
            constants: "#2a6cc6",
            variables: "#5699af",
            variableUsage: "#a9a1e1",
            assignment: "#cb4b16",
            currency: "#26a6a6",
            units: "#5699af",
            results: "#26a6a6",
            comments: "#51504d"
        )
    ),
    Theme(
        name: "Dot Gov",
        syntax: SyntaxColors(
            text: "#ebebeb",
            background: "#262c35",
            numbers: "#17b2e0",
            operators: "#bf091d",
            keywords: "#7830b0",
            functions: "#f6bb34",
            constants: "#17b2e0",
            variables: "#8bd2ed",
            variableUsage: "#7830b0",
            assignment: "#bf091d",
            currency: "#3d9751",
            units: "#8bd2ed",
            results: "#3d9751",
            comments: "#595959"
        )
    ),
    Theme(
        name: "Dracula",
        syntax: SyntaxColors(
            text: "#f8f8f2",
            background: "#282a36",
            numbers: "#bd93f9",
            operators: "#ff5555",
            keywords: "#ff79c6",
            functions: "#f1fa8c",
            constants: "#bd93f9",
            variables: "#8be9fd",
            variableUsage: "#ff79c6",
            assignment: "#ff5555",
            currency: "#50fa7b",
            units: "#8be9fd",
            results: "#50fa7b",
            comments: "#6272a4"
        )
    ),
    Theme(
        name: "Dracula+",
        syntax: SyntaxColors(
            text: "#f8f8f2",
            background: "#212121",
            numbers: "#82aaff",
            operators: "#ff5555",
            keywords: "#c792ea",
            functions: "#ffcb6b",
            constants: "#82aaff",
            variables: "#8be9fd",
            variableUsage: "#c792ea",
            assignment: "#ff5555",
            currency: "#50fa7b",
            units: "#8be9fd",
            results: "#50fa7b",
            comments: "#545454"
        )
    ),
    Theme(
        name: "Duckbones",
        syntax: SyntaxColors(
            text: "#ebefc0",
            background: "#0e101a",
            numbers: "#00a3cb",
            operators: "#e03600",
            keywords: "#795ccc",
            functions: "#e39500",
            constants: "#00a3cb",
            variables: "#00a3cb",
            variableUsage: "#795ccc",
            assignment: "#e03600",
            currency: "#5dcd97",
            units: "#00a3cb",
            results: "#5dcd97",
            comments: "#454860"
        )
    ),
    Theme(
        name: "Duotone Dark",
        syntax: SyntaxColors(
            text: "#b7a1ff",
            background: "#1f1d27",
            numbers: "#ffc284",
            operators: "#d9393e",
            keywords: "#de8d40",
            functions: "#d9b76e",
            constants: "#ffc284",
            variables: "#2488ff",
            variableUsage: "#de8d40",
            assignment: "#d9393e",
            currency: "#2dcd73",
            units: "#2488ff",
            results: "#2dcd73",
            comments: "#4f4b60"
        )
    ),
    Theme(
        name: "Duskfox",
        syntax: SyntaxColors(
            text: "#e0def4",
            background: "#232136",
            numbers: "#569fba",
            operators: "#eb6f92",
            keywords: "#c4a7e7",
            functions: "#f6c177",
            constants: "#569fba",
            variables: "#9ccfd8",
            variableUsage: "#c4a7e7",
            assignment: "#eb6f92",
            currency: "#a3be8c",
            units: "#9ccfd8",
            results: "#a3be8c",
            comments: "#544d8a"
        )
    ),
    Theme(
        name: "ENCOM",
        syntax: SyntaxColors(
            text: "#00a595",
            background: "#000000",
            numbers: "#0081ff",
            operators: "#9f0000",
            keywords: "#bc00ca",
            functions: "#ffd000",
            constants: "#0081ff",
            variables: "#008b8b",
            variableUsage: "#bc00ca",
            assignment: "#9f0000",
            currency: "#008b00",
            units: "#008b8b",
            results: "#008b00",
            comments: "#555555"
        )
    ),
    Theme(
        name: "Earthsong",
        syntax: SyntaxColors(
            text: "#e5c7a9",
            background: "#292520",
            numbers: "#1398b9",
            operators: "#c94234",
            keywords: "#d0633d",
            functions: "#f5ae2e",
            constants: "#1398b9",
            variables: "#509552",
            variableUsage: "#d0633d",
            assignment: "#c94234",
            currency: "#85c54c",
            units: "#509552",
            results: "#85c54c",
            comments: "#675f54"
        )
    ),
    Theme(
        name: "Electron Highlighter",
        syntax: SyntaxColors(
            text: "#a5b6d4",
            background: "#23283d",
            numbers: "#77abff",
            operators: "#ff6c8d",
            keywords: "#daa4f4",
            functions: "#ffd7a9",
            constants: "#77abff",
            variables: "#00fdff",
            variableUsage: "#daa4f4",
            assignment: "#ff6c8d",
            currency: "#00ffc3",
            units: "#00fdff",
            results: "#00ffc3",
            comments: "#4a6789"
        )
    ),
    Theme(
        name: "Elegant",
        syntax: SyntaxColors(
            text: "#ced2d6",
            background: "#292b31",
            numbers: "#8dabe1",
            operators: "#ff0257",
            keywords: "#c792eb",
            functions: "#ffcb8b",
            constants: "#8dabe1",
            variables: "#78ccf0",
            variableUsage: "#c792eb",
            assignment: "#ff0257",
            currency: "#85cc95",
            units: "#78ccf0",
            results: "#85cc95",
            comments: "#575656"
        )
    ),
    Theme(
        name: "Elemental",
        syntax: SyntaxColors(
            text: "#807a74",
            background: "#22211d",
            numbers: "#497f7d",
            operators: "#98290f",
            keywords: "#7f4e2f",
            functions: "#7f7111",
            constants: "#497f7d",
            variables: "#387f58",
            variableUsage: "#7f4e2f",
            assignment: "#98290f",
            currency: "#479a43",
            units: "#387f58",
            results: "#479a43",
            comments: "#555445"
        )
    ),
    Theme(
        name: "Elementary",
        syntax: SyntaxColors(
            text: "#efefef",
            background: "#181818",
            numbers: "#124799",
            operators: "#d71c15",
            keywords: "#e40038",
            functions: "#fdb40c",
            constants: "#124799",
            variables: "#2595e1",
            variableUsage: "#e40038",
            assignment: "#d71c15",
            currency: "#5aa513",
            units: "#2595e1",
            results: "#5aa513",
            comments: "#4b4b4b"
        )
    ),
    Theme(
        name: "Embark",
        syntax: SyntaxColors(
            text: "#eeffff",
            background: "#1e1c31",
            numbers: "#57c7ff",
            operators: "#f0719b",
            keywords: "#c792ea",
            functions: "#ffe9aa",
            constants: "#57c7ff",
            variables: "#87dfeb",
            variableUsage: "#c792ea",
            assignment: "#f0719b",
            currency: "#a1efd3",
            units: "#87dfeb",
            results: "#a1efd3",
            comments: "#585273"
        )
    ),
    Theme(
        name: "Embers Dark",
        syntax: SyntaxColors(
            text: "#a39a90",
            background: "#16130f",
            numbers: "#6d5782",
            operators: "#826d57",
            keywords: "#82576d",
            functions: "#6d8257",
            constants: "#6d5782",
            variables: "#576d82",
            variableUsage: "#82576d",
            assignment: "#826d57",
            currency: "#57826d",
            units: "#576d82",
            results: "#57826d",
            comments: "#5a5047"
        )
    ),
    Theme(
        name: "Espresso",
        syntax: SyntaxColors(
            text: "#ffffff",
            background: "#323232",
            numbers: "#6c99bb",
            operators: "#d25252",
            keywords: "#d197d9",
            functions: "#ffc66d",
            constants: "#6c99bb",
            variables: "#bed6ff",
            variableUsage: "#d197d9",
            assignment: "#d25252",
            currency: "#a5c261",
            units: "#bed6ff",
            results: "#a5c261",
            comments: "#606060"
        )
    ),
    Theme(
        name: "Espresso Libre",
        syntax: SyntaxColors(
            text: "#b8a898",
            background: "#2a211c",
            numbers: "#0066ff",
            operators: "#cc0000",
            keywords: "#c5656b",
            functions: "#f0e53a",
            constants: "#0066ff",
            variables: "#06989a",
            variableUsage: "#c5656b",
            assignment: "#cc0000",
            currency: "#1a921c",
            units: "#06989a",
            results: "#1a921c",
            comments: "#555753"
        )
    ),
    Theme(
        name: "Everblush",
        syntax: SyntaxColors(
            text: "#dadada",
            background: "#141b1e",
            numbers: "#67b0e8",
            operators: "#e57474",
            keywords: "#c47fd5",
            functions: "#e5c76b",
            constants: "#67b0e8",
            variables: "#6cbfbf",
            variableUsage: "#c47fd5",
            assignment: "#e57474",
            currency: "#8ccf7e",
            units: "#6cbfbf",
            results: "#8ccf7e",
            comments: "#464e50"
        )
    ),
    Theme(
        name: "Everforest Dark Hard",
        syntax: SyntaxColors(
            text: "#d3c6aa",
            background: "#1e2326",
            numbers: "#7fbbb3",
            operators: "#e67e80",
            keywords: "#d699b6",
            functions: "#dbbc7f",
            constants: "#7fbbb3",
            variables: "#83c092",
            variableUsage: "#d699b6",
            assignment: "#e67e80",
            currency: "#a7c080",
            units: "#83c092",
            results: "#a7c080",
            comments: "#a6b0a0"
        )
    ),
    Theme(
        name: "Everforest Light Med",
        syntax: SyntaxColors(
            text: "#5c6a72",
            background: "#efebd4",
            numbers: "#7fbbb3",
            operators: "#e67e80",
            keywords: "#d699b6",
            functions: "#c1a266",
            constants: "#7fbbb3",
            variables: "#83c092",
            variableUsage: "#d699b6",
            assignment: "#e67e80",
            currency: "#9ab373",
            units: "#83c092",
            results: "#9ab373",
            comments: "#a6b0a0"
        )
    ),
    Theme(
        name: "Fahrenheit",
        syntax: SyntaxColors(
            text: "#ffffce",
            background: "#000000",
            numbers: "#7f0e0e",
            operators: "#cda074",
            keywords: "#734c4d",
            functions: "#fecf75",
            constants: "#7f0e0e",
            variables: "#979797",
            variableUsage: "#734c4d",
            assignment: "#cda074",
            currency: "#9e744d",
            units: "#979797",
            results: "#9e744d",
            comments: "#404040"
        )
    ),
    Theme(
        name: "Fairyfloss",
        syntax: SyntaxColors(
            text: "#f8f8f2",
            background: "#5a5475",
            numbers: "#c2ffdf",
            operators: "#f92672",
            keywords: "#ffb8d1",
            functions: "#e6c000",
            constants: "#c2ffdf",
            variables: "#c5a3ff",
            variableUsage: "#ffb8d1",
            assignment: "#f92672",
            currency: "#c2ffdf",
            units: "#c5a3ff",
            results: "#c2ffdf",
            comments: "#6090cb"
        )
    ),
    Theme(
        name: "Farmhouse Dark",
        syntax: SyntaxColors(
            text: "#e8e4e1",
            background: "#1d2027",
            numbers: "#0049e6",
            operators: "#ba0004",
            keywords: "#9f1b61",
            functions: "#c87300",
            constants: "#0049e6",
            variables: "#1fb65c",
            variableUsage: "#9f1b61",
            assignment: "#ba0004",
            currency: "#549d00",
            units: "#1fb65c",
            results: "#549d00",
            comments: "#464d54"
        )
    ),
    Theme(
        name: "Farmhouse Light",
        syntax: SyntaxColors(
            text: "#1d2027",
            background: "#e8e4e1",
            numbers: "#092ccd",
            operators: "#8d0003",
            keywords: "#820046",
            functions: "#a95600",
            constants: "#092ccd",
            variables: "#229256",
            variableUsage: "#820046",
            assignment: "#8d0003",
            currency: "#3a7d00",
            units: "#229256",
            results: "#3a7d00",
            comments: "#394047"
        )
    ),
    Theme(
        name: "Fideloper",
        syntax: SyntaxColors(
            text: "#dbdae0",
            background: "#292f33",
            numbers: "#2e78c2",
            operators: "#cb1e2d",
            keywords: "#c0236f",
            functions: "#b7ab9b",
            constants: "#2e78c2",
            variables: "#309186",
            variableUsage: "#c0236f",
            assignment: "#cb1e2d",
            currency: "#edb8ac",
            units: "#309186",
            results: "#edb8ac",
            comments: "#496068"
        )
    ),
    Theme(
        name: "Firefly Traditional",
        syntax: SyntaxColors(
            text: "#f5f5f5",
            background: "#000000",
            numbers: "#5a63ff",
            operators: "#c23720",
            keywords: "#d53ad2",
            functions: "#afad24",
            constants: "#5a63ff",
            variables: "#33bbc7",
            variableUsage: "#d53ad2",
            assignment: "#c23720",
            currency: "#33bc26",
            units: "#33bbc7",
            results: "#33bc26",
            comments: "#828282"
        )
    ),
    Theme(
        name: "Firefox Dev",
        syntax: SyntaxColors(
            text: "#7c8fa4",
            background: "#0e1011",
            numbers: "#359ddf",
            operators: "#e63853",
            keywords: "#d75cff",
            functions: "#a57706",
            constants: "#359ddf",
            variables: "#4b73a2",
            variableUsage: "#d75cff",
            assignment: "#e63853",
            currency: "#5eb83c",
            units: "#4b73a2",
            results: "#5eb83c",
            comments: "#26444d"
        )
    ),
    Theme(
        name: "Firewatch",
        syntax: SyntaxColors(
            text: "#9ba2b2",
            background: "#1e2027",
            numbers: "#4d89c4",
            operators: "#d95360",
            keywords: "#d55119",
            functions: "#dfb563",
            constants: "#4d89c4",
            variables: "#44a8b6",
            variableUsage: "#d55119",
            assignment: "#d95360",
            currency: "#5ab977",
            units: "#44a8b6",
            results: "#5ab977",
            comments: "#585f6d"
        )
    ),
    Theme(
        name: "Fish Tank",
        syntax: SyntaxColors(
            text: "#ecf0fe",
            background: "#232537",
            numbers: "#525fb8",
            operators: "#c6004a",
            keywords: "#986f82",
            functions: "#fecd5e",
            constants: "#525fb8",
            variables: "#968763",
            variableUsage: "#986f82",
            assignment: "#c6004a",
            currency: "#acf157",
            units: "#968763",
            results: "#acf157",
            comments: "#6c5b30"
        )
    ),
    Theme(
        name: "Flat",
        syntax: SyntaxColors(
            text: "#2cc55d",
            background: "#002240",
            numbers: "#3167ac",
            operators: "#a82320",
            keywords: "#781aa0",
            functions: "#e58d11",
            constants: "#3167ac",
            variables: "#2c9370",
            variableUsage: "#781aa0",
            assignment: "#a82320",
            currency: "#32a548",
            units: "#2c9370",
            results: "#32a548",
            comments: "#475262"
        )
    ),
    Theme(
        name: "Flatland",
        syntax: SyntaxColors(
            text: "#b8dbef",
            background: "#1d1f21",
            numbers: "#5096be",
            operators: "#f18339",
            keywords: "#695abc",
            functions: "#f4ef6d",
            constants: "#5096be",
            variables: "#d63865",
            variableUsage: "#695abc",
            assignment: "#f18339",
            currency: "#9fd364",
            units: "#d63865",
            results: "#9fd364",
            comments: "#50504c"
        )
    ),
    Theme(
        name: "Flexoki Dark",
        syntax: SyntaxColors(
            text: "#cecdc3",
            background: "#100f0f",
            numbers: "#4385be",
            operators: "#d14d41",
            keywords: "#ce5d97",
            functions: "#d0a215",
            constants: "#4385be",
            variables: "#3aa99f",
            variableUsage: "#ce5d97",
            assignment: "#d14d41",
            currency: "#879a39",
            units: "#3aa99f",
            results: "#879a39",
            comments: "#575653"
        )
    ),
    Theme(
        name: "Flexoki Light",
        syntax: SyntaxColors(
            text: "#100f0f",
            background: "#fffcf0",
            numbers: "#205ea6",
            operators: "#af3029",
            keywords: "#a02f6f",
            functions: "#ad8301",
            constants: "#205ea6",
            variables: "#24837b",
            variableUsage: "#a02f6f",
            assignment: "#af3029",
            currency: "#66800b",
            units: "#24837b",
            results: "#66800b",
            comments: "#b7b5ac"
        )
    ),
    Theme(
        name: "Floraverse",
        syntax: SyntaxColors(
            text: "#dbd1b9",
            background: "#0e0d15",
            numbers: "#1d6da1",
            operators: "#7e1a46",
            keywords: "#b7077e",
            functions: "#cd751c",
            constants: "#1d6da1",
            variables: "#42a38c",
            variableUsage: "#b7077e",
            assignment: "#7e1a46",
            currency: "#5d731a",
            units: "#42a38c",
            results: "#5d731a",
            comments: "#4c3866"
        )
    ),
    Theme(
        name: "Forest Blue",
        syntax: SyntaxColors(
            text: "#e2d8cd",
            background: "#051519",
            numbers: "#8ed0ce",
            operators: "#f8818e",
            keywords: "#5e468c",
            functions: "#1a8e63",
            constants: "#8ed0ce",
            variables: "#31658c",
            variableUsage: "#5e468c",
            assignment: "#f8818e",
            currency: "#92d3a2",
            units: "#31658c",
            results: "#92d3a2",
            comments: "#4a4a4a"
        )
    ),
    Theme(
        name: "Framer",
        syntax: SyntaxColors(
            text: "#777777",
            background: "#111111",
            numbers: "#00aaff",
            operators: "#ff5555",
            keywords: "#aa88ff",
            functions: "#ffcc33",
            constants: "#00aaff",
            variables: "#88ddff",
            variableUsage: "#aa88ff",
            assignment: "#ff5555",
            currency: "#98ec65",
            units: "#88ddff",
            results: "#98ec65",
            comments: "#414141"
        )
    ),
    Theme(
        name: "Front End Delight",
        syntax: SyntaxColors(
            text: "#adadad",
            background: "#1b1c1d",
            numbers: "#2c70b7",
            operators: "#f8511b",
            keywords: "#f02e4f",
            functions: "#fa771d",
            constants: "#2c70b7",
            variables: "#3ca1a6",
            variableUsage: "#f02e4f",
            assignment: "#f8511b",
            currency: "#565747",
            units: "#3ca1a6",
            results: "#565747",
            comments: "#5fac6d"
        )
    ),
    Theme(
        name: "Fun Forrest",
        syntax: SyntaxColors(
            text: "#dec165",
            background: "#251200",
            numbers: "#4699a3",
            operators: "#d6262b",
            keywords: "#8d4331",
            functions: "#be8a13",
            constants: "#4699a3",
            variables: "#da8213",
            variableUsage: "#8d4331",
            assignment: "#d6262b",
            currency: "#919c00",
            units: "#da8213",
            results: "#919c00",
            comments: "#7f6a55"
        )
    ),
    Theme(
        name: "Galaxy",
        syntax: SyntaxColors(
            text: "#ffffff",
            background: "#1d2837",
            numbers: "#589df6",
            operators: "#f9555f",
            keywords: "#944d95",
            functions: "#fef02a",
            constants: "#589df6",
            variables: "#1f9ee7",
            variableUsage: "#944d95",
            assignment: "#f9555f",
            currency: "#21b089",
            units: "#1f9ee7",
            results: "#21b089",
            comments: "#555555"
        )
    ),
    Theme(
        name: "Galizur",
        syntax: SyntaxColors(
            text: "#ddeeff",
            background: "#071317",
            numbers: "#2255cc",
            operators: "#aa1122",
            keywords: "#7755aa",
            functions: "#ccaa22",
            constants: "#2255cc",
            variables: "#22bbdd",
            variableUsage: "#7755aa",
            assignment: "#aa1122",
            currency: "#33aa11",
            units: "#22bbdd",
            results: "#33aa11",
            comments: "#556677"
        )
    ),
    Theme(
        name: "Default Dark Style",
        syntax: SyntaxColors(
            text: "#ffffff",
            background: "#282c34",
            numbers: "#82a2be",
            operators: "#cc6566",
            keywords: "#b294bb",
            functions: "#f0c674",
            constants: "#82a2be",
            variables: "#8abeb7",
            variableUsage: "#b294bb",
            assignment: "#cc6566",
            currency: "#b6bd68",
            units: "#8abeb7",
            results: "#b6bd68",
            comments: "#666666"
        )
    ),
    Theme(
        name: "GitHub",
        syntax: SyntaxColors(
            text: "#3e3e3e",
            background: "#f4f4f4",
            numbers: "#003e8a",
            operators: "#970b16",
            keywords: "#e94691",
            functions: "#c5bb94",
            constants: "#003e8a",
            variables: "#7cc4df",
            variableUsage: "#e94691",
            assignment: "#970b16",
            currency: "#07962a",
            units: "#7cc4df",
            results: "#07962a",
            comments: "#666666"
        )
    ),
    Theme(
        name: "GitHub Dark",
        syntax: SyntaxColors(
            text: "#8b949e",
            background: "#101216",
            numbers: "#6ca4f8",
            operators: "#f78166",
            keywords: "#db61a2",
            functions: "#e3b341",
            constants: "#6ca4f8",
            variables: "#2b7489",
            variableUsage: "#db61a2",
            assignment: "#f78166",
            currency: "#56d364",
            units: "#2b7489",
            results: "#56d364",
            comments: "#4d4d4d"
        )
    ),
    Theme(
        name: "GitHub Dark Colorblind",
        syntax: SyntaxColors(
            text: "#c9d1d9",
            background: "#0d1117",
            numbers: "#58a6ff",
            operators: "#ec8e2c",
            keywords: "#bc8cff",
            functions: "#d29922",
            constants: "#58a6ff",
            variables: "#39c5cf",
            variableUsage: "#bc8cff",
            assignment: "#ec8e2c",
            currency: "#58a6ff",
            units: "#39c5cf",
            results: "#58a6ff",
            comments: "#6e7681"
        )
    ),
    Theme(
        name: "GitHub Dark Default",
        syntax: SyntaxColors(
            text: "#e6edf3",
            background: "#0d1117",
            numbers: "#58a6ff",
            operators: "#ff7b72",
            keywords: "#bc8cff",
            functions: "#d29922",
            constants: "#58a6ff",
            variables: "#39c5cf",
            variableUsage: "#bc8cff",
            assignment: "#ff7b72",
            currency: "#3fb950",
            units: "#39c5cf",
            results: "#3fb950",
            comments: "#6e7681"
        )
    ),
    Theme(
        name: "GitHub Dark Dimmed",
        syntax: SyntaxColors(
            text: "#adbac7",
            background: "#22272e",
            numbers: "#539bf5",
            operators: "#f47067",
            keywords: "#b083f0",
            functions: "#c69026",
            constants: "#539bf5",
            variables: "#39c5cf",
            variableUsage: "#b083f0",
            assignment: "#f47067",
            currency: "#57ab5a",
            units: "#39c5cf",
            results: "#57ab5a",
            comments: "#636e7b"
        )
    ),
    Theme(
        name: "GitHub Dark High Contrast",
        syntax: SyntaxColors(
            text: "#f0f3f6",
            background: "#0a0c10",
            numbers: "#71b7ff",
            operators: "#ff9492",
            keywords: "#cb9eff",
            functions: "#f0b72f",
            constants: "#71b7ff",
            variables: "#39c5cf",
            variableUsage: "#cb9eff",
            assignment: "#ff9492",
            currency: "#26cd4d",
            units: "#39c5cf",
            results: "#26cd4d",
            comments: "#9ea7b3"
        )
    ),
    Theme(
        name: "GitHub Light Colorblind",
        syntax: SyntaxColors(
            text: "#24292f",
            background: "#ffffff",
            numbers: "#0969da",
            operators: "#b35900",
            keywords: "#8250df",
            functions: "#4d2d00",
            constants: "#0969da",
            variables: "#1b7c83",
            variableUsage: "#8250df",
            assignment: "#b35900",
            currency: "#0550ae",
            units: "#1b7c83",
            results: "#0550ae",
            comments: "#57606a"
        )
    ),
    Theme(
        name: "GitHub Light Default",
        syntax: SyntaxColors(
            text: "#1f2328",
            background: "#ffffff",
            numbers: "#0969da",
            operators: "#cf222e",
            keywords: "#8250df",
            functions: "#4d2d00",
            constants: "#0969da",
            variables: "#1b7c83",
            variableUsage: "#8250df",
            assignment: "#cf222e",
            currency: "#116329",
            units: "#1b7c83",
            results: "#116329",
            comments: "#57606a"
        )
    ),
    Theme(
        name: "GitHub Light High Contrast",
        syntax: SyntaxColors(
            text: "#0e1116",
            background: "#ffffff",
            numbers: "#0349b4",
            operators: "#a0111f",
            keywords: "#622cbc",
            functions: "#3f2200",
            constants: "#0349b4",
            variables: "#1b7c83",
            variableUsage: "#622cbc",
            assignment: "#a0111f",
            currency: "#024c1a",
            units: "#1b7c83",
            results: "#024c1a",
            comments: "#4b535d"
        )
    ),
    Theme(
        name: "GitLab Dark",
        syntax: SyntaxColors(
            text: "#ffffff",
            background: "#28262b",
            numbers: "#7fb6ed",
            operators: "#f57f6c",
            keywords: "#f88aaf",
            functions: "#d99530",
            constants: "#7fb6ed",
            variables: "#32c5d2",
            variableUsage: "#f88aaf",
            assignment: "#f57f6c",
            currency: "#52b87a",
            units: "#32c5d2",
            results: "#52b87a",
            comments: "#666666"
        )
    ),
    Theme(
        name: "GitLab Dark Grey",
        syntax: SyntaxColors(
            text: "#ffffff",
            background: "#222222",
            numbers: "#7fb6ed",
            operators: "#f57f6c",
            keywords: "#f88aaf",
            functions: "#d99530",
            constants: "#7fb6ed",
            variables: "#32c5d2",
            variableUsage: "#f88aaf",
            assignment: "#f57f6c",
            currency: "#52b87a",
            units: "#32c5d2",
            results: "#52b87a",
            comments: "#666666"
        )
    ),
    Theme(
        name: "GitLab Light",
        syntax: SyntaxColors(
            text: "#303030",
            background: "#fafaff",
            numbers: "#006cd8",
            operators: "#a31700",
            keywords: "#583cac",
            functions: "#af551d",
            constants: "#006cd8",
            variables: "#00798a",
            variableUsage: "#583cac",
            assignment: "#a31700",
            currency: "#0a7f3d",
            units: "#00798a",
            results: "#0a7f3d",
            comments: "#303030"
        )
    ),
    Theme(
        name: "Glacier",
        syntax: SyntaxColors(
            text: "#ffffff",
            background: "#0c1115",
            numbers: "#1f5872",
            operators: "#bd0f2f",
            keywords: "#bd2523",
            functions: "#fb9435",
            constants: "#1f5872",
            variables: "#778397",
            variableUsage: "#bd2523",
            assignment: "#bd0f2f",
            currency: "#35a770",
            units: "#778397",
            results: "#35a770",
            comments: "#404a55"
        )
    ),
    Theme(
        name: "Grape",
        syntax: SyntaxColors(
            text: "#9f9fa1",
            background: "#171423",
            numbers: "#487df4",
            operators: "#ed2261",
            keywords: "#8d35c9",
            functions: "#8ddc20",
            constants: "#487df4",
            variables: "#3bdeed",
            variableUsage: "#8d35c9",
            assignment: "#ed2261",
            currency: "#1fa91b",
            units: "#3bdeed",
            results: "#1fa91b",
            comments: "#59516a"
        )
    ),
    Theme(
        name: "Grass",
        syntax: SyntaxColors(
            text: "#fff0a5",
            background: "#13773d",
            numbers: "#0000a3",
            operators: "#ff5959",
            keywords: "#ee59bb",
            functions: "#e7b000",
            constants: "#0000a3",
            variables: "#00bbbb",
            variableUsage: "#ee59bb",
            assignment: "#ff5959",
            currency: "#00bb00",
            units: "#00bbbb",
            results: "#00bb00",
            comments: "#959595"
        )
    ),
    Theme(
        name: "Grey Green",
        syntax: SyntaxColors(
            text: "#ffffff",
            background: "#002a1a",
            numbers: "#00deff",
            operators: "#fe1414",
            keywords: "#ff00f0",
            functions: "#f1ff01",
            constants: "#00deff",
            variables: "#00ffbc",
            variableUsage: "#ff00f0",
            assignment: "#fe1414",
            currency: "#74ff00",
            units: "#00ffbc",
            results: "#74ff00",
            comments: "#666666"
        )
    ),
    Theme(
        name: "Gruber Darker",
        syntax: SyntaxColors(
            text: "#e4e4e4",
            background: "#181818",
            numbers: "#92a7cb",
            operators: "#ff0a36",
            keywords: "#a095cb",
            functions: "#ffdb00",
            constants: "#92a7cb",
            variables: "#90aa9e",
            variableUsage: "#a095cb",
            assignment: "#ff0a36",
            currency: "#42dc00",
            units: "#90aa9e",
            results: "#42dc00",
            comments: "#54494e"
        )
    ),
    Theme(
        name: "Gruvbox Dark",
        syntax: SyntaxColors(
            text: "#ebdbb2",
            background: "#282828",
            numbers: "#458588",
            operators: "#cc241d",
            keywords: "#b16286",
            functions: "#d79921",
            constants: "#458588",
            variables: "#689d6a",
            variableUsage: "#b16286",
            assignment: "#cc241d",
            currency: "#98971a",
            units: "#689d6a",
            results: "#98971a",
            comments: "#928374"
        )
    ),
    Theme(
        name: "Gruvbox Dark Hard",
        syntax: SyntaxColors(
            text: "#ebdbb2",
            background: "#1d2021",
            numbers: "#458588",
            operators: "#cc241d",
            keywords: "#b16286",
            functions: "#d79921",
            constants: "#458588",
            variables: "#689d6a",
            variableUsage: "#b16286",
            assignment: "#cc241d",
            currency: "#98971a",
            units: "#689d6a",
            results: "#98971a",
            comments: "#928374"
        )
    ),
    Theme(
        name: "Gruvbox Light",
        syntax: SyntaxColors(
            text: "#3c3836",
            background: "#fbf1c7",
            numbers: "#458588",
            operators: "#cc241d",
            keywords: "#b16286",
            functions: "#d79921",
            constants: "#458588",
            variables: "#689d6a",
            variableUsage: "#b16286",
            assignment: "#cc241d",
            currency: "#98971a",
            units: "#689d6a",
            results: "#98971a",
            comments: "#928374"
        )
    ),
    Theme(
        name: "Gruvbox Light Hard",
        syntax: SyntaxColors(
            text: "#3c3836",
            background: "#f9f5d7",
            numbers: "#458588",
            operators: "#cc241d",
            keywords: "#b16286",
            functions: "#d79921",
            constants: "#458588",
            variables: "#689d6a",
            variableUsage: "#b16286",
            assignment: "#cc241d",
            currency: "#98971a",
            units: "#689d6a",
            results: "#98971a",
            comments: "#928374"
        )
    ),
    Theme(
        name: "Gruvbox Material",
        syntax: SyntaxColors(
            text: "#d4be98",
            background: "#1d2021",
            numbers: "#6da3ec",
            operators: "#ea6926",
            keywords: "#fd9bc1",
            functions: "#eecf75",
            constants: "#6da3ec",
            variables: "#fe9d6e",
            variableUsage: "#fd9bc1",
            assignment: "#ea6926",
            currency: "#c1d041",
            units: "#fe9d6e",
            results: "#c1d041",
            comments: "#4c4c4c"
        )
    ),
    Theme(
        name: "Gruvbox Material Dark",
        syntax: SyntaxColors(
            text: "#d4be98",
            background: "#282828",
            numbers: "#7daea3",
            operators: "#ea6962",
            keywords: "#d3869b",
            functions: "#d8a657",
            constants: "#7daea3",
            variables: "#89b482",
            variableUsage: "#d3869b",
            assignment: "#ea6962",
            currency: "#a9b665",
            units: "#89b482",
            results: "#a9b665",
            comments: "#7c6f64"
        )
    ),
    Theme(
        name: "Gruvbox Material Light",
        syntax: SyntaxColors(
            text: "#654735",
            background: "#fbf1c7",
            numbers: "#45707a",
            operators: "#c14a4a",
            keywords: "#945e80",
            functions: "#b47109",
            constants: "#45707a",
            variables: "#4c7a5d",
            variableUsage: "#945e80",
            assignment: "#c14a4a",
            currency: "#6c782e",
            units: "#4c7a5d",
            results: "#6c782e",
            comments: "#a89984"
        )
    ),
    Theme(
        name: "Guezwhoz",
        syntax: SyntaxColors(
            text: "#d9d9d9",
            background: "#1d1d1d",
            numbers: "#5aa0d6",
            operators: "#e85181",
            keywords: "#9a90e0",
            functions: "#b7d074",
            constants: "#5aa0d6",
            variables: "#58d6ce",
            variableUsage: "#9a90e0",
            assignment: "#e85181",
            currency: "#7ad694",
            units: "#58d6ce",
            results: "#7ad694",
            comments: "#808080"
        )
    ),
    Theme(
        name: "HaX0R Blue",
        syntax: SyntaxColors(
            text: "#11b7ff",
            background: "#010515",
            numbers: "#10b6ff",
            operators: "#10b6ff",
            keywords: "#10b6ff",
            functions: "#10b6ff",
            constants: "#10b6ff",
            variables: "#10b6ff",
            variableUsage: "#10b6ff",
            assignment: "#10b6ff",
            currency: "#10b6ff",
            units: "#10b6ff",
            results: "#10b6ff",
            comments: "#484157"
        )
    ),
    Theme(
        name: "HaX0R Gr33N",
        syntax: SyntaxColors(
            text: "#16b10e",
            background: "#020f01",
            numbers: "#15d00d",
            operators: "#15d00d",
            keywords: "#15d00d",
            functions: "#15d00d",
            constants: "#15d00d",
            variables: "#15d00d",
            variableUsage: "#15d00d",
            assignment: "#15d00d",
            currency: "#15d00d",
            units: "#15d00d",
            results: "#15d00d",
            comments: "#334843"
        )
    ),
    Theme(
        name: "HaX0R R3D",
        syntax: SyntaxColors(
            text: "#b10e0e",
            background: "#200101",
            numbers: "#b00d0d",
            operators: "#b00d0d",
            keywords: "#b00d0d",
            functions: "#b00d0d",
            constants: "#b00d0d",
            variables: "#b00d0d",
            variableUsage: "#b00d0d",
            assignment: "#b00d0d",
            currency: "#b00d0d",
            units: "#b00d0d",
            results: "#b00d0d",
            comments: "#554040"
        )
    ),
    Theme(
        name: "Hacktober",
        syntax: SyntaxColors(
            text: "#c9c9c9",
            background: "#141414",
            numbers: "#206ec5",
            operators: "#b34538",
            keywords: "#864651",
            functions: "#d08949",
            constants: "#206ec5",
            variables: "#ac9166",
            variableUsage: "#864651",
            assignment: "#b34538",
            currency: "#587744",
            units: "#ac9166",
            results: "#587744",
            comments: "#464444"
        )
    ),
    Theme(
        name: "Hardcore",
        syntax: SyntaxColors(
            text: "#a0a0a0",
            background: "#121212",
            numbers: "#66d9ef",
            operators: "#f92672",
            keywords: "#9e6ffe",
            functions: "#fd971f",
            constants: "#66d9ef",
            variables: "#5e7175",
            variableUsage: "#9e6ffe",
            assignment: "#f92672",
            currency: "#a6e22e",
            units: "#5e7175",
            results: "#a6e22e",
            comments: "#505354"
        )
    ),
    Theme(
        name: "Harper",
        syntax: SyntaxColors(
            text: "#a8a49d",
            background: "#010101",
            numbers: "#489e48",
            operators: "#f8b63f",
            keywords: "#b296c6",
            functions: "#d6da25",
            constants: "#489e48",
            variables: "#f5bfd7",
            variableUsage: "#b296c6",
            assignment: "#f8b63f",
            currency: "#7fb5e1",
            units: "#f5bfd7",
            results: "#7fb5e1",
            comments: "#726e6a"
        )
    ),
    Theme(
        name: "Havn Daggry",
        syntax: SyntaxColors(
            text: "#3b4a7a",
            background: "#f8f9fb",
            numbers: "#3a577d",
            operators: "#985248",
            keywords: "#7c5c97",
            functions: "#be6b00",
            constants: "#3a577d",
            variables: "#925780",
            variableUsage: "#7c5c97",
            assignment: "#985248",
            currency: "#577159",
            units: "#925780",
            results: "#577159",
            comments: "#1f2842"
        )
    ),
    Theme(
        name: "Havn Skumring",
        syntax: SyntaxColors(
            text: "#d6dbeb",
            background: "#111522",
            numbers: "#596cf7",
            operators: "#ea563e",
            keywords: "#7c719e",
            functions: "#f8b330",
            constants: "#596cf7",
            variables: "#d588c1",
            variableUsage: "#7c719e",
            assignment: "#ea563e",
            currency: "#6ead7b",
            units: "#d588c1",
            results: "#6ead7b",
            comments: "#36425e"
        )
    ),
    Theme(
        name: "Heeler",
        syntax: SyntaxColors(
            text: "#fdfdfd",
            background: "#211f46",
            numbers: "#5ba5f2",
            operators: "#e44c2e",
            keywords: "#ff95c2",
            functions: "#f4ce65",
            constants: "#5ba5f2",
            variables: "#ff9763",
            variableUsage: "#ff95c2",
            assignment: "#e44c2e",
            currency: "#bdd100",
            units: "#ff9763",
            results: "#bdd100",
            comments: "#4d4c4c"
        )
    ),
    Theme(
        name: "Highway",
        syntax: SyntaxColors(
            text: "#ededed",
            background: "#222225",
            numbers: "#006bb3",
            operators: "#d00e18",
            keywords: "#773482",
            functions: "#ffcb3e",
            constants: "#006bb3",
            variables: "#455271",
            variableUsage: "#773482",
            assignment: "#d00e18",
            currency: "#138034",
            units: "#455271",
            results: "#138034",
            comments: "#5d504a"
        )
    ),
    Theme(
        name: "Hipster Green",
        syntax: SyntaxColors(
            text: "#84c138",
            background: "#100b05",
            numbers: "#246eb2",
            operators: "#b6214a",
            keywords: "#b200b2",
            functions: "#bfbf00",
            constants: "#246eb2",
            variables: "#00a6b2",
            variableUsage: "#b200b2",
            assignment: "#b6214a",
            currency: "#00a600",
            units: "#00a6b2",
            results: "#00a600",
            comments: "#666666"
        )
    ),
    Theme(
        name: "Hivacruz",
        syntax: SyntaxColors(
            text: "#ede4e4",
            background: "#132638",
            numbers: "#3d8fd1",
            operators: "#c94922",
            keywords: "#6679cc",
            functions: "#c08b30",
            constants: "#3d8fd1",
            variables: "#22a2c9",
            variableUsage: "#6679cc",
            assignment: "#c94922",
            currency: "#ac9739",
            units: "#22a2c9",
            results: "#ac9739",
            comments: "#6b7394"
        )
    ),
    Theme(
        name: "Homebrew",
        syntax: SyntaxColors(
            text: "#00ff00",
            background: "#000000",
            numbers: "#0d0dbf",
            operators: "#990000",
            keywords: "#b200b2",
            functions: "#999900",
            constants: "#0d0dbf",
            variables: "#00a6b2",
            variableUsage: "#b200b2",
            assignment: "#990000",
            currency: "#00a600",
            units: "#00a6b2",
            results: "#00a600",
            comments: "#666666"
        )
    ),
    Theme(
        name: "Hopscotch",
        syntax: SyntaxColors(
            text: "#b9b5b8",
            background: "#322931",
            numbers: "#1290bf",
            operators: "#dd464c",
            keywords: "#c85e7c",
            functions: "#fdcc59",
            constants: "#1290bf",
            variables: "#149b93",
            variableUsage: "#c85e7c",
            assignment: "#dd464c",
            currency: "#8fc13e",
            units: "#149b93",
            results: "#8fc13e",
            comments: "#797379"
        )
    ),
    Theme(
        name: "Hopscotch.256",
        syntax: SyntaxColors(
            text: "#b9b5b8",
            background: "#322931",
            numbers: "#1290bf",
            operators: "#dd464c",
            keywords: "#c85e7c",
            functions: "#fdcc59",
            constants: "#1290bf",
            variables: "#149b93",
            variableUsage: "#c85e7c",
            assignment: "#dd464c",
            currency: "#8fc13e",
            units: "#149b93",
            results: "#8fc13e",
            comments: "#797379"
        )
    ),
    Theme(
        name: "Horizon",
        syntax: SyntaxColors(
            text: "#d5d8da",
            background: "#1c1e26",
            numbers: "#26bbd9",
            operators: "#e95678",
            keywords: "#ee64ac",
            functions: "#fab795",
            constants: "#26bbd9",
            variables: "#59e1e3",
            variableUsage: "#ee64ac",
            assignment: "#e95678",
            currency: "#29d398",
            units: "#59e1e3",
            results: "#29d398",
            comments: "#666666"
        )
    ),
    Theme(
        name: "Horizon Bright",
        syntax: SyntaxColors(
            text: "#16161d",
            background: "#fdf0ed",
            numbers: "#00bedd",
            operators: "#fc4777",
            keywords: "#ff58b1",
            functions: "#ffa27b",
            constants: "#00bedd",
            variables: "#00c8c1",
            variableUsage: "#ff58b1",
            assignment: "#fc4777",
            currency: "#00ce81",
            units: "#00c8c1",
            results: "#00ce81",
            comments: "#1a1c24"
        )
    ),
    Theme(
        name: "Hot Dog Stand",
        syntax: SyntaxColors(
            text: "#ffffff",
            background: "#ea3323",
            numbers: "#000000",
            operators: "#ffff54",
            keywords: "#ffff54",
            functions: "#ffff54",
            constants: "#000000",
            variables: "#ffffff",
            variableUsage: "#ffff54",
            assignment: "#ffff54",
            currency: "#ffff54",
            units: "#ffffff",
            results: "#ffff54",
            comments: "#000000"
        )
    ),
    Theme(
        name: "Hot Dog Stand (Mustard)",
        syntax: SyntaxColors(
            text: "#000000",
            background: "#ffff54",
            numbers: "#000000",
            operators: "#ea3323",
            keywords: "#ea3323",
            functions: "#ea3323",
            constants: "#000000",
            variables: "#000000",
            variableUsage: "#ea3323",
            assignment: "#ea3323",
            currency: "#ea3323",
            units: "#000000",
            results: "#ea3323",
            comments: "#000000"
        )
    ),
    Theme(
        name: "Hurtado",
        syntax: SyntaxColors(
            text: "#dbdbdb",
            background: "#000000",
            numbers: "#496487",
            operators: "#ff1b00",
            keywords: "#fd5ff1",
            functions: "#fbe74a",
            constants: "#496487",
            variables: "#86e9fe",
            variableUsage: "#fd5ff1",
            assignment: "#ff1b00",
            currency: "#a5e055",
            units: "#86e9fe",
            results: "#a5e055",
            comments: "#3f3f3f"
        )
    ),
    Theme(
        name: "Hybrid",
        syntax: SyntaxColors(
            text: "#b7bcba",
            background: "#161719",
            numbers: "#6e90b0",
            operators: "#b84d51",
            keywords: "#a17eac",
            functions: "#e4b55e",
            constants: "#6e90b0",
            variables: "#7fbfb4",
            variableUsage: "#a17eac",
            assignment: "#b84d51",
            currency: "#b3bf5a",
            units: "#7fbfb4",
            results: "#b3bf5a",
            comments: "#444548"
        )
    ),
    Theme(
        name: "IBM 5153 CGA",
        syntax: SyntaxColors(
            text: "#d6d6d6",
            background: "#262626",
            numbers: "#3333db",
            operators: "#db3333",
            keywords: "#db33db",
            functions: "#db9833",
            constants: "#3333db",
            variables: "#33dbdb",
            variableUsage: "#db33db",
            assignment: "#db3333",
            currency: "#33db33",
            units: "#33dbdb",
            results: "#33db33",
            comments: "#4e4e4e"
        )
    ),
    Theme(
        name: "IBM 5153 CGA (Black)",
        syntax: SyntaxColors(
            text: "#c4c4c4",
            background: "#000000",
            numbers: "#0000c4",
            operators: "#c40000",
            keywords: "#c400c4",
            functions: "#c47e00",
            constants: "#0000c4",
            variables: "#00c4c4",
            variableUsage: "#c400c4",
            assignment: "#c40000",
            currency: "#00c400",
            units: "#00c4c4",
            results: "#00c400",
            comments: "#4e4e4e"
        )
    ),
    Theme(
        name: "IC Green PPL",
        syntax: SyntaxColors(
            text: "#e0f1dc",
            background: "#2c2c2c",
            numbers: "#2ec3b9",
            operators: "#ff2736",
            keywords: "#50a096",
            functions: "#76a831",
            constants: "#2ec3b9",
            variables: "#3ca078",
            variableUsage: "#50a096",
            assignment: "#ff2736",
            currency: "#41a638",
            units: "#3ca078",
            results: "#41a638",
            comments: "#106910"
        )
    ),
    Theme(
        name: "IC Orange PPL",
        syntax: SyntaxColors(
            text: "#ffcb83",
            background: "#262626",
            numbers: "#bd6d00",
            operators: "#c13900",
            keywords: "#fc5e00",
            functions: "#caaf00",
            constants: "#bd6d00",
            variables: "#f79500",
            variableUsage: "#fc5e00",
            assignment: "#c13900",
            currency: "#a4a900",
            units: "#f79500",
            results: "#a4a900",
            comments: "#6a4f2a"
        )
    ),
    Theme(
        name: "IR Black",
        syntax: SyntaxColors(
            text: "#f1f1f1",
            background: "#000000",
            numbers: "#96cafe",
            operators: "#fa6c60",
            keywords: "#fa73fd",
            functions: "#fffeb7",
            constants: "#96cafe",
            variables: "#c6c5fe",
            variableUsage: "#fa73fd",
            assignment: "#fa6c60",
            currency: "#a8ff60",
            units: "#c6c5fe",
            results: "#a8ff60",
            comments: "#7b7b7b"
        )
    ),
    Theme(
        name: "IRIX Console",
        syntax: SyntaxColors(
            text: "#f2f2f2",
            background: "#0c0c0c",
            numbers: "#0739e2",
            operators: "#d42426",
            keywords: "#911f9c",
            functions: "#c29d28",
            constants: "#0739e2",
            variables: "#4497df",
            variableUsage: "#911f9c",
            assignment: "#d42426",
            currency: "#37a327",
            units: "#4497df",
            results: "#37a327",
            comments: "#767676"
        )
    ),
    Theme(
        name: "IRIX Terminal",
        syntax: SyntaxColors(
            text: "#f2f2f2",
            background: "#000043",
            numbers: "#0004ff",
            operators: "#ff2b1e",
            keywords: "#ff2cff",
            functions: "#ffff44",
            constants: "#0004ff",
            variables: "#56ffff",
            variableUsage: "#ff2cff",
            assignment: "#ff2b1e",
            currency: "#57ff3d",
            units: "#56ffff",
            results: "#57ff3d",
            comments: "#ffff44"
        )
    ),
    Theme(
        name: "Iceberg Dark",
        syntax: SyntaxColors(
            text: "#c6c8d1",
            background: "#161821",
            numbers: "#84a0c6",
            operators: "#e27878",
            keywords: "#a093c7",
            functions: "#e2a478",
            constants: "#84a0c6",
            variables: "#89b8c2",
            variableUsage: "#a093c7",
            assignment: "#e27878",
            currency: "#b4be82",
            units: "#89b8c2",
            results: "#b4be82",
            comments: "#6b7089"
        )
    ),
    Theme(
        name: "Iceberg Light",
        syntax: SyntaxColors(
            text: "#33374c",
            background: "#e8e9ec",
            numbers: "#2d539e",
            operators: "#cc517a",
            keywords: "#7759b4",
            functions: "#c57339",
            constants: "#2d539e",
            variables: "#3f83a6",
            variableUsage: "#7759b4",
            assignment: "#cc517a",
            currency: "#668e3d",
            units: "#3f83a6",
            results: "#668e3d",
            comments: "#8389a3"
        )
    ),
    Theme(
        name: "Idea",
        syntax: SyntaxColors(
            text: "#adadad",
            background: "#202020",
            numbers: "#437ee7",
            operators: "#fc5256",
            keywords: "#9d74b0",
            functions: "#ccb444",
            constants: "#437ee7",
            variables: "#248887",
            variableUsage: "#9d74b0",
            assignment: "#fc5256",
            currency: "#98b61c",
            units: "#248887",
            results: "#98b61c",
            comments: "#ffffff"
        )
    ),
    Theme(
        name: "Idle Toes",
        syntax: SyntaxColors(
            text: "#ffffff",
            background: "#323232",
            numbers: "#4099ff",
            operators: "#d25252",
            keywords: "#f680ff",
            functions: "#ffc66d",
            constants: "#4099ff",
            variables: "#bed6ff",
            variableUsage: "#f680ff",
            assignment: "#d25252",
            currency: "#7fe173",
            units: "#bed6ff",
            results: "#7fe173",
            comments: "#606060"
        )
    ),
    Theme(
        name: "Jackie Brown",
        syntax: SyntaxColors(
            text: "#ffcc2f",
            background: "#2c1d16",
            numbers: "#246eb2",
            operators: "#ef5734",
            keywords: "#d05ec1",
            functions: "#bebf00",
            constants: "#246eb2",
            variables: "#00acee",
            variableUsage: "#d05ec1",
            assignment: "#ef5734",
            currency: "#2baf2b",
            units: "#00acee",
            results: "#2baf2b",
            comments: "#666666"
        )
    ),
    Theme(
        name: "Japanesque",
        syntax: SyntaxColors(
            text: "#f7f6ec",
            background: "#1e1e1e",
            numbers: "#4c9ad4",
            operators: "#cf3f61",
            keywords: "#a57fc4",
            functions: "#e9b32a",
            constants: "#4c9ad4",
            variables: "#389aad",
            variableUsage: "#a57fc4",
            assignment: "#cf3f61",
            currency: "#7bb75b",
            units: "#389aad",
            results: "#7bb75b",
            comments: "#595b59"
        )
    ),
    Theme(
        name: "Jellybeans",
        syntax: SyntaxColors(
            text: "#dedede",
            background: "#121212",
            numbers: "#97bedc",
            operators: "#e27373",
            keywords: "#e1c0fa",
            functions: "#ffba7b",
            constants: "#97bedc",
            variables: "#00988e",
            variableUsage: "#e1c0fa",
            assignment: "#e27373",
            currency: "#94b979",
            units: "#00988e",
            results: "#94b979",
            comments: "#bdbdbd"
        )
    ),
    Theme(
        name: "JetBrains Darcula",
        syntax: SyntaxColors(
            text: "#adadad",
            background: "#202020",
            numbers: "#4581eb",
            operators: "#fa5355",
            keywords: "#fa54ff",
            functions: "#c2c300",
            constants: "#4581eb",
            variables: "#33c2c1",
            variableUsage: "#fa54ff",
            assignment: "#fa5355",
            currency: "#126e00",
            units: "#33c2c1",
            results: "#126e00",
            comments: "#555555"
        )
    ),
    Theme(
        name: "Jubi",
        syntax: SyntaxColors(
            text: "#c3d3de",
            background: "#262b33",
            numbers: "#576ea6",
            operators: "#cf7b98",
            keywords: "#bc4f68",
            functions: "#6ebfc0",
            constants: "#576ea6",
            variables: "#75a7d2",
            variableUsage: "#bc4f68",
            assignment: "#cf7b98",
            currency: "#90a94b",
            units: "#75a7d2",
            results: "#90a94b",
            comments: "#a874ce"
        )
    ),
    Theme(
        name: "Kanagawa Dragon",
        syntax: SyntaxColors(
            text: "#c8c093",
            background: "#181616",
            numbers: "#8ba4b0",
            operators: "#c4746e",
            keywords: "#a292a3",
            functions: "#c4b28a",
            constants: "#8ba4b0",
            variables: "#8ea4a2",
            variableUsage: "#a292a3",
            assignment: "#c4746e",
            currency: "#8a9a7b",
            units: "#8ea4a2",
            results: "#8a9a7b",
            comments: "#a6a69c"
        )
    ),
    Theme(
        name: "Kanagawa Wave",
        syntax: SyntaxColors(
            text: "#dcd7ba",
            background: "#1f1f28",
            numbers: "#7e9cd8",
            operators: "#c34043",
            keywords: "#957fb8",
            functions: "#c0a36e",
            constants: "#7e9cd8",
            variables: "#6a9589",
            variableUsage: "#957fb8",
            assignment: "#c34043",
            currency: "#76946a",
            units: "#6a9589",
            results: "#76946a",
            comments: "#727169"
        )
    ),
    Theme(
        name: "Kanagawabones",
        syntax: SyntaxColors(
            text: "#ddd8bb",
            background: "#1f1f28",
            numbers: "#7eb3c9",
            operators: "#e46a78",
            keywords: "#957fb8",
            functions: "#e5c283",
            constants: "#7eb3c9",
            variables: "#7eb3c9",
            variableUsage: "#957fb8",
            assignment: "#e46a78",
            currency: "#98bc6d",
            units: "#7eb3c9",
            results: "#98bc6d",
            comments: "#49495e"
        )
    ),
    Theme(
        name: "Kibble",
        syntax: SyntaxColors(
            text: "#f7f7f7",
            background: "#0e100a",
            numbers: "#3449d1",
            operators: "#c70031",
            keywords: "#8400ff",
            functions: "#d8e30e",
            constants: "#3449d1",
            variables: "#0798ab",
            variableUsage: "#8400ff",
            assignment: "#c70031",
            currency: "#29cf13",
            units: "#0798ab",
            results: "#29cf13",
            comments: "#5a5a5a"
        )
    ),
    Theme(
        name: "Kitty Default",
        syntax: SyntaxColors(
            text: "#dddddd",
            background: "#000000",
            numbers: "#0d73cc",
            operators: "#cc0403",
            keywords: "#cb1ed1",
            functions: "#cecb00",
            constants: "#0d73cc",
            variables: "#0dcdcd",
            variableUsage: "#cb1ed1",
            assignment: "#cc0403",
            currency: "#19cb00",
            units: "#0dcdcd",
            results: "#19cb00",
            comments: "#767676"
        )
    ),
    Theme(
        name: "Kitty Low Contrast",
        syntax: SyntaxColors(
            text: "#ffffff",
            background: "#333333",
            numbers: "#0d73cc",
            operators: "#cc0403",
            keywords: "#cb1ed1",
            functions: "#cecb00",
            constants: "#0d73cc",
            variables: "#0dcdcd",
            variableUsage: "#cb1ed1",
            assignment: "#cc0403",
            currency: "#19cb00",
            units: "#0dcdcd",
            results: "#19cb00",
            comments: "#767676"
        )
    ),
    Theme(
        name: "Kolorit",
        syntax: SyntaxColors(
            text: "#efecec",
            background: "#1d1a1e",
            numbers: "#5db4ee",
            operators: "#ff5b82",
            keywords: "#da6cda",
            functions: "#e8e562",
            constants: "#5db4ee",
            variables: "#57e9eb",
            variableUsage: "#da6cda",
            assignment: "#ff5b82",
            currency: "#47d7a1",
            units: "#57e9eb",
            results: "#47d7a1",
            comments: "#504d51"
        )
    ),
    Theme(
        name: "Konsolas",
        syntax: SyntaxColors(
            text: "#c8c1c1",
            background: "#060606",
            numbers: "#2323a5",
            operators: "#aa1717",
            keywords: "#ad1edc",
            functions: "#ebae1f",
            constants: "#2323a5",
            variables: "#42b0c8",
            variableUsage: "#ad1edc",
            assignment: "#aa1717",
            currency: "#18b218",
            units: "#42b0c8",
            results: "#18b218",
            comments: "#7b716e"
        )
    ),
    Theme(
        name: "Kurokula",
        syntax: SyntaxColors(
            text: "#e0cfc2",
            background: "#141515",
            numbers: "#5c91dd",
            operators: "#c35a52",
            keywords: "#8b79a6",
            functions: "#e1b917",
            constants: "#5c91dd",
            variables: "#867268",
            variableUsage: "#8b79a6",
            assignment: "#c35a52",
            currency: "#78b3a9",
            units: "#867268",
            results: "#78b3a9",
            comments: "#515151"
        )
    ),
    Theme(
        name: "Lab Fox",
        syntax: SyntaxColors(
            text: "#ffffff",
            background: "#2e2e2e",
            numbers: "#db3b21",
            operators: "#fc6d26",
            keywords: "#6b40a8",
            functions: "#fca121",
            constants: "#db3b21",
            variables: "#6e49cb",
            variableUsage: "#6b40a8",
            assignment: "#fc6d26",
            currency: "#3eb383",
            units: "#6e49cb",
            results: "#3eb383",
            comments: "#5f5f5f"
        )
    ),
    Theme(
        name: "Laser",
        syntax: SyntaxColors(
            text: "#f106e3",
            background: "#030d18",
            numbers: "#fed300",
            operators: "#ff8373",
            keywords: "#ff90fe",
            functions: "#09b4bd",
            constants: "#fed300",
            variables: "#d1d1fe",
            variableUsage: "#ff90fe",
            assignment: "#ff8373",
            currency: "#b4fb73",
            units: "#d1d1fe",
            results: "#b4fb73",
            comments: "#8f8f8f"
        )
    ),
    Theme(
        name: "Later This Evening",
        syntax: SyntaxColors(
            text: "#959595",
            background: "#222222",
            numbers: "#a0bad6",
            operators: "#d45a60",
            keywords: "#c092d6",
            functions: "#e5d289",
            constants: "#a0bad6",
            variables: "#91bfb7",
            variableUsage: "#c092d6",
            assignment: "#d45a60",
            currency: "#afba67",
            units: "#91bfb7",
            results: "#afba67",
            comments: "#515454"
        )
    ),
    Theme(
        name: "Lavandula",
        syntax: SyntaxColors(
            text: "#736e7d",
            background: "#050014",
            numbers: "#4f4a7f",
            operators: "#7d1625",
            keywords: "#5a3f7f",
            functions: "#7f6f49",
            constants: "#4f4a7f",
            variables: "#58777f",
            variableUsage: "#5a3f7f",
            assignment: "#7d1625",
            currency: "#337e6f",
            units: "#58777f",
            results: "#337e6f",
            comments: "#443a53"
        )
    ),
    Theme(
        name: "Light Owl",
        syntax: SyntaxColors(
            text: "#403f53",
            background: "#fbfbfb",
            numbers: "#288ed7",
            operators: "#de3d3b",
            keywords: "#d6438a",
            functions: "#e0af02",
            constants: "#288ed7",
            variables: "#2aa298",
            variableUsage: "#d6438a",
            assignment: "#de3d3b",
            currency: "#08916a",
            units: "#2aa298",
            results: "#08916a",
            comments: "#989fb1"
        )
    ),
    Theme(
        name: "Liquid Carbon",
        syntax: SyntaxColors(
            text: "#afc2c2",
            background: "#303030",
            numbers: "#0099cc",
            operators: "#ff3030",
            keywords: "#cc69c8",
            functions: "#ccac00",
            constants: "#0099cc",
            variables: "#7ac4cc",
            variableUsage: "#cc69c8",
            assignment: "#ff3030",
            currency: "#559a70",
            units: "#7ac4cc",
            results: "#559a70",
            comments: "#595959"
        )
    ),
    Theme(
        name: "Liquid Carbon Transparent",
        syntax: SyntaxColors(
            text: "#afc2c2",
            background: "#000000",
            numbers: "#0099cc",
            operators: "#ff3030",
            keywords: "#cc69c8",
            functions: "#ccac00",
            constants: "#0099cc",
            variables: "#7ac4cc",
            variableUsage: "#cc69c8",
            assignment: "#ff3030",
            currency: "#559a70",
            units: "#7ac4cc",
            results: "#559a70",
            comments: "#404040"
        )
    ),
    Theme(
        name: "Lovelace",
        syntax: SyntaxColors(
            text: "#fdfdfd",
            background: "#1d1f28",
            numbers: "#8897f4",
            operators: "#f37f97",
            keywords: "#c574dd",
            functions: "#f2a272",
            constants: "#8897f4",
            variables: "#79e6f3",
            variableUsage: "#c574dd",
            assignment: "#f37f97",
            currency: "#5adecd",
            units: "#79e6f3",
            results: "#5adecd",
            comments: "#4e5165"
        )
    ),
    Theme(
        name: "Man Page",
        syntax: SyntaxColors(
            text: "#000000",
            background: "#fef49c",
            numbers: "#0000b2",
            operators: "#cc0000",
            keywords: "#b200b2",
            functions: "#999900",
            constants: "#0000b2",
            variables: "#00a6b2",
            variableUsage: "#b200b2",
            assignment: "#cc0000",
            currency: "#00a600",
            units: "#00a6b2",
            results: "#00a600",
            comments: "#666666"
        )
    ),
    Theme(
        name: "Mariana",
        syntax: SyntaxColors(
            text: "#d8dee9",
            background: "#343d46",
            numbers: "#6699cc",
            operators: "#ec5f66",
            keywords: "#c695c6",
            functions: "#f9ae58",
            constants: "#6699cc",
            variables: "#5fb4b4",
            variableUsage: "#c695c6",
            assignment: "#ec5f66",
            currency: "#99c794",
            units: "#5fb4b4",
            results: "#99c794",
            comments: "#666666"
        )
    ),
    Theme(
        name: "Material",
        syntax: SyntaxColors(
            text: "#232322",
            background: "#eaeaea",
            numbers: "#134eb2",
            operators: "#b7141f",
            keywords: "#560088",
            functions: "#f6981e",
            constants: "#134eb2",
            variables: "#0e717c",
            variableUsage: "#560088",
            assignment: "#b7141f",
            currency: "#457b24",
            units: "#0e717c",
            results: "#457b24",
            comments: "#424242"
        )
    ),
    Theme(
        name: "Material Dark",
        syntax: SyntaxColors(
            text: "#e5e5e5",
            background: "#232322",
            numbers: "#134eb2",
            operators: "#b7141f",
            keywords: "#6f1aa1",
            functions: "#f6981e",
            constants: "#134eb2",
            variables: "#0e717c",
            variableUsage: "#6f1aa1",
            assignment: "#b7141f",
            currency: "#457b24",
            units: "#0e717c",
            results: "#457b24",
            comments: "#4f4f4f"
        )
    ),
    Theme(
        name: "Material Darker",
        syntax: SyntaxColors(
            text: "#eeffff",
            background: "#212121",
            numbers: "#82aaff",
            operators: "#ff5370",
            keywords: "#c792ea",
            functions: "#ffcb6b",
            constants: "#82aaff",
            variables: "#89ddff",
            variableUsage: "#c792ea",
            assignment: "#ff5370",
            currency: "#c3e88d",
            units: "#89ddff",
            results: "#c3e88d",
            comments: "#545454"
        )
    ),
    Theme(
        name: "Material Design Colors",
        syntax: SyntaxColors(
            text: "#e7ebed",
            background: "#1d262a",
            numbers: "#37b6ff",
            operators: "#fc3841",
            keywords: "#fc226e",
            functions: "#fed032",
            constants: "#37b6ff",
            variables: "#59ffd1",
            variableUsage: "#fc226e",
            assignment: "#fc3841",
            currency: "#5cf19e",
            units: "#59ffd1",
            results: "#5cf19e",
            comments: "#a1b0b8"
        )
    ),
    Theme(
        name: "Material Ocean",
        syntax: SyntaxColors(
            text: "#8f93a2",
            background: "#0f111a",
            numbers: "#82aaff",
            operators: "#ff5370",
            keywords: "#c792ea",
            functions: "#ffcb6b",
            constants: "#82aaff",
            variables: "#89ddff",
            variableUsage: "#c792ea",
            assignment: "#ff5370",
            currency: "#c3e88d",
            units: "#89ddff",
            results: "#c3e88d",
            comments: "#546e7a"
        )
    ),
    Theme(
        name: "Mathias",
        syntax: SyntaxColors(
            text: "#bbbbbb",
            background: "#000000",
            numbers: "#c48dff",
            operators: "#e52222",
            keywords: "#fa2573",
            functions: "#fc951e",
            constants: "#c48dff",
            variables: "#67d9f0",
            variableUsage: "#fa2573",
            assignment: "#e52222",
            currency: "#a6e32d",
            units: "#67d9f0",
            results: "#a6e32d",
            comments: "#555555"
        )
    ),
    Theme(
        name: "Matrix",
        syntax: SyntaxColors(
            text: "#426644",
            background: "#0f191c",
            numbers: "#3f5242",
            operators: "#23755a",
            keywords: "#409931",
            functions: "#ffd700",
            constants: "#3f5242",
            variables: "#50b45a",
            variableUsage: "#409931",
            assignment: "#23755a",
            currency: "#82d967",
            units: "#50b45a",
            results: "#82d967",
            comments: "#688060"
        )
    ),
    Theme(
        name: "Matte Black",
        syntax: SyntaxColors(
            text: "#bebebe",
            background: "#121212",
            numbers: "#e68e0d",
            operators: "#d35f5f",
            keywords: "#d35f5f",
            functions: "#b91c1c",
            constants: "#e68e0d",
            variables: "#bebebe",
            variableUsage: "#d35f5f",
            assignment: "#d35f5f",
            currency: "#ffc107",
            units: "#bebebe",
            results: "#ffc107",
            comments: "#8a8a8d"
        )
    ),
    Theme(
        name: "Medallion",
        syntax: SyntaxColors(
            text: "#cac296",
            background: "#1d1908",
            numbers: "#616bb0",
            operators: "#b64c00",
            keywords: "#8c5a90",
            functions: "#d3bd26",
            constants: "#616bb0",
            variables: "#916c25",
            variableUsage: "#8c5a90",
            assignment: "#b64c00",
            currency: "#7c8b16",
            units: "#916c25",
            results: "#7c8b16",
            comments: "#5e5219"
        )
    ),
    Theme(
        name: "Melange Dark",
        syntax: SyntaxColors(
            text: "#ece1d7",
            background: "#292522",
            numbers: "#7f91b2",
            operators: "#bd8183",
            keywords: "#b380b0",
            functions: "#e49b5d",
            constants: "#7f91b2",
            variables: "#7b9695",
            variableUsage: "#b380b0",
            assignment: "#bd8183",
            currency: "#78997a",
            units: "#7b9695",
            results: "#78997a",
            comments: "#867462"
        )
    ),
    Theme(
        name: "Melange Light",
        syntax: SyntaxColors(
            text: "#54433a",
            background: "#f1f1f1",
            numbers: "#7892bd",
            operators: "#c77b8b",
            keywords: "#be79bb",
            functions: "#bc5c00",
            constants: "#7892bd",
            variables: "#739797",
            variableUsage: "#be79bb",
            assignment: "#c77b8b",
            currency: "#6e9b72",
            units: "#739797",
            results: "#6e9b72",
            comments: "#a98a78"
        )
    ),
    Theme(
        name: "Mellifluous",
        syntax: SyntaxColors(
            text: "#dadada",
            background: "#1a1a1a",
            numbers: "#a8a1be",
            operators: "#d29393",
            keywords: "#b39fb0",
            functions: "#cbaa89",
            constants: "#a8a1be",
            variables: "#c0af8c",
            variableUsage: "#b39fb0",
            assignment: "#d29393",
            currency: "#b3b393",
            units: "#c0af8c",
            results: "#b3b393",
            comments: "#5b5b5b"
        )
    ),
    Theme(
        name: "Mellow",
        syntax: SyntaxColors(
            text: "#c9c7cd",
            background: "#161617",
            numbers: "#aca1cf",
            operators: "#f5a191",
            keywords: "#e29eca",
            functions: "#e6b99d",
            constants: "#aca1cf",
            variables: "#ea83a5",
            variableUsage: "#e29eca",
            assignment: "#f5a191",
            currency: "#90b99f",
            units: "#ea83a5",
            results: "#90b99f",
            comments: "#424246"
        )
    ),
    Theme(
        name: "Miasma",
        syntax: SyntaxColors(
            text: "#c2c2b0",
            background: "#222222",
            numbers: "#78824b",
            operators: "#685742",
            keywords: "#bb7744",
            functions: "#b36d43",
            constants: "#78824b",
            variables: "#c9a554",
            variableUsage: "#bb7744",
            assignment: "#685742",
            currency: "#5f875f",
            units: "#c9a554",
            results: "#5f875f",
            comments: "#666666"
        )
    ),
    Theme(
        name: "Midnight In Mojave",
        syntax: SyntaxColors(
            text: "#ffffff",
            background: "#1e1e1e",
            numbers: "#0a84ff",
            operators: "#ff453a",
            keywords: "#bf5af2",
            functions: "#ffd60a",
            constants: "#0a84ff",
            variables: "#5ac8fa",
            variableUsage: "#bf5af2",
            assignment: "#ff453a",
            currency: "#32d74b",
            units: "#5ac8fa",
            results: "#32d74b",
            comments: "#515151"
        )
    ),
    Theme(
        name: "Mirage",
        syntax: SyntaxColors(
            text: "#a6b2c0",
            background: "#1b2738",
            numbers: "#7fb5ff",
            operators: "#ff9999",
            keywords: "#ddb3ff",
            functions: "#ffd700",
            constants: "#7fb5ff",
            variables: "#21c7a8",
            variableUsage: "#ddb3ff",
            assignment: "#ff9999",
            currency: "#85cc95",
            units: "#21c7a8",
            results: "#85cc95",
            comments: "#575656"
        )
    ),
    Theme(
        name: "Misterioso",
        syntax: SyntaxColors(
            text: "#e1e1e0",
            background: "#2d3743",
            numbers: "#338f86",
            operators: "#ff4242",
            keywords: "#9414e6",
            functions: "#ffad29",
            constants: "#338f86",
            variables: "#23d7d7",
            variableUsage: "#9414e6",
            assignment: "#ff4242",
            currency: "#74af68",
            units: "#23d7d7",
            results: "#74af68",
            comments: "#626262"
        )
    ),
    Theme(
        name: "Molokai",
        syntax: SyntaxColors(
            text: "#bbbbbb",
            background: "#121212",
            numbers: "#1080d0",
            operators: "#fa2573",
            keywords: "#8700ff",
            functions: "#dfd460",
            constants: "#1080d0",
            variables: "#43a8d0",
            variableUsage: "#8700ff",
            assignment: "#fa2573",
            currency: "#98e123",
            units: "#43a8d0",
            results: "#98e123",
            comments: "#555555"
        )
    ),
    Theme(
        name: "Mona Lisa",
        syntax: SyntaxColors(
            text: "#f7d66a",
            background: "#120b0d",
            numbers: "#515c5d",
            operators: "#9b291c",
            keywords: "#9b1d29",
            functions: "#c36e28",
            constants: "#515c5d",
            variables: "#588056",
            variableUsage: "#9b1d29",
            assignment: "#9b291c",
            currency: "#636232",
            units: "#588056",
            results: "#636232",
            comments: "#874228"
        )
    ),
    Theme(
        name: "Monokai Classic",
        syntax: SyntaxColors(
            text: "#fdfff1",
            background: "#272822",
            numbers: "#fd971f",
            operators: "#f92672",
            keywords: "#ae81ff",
            functions: "#e6db74",
            constants: "#fd971f",
            variables: "#66d9ef",
            variableUsage: "#ae81ff",
            assignment: "#f92672",
            currency: "#a6e22e",
            units: "#66d9ef",
            results: "#a6e22e",
            comments: "#6e7066"
        )
    ),
    Theme(
        name: "Monokai Pro",
        syntax: SyntaxColors(
            text: "#fcfcfa",
            background: "#2d2a2e",
            numbers: "#fc9867",
            operators: "#ff6188",
            keywords: "#ab9df2",
            functions: "#ffd866",
            constants: "#fc9867",
            variables: "#78dce8",
            variableUsage: "#ab9df2",
            assignment: "#ff6188",
            currency: "#a9dc76",
            units: "#78dce8",
            results: "#a9dc76",
            comments: "#727072"
        )
    ),
    Theme(
        name: "Monokai Pro Light",
        syntax: SyntaxColors(
            text: "#29242a",
            background: "#faf4f2",
            numbers: "#e16032",
            operators: "#e14775",
            keywords: "#7058be",
            functions: "#cc7a0a",
            constants: "#e16032",
            variables: "#1c8ca8",
            variableUsage: "#7058be",
            assignment: "#e14775",
            currency: "#269d69",
            units: "#1c8ca8",
            results: "#269d69",
            comments: "#a59fa0"
        )
    ),
    Theme(
        name: "Monokai Pro Light Sun",
        syntax: SyntaxColors(
            text: "#2c232e",
            background: "#f8efe7",
            numbers: "#d4572b",
            operators: "#ce4770",
            keywords: "#6851a2",
            functions: "#b16803",
            constants: "#d4572b",
            variables: "#2473b6",
            variableUsage: "#6851a2",
            assignment: "#ce4770",
            currency: "#218871",
            units: "#2473b6",
            results: "#218871",
            comments: "#a59c9c"
        )
    ),
    Theme(
        name: "Monokai Pro Machine",
        syntax: SyntaxColors(
            text: "#f2fffc",
            background: "#273136",
            numbers: "#ffb270",
            operators: "#ff6d7e",
            keywords: "#baa0f8",
            functions: "#ffed72",
            constants: "#ffb270",
            variables: "#7cd5f1",
            variableUsage: "#baa0f8",
            assignment: "#ff6d7e",
            currency: "#a2e57b",
            units: "#7cd5f1",
            results: "#a2e57b",
            comments: "#6b7678"
        )
    ),
    Theme(
        name: "Monokai Pro Octagon",
        syntax: SyntaxColors(
            text: "#eaf2f1",
            background: "#282a3a",
            numbers: "#ff9b5e",
            operators: "#ff657a",
            keywords: "#c39ac9",
            functions: "#ffd76d",
            constants: "#ff9b5e",
            variables: "#9cd1bb",
            variableUsage: "#c39ac9",
            assignment: "#ff657a",
            currency: "#bad761",
            units: "#9cd1bb",
            results: "#bad761",
            comments: "#696d77"
        )
    ),
    Theme(
        name: "Monokai Pro Ristretto",
        syntax: SyntaxColors(
            text: "#fff1f3",
            background: "#2c2525",
            numbers: "#f38d70",
            operators: "#fd6883",
            keywords: "#a8a9eb",
            functions: "#f9cc6c",
            constants: "#f38d70",
            variables: "#85dacc",
            variableUsage: "#a8a9eb",
            assignment: "#fd6883",
            currency: "#adda78",
            units: "#85dacc",
            results: "#adda78",
            comments: "#72696a"
        )
    ),
    Theme(
        name: "Monokai Pro Spectrum",
        syntax: SyntaxColors(
            text: "#f7f1ff",
            background: "#222222",
            numbers: "#fd9353",
            operators: "#fc618d",
            keywords: "#948ae3",
            functions: "#fce566",
            constants: "#fd9353",
            variables: "#5ad4e6",
            variableUsage: "#948ae3",
            assignment: "#fc618d",
            currency: "#7bd88f",
            units: "#5ad4e6",
            results: "#7bd88f",
            comments: "#69676c"
        )
    ),
    Theme(
        name: "Monokai Remastered",
        syntax: SyntaxColors(
            text: "#d9d9d9",
            background: "#0c0c0c",
            numbers: "#9d65ff",
            operators: "#f4005f",
            keywords: "#f4005f",
            functions: "#fd971f",
            constants: "#9d65ff",
            variables: "#58d1eb",
            variableUsage: "#f4005f",
            assignment: "#f4005f",
            currency: "#98e024",
            units: "#58d1eb",
            results: "#98e024",
            comments: "#625e4c"
        )
    ),
    Theme(
        name: "Monokai Soda",
        syntax: SyntaxColors(
            text: "#c4c5b5",
            background: "#1a1a1a",
            numbers: "#9d65ff",
            operators: "#f4005f",
            keywords: "#f4005f",
            functions: "#fa8419",
            constants: "#9d65ff",
            variables: "#58d1eb",
            variableUsage: "#f4005f",
            assignment: "#f4005f",
            currency: "#98e024",
            units: "#58d1eb",
            results: "#98e024",
            comments: "#625e4c"
        )
    ),
    Theme(
        name: "Monokai Vivid",
        syntax: SyntaxColors(
            text: "#f9f9f9",
            background: "#121212",
            numbers: "#0443ff",
            operators: "#fa2934",
            keywords: "#f800f8",
            functions: "#fff30a",
            constants: "#0443ff",
            variables: "#01b6ed",
            variableUsage: "#f800f8",
            assignment: "#fa2934",
            currency: "#98e123",
            units: "#01b6ed",
            results: "#98e123",
            comments: "#838383"
        )
    ),
    Theme(
        name: "Moonfly",
        syntax: SyntaxColors(
            text: "#bdbdbd",
            background: "#080808",
            numbers: "#80a0ff",
            operators: "#ff5454",
            keywords: "#cf87e8",
            functions: "#e3c78a",
            constants: "#80a0ff",
            variables: "#79dac8",
            variableUsage: "#cf87e8",
            assignment: "#ff5454",
            currency: "#8cc85f",
            units: "#79dac8",
            results: "#8cc85f",
            comments: "#949494"
        )
    ),
    Theme(
        name: "N0Tch2K",
        syntax: SyntaxColors(
            text: "#a0a0a0",
            background: "#222222",
            numbers: "#657d3e",
            operators: "#a95551",
            keywords: "#767676",
            functions: "#a98051",
            constants: "#657d3e",
            variables: "#c9c9c9",
            variableUsage: "#767676",
            assignment: "#a95551",
            currency: "#666666",
            units: "#c9c9c9",
            results: "#666666",
            comments: "#545454"
        )
    ),
    Theme(
        name: "Neobones Dark",
        syntax: SyntaxColors(
            text: "#c6d5cf",
            background: "#0f191f",
            numbers: "#8190d4",
            operators: "#de6e7c",
            keywords: "#b279a7",
            functions: "#b77e64",
            constants: "#8190d4",
            variables: "#66a5ad",
            variableUsage: "#b279a7",
            assignment: "#de6e7c",
            currency: "#90ff6b",
            units: "#66a5ad",
            results: "#90ff6b",
            comments: "#334652"
        )
    ),
    Theme(
        name: "Neobones Light",
        syntax: SyntaxColors(
            text: "#202e18",
            background: "#e5ede6",
            numbers: "#286486",
            operators: "#a8334c",
            keywords: "#88507d",
            functions: "#944927",
            constants: "#286486",
            variables: "#3b8992",
            variableUsage: "#88507d",
            assignment: "#a8334c",
            currency: "#567a30",
            units: "#3b8992",
            results: "#567a30",
            comments: "#99ac9c"
        )
    ),
    Theme(
        name: "Neon",
        syntax: SyntaxColors(
            text: "#00fffc",
            background: "#14161a",
            numbers: "#0f15d8",
            operators: "#ff3045",
            keywords: "#f924e7",
            functions: "#fffc7e",
            constants: "#0f15d8",
            variables: "#00fffc",
            variableUsage: "#f924e7",
            assignment: "#ff3045",
            currency: "#5ffa74",
            units: "#00fffc",
            results: "#5ffa74",
            comments: "#686868"
        )
    ),
    Theme(
        name: "Neopolitan",
        syntax: SyntaxColors(
            text: "#ffffff",
            background: "#271f19",
            numbers: "#324883",
            operators: "#9a1a1a",
            keywords: "#ff0080",
            functions: "#fbde2d",
            constants: "#324883",
            variables: "#8da6ce",
            variableUsage: "#ff0080",
            assignment: "#9a1a1a",
            currency: "#61ce3c",
            units: "#8da6ce",
            results: "#61ce3c",
            comments: "#4c4c4c"
        )
    ),
    Theme(
        name: "Neutron",
        syntax: SyntaxColors(
            text: "#e6e8ef",
            background: "#1c1e22",
            numbers: "#6a7c93",
            operators: "#b54036",
            keywords: "#a4799d",
            functions: "#deb566",
            constants: "#6a7c93",
            variables: "#3f94a8",
            variableUsage: "#a4799d",
            assignment: "#b54036",
            currency: "#5ab977",
            units: "#3f94a8",
            results: "#5ab977",
            comments: "#494c51"
        )
    ),
    Theme(
        name: "Night Lion V1",
        syntax: SyntaxColors(
            text: "#bbbbbb",
            background: "#000000",
            numbers: "#276bd8",
            operators: "#bb0000",
            keywords: "#bb00bb",
            functions: "#f3f167",
            constants: "#276bd8",
            variables: "#00dadf",
            variableUsage: "#bb00bb",
            assignment: "#bb0000",
            currency: "#5fde8f",
            units: "#00dadf",
            results: "#5fde8f",
            comments: "#555555"
        )
    ),
    Theme(
        name: "Night Lion V2",
        syntax: SyntaxColors(
            text: "#bbbbbb",
            background: "#171717",
            numbers: "#64d0f0",
            operators: "#bb0000",
            keywords: "#ce6fdb",
            functions: "#f3f167",
            constants: "#64d0f0",
            variables: "#00dadf",
            variableUsage: "#ce6fdb",
            assignment: "#bb0000",
            currency: "#04f623",
            units: "#00dadf",
            results: "#04f623",
            comments: "#555555"
        )
    ),
    Theme(
        name: "Night Owl",
        syntax: SyntaxColors(
            text: "#d6deeb",
            background: "#011627",
            numbers: "#82aaff",
            operators: "#ef5350",
            keywords: "#c792ea",
            functions: "#addb67",
            constants: "#82aaff",
            variables: "#21c7a8",
            variableUsage: "#c792ea",
            assignment: "#ef5350",
            currency: "#22da6e",
            units: "#21c7a8",
            results: "#22da6e",
            comments: "#575656"
        )
    ),
    Theme(
        name: "Night Owlish Light",
        syntax: SyntaxColors(
            text: "#403f53",
            background: "#ffffff",
            numbers: "#4876d6",
            operators: "#d3423e",
            keywords: "#403f53",
            functions: "#daaa01",
            constants: "#4876d6",
            variables: "#08916a",
            variableUsage: "#403f53",
            assignment: "#d3423e",
            currency: "#2aa298",
            units: "#08916a",
            results: "#2aa298",
            comments: "#7a8181"
        )
    ),
    Theme(
        name: "Nightfox",
        syntax: SyntaxColors(
            text: "#cdcecf",
            background: "#192330",
            numbers: "#719cd6",
            operators: "#c94f6d",
            keywords: "#9d79d6",
            functions: "#dbc074",
            constants: "#719cd6",
            variables: "#63cdcf",
            variableUsage: "#9d79d6",
            assignment: "#c94f6d",
            currency: "#81b29a",
            units: "#63cdcf",
            results: "#81b29a",
            comments: "#575860"
        )
    ),
    Theme(
        name: "Niji",
        syntax: SyntaxColors(
            text: "#ffffff",
            background: "#141515",
            numbers: "#2ab9ff",
            operators: "#d23e08",
            keywords: "#ff50da",
            functions: "#fff700",
            constants: "#2ab9ff",
            variables: "#1ef9f5",
            variableUsage: "#ff50da",
            assignment: "#d23e08",
            currency: "#54ca74",
            units: "#1ef9f5",
            results: "#54ca74",
            comments: "#515151"
        )
    ),
    Theme(
        name: "Nocturnal Winter",
        syntax: SyntaxColors(
            text: "#e6e5e5",
            background: "#0d0d17",
            numbers: "#3182e0",
            operators: "#f12d52",
            keywords: "#ff2b6d",
            functions: "#f5f17a",
            constants: "#3182e0",
            variables: "#09c87a",
            variableUsage: "#ff2b6d",
            assignment: "#f12d52",
            currency: "#09cd7e",
            units: "#09c87a",
            results: "#09cd7e",
            comments: "#808080"
        )
    ),
    Theme(
        name: "Nord",
        syntax: SyntaxColors(
            text: "#d8dee9",
            background: "#2e3440",
            numbers: "#81a1c1",
            operators: "#bf616a",
            keywords: "#b48ead",
            functions: "#ebcb8b",
            constants: "#81a1c1",
            variables: "#88c0d0",
            variableUsage: "#b48ead",
            assignment: "#bf616a",
            currency: "#a3be8c",
            units: "#88c0d0",
            results: "#a3be8c",
            comments: "#596377"
        )
    ),
    Theme(
        name: "Nord Light",
        syntax: SyntaxColors(
            text: "#414858",
            background: "#e5e9f0",
            numbers: "#81a1c1",
            operators: "#bf616a",
            keywords: "#b48ead",
            functions: "#c5a565",
            constants: "#81a1c1",
            variables: "#7bb3c3",
            variableUsage: "#b48ead",
            assignment: "#bf616a",
            currency: "#96b17f",
            units: "#7bb3c3",
            results: "#96b17f",
            comments: "#4c566a"
        )
    ),
    Theme(
        name: "Nord Wave",
        syntax: SyntaxColors(
            text: "#d8dee9",
            background: "#212121",
            numbers: "#81a1c1",
            operators: "#bf616a",
            keywords: "#b48ead",
            functions: "#ebcb8b",
            constants: "#81a1c1",
            variables: "#88c0d0",
            variableUsage: "#b48ead",
            assignment: "#bf616a",
            currency: "#a3be8c",
            units: "#88c0d0",
            results: "#a3be8c",
            comments: "#4c566a"
        )
    ),
    Theme(
        name: "Nordfox",
        syntax: SyntaxColors(
            text: "#cdcecf",
            background: "#2e3440",
            numbers: "#81a1c1",
            operators: "#bf616a",
            keywords: "#b48ead",
            functions: "#ebcb8b",
            constants: "#81a1c1",
            variables: "#88c0d0",
            variableUsage: "#b48ead",
            assignment: "#bf616a",
            currency: "#a3be8c",
            units: "#88c0d0",
            results: "#a3be8c",
            comments: "#53648d"
        )
    ),
    Theme(
        name: "Novel",
        syntax: SyntaxColors(
            text: "#3b2322",
            background: "#dfdbc3",
            numbers: "#0000cc",
            operators: "#cc0000",
            keywords: "#cc00cc",
            functions: "#d06b00",
            constants: "#0000cc",
            variables: "#0087cc",
            variableUsage: "#cc00cc",
            assignment: "#cc0000",
            currency: "#009600",
            units: "#0087cc",
            results: "#009600",
            comments: "#808080"
        )
    ),
    Theme(
        name: "Nvim Dark",
        syntax: SyntaxColors(
            text: "#e0e2ea",
            background: "#14161b",
            numbers: "#a6dbff",
            operators: "#ffc0b9",
            keywords: "#ffcaff",
            functions: "#fce094",
            constants: "#a6dbff",
            variables: "#8cf8f7",
            variableUsage: "#ffcaff",
            assignment: "#ffc0b9",
            currency: "#b3f6c0",
            units: "#8cf8f7",
            results: "#b3f6c0",
            comments: "#4f5258"
        )
    ),
    Theme(
        name: "Nvim Light",
        syntax: SyntaxColors(
            text: "#14161b",
            background: "#e0e2ea",
            numbers: "#004c73",
            operators: "#590008",
            keywords: "#470045",
            functions: "#6b5300",
            constants: "#004c73",
            variables: "#007373",
            variableUsage: "#470045",
            assignment: "#590008",
            currency: "#005523",
            units: "#007373",
            results: "#005523",
            comments: "#4f5258"
        )
    ),
    Theme(
        name: "Obsidian",
        syntax: SyntaxColors(
            text: "#cdcdcd",
            background: "#283033",
            numbers: "#3a9bdb",
            operators: "#b30d0e",
            keywords: "#bb00bb",
            functions: "#fecd22",
            constants: "#3a9bdb",
            variables: "#00bbbb",
            variableUsage: "#bb00bb",
            assignment: "#b30d0e",
            currency: "#00bb00",
            units: "#00bbbb",
            results: "#00bb00",
            comments: "#555555"
        )
    ),
    Theme(
        name: "Ocean",
        syntax: SyntaxColors(
            text: "#ffffff",
            background: "#224fbc",
            numbers: "#0000b2",
            operators: "#e64c4c",
            keywords: "#d826d8",
            functions: "#999900",
            constants: "#0000b2",
            variables: "#00a6b2",
            variableUsage: "#d826d8",
            assignment: "#e64c4c",
            currency: "#00a600",
            units: "#00a6b2",
            results: "#00a600",
            comments: "#808080"
        )
    ),
    Theme(
        name: "Oceanic Material",
        syntax: SyntaxColors(
            text: "#c2c8d7",
            background: "#1c262b",
            numbers: "#1e80f0",
            operators: "#ee2b2a",
            keywords: "#8800a0",
            functions: "#ffea2e",
            constants: "#1e80f0",
            variables: "#16afca",
            variableUsage: "#8800a0",
            assignment: "#ee2b2a",
            currency: "#40a33f",
            units: "#16afca",
            results: "#40a33f",
            comments: "#777777"
        )
    ),
    Theme(
        name: "Oceanic Next",
        syntax: SyntaxColors(
            text: "#c0c5ce",
            background: "#162c35",
            numbers: "#6699cc",
            operators: "#ec5f67",
            keywords: "#c594c5",
            functions: "#fac863",
            constants: "#6699cc",
            variables: "#5fb3b3",
            variableUsage: "#c594c5",
            assignment: "#ec5f67",
            currency: "#99c794",
            units: "#5fb3b3",
            results: "#99c794",
            comments: "#65737e"
        )
    ),
    Theme(
        name: "Ollie",
        syntax: SyntaxColors(
            text: "#8a8dae",
            background: "#222125",
            numbers: "#2d57ac",
            operators: "#ac2e31",
            keywords: "#b08528",
            functions: "#ac4300",
            constants: "#2d57ac",
            variables: "#1fa6ac",
            variableUsage: "#b08528",
            assignment: "#ac2e31",
            currency: "#31ac61",
            units: "#1fa6ac",
            results: "#31ac61",
            comments: "#674432"
        )
    ),
    Theme(
        name: "One Double Dark",
        syntax: SyntaxColors(
            text: "#dbdfe5",
            background: "#282c34",
            numbers: "#3fb1f5",
            operators: "#f16372",
            keywords: "#d373e3",
            functions: "#ecbe70",
            constants: "#3fb1f5",
            variables: "#17b9c4",
            variableUsage: "#d373e3",
            assignment: "#f16372",
            currency: "#8cc570",
            units: "#17b9c4",
            results: "#8cc570",
            comments: "#525d6f"
        )
    ),
    Theme(
        name: "One Double Light",
        syntax: SyntaxColors(
            text: "#383a43",
            background: "#fafafa",
            numbers: "#0087c1",
            operators: "#f74840",
            keywords: "#b50da9",
            functions: "#cc8100",
            constants: "#0087c1",
            variables: "#009ab7",
            variableUsage: "#b50da9",
            assignment: "#f74840",
            currency: "#25a343",
            units: "#009ab7",
            results: "#25a343",
            comments: "#0e131f"
        )
    ),
    Theme(
        name: "One Half Dark",
        syntax: SyntaxColors(
            text: "#dcdfe4",
            background: "#282c34",
            numbers: "#61afef",
            operators: "#e06c75",
            keywords: "#c678dd",
            functions: "#e5c07b",
            constants: "#61afef",
            variables: "#56b6c2",
            variableUsage: "#c678dd",
            assignment: "#e06c75",
            currency: "#98c379",
            units: "#56b6c2",
            results: "#98c379",
            comments: "#5d677a"
        )
    ),
    Theme(
        name: "One Half Light",
        syntax: SyntaxColors(
            text: "#383a42",
            background: "#fafafa",
            numbers: "#0184bc",
            operators: "#e45649",
            keywords: "#a626a4",
            functions: "#c18401",
            constants: "#0184bc",
            variables: "#0997b3",
            variableUsage: "#a626a4",
            assignment: "#e45649",
            currency: "#50a14f",
            units: "#0997b3",
            results: "#50a14f",
            comments: "#4f525e"
        )
    ),
    Theme(
        name: "Operator Mono Dark",
        syntax: SyntaxColors(
            text: "#c3cac2",
            background: "#191919",
            numbers: "#4387cf",
            operators: "#ca372d",
            keywords: "#b86cb4",
            functions: "#d4d697",
            constants: "#4387cf",
            variables: "#72d5c6",
            variableUsage: "#b86cb4",
            assignment: "#ca372d",
            currency: "#4d7b3a",
            units: "#72d5c6",
            results: "#4d7b3a",
            comments: "#9a9b99"
        )
    ),
    Theme(
        name: "Overnight Slumber",
        syntax: SyntaxColors(
            text: "#ced2d6",
            background: "#0e1729",
            numbers: "#8dabe1",
            operators: "#ffa7c4",
            keywords: "#c792eb",
            functions: "#ffcb8b",
            constants: "#8dabe1",
            variables: "#78ccf0",
            variableUsage: "#c792eb",
            assignment: "#ffa7c4",
            currency: "#85cc95",
            units: "#78ccf0",
            results: "#85cc95",
            comments: "#575656"
        )
    ),
    Theme(
        name: "Oxocarbon",
        syntax: SyntaxColors(
            text: "#f2f4f8",
            background: "#161616",
            numbers: "#00c15a",
            operators: "#00dfdb",
            keywords: "#c693ff",
            functions: "#ff4297",
            constants: "#00c15a",
            variables: "#ff74b8",
            variableUsage: "#c693ff",
            assignment: "#00dfdb",
            currency: "#00b4ff",
            units: "#ff74b8",
            results: "#00b4ff",
            comments: "#585858"
        )
    ),
    Theme(
        name: "Pale Night Hc",
        syntax: SyntaxColors(
            text: "#cccccc",
            background: "#3e4251",
            numbers: "#82aaff",
            operators: "#f07178",
            keywords: "#c792ea",
            functions: "#ffcb6b",
            constants: "#82aaff",
            variables: "#89ddff",
            variableUsage: "#c792ea",
            assignment: "#f07178",
            currency: "#c3e88d",
            units: "#89ddff",
            results: "#c3e88d",
            comments: "#737373"
        )
    ),
    Theme(
        name: "Pandora",
        syntax: SyntaxColors(
            text: "#e1e1e1",
            background: "#141e43",
            numbers: "#338f86",
            operators: "#ff4242",
            keywords: "#9414e6",
            functions: "#ffad29",
            constants: "#338f86",
            variables: "#23d7d7",
            variableUsage: "#9414e6",
            assignment: "#ff4242",
            currency: "#74af68",
            units: "#23d7d7",
            results: "#74af68",
            comments: "#3f5648"
        )
    ),
    Theme(
        name: "Paraiso Dark",
        syntax: SyntaxColors(
            text: "#a39e9b",
            background: "#2f1e2e",
            numbers: "#06b6ef",
            operators: "#ef6155",
            keywords: "#815ba4",
            functions: "#fec418",
            constants: "#06b6ef",
            variables: "#5bc4bf",
            variableUsage: "#815ba4",
            assignment: "#ef6155",
            currency: "#48b685",
            units: "#5bc4bf",
            results: "#48b685",
            comments: "#776e71"
        )
    ),
    Theme(
        name: "Paul Millr",
        syntax: SyntaxColors(
            text: "#f2f2f2",
            background: "#000000",
            numbers: "#396bd7",
            operators: "#ff0000",
            keywords: "#b449be",
            functions: "#e7bf00",
            constants: "#396bd7",
            variables: "#66ccff",
            variableUsage: "#b449be",
            assignment: "#ff0000",
            currency: "#79ff0f",
            units: "#66ccff",
            results: "#79ff0f",
            comments: "#666666"
        )
    ),
    Theme(
        name: "Pencil Dark",
        syntax: SyntaxColors(
            text: "#f1f1f1",
            background: "#212121",
            numbers: "#008ec4",
            operators: "#c30771",
            keywords: "#5f4986",
            functions: "#a89c14",
            constants: "#008ec4",
            variables: "#20a5ba",
            variableUsage: "#5f4986",
            assignment: "#c30771",
            currency: "#10a778",
            units: "#20a5ba",
            results: "#10a778",
            comments: "#4f4f4f"
        )
    ),
    Theme(
        name: "Pencil Light",
        syntax: SyntaxColors(
            text: "#424242",
            background: "#f1f1f1",
            numbers: "#008ec4",
            operators: "#c30771",
            keywords: "#523c79",
            functions: "#a89c14",
            constants: "#008ec4",
            variables: "#20a5ba",
            variableUsage: "#523c79",
            assignment: "#c30771",
            currency: "#10a778",
            units: "#20a5ba",
            results: "#10a778",
            comments: "#424242"
        )
    ),
    Theme(
        name: "Peppermint",
        syntax: SyntaxColors(
            text: "#c8c8c8",
            background: "#000000",
            numbers: "#449fd0",
            operators: "#e74669",
            keywords: "#da62dc",
            functions: "#dab853",
            constants: "#449fd0",
            variables: "#65aaaf",
            variableUsage: "#da62dc",
            assignment: "#e74669",
            currency: "#89d287",
            units: "#65aaaf",
            results: "#89d287",
            comments: "#535353"
        )
    ),
    Theme(
        name: "Phala Green Dark",
        syntax: SyntaxColors(
            text: "#c1fc03",
            background: "#000000",
            numbers: "#0223c0",
            operators: "#ab1500",
            keywords: "#c22ec0",
            functions: "#a9a700",
            constants: "#0223c0",
            variables: "#00b4c0",
            variableUsage: "#c22ec0",
            assignment: "#ab1500",
            currency: "#00b100",
            units: "#00b4c0",
            results: "#00b100",
            comments: "#797979"
        )
    ),
    Theme(
        name: "Piatto Light",
        syntax: SyntaxColors(
            text: "#414141",
            background: "#ffffff",
            numbers: "#3c5ea8",
            operators: "#b23771",
            keywords: "#a454b2",
            functions: "#cd6f34",
            constants: "#3c5ea8",
            variables: "#66781e",
            variableUsage: "#a454b2",
            assignment: "#b23771",
            currency: "#66781e",
            units: "#66781e",
            results: "#66781e",
            comments: "#3f3f3f"
        )
    ),
    Theme(
        name: "Pnevma",
        syntax: SyntaxColors(
            text: "#d0d0d0",
            background: "#1c1c1c",
            numbers: "#7fa5bd",
            operators: "#a36666",
            keywords: "#c79ec4",
            functions: "#d7af87",
            constants: "#7fa5bd",
            variables: "#8adbb4",
            variableUsage: "#c79ec4",
            assignment: "#a36666",
            currency: "#90a57d",
            units: "#8adbb4",
            results: "#90a57d",
            comments: "#4a4845"
        )
    ),
    Theme(
        name: "Popping And Locking",
        syntax: SyntaxColors(
            text: "#ebdbb2",
            background: "#181921",
            numbers: "#458588",
            operators: "#cc241d",
            keywords: "#b16286",
            functions: "#d79921",
            constants: "#458588",
            variables: "#689d6a",
            variableUsage: "#b16286",
            assignment: "#cc241d",
            currency: "#98971a",
            units: "#689d6a",
            results: "#98971a",
            comments: "#928374"
        )
    ),
    Theme(
        name: "Powershell",
        syntax: SyntaxColors(
            text: "#f6f6f7",
            background: "#052454",
            numbers: "#403fc2",
            operators: "#971921",
            keywords: "#d33682",
            functions: "#c4a000",
            constants: "#403fc2",
            variables: "#0e807f",
            variableUsage: "#d33682",
            assignment: "#971921",
            currency: "#098003",
            units: "#0e807f",
            results: "#098003",
            comments: "#808080"
        )
    ),
    Theme(
        name: "Primary",
        syntax: SyntaxColors(
            text: "#000000",
            background: "#ffffff",
            numbers: "#4285f4",
            operators: "#db4437",
            keywords: "#db4437",
            functions: "#f4b400",
            constants: "#4285f4",
            variables: "#4285f4",
            variableUsage: "#db4437",
            assignment: "#db4437",
            currency: "#0f9d58",
            units: "#4285f4",
            results: "#0f9d58",
            comments: "#000000"
        )
    ),
    Theme(
        name: "Pro",
        syntax: SyntaxColors(
            text: "#f2f2f2",
            background: "#000000",
            numbers: "#2009db",
            operators: "#990000",
            keywords: "#b200b2",
            functions: "#999900",
            constants: "#2009db",
            variables: "#00a6b2",
            variableUsage: "#b200b2",
            assignment: "#990000",
            currency: "#00a600",
            units: "#00a6b2",
            results: "#00a600",
            comments: "#666666"
        )
    ),
    Theme(
        name: "Pro Light",
        syntax: SyntaxColors(
            text: "#191919",
            background: "#ffffff",
            numbers: "#3b75ff",
            operators: "#e5492b",
            keywords: "#ed66e8",
            functions: "#c6c440",
            constants: "#3b75ff",
            variables: "#4ed2de",
            variableUsage: "#ed66e8",
            assignment: "#e5492b",
            currency: "#50d148",
            units: "#4ed2de",
            results: "#50d148",
            comments: "#9f9f9f"
        )
    ),
    Theme(
        name: "Purple Rain",
        syntax: SyntaxColors(
            text: "#fffbf6",
            background: "#21084a",
            numbers: "#00a2fa",
            operators: "#ff260e",
            keywords: "#815bb5",
            functions: "#ffc400",
            constants: "#00a2fa",
            variables: "#00deef",
            variableUsage: "#815bb5",
            assignment: "#ff260e",
            currency: "#9be205",
            units: "#00deef",
            results: "#9be205",
            comments: "#565656"
        )
    ),
    Theme(
        name: "Purplepeter",
        syntax: SyntaxColors(
            text: "#ece7fa",
            background: "#2a1a4a",
            numbers: "#66d9ef",
            operators: "#ff796d",
            keywords: "#e78fcd",
            functions: "#efdfac",
            constants: "#66d9ef",
            variables: "#ba8cff",
            variableUsage: "#e78fcd",
            assignment: "#ff796d",
            currency: "#99b481",
            units: "#ba8cff",
            results: "#99b481",
            comments: "#504b63"
        )
    ),
    Theme(
        name: "Rapture",
        syntax: SyntaxColors(
            text: "#c0c9e5",
            background: "#111e2a",
            numbers: "#6c9bf5",
            operators: "#fc644d",
            keywords: "#ff4fa1",
            functions: "#fff09b",
            constants: "#6c9bf5",
            variables: "#64e0ff",
            variableUsage: "#ff4fa1",
            assignment: "#fc644d",
            currency: "#7afde1",
            units: "#64e0ff",
            results: "#7afde1",
            comments: "#304b66"
        )
    ),
    Theme(
        name: "Raycast Dark",
        syntax: SyntaxColors(
            text: "#ffffff",
            background: "#1a1a1a",
            numbers: "#56c2ff",
            operators: "#ff5360",
            keywords: "#cf2f98",
            functions: "#ffc531",
            constants: "#56c2ff",
            variables: "#52eee5",
            variableUsage: "#cf2f98",
            assignment: "#ff5360",
            currency: "#59d499",
            units: "#52eee5",
            results: "#59d499",
            comments: "#4c4c4c"
        )
    ),
    Theme(
        name: "Raycast Light",
        syntax: SyntaxColors(
            text: "#000000",
            background: "#ffffff",
            numbers: "#138af2",
            operators: "#b12424",
            keywords: "#9a1b6e",
            functions: "#f8a300",
            constants: "#138af2",
            variables: "#3eb8bf",
            variableUsage: "#9a1b6e",
            assignment: "#b12424",
            currency: "#006b4f",
            units: "#3eb8bf",
            results: "#006b4f",
            comments: "#000000"
        )
    ),
    Theme(
        name: "Rebecca",
        syntax: SyntaxColors(
            text: "#e8e6ed",
            background: "#292a44",
            numbers: "#7aa5ff",
            operators: "#dd7755",
            keywords: "#bf9cf9",
            functions: "#f2e7b7",
            constants: "#7aa5ff",
            variables: "#56d3c2",
            variableUsage: "#bf9cf9",
            assignment: "#dd7755",
            currency: "#04dbb5",
            units: "#56d3c2",
            results: "#04dbb5",
            comments: "#666699"
        )
    ),
    Theme(
        name: "Red Alert",
        syntax: SyntaxColors(
            text: "#ffffff",
            background: "#762423",
            numbers: "#489bee",
            operators: "#d62e4e",
            keywords: "#e979d7",
            functions: "#beb86b",
            constants: "#489bee",
            variables: "#6bbeb8",
            variableUsage: "#e979d7",
            assignment: "#d62e4e",
            currency: "#71be6b",
            units: "#6bbeb8",
            results: "#71be6b",
            comments: "#666666"
        )
    ),
    Theme(
        name: "Red Planet",
        syntax: SyntaxColors(
            text: "#c2b790",
            background: "#222222",
            numbers: "#69819e",
            operators: "#8c3432",
            keywords: "#896492",
            functions: "#e8bf6a",
            constants: "#69819e",
            variables: "#5b8390",
            variableUsage: "#896492",
            assignment: "#8c3432",
            currency: "#728271",
            units: "#5b8390",
            results: "#728271",
            comments: "#676767"
        )
    ),
    Theme(
        name: "Red Sands",
        syntax: SyntaxColors(
            text: "#d7c9a7",
            background: "#7a251e",
            numbers: "#0072ff",
            operators: "#ff3f00",
            keywords: "#bb00bb",
            functions: "#e7b000",
            constants: "#0072ff",
            variables: "#00bbbb",
            variableUsage: "#bb00bb",
            assignment: "#ff3f00",
            currency: "#00bb00",
            units: "#00bbbb",
            results: "#00bb00",
            comments: "#6e6e6e"
        )
    ),
    Theme(
        name: "Relaxed",
        syntax: SyntaxColors(
            text: "#d9d9d9",
            background: "#353a44",
            numbers: "#6a8799",
            operators: "#bc5653",
            keywords: "#b06698",
            functions: "#ebc17a",
            constants: "#6a8799",
            variables: "#c9dfff",
            variableUsage: "#b06698",
            assignment: "#bc5653",
            currency: "#909d63",
            units: "#c9dfff",
            results: "#909d63",
            comments: "#636363"
        )
    ),
    Theme(
        name: "Retro",
        syntax: SyntaxColors(
            text: "#13a10e",
            background: "#000000",
            numbers: "#13a10e",
            operators: "#13a10e",
            keywords: "#13a10e",
            functions: "#13a10e",
            constants: "#13a10e",
            variables: "#13a10e",
            variableUsage: "#13a10e",
            assignment: "#13a10e",
            currency: "#13a10e",
            units: "#13a10e",
            results: "#13a10e",
            comments: "#16ba10"
        )
    ),
    Theme(
        name: "Retro Legends",
        syntax: SyntaxColors(
            text: "#45eb45",
            background: "#0d0d0d",
            numbers: "#4066f2",
            operators: "#de5454",
            keywords: "#bf4cf2",
            functions: "#f7bf2b",
            constants: "#4066f2",
            variables: "#40d9e6",
            variableUsage: "#bf4cf2",
            assignment: "#de5454",
            currency: "#45eb45",
            units: "#40d9e6",
            results: "#45eb45",
            comments: "#4c594c"
        )
    ),
    Theme(
        name: "Rippedcasts",
        syntax: SyntaxColors(
            text: "#ffffff",
            background: "#2b2b2b",
            numbers: "#75a5b0",
            operators: "#cdaf95",
            keywords: "#ff73fd",
            functions: "#bfbb1f",
            constants: "#75a5b0",
            variables: "#5a647e",
            variableUsage: "#ff73fd",
            assignment: "#cdaf95",
            currency: "#a8ff60",
            units: "#5a647e",
            results: "#a8ff60",
            comments: "#666666"
        )
    ),
    Theme(
        name: "Rose Pine",
        syntax: SyntaxColors(
            text: "#e0def4",
            background: "#191724",
            numbers: "#9ccfd8",
            operators: "#eb6f92",
            keywords: "#c4a7e7",
            functions: "#f6c177",
            constants: "#9ccfd8",
            variables: "#ebbcba",
            variableUsage: "#c4a7e7",
            assignment: "#eb6f92",
            currency: "#31748f",
            units: "#ebbcba",
            results: "#31748f",
            comments: "#6e6a86"
        )
    ),
    Theme(
        name: "Rose Pine Dawn",
        syntax: SyntaxColors(
            text: "#575279",
            background: "#faf4ed",
            numbers: "#56949f",
            operators: "#b4637a",
            keywords: "#907aa9",
            functions: "#ea9d34",
            constants: "#56949f",
            variables: "#d7827e",
            variableUsage: "#907aa9",
            assignment: "#b4637a",
            currency: "#286983",
            units: "#d7827e",
            results: "#286983",
            comments: "#9893a5"
        )
    ),
    Theme(
        name: "Rose Pine Moon",
        syntax: SyntaxColors(
            text: "#e0def4",
            background: "#232136",
            numbers: "#9ccfd8",
            operators: "#eb6f92",
            keywords: "#c4a7e7",
            functions: "#f6c177",
            constants: "#9ccfd8",
            variables: "#ea9a97",
            variableUsage: "#c4a7e7",
            assignment: "#eb6f92",
            currency: "#3e8fb0",
            units: "#ea9a97",
            results: "#3e8fb0",
            comments: "#6e6a86"
        )
    ),
    Theme(
        name: "Rouge 2",
        syntax: SyntaxColors(
            text: "#a2a3aa",
            background: "#17182b",
            numbers: "#6e94b9",
            operators: "#c6797e",
            keywords: "#4c4e78",
            functions: "#dbcdab",
            constants: "#6e94b9",
            variables: "#8ab6c1",
            variableUsage: "#4c4e78",
            assignment: "#c6797e",
            currency: "#969e92",
            units: "#8ab6c1",
            results: "#969e92",
            comments: "#616274"
        )
    ),
    Theme(
        name: "Royal",
        syntax: SyntaxColors(
            text: "#514968",
            background: "#100815",
            numbers: "#6580b0",
            operators: "#91284c",
            keywords: "#674d96",
            functions: "#b49d27",
            constants: "#6580b0",
            variables: "#8aaabe",
            variableUsage: "#674d96",
            assignment: "#91284c",
            currency: "#23801c",
            units: "#8aaabe",
            results: "#23801c",
            comments: "#3e3a49"
        )
    ),
    Theme(
        name: "Ryuuko",
        syntax: SyntaxColors(
            text: "#ececec",
            background: "#2c3941",
            numbers: "#6a8e95",
            operators: "#865f5b",
            keywords: "#b18a73",
            functions: "#b1a990",
            constants: "#6a8e95",
            variables: "#88b2ac",
            variableUsage: "#b18a73",
            assignment: "#865f5b",
            currency: "#66907d",
            units: "#88b2ac",
            results: "#66907d",
            comments: "#5d7079"
        )
    ),
    Theme(
        name: "Sakura",
        syntax: SyntaxColors(
            text: "#dd7bdc",
            background: "#18131e",
            numbers: "#6964ab",
            operators: "#d52370",
            keywords: "#c71fbf",
            functions: "#bc7053",
            constants: "#6964ab",
            variables: "#939393",
            variableUsage: "#c71fbf",
            assignment: "#d52370",
            currency: "#41af1a",
            units: "#939393",
            results: "#41af1a",
            comments: "#786d69"
        )
    ),
    Theme(
        name: "Scarlet Protocol",
        syntax: SyntaxColors(
            text: "#e41951",
            background: "#1c153d",
            numbers: "#0271b6",
            operators: "#ff0051",
            keywords: "#ca30c7",
            functions: "#faf945",
            constants: "#0271b6",
            variables: "#00c5c7",
            variableUsage: "#ca30c7",
            assignment: "#ff0051",
            currency: "#00dc84",
            units: "#00c5c7",
            results: "#00dc84",
            comments: "#686868"
        )
    ),
    Theme(
        name: "Sea Shells",
        syntax: SyntaxColors(
            text: "#deb88d",
            background: "#09141b",
            numbers: "#1e4950",
            operators: "#d15123",
            keywords: "#68d4f1",
            functions: "#fca02f",
            constants: "#1e4950",
            variables: "#50a3b5",
            variableUsage: "#68d4f1",
            assignment: "#d15123",
            currency: "#027c9b",
            units: "#50a3b5",
            results: "#027c9b",
            comments: "#434b53"
        )
    ),
    Theme(
        name: "Seafoam Pastel",
        syntax: SyntaxColors(
            text: "#d4e7d4",
            background: "#243435",
            numbers: "#4d7b82",
            operators: "#825d4d",
            keywords: "#8a7267",
            functions: "#ada16d",
            constants: "#4d7b82",
            variables: "#729494",
            variableUsage: "#8a7267",
            assignment: "#825d4d",
            currency: "#728c62",
            units: "#729494",
            results: "#728c62",
            comments: "#8a8a8a"
        )
    ),
    Theme(
        name: "Selenized Dark",
        syntax: SyntaxColors(
            text: "#adbcbc",
            background: "#103c48",
            numbers: "#4695f7",
            operators: "#fa5750",
            keywords: "#f275be",
            functions: "#dbb32d",
            constants: "#4695f7",
            variables: "#41c7b9",
            variableUsage: "#f275be",
            assignment: "#fa5750",
            currency: "#75b938",
            units: "#41c7b9",
            results: "#75b938",
            comments: "#396775"
        )
    ),
    Theme(
        name: "Selenized Light",
        syntax: SyntaxColors(
            text: "#53676d",
            background: "#fbf3db",
            numbers: "#0072d4",
            operators: "#d2212d",
            keywords: "#ca4898",
            functions: "#ad8900",
            constants: "#0072d4",
            variables: "#009c8f",
            variableUsage: "#ca4898",
            assignment: "#d2212d",
            currency: "#489100",
            units: "#009c8f",
            results: "#489100",
            comments: "#bbb39c"
        )
    ),
    Theme(
        name: "Seoulbones Dark",
        syntax: SyntaxColors(
            text: "#dddddd",
            background: "#4b4b4b",
            numbers: "#97bdde",
            operators: "#e388a3",
            keywords: "#a5a6c5",
            functions: "#ffdf9b",
            constants: "#97bdde",
            variables: "#6fbdbe",
            variableUsage: "#a5a6c5",
            assignment: "#e388a3",
            currency: "#98bd99",
            units: "#6fbdbe",
            results: "#98bd99",
            comments: "#797172"
        )
    ),
    Theme(
        name: "Seoulbones Light",
        syntax: SyntaxColors(
            text: "#555555",
            background: "#e2e2e2",
            numbers: "#0084a3",
            operators: "#dc5284",
            keywords: "#896788",
            functions: "#c48562",
            constants: "#0084a3",
            variables: "#008586",
            variableUsage: "#896788",
            assignment: "#dc5284",
            currency: "#628562",
            units: "#008586",
            results: "#628562",
            comments: "#a5a0a1"
        )
    ),
    Theme(
        name: "Seti",
        syntax: SyntaxColors(
            text: "#cacecd",
            background: "#111213",
            numbers: "#43a5d5",
            operators: "#c22832",
            keywords: "#8b57b5",
            functions: "#e0c64f",
            constants: "#43a5d5",
            variables: "#8ec43d",
            variableUsage: "#8b57b5",
            assignment: "#c22832",
            currency: "#8ec43d",
            units: "#8ec43d",
            results: "#8ec43d",
            comments: "#3f3f3f"
        )
    ),
    Theme(
        name: "Shades Of Purple",
        syntax: SyntaxColors(
            text: "#ffffff",
            background: "#1e1d40",
            numbers: "#6943ff",
            operators: "#d90429",
            keywords: "#ff2c70",
            functions: "#ffe700",
            constants: "#6943ff",
            variables: "#00c5c7",
            variableUsage: "#ff2c70",
            assignment: "#d90429",
            currency: "#3ad900",
            units: "#00c5c7",
            results: "#3ad900",
            comments: "#686868"
        )
    ),
    Theme(
        name: "Shaman",
        syntax: SyntaxColors(
            text: "#405555",
            background: "#001015",
            numbers: "#449a86",
            operators: "#b2302d",
            keywords: "#00599d",
            functions: "#5e8baa",
            constants: "#449a86",
            variables: "#5d7e19",
            variableUsage: "#00599d",
            assignment: "#b2302d",
            currency: "#00a941",
            units: "#5d7e19",
            results: "#00a941",
            comments: "#384451"
        )
    ),
    Theme(
        name: "Slate",
        syntax: SyntaxColors(
            text: "#35b1d2",
            background: "#222222",
            numbers: "#325856",
            operators: "#e2a8bf",
            keywords: "#a481d3",
            functions: "#c4c9c0",
            constants: "#325856",
            variables: "#15ab9c",
            variableUsage: "#a481d3",
            assignment: "#e2a8bf",
            currency: "#81d778",
            units: "#15ab9c",
            results: "#81d778",
            comments: "#ffffff"
        )
    ),
    Theme(
        name: "Sleepy Hollow",
        syntax: SyntaxColors(
            text: "#af9a91",
            background: "#121214",
            numbers: "#5f63b4",
            operators: "#ba3934",
            keywords: "#a17c7b",
            functions: "#b55600",
            constants: "#5f63b4",
            variables: "#8faea9",
            variableUsage: "#a17c7b",
            assignment: "#ba3934",
            currency: "#91773f",
            units: "#8faea9",
            results: "#91773f",
            comments: "#4e4b61"
        )
    ),
    Theme(
        name: "Smyck",
        syntax: SyntaxColors(
            text: "#f7f7f7",
            background: "#1b1b1b",
            numbers: "#62a3c4",
            operators: "#b84131",
            keywords: "#ba8acc",
            functions: "#c4a500",
            constants: "#62a3c4",
            variables: "#207383",
            variableUsage: "#ba8acc",
            assignment: "#b84131",
            currency: "#7da900",
            units: "#207383",
            results: "#7da900",
            comments: "#7a7a7a"
        )
    ),
    Theme(
        name: "Snazzy",
        syntax: SyntaxColors(
            text: "#ebece6",
            background: "#1e1f29",
            numbers: "#49baff",
            operators: "#fc4346",
            keywords: "#fc4cb4",
            functions: "#f0fb8c",
            constants: "#49baff",
            variables: "#8be9fe",
            variableUsage: "#fc4cb4",
            assignment: "#fc4346",
            currency: "#50fb7c",
            units: "#8be9fe",
            results: "#50fb7c",
            comments: "#555555"
        )
    ),
    Theme(
        name: "Snazzy Soft",
        syntax: SyntaxColors(
            text: "#eff0eb",
            background: "#282a36",
            numbers: "#57c7ff",
            operators: "#ff5c57",
            keywords: "#ff6ac1",
            functions: "#f3f99d",
            constants: "#57c7ff",
            variables: "#9aedfe",
            variableUsage: "#ff6ac1",
            assignment: "#ff5c57",
            currency: "#5af78e",
            units: "#9aedfe",
            results: "#5af78e",
            comments: "#686868"
        )
    ),
    Theme(
        name: "Soft Server",
        syntax: SyntaxColors(
            text: "#99a3a2",
            background: "#242626",
            numbers: "#6b8fa3",
            operators: "#a2686a",
            keywords: "#6a71a3",
            functions: "#a3906a",
            constants: "#6b8fa3",
            variables: "#6ba58f",
            variableUsage: "#6a71a3",
            assignment: "#a2686a",
            currency: "#9aa56a",
            units: "#6ba58f",
            results: "#9aa56a",
            comments: "#666c6c"
        )
    ),
    Theme(
        name: "Solarized Darcula",
        syntax: SyntaxColors(
            text: "#d2d8d9",
            background: "#3d3f41",
            numbers: "#2075c7",
            operators: "#f24840",
            keywords: "#797fd4",
            functions: "#b68800",
            constants: "#2075c7",
            variables: "#15968d",
            variableUsage: "#797fd4",
            assignment: "#f24840",
            currency: "#629655",
            units: "#15968d",
            results: "#629655",
            comments: "#65696a"
        )
    ),
    Theme(
        name: "Solarized Dark Higher Contrast",
        syntax: SyntaxColors(
            text: "#9cc2c3",
            background: "#001e27",
            numbers: "#2176c7",
            operators: "#d11c24",
            keywords: "#c61c6f",
            functions: "#a57706",
            constants: "#2176c7",
            variables: "#259286",
            variableUsage: "#c61c6f",
            assignment: "#d11c24",
            currency: "#6cbe6c",
            units: "#259286",
            results: "#6cbe6c",
            comments: "#006488"
        )
    ),
    Theme(
        name: "Solarized Dark Patched",
        syntax: SyntaxColors(
            text: "#708284",
            background: "#001e27",
            numbers: "#2176c7",
            operators: "#d11c24",
            keywords: "#c61c6f",
            functions: "#a57706",
            constants: "#2176c7",
            variables: "#259286",
            variableUsage: "#c61c6f",
            assignment: "#d11c24",
            currency: "#738a05",
            units: "#259286",
            results: "#738a05",
            comments: "#475b62"
        )
    ),
    Theme(
        name: "Solarized Osaka Night",
        syntax: SyntaxColors(
            text: "#c0caf5",
            background: "#1a1b26",
            numbers: "#7aa2f7",
            operators: "#f7768e",
            keywords: "#bb9af7",
            functions: "#e0af68",
            constants: "#7aa2f7",
            variables: "#7dcfff",
            variableUsage: "#bb9af7",
            assignment: "#f7768e",
            currency: "#9ece6a",
            units: "#7dcfff",
            results: "#9ece6a",
            comments: "#414868"
        )
    ),
    Theme(
        name: "Sonokai",
        syntax: SyntaxColors(
            text: "#e2e2e3",
            background: "#2c2e34",
            numbers: "#76cce0",
            operators: "#fc5d7c",
            keywords: "#b39df3",
            functions: "#e7c664",
            constants: "#76cce0",
            variables: "#f39660",
            variableUsage: "#b39df3",
            assignment: "#fc5d7c",
            currency: "#9ed072",
            units: "#f39660",
            results: "#9ed072",
            comments: "#7f8490"
        )
    ),
    Theme(
        name: "Spacedust",
        syntax: SyntaxColors(
            text: "#ecf0c1",
            background: "#0a1e24",
            numbers: "#0f548b",
            operators: "#e35b00",
            keywords: "#e35b00",
            functions: "#e3cd7b",
            constants: "#0f548b",
            variables: "#06afc7",
            variableUsage: "#e35b00",
            assignment: "#e35b00",
            currency: "#5cab96",
            units: "#06afc7",
            results: "#5cab96",
            comments: "#684c31"
        )
    ),
    Theme(
        name: "Spacegray",
        syntax: SyntaxColors(
            text: "#b3b8c3",
            background: "#20242d",
            numbers: "#7d8fa4",
            operators: "#b04b57",
            keywords: "#a47996",
            functions: "#e5c179",
            constants: "#7d8fa4",
            variables: "#85a7a5",
            variableUsage: "#a47996",
            assignment: "#b04b57",
            currency: "#87b379",
            units: "#85a7a5",
            results: "#87b379",
            comments: "#4c4c4c"
        )
    ),
    Theme(
        name: "Spacegray Bright",
        syntax: SyntaxColors(
            text: "#f3f3f3",
            background: "#2a2e3a",
            numbers: "#7baec1",
            operators: "#bc5553",
            keywords: "#b98aae",
            functions: "#f6c987",
            constants: "#7baec1",
            variables: "#85c9b8",
            variableUsage: "#b98aae",
            assignment: "#bc5553",
            currency: "#a0b56c",
            units: "#85c9b8",
            results: "#a0b56c",
            comments: "#626262"
        )
    ),
    Theme(
        name: "Spacegray Eighties",
        syntax: SyntaxColors(
            text: "#bdbaae",
            background: "#222222",
            numbers: "#5486c0",
            operators: "#ec5f67",
            keywords: "#bf83c1",
            functions: "#fec254",
            constants: "#5486c0",
            variables: "#57c2c1",
            variableUsage: "#bf83c1",
            assignment: "#ec5f67",
            currency: "#81a764",
            units: "#57c2c1",
            results: "#81a764",
            comments: "#555555"
        )
    ),
    Theme(
        name: "Spacegray Eighties Dull",
        syntax: SyntaxColors(
            text: "#c9c6bc",
            background: "#222222",
            numbers: "#7c8fa5",
            operators: "#b24a56",
            keywords: "#a5789e",
            functions: "#c6735a",
            constants: "#7c8fa5",
            variables: "#80cdcb",
            variableUsage: "#a5789e",
            assignment: "#b24a56",
            currency: "#92b477",
            units: "#80cdcb",
            results: "#92b477",
            comments: "#555555"
        )
    ),
    Theme(
        name: "Spiderman",
        syntax: SyntaxColors(
            text: "#e3e3e3",
            background: "#1b1d1e",
            numbers: "#2c3fff",
            operators: "#e60813",
            keywords: "#2435db",
            functions: "#e24756",
            constants: "#2c3fff",
            variables: "#3256ff",
            variableUsage: "#2435db",
            assignment: "#e60813",
            currency: "#e22928",
            units: "#3256ff",
            results: "#e22928",
            comments: "#505354"
        )
    ),
    Theme(
        name: "Spring",
        syntax: SyntaxColors(
            text: "#4d4d4c",
            background: "#ffffff",
            numbers: "#1dd3ee",
            operators: "#ff4d83",
            keywords: "#8959a8",
            functions: "#1fc95b",
            constants: "#1dd3ee",
            variables: "#3e999f",
            variableUsage: "#8959a8",
            assignment: "#ff4d83",
            currency: "#1f8c3b",
            units: "#3e999f",
            results: "#1f8c3b",
            comments: "#000000"
        )
    ),
    Theme(
        name: "Square",
        syntax: SyntaxColors(
            text: "#acacab",
            background: "#1a1a1a",
            numbers: "#a9cdeb",
            operators: "#e9897c",
            keywords: "#75507b",
            functions: "#ecebbe",
            constants: "#a9cdeb",
            variables: "#c9caec",
            variableUsage: "#75507b",
            assignment: "#e9897c",
            currency: "#b6377d",
            units: "#c9caec",
            results: "#b6377d",
            comments: "#474747"
        )
    ),
    Theme(
        name: "Squirrelsong Dark",
        syntax: SyntaxColors(
            text: "#b19b89",
            background: "#372920",
            numbers: "#4395c6",
            operators: "#ba4138",
            keywords: "#855fb8",
            functions: "#d4b139",
            constants: "#4395c6",
            variables: "#2f9794",
            variableUsage: "#855fb8",
            assignment: "#ba4138",
            currency: "#468336",
            units: "#2f9794",
            results: "#468336",
            comments: "#704f39"
        )
    ),
    Theme(
        name: "Srcery",
        syntax: SyntaxColors(
            text: "#fce8c3",
            background: "#1c1b19",
            numbers: "#2c78bf",
            operators: "#ef2f27",
            keywords: "#e02c6d",
            functions: "#fbb829",
            constants: "#2c78bf",
            variables: "#0aaeb3",
            variableUsage: "#e02c6d",
            assignment: "#ef2f27",
            currency: "#519f50",
            units: "#0aaeb3",
            results: "#519f50",
            comments: "#918175"
        )
    ),
    Theme(
        name: "Starlight",
        syntax: SyntaxColors(
            text: "#ffffff",
            background: "#242424",
            numbers: "#24acd4",
            operators: "#f62b5a",
            keywords: "#f2affd",
            functions: "#e3c401",
            constants: "#24acd4",
            variables: "#13c299",
            variableUsage: "#f2affd",
            assignment: "#f62b5a",
            currency: "#47b413",
            units: "#13c299",
            results: "#47b413",
            comments: "#616161"
        )
    ),
    Theme(
        name: "Sublette",
        syntax: SyntaxColors(
            text: "#ccced0",
            background: "#202535",
            numbers: "#5588ff",
            operators: "#ee5577",
            keywords: "#ff77cc",
            functions: "#ffdd88",
            constants: "#5588ff",
            variables: "#44eeee",
            variableUsage: "#ff77cc",
            assignment: "#ee5577",
            currency: "#55ee77",
            units: "#44eeee",
            results: "#55ee77",
            comments: "#405570"
        )
    ),
    Theme(
        name: "Subliminal",
        syntax: SyntaxColors(
            text: "#d4d4d4",
            background: "#282c35",
            numbers: "#6699cc",
            operators: "#e15a60",
            keywords: "#f1a5ab",
            functions: "#ffe2a9",
            constants: "#6699cc",
            variables: "#5fb3b3",
            variableUsage: "#f1a5ab",
            assignment: "#e15a60",
            currency: "#a9cfa4",
            units: "#5fb3b3",
            results: "#a9cfa4",
            comments: "#7f7f7f"
        )
    ),
    Theme(
        name: "Sugarplum",
        syntax: SyntaxColors(
            text: "#db7ddd",
            background: "#111147",
            numbers: "#db7ddd",
            operators: "#5ca8dc",
            keywords: "#d0beee",
            functions: "#249a84",
            constants: "#db7ddd",
            variables: "#f9f3f9",
            variableUsage: "#d0beee",
            assignment: "#5ca8dc",
            currency: "#53b397",
            units: "#f9f3f9",
            results: "#53b397",
            comments: "#44447a"
        )
    ),
    Theme(
        name: "Sundried",
        syntax: SyntaxColors(
            text: "#c9c9c9",
            background: "#1a1818",
            numbers: "#485b98",
            operators: "#a7463d",
            keywords: "#864651",
            functions: "#9d602a",
            constants: "#485b98",
            variables: "#9c814f",
            variableUsage: "#864651",
            assignment: "#a7463d",
            currency: "#587744",
            units: "#9c814f",
            results: "#587744",
            comments: "#4d4e48"
        )
    ),
    Theme(
        name: "Symfonic",
        syntax: SyntaxColors(
            text: "#ffffff",
            background: "#000000",
            numbers: "#0084d4",
            operators: "#dc322f",
            keywords: "#b729d9",
            functions: "#ff8400",
            constants: "#0084d4",
            variables: "#ccccff",
            variableUsage: "#b729d9",
            assignment: "#dc322f",
            currency: "#56db3a",
            units: "#ccccff",
            results: "#56db3a",
            comments: "#414347"
        )
    ),
    Theme(
        name: "Synthwave",
        syntax: SyntaxColors(
            text: "#dad9c7",
            background: "#000000",
            numbers: "#2186ec",
            operators: "#f6188f",
            keywords: "#f85a21",
            functions: "#fdf834",
            constants: "#2186ec",
            variables: "#12c3e2",
            variableUsage: "#f85a21",
            assignment: "#f6188f",
            currency: "#1ebb2b",
            units: "#12c3e2",
            results: "#1ebb2b",
            comments: "#7f7094"
        )
    ),
    Theme(
        name: "Synthwave Alpha",
        syntax: SyntaxColors(
            text: "#f2f2e3",
            background: "#241b30",
            numbers: "#6e29ad",
            operators: "#e60a70",
            keywords: "#b300ad",
            functions: "#adad3e",
            constants: "#6e29ad",
            variables: "#00b0b1",
            variableUsage: "#b300ad",
            assignment: "#e60a70",
            currency: "#00986c",
            units: "#00b0b1",
            results: "#00986c",
            comments: "#7f7094"
        )
    ),
    Theme(
        name: "Synthwave Everything",
        syntax: SyntaxColors(
            text: "#f0eff1",
            background: "#2a2139",
            numbers: "#6d77b3",
            operators: "#f97e72",
            keywords: "#c792ea",
            functions: "#fede5d",
            constants: "#6d77b3",
            variables: "#f772e0",
            variableUsage: "#c792ea",
            assignment: "#f97e72",
            currency: "#72f1b8",
            units: "#f772e0",
            results: "#72f1b8",
            comments: "#fefefe"
        )
    ),
    Theme(
        name: "Tango Adapted",
        syntax: SyntaxColors(
            text: "#000000",
            background: "#ffffff",
            numbers: "#00a2ff",
            operators: "#ff0000",
            keywords: "#c17ecc",
            functions: "#e3be00",
            constants: "#00a2ff",
            variables: "#00d0d6",
            variableUsage: "#c17ecc",
            assignment: "#ff0000",
            currency: "#59d600",
            units: "#00d0d6",
            results: "#59d600",
            comments: "#8f928b"
        )
    ),
    Theme(
        name: "Tango Half Adapted",
        syntax: SyntaxColors(
            text: "#000000",
            background: "#ffffff",
            numbers: "#008ef6",
            operators: "#ff0000",
            keywords: "#a96cb3",
            functions: "#e2c000",
            constants: "#008ef6",
            variables: "#00bdc3",
            variableUsage: "#a96cb3",
            assignment: "#ff0000",
            currency: "#4cc300",
            units: "#00bdc3",
            results: "#4cc300",
            comments: "#797d76"
        )
    ),
    Theme(
        name: "Tearout",
        syntax: SyntaxColors(
            text: "#f4d2ae",
            background: "#34392d",
            numbers: "#b5955e",
            operators: "#cc967b",
            keywords: "#c9a554",
            functions: "#6c9861",
            constants: "#b5955e",
            variables: "#d7c483",
            variableUsage: "#c9a554",
            assignment: "#cc967b",
            currency: "#97976d",
            units: "#d7c483",
            results: "#97976d",
            comments: "#74634e"
        )
    ),
    Theme(
        name: "Teerb",
        syntax: SyntaxColors(
            text: "#d0d0d0",
            background: "#262626",
            numbers: "#86aed6",
            operators: "#d68686",
            keywords: "#d6aed6",
            functions: "#d7af87",
            constants: "#86aed6",
            variables: "#8adbb4",
            variableUsage: "#d6aed6",
            assignment: "#d68686",
            currency: "#aed686",
            units: "#8adbb4",
            results: "#aed686",
            comments: "#4f4f4f"
        )
    ),
    Theme(
        name: "Terafox",
        syntax: SyntaxColors(
            text: "#e6eaea",
            background: "#152528",
            numbers: "#5a93aa",
            operators: "#e85c51",
            keywords: "#ad5c7c",
            functions: "#fda47f",
            constants: "#5a93aa",
            variables: "#a1cdd8",
            variableUsage: "#ad5c7c",
            assignment: "#e85c51",
            currency: "#7aa4a1",
            units: "#a1cdd8",
            results: "#7aa4a1",
            comments: "#4e5157"
        )
    ),
    Theme(
        name: "Terminal Basic",
        syntax: SyntaxColors(
            text: "#000000",
            background: "#ffffff",
            numbers: "#0000b2",
            operators: "#990000",
            keywords: "#b200b2",
            functions: "#999900",
            constants: "#0000b2",
            variables: "#00a6b2",
            variableUsage: "#b200b2",
            assignment: "#990000",
            currency: "#00a600",
            units: "#00a6b2",
            results: "#00a600",
            comments: "#666666"
        )
    ),
    Theme(
        name: "Terminal Basic Dark",
        syntax: SyntaxColors(
            text: "#ffffff",
            background: "#1d1e1d",
            numbers: "#6444ed",
            operators: "#c65339",
            keywords: "#d357db",
            functions: "#b8b74a",
            constants: "#6444ed",
            variables: "#69c1cf",
            variableUsage: "#d357db",
            assignment: "#c65339",
            currency: "#6ac44b",
            units: "#69c1cf",
            results: "#6ac44b",
            comments: "#909090"
        )
    ),
    Theme(
        name: "Thayer Bright",
        syntax: SyntaxColors(
            text: "#f8f8f8",
            background: "#1b1d1e",
            numbers: "#2757d6",
            operators: "#f92672",
            keywords: "#8c54fe",
            functions: "#f4fd22",
            constants: "#2757d6",
            variables: "#38c8b5",
            variableUsage: "#8c54fe",
            assignment: "#f92672",
            currency: "#4df840",
            units: "#38c8b5",
            results: "#4df840",
            comments: "#505354"
        )
    ),
    Theme(
        name: "The Hulk",
        syntax: SyntaxColors(
            text: "#b5b5b5",
            background: "#1b1d1e",
            numbers: "#2525f5",
            operators: "#269d1b",
            keywords: "#712c80",
            functions: "#63e457",
            constants: "#2525f5",
            variables: "#378ca9",
            variableUsage: "#712c80",
            assignment: "#269d1b",
            currency: "#13ce30",
            units: "#378ca9",
            results: "#13ce30",
            comments: "#505354"
        )
    ),
    Theme(
        name: "Tinacious Design Dark",
        syntax: SyntaxColors(
            text: "#cbcbf0",
            background: "#1d1d26",
            numbers: "#00cbff",
            operators: "#ff3399",
            keywords: "#cc66ff",
            functions: "#ffcc66",
            constants: "#00cbff",
            variables: "#00ceca",
            variableUsage: "#cc66ff",
            assignment: "#ff3399",
            currency: "#00d364",
            units: "#00ceca",
            results: "#00d364",
            comments: "#636667"
        )
    ),
    Theme(
        name: "Tinacious Design Light",
        syntax: SyntaxColors(
            text: "#1d1d26",
            background: "#f8f8ff",
            numbers: "#00cbff",
            operators: "#ff3399",
            keywords: "#cc66ff",
            functions: "#e5b34d",
            constants: "#00cbff",
            variables: "#00ceca",
            variableUsage: "#cc66ff",
            assignment: "#ff3399",
            currency: "#00d364",
            units: "#00ceca",
            results: "#00d364",
            comments: "#636667"
        )
    ),
    Theme(
        name: "TokyoNight",
        syntax: SyntaxColors(
            text: "#c0caf5",
            background: "#1a1b26",
            numbers: "#7aa2f7",
            operators: "#f7768e",
            keywords: "#bb9af7",
            functions: "#e0af68",
            constants: "#7aa2f7",
            variables: "#7dcfff",
            variableUsage: "#bb9af7",
            assignment: "#f7768e",
            currency: "#9ece6a",
            units: "#7dcfff",
            results: "#9ece6a",
            comments: "#414868"
        )
    ),
    Theme(
        name: "TokyoNight Day",
        syntax: SyntaxColors(
            text: "#3760bf",
            background: "#e1e2e7",
            numbers: "#2e7de9",
            operators: "#f52a65",
            keywords: "#9854f1",
            functions: "#8c6c3e",
            constants: "#2e7de9",
            variables: "#007197",
            variableUsage: "#9854f1",
            assignment: "#f52a65",
            currency: "#587539",
            units: "#007197",
            results: "#587539",
            comments: "#a1a6c5"
        )
    ),
    Theme(
        name: "TokyoNight Moon",
        syntax: SyntaxColors(
            text: "#c8d3f5",
            background: "#222436",
            numbers: "#82aaff",
            operators: "#ff757f",
            keywords: "#c099ff",
            functions: "#ffc777",
            constants: "#82aaff",
            variables: "#86e1fc",
            variableUsage: "#c099ff",
            assignment: "#ff757f",
            currency: "#c3e88d",
            units: "#86e1fc",
            results: "#c3e88d",
            comments: "#444a73"
        )
    ),
    Theme(
        name: "TokyoNight Night",
        syntax: SyntaxColors(
            text: "#c0caf5",
            background: "#1a1b26",
            numbers: "#7aa2f7",
            operators: "#f7768e",
            keywords: "#bb9af7",
            functions: "#e0af68",
            constants: "#7aa2f7",
            variables: "#7dcfff",
            variableUsage: "#bb9af7",
            assignment: "#f7768e",
            currency: "#9ece6a",
            units: "#7dcfff",
            results: "#9ece6a",
            comments: "#414868"
        )
    ),
    Theme(
        name: "TokyoNight Storm",
        syntax: SyntaxColors(
            text: "#c0caf5",
            background: "#24283b",
            numbers: "#7aa2f7",
            operators: "#f7768e",
            keywords: "#bb9af7",
            functions: "#e0af68",
            constants: "#7aa2f7",
            variables: "#7dcfff",
            variableUsage: "#bb9af7",
            assignment: "#f7768e",
            currency: "#9ece6a",
            units: "#7dcfff",
            results: "#9ece6a",
            comments: "#4e5575"
        )
    ),
    Theme(
        name: "Tomorrow",
        syntax: SyntaxColors(
            text: "#4d4d4c",
            background: "#ffffff",
            numbers: "#4271ae",
            operators: "#c82829",
            keywords: "#8959a8",
            functions: "#eab700",
            constants: "#4271ae",
            variables: "#3e999f",
            variableUsage: "#8959a8",
            assignment: "#c82829",
            currency: "#718c00",
            units: "#3e999f",
            results: "#718c00",
            comments: "#000000"
        )
    ),
    Theme(
        name: "Tomorrow Night",
        syntax: SyntaxColors(
            text: "#c5c8c6",
            background: "#1d1f21",
            numbers: "#81a2be",
            operators: "#cc6666",
            keywords: "#b294bb",
            functions: "#f0c674",
            constants: "#81a2be",
            variables: "#8abeb7",
            variableUsage: "#b294bb",
            assignment: "#cc6666",
            currency: "#b5bd68",
            units: "#8abeb7",
            results: "#b5bd68",
            comments: "#4c4c4c"
        )
    ),
    Theme(
        name: "Tomorrow Night Blue",
        syntax: SyntaxColors(
            text: "#ffffff",
            background: "#002451",
            numbers: "#bbdaff",
            operators: "#ff9da4",
            keywords: "#ebbbff",
            functions: "#ffeead",
            constants: "#bbdaff",
            variables: "#99ffff",
            variableUsage: "#ebbbff",
            assignment: "#ff9da4",
            currency: "#d1f1a9",
            units: "#99ffff",
            results: "#d1f1a9",
            comments: "#4c4c4c"
        )
    ),
    Theme(
        name: "Tomorrow Night Bright",
        syntax: SyntaxColors(
            text: "#eaeaea",
            background: "#000000",
            numbers: "#7aa6da",
            operators: "#d54e53",
            keywords: "#c397d8",
            functions: "#e7c547",
            constants: "#7aa6da",
            variables: "#70c0b1",
            variableUsage: "#c397d8",
            assignment: "#d54e53",
            currency: "#b9ca4a",
            units: "#70c0b1",
            results: "#b9ca4a",
            comments: "#404040"
        )
    ),
    Theme(
        name: "Tomorrow Night Burns",
        syntax: SyntaxColors(
            text: "#a1b0b8",
            background: "#151515",
            numbers: "#fc595f",
            operators: "#832e31",
            keywords: "#df9395",
            functions: "#d3494e",
            constants: "#fc595f",
            variables: "#ba8586",
            variableUsage: "#df9395",
            assignment: "#832e31",
            currency: "#a63c40",
            units: "#ba8586",
            results: "#a63c40",
            comments: "#5d6f71"
        )
    ),
    Theme(
        name: "Tomorrow Night Eighties",
        syntax: SyntaxColors(
            text: "#cccccc",
            background: "#2d2d2d",
            numbers: "#6699cc",
            operators: "#f2777a",
            keywords: "#cc99cc",
            functions: "#ffcc66",
            constants: "#6699cc",
            variables: "#66cccc",
            variableUsage: "#cc99cc",
            assignment: "#f2777a",
            currency: "#99cc99",
            units: "#66cccc",
            results: "#99cc99",
            comments: "#595959"
        )
    ),
    Theme(
        name: "Toy Chest",
        syntax: SyntaxColors(
            text: "#31d07b",
            background: "#24364b",
            numbers: "#325d96",
            operators: "#be2d26",
            keywords: "#8a5edc",
            functions: "#db8e27",
            constants: "#325d96",
            variables: "#35a08f",
            variableUsage: "#8a5edc",
            assignment: "#be2d26",
            currency: "#1a9172",
            units: "#35a08f",
            results: "#1a9172",
            comments: "#336889"
        )
    ),
    Theme(
        name: "Treehouse",
        syntax: SyntaxColors(
            text: "#786b53",
            background: "#191919",
            numbers: "#58859a",
            operators: "#b2270e",
            keywords: "#97363d",
            functions: "#aa820c",
            constants: "#58859a",
            variables: "#b25a1e",
            variableUsage: "#97363d",
            assignment: "#b2270e",
            currency: "#44a900",
            units: "#b25a1e",
            results: "#44a900",
            comments: "#504332"
        )
    ),
    Theme(
        name: "Twilight",
        syntax: SyntaxColors(
            text: "#ffffd4",
            background: "#141414",
            numbers: "#44474a",
            operators: "#c06d44",
            keywords: "#b4be7c",
            functions: "#c2a86c",
            constants: "#44474a",
            variables: "#778385",
            variableUsage: "#b4be7c",
            assignment: "#c06d44",
            currency: "#afb97a",
            units: "#778385",
            results: "#afb97a",
            comments: "#404040"
        )
    ),
    Theme(
        name: "Ubuntu",
        syntax: SyntaxColors(
            text: "#eeeeec",
            background: "#300a24",
            numbers: "#3465a4",
            operators: "#cc0000",
            keywords: "#75507b",
            functions: "#c4a000",
            constants: "#3465a4",
            variables: "#06989a",
            variableUsage: "#75507b",
            assignment: "#cc0000",
            currency: "#4e9a06",
            units: "#06989a",
            results: "#4e9a06",
            comments: "#555753"
        )
    ),
    Theme(
        name: "Ultra Dark",
        syntax: SyntaxColors(
            text: "#ffffff",
            background: "#000000",
            numbers: "#82aaff",
            operators: "#f07178",
            keywords: "#c792ea",
            functions: "#ffcb6b",
            constants: "#82aaff",
            variables: "#89ddff",
            variableUsage: "#c792ea",
            assignment: "#f07178",
            currency: "#c3e88d",
            units: "#89ddff",
            results: "#c3e88d",
            comments: "#404040"
        )
    ),
    Theme(
        name: "Ultra Violent",
        syntax: SyntaxColors(
            text: "#c1c1c1",
            background: "#242728",
            numbers: "#47e0fb",
            operators: "#ff0090",
            keywords: "#d731ff",
            functions: "#fff727",
            constants: "#47e0fb",
            variables: "#0effbb",
            variableUsage: "#d731ff",
            assignment: "#ff0090",
            currency: "#b6ff00",
            units: "#0effbb",
            results: "#b6ff00",
            comments: "#636667"
        )
    ),
    Theme(
        name: "Under The Sea",
        syntax: SyntaxColors(
            text: "#ffffff",
            background: "#011116",
            numbers: "#459a86",
            operators: "#b2302d",
            keywords: "#00599d",
            functions: "#59819c",
            constants: "#459a86",
            variables: "#5d7e19",
            variableUsage: "#00599d",
            assignment: "#b2302d",
            currency: "#00a941",
            units: "#5d7e19",
            results: "#00a941",
            comments: "#384451"
        )
    ),
    Theme(
        name: "Unikitty",
        syntax: SyntaxColors(
            text: "#0b0b0b",
            background: "#ff8cd9",
            numbers: "#145fcd",
            operators: "#a80f20",
            keywords: "#ffe9ff",
            functions: "#fff965",
            constants: "#145fcd",
            variables: "#9effef",
            variableUsage: "#ffe9ff",
            assignment: "#a80f20",
            currency: "#c7ff98",
            units: "#9effef",
            results: "#c7ff98",
            comments: "#434343"
        )
    ),
    Theme(
        name: "Urple",
        syntax: SyntaxColors(
            text: "#877a9b",
            background: "#1b1b23",
            numbers: "#564d9b",
            operators: "#b0425b",
            keywords: "#6c3ca1",
            functions: "#ad5c42",
            constants: "#564d9b",
            variables: "#808080",
            variableUsage: "#6c3ca1",
            assignment: "#b0425b",
            currency: "#37a415",
            units: "#808080",
            results: "#37a415",
            comments: "#693e32"
        )
    ),
    Theme(
        name: "Vague",
        syntax: SyntaxColors(
            text: "#cdcdcd",
            background: "#141415",
            numbers: "#7e98e8",
            operators: "#df6882",
            keywords: "#c3c3d5",
            functions: "#f3be7c",
            constants: "#7e98e8",
            variables: "#9bb4bc",
            variableUsage: "#c3c3d5",
            assignment: "#df6882",
            currency: "#8cb66d",
            units: "#9bb4bc",
            results: "#8cb66d",
            comments: "#878787"
        )
    ),
    Theme(
        name: "Vaughn",
        syntax: SyntaxColors(
            text: "#dcdccc",
            background: "#25234f",
            numbers: "#5555ff",
            operators: "#705050",
            keywords: "#f08cc3",
            functions: "#dfaf8f",
            constants: "#5555ff",
            variables: "#8cd0d3",
            variableUsage: "#f08cc3",
            assignment: "#705050",
            currency: "#60b48a",
            units: "#8cd0d3",
            results: "#60b48a",
            comments: "#709080"
        )
    ),
    Theme(
        name: "Vercel",
        syntax: SyntaxColors(
            text: "#fafafa",
            background: "#101010",
            numbers: "#006aff",
            operators: "#fc0036",
            keywords: "#f32882",
            functions: "#ffae00",
            constants: "#006aff",
            variables: "#00ac96",
            variableUsage: "#f32882",
            assignment: "#fc0036",
            currency: "#29a948",
            units: "#00ac96",
            results: "#29a948",
            comments: "#a8a8a8"
        )
    ),
    Theme(
        name: "Vesper",
        syntax: SyntaxColors(
            text: "#ffffff",
            background: "#101010",
            numbers: "#aca1cf",
            operators: "#f5a191",
            keywords: "#e29eca",
            functions: "#e6b99d",
            constants: "#aca1cf",
            variables: "#ea83a5",
            variableUsage: "#e29eca",
            assignment: "#f5a191",
            currency: "#90b99f",
            units: "#ea83a5",
            results: "#90b99f",
            comments: "#7e7e7e"
        )
    ),
    Theme(
        name: "Vibrant Ink",
        syntax: SyntaxColors(
            text: "#ffffff",
            background: "#000000",
            numbers: "#44b4cc",
            operators: "#ff6600",
            keywords: "#9933cc",
            functions: "#ffcc00",
            constants: "#44b4cc",
            variables: "#44b4cc",
            variableUsage: "#9933cc",
            assignment: "#ff6600",
            currency: "#ccff04",
            units: "#44b4cc",
            results: "#ccff04",
            comments: "#555555"
        )
    ),
    Theme(
        name: "Vimbones",
        syntax: SyntaxColors(
            text: "#353535",
            background: "#f0f0ca",
            numbers: "#286486",
            operators: "#a8334c",
            keywords: "#88507d",
            functions: "#944927",
            constants: "#286486",
            variables: "#3b8992",
            variableUsage: "#88507d",
            assignment: "#a8334c",
            currency: "#4f6c31",
            units: "#3b8992",
            results: "#4f6c31",
            comments: "#acac89"
        )
    ),
    Theme(
        name: "Violet Dark",
        syntax: SyntaxColors(
            text: "#708284",
            background: "#1c1d1f",
            numbers: "#2e8bce",
            operators: "#c94c22",
            keywords: "#d13a82",
            functions: "#b4881d",
            constants: "#2e8bce",
            variables: "#32a198",
            variableUsage: "#d13a82",
            assignment: "#c94c22",
            currency: "#85981c",
            units: "#32a198",
            results: "#85981c",
            comments: "#45484b"
        )
    ),
    Theme(
        name: "Violet Light",
        syntax: SyntaxColors(
            text: "#536870",
            background: "#fcf4dc",
            numbers: "#2e8bce",
            operators: "#c94c22",
            keywords: "#d13a82",
            functions: "#b4881d",
            constants: "#2e8bce",
            variables: "#32a198",
            variableUsage: "#d13a82",
            assignment: "#c94c22",
            currency: "#85981c",
            units: "#32a198",
            results: "#85981c",
            comments: "#45484b"
        )
    ),
    Theme(
        name: "Violite",
        syntax: SyntaxColors(
            text: "#eef4f6",
            background: "#241c36",
            numbers: "#a979ec",
            operators: "#ec7979",
            keywords: "#ec79ec",
            functions: "#ece279",
            constants: "#a979ec",
            variables: "#79ecec",
            variableUsage: "#ec79ec",
            assignment: "#ec7979",
            currency: "#79ecb3",
            units: "#79ecec",
            results: "#79ecb3",
            comments: "#554379"
        )
    ),
    Theme(
        name: "Warm Neon",
        syntax: SyntaxColors(
            text: "#afdab6",
            background: "#404040",
            numbers: "#4261c5",
            operators: "#e24346",
            keywords: "#f920fb",
            functions: "#dae145",
            constants: "#4261c5",
            variables: "#2abbd4",
            variableUsage: "#f920fb",
            assignment: "#e24346",
            currency: "#39b13a",
            units: "#2abbd4",
            results: "#39b13a",
            comments: "#fefcfc"
        )
    ),
    Theme(
        name: "Wez",
        syntax: SyntaxColors(
            text: "#b3b3b3",
            background: "#000000",
            numbers: "#5555cc",
            operators: "#cc5555",
            keywords: "#cc55cc",
            functions: "#cdcd55",
            constants: "#5555cc",
            variables: "#7acaca",
            variableUsage: "#cc55cc",
            assignment: "#cc5555",
            currency: "#55cc55",
            units: "#7acaca",
            results: "#55cc55",
            comments: "#555555"
        )
    ),
    Theme(
        name: "Whimsy",
        syntax: SyntaxColors(
            text: "#b3b0d6",
            background: "#29283b",
            numbers: "#65aef7",
            operators: "#ef6487",
            keywords: "#aa7ff0",
            functions: "#fdd877",
            constants: "#65aef7",
            variables: "#43c1be",
            variableUsage: "#aa7ff0",
            assignment: "#ef6487",
            currency: "#5eca89",
            units: "#43c1be",
            results: "#5eca89",
            comments: "#535178"
        )
    ),
    Theme(
        name: "Wild Cherry",
        syntax: SyntaxColors(
            text: "#dafaff",
            background: "#1f1726",
            numbers: "#883cdc",
            operators: "#d94085",
            keywords: "#ececec",
            functions: "#ffd16f",
            constants: "#883cdc",
            variables: "#c1b8b7",
            variableUsage: "#ececec",
            assignment: "#d94085",
            currency: "#2ab250",
            units: "#c1b8b7",
            results: "#2ab250",
            comments: "#009cc9"
        )
    ),
    Theme(
        name: "Wilmersdorf",
        syntax: SyntaxColors(
            text: "#c6c6c6",
            background: "#282b33",
            numbers: "#a6c1e0",
            operators: "#e06383",
            keywords: "#e1c1ee",
            functions: "#cccccc",
            constants: "#a6c1e0",
            variables: "#5b94ab",
            variableUsage: "#e1c1ee",
            assignment: "#e06383",
            currency: "#7ebebd",
            units: "#5b94ab",
            results: "#7ebebd",
            comments: "#50545d"
        )
    ),
    Theme(
        name: "Wombat",
        syntax: SyntaxColors(
            text: "#dedacf",
            background: "#171717",
            numbers: "#5da9f6",
            operators: "#ff615a",
            keywords: "#e86aff",
            functions: "#ebd99c",
            constants: "#5da9f6",
            variables: "#82fff7",
            variableUsage: "#e86aff",
            assignment: "#ff615a",
            currency: "#b1e969",
            units: "#82fff7",
            results: "#b1e969",
            comments: "#4b4b4b"
        )
    ),
    Theme(
        name: "Wryan",
        syntax: SyntaxColors(
            text: "#999993",
            background: "#101010",
            numbers: "#395573",
            operators: "#8c4665",
            keywords: "#5e468c",
            functions: "#7c7c99",
            constants: "#395573",
            variables: "#31658c",
            variableUsage: "#5e468c",
            assignment: "#8c4665",
            currency: "#287373",
            units: "#31658c",
            results: "#287373",
            comments: "#3d3d3d"
        )
    ),
    Theme(
        name: "Xcode Dark",
        syntax: SyntaxColors(
            text: "#dfdfe0",
            background: "#292a30",
            numbers: "#4eb0cc",
            operators: "#ff8170",
            keywords: "#ff7ab2",
            functions: "#d9c97c",
            constants: "#4eb0cc",
            variables: "#b281eb",
            variableUsage: "#ff7ab2",
            assignment: "#ff8170",
            currency: "#78c2b3",
            units: "#b281eb",
            results: "#78c2b3",
            comments: "#7f8c98"
        )
    ),
    Theme(
        name: "Xcode Dark hc",
        syntax: SyntaxColors(
            text: "#ffffff",
            background: "#1f1f24",
            numbers: "#4ec4e6",
            operators: "#ff8a7a",
            keywords: "#ff85b8",
            functions: "#d9c668",
            constants: "#4ec4e6",
            variables: "#cda1ff",
            variableUsage: "#ff85b8",
            assignment: "#ff8a7a",
            currency: "#83c9bc",
            units: "#cda1ff",
            results: "#83c9bc",
            comments: "#838991"
        )
    ),
    Theme(
        name: "Xcode Light",
        syntax: SyntaxColors(
            text: "#262626",
            background: "#ffffff",
            numbers: "#0f68a0",
            operators: "#d12f1b",
            keywords: "#ad3da4",
            functions: "#78492a",
            constants: "#0f68a0",
            variables: "#804fb8",
            variableUsage: "#ad3da4",
            assignment: "#d12f1b",
            currency: "#3e8087",
            units: "#804fb8",
            results: "#3e8087",
            comments: "#8a99a6"
        )
    ),
    Theme(
        name: "Xcode Light hc",
        syntax: SyntaxColors(
            text: "#000000",
            background: "#ffffff",
            numbers: "#0058a1",
            operators: "#ad1805",
            keywords: "#9c2191",
            functions: "#78492a",
            constants: "#0058a1",
            variables: "#703daa",
            variableUsage: "#9c2191",
            assignment: "#ad1805",
            currency: "#355d61",
            units: "#703daa",
            results: "#355d61",
            comments: "#8a99a6"
        )
    ),
    Theme(
        name: "Xcode WWDC",
        syntax: SyntaxColors(
            text: "#e7e8eb",
            background: "#292c36",
            numbers: "#8884c5",
            operators: "#bb383a",
            keywords: "#b73999",
            functions: "#d28e5d",
            constants: "#8884c5",
            variables: "#00aba4",
            variableUsage: "#b73999",
            assignment: "#bb383a",
            currency: "#94c66e",
            units: "#00aba4",
            results: "#94c66e",
            comments: "#7f869e"
        )
    ),
    Theme(
        name: "Zenbones",
        syntax: SyntaxColors(
            text: "#2c363c",
            background: "#f0edec",
            numbers: "#286486",
            operators: "#a8334c",
            keywords: "#88507d",
            functions: "#944927",
            constants: "#286486",
            variables: "#3b8992",
            variableUsage: "#88507d",
            assignment: "#a8334c",
            currency: "#4f6c31",
            units: "#3b8992",
            results: "#4f6c31",
            comments: "#b5a7a0"
        )
    ),
    Theme(
        name: "Zenbones Dark",
        syntax: SyntaxColors(
            text: "#b4bdc3",
            background: "#1c1917",
            numbers: "#6099c0",
            operators: "#de6e7c",
            keywords: "#b279a7",
            functions: "#b77e64",
            constants: "#6099c0",
            variables: "#66a5ad",
            variableUsage: "#b279a7",
            assignment: "#de6e7c",
            currency: "#819b69",
            units: "#66a5ad",
            results: "#819b69",
            comments: "#4d4540"
        )
    ),
    Theme(
        name: "Zenbones Light",
        syntax: SyntaxColors(
            text: "#2c363c",
            background: "#f0edec",
            numbers: "#286486",
            operators: "#a8334c",
            keywords: "#88507d",
            functions: "#944927",
            constants: "#286486",
            variables: "#3b8992",
            variableUsage: "#88507d",
            assignment: "#a8334c",
            currency: "#4f6c31",
            units: "#3b8992",
            results: "#4f6c31",
            comments: "#b5a7a0"
        )
    ),
    Theme(
        name: "Zenburn",
        syntax: SyntaxColors(
            text: "#dcdccc",
            background: "#3f3f3f",
            numbers: "#5d6d7d",
            operators: "#7d5d5d",
            keywords: "#dc8cc3",
            functions: "#f0dfaf",
            constants: "#5d6d7d",
            variables: "#8cd0d3",
            variableUsage: "#dc8cc3",
            assignment: "#7d5d5d",
            currency: "#60b48a",
            units: "#8cd0d3",
            results: "#60b48a",
            comments: "#709080"
        )
    ),
    Theme(
        name: "Zenburned",
        syntax: SyntaxColors(
            text: "#f0e4cf",
            background: "#404040",
            numbers: "#6099c0",
            operators: "#e3716e",
            keywords: "#b279a7",
            functions: "#b77e64",
            constants: "#6099c0",
            variables: "#66a5ad",
            variableUsage: "#b279a7",
            assignment: "#e3716e",
            currency: "#819b69",
            units: "#66a5ad",
            results: "#819b69",
            comments: "#6f6768"
        )
    ),
    Theme(
        name: "Zenwritten Dark",
        syntax: SyntaxColors(
            text: "#bbbbbb",
            background: "#191919",
            numbers: "#6099c0",
            operators: "#de6e7c",
            keywords: "#b279a7",
            functions: "#b77e64",
            constants: "#6099c0",
            variables: "#66a5ad",
            variableUsage: "#b279a7",
            assignment: "#de6e7c",
            currency: "#819b69",
            units: "#66a5ad",
            results: "#819b69",
            comments: "#4a4546"
        )
    ),
    Theme(
        name: "Zenwritten Light",
        syntax: SyntaxColors(
            text: "#353535",
            background: "#eeeeee",
            numbers: "#286486",
            operators: "#a8334c",
            keywords: "#88507d",
            functions: "#944927",
            constants: "#286486",
            variables: "#3b8992",
            variableUsage: "#88507d",
            assignment: "#a8334c",
            currency: "#4f6c31",
            units: "#3b8992",
            results: "#4f6c31",
            comments: "#aca9a9"
        )
    ),
    Theme(
        name: "iTerm2 Dark Background",
        syntax: SyntaxColors(
            text: "#c7c7c7",
            background: "#000000",
            numbers: "#0225c7",
            operators: "#c91b00",
            keywords: "#ca30c7",
            functions: "#c7c400",
            constants: "#0225c7",
            variables: "#00c5c7",
            variableUsage: "#ca30c7",
            assignment: "#c91b00",
            currency: "#00c200",
            units: "#00c5c7",
            results: "#00c200",
            comments: "#686868"
        )
    ),
    Theme(
        name: "iTerm2 Default",
        syntax: SyntaxColors(
            text: "#ffffff",
            background: "#000000",
            numbers: "#2225c4",
            operators: "#c91b00",
            keywords: "#ca30c7",
            functions: "#c7c400",
            constants: "#2225c4",
            variables: "#00c5c7",
            variableUsage: "#ca30c7",
            assignment: "#c91b00",
            currency: "#00c200",
            units: "#00c5c7",
            results: "#00c200",
            comments: "#686868"
        )
    ),
    Theme(
        name: "iTerm2 Light Background",
        syntax: SyntaxColors(
            text: "#000000",
            background: "#ffffff",
            numbers: "#0225c7",
            operators: "#c91b00",
            keywords: "#ca30c7",
            functions: "#c7c400",
            constants: "#0225c7",
            variables: "#00c5c7",
            variableUsage: "#ca30c7",
            assignment: "#c91b00",
            currency: "#00c200",
            units: "#00c5c7",
            results: "#00c200",
            comments: "#686868"
        )
    ),
    Theme(
        name: "iTerm2 Pastel Dark Background",
        syntax: SyntaxColors(
            text: "#c7c7c7",
            background: "#000000",
            numbers: "#a5d5fe",
            operators: "#ff8373",
            keywords: "#ff90fe",
            functions: "#fffdc3",
            constants: "#a5d5fe",
            variables: "#d1d1fe",
            variableUsage: "#ff90fe",
            assignment: "#ff8373",
            currency: "#b4fb73",
            units: "#d1d1fe",
            results: "#b4fb73",
            comments: "#8f8f8f"
        )
    ),
    Theme(
        name: "iTerm2 Smoooooth",
        syntax: SyntaxColors(
            text: "#dcdcdc",
            background: "#15191f",
            numbers: "#2744c7",
            operators: "#b43c2a",
            keywords: "#c040be",
            functions: "#c7c400",
            constants: "#2744c7",
            variables: "#00c5c7",
            variableUsage: "#c040be",
            assignment: "#b43c2a",
            currency: "#00c200",
            units: "#00c5c7",
            results: "#00c200",
            comments: "#686868"
        )
    ),
    Theme(
        name: "iTerm2 Solarized Dark",
        syntax: SyntaxColors(
            text: "#839496",
            background: "#002b36",
            numbers: "#268bd2",
            operators: "#dc322f",
            keywords: "#d33682",
            functions: "#b58900",
            constants: "#268bd2",
            variables: "#2aa198",
            variableUsage: "#d33682",
            assignment: "#dc322f",
            currency: "#859900",
            units: "#2aa198",
            results: "#859900",
            comments: "#335e69"
        )
    ),
    Theme(
        name: "iTerm2 Solarized Light",
        syntax: SyntaxColors(
            text: "#657b83",
            background: "#fdf6e3",
            numbers: "#268bd2",
            operators: "#dc322f",
            keywords: "#d33682",
            functions: "#b58900",
            constants: "#268bd2",
            variables: "#2aa198",
            variableUsage: "#d33682",
            assignment: "#dc322f",
            currency: "#859900",
            units: "#2aa198",
            results: "#859900",
            comments: "#002b36"
        )
    ),
    Theme(
        name: "iTerm2 Tango Dark",
        syntax: SyntaxColors(
            text: "#ffffff",
            background: "#000000",
            numbers: "#427ab3",
            operators: "#d81e00",
            keywords: "#89658e",
            functions: "#cfae00",
            constants: "#427ab3",
            variables: "#00a7aa",
            variableUsage: "#89658e",
            assignment: "#d81e00",
            currency: "#5ea702",
            units: "#00a7aa",
            results: "#5ea702",
            comments: "#686a66"
        )
    ),
    Theme(
        name: "iTerm2 Tango Light",
        syntax: SyntaxColors(
            text: "#000000",
            background: "#ffffff",
            numbers: "#427ab3",
            operators: "#d81e00",
            keywords: "#89658e",
            functions: "#cfae00",
            constants: "#427ab3",
            variables: "#00a7aa",
            variableUsage: "#89658e",
            assignment: "#d81e00",
            currency: "#5ea702",
            units: "#00a7aa",
            results: "#5ea702",
            comments: "#686a66"
        )
    ),
    ]
}
