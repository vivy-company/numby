//
//  Configuration.swift
//  Numby
//
//  App-wide configuration and preferences
//

import Foundation
import AppKit
import SwiftUI
import Combine

/// Global app configuration
struct AppConfiguration: Codable {
    /// Window restoration enabled
    var windowRestoration: Bool = true

    /// Default split ratio for calculator panels
    var defaultSplitRatio: Double = 0.5

    /// Tab bar style
    var tabBarStyle: TabBarStyle = .automatic

    /// Background color (hex string)
    var backgroundColorHex: String? = nil

    /// Background color as NSColor
    var backgroundColor: NSColor? {
        get {
            guard let hex = backgroundColorHex else { return nil }
            return NSColor(hex: hex)
        }
        set {
            backgroundColorHex = newValue?.hexString
        }
    }

    /// Font size for calculator input/results
    var fontSize: Double = 16.0

    /// Font name
    var fontName: String? = "SFMono-Regular"

    /// Enable syntax highlighting
    var syntaxHighlighting: Bool = true

    /// Auto-evaluate on input
    var autoEvaluate: Bool = true

    enum TabBarStyle: String, Codable {
        case automatic = "automatic"
        case unified = "unified"
        case expanded = "expanded"
        case native = "native"
    }

    // MARK: - Persistence

    private static let configKey = "NumbyAppConfiguration"

    /// Save configuration to UserDefaults
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.configKey)
        }
    }

    /// Load configuration from UserDefaults
    static func load() -> AppConfiguration {
        guard let data = UserDefaults.standard.data(forKey: configKey),
              let config = try? JSONDecoder().decode(AppConfiguration.self, from: data) else {
            return AppConfiguration()
        }
        return config
    }

    /// Reset to defaults
    static func reset() {
        UserDefaults.standard.removeObject(forKey: configKey)
    }
}

/// Global configuration manager
class ConfigurationManager: ObservableObject {
    static let shared = ConfigurationManager()

    @Published var config: AppConfiguration

    private init() {
        self.config = AppConfiguration.load()
    }

    func save() {
        config.save()
        notifyWindows()
    }

    func reset() {
        config = AppConfiguration()
        AppConfiguration.reset()
        notifyWindows()
    }

    private func notifyWindows() {
        for window in NSApplication.shared.windows.compactMap({ $0 as? NumbyWindow }) {
            DispatchQueue.main.async { [weak window] in
                guard let window = window else { return }

                window.controller?.objectWillChange.send()
                for (_, calculator) in window.controller?.calculators ?? [:] {
                    calculator.objectWillChange.send()
                }
            }
        }
    }

    /// Apply configuration to the app
    func apply() {
        // Apply window-level settings
        applyWindowSettings()
    }

    private func applyWindowSettings() {
        // Configure tab bar appearance if needed
        switch config.tabBarStyle {
        case .automatic:
            break // Use system default
        case .unified, .expanded, .native:
            // These would be applied per-window
            break
        }
    }
}

// MARK: - NSColor Hex Extensions

extension NSColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }

    var hexString: String {
        guard let rgb = self.usingColorSpace(.deviceRGB) else { return "#000000" }
        let r = Int(rgb.redComponent * 255.0)
        let g = Int(rgb.greenComponent * 255.0)
        let b = Int(rgb.blueComponent * 255.0)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
