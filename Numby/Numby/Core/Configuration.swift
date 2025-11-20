//
//  Configuration.swift
//  Numby
//
//  App-wide configuration and preferences
//

import Foundation
#if os(macOS)
import AppKit
#else
import UIKit
#endif
import SwiftUI
import Combine

// MARK: - Platform Abstractions

#if os(macOS)
typealias PlatformColor = NSColor
#else
typealias PlatformColor = UIColor
#endif

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

    /// Background color as PlatformColor
    var backgroundColor: PlatformColor? {
        get {
            guard let hex = backgroundColorHex else { return nil }
            return PlatformColor(hex: hex)
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
class Configuration: ObservableObject {
    static let shared = Configuration()

    @Published var config: AppConfiguration
    @Published var currentLocale: String = "en-US"
    var locale: String? { config.locale }
    var fontSize: String { "Medium" }

    private init() {
        self.config = AppConfiguration.load()
        self.currentLocale = config.locale ?? "en-US"
    }

    func load() {
        config = AppConfiguration.load()
        currentLocale = config.locale ?? "en-US"
    }

    func save() {
        config.save()
        NotificationCenter.default.post(name: NSNotification.Name("ConfigurationDidChange"), object: nil)
    }

    func reset() {
        config = AppConfiguration()
        AppConfiguration.reset()
        NotificationCenter.default.post(name: NSNotification.Name("ConfigurationDidChange"), object: nil)
    }

    /// Update locale and trigger UI refresh
    func updateLocale(_ newLocale: String) {
        config.locale = newLocale
        self.currentLocale = newLocale
        self.objectWillChange.send()
        save()
    }
}

// MARK: - Localization Helper (for backward compatibility with macOS AppDelegate)
extension String {
    /// Returns the string itself (localization removed for now)
    var localized: String {
        return self
    }
}

// MARK: - PlatformColor Hex Extensions

extension PlatformColor {
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
        #if os(macOS)
        guard let rgb = self.usingColorSpace(.deviceRGB) else { return "#000000" }
        let r = Int(rgb.redComponent * 255.0)
        let g = Int(rgb.greenComponent * 255.0)
        let b = Int(rgb.blueComponent * 255.0)
        return String(format: "#%02X%02X%02X", r, g, b)
        #else
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        self.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255.0), Int(g * 255.0), Int(b * 255.0))
        #endif
    }
}
