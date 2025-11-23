use crate::evaluator::agents::PRIORITY_MATH;
use crate::evaluator::{evaluate_expr, preprocess_input, EvalContext};
use crate::models::{Agent, AppState};
use crate::prettify::prettify_number;

pub struct MathAgent;

impl Agent for MathAgent {
    fn priority(&self) -> i32 {
        PRIORITY_MATH
    }

    fn can_handle(&self, _input: &str, _state: &AppState) -> bool {
        true
    }

    fn process(
        &self,
        input: &str,
        state: &mut AppState,
        config: &crate::config::Config,
    ) -> Option<(String, bool, Option<f64>, Option<String>)> {
        let mut vars_guard = state.variables.write().ok()?;
        let history_guard = state.history.read().ok()?;

        let preprocessed = preprocess_input(input, &vars_guard, config);

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

        evaluate_expr(&preprocessed, &mut ctx).ok().map(|result| {
            let formatted = prettify_number(result.value);
            let output = if let Some(unit) = &result.unit {
                format!("{} {}", formatted, unit)
            } else {
                formatted
            };
            (output, true, Some(result.value), result.unit)
        })
    }
}
