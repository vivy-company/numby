use crate::evaluator::agents::PRIORITY_HISTORY;
use crate::models::{Agent, AppState};

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
                let formatted = if let Some(ref u) = unit {
                    format!("{} {}", sum, u)
                } else {
                    format!("{}", sum)
                };
                Some((formatted, true, Some(sum), unit.clone()))
            }
            "average" | "avg" => {
                if history_guard.is_empty() {
                    None
                } else {
                    let avg = history_guard.iter().map(|h| h.value).sum::<f64>()
                        / history_guard.len() as f64;
                    let formatted = if let Some(ref u) = unit {
                        format!("{} {}", avg, u)
                    } else {
                        format!("{}", avg)
                    };
                    Some((formatted, true, Some(avg), unit.clone()))
                }
            }
            "prev" => history_guard.last().map(|h| {
                let formatted = if let Some(ref u) = h.unit {
                    format!("{} {}", h.value, u)
                } else {
                    format!("{}", h.value)
                };
                (formatted, true, Some(h.value), h.unit.clone())
            }),
            _ => None,
        }
    }
}
