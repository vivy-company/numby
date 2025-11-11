use crate::models::{Agent, AppState};
use crate::evaluator::{evaluate_expr, evaluate_unit_conversion, EvalContext, preprocess_input};
use crate::evaluator::agents::PRIORITY_UNIT;

pub struct UnitAgent;

impl Agent for UnitAgent {
    fn priority(&self) -> i32 { PRIORITY_UNIT }

    fn can_handle(&self, input: &str, _state: &AppState) -> bool {
        input.contains(" in ") || input.contains(" to ")
    }

    fn process(&self, input: &str, state: &mut AppState, config: &crate::config::Config) -> Option<(String, bool)> {
        let conversion_keyword = input.find(" in ").map(|pos| (" in ", pos)).or_else(|| input.find(" to ").map(|pos| (" to ", pos)));
        if let Some((kw, pos)) = conversion_keyword {
            let left = input[..pos].trim();
            let right = input[pos + kw.len()..].trim();

            // Try direct conversion first (e.g., "100 m in km")
            if let Some(val) = evaluate_unit_conversion(left, right, &state.length_units, &state.time_units, &state.temperature_units, &state.area_units, &state.volume_units, &state.weight_units, &state.angular_units, &state.data_units, &state.speed_units, &state.rates, &config.custom_units) {
                return Some((val, true));
            }

            // If direct conversion failed, try evaluating the left side as an expression
            // This handles cases like "10 + 5 m in cm" or "100 usd * 2 in jpy"
            let mut vars_guard = state.variables.write().ok()?;
            let history_guard = state.history.read().ok()?;

            let preprocessed = preprocess_input(left, &vars_guard, config);

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

            if let Ok(left_result) = evaluate_expr(&preprocessed, &mut ctx) {
                // Format the evaluated result back to string for unit conversion
                let left_result_str = if let Some(unit) = left_result.unit {
                    format!("{} {}", left_result.value, unit)
                } else {
                    left_result.value.to_string()
                };
                // Now try conversion with the evaluated result
                if let Some(val) = evaluate_unit_conversion(&left_result_str, right, &config.length_units, &config.time_units, &config.temperature_units, &config.area_units, &config.volume_units, &config.weight_units, &config.angular_units, &config.data_units, &config.speed_units, &config.currencies, &config.custom_units) {
                    return Some((val, true));
                }
            }
        }
        None
    }
}
