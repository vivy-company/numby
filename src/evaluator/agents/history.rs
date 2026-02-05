use crate::evaluator::agents::PRIORITY_HISTORY;
use crate::models::{Agent, AppState};
use crate::prettify::format_number;

pub struct HistoryAgent;

impl Agent for HistoryAgent {
    fn priority(&self) -> i32 {
        PRIORITY_HISTORY
    }

    fn can_handle(&self, input: &str, _state: &AppState) -> bool {
        let trimmed = input.trim();
        matches!(trimmed, "sum" | "total" | "average" | "avg" | "prev")
    }

    fn process(
        &self,
        input: &str,
        state: &mut AppState,
        _config: &crate::config::Config,
    ) -> Option<(String, bool, Option<f64>, Option<String>)> {
        let trimmed = input.trim();
        let history_guard = state
            .history
            .read()
            .expect("Failed to acquire read lock on history");
        let unit = crate::evaluator::core::all_same_unit(&history_guard);
        match trimmed {
            "sum" | "total" => {
                let sum = history_guard.iter().map(|h| h.value).sum::<f64>();
                let formatted_sum =
                    format_number(sum, state.number_format.as_str(), state.number_max_decimals);
                let formatted = if let Some(ref u) = unit {
                    format!("{} {}", formatted_sum, u)
                } else {
                    formatted_sum
                };
                Some((formatted, true, Some(sum), unit.clone()))
            }
            "average" | "avg" => {
                if history_guard.is_empty() {
                    None
                } else {
                    let avg = history_guard.iter().map(|h| h.value).sum::<f64>()
                        / history_guard.len() as f64;
                    let formatted_avg =
                        format_number(avg, state.number_format.as_str(), state.number_max_decimals);
                    let formatted = if let Some(ref u) = unit {
                        format!("{} {}", formatted_avg, u)
                    } else {
                        formatted_avg
                    };
                    Some((formatted, true, Some(avg), unit.clone()))
                }
            }
            "prev" => history_guard.last().map(|h| {
                let formatted_value = format_number(
                    h.value,
                    state.number_format.as_str(),
                    state.number_max_decimals,
                );
                let formatted = if let Some(ref u) = h.unit {
                    format!("{} {}", formatted_value, u)
                } else {
                    formatted_value
                };
                (formatted, true, Some(h.value), h.unit.clone())
            }),
            _ => None,
        }
    }
}
