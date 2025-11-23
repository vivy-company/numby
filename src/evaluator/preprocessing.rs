use crate::config::Config;
use crate::models::AppState;
use crate::parser::{apply_function_parsing, apply_replacements};
use lazy_static::lazy_static;
use regex::Regex;
use std::collections::HashMap;
use std::sync::Mutex;

const MAX_VARIABLES: usize = 1000;

lazy_static! {
    static ref REGEX_CACHE: Mutex<HashMap<String, Regex>> = Mutex::new(HashMap::new());
    static ref UNDERSCORE_RE: Regex =
        Regex::new(r"(\d)_(\d)").expect("Invalid regex for underscore removal");
    static ref COMMA_RE: Regex = Regex::new(r"(\d),(\d)").expect("Invalid regex for comma removal");
}

fn get_variable_regex(var: &str) -> Regex {
    let pattern = format!(r"\b{}\b", regex::escape(var));

    let mut cache = REGEX_CACHE.lock().expect("Failed to lock regex cache");

    // Enforce cache size limit to prevent memory bloat
    if cache.len() >= MAX_VARIABLES && !cache.contains_key(&pattern) {
        cache.clear();
    }

    cache
        .entry(pattern.clone())
        .or_insert_with(|| {
            Regex::new(&pattern).expect("Invalid regex pattern in variable replacement")
        })
        .clone()
}

pub fn preprocess_input(
    input: &str,
    variables: &HashMap<String, (f64, Option<String>)>,
    config: &Config,
) -> String {
    let mut expr_str = input.to_string();

    // Remove underscores and commas from numbers (1_000_000 -> 1000000, 10,000 -> 10000)
    while UNDERSCORE_RE.is_match(&expr_str) {
        expr_str = UNDERSCORE_RE.replace_all(&expr_str, "${1}${2}").to_string();
    }
    while COMMA_RE.is_match(&expr_str) {
        expr_str = COMMA_RE.replace_all(&expr_str, "${1}${2}").to_string();
    }

    // Add spaces between numbers and currency symbols ($, €, etc.)
    let currency_symbol_re =
        Regex::new(r"(\d)([$€£¥₹￥])").expect("Invalid regex for currency symbols");
    expr_str = currency_symbol_re
        .replace_all(&expr_str, "$1 $2")
        .to_string();

    // Convert standalone currency symbols to their codes
    // This handles cases like "100 $" -> "100 USD" and "$100" -> "100 USD"
    // First handle prefix symbols like "$100"
    let prefix_currency_re =
        Regex::new(r"^([$€£¥₹￥])\s*(\d+(?:\.\d+)?)").expect("Invalid regex for prefix currency");
    expr_str = prefix_currency_re
        .replace_all(&expr_str, |caps: &regex::Captures| {
            let symbol = &caps[1];
            let num = &caps[2];
            let code = match symbol {
                "$" => "USD",
                "€" => "EUR",
                "£" => "GBP",
                "¥" => "JPY",
                "₹" => "INR",
                "￥" => "CNY",
                _ => return caps[0].to_string(),
            };
            format!("{} {}", num, code)
        })
        .to_string();

    // Then handle suffix symbols like "100$" or "100 $"
    // But we need to avoid breaking conversion expressions like "100$ to eur"
    // Check if this looks like a conversion first
    if !expr_str.contains(" to ") && !expr_str.contains(" in ") {
        let suffix_currency_re = Regex::new(r"(\d+(?:\.\d+)?)\s*([$€£¥₹￥])(?:\s|$)")
            .expect("Invalid regex for suffix currency");
        expr_str = suffix_currency_re
            .replace_all(&expr_str, |caps: &regex::Captures| {
                let num = &caps[1];
                let symbol = &caps[2];
                let code = match symbol {
                    "$" => "USD",
                    "€" => "EUR",
                    "£" => "GBP",
                    "¥" => "JPY",
                    "₹" => "INR",
                    "￥" => "CNY",
                    _ => return caps[0].to_string(),
                };
                format!("{} {}", num, code)
            })
            .to_string();
    } else {
        // For conversion expressions, only replace when it's at the end of the left part
        // Split by conversion keyword and process each part
        if let Some(pos) = expr_str.find(" to ").or_else(|| expr_str.find(" in ")) {
            // keyword is always 4 chars: " to " or " in "
            let keyword_len = 4;
            let left_part = &expr_str[..pos];
            let right_part = &expr_str[pos + keyword_len..];
            let keyword = &expr_str[pos..pos + keyword_len];

            // Only replace currency symbol if it's at the very end of the left part
            let suffix_currency_re = Regex::new(r"(\d+(?:\.\d+)?)\s*([$€£¥₹￥])$")
                .expect("Invalid regex for suffix currency at end");
            let processed_left = suffix_currency_re
                .replace_all(left_part, |caps: &regex::Captures| {
                    let num = &caps[1];
                    let symbol = &caps[2];
                    let code = match symbol {
                        "$" => "USD",
                        "€" => "EUR",
                        "£" => "GBP",
                        "¥" => "JPY",
                        "₹" => "INR",
                        "￥" => "CNY",
                        _ => return caps[0].to_string(),
                    };
                    format!("{} {}", num, code)
                })
                .to_string();

            expr_str = format!("{}{}{}", processed_left, keyword, right_part);
        }
    }

    // Add spaces between numbers and units/currencies (100USD -> 100 USD)
    // Match number followed by uppercase letters (likely currency/unit codes)
    let unit_re = Regex::new(r"(\d)([A-Z]{2,})").expect("Invalid regex for unit separation");
    expr_str = unit_re.replace_all(&expr_str, "$1 $2").to_string();

    // Strip comments
    let expr_str_comments = expr_str
        .lines()
        .map(|line| {
            if let Some(pos) = line.find("//").or_else(|| line.find("#")) {
                &line[..pos]
            } else {
                line
            }
        })
        .collect::<Vec<&str>>()
        .join("\n");
    expr_str = expr_str_comments.trim().to_string();

    // Check if this is a variable assignment - if so, don't replace the left side
    let is_assignment = expr_str.contains('=');
    let (left_side, right_side) = if is_assignment {
        if let Some(eq_pos) = expr_str.find('=') {
            let left = &expr_str[..eq_pos];
            let right = &expr_str[eq_pos + 1..];
            (left.to_string(), right.to_string())
        } else {
            (expr_str.clone(), String::new())
        }
    } else {
        (String::new(), expr_str.clone())
    };

    // Replace variables with cached regexes (only in right side for assignments)
    let mut preprocessed_right = right_side.clone();

    for (var, (val, unit)) in variables {
        let re = get_variable_regex(var);
        // Always include unit when replacing variables if the variable has a unit
        // This allows the evaluator to handle unit algebra (multiplication/division)
        let replacement = if unit.is_some() {
            format!("{} {}", val, unit.as_ref().unwrap())
        } else {
            val.to_string()
        };
        preprocessed_right = re
            .replace_all(&preprocessed_right, &replacement)
            .to_string();
    }

    // Reconstruct expression
    expr_str = if is_assignment {
        format!("{}={}", left_side, preprocessed_right)
    } else {
        preprocessed_right
    };

    // Replace Unicode math symbols first (order matters)
    expr_str = expr_str.replace("π", &std::f64::consts::PI.to_string());
    expr_str = expr_str.replace("×", "*");
    expr_str = expr_str.replace("÷", "/");

    // Add helper functions for sqrt and ln
    // sqrt(x) -> x^0.5
    let sqrt_re = Regex::new(r"sqrt\s*\(([^)]+)\)").expect("Invalid regex for sqrt");
    expr_str = sqrt_re.replace_all(&expr_str, "($1)^0.5").to_string();

    // ln(x) -> log(x) / log(e) [natural log using change of base formula]
    let ln_re = Regex::new(r"ln\s*\(([^)]+)\)").expect("Invalid regex for ln");
    let log_e = format!("{}", std::f64::consts::E.log10());
    expr_str = ln_re
        .replace_all(&expr_str, &format!("(log($1) / {})", log_e))
        .to_string();

    // Replace operators
    for (op, repl) in &config.operators {
        expr_str = expr_str.replace(op, repl);
    }

    // Constants
    let pi_re = Regex::new(r"\bpi\b").expect("Invalid regex pattern for pi constant");
    expr_str = pi_re
        .replace_all(&expr_str, &std::f64::consts::PI.to_string())
        .to_string();
    let e_re = Regex::new(r"\be\b").expect("Invalid regex pattern for e constant");
    expr_str = e_re
        .replace_all(&expr_str, &std::f64::consts::E.to_string())
        .to_string();
    let pi_upper_re = Regex::new(r"\bPI\b").expect("Invalid regex pattern for PI constant");
    expr_str = pi_upper_re
        .replace_all(&expr_str, &std::f64::consts::PI.to_string())
        .to_string();
    let e_upper_re = Regex::new(r"\bE\b").expect("Invalid regex pattern for E constant");
    expr_str = e_upper_re
        .replace_all(&expr_str, &std::f64::consts::E.to_string())
        .to_string();

    // Functions
    for (func, repl) in &config.functions {
        expr_str = expr_str.replace(&format!("{} ", func), repl);
    }

    // Scales
    for (scale, factor) in &config.scales {
        let re = Regex::new(&format!(r"(\d+(?:\.\d+)?)\s*{}\b", regex::escape(scale)))
            .expect("Invalid regex pattern in scale replacement");
        expr_str = re
            .replace_all(&expr_str, |caps: &regex::Captures| {
                if let Ok(num) = caps[1].parse::<f64>() {
                    (num * factor).to_string()
                } else {
                    caps[0].to_string()
                }
            })
            .to_string();
    }

    // Apply other replacements (binary, etc.)
    expr_str = apply_replacements(expr_str);
    expr_str = apply_function_parsing(expr_str);

    expr_str
}

pub fn preprocess(input: &str, state: &mut AppState, config: &Config) -> String {
    let variables_guard = state
        .variables
        .read()
        .expect("Failed to acquire read lock on variables");
    preprocess_input(input, &variables_guard, config)
}
