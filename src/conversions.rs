use crate::models::{Rates, Units};

fn parse_number_with_scale(num_str: &str) -> Option<f64> {
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

pub fn evaluate_generic_conversion(
    left: &str,
    right: &str,
    units: &Units,
) -> Option<f64> {
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


pub fn evaluate_temperature_conversion(
    left: &str,
    right: &str,
) -> Option<f64> {
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

pub fn evaluate_currency_conversion(
    left: &str,
    right: &str,
    rates: &Rates,
) -> Option<f64> {
    // Similar to length
    let left_parts: Vec<&str> = left.split_whitespace().collect();
    if left_parts.len() == 2 {
        let num_str = left_parts[0];
        let curr1 = left_parts[1];
        let curr2 = right;
        if let Some(num) = parse_number_with_scale(num_str) {
            if let Some(rate1) = rates.get(&curr1.to_uppercase()) {
                if let Some(rate2) = rates.get(&curr2.to_uppercase()) {
                    return Some(num * rate1 / rate2);
                }
            }
        }
    }
    // For expressions, skip
    None
}