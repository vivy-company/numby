//
//  Theme.swift
//  Numby
//
//  Theme definitions and color management
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
                    assignment: "#EE99A0",     // Maroon
                    currency: "#A6DA95",       // Green
                    units: "#8BD5CA",          // Teal
                    results: "#A6DA95",        // Green
                    comments: "#5B6078"        // Surface2 (gray for comments)
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
                    assignment: "#EBA0AC",     // Maroon
                    currency: "#A6E3A1",       // Green
                    units: "#94E2D5",          // Teal
                    results: "#A6E3A1",        // Green
                    comments: "#585B70"        // Surface2 (gray for comments)
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
