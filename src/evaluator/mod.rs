mod core;
mod preprocessing;
pub mod agents;
pub mod error;
pub mod cache;
pub mod events;

pub use core::{evaluate_expr, evaluate_unit_conversion, EvalContext};
pub use preprocessing::{preprocess, preprocess_input};
pub use error::{EvaluatorError, Result};
pub use cache::CacheManager;
pub use events::{StateEvent, EventSubscriber};

use crate::config::Config;
use crate::models::{Agent, AppState};
use crate::security::validate_input_size;

pub struct AgentRegistry {
    agents: Vec<Box<dyn Agent>>,
    config: std::sync::Arc<Config>,
}

impl AgentRegistry {
    pub fn new(config: &Config) -> Result<Self> {
        let mut agents: Vec<Box<dyn Agent>> = vec![
            Box::new(agents::HistoryAgent),
            Box::new(agents::VariableAgent),
            Box::new(agents::PercentageAgent),
            Box::new(agents::UnitAgent),
            Box::new(agents::MathAgent),
        ];

        Self::validate_agents(&agents)?;

        agents.sort_by_key(|a| a.priority());
        Ok(Self { agents, config: std::sync::Arc::new(config.clone()) })
    }

    fn validate_agents(agents: &[Box<dyn Agent>]) -> Result<()> {
        let mut priorities = std::collections::HashMap::new();

        for agent in agents {
            let priority = agent.priority();
            if priorities.contains_key(&priority) {
                return Err(EvaluatorError::ConfigError(
                    format!("Priority conflict: {} has same priority as another agent", priority)
                ));
            }
            priorities.insert(priority, ());
        }

        if agents.is_empty() {
            return Err(EvaluatorError::ConfigError(
                "No agents registered".to_string()
            ));
        }

        Ok(())
    }

    pub fn evaluate(&self, input: &str, state: &mut AppState) -> Option<(String, bool)> {
        // Validate input size
        if let Err(e) = validate_input_size(input) {
            eprintln!("{}", crate::fl!("input-validation-error", "error" => &e));
            return None;
        }
        self.evaluate_with_history(input, state, true)
    }

    pub fn evaluate_for_display(&self, input: &str, state: &AppState) -> Option<(String, bool)> {
        // Validate input size
        if let Err(e) = validate_input_size(input) {
            eprintln!("{}", crate::fl!("input-validation-error", "error" => &e));
            return None;
        }
        let mut temp_state = state.clone();
        self.evaluate_with_history(input, &mut temp_state, false)
    }

    fn evaluate_with_history(&self, input: &str, state: &mut AppState, modify_history: bool) -> Option<(String, bool)> {
        let preprocessed = preprocess(input, state, &self.config);
        // Check if this is a history command (don't add history command results to history)
        let is_history_command = matches!(preprocessed.trim(), "sum" | "total" | "average" | "avg" | "prev");

        for agent in &self.agents {
            if agent.can_handle(&preprocessed, state) {
                let result = agent.process(&preprocessed, state, &self.config);
                if let Some((res, add_to_history)) = &result {
                    if modify_history && *add_to_history && !is_history_command {
                        // Add to history if it's an expression and modify_history is true
                        // but NOT if it's a history command
                        if let Some(num_str) = res.split_whitespace().next() {
                            if let Ok(r) = num_str.parse::<f64>() {
                                let _ = state.add_history(r);
                            }
                        }
                    }
                }
                return result;
            }
        }
        None
    }
}
