use crate::evaluator::agents::PRIORITY_VARIABLE;
use crate::evaluator::{preprocess_input, EvalContext};
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
    ) -> Option<(String, bool, Option<f64>, Option<String>)> {
        // Get original input to extract the original val_expr (before variable substitution)
        // If not available, fall back to using the preprocessed input
        let original_input = state.original_input.read().ok()?.clone();
        let original_parts: Vec<&str> = if let Some(ref orig) = original_input {
            orig.split('=').collect()
        } else {
            vec![]
        };

        let parts: Vec<&str> = input.split('=').collect();
        if parts.len() == 2 {
            let var = parts[0].trim();
            let val_expr = parts[1].trim();

            // Validate variable name: not empty, valid identifier, starts with letter/underscore
            if var.is_empty()
                || val_expr.is_empty()
                || !var.chars().all(|c| c.is_alphanumeric() || c == '_')
                || !var
                    .chars()
                    .next()
                    .map(|c| c.is_alphabetic() || c == '_')
                    .unwrap_or(false)
            {
                return None;
            }
            // Use original val_expr if available, otherwise use preprocessed
            let original_val_expr = if original_parts.len() == 2 {
                original_parts[1].trim()
            } else {
                val_expr
            };

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

            // Pass original expression for unit tracking
            if let Ok(eval_result) = crate::evaluator::evaluate_expr_with_original(
                &preprocessed,
                &mut ctx,
                Some(original_val_expr),
            ) {
                // Block variable assignments in display-only mode
                if state.is_display_only {
                    // Format the result for display but don't store it
                    let formatted = prettify_number(eval_result.value);
                    let unit_clone = eval_result.unit.clone();
                    let val_str = if let Some(unit) = unit_clone.as_ref() {
                        format!("{} {}", formatted, unit)
                    } else {
                        formatted
                    };
                    return Some((val_str, true, Some(eval_result.value), unit_clone));
                }

                // Check if we're evaluating a specific line (TUI mode)
                if let Ok(current_line_guard) = state.current_line.read() {
                    if let Some(line_idx) = *current_line_guard {
                        drop(current_line_guard);

                        // Check if this line previously created a different variable
                        match state.line_variables.write() {
                            Ok(mut line_vars) => {
                                if let Some(old_var) = line_vars.get(&line_idx) {
                                    // If the variable name changed, delete the old variable
                                    if old_var != var {
                                        vars_guard.remove(old_var);
                                    }
                                }
                                // Track that this line now creates this variable
                                line_vars.insert(line_idx, var.to_string());
                            }
                            Err(e) => {
                                eprintln!(
                                    "Warning: Failed to update line variable tracking: {}",
                                    e
                                );
                            }
                        }

                        // Store the evaluated content for this line
                        // Store the ORIGINAL user input for change detection,
                        // not the preprocessed string (which already replaced variables).
                        let original_line = state
                            .original_input
                            .read()
                            .ok()
                            .and_then(|o| o.clone())
                            .unwrap_or_else(|| input.to_string());

                        match state.line_content.write() {
                            Ok(mut line_content) => {
                                line_content.insert(line_idx, original_line);
                            }
                            Err(e) => {
                                eprintln!("Warning: Failed to update line content tracking: {}", e);
                            }
                        }

                        // Note: Don't publish VariableDeleted yet - wait until new var is inserted
                        // to avoid rendering with incomplete state
                    }
                }

                // Insert directly since we already have the lock
                vars_guard.insert(
                    var.to_string(),
                    (eval_result.value, eval_result.unit.clone()),
                );

                // Drop locks before calling methods that might need them
                drop(vars_guard);
                drop(history_guard);

                // Publish VariableChanged event which will invalidate entire cache
                // This happens AFTER both delete and insert are complete
                state.publish_event(crate::evaluator::StateEvent::VariableChanged(
                    var.to_string(),
                ));

                // Format the result string for display
                let formatted = prettify_number(eval_result.value);
                let unit_clone = eval_result.unit.clone();
                let val_str = if let Some(unit) = unit_clone.as_ref() {
                    format!("{} {}", formatted, unit)
                } else {
                    formatted
                };
                return Some((val_str, true, Some(eval_result.value), unit_clone));
            }
        }
        None
    }
}
