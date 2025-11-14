use crate::models::{Agent, AppState};
use crate::evaluator::agents::PRIORITY_HISTORY;

pub struct HistoryAgent;

impl Agent for HistoryAgent {
    fn priority(&self) -> i32 { PRIORITY_HISTORY }

    fn can_handle(&self, input: &str, _state: &AppState) -> bool {
        let trimmed = input.trim();
        matches!(trimmed, "sum" | "total" | "average" | "avg" | "prev")
    }

    fn process(&self, input: &str, state: &mut AppState, _config: &crate::config::Config) -> Option<(String, bool, Option<f64>)> {
        let trimmed = input.trim();
        let history_guard = state.history.read().expect("Failed to acquire read lock on history");
        match trimmed {
            "sum" | "total" => {
                let sum = history_guard.iter().sum::<f64>();
                Some((format!("{}", sum), true, Some(sum)))
            }
            "average" | "avg" => {
                if history_guard.is_empty() {
                    None
                } else {
                    let avg = history_guard.iter().sum::<f64>() / history_guard.len() as f64;
                    Some((format!("{}", avg), true, Some(avg)))
                }
            }
            "prev" => history_guard.last().map(|&v| (format!("{}", v), true, Some(v))),
            _ => None,
        }
    }
}
