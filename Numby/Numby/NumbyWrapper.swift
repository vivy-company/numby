//
//  NumbyWrapper.swift
//  Numby
//

import Foundation
import SwiftUI
import Combine

// Opaque types from libnumby.h
typealias NumbyContext = OpaquePointer

class NumbyWrapper: ObservableObject {
    @Published var lastResult: String = ""
    var context: NumbyContext?
    private var resolvedConfigPath: String?

    init() {
        context = libnumby_context_new()
        setup()
    }

    private func setup() {
        let configPath = loadOrSeedConfigPath() ?? Bundle.main.path(forResource: "config", ofType: "json")
        if let configPath {
            configPath.withCString { cPath in
                _ = libnumby_load_config(context, cPath)
            }
        }
        // Set locale (prioritize saved config, then system locale)
        let locale = Configuration.shared.config.locale ?? Locale.current.language.languageCode?.identifier ?? "en-US"
        locale.withCString { cLocale in
            _ = libnumby_set_locale(context, cLocale)
        }

        // Check if rates are stale and update in background if needed
        updateCurrencyRatesIfStale()
    }

    private func loadOrSeedConfigPath() -> String? {
        if let cached = resolvedConfigPath {
            return cached
        }

        guard let defaultPathPointer = libnumby_get_default_config_path() else {
            return nil
        }
        defer { libnumby_free_string(defaultPathPointer) }

        let path = String(cString: defaultPathPointer)
        if seedConfigFile(atPath: path) {
            resolvedConfigPath = path
            return path
        }
        return nil
    }

    private func seedConfigFile(atPath path: String) -> Bool {
        let fm = FileManager.default
        let configURL = URL(fileURLWithPath: path)
        let directory = configURL.deletingLastPathComponent()

        do {
            try fm.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            print("Failed to create config directory: \(error.localizedDescription)")
            return false
        }

        if !fm.fileExists(atPath: configURL.path) {
            guard let bundledURL = Bundle.main.url(forResource: "config", withExtension: "json") else {
                print("Bundled config.json missing")
                return false
            }
            do {
                try fm.copyItem(at: bundledURL, to: configURL)
            } catch {
                print("Failed to copy bundled config: \(error.localizedDescription)")
                return false
            }
        }

        return fm.fileExists(atPath: configURL.path)
    }

    /// Updates currency rates if they are stale (>24 hours old)
    func updateCurrencyRatesIfStale() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self, let ctx = self.context else { return }

            let stale = libnumby_are_rates_stale()
            if stale == 1 {
                print("Currency rates are stale, updating...")
                let result = libnumby_update_currency_rates(ctx)
                if result == 0 {
                    print("Currency rates updated successfully")
                    if let date = self.getCurrencyRatesUpdateDate() {
                        print("Rates updated on: \(date)")
                    }
                } else {
                    print("Failed to update currency rates, using cached values")
                }
            }
        }
    }

    /// Manually updates currency rates from the API
    /// - Returns: True if update succeeded, false otherwise
    func updateCurrencyRates() -> Bool {
        guard let ctx = context else { return false }
        let result = libnumby_update_currency_rates(ctx)
        return result == 0
    }

    /// Checks if currency rates are stale
    /// - Returns: True if stale or unknown, false if fresh
    func areCurrencyRatesStale() -> Bool {
        let result = libnumby_are_rates_stale()
        return result != 0 // Stale if 1 or error (-1)
    }

    /// Gets the date when currency rates were last updated
    /// - Returns: Date string in YYYY-MM-DD format, or nil if unavailable
    func getCurrencyRatesUpdateDate() -> String? {
        guard let cString = libnumby_get_rates_update_date() else {
            return nil
        }
        defer { libnumby_free_string(cString) }
        return String(cString: cString)
    }

    // MARK: - Localization

    /// Get current locale
    func getCurrentLocale() -> String {
        guard let cString = libnumby_get_locale() else {
            return "en-US"
        }
        defer { libnumby_free_string(cString) }
        return String(cString: cString)
    }

    /// Set current locale
    func setLocale(_ locale: String) -> Bool {
        guard let ctx = context else { return false }
        return locale.withCString { cLocale in
            libnumby_set_locale(ctx, cLocale) == 0
        }
    }

    /// Get list of available locales
    func getAvailableLocales() -> [(code: String, name: String)] {
        let count = libnumby_get_locales_count()
        var locales: [(String, String)] = []

        for i in 0..<count {
            guard let codePtr = libnumby_get_locale_code(i),
                  let namePtr = libnumby_get_locale_name(i) else {
                continue
            }
            defer {
                libnumby_free_string(codePtr)
                libnumby_free_string(namePtr)
            }

            let code = String(cString: codePtr)
            let name = String(cString: namePtr)
            locales.append((code, name))
        }

        return locales
    }

    func evaluate(_ input: String) -> (value: Double, formatted: String?, unit: String?, error: String?) {
        guard let ctx = context else { return (0.0, nil, nil, "No context") }

        var outFormatted: UnsafeMutablePointer<CChar>?
        var outUnit: UnsafeMutablePointer<CChar>?
        var outError: UnsafeMutablePointer<CChar>?

        let value = input.withCString { cInput in
            libnumby_evaluate(ctx, cInput, &outFormatted, &outUnit, &outError)
        }

        let formatted = outFormatted.flatMap { String(cString: $0) }
        let unit = outUnit.flatMap { String(cString: $0) }
        let error = outError.flatMap { String(cString: $0) }

        // Free Rust-allocated strings
        libnumby_free_string(outFormatted)
        libnumby_free_string(outUnit)
        libnumby_free_string(outError)

        if let error = error {
            lastResult = "Error: \(error)"
        } else {
            lastResult = formatted ?? "\(value) \(unit ?? "")"
        }

        return (value, formatted, unit, error)
    }

    func setVariable(name: String, value: Double, unit: String? = nil) {
        guard let ctx = context else { return }
        name.withCString { cName in
            if let unitStr = unit {
                unitStr.withCString { cUnit in
                    let success = libnumby_set_variable(ctx, cName, value, cUnit)
                    if success != 0 {
                        print("Failed to set variable \(name)")
                    }
                }
            } else {
                let success = libnumby_set_variable(ctx, cName, value, nil)
                if success != 0 {
                    print("Failed to set variable \(name)")
                }
            }
        }
    }

    func clearHistory() {
        guard let ctx = context else { return }
        let result = libnumby_clear_history(ctx)
        if result != 0 {
            print("Failed to clear history")
        }
    }

    func clearVariables() {
        guard let ctx = context else { return }
        let result = libnumby_clear_variables(ctx)
        if result != 0 {
            print("Failed to clear variables")
        }
    }

    func getHistoryCount() -> Int {
        guard let ctx = context else { return 0 }
        let count = libnumby_get_history_count(ctx)
        return count >= 0 ? Int(count) : 0
    }

    deinit {
        libnumby_context_free(context)
    }
}

// Convenience extension
extension NumbyWrapper {
    func calculate(_ input: String) -> String {
        _ = evaluate(input)
        return lastResult
    }

    /// Evaluate an expression and return the result string (for CalculatorInstance)
    func evaluate(expression: String) -> String? {
        let result = evaluate(expression)

        // Don't show errors, just return nil
        if result.error != nil {
            return nil
        }

        // The formatted string already includes the unit, don't append again
        if let formatted = result.formatted {
            return formatted
        }

        return nil
    }
}
