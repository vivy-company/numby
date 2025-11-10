use crate::models::{Agent, AppState};
use crate::evaluator::evaluate_expr;

pub struct MathAgent;

impl Agent for MathAgent {
    fn priority(&self) -> i32 { 100 } // Lowest priority

    fn can_handle(&self, _input: &str, _state: &AppState) -> bool { true }

    fn process(&self, input: &str, _state: &mut AppState, config: &crate::config::Config) -> Option<(String, bool)> {
        // evaluate_expr is static, doesn't modify state
        evaluate_expr(input, &mut std::collections::HashMap::new(), &[], &config.length_units, &config.time_units, &config.temperature_units, &config.area_units, &config.volume_units, &config.weight_units, &config.angular_units, &config.data_units, &config.speed_units, &config.currencies, &config.custom_units)
            .map(|s| (s, true))
    }
}
