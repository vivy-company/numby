use lazy_static::lazy_static;
use regex::Regex;
use std::collections::HashMap;

use crate::conversions::{
    evaluate_currency_conversion, evaluate_generic_conversion, evaluate_temperature_conversion,
};
use crate::evaluator::{EvaluatorError, Result};
use crate::models::{Rates, TempUnits, Units};
use crate::parser::{apply_function_parsing, apply_replacements, parse_percentage_op};
use crate::prettify::prettify_number;

#[derive(Debug, Clone)]
pub struct EvalResult {
    pub value: f64,
    pub unit: Option<String>,
}

pub struct EvalContext<'a> {
    pub variables: &'a mut HashMap<String, (f64, Option<String>)>,
    pub history: &'a [f64],
    pub length_units: &'a Units,
    pub time_units: &'a Units,
    pub temperature_units: &'a TempUnits,
    pub area_units: &'a Units,
    pub volume_units: &'a Units,
    pub weight_units: &'a Units,
    pub angular_units: &'a Units,
    pub data_units: &'a Units,
    pub speed_units: &'a Units,
    pub rates: &'a Rates,
    pub custom_units: &'a HashMap<String, HashMap<String, f64>>,
}

lazy_static! {
    static ref PI_RE: Regex = Regex::new(r"\bpi\b").expect("Invalid regex pattern for pi constant");
    static ref E_RE: Regex = Regex::new(r"\be\b").expect("Invalid regex pattern for e constant");
    static ref PI_UPPER_RE: Regex =
        Regex::new(r"\bPI\b").expect("Invalid regex pattern for PI constant");
    static ref E_UPPER_RE: Regex =
        Regex::new(r"\bE\b").expect("Invalid regex pattern for E constant");
    static ref PERCENT_OF_RE: Regex = Regex::new(r"(\d+(?:\.\d+)?)%\s*of\s*(.+)")
        .expect("Invalid regex pattern for percent-of expression");
    static ref PERCENT_OP_RE: Regex = Regex::new(r"(\d+(?:\.\d+)?)\s*([+\-*/])\s*(\d+(?:\.\d+)?)%")
        .expect("Invalid regex pattern for percent-operation expression");
    static ref FUNC_RE: Regex =
        Regex::new(r"(\w+)\s+(\d+(?:\.\d+)?)").expect("Invalid regex pattern for function parsing");
}

/// Evaluate an expression
pub fn evaluate_expr(expr: &str, ctx: &mut EvalContext) -> Result<EvalResult> {
    evaluate_expr_with_original(expr, ctx, None)
}

/// Evaluate an expression with optional original expression for unit tracking
///
/// # Arguments
/// * `expr` - The preprocessed expression to evaluate
/// * `ctx` - The evaluation context
/// * `original_expr` - Optional original expression (before variable substitution) for unit tracking
pub fn evaluate_expr_with_original(
    expr: &str,
    ctx: &mut EvalContext,
    original_expr: Option<&str>,
) -> Result<EvalResult> {
    // Preprocessing is now handled elsewhere before calling this function
    // This function receives already preprocessed input
    let mut expr_str = expr.to_string();

    // Track unit from variables that are actually used in the ORIGINAL expression
    // (before preprocessing replaced variable names with values)
    let expr_for_unit_check = original_expr.unwrap_or(expr);
    let mut has_unit = false;
    let mut result_unit = None;
    for (var_name, (_val, unit)) in ctx.variables.iter() {
        if unit.is_some() && expr_for_unit_check.contains(var_name) {
            has_unit = true;
            result_unit = unit.clone();
            break;
        }
    }

    // Special commands
    let trimmed = expr_str.trim();
    if trimmed == "sum" || trimmed == "total" {
        return Ok(EvalResult {
            value: ctx.history.iter().sum::<f64>(),
            unit: None,
        });
    }
    if trimmed == "average" || trimmed == "avg" {
        if ctx.history.is_empty() {
            return Err(EvaluatorError::InvalidExpression(crate::fl!(
                "cannot-compute-average-empty"
            )));
        }
        return Ok(EvalResult {
            value: ctx.history.iter().sum::<f64>() / ctx.history.len() as f64,
            unit: None,
        });
    }
    if trimmed == "prev" {
        return ctx
            .history
            .last()
            .map(|&v| EvalResult {
                value: v,
                unit: None,
            })
            .ok_or_else(|| EvaluatorError::InvalidExpression(crate::fl!("no-previous-result")));
    }

    expr_str = apply_replacements(expr_str);
    expr_str = apply_function_parsing(expr_str);
    if let Some(result_str) = parse_percentage_op(&expr_str) {
        let value = result_str
            .split_whitespace()
            .next()
            .unwrap_or(&result_str)
            .parse::<f64>()
            .map_err(|e| {
                EvaluatorError::ParseError(
                    crate::fl!("failed-parse-percentage", "error" => &e.to_string()),
                )
            })?;
        return Ok(EvalResult { value, unit: None });
    }

    // Percentage expressions: "X% of Y"
    if let Some(caps) = PERCENT_OF_RE.captures(&expr_str) {
        if let (Some(percent_str), Some(base_str)) = (caps.get(1), caps.get(2)) {
            if let Ok(percent) = percent_str.as_str().parse::<f64>() {
                if let Ok(base_result) = evaluate_expr(base_str.as_str(), ctx) {
                    let result = percent / 100.0 * base_result.value;
                    return Ok(EvalResult {
                        value: result,
                        unit: base_result.unit.clone(),
                    });
                }
            }
        }
    }

    // Percentage operations: "X + Y%" or "X - Y%" etc.
    if let Some(caps) = PERCENT_OP_RE.captures(&expr_str) {
        if let (Some(base_str), Some(op), Some(percent_str)) =
            (caps.get(1), caps.get(2), caps.get(3))
        {
            if let (Ok(base), Ok(percent)) = (
                base_str.as_str().parse::<f64>(),
                percent_str.as_str().parse::<f64>(),
            ) {
                let percent_decimal = percent / 100.0;
                let result = match op.as_str() {
                    "+" => base + (base * percent_decimal),
                    "-" => base - (base * percent_decimal),
                    "*" => base * percent_decimal,
                    "/" => base / percent_decimal,
                    _ => {
                        return Err(EvaluatorError::InvalidExpression(
                            crate::fl!("invalid-percentage-operator", "op" => op.as_str()),
                        ))
                    }
                };
                return Ok(EvalResult {
                    value: result,
                    unit: None,
                });
            }
        }
    }

    // Unit conversion
    let conversion_keyword = expr_str
        .find(" in ")
        .map(|pos| (" in ", pos))
        .or_else(|| expr_str.find(" to ").map(|pos| (" to ", pos)));
    if let Some((kw, pos)) = conversion_keyword {
        let left = expr_str[..pos].trim();
        let right = expr_str[pos + kw.len()..].trim();

        // First, try direct conversion (e.g., "100 USD" to "EUR")
        if let Some(val) = evaluate_unit_conversion(
            left,
            right,
            ctx.length_units,
            ctx.time_units,
            ctx.temperature_units,
            ctx.area_units,
            ctx.volume_units,
            ctx.weight_units,
            ctx.angular_units,
            ctx.data_units,
            ctx.speed_units,
            ctx.rates,
            ctx.custom_units,
        ) {
            // Parse the unit conversion result back into value and unit
            let parts: Vec<&str> = val.split_whitespace().collect();
            let value = parts
                .first()
                .and_then(|v| crate::conversions::parse_number_with_scale(v))
                .unwrap_or(0.0);
            let unit = if parts.len() > 1 {
                Some(parts[1].to_string())
            } else {
                None
            };
            return Ok(EvalResult { value, unit });
        }

        // If direct conversion failed, try evaluating left side first (e.g., "150 USD * 5" to "JPY")
        if let Ok(left_result) = evaluate_expr(left, ctx) {
            // Format as "value unit" for conversion
            let left_with_unit = if let Some(unit) = left_result.unit {
                format!("{} {}", left_result.value, unit)
            } else {
                left_result.value.to_string()
            };

            if let Some(val) = evaluate_unit_conversion(
                &left_with_unit,
                right,
                ctx.length_units,
                ctx.time_units,
                ctx.temperature_units,
                ctx.area_units,
                ctx.volume_units,
                ctx.weight_units,
                ctx.angular_units,
                ctx.data_units,
                ctx.speed_units,
                ctx.rates,
                ctx.custom_units,
            ) {
                let parts: Vec<&str> = val.split_whitespace().collect();
                let value = parts
                    .first()
                    .and_then(|v| crate::conversions::parse_number_with_scale(v))
                    .unwrap_or(0.0);
                let unit = if parts.len() > 1 {
                    Some(parts[1].to_string())
                } else {
                    None
                };
                return Ok(EvalResult { value, unit });
            }
        }
    }

    // Try to parse and handle unit algebra for multiplication/division
    // Check if expression contains units and operations
    let result_from_algebra = try_evaluate_with_unit_algebra(&expr_str, ctx);
    if result_from_algebra.is_ok() {
        return result_from_algebra;
    }

    // Fall back to original unit extraction logic for simple cases
    let mut num_expr = expr_str.clone();
    let mut found_unit = None;
    let words: Vec<&str> = expr_str.split_whitespace().collect();
    for word in words {
        let lower = word.to_lowercase();
        let upper = word.to_uppercase();
        if ctx.length_units.get(&lower).is_some()
            || ctx.time_units.get(&lower).is_some()
            || ctx.temperature_units.get(&lower).is_some()
            || ctx.area_units.get(&lower).is_some()
            || ctx.volume_units.get(&lower).is_some()
            || ctx.weight_units.get(&lower).is_some()
            || ctx.angular_units.get(&lower).is_some()
            || ctx.data_units.get(&lower).is_some()
            || ctx.speed_units.get(&lower).is_some()
            || ctx.rates.get(&upper).is_some()
            || ctx.custom_units.values().any(|u| u.contains_key(&lower))
        {
            num_expr = num_expr.replace(word, "");
            found_unit = Some(word);
        }
    }
    // Functions
    num_expr = FUNC_RE.replace_all(&num_expr, "$1($2)").to_string();

    num_expr = num_expr.replace(" ", "").trim().to_string();
    // Eval
    if let Ok(val) = num_expr.parse::<f64>() {
        let unit = if has_unit && result_unit.is_some() {
            result_unit.clone()
        } else {
            found_unit.map(|u| u.to_string())
        };
        Ok(EvalResult { value: val, unit })
    } else {
        let mut ns = fasteval2::EmptyNamespace;
        match fasteval2::ez_eval(&num_expr, &mut ns) {
            Ok(val) => {
                let unit = if has_unit && result_unit.is_some() {
                    result_unit.clone()
                } else {
                    found_unit.map(|u| u.to_string())
                };
                Ok(EvalResult { value: val, unit })
            }
            Err(e) => Err(EvaluatorError::EvaluationError(
                crate::fl!("failed-evaluate-expression", "error" => &e.to_string()),
            )),
        }
    }
}

/// Try to evaluate an expression with unit algebra (multiplication/division)
fn try_evaluate_with_unit_algebra(expr: &str, ctx: &EvalContext) -> Result<EvalResult> {
    // Simple regex to match patterns like: "number unit * number unit" or "number unit * number"
    lazy_static! {
        static ref MULT_DIV_RE: Regex = Regex::new(
            r"^\s*([\d.]+)\s+([a-zA-Z]+)\s*([*/])\s*([\d.]+)\s*([a-zA-Z]*)\s*$"
        ).expect("Invalid unit algebra regex");
    }

    if let Some(caps) = MULT_DIV_RE.captures(expr) {
        let left_val: f64 = caps[1].parse().map_err(|_| {
            EvaluatorError::ParseError("Failed to parse left operand".to_string())
        })?;
        let left_unit = caps[2].to_string();
        let op = &caps[3];
        let right_val: f64 = caps[4].parse().map_err(|_| {
            EvaluatorError::ParseError("Failed to parse right operand".to_string())
        })?;
        let right_unit = caps.get(5).map(|m| m.as_str().to_string());

        // Perform the operation
        let value = match op {
            "*" => left_val * right_val,
            "/" => left_val / right_val,
            _ => return Err(EvaluatorError::InvalidExpression("Unsupported operation".to_string())),
        };

        // Determine result unit based on operation and units
        let unit = match (op, &right_unit) {
            ("*", None) => {
                // number unit * number = number unit (e.g., 5 feet * 2 = 10 feet)
                Some(left_unit)
            }
            ("*", Some(right_u)) if right_u.is_empty() => {
                // number unit * number = number unit (e.g., 5 feet * 2 = 10 feet)
                Some(left_unit)
            }
            ("*", Some(right_u)) if right_u == &left_unit => {
                // Same unit multiplication: feet * feet = feet² (but for now, keep first unit)
                // This is where you'd implement proper unit squaring
                Some(left_unit)
            }
            ("*", Some(right_u)) if is_currency(right_u, ctx) => {
                // area unit * currency = currency (e.g., feet² * USD = USD)
                Some(right_u.clone())
            }
            ("/", None) => {
                // number unit / number = number unit (e.g., 10 feet / 2 = 5 feet)
                Some(left_unit)
            }
            ("/", Some(right_u)) if right_u.is_empty() => {
                // number unit / number = number unit (e.g., 10 feet / 2 = 5 feet)
                Some(left_unit)
            }
            ("/", Some(right_u)) if right_u == &left_unit => {
                // Same unit division: feet / feet = unitless
                None
            }
            _ => {
                // For other cases, keep left unit
                Some(left_unit)
            }
        };

        Ok(EvalResult { value, unit })
    } else {
        Err(EvaluatorError::InvalidExpression("Not a unit algebra expression".to_string()))
    }
}

/// Check if a unit string is a currency
fn is_currency(unit: &str, ctx: &EvalContext) -> bool {
    ctx.rates.contains_key(&unit.to_uppercase())
}

#[allow(clippy::too_many_arguments)]
pub fn evaluate_unit_conversion(
    left: &str,
    right: &str,
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
        if let Some(val) = evaluate_temperature_conversion(left, right) {
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
