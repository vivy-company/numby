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
    static ref BLOCK_COMMENT_RE: Regex =
        Regex::new(r"(?s)/\*.*?\*/").expect("Invalid regex for block comments");
    static ref DATA_UNIT_RE: Regex = Regex::new(r"(\d)([a-zA-Z]+(?:/s)?)\b")
        .expect("Invalid data unit regex");
    static ref WORD_NUMBER_RE: Regex = Regex::new(
        r"(?i)\b(zero|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty|thirty|forty|fifty|sixty|seventy|eighty|ninety)\b"
    )
    .expect("Invalid word-number regex");
    static ref CURRENCY_WORD_RE: Regex = Regex::new(
        r"(?i)\b(dollars?|euros?|pounds?|yen|yuan|rmb|rupees?|rubles?|won|francs?|pesos?|krona|krone|lira|bitcoin|btc|ethereum|eth)\b"
    )
    .expect("Invalid currency word regex");
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
    // Strip block comments (/* ... */), including multiline
    expr_str = BLOCK_COMMENT_RE.replace_all(&expr_str, " ").to_string();

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

    // Separate attached data units while keeping the existing 5b billion shorthand.
    expr_str = DATA_UNIT_RE
        .replace_all(&expr_str, |caps: &regex::Captures| {
            if &caps[2] != "b" && crate::conversions::data_unit(&caps[2]).is_some() {
                format!("{} {}", &caps[1], &caps[2])
            } else {
                caps[0].to_string()
            }
        })
        .to_string();

    // Replace simple word numbers (one..ninety) with digits so "ten plus five" works
    expr_str = replace_word_numbers(&expr_str);

    // Replace currency words (dollar -> USD, euro -> EUR, etc.) for voice dictation
    expr_str = replace_currency_words(&expr_str);

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

    // Strip line comments
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
    let mut preprocessed_right = strip_inline_annotations(&right_side, variables, config);

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

    // Case-insensitive operator words (e.g., MINUS)
    for (op, repl) in &config.operators {
        let re = Regex::new(&format!(r"(?i)\b{}\b", regex::escape(op)))
            .expect("Invalid regex pattern in operator replacement");
        expr_str = re.replace_all(&expr_str, repl.clone()).to_string();
    }

    // Scales
    for (scale, factor) in &config.scales {
        let separator = if scale == "b" { "" } else { r"\s*" };
        let re = Regex::new(&format!(
            r"(\d+(?:\.\d+)?){separator}{}\b",
            regex::escape(scale)
        ))
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

pub(crate) fn word_to_number(word: &str) -> Option<&'static str> {
    match word {
        "zero" => Some("0"),
        "one" => Some("1"),
        "two" => Some("2"),
        "three" => Some("3"),
        "four" => Some("4"),
        "five" => Some("5"),
        "six" => Some("6"),
        "seven" => Some("7"),
        "eight" => Some("8"),
        "nine" => Some("9"),
        "ten" => Some("10"),
        "eleven" => Some("11"),
        "twelve" => Some("12"),
        "thirteen" => Some("13"),
        "fourteen" => Some("14"),
        "fifteen" => Some("15"),
        "sixteen" => Some("16"),
        "seventeen" => Some("17"),
        "eighteen" => Some("18"),
        "nineteen" => Some("19"),
        "twenty" => Some("20"),
        "thirty" => Some("30"),
        "forty" => Some("40"),
        "fifty" => Some("50"),
        "sixty" => Some("60"),
        "seventy" => Some("70"),
        "eighty" => Some("80"),
        "ninety" => Some("90"),
        _ => None,
    }
}

fn replace_word_numbers(input: &str) -> String {
    WORD_NUMBER_RE
        .replace_all(input, |caps: &regex::Captures| {
            let w = caps.get(0).unwrap().as_str();
            let lower = w.to_lowercase();
            word_to_number(&lower)
                .map(|s| s.to_string())
                .unwrap_or_else(|| w.to_string())
        })
        .to_string()
}

fn word_to_currency(word: &str) -> Option<&'static str> {
    match word {
        "dollar" | "dollars" => Some("USD"),
        "euro" | "euros" => Some("EUR"),
        "pound" | "pounds" => Some("GBP"),
        "yen" => Some("JPY"),
        "yuan" | "rmb" => Some("CNY"),
        "rupee" | "rupees" => Some("INR"),
        "ruble" | "rubles" => Some("RUB"),
        "won" => Some("KRW"),
        "franc" | "francs" => Some("CHF"),
        "peso" | "pesos" => Some("MXN"),
        "krona" => Some("SEK"),
        "krone" => Some("NOK"),
        "lira" => Some("TRY"),
        "bitcoin" | "btc" => Some("BTC"),
        "ethereum" | "eth" => Some("ETH"),
        _ => None,
    }
}

fn replace_currency_words(input: &str) -> String {
    CURRENCY_WORD_RE
        .replace_all(input, |caps: &regex::Captures| {
            let w = caps.get(0).unwrap().as_str();
            let lower = w.to_lowercase();
            word_to_currency(&lower)
                .map(|s| s.to_string())
                .unwrap_or_else(|| w.to_string())
        })
        .to_string()
}

#[derive(Copy, Clone, PartialEq)]
enum PrevKind {
    None,
    Operator,
    Value,
}

fn is_operator_token(token: &str) -> bool {
    let trimmed = token.trim();
    if trimmed.is_empty() {
        return false;
    }
    trimmed
        .chars()
        .all(|c| "+-*/%^=(),".contains(c) || c.is_whitespace())
}

fn is_operator_word(word: &str, config: &Config) -> bool {
    config.operators.keys().any(|op| {
        op.eq_ignore_ascii_case(word)
            || op
                .split_whitespace()
                .any(|part| part.eq_ignore_ascii_case(word))
    })
}

fn is_history_keyword(word: &str) -> bool {
    matches!(word, "sum" | "total" | "average" | "avg" | "prev")
}

fn is_datetime_keyword(word: &str) -> bool {
    matches!(
        word,
        "time"
            | "now"
            | "today"
            | "tomorrow"
            | "yesterday"
            | "ago"
            | "before"
            | "after"
            | "next"
            | "last"
            | "this"
            | "between"
            | "from"
            | "in"
            | "to"
    )
}

fn is_inline_operator_keyword(word: &str) -> bool {
    matches!(word, "in" | "to" | "of" | "from" | "per")
}

fn is_currency_word(word: &str) -> bool {
    matches!(
        word,
        "dollar"
            | "dollars"
            | "euro"
            | "euros"
            | "pound"
            | "pounds"
            | "yen"
            | "yuan"
            | "rmb"
            | "rupee"
            | "rupees"
            | "ruble"
            | "rubles"
            | "won"
            | "franc"
            | "francs"
            | "peso"
            | "pesos"
            | "krona"
            | "krone"
            | "lira"
            | "bitcoin"
            | "btc"
            | "ethereum"
            | "eth"
    )
}

fn strip_inline_annotations(
    input: &str,
    variables: &HashMap<String, (f64, Option<String>)>,
    config: &Config,
) -> String {
    let mut out: Vec<String> = Vec::new();
    let mut prev_kind = PrevKind::None;

    let tokens: Vec<&str> = input.split_whitespace().collect();
    for (idx, token) in tokens.iter().enumerate() {
        let trimmed = token.trim();
        if trimmed.is_empty() {
            continue;
        }
        if trimmed.starts_with("//") || trimmed.starts_with('#') {
            break;
        }
        if let Some(pos) = trimmed.find("//").or_else(|| trimmed.find('#')) {
            if pos == 0 {
                break;
            }
            let before = &trimmed[..pos];
            if !before.is_empty() {
                out.push(before.to_string());
            }
            break;
        }

        // Preserve operator-only tokens (e.g., "+", "-", "()", etc.)
        if is_operator_token(trimmed) {
            out.push(trimmed.to_string());
            if trimmed.contains(')') {
                prev_kind = PrevKind::Value;
            } else {
                prev_kind = PrevKind::Operator;
            }
            continue;
        }

        let cleaned = trimmed
            .trim_matches(|c: char| !c.is_alphanumeric() && c != '/' && c != '_')
            .to_string();
        if cleaned.is_empty() {
            out.push(trimmed.to_string());
            prev_kind = PrevKind::Operator;
            continue;
        }

        let lower = cleaned.to_lowercase();
        let upper = cleaned.to_uppercase();
        let next_is_conversion = tokens
            .get(idx + 1)
            .map(|next| {
                next.trim_matches(|c: char| !c.is_alphanumeric() && c != '/' && c != '_')
                    .to_lowercase()
            })
            .map(|next| next == "in" || next == "to")
            .unwrap_or(false);

        let has_digits = cleaned.chars().any(|c| c.is_ascii_digit());
        let is_known_operator = is_operator_word(cleaned.as_str(), config);
        let is_known_function = config.functions.contains_key(cleaned.as_str());
        let is_known_scale = config.scales.contains_key(cleaned.as_str());
        let is_known_unit = config.length_units.contains_key(&lower)
            || config.time_units.contains_key(&lower)
            || config.temperature_units.contains_key(&lower)
            || config.area_units.contains_key(&lower)
            || config.volume_units.contains_key(&lower)
            || config.weight_units.contains_key(&lower)
            || config.angular_units.contains_key(&lower)
            || config.data_units.contains_key(&lower)
            || crate::conversions::data_unit(&cleaned).is_some()
            || config.speed_units.contains_key(&lower);
        let is_known_currency =
            config.currencies.contains_key(upper.as_str()) || is_currency_word(&lower);
        let is_known_keyword = is_history_keyword(&lower)
            || is_datetime_keyword(&lower)
            || is_inline_operator_keyword(&lower);
        let is_known_variable = variables.contains_key(cleaned.as_str());

        let looks_like_code = cleaned.len() >= 2 && cleaned.chars().all(|c| c.is_ascii_uppercase());

        if has_digits
            || is_known_operator
            || is_known_function
            || is_known_scale
            || is_known_unit
            || is_known_currency
            || is_known_keyword
            || is_known_variable
            || looks_like_code
        {
            out.push(trimmed.to_string());
            if is_known_operator || is_inline_operator_keyword(&lower) || is_known_function {
                prev_kind = PrevKind::Operator;
            } else {
                prev_kind = PrevKind::Value;
            }
            continue;
        }

        // Unknown word: treat as inline annotation if it follows a value.
        if prev_kind == PrevKind::Value && !next_is_conversion {
            continue;
        }

        out.push(trimmed.to_string());
        prev_kind = PrevKind::Value;
    }

    out.join(" ")
}

pub fn preprocess(input: &str, state: &mut AppState, config: &Config) -> String {
    let variables_guard = state
        .variables
        .read()
        .expect("Failed to acquire read lock on variables");
    preprocess_input(input, &variables_guard, config)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::config::Config;
    use std::collections::HashMap;

    #[test]
    fn test_strip_block_comments() {
        let config = Config::default();
        let vars: HashMap<String, (f64, Option<String>)> = HashMap::new();
        let input = "10 + /* note */ 5";
        let out = preprocess_input(input, &vars, &config);
        assert!(out.contains("10"));
        assert!(out.contains("+"));
        assert!(out.contains("5"));
        assert!(!out.contains("note"));
    }

    #[test]
    fn test_inline_annotations_are_removed_after_values() {
        let config = Config::default();
        let vars: HashMap<String, (f64, Option<String>)> = HashMap::new();
        let input = "14.50 CAD internet + 16 USD spotify";
        let out = preprocess_input(input, &vars, &config);
        assert!(!out.contains("internet"));
        assert!(!out.contains("spotify"));
    }

    #[test]
    fn test_unknown_word_at_start_is_preserved() {
        let config = Config::default();
        let vars: HashMap<String, (f64, Option<String>)> = HashMap::new();
        let input = "foo + 2";
        let out = preprocess_input(input, &vars, &config);
        assert!(out.contains("foo"));
    }
}
