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

    /// Preferred locale (language code like "en-US", "fr", etc.)
    var locale: String? = nil

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
    @Published var currentLocale: String = "en-US"

    private init() {
        self.config = AppConfiguration.load()
        self.currentLocale = config.locale ?? "en-US"
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

    /// Update locale and trigger UI refresh
    func updateLocale(_ newLocale: String) {
        // Map Rust locale to Swift locale
        let swiftLocale: String
        switch newLocale {
        case "zh-CN":
            swiftLocale = "zh-Hans"
        case "zh-TW":
            swiftLocale = "zh-Hant"
        case "en-US":
            swiftLocale = "en"
        default:
            swiftLocale = newLocale
        }

        // Update UserDefaults
        UserDefaults.standard.set([swiftLocale], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()

        // Update published property to trigger UI refresh
        self.currentLocale = newLocale
        self.objectWillChange.send()
    }

    /// Get localized string that reacts to locale changes
    func localizedString(_ key: String, comment: String = "") -> String {
        // Map Rust locale to Swift locale
        let swiftLocale: String
        switch currentLocale {
        case "zh-CN":
            swiftLocale = "zh-Hans"
        case "zh-TW":
            swiftLocale = "zh-Hant"
        case "en-US":
            swiftLocale = "en"
        default:
            swiftLocale = currentLocale
        }

        // Get the appropriate bundle path for the locale
        guard let bundlePath = Bundle.main.path(forResource: swiftLocale, ofType: "lproj"),
              let bundle = Bundle(path: bundlePath) else {
            // Fallback to English
            if let enPath = Bundle.main.path(forResource: "en", ofType: "lproj"),
               let enBundle = Bundle(path: enPath) {
                return enBundle.localizedString(forKey: key, value: key, table: nil)
            }
            return key
        }

        // Get localized string from the locale-specific bundle
        let localized = bundle.localizedString(forKey: key, value: nil, table: nil)
        // If the key wasn't found in this locale, the bundle returns the key itself
        // In that case, fall back to English
        if localized == key {
            if let enPath = Bundle.main.path(forResource: "en", ofType: "lproj"),
               let enBundle = Bundle(path: enPath) {
                return enBundle.localizedString(forKey: key, value: key, table: nil)
            }
        }
        return localized
    }
}

// MARK: - Localization Helper

extension String {
    /// Get localized string using current app locale
    func localized(comment: String = "") -> String {
        return ConfigurationManager.shared.localizedString(self, comment: comment)
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
