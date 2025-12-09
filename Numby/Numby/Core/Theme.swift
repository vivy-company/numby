//
//  Theme.swift
//  Numby
//
//  Theme definitions and color management
//

import Foundation
import Combine
import SwiftUI

#if os(macOS)
import AppKit
typealias PlatformApplication = NSApplication
#elseif os(iOS) || os(visionOS)
import UIKit
typealias PlatformApplication = UIApplication
#endif

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

    /// Current active theme
    static var current: Theme {
        get {
            let savedThemeName = UserDefaults.standard.string(forKey: "selectedTheme")
            if let themeName = savedThemeName,
               let theme = Theme.allThemes.first(where: { $0.name == themeName }) {
                return theme
            }
            return CatppuccinTheme.mocha.theme
        }
        set {
            UserDefaults.standard.set(newValue.name, forKey: "selectedTheme")
            applyTheme(newValue)
        }
    }

    /// Apply theme to the application
    private static func applyTheme(_ theme: Theme) {
        guard let bgColor = PlatformColor(hex: theme.syntax.background) else {
            return
        }

        // Update configuration
        var updatedConfig = Configuration.shared.config
        updatedConfig.backgroundColor = bgColor
        Configuration.shared.config = updatedConfig
        Configuration.shared.save()

        #if os(macOS)
        // Update all windows on macOS
        for window in PlatformApplication.shared.windows.compactMap({ $0 as? NumbyWindow }) {
            DispatchQueue.main.async { [weak window] in
                guard let window = window else { return }

                window.updateBackgroundColor(bgColor)

                window.controller?.objectWillChange.send()
                for (_, calculator) in window.controller?.calculators ?? [:] {
                    calculator.objectWillChange.send()
                }
            }
        }
        #endif
    }

    /// Get background color
    var backgroundColor: PlatformColor {
        #if os(macOS)
        return PlatformColor(hex: syntax.background) ?? .windowBackgroundColor
        #elseif os(iOS) || os(visionOS)
        return PlatformColor(hex: syntax.background) ?? .systemBackground
        #endif
    }

    /// Get text color
    var textColor: PlatformColor {
        #if os(macOS)
        return PlatformColor(hex: syntax.text) ?? .textColor
        #elseif os(iOS) || os(visionOS)
        return PlatformColor(hex: syntax.text) ?? .label
        #endif
    }

    /// Get syntax color for a specific type
    func syntaxColor(for type: SyntaxColorType) -> PlatformColor {
        let hex: String

        switch type {
        case .text: hex = syntax.text
        case .background: hex = syntax.background
        case .numbers: hex = syntax.numbers
        case .operators: hex = syntax.operators
        case .keywords: hex = syntax.keywords
        case .functions: hex = syntax.functions
        case .constants: hex = syntax.constants
        case .variables: hex = syntax.variables
        case .variableUsage: hex = syntax.variableUsage
        case .assignment: hex = syntax.assignment
        case .currency: hex = syntax.currency
        case .units: hex = syntax.units
        case .results: hex = syntax.results
        case .comments: hex = syntax.comments
        }

        #if os(macOS)
        return PlatformColor(hex: hex) ?? .textColor
        #elseif os(iOS) || os(visionOS)
        return PlatformColor(hex: hex) ?? .label
        #endif
    }
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

enum SyntaxColorType {
    case text, background, numbers, operators, keywords, functions
    case constants, variables, variableUsage, assignment, currency, units, results, comments
}
