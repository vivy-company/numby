use crate::models::{Agent, AppState};
use crate::evaluator::evaluate_expr;

pub struct VariableAgent;

impl Agent for VariableAgent {
    fn priority(&self) -> i32 { 20 }

    fn can_handle(&self, input: &str, _state: &AppState) -> bool {
        input.contains('=')
    }

    fn process(&self, input: &str, state: &mut AppState, _config: &crate::config::Config) -> Option<(String, bool)> {
        let parts: Vec<&str> = input.split('=').collect();
        if parts.len() == 2 {
            let var = parts[0].trim();
            let val_expr = parts[1].trim();
            // Clone variables to avoid deadlock
            let mut vars_clone = state.variables.read().expect("Failed to acquire read lock on variables").clone();
            if let Some(val_str) = evaluate_expr(val_expr, &mut vars_clone, &state.history.read().expect("Failed to acquire read lock on history").clone(), &state.length_units, &state.time_units, &state.temperature_units, &state.area_units, &state.volume_units, &state.weight_units, &state.angular_units, &state.data_units, &state.speed_units, &state.rates, &std::collections::HashMap::new()) {
                let parts_val: Vec<&str> = val_str.split_whitespace().collect();
                if let Some(num_str) = parts_val.first() {
                    if let Ok(val) = num_str.parse::<f64>() {
                        let unit = if parts_val.len() > 1 { Some(parts_val[1].to_string()) } else { None };
                        state.variables.write().expect("Failed to acquire write lock on variables").insert(var.to_string(), (val, unit));
                        // Invalidate caches since variables changed
                        state.display_cache.write().expect("Failed to acquire write lock on display_cache").clear();
                        state.highlight_cache.write().expect("Failed to acquire write lock on highlight_cache").clear();
                    }
                }
                return Some((val_str, true));
            }
        }
        None
    }
}
