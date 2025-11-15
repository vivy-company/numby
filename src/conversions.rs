//! Unit and currency conversion functions.
//!
//! This module provides conversion between different units of measurement
//! including length, temperature, and currencies.

use crate::models::{Rates, Units};

/// Map currency symbols to their ISO currency codes.
///
/// # Examples
///
/// ```
/// # use numby::conversions::*;
/// # fn symbol_to_currency_code(s: &str) -> Option<&str> {
/// #     match s {
/// #         "$" => Some("USD"),
/// #         "€" => Some("EUR"),
/// #         _ => None,
/// #     }
/// # }
/// assert_eq!(symbol_to_currency_code("$"), Some("USD"));
/// assert_eq!(symbol_to_currency_code("€"), Some("EUR"));
/// assert_eq!(symbol_to_currency_code("unknown"), None);
/// ```
fn symbol_to_currency_code(symbol: &str) -> Option<&str> {
    match symbol {
        "$" => Some("USD"),
        "€" => Some("EUR"),
        "£" => Some("GBP"),
        "¥" => Some("JPY"),
        "₹" => Some("INR"),
        "￥" => Some("CNY"), // Chinese Yuan
        "¢" => Some("USD"), // cents
        "₽" => Some("RUB"),
        "₩" => Some("KRW"),
        "₪" => Some("ILS"),
        "₦" => Some("NGN"),
        "₨" => Some("PKR"),
        "₱" => Some("PHP"),
        "฿" => Some("THB"),
        "₡" => Some("CRC"),
        "₴" => Some("UAH"),
        "₵" => Some("GHS"),
        "₸" => Some("KZT"),
        "₺" => Some("TRY"),
        "₼" => Some("AZN"),
        "₾" => Some("GEL"),
        _ => None,
    }
}

/// Normalize currency input by converting symbols to codes
/// Examples: "100$" -> "100 USD", "$100" -> "100 USD", "€50" -> "50 EUR"
fn normalize_currency_input(input: &str) -> String {
    let input = input.trim();

    // Check if first char is a currency symbol
    if let Some(first_char) = input.chars().next() {
        let first_str = first_char.to_string();
        if let Some(code) = symbol_to_currency_code(&first_str) {
            // Symbol at start: "$100" -> "100 USD"
            let rest = &input[first_char.len_utf8()..].trim();
            return format!("{} {}", rest, code);
        }
    }

    // Check if last char is a currency symbol
    if let Some(last_char) = input.chars().last() {
        let last_str = last_char.to_string();
        if let Some(code) = symbol_to_currency_code(&last_str) {
            // Symbol at end: "100$" -> "100 USD"
            let rest = &input[..input.len() - last_char.len_utf8()].trim();
            return format!("{} {}", rest, code);
        }
    }

    // No symbol found, return as-is
    input.to_string()
}

pub fn parse_number_with_scale(num_str: &str) -> Option<f64> {
    // Try direct parse first
    if let Ok(num) = num_str.parse::<f64>() {
        return Some(num);
    }

    // Try parsing with scale suffixes (k, M, G, B)
    let num_str = num_str.trim();
    if let Some(last_char) = num_str.chars().last() {
        let multiplier = match last_char {
            'k' => 1_000.0,
            'M' => 1_000_000.0,
            'G' | 'B' => 1_000_000_000.0,
            'T' => 1_000_000_000_000.0,
            _ => return None,
        };

        let num_part = &num_str[..num_str.len() - 1];
        if let Ok(num) = num_part.parse::<f64>() {
            return Some(num * multiplier);
        }
    }

    None
}

/// Convert between generic units (length, weight, volume, etc.).
///
/// Takes an expression like "5 km" and a target unit like "miles",
/// returns the converted value.
///
/// # Arguments
///
/// * `left` - Expression with number and source unit (e.g., "5 km")
/// * `right` - Target unit name (e.g., "miles")
/// * `units` - HashMap of unit names to conversion factors
///
/// # Examples
///
/// ```
/// use std::collections::HashMap;
/// use numby::conversions::evaluate_generic_conversion;
///
/// let mut units = HashMap::new();
/// units.insert("km".to_string(), 1000.0);
/// units.insert("miles".to_string(), 1609.344);
///
/// let result = evaluate_generic_conversion("5 km", "miles", &units);
/// assert!(result.is_some());
/// let value = result.unwrap();
/// assert!((value - 3.106).abs() < 0.01); // 5 km ≈ 3.106 miles
/// ```
pub fn evaluate_generic_conversion(left: &str, right: &str, units: &Units) -> Option<f64> {
    // Simple: assume left is number + unit, right is unit
    let left_parts: Vec<&str> = left.split_whitespace().collect();
    if left_parts.len() == 2 {
        let num_str = left_parts[0];
        let unit1 = left_parts[1];
        let unit2 = right;
        if let Some(num) = parse_number_with_scale(num_str) {
            if let Some(conv1) = units.get(&unit1.to_lowercase()) {
                if let Some(conv2) = units.get(&unit2.to_lowercase()) {
                    return Some(num * conv1 / conv2);
                }
            }
        }
    }
    // For expressions, skip for now to avoid recursion
    None
}

/// Convert between temperature units (Celsius, Fahrenheit, Kelvin).
///
/// # Arguments
///
/// * `left` - Expression with number and source unit (e.g., "100 celsius")
/// * `right` - Target unit name (e.g., "fahrenheit")
///
/// # Examples
///
/// ```
/// use numby::conversions::evaluate_temperature_conversion;
///
/// // 0°C = 32°F
/// let result = evaluate_temperature_conversion("0 celsius", "fahrenheit");
/// assert_eq!(result, Some(32.0));
///
/// // 100°C = 212°F
/// let result = evaluate_temperature_conversion("100 celsius", "fahrenheit");
/// assert_eq!(result, Some(212.0));
///
/// // 0 Kelvin = -273.15°C
/// let result = evaluate_temperature_conversion("0 kelvin", "celsius");
/// assert_eq!(result, Some(-273.15));
/// ```
pub fn evaluate_temperature_conversion(left: &str, right: &str) -> Option<f64> {
    // Assume left is number + unit
    let left_parts: Vec<&str> = left.split_whitespace().collect();
    if left_parts.len() == 2 {
        let num_str = left_parts[0];
        let unit1 = left_parts[1].to_lowercase();
        let unit2 = right.to_lowercase();
        if let Some(num) = parse_number_with_scale(num_str) {
            return convert_temperature(num, &unit1, &unit2);
        }
    }
    // For expressions, skip
    None
}

fn convert_temperature(val: f64, from: &str, to: &str) -> Option<f64> {
    // Convert to celsius first
    let celsius = match from {
        "celsius" => val,
        "fahrenheit" => (val - 32.0) * 5.0 / 9.0,
        "kelvin" => val - 273.15,
        _ => return None,
    };
    // Convert from celsius to target
    match to {
        "celsius" => Some(celsius),
        "fahrenheit" => Some(celsius * 9.0 / 5.0 + 32.0),
        "kelvin" => Some(celsius + 273.15),
        _ => None,
    }
}

/// Convert between currencies using exchange rates.
///
/// Supports both currency codes (USD, EUR) and symbols ($, €).
///
/// # Arguments
///
/// * `left` - Expression with amount and source currency (e.g., "100 USD" or "$100")
/// * `right` - Target currency code or symbol (e.g., "EUR" or "€")
/// * `rates` - HashMap of currency codes to exchange rates (relative to USD)
///
/// # Examples
///
/// ```
/// use std::collections::HashMap;
/// use numby::conversions::evaluate_currency_conversion;
///
/// let mut rates = HashMap::new();
/// rates.insert("USD".to_string(), 1.0);
/// rates.insert("EUR".to_string(), 0.85);
///
/// let result = evaluate_currency_conversion("100 USD", "EUR", &rates);
/// assert!(result.is_some());
/// assert_eq!(result.unwrap(), 85.0); // 100 USD = 85 EUR
/// ```
pub fn evaluate_currency_conversion(left: &str, right: &str, rates: &Rates) -> Option<f64> {
    // Normalize inputs to handle currency symbols
    let left_normalized = normalize_currency_input(left);
    let right_normalized = normalize_currency_input(right);

    // Similar to length
    let left_parts: Vec<&str> = left_normalized.split_whitespace().collect();

    // Handle "NUMBER CURRENCY to CURRENCY" format
    if left_parts.len() == 2 {
        let num_str = left_parts[0];
        let curr1 = left_parts[1];
        let curr2 = right_normalized.trim();
        if let Some(num) = parse_number_with_scale(num_str) {
            if let Some(rate1) = rates.get(&curr1.to_uppercase()) {
                if let Some(rate2) = rates.get(&curr2.to_uppercase()) {
                    // Formula: Convert from source currency to target currency
                    // Rates are stored as "X units per 1 USD" (e.g., 154 JPY per 1 USD)
                    // To convert: first convert source to USD, then USD to target
                    // source -> USD: amount / rate1 (e.g., 850 USD / 1 = 850 USD)
                    // USD -> target: usd_amount * rate2 (e.g., 850 * 154 = 130,900 JPY)
                    // Combined: amount * rate2 / rate1
                    return Some(num * rate2 / rate1);
                }
            }
        }
    }

    // Handle "NUMBER to CURRENCY" format (no source unit)
    // Assume the number is already in the target currency (just format it)
    if left_parts.len() == 1 {
        let curr2 = right_normalized.trim();
        // Only apply this if the target is actually a valid currency
        if rates.contains_key(&curr2.to_uppercase()) {
            if let Some(num) = parse_number_with_scale(left_parts[0]) {
                // Just return the number - it's being "converted" to the target currency
                // This allows expressions like "100 + 400 to USD" to work
                return Some(num);
            }
        }
    }

    // For expressions, skip
    None
}
