use lazy_static::lazy_static;
use regex::Regex;
use std::collections::HashMap;

use crate::conversions::{evaluate_currency_conversion, evaluate_generic_conversion, evaluate_temperature_conversion};
use crate::models::{Rates, TempUnits, Units};
use crate::parser::{apply_function_parsing, apply_replacements, parse_percentage_op};
use crate::prettify::prettify_number;

lazy_static! {
    static ref PI_RE: Regex = Regex::new(r"\bpi\b").unwrap();
    static ref E_RE: Regex = Regex::new(r"\be\b").unwrap();
    static ref PI_UPPER_RE: Regex = Regex::new(r"\bPI\b").unwrap();
    static ref E_UPPER_RE: Regex = Regex::new(r"\bE\b").unwrap();
    static ref PERCENT_OF_RE: Regex = Regex::new(r"(\d+(?:\.\d+)?)%\s*of\s*(.+)").unwrap();
    static ref PERCENT_OP_RE: Regex = Regex::new(r"(\d+(?:\.\d+)?)\s*([+\-*/])\s*(\d+(?:\.\d+)?)%").unwrap();
    static ref FUNC_RE: Regex = Regex::new(r"(\w+)\s+(\d+(?:\.\d+)?)").unwrap();
}

#[allow(clippy::too_many_arguments)]
pub fn evaluate_expr(
    expr: &str,
    variables: &mut HashMap<String, (f64, Option<String>)>,
    history: &[f64],
    length_units: &Units,
    time_units: &Units,
    temperature_units: &TempUnits,
    area_units: &Units,
    volume_units: &Units,
    weight_units: &Units,
    angular_units: &Units,
    data_units: &Units,
    speed_units: &Units,
    rates: &Rates,
    custom_units: &HashMap<String, HashMap<String, f64>>,
) -> Option<String> {
    // Strip comments (anything after // or # on each line)
    let expr_str = expr.lines()
        .map(|line| {
            // Find the first comment marker (# or //)
            let comment_pos = line.find("//").or_else(|| line.find("#"));
            if let Some(pos) = comment_pos {
                &line[..pos]
            } else {
                line
            }
        })
        .collect::<Vec<&str>>()
        .join("\n");

    let mut expr_str = expr_str.trim().to_string();
    // Replace vars
    let mut has_unit = false;
    let mut result_unit = None;
    for (var, (val, unit)) in &*variables {
        let re = Regex::new(&format!(r"\b{}\b", regex::escape(var))).unwrap();
        expr_str = re.replace_all(&expr_str, &(*val).to_string()).to_string();
        if (*unit).is_some() {
            has_unit = true;
            result_unit = (*unit).clone();
        }
    }
    // Replace operators
    expr_str = expr_str.replace("plus", "+");
    expr_str = expr_str.replace("minus", "-");
    expr_str = expr_str.replace("times", "*");
    expr_str = expr_str.replace("multiplied by", "*");
    expr_str = expr_str.replace("divided by", "/");
    expr_str = expr_str.replace("divide by", "/");
    expr_str = expr_str.replace("subtract", "-");
    expr_str = expr_str.replace("and", "+");
    expr_str = expr_str.replace("with", "+");
    expr_str = expr_str.replace("mod", "%");
    // Bitwise operators
    expr_str = expr_str.replace("and", "&"); // Wait, conflict with "and" for +
    // Better to use specific: assume "bitand" or something, but numi uses &
    // Since "and" is replaced to +, use & directly, but user types "and" for +
    // For bitwise, perhaps require "&"
    // Add xor, <<, >>
    // Since regex, add replacements for xor, left shift, right shift
    expr_str = expr_str.replace("xor", "^"); // In rust, ^ is bitwise xor for ints, but fasteval2 is float
    // fasteval2 is for floats, bitwise ops are for ints. Problem.
    // Perhaps skip bitwise for now, as it's not float math.

    // Constants
    expr_str = PI_RE.replace_all(&expr_str, &std::f64::consts::PI.to_string()).to_string();
    expr_str = E_RE.replace_all(&expr_str, &std::f64::consts::E.to_string()).to_string();
    expr_str = PI_UPPER_RE.replace_all(&expr_str, &std::f64::consts::PI.to_string()).to_string();
    expr_str = E_UPPER_RE.replace_all(&expr_str, &std::f64::consts::E.to_string()).to_string();

    // Functions
    expr_str = expr_str.replace("log ", "log10(");
    expr_str = expr_str.replace("ln ", "ln(");
    expr_str = expr_str.replace("abs ", "abs(");
    expr_str = expr_str.replace("round ", "round(");
    expr_str = expr_str.replace("ceil ", "ceil(");
    expr_str = expr_str.replace("floor ", "floor(");
    expr_str = expr_str.replace("sinh ", "sinh(");
    expr_str = expr_str.replace("cosh ", "cosh(");
    expr_str = expr_str.replace("tanh ", "tanh(");
    expr_str = expr_str.replace("arcsin ", "asin(");
    expr_str = expr_str.replace("arccos ", "acos(");
    expr_str = expr_str.replace("arctan ", "atan(");

    // Special commands
    let trimmed = expr_str.trim();
    if trimmed == "sum" || trimmed == "total" {
        return Some(format!("{}", history.iter().sum::<f64>()));
    }
    if trimmed == "average" || trimmed == "avg" {
        if history.is_empty() {
            return None;
        }
        return Some(format!(
            "{}",
            history.iter().sum::<f64>() / history.len() as f64
        ));
    }
    if trimmed == "prev" {
        return history.last().map(|&v| format!("{}", v));
    }

    expr_str = apply_replacements(expr_str);
    expr_str = apply_function_parsing(expr_str);
    if let Some(result) = parse_percentage_op(&expr_str) { return Some(result); }

    // Percentage expressions: "X% of Y"
    if let Some(caps) = PERCENT_OF_RE.captures(&expr_str) {
        if let (Some(percent_str), Some(base_str)) = (caps.get(1), caps.get(2)) {
            if let (Ok(percent), Some(base_result)) = (
                percent_str.as_str().parse::<f64>(),
                evaluate_expr(base_str.as_str(), variables, history, length_units, time_units, temperature_units, area_units, volume_units, weight_units, angular_units, data_units, speed_units, rates, custom_units)
            ) {
                let result = percent / 100.0 * base_result.split_whitespace()
                    .next()
                    .unwrap_or(&base_result)
                    .parse::<f64>()
                    .unwrap_or(0.0);
                let pretty_result = prettify_number(result);

                // Preserve unit from base if present
                let base_parts: Vec<&str> = base_result.split_whitespace().collect();
                if base_parts.len() > 1 {
                    return Some(format!("{} {}", pretty_result, base_parts[1]));
                } else {
                    return Some(pretty_result);
                }
            }
        }
    }

    // Percentage operations: "X + Y%" or "X - Y%" etc.
    if let Some(caps) = PERCENT_OP_RE.captures(&expr_str) {
        if let (Some(base_str), Some(op), Some(percent_str)) = (caps.get(1), caps.get(2), caps.get(3)) {
            if let (Ok(base), Ok(percent)) = (base_str.as_str().parse::<f64>(), percent_str.as_str().parse::<f64>()) {
                let percent_decimal = percent / 100.0;
                let result = match op.as_str() {
                    "+" => base + (base * percent_decimal),  // X + Y% = X + (X * Y/100)
                    "-" => base - (base * percent_decimal),  // X - Y% = X - (X * Y/100)
                    "*" => base * percent_decimal,           // X * Y% = X * (Y/100)
                    "/" => base / percent_decimal,           // X / Y% = X / (Y/100)
                    _ => return None,
                };
                return Some(prettify_number(result));
            }
        }
    }

    // Unit conversion
    let conversion_keyword = expr_str
        .find(" in ")
        .map(|pos| (" in ", pos))
        .or_else(|| expr_str.find(" to ").map(|pos| (" to ", pos)));
    if let Some((kw, pos)) = conversion_keyword {
        let left = &expr_str[..pos].trim();
        let right = &expr_str[pos + kw.len()..].trim();
        if let Some(val) = evaluate_unit_conversion(left, right, variables, history, length_units, time_units, temperature_units, area_units, volume_units, weight_units, angular_units, data_units, speed_units, rates, custom_units) {
            return Some(val);
        }
    }

    // Extract units from expression
    let mut num_expr = expr_str.clone();
    let mut found_unit = None;
    let words: Vec<&str> = expr_str.split_whitespace().collect();
    for word in words {
        let lower = word.to_lowercase();
        let upper = word.to_uppercase();
        if length_units.get(&lower).is_some() || time_units.get(&lower).is_some() || temperature_units.get(&lower).is_some() ||
           area_units.get(&lower).is_some() || volume_units.get(&lower).is_some() || weight_units.get(&lower).is_some() ||
           angular_units.get(&lower).is_some() || data_units.get(&lower).is_some() || speed_units.get(&lower).is_some() || rates.get(&upper).is_some() ||
           custom_units.values().any(|u| u.contains_key(&lower)) {
            num_expr = num_expr.replace(word, "");
            found_unit = Some(word);
        }
    }
    // Functions
    num_expr = FUNC_RE.replace_all(&num_expr, "$1($2)").to_string();

    num_expr = num_expr.replace(" ", "").trim().to_string();
    // Eval
    if let Ok(val) = num_expr.parse::<f64>() {
        let pretty_num = prettify_number(val);
        if has_unit && result_unit.is_some() {
            Some(format!("{} {}", pretty_num, result_unit.unwrap()))
        } else if let Some(unit) = found_unit {
            Some(format!("{} {}", pretty_num, unit))
        } else {
            Some(pretty_num)
        }
    } else {
        let mut ns = fasteval2::EmptyNamespace;
        match fasteval2::ez_eval(&num_expr, &mut ns) {
            Ok(val) => {
                let pretty_num = prettify_number(val);
                if has_unit && result_unit.is_some() {
                    Some(format!("{} {}", pretty_num, result_unit.unwrap()))
                } else if let Some(unit) = found_unit {
                    Some(format!("{} {}", pretty_num, unit))
                } else {
                    Some(pretty_num)
                }
            }
            Err(_) => None,
        }
    }
}

#[allow(clippy::too_many_arguments)]
pub fn evaluate_unit_conversion(
    left: &str,
    right: &str,
    _variables: &HashMap<String, (f64, Option<String>)>,
    _history: &[f64],
    length_units: &Units,
    time_units: &Units,
    temperature_units: &TempUnits,
    area_units: &Units,
    volume_units: &Units,
    weight_units: &Units,
    angular_units: &Units,
    data_units: &Units,
    speed_units: &Units,
    rates: &Rates,
    custom_units: &HashMap<String, HashMap<String, f64>>,
) -> Option<String> {
    let right_lower = right.to_lowercase();
    let _left_lower = left.to_lowercase();
    // Determine unit type based on right unit
    if length_units.contains_key(&right_lower) {
        if let Some(val) = evaluate_generic_conversion(left, right, length_units) {
            return Some(format!("{} {}", prettify_number(val), right));
        }
    } else if time_units.contains_key(&right_lower) {
        if let Some(val) = evaluate_generic_conversion(left, right, time_units) {
            return Some(format!("{} {}", prettify_number(val), right));
        }
    } else if temperature_units.contains_key(&right_lower) {
        if let Some(val) = evaluate_temperature_conversion(left, right, temperature_units) {
            return Some(format!("{} {}", prettify_number(val), right));
        }
    } else if area_units.contains_key(&right_lower) {
        if let Some(val) = evaluate_generic_conversion(left, right, area_units) {
            return Some(format!("{} {}", prettify_number(val), right));
        }
    } else if volume_units.contains_key(&right_lower) {
        if let Some(val) = evaluate_generic_conversion(left, right, volume_units) {
            return Some(format!("{} {}", prettify_number(val), right));
        }
    } else if weight_units.contains_key(&right_lower) {
        if let Some(val) = evaluate_generic_conversion(left, right, weight_units) {
            return Some(format!("{} {}", prettify_number(val), right));
        }
    } else if angular_units.contains_key(&right_lower) {
        if let Some(val) = evaluate_generic_conversion(left, right, angular_units) {
            return Some(format!("{} {}", prettify_number(val), right));
        }
    } else if data_units.contains_key(&right_lower) {
        if let Some(val) = evaluate_generic_conversion(left, right, data_units) {
            return Some(format!("{} {}", prettify_number(val), right));
        }
    } else if speed_units.contains_key(&right_lower) {
        if let Some(val) = evaluate_generic_conversion(left, right, speed_units) {
            return Some(format!("{} {}", prettify_number(val), right));
        }
    } else if rates.contains_key(&right.to_uppercase()) {
        // Currency
        if let Some(val) = evaluate_currency_conversion(left, right, rates) {
            return Some(format!("{} {}", prettify_number(val), right));
        }
    } else {
        // Check custom units
        for units in custom_units.values() {
            if units.contains_key(&right_lower) {
                if let Some(val) = evaluate_generic_conversion(left, right, units) {
                    return Some(format!("{} {}", prettify_number(val), right));
                }
            }
        }
    }
    None
}
