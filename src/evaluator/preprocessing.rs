use regex::Regex;
use crate::config::Config;
use crate::models::AppState;
use crate::parser::{apply_function_parsing, apply_replacements};

pub fn preprocess(input: &str, state: &mut AppState, config: &Config) -> String {
    let mut expr_str = input.to_string();
    // Strip comments
    let expr_str_comments = expr_str.lines().map(|line| {
        if let Some(pos) = line.find("//").or_else(|| line.find("#")) {
            &line[..pos]
        } else {
            line
        }
    }).collect::<Vec<&str>>().join("\n");
    expr_str = expr_str_comments.trim().to_string();

    // Replace variables
    let variables_guard = state.variables.read().unwrap();
    for (var, (val, _unit)) in &*variables_guard {
        let re = Regex::new(&format!(r"\b{}\b", regex::escape(var))).unwrap();
        expr_str = re.replace_all(&expr_str, &(*val).to_string()).to_string();
    }

    // Replace operators
    for (op, repl) in &config.operators {
        expr_str = expr_str.replace(op, repl);
    }

    // Constants
    let pi_re = Regex::new(r"\bpi\b").unwrap();
    expr_str = pi_re.replace_all(&expr_str, &std::f64::consts::PI.to_string()).to_string();
    let e_re = Regex::new(r"\be\b").unwrap();
    expr_str = e_re.replace_all(&expr_str, &std::f64::consts::E.to_string()).to_string();
    let pi_upper_re = Regex::new(r"\bPI\b").unwrap();
    expr_str = pi_upper_re.replace_all(&expr_str, &std::f64::consts::PI.to_string()).to_string();
    let e_upper_re = Regex::new(r"\bE\b").unwrap();
    expr_str = e_upper_re.replace_all(&expr_str, &std::f64::consts::E.to_string()).to_string();

    // Functions
    for (func, repl) in &config.functions {
        expr_str = expr_str.replace(&format!("{} ", func), repl);
    }

    // Scales
    for (scale, factor) in &config.scales {
        let re = Regex::new(&format!(r"(\d+(?:\.\d+)?)\s*{}\b", regex::escape(scale))).unwrap();
        expr_str = re.replace_all(&expr_str, |caps: &regex::Captures| {
            if let Ok(num) = caps[1].parse::<f64>() {
                (num * factor).to_string()
            } else {
                caps[0].to_string()
            }
        }).to_string();
    }

    // Apply other replacements (binary, etc.)
    expr_str = apply_replacements(expr_str);
    expr_str = apply_function_parsing(expr_str);

    expr_str
}
