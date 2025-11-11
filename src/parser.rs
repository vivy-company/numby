use lazy_static::lazy_static;
use regex::Regex;

use crate::prettify::prettify_number;

lazy_static! {
    static ref BIN_RE: Regex = Regex::new(r"0b([01]+)").expect("Invalid regex pattern for binary number");
    static ref OCT_RE: Regex = Regex::new(r"0o([0-7]+)").expect("Invalid regex pattern for octal number");
    static ref HEX_RE: Regex = Regex::new(r"0x([0-9a-fA-F]+)").expect("Invalid regex pattern for hex number");
    static ref K_RE: Regex = Regex::new(r"(\d+(?:\.\d+)?)\s*k\b").expect("Invalid regex pattern for kilo scale");
    static ref M_RE: Regex = Regex::new(r"(\d+(?:\.\d+)?)\s*M\b").expect("Invalid regex pattern for mega scale");
    static ref G_RE: Regex = Regex::new(r"(\d+(?:\.\d+)?)\s*G\b").expect("Invalid regex pattern for giga scale");
    static ref T_RE: Regex = Regex::new(r"(\d+(?:\.\d+)?)\s*T\b").expect("Invalid regex pattern for tera scale");
    static ref B_RE: Regex = Regex::new(r"(\d+(?:\.\d+)?)\s*b\b").expect("Invalid regex pattern for bit scale");
    static ref KILO_RE: Regex = Regex::new(r"(\d+(?:\.\d+)?)\s*kilo\b").expect("Invalid regex pattern for kilo scale");
    static ref MEGA_RE: Regex = Regex::new(r"(\d+(?:\.\d+)?)\s*mega\b").expect("Invalid regex pattern for mega scale");
    static ref GIGA_RE: Regex = Regex::new(r"(\d+(?:\.\d+)?)\s*giga\b").expect("Invalid regex pattern for giga scale");
    static ref TERA_RE: Regex = Regex::new(r"(\d+(?:\.\d+)?)\s*tera\b").expect("Invalid regex pattern for tera scale");
    static ref PERCENT_OP_RE: Regex = Regex::new(r"(\d+(?:\.\d+)?)\s*([+\-*/])\s*(\d+(?:\.\d+)?)%").expect("Invalid regex pattern for percent-operation expression");
    static ref FUNC_RE: Regex = Regex::new(r"(\w+)\s+(\d+(?:\.\d+)?)").expect("Invalid regex pattern for function parsing");
    static ref BIL_RE: Regex = Regex::new(r"(\d+(?:\.\d+)?)\s*billion\b").expect("Invalid regex pattern for billion scale");
}

/// Apply parsing replacements to the expression string.
pub fn apply_replacements(mut expr_str: String) -> String {
    // Binary
    expr_str = BIN_RE.replace_all(&expr_str, |caps: &regex::Captures| {
        u64::from_str_radix(&caps[1], 2).unwrap_or(0).to_string()
    }).to_string();
    // Octal
    expr_str = OCT_RE.replace_all(&expr_str, |caps: &regex::Captures| {
        u64::from_str_radix(&caps[1], 8).unwrap_or(0).to_string()
    }).to_string();
    // Hex
    expr_str = HEX_RE.replace_all(&expr_str, |caps: &regex::Captures| {
        u64::from_str_radix(&caps[1], 16).unwrap_or(0).to_string()
    }).to_string();

    // Scales
    expr_str = K_RE.replace_all(&expr_str, |caps: &regex::Captures| {
        if let Ok(num) = caps[1].parse::<f64>() {
            (num * 1000.0).to_string()
        } else {
            caps[0].to_string()
        }
    }).to_string();
    expr_str = M_RE.replace_all(&expr_str, |caps: &regex::Captures| {
        if let Ok(num) = caps[1].parse::<f64>() {
            (num * 1000000.0).to_string()
        } else {
            caps[0].to_string()
        }
    }).to_string();
    expr_str = G_RE.replace_all(&expr_str, |caps: &regex::Captures| {
        if let Ok(num) = caps[1].parse::<f64>() {
            (num * 1000000000.0).to_string()
        } else {
            caps[0].to_string()
        }
    }).to_string();
    expr_str = T_RE.replace_all(&expr_str, |caps: &regex::Captures| {
        if let Ok(num) = caps[1].parse::<f64>() {
            (num * 1000000000000.0).to_string()
        } else {
            caps[0].to_string()
        }
    }).to_string();
    expr_str = B_RE.replace_all(&expr_str, |caps: &regex::Captures| {
        if let Ok(num) = caps[1].parse::<f64>() {
            (num * 1000000000.0).to_string()
        } else {
            caps[0].to_string()
        }
    }).to_string();
    // SI word scales
    expr_str = KILO_RE.replace_all(&expr_str, |caps: &regex::Captures| {
        if let Ok(num) = caps[1].parse::<f64>() {
            (num * 1000.0).to_string()
        } else {
            caps[0].to_string()
        }
    }).to_string();
    expr_str = MEGA_RE.replace_all(&expr_str, |caps: &regex::Captures| {
        if let Ok(num) = caps[1].parse::<f64>() {
            (num * 1000000.0).to_string()
        } else {
            caps[0].to_string()
        }
    }).to_string();
    expr_str = GIGA_RE.replace_all(&expr_str, |caps: &regex::Captures| {
        if let Ok(num) = caps[1].parse::<f64>() {
            (num * 1000000000.0).to_string()
        } else {
            caps[0].to_string()
        }
    }).to_string();
    expr_str = TERA_RE.replace_all(&expr_str, |caps: &regex::Captures| {
        if let Ok(num) = caps[1].parse::<f64>() {
            (num * 1000000000000.0).to_string()
        } else {
            caps[0].to_string()
        }
    }).to_string();
    expr_str = BIL_RE.replace_all(&expr_str, |caps: &regex::Captures| {
        if let Ok(num) = caps[1].parse::<f64>() {
            (num * 1000000000.0).to_string()
        } else {
            caps[0].to_string()
        }
    }).to_string();

    expr_str
}

/// Parse percentage operations.
pub fn parse_percentage_op(expr_str: &str) -> Option<String> {
    if let Some(caps) = PERCENT_OP_RE.captures(expr_str) {
        if let (Some(base_str), Some(op), Some(percent_str)) = (caps.get(1), caps.get(2), caps.get(3)) {
            if let (Ok(base), Ok(percent)) = (base_str.as_str().parse::<f64>(), percent_str.as_str().parse::<f64>()) {
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

/// Apply function parsing.
pub fn apply_function_parsing(mut num_expr: String) -> String {
    num_expr = FUNC_RE.replace_all(&num_expr, "$1($2)").to_string();
    num_expr
}