//! Expression parsing and preprocessing utilities.
//!
//! This module handles parsing of special number formats (binary, hex, octal),
//! scale suffixes (k, M, G, T), and percentage operations.

use lazy_static::lazy_static;
use regex::Regex;

use crate::prettify::prettify_number;

lazy_static! {
    static ref BIN_RE: Regex =
        Regex::new(r"0b([01]+)").expect("Invalid regex pattern for binary number");
    static ref OCT_RE: Regex =
        Regex::new(r"0o([0-7]+)").expect("Invalid regex pattern for octal number");
    static ref HEX_RE: Regex =
        Regex::new(r"0x([0-9a-fA-F]+)").expect("Invalid regex pattern for hex number");
    static ref K_RE: Regex =
        Regex::new(r"(\d+(?:\.\d+)?)\s*k\b").expect("Invalid regex pattern for kilo scale");
    static ref M_RE: Regex =
        Regex::new(r"(\d+(?:\.\d+)?)\s*M\b").expect("Invalid regex pattern for mega scale");
    static ref G_RE: Regex =
        Regex::new(r"(\d+(?:\.\d+)?)\s*G\b").expect("Invalid regex pattern for giga scale");
    static ref T_RE: Regex =
        Regex::new(r"(\d+(?:\.\d+)?)\s*T\b").expect("Invalid regex pattern for tera scale");
    static ref B_RE: Regex =
        Regex::new(r"(\d+(?:\.\d+)?)\s*b\b").expect("Invalid regex pattern for bit scale");
    static ref KILO_RE: Regex =
        Regex::new(r"(\d+(?:\.\d+)?)\s*kilo\b").expect("Invalid regex pattern for kilo scale");
    static ref MEGA_RE: Regex =
        Regex::new(r"(\d+(?:\.\d+)?)\s*mega\b").expect("Invalid regex pattern for mega scale");
    static ref GIGA_RE: Regex =
        Regex::new(r"(\d+(?:\.\d+)?)\s*giga\b").expect("Invalid regex pattern for giga scale");
    static ref TERA_RE: Regex =
        Regex::new(r"(\d+(?:\.\d+)?)\s*tera\b").expect("Invalid regex pattern for tera scale");
    static ref PERCENT_OP_RE: Regex = Regex::new(r"(-?\d+(?:\.\d+)?)\s*([+\-*/])\s*(\d+(?:\.\d+)?)%")
        .expect("Invalid regex pattern for percent-operation expression");
    static ref PERCENT_OF_RE: Regex = Regex::new(r"(\d+(?:\.\d+)?)%\s*of\s*(-?\d+(?:\.\d+)?)")
        .expect("Invalid regex pattern for percent-of expression");
    static ref FUNC_RE: Regex =
        Regex::new(r"(\w+)\s+(\d+(?:\.\d+)?)").expect("Invalid regex pattern for function parsing");
    static ref BIL_RE: Regex = Regex::new(r"(\d+(?:\.\d+)?)\s*billion\b")
        .expect("Invalid regex pattern for billion scale");
}

/// Apply parsing replacements to convert special formats to decimal.
///
/// Handles:
/// - Binary numbers (0b101 → 5)
/// - Octal numbers (0o10 → 8)
/// - Hexadecimal numbers (0xFF → 255)
/// - Scale suffixes (5k → 5000, 2M → 2000000, 3G → 3000000000, etc.)
///
/// # Examples
///
/// ```
/// use numby::parser::apply_replacements;
///
/// // Binary to decimal
/// assert_eq!(apply_replacements("0b1010".to_string()), "10");
///
/// // Hex to decimal
/// assert_eq!(apply_replacements("0xFF".to_string()), "255");
///
/// // Scale suffixes
/// assert_eq!(apply_replacements("5k".to_string()), "5000");
/// assert_eq!(apply_replacements("2M".to_string()), "2000000");
/// ```
pub fn apply_replacements(mut expr_str: String) -> String {
    // Binary
    expr_str = BIN_RE
        .replace_all(&expr_str, |caps: &regex::Captures| {
            u64::from_str_radix(&caps[1], 2).unwrap_or(0).to_string()
        })
        .to_string();
    // Octal
    expr_str = OCT_RE
        .replace_all(&expr_str, |caps: &regex::Captures| {
            u64::from_str_radix(&caps[1], 8).unwrap_or(0).to_string()
        })
        .to_string();
    // Hex
    expr_str = HEX_RE
        .replace_all(&expr_str, |caps: &regex::Captures| {
            u64::from_str_radix(&caps[1], 16).unwrap_or(0).to_string()
        })
        .to_string();

    // Scales
    expr_str = K_RE
        .replace_all(&expr_str, |caps: &regex::Captures| {
            if let Ok(num) = caps[1].parse::<f64>() {
                (num * 1000.0).to_string()
            } else {
                caps[0].to_string()
            }
        })
        .to_string();
    expr_str = M_RE
        .replace_all(&expr_str, |caps: &regex::Captures| {
            if let Ok(num) = caps[1].parse::<f64>() {
                (num * 1000000.0).to_string()
            } else {
                caps[0].to_string()
            }
        })
        .to_string();
    expr_str = G_RE
        .replace_all(&expr_str, |caps: &regex::Captures| {
            if let Ok(num) = caps[1].parse::<f64>() {
                (num * 1000000000.0).to_string()
            } else {
                caps[0].to_string()
            }
        })
        .to_string();
    expr_str = T_RE
        .replace_all(&expr_str, |caps: &regex::Captures| {
            if let Ok(num) = caps[1].parse::<f64>() {
                (num * 1000000000000.0).to_string()
            } else {
                caps[0].to_string()
            }
        })
        .to_string();
    expr_str = B_RE
        .replace_all(&expr_str, |caps: &regex::Captures| {
            if let Ok(num) = caps[1].parse::<f64>() {
                (num * 1000000000.0).to_string()
            } else {
                caps[0].to_string()
            }
        })
        .to_string();
    // SI word scales
    expr_str = KILO_RE
        .replace_all(&expr_str, |caps: &regex::Captures| {
            if let Ok(num) = caps[1].parse::<f64>() {
                (num * 1000.0).to_string()
            } else {
                caps[0].to_string()
            }
        })
        .to_string();
    expr_str = MEGA_RE
        .replace_all(&expr_str, |caps: &regex::Captures| {
            if let Ok(num) = caps[1].parse::<f64>() {
                (num * 1000000.0).to_string()
            } else {
                caps[0].to_string()
            }
        })
        .to_string();
    expr_str = GIGA_RE
        .replace_all(&expr_str, |caps: &regex::Captures| {
            if let Ok(num) = caps[1].parse::<f64>() {
                (num * 1000000000.0).to_string()
            } else {
                caps[0].to_string()
            }
        })
        .to_string();
    expr_str = TERA_RE
        .replace_all(&expr_str, |caps: &regex::Captures| {
            if let Ok(num) = caps[1].parse::<f64>() {
                (num * 1000000000000.0).to_string()
            } else {
                caps[0].to_string()
            }
        })
        .to_string();
    expr_str = BIL_RE
        .replace_all(&expr_str, |caps: &regex::Captures| {
            if let Ok(num) = caps[1].parse::<f64>() {
                (num * 1000000000.0).to_string()
            } else {
                caps[0].to_string()
            }
        })
        .to_string();

    expr_str
}

/// Parse percentage operations like "100 + 10%" or "50 - 20%".
///
/// Handles operations where a percentage is applied to a base number.
///
/// # Examples
///
/// ```
/// use numby::parser::parse_percentage_op;
///
/// // 100 + 10% = 110
/// let result = parse_percentage_op("100 + 10%");
/// assert!(result.is_some());
/// assert_eq!(result.unwrap(), "110");
///
/// // 200 - 25% = 150
/// let result = parse_percentage_op("200 - 25%");
/// assert!(result.is_some());
/// assert_eq!(result.unwrap(), "150");
///
/// // No percentage operation
/// assert!(parse_percentage_op("100 + 10").is_none());
/// ```
pub fn parse_percentage_op(expr_str: &str) -> Option<String> {
    if let Some(caps) = PERCENT_OP_RE.captures(expr_str) {
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
                    _ => return None,
                };
                return Some(prettify_number(result));
            }
        }
    }
    None
}

/// Apply function parsing to convert "sin 45" to "sin(45)".
///
/// # Examples
///
/// ```
/// use numby::parser::apply_function_parsing;
///
/// assert_eq!(apply_function_parsing("sin 45".to_string()), "sin(45)");
/// assert_eq!(apply_function_parsing("log 100".to_string()), "log(100)");
/// assert_eq!(apply_function_parsing("sqrt 16".to_string()), "sqrt(16)");
/// ```
pub fn apply_function_parsing(mut num_expr: String) -> String {
    // Don't convert "of" to a function - it's used in percentage expressions
    num_expr = FUNC_RE
        .replace_all(&num_expr, |caps: &regex::Captures| {
            let func_name = &caps[1];
            let arg = &caps[2];
            // Skip "of" as it's used in "X% of Y" expressions
            if func_name.eq_ignore_ascii_case("of") {
                caps[0].to_string()
            } else {
                format!("{}({})", func_name, arg)
            }
        })
        .to_string();
    num_expr
}

/// Evaluate a simple percentage expression like "30% of 15" or "100 + 10%".
/// Returns Some(result) if successfully evaluated, None otherwise.
fn evaluate_simple_percentage(expr: &str) -> Option<f64> {
    // Try "X% of Y" pattern
    if let Some(caps) = PERCENT_OF_RE.captures(expr) {
        if let (Some(percent_str), Some(base_str)) = (caps.get(1), caps.get(2)) {
            if let (Ok(percent), Ok(base)) = (
                percent_str.as_str().parse::<f64>(),
                base_str.as_str().parse::<f64>(),
            ) {
                return Some(percent / 100.0 * base);
            }
        }
    }

    // Try "X + Y%" pattern
    if let Some(caps) = PERCENT_OP_RE.captures(expr) {
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
                    _ => return None,
                };
                return Some(result);
            }
        }
    }

    None
}

/// Pre-process percentage expressions in parentheses.
/// Recursively evaluates expressions like (30% of 15) or (100 + 10%)
/// and replaces them with their numeric results.
///
/// # Examples
///
/// ```
/// use numby::parser::preprocess_percentage_parens;
///
/// assert_eq!(preprocess_percentage_parens("15 - (30% of 15)".to_string()), "15 - 4.5");
/// assert_eq!(preprocess_percentage_parens("(100 + 50%)".to_string()), "150");
/// ```
pub fn preprocess_percentage_parens(mut expr: String) -> String {
    // Limit iterations to prevent infinite loops
    let max_iterations = 100;
    let mut iterations = 0;

    loop {
        if iterations >= max_iterations {
            break;
        }
        iterations += 1;

        // Find innermost parentheses containing %
        let mut best_start = None;
        let mut best_end = None;
        let mut depth = 0;
        let mut current_start = None;

        for (i, c) in expr.char_indices() {
            match c {
                '(' => {
                    depth += 1;
                    current_start = Some(i);
                }
                ')' => {
                    if depth > 0 {
                        if let Some(start) = current_start {
                            let content = &expr[start + 1..i];
                            // Check if this paren contains % and no nested parens
                            if content.contains('%') && !content.contains('(') {
                                best_start = Some(start);
                                best_end = Some(i);
                                break; // Process innermost first
                            }
                        }
                        depth -= 1;
                    }
                }
                _ => {}
            }
        }

        // If we found a parenthesized percentage expression, evaluate it
        if let (Some(start), Some(end)) = (best_start, best_end) {
            let content = &expr[start + 1..end];
            if let Some(result) = evaluate_simple_percentage(content) {
                let replacement = result.to_string();
                expr = format!("{}{}{}", &expr[..start], replacement, &expr[end + 1..]);
                continue; // Try again for nested cases
            }
        }

        // No more parenthesized percentage expressions found
        break;
    }

    expr
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_preprocess_percentage_parens_simple() {
        assert_eq!(
            preprocess_percentage_parens("(30% of 15)".to_string()),
            "4.5"
        );
    }

    #[test]
    fn test_preprocess_percentage_parens_subtraction() {
        assert_eq!(
            preprocess_percentage_parens("15 - (30% of 15)".to_string()),
            "15 - 4.5"
        );
    }

    #[test]
    fn test_preprocess_percentage_parens_op() {
        assert_eq!(
            preprocess_percentage_parens("(100 + 50%)".to_string()),
            "150"
        );
    }

    #[test]
    fn test_evaluate_simple_percentage_of() {
        assert_eq!(evaluate_simple_percentage("30% of 15"), Some(4.5));
        assert_eq!(evaluate_simple_percentage("50% of 100"), Some(50.0));
    }

    #[test]
    fn test_evaluate_simple_percentage_op() {
        assert_eq!(evaluate_simple_percentage("100 + 50%"), Some(150.0));
        assert_eq!(evaluate_simple_percentage("100 - 20%"), Some(80.0));
    }
}
