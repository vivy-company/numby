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

    init() {
        context = libnumby_context_new()
        setup()
    }

    private func setup() {
        // Load config.json (copy from Rust root to your app's Resources if desired)
        if let configPath = Bundle.main.path(forResource: "config", ofType: "json") {
            configPath.withCString { cPath in
                _ = libnumby_load_config(context, cPath)
            }
        }
        // Set locale
        let locale = Locale.current.language.languageCode?.identifier ?? "en-US"
        locale.withCString { cLocale in
            _ = libnumby_set_locale(context, cLocale)
        }

        // Check if rates are stale and update in background if needed
        updateCurrencyRatesIfStale()
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