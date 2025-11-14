use crate::evaluator::agents::PRIORITY_VARIABLE;
use crate::evaluator::{evaluate_expr, preprocess_input, EvalContext};
use crate::models::{Agent, AppState};
use crate::prettify::prettify_number;

pub struct VariableAgent;

impl Agent for VariableAgent {
    fn priority(&self) -> i32 {
        PRIORITY_VARIABLE
    }

    fn can_handle(&self, input: &str, _state: &AppState) -> bool {
        input.contains('=')
    }

    fn process(
        &self,
        input: &str,
        state: &mut AppState,
        config: &crate::config::Config,
    ) -> Option<(String, bool, Option<f64>)> {
        let parts: Vec<&str> = input.split('=').collect();
        if parts.len() == 2 {
            let var = parts[0].trim();
            let val_expr = parts[1].trim();

            let mut vars_guard = state.variables.write().ok()?;
            let history_guard = state.history.read().ok()?;

            let preprocessed = preprocess_input(val_expr, &vars_guard, config);

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

            if let Ok(eval_result) = evaluate_expr(&preprocessed, &mut ctx) {
                // Block variable assignments in display-only mode
                if state.is_display_only {
                    // Format the result for display but don't store it
                    let formatted = prettify_number(eval_result.value);
                    let val_str = if let Some(unit) = eval_result.unit {
                        format!("{} {}", formatted, unit)
                    } else {
                        formatted
                    };
                    return Some((val_str, true, Some(eval_result.value)));
                }

                // Insert directly since we already have the lock
                vars_guard.insert(
                    var.to_string(),
                    (eval_result.value, eval_result.unit.clone()),
                );

                // Drop locks before calling methods that might need them
                drop(vars_guard);
                drop(history_guard);

                // Publish event - CacheManager subscriber will handle invalidation
                state.publish_event(crate::evaluator::StateEvent::VariableChanged(
                    var.to_string(),
                ));

                // Format the result string for display
                let formatted = prettify_number(eval_result.value);
                let val_str = if let Some(unit) = eval_result.unit {
                    format!("{} {}", formatted, unit)
                } else {
                    formatted
                };
                return Some((val_str, true, Some(eval_result.value)));
            }
        }
        None
    }
}
