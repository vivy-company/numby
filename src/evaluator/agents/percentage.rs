use crate::evaluator::agents::PRIORITY_PERCENTAGE;
use crate::evaluator::{evaluate_expr, preprocess_input, EvalContext};
use crate::models::{Agent, AppState};
use crate::parser::parse_percentage_op;
use crate::prettify::prettify_number;
use regex::Regex;

pub struct PercentageAgent;

impl Agent for PercentageAgent {
    fn priority(&self) -> i32 {
        PRIORITY_PERCENTAGE
    }

    fn can_handle(&self, input: &str, _state: &AppState) -> bool {
        // Only handle percentage operations like "X + Y%" or "X% of Y"
        // Don't handle modulo operations like "X % Y"
        if !input.contains('%') {
            return false;
        }
        // Check if it's a percentage operation (% appears after a digit with optional whitespace before it)
        // and NOT a modulo operation (% appears between two numbers with spaces around it)
        let percent_op_pattern =
            Regex::new(r"\d+(?:\.\d+)?%").expect("Invalid regex pattern for percentage detection");
        percent_op_pattern.is_match(input)
    }

    fn process(
        &self,
        input: &str,
        state: &mut AppState,
        config: &crate::config::Config,
    ) -> Option<(String, bool, Option<f64>)> {
        // Handle "X% of Y" pattern
        let percent_of_re = Regex::new(r"(\d+(?:\.\d+)?)%\s*of\s*(.+)")
            .expect("Invalid regex pattern for percent-of expression");
        if let Some(caps) = percent_of_re.captures(input) {
            if let (Some(percent_str), Some(base_str)) = (caps.get(1), caps.get(2)) {
                if let Ok(percent) = percent_str.as_str().parse::<f64>() {
                    // Recursively evaluate the base expression
                    let mut vars_guard = state.variables.write().ok()?;
                    let history_guard = state.history.read().ok()?;

                    let preprocessed = preprocess_input(base_str.as_str(), &vars_guard, config);

                    let mut ctx = EvalContext {
                        variables: &mut vars_guard,
                        history: &history_guard,
                        length_units: &config.length_units,
                        time_units: &config.time_units,
                        temperature_units: &config.temperature_units,
                        area_units: &config.area_units,
                        volume_units: &config.volume_units,
                        weight_units: &config.weight_units,
                        angular_units: &config.angular_units,
                        data_units: &config.data_units,
                        speed_units: &config.speed_units,
                        rates: &config.currencies,
                        custom_units: &config.custom_units,
                    };

                    if let Ok(base_result) = evaluate_expr(&preprocessed, &mut ctx) {
                        let result = percent / 100.0 * base_result.value;
                        let pretty_result = prettify_number(result);

                        // Preserve unit from base if present
                        if let Some(unit) = base_result.unit {
                            return Some((
                                format!("{} {}", pretty_result, unit),
                                true,
                                Some(result),
                            ));
                        } else {
                            return Some((pretty_result, true, Some(result)));
                        }
                    }
                }
            }
        }

        // Handle "X + Y%" pattern
        if let Some(result) = parse_percentage_op(input) {
            // Extract numeric value from result string
            let numeric_value = result
                .split_whitespace()
                .next()
                .and_then(|s| s.parse::<f64>().ok());
            return Some((result, true, numeric_value));
        }
        None
    }
}
