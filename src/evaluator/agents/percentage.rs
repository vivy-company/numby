use regex::Regex;
use crate::models::{Agent, AppState};
use crate::evaluator::evaluate_expr;
use crate::parser::parse_percentage_op;
use crate::prettify::prettify_number;

pub struct PercentageAgent;

impl Agent for PercentageAgent {
    fn priority(&self) -> i32 { 30 }

    fn can_handle(&self, input: &str, _state: &AppState) -> bool {
        // Only handle percentage operations like "X + Y%" or "X% of Y"
        // Don't handle modulo operations like "X % Y"
        if !input.contains('%') {
            return false;
        }
        // Check if it's a percentage operation (% appears after a digit with optional whitespace before it)
        // and NOT a modulo operation (% appears between two numbers with spaces around it)
        let percent_op_pattern = Regex::new(r"\d+(?:\.\d+)?%").unwrap();
        percent_op_pattern.is_match(input)
    }

    fn process(&self, input: &str, state: &mut AppState, config: &crate::config::Config) -> Option<(String, bool)> {
        // Handle "X% of Y" pattern
        let percent_of_re = Regex::new(r"(\d+(?:\.\d+)?)%\s*of\s*(.+)").unwrap();
        if let Some(caps) = percent_of_re.captures(input) {
            if let (Some(percent_str), Some(base_str)) = (caps.get(1), caps.get(2)) {
                if let Ok(percent) = percent_str.as_str().parse::<f64>() {
                    // Recursively evaluate the base expression
                    let vars_clone = state.variables.read().unwrap().clone();
                    if let Some(base_result) = evaluate_expr(
                        base_str.as_str(),
                        &mut vars_clone.clone(),
                        &state.history.read().unwrap().clone(),
                        &config.length_units,
                        &config.time_units,
                        &config.temperature_units,
                        &config.area_units,
                        &config.volume_units,
                        &config.weight_units,
                        &config.angular_units,
                        &config.data_units,
                        &config.speed_units,
                        &config.currencies,
                        &config.custom_units,
                    ) {
                        let base_num = base_result.split_whitespace()
                            .next()
                            .unwrap_or(&base_result)
                            .parse::<f64>()
                            .unwrap_or(0.0);
                        let result = percent / 100.0 * base_num;
                        let pretty_result = prettify_number(result);

                        // Preserve unit from base if present
                        let base_parts: Vec<&str> = base_result.split_whitespace().collect();
                        if base_parts.len() > 1 {
                            return Some((format!("{} {}", pretty_result, base_parts[1]), true));
                        } else {
                            return Some((pretty_result, true));
                        }
                    }
                }
            }
        }

        // Handle "X + Y%" pattern
        if let Some(result) = parse_percentage_op(input) {
            return Some((result, true));
        }
        None
    }
}
