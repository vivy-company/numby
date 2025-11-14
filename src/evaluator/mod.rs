//! Expression evaluation and agent registry.
//!
//! This module coordinates different evaluation agents (math, units, variables, etc.)
//! to process user input and return results.

pub mod agents;
pub mod cache;
mod core;
pub mod error;
pub mod events;
mod preprocessing;

pub use cache::CacheManager;
pub use core::{evaluate_expr, evaluate_unit_conversion, EvalContext};
pub use error::{EvaluatorError, Result};
pub use events::{EventSubscriber, StateEvent};
pub use preprocessing::{preprocess, preprocess_input};

use crate::config::Config;
use crate::models::{Agent, AppState};
use crate::security::validate_input_size;

/// Registry of evaluation agents that process user input.
///
/// Agents are checked in priority order until one can handle the input.
///
/// # Examples
///
/// ```
/// use numby::config::Config;
/// use numby::evaluator::AgentRegistry;
/// use numby::models::AppState;
///
/// let config = Config::default();
/// let registry = AgentRegistry::new(&config).expect("Failed to create registry");
/// let mut state = AppState::builder(&config).build();
///
/// // Evaluate basic math
/// let result = registry.evaluate("2 + 2", &mut state);
/// assert!(result.is_some());
/// ```
pub struct AgentRegistry {
    agents: Vec<Box<dyn Agent>>,
    config: std::sync::Arc<Config>,
}

impl AgentRegistry {
    /// Create a new agent registry with default agents.
    ///
    /// # Errors
    ///
    /// Returns error if agent priorities conflict or no agents registered.
    ///
    /// # Examples
    ///
    /// ```
    /// use numby::config::Config;
    /// use numby::evaluator::AgentRegistry;
    ///
    /// let config = Config::default();
    /// let registry = AgentRegistry::new(&config).expect("Failed to create registry");
    /// ```
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
        Ok(Self {
            agents,
            config: std::sync::Arc::new(config.clone()),
        })
    }

    fn validate_agents(agents: &[Box<dyn Agent>]) -> Result<()> {
        let mut priorities = std::collections::HashMap::new();

        for agent in agents {
            let priority = agent.priority();
            if priorities.contains_key(&priority) {
                return Err(EvaluatorError::ConfigError(format!(
                    "Priority conflict: {} has same priority as another agent",
                    priority
                )));
            }
            priorities.insert(priority, ());
        }

        if agents.is_empty() {
            return Err(EvaluatorError::ConfigError(
                "No agents registered".to_string(),
            ));
        }

        Ok(())
    }

    /// Evaluate an expression and modify state (e.g., add to history).
    ///
    /// # Arguments
    ///
    /// * `input` - Expression to evaluate
    /// * `state` - Mutable application state
    ///
    /// # Returns
    ///
    /// Returns Some((result_string, should_add_to_history)) or None if no agent could handle input.
    ///
    /// # Examples
    ///
    /// ```
    /// use numby::config::Config;
    /// use numby::evaluator::AgentRegistry;
    /// use numby::models::AppState;
    ///
    /// let config = Config::default();
    /// let registry = AgentRegistry::new(&config).unwrap();
    /// let mut state = AppState::builder(&config).build();
    ///
    /// let result = registry.evaluate("10 + 5", &mut state);
    /// assert!(result.is_some());
    /// ```
    pub fn evaluate(&self, input: &str, state: &mut AppState) -> Option<(String, bool)> {
        // Validate input size
        if let Err(e) = validate_input_size(input) {
            eprintln!("{}", crate::fl!("input-validation-error", "error" => &e));
            return None;
        }

        self.evaluate_with_history(input, state, true)
    }

    /// Evaluate expression for display only (does not modify state).
    ///
    /// Used for showing live preview of what would happen without committing changes.
    ///
    /// # Arguments
    ///
    /// * `input` - Expression to evaluate
    /// * `state` - Read-only application state
    ///
    /// # Returns
    ///
    /// Returns Some((result_string, should_add_to_history)) or None if no agent could handle input.
    ///
    /// # Examples
    ///
    /// ```
    /// use numby::config::Config;
    /// use numby::evaluator::AgentRegistry;
    /// use numby::models::AppState;
    ///
    /// let config = Config::default();
    /// let registry = AgentRegistry::new(&config).unwrap();
    /// let state = AppState::builder(&config).build();
    ///
    /// // Preview without modifying state
    /// let result = registry.evaluate_for_display("x = 100", &state);
    /// // State remains unchanged
    /// ```
    pub fn evaluate_for_display(&self, input: &str, state: &AppState) -> Option<(String, bool)> {
        // Validate input size
        if let Err(e) = validate_input_size(input) {
            eprintln!("{}", crate::fl!("input-validation-error", "error" => &e));
            return None;
        }
        let mut temp_state = state.clone();
        temp_state.is_display_only = true;
        self.evaluate_with_history(input, &mut temp_state, false)
    }

    fn evaluate_with_history(
        &self,
        input: &str,
        state: &mut AppState,
        modify_history: bool,
    ) -> Option<(String, bool)> {
        let preprocessed = preprocess(input, state, &self.config);
        // Check if this is a history command (don't add history command results to history)
        let is_history_command = matches!(
            preprocessed.trim(),
            "sum" | "total" | "average" | "avg" | "prev"
        );

        for agent in &self.agents {
            if agent.can_handle(&preprocessed, state) {
                let result = agent.process(&preprocessed, state, &self.config);
                if let Some((_res, add_to_history, raw_value)) = &result {
                    if modify_history && *add_to_history && !is_history_command {
                        // Add to history if it's an expression and modify_history is true
                        // but NOT if it's a history command
                        if let Some(value) = raw_value {
                            let _ = state.add_history(*value);
                        }
                    }
                }
                return result.map(|(res, add_to_history, _)| (res, add_to_history));
            }
        }
        None
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::models::AppStateBuilder;

    #[test]
    fn test_history_sum_with_prettified_numbers() {
        let config = Config::default();
        let registry = AgentRegistry::new(&config).expect("Failed to create registry");
        let mut state = AppStateBuilder::new(&config).build();

        // Test case from bug: 400, 300, 2000, 100 should sum to 2800
        // Previously, 2000 was formatted as "2.0k" and failed to parse, so only 800 was summed
        let inputs = vec!["400", "300", "2000", "100"];

        for input in &inputs {
            let _ = registry.evaluate(input, &mut state);
            std::thread::sleep(std::time::Duration::from_millis(51));
        }

        // Check history contains all values
        let history = state.history.read().unwrap();
        assert_eq!(history.len(), 4, "All 4 values should be in history");
        assert_eq!(history[0], 400.0);
        assert_eq!(history[1], 300.0);
        assert_eq!(history[2], 2000.0);
        assert_eq!(history[3], 100.0);

        let sum: f64 = history.iter().sum();
        assert_eq!(sum, 2800.0, "Sum should be 2800, not 800");
        drop(history);

        // Test sum command
        let result = registry.evaluate("sum", &mut state);
        assert!(result.is_some());
        let (sum_str, _) = result.unwrap();
        assert_eq!(sum_str, "2800", "sum command should return 2800");
    }

    #[test]
    fn test_variable_stability_across_lines() {
        let config = Config::default();
        let registry = AgentRegistry::new(&config).expect("Failed to create registry");
        let mut state = AppStateBuilder::new(&config).build();

        // Line 1: Create first variable
        let result1 = registry.evaluate("hause = 100000 USD", &mut state);
        assert!(result1.is_some());
        let (val1, _) = result1.unwrap();
        assert!(
            val1.contains("100")
                || val1.contains("100000")
                || val1.contains("100,000")
                || val1.contains("100k")
        );

        // Verify variable was stored
        let vars = state.variables.read().unwrap();
        assert!(vars.contains_key("hause"));
        assert_eq!(vars.get("hause").unwrap().0, 100000.0);
        drop(vars);

        // Wait for rate limit
        std::thread::sleep(std::time::Duration::from_millis(51));

        // Line 2: Create second variable
        let result2 = registry.evaluate("salary = 4000 USD", &mut state);
        assert!(result2.is_some());
        let (val2, _) = result2.unwrap();
        assert!(
            val2.contains("4")
                || val2.contains("4000")
                || val2.contains("4,000")
                || val2.contains("4k")
        );

        // Verify both variables exist
        let vars = state.variables.read().unwrap();
        assert!(vars.contains_key("hause"));
        assert!(vars.contains_key("salary"));
        assert_eq!(vars.get("hause").unwrap().0, 100000.0);
        assert_eq!(vars.get("salary").unwrap().0, 4000.0);
        drop(vars);

        // Wait for rate limit
        std::thread::sleep(std::time::Duration::from_millis(51));

        // Line 3: Use variables in calculation
        let result3 = registry.evaluate("hause / salary", &mut state);
        assert!(result3.is_some());
        let (val3, _) = result3.unwrap();
        // 100000 / 4000 = 25
        assert!(val3.contains("25"));

        // Verify variables still have correct values
        let vars = state.variables.read().unwrap();
        assert_eq!(vars.get("hause").unwrap().0, 100000.0);
        assert_eq!(vars.get("salary").unwrap().0, 4000.0);
    }

    #[test]
    fn test_display_mode_does_not_modify_variables() {
        let config = Config::default();
        let registry = AgentRegistry::new(&config).expect("Failed to create registry");
        let mut state = AppStateBuilder::new(&config).build();

        // Set up initial variable
        registry.evaluate("x = 100", &mut state);

        // Verify x = 100
        let vars = state.variables.read().unwrap();
        assert_eq!(vars.get("x").unwrap().0, 100.0);
        drop(vars);

        // Call evaluate_for_display with assignment (should not modify variables)
        let display_result = registry.evaluate_for_display("x = 200", &state);
        assert!(display_result.is_some());

        // Verify x is still 100 (not modified by display evaluation)
        let vars = state.variables.read().unwrap();
        assert_eq!(vars.get("x").unwrap().0, 100.0);
        drop(vars);

        // Wait for rate limit
        std::thread::sleep(std::time::Duration::from_millis(51));

        // Call evaluate with assignment (should modify variables)
        registry.evaluate("x = 200", &mut state);

        // Verify x is now 200
        let vars = state.variables.read().unwrap();
        assert_eq!(vars.get("x").unwrap().0, 200.0);
    }
}
