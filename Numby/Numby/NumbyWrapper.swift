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
        let configPath = loadOrSeedConfigPath()
        if let configPath {
            configPath.withCString { cPath in
                _ = libnumby_load_config(context, cPath)
            }
        } else {
            // If we couldn't create a config file, try to load from current directory as fallback
            let currentDirConfig = "./config.json"
            if FileManager.default.fileExists(atPath: currentDirConfig) {
                currentDirConfig.withCString { cPath in
                    _ = libnumby_load_config(context, cPath)
                }
            }
            // If all else fails, the Rust library will use default config
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
        } else {
            return nil
        }
    }

    private func seedConfigFile(atPath path: String) -> Bool {
        let fm = FileManager.default
        let configURL = URL(fileURLWithPath: path)
        let directory = configURL.deletingLastPathComponent()

        do {
            try fm.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            return false
        }

        if !fm.fileExists(atPath: configURL.path) {
            // Try to copy from bundled config first
            if let bundledURL = Bundle.main.url(forResource: "config", withExtension: "json") {
                do {
                    try fm.copyItem(at: bundledURL, to: configURL)
                    return true
                } catch {
                    // Continue to create default config if bundled copy fails
                }
            }

            // Create default config if bundled config doesn't exist or copy fails
            let defaultConfig = """
            {
              "length_units": {
                "m": 1.0,
                "meter": 1.0,
                "meters": 1.0,
                "cm": 0.01,
                "centimeter": 0.01,
                "centimeters": 0.01,
                "mm": 0.001,
                "millimeter": 0.001,
                "millimeters": 0.001,
                "km": 1000.0,
                "kilometer": 1000.0,
                "kilometers": 1000.0,
                "ft": 0.3048,
                "foot": 0.3048,
                "feet": 0.3048,
                "in": 0.0254,
                "inch": 0.0254,
                "inches": 0.0254,
                "yard": 0.9144,
                "yards": 0.9144,
                "mile": 1609.344,
                "miles": 1609.344
              },
              "time_units": {
                "s": 1.0,
                "sec": 1.0,
                "second": 1.0,
                "seconds": 1.0,
                "min": 60.0,
                "minute": 60.0,
                "minutes": 60.0,
                "h": 3600.0,
                "hr": 3600.0,
                "hour": 3600.0,
                "hours": 3600.0,
                "day": 86400.0,
                "days": 86400.0,
                "week": 604800.0,
                "weeks": 604800.0,
                "month": 2592000.0,
                "months": 2592000.0,
                "year": 31536000.0,
                "years": 31536000.0
              },
              "temperature_units": {
                "k": "kelvin",
                "kelvin": "kelvin",
                "kelvins": "kelvin",
                "c": "celsius",
                "celsius": "celsius",
                "f": "fahrenheit",
                "fahrenheit": "fahrenheit"
              },
              "area_units": {
                "m2": 1.0,
                "square meter": 1.0,
                "square meters": 1.0,
                "hectare": 10000.0,
                "hectares": 10000.0,
                "are": 100.0,
                "ares": 100.0,
                "acre": 4046.86,
                "acres": 4046.86
              },
              "volume_units": {
                "m3": 1.0,
                "cubic meter": 1.0,
                "cubic meters": 1.0,
                "liter": 0.001,
                "liters": 0.001,
                "l": 0.001,
                "milliliter": 0.000001,
                "milliliters": 0.000001,
                "ml": 0.000001,
                "pint": 0.000473176,
                "pints": 0.000473176,
                "quart": 0.000946353,
                "quarts": 0.000946353,
                "gallon": 0.00378541,
                "gallons": 0.00378541,
                "teaspoon": 4.92892e-6,
                "teaspoons": 4.92892e-6,
                "tsp": 4.92892e-6,
                "tablespoon": 1.47868e-5,
                "tablespoons": 1.47868e-5,
                "tbsp": 1.47868e-5,
                "cup": 0.000236588,
                "cups": 0.000236588
              },
              "weight_units": {
                "gram": 1.0,
                "grams": 1.0,
                "g": 1.0,
                "kilogram": 1000.0,
                "kilograms": 1000.0,
                "kg": 1000.0,
                "tonne": 1000000.0,
                "tonnes": 1000000.0,
                "carat": 0.2,
                "carats": 0.2,
                "centner": 100000.0,
                "pound": 453.592,
                "pounds": 453.592,
                "lb": 453.592,
                "lbs": 453.592,
                "stone": 6350.29,
                "stones": 6350.29,
                "ounce": 28.3495,
                "ounces": 28.3495,
                "oz": 28.3495
              },
              "angular_units": {
                "radian": 1.0,
                "radians": 1.0,
                "degree": 0.0174533,
                "degrees": 0.0174533,
                "°": 0.0174533
              },
              "data_units": {
                "bit": 1.0,
                "bits": 1.0,
                "byte": 8.0,
                "bytes": 8.0,
                "b": 1.0,
                "B": 8.0
              },
              "speed_units": {
                "m/s": 1.0,
                "meter per second": 1.0,
                "meters per second": 1.0,
                "km/h": 0.277778,
                "kilometer per hour": 0.277778,
                "kilometers per hour": 0.277778,
                "mph": 0.44704,
                "mile per hour": 0.44704,
                "miles per hour": 0.44704,
                "knot": 0.514444,
                "knots": 0.514444
              },
              "currencies": {
                "USD": 1.0,
                "EUR": 0.86,
                "GBP": 0.76,
                "JPY": 154.0,
                "CAD": 1.40
              },
              "operators": {
                "plus": "+",
                "minus": "-",
                "times": "*",
                "multiplied by": "*",
                "divided by": "/",
                "divide by": "/",
                "subtract": "-",
                "and": "+",
                "with": "+",
                "mod": "%"
              },
              "scales": {
                "k": 1000,
                "kilo": 1000,
                "thousand": 1000,
                "M": 1000000,
                "mega": 1000000,
                "million": 1000000,
                "G": 1000000000,
                "giga": 1000000000,
                "billion": 1000000000,
                "T": 1000000000000,
                "tera": 1000000000000,
                "b": 1000000000
              },
              "functions": {
                "log": "log10(",
                "ln": "ln(",
                "abs": "abs(",
                "round": "round(",
                "ceil": "ceil(",
                "floor": "floor(",
                "sinh": "sinh(",
                "cosh": "cosh(",
                "tanh": "tanh(",
                "arcsin": "asin(",
                "arccos": "acos(",
                "arctan": "atan("
              },
              "custom_units": {
                "energy": {
                  "joule": 1.0,
                  "joules": 1.0,
                  "j": 1.0,
                  "calorie": 4.184,
                  "calories": 4.184,
                  "cal": 4.184
                }
              },
              "rates_updated_at": null
            }
            """
            do {
                try defaultConfig.write(to: configURL, atomically: true, encoding: .utf8)
            } catch {
                return false
            }
        }

        return fm.fileExists(atPath: configURL.path)
    }

    /// Updates currency rates if they are stale (>24 hours old)
    func updateCurrencyRatesIfStale() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }

            let stale = libnumby_are_rates_stale()
            if stale == 1 {
                self.updateCurrencyRatesNative { _ in }
            }
        }
    }

    /// Manually updates currency rates from the API
    /// - Returns: True if update succeeded, false otherwise
    func updateCurrencyRates() -> Bool {
        guard let ctx = context else { return false }

        // Try Rust's ureq first (works on macOS/iOS)
        let result = libnumby_update_currency_rates(ctx)
        return result == 0
    }

    /// Updates currency rates using Swift's URLSession (works on all Apple platforms including visionOS)
    /// - Parameter completion: Called with true on success, false on failure
    func updateCurrencyRatesNative(completion: @escaping (Bool) -> Void) {
        guard let ctx = context else {
            completion(false)
            return
        }

        let primaryURL = URL(string: "https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/usd.min.json")!
        let fallbackURL = URL(string: "https://latest.currency-api.pages.dev/v1/currencies/usd.min.json")!

        fetchCurrencyData(from: primaryURL) { [weak self] data in
            if let data = data {
                self?.processCurrencyData(data, ctx: ctx, completion: completion)
            } else {
                // Try fallback URL
                self?.fetchCurrencyData(from: fallbackURL) { [weak self] data in
                    if let data = data {
                        self?.processCurrencyData(data, ctx: ctx, completion: completion)
                    } else {
                        completion(false)
                    }
                }
            }
        }
    }

    private func fetchCurrencyData(from url: URL, completion: @escaping (Data?) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard error == nil,
                  let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let data = data else {
                completion(nil)
                return
            }
            completion(data)
        }
        task.resume()
    }

    private func processCurrencyData(_ data: Data, ctx: NumbyContext, completion: @escaping (Bool) -> Void) {
        guard let jsonString = String(data: data, encoding: .utf8) else {
            completion(false)
            return
        }

        let result = jsonString.withCString { cJson in
            libnumby_set_currency_rates_json(ctx, cJson)
        }

        completion(result == 0)
    }

    /// Checks if currency rates are stale
    /// - Returns: True if stale or unknown, false if fresh
    func areCurrencyRatesStale() -> Bool {
        let result = libnumby_are_rates_stale()
        return result != 0 // Stale if 1 or error (-1)
    }

    /// Gets the date when currency rates were last updated (when we fetched)
    /// - Returns: Date string in YYYY-MM-DD format, or nil if unavailable
    func getCurrencyRatesUpdateDate() -> String? {
        guard let cString = libnumby_get_rates_update_date() else {
            return nil
        }
        defer { libnumby_free_string(cString) }
        return String(cString: cString)
    }

    /// Gets the API rates date (when the rates were published by the API)
    /// - Returns: Date string in YYYY-MM-DD format, or nil if unavailable
    func getApiRatesDate() -> String? {
        guard let cString = libnumby_get_api_rates_date() else {
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
                    _ = libnumby_set_variable(ctx, cName, value, cUnit)
                }
            } else {
                _ = libnumby_set_variable(ctx, cName, value, nil)
            }
        }
    }

    func clearHistory() {
        guard let ctx = context else { return }
        _ = libnumby_clear_history(ctx)
    }

    func clearVariables() {
        guard let ctx = context else { return }
        _ = libnumby_clear_variables(ctx)
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
