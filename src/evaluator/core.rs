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

pub fn evaluate_expr(expr: &str, ctx: &mut EvalContext) -> Result<EvalResult> {
    // Preprocessing is now handled elsewhere before calling this function
    // This function receives already preprocessed input
    let mut expr_str = expr.to_string();

    // Track unit from variables
    let mut has_unit = false;
    let mut result_unit = None;
    for (_val, unit) in (*ctx.variables).values() {
        if unit.is_some() {
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
        let left = &expr_str[..pos].trim();
        let right = &expr_str[pos + kw.len()..].trim();
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
                .and_then(|v| v.parse::<f64>().ok())
                .unwrap_or(0.0);
            let unit = if parts.len() > 1 {
                Some(parts[1].to_string())
            } else {
                None
            };
            return Ok(EvalResult { value, unit });
        }
    }

    // Extract units from expression
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
