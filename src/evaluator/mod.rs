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
pub use core::{evaluate_expr, evaluate_expr_with_original, evaluate_unit_conversion, EvalContext};
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
            Box::new(agents::DateTimeAgent),
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

    /// Evaluate an expression mutating state but without adding to history.
    ///
    /// Used by background re-evaluation in the TUI so that variables update
    /// immediately while history remains untouched until the user explicitly
    /// submits the expression.
    pub fn evaluate_without_history(
        &self,
        input: &str,
        state: &mut AppState,
    ) -> Option<(String, bool)> {
        // Validate input size
        if let Err(e) = validate_input_size(input) {
            eprintln!("{}", crate::fl!("input-validation-error", "error" => &e));
            return None;
        }
        self.evaluate_with_history(input, state, false)
    }

    fn evaluate_with_history(
        &self,
        input: &str,
        state: &mut AppState,
        modify_history: bool,
    ) -> Option<(String, bool)> {
        // Store original input so agents can access it
        if let Ok(mut orig) = state.original_input.write() {
            *orig = Some(input.to_string());
        }
        let preprocessed = preprocess(input, state, &self.config);
        // Check if this is a history command (don't add history command results to history)
        let is_history_command = matches!(
            preprocessed.trim(),
            "sum" | "total" | "average" | "avg" | "prev"
        );

        for agent in &self.agents {
            if agent.can_handle(&preprocessed, state) {
                let result = agent.process(&preprocessed, state, &self.config);
                if let Some((_res, add_to_history, raw_value, unit)) = &result {
                    if modify_history && *add_to_history && !is_history_command {
                        // Add to history if it's an expression and modify_history is true
                        // but NOT if it's a history command
                        if let Some(value) = raw_value {
                            let _ = state.add_history(*value, unit.clone());
                        }
                    }
                    return result.map(|(res, add_to_history, _, _)| (res, add_to_history));
                }

                // If this agent can't fully handle the input (returns None),
                // fall through to lower-priority agents instead of aborting the pipeline.
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
        assert_eq!(history[0].value, 400.0);
        assert_eq!(history[1].value, 300.0);
        assert_eq!(history[2].value, 2000.0);
        assert_eq!(history[3].value, 100.0);

        let sum: f64 = history.iter().map(|h| h.value).sum();
        assert_eq!(sum, 2800.0, "Sum should be 2800, not 800");
        drop(history);

        // Test sum command
        let result = registry.evaluate("sum", &mut state);
        assert!(result.is_some());
        let (sum_str, _) = result.unwrap();
        assert_eq!(sum_str, "2800", "sum command should return 2800");
    }

    #[test]
    fn test_history_keywords_inside_math_expression() {
        let config = Config::default();
        let registry = AgentRegistry::new(&config).expect("Failed to create registry");
        let mut state = AppStateBuilder::new(&config).build();

        let inputs = vec!["10", "5"];
        for input in &inputs {
            let _ = registry.evaluate(input, &mut state);
            std::thread::sleep(std::time::Duration::from_millis(51));
        }

        let result = registry.evaluate("sum + 100", &mut state);
        assert!(result.is_some(), "sum should be usable in expressions");
        let (val, _) = result.unwrap();
        assert!(val.contains("115"), "expected 115, got {}", val);
    }

    #[test]
    fn test_sum_to_currency_with_trailing_math() {
        let config = Config::default();
        let registry = AgentRegistry::new(&config).expect("Failed to create registry");
        let mut state = AppStateBuilder::new(&config).build();

        let inputs = vec!["400 USD", "300 USD"];
        for input in &inputs {
            let _ = registry.evaluate(input, &mut state);
            std::thread::sleep(std::time::Duration::from_millis(51));
        }

        let result = registry.evaluate("sum to USD + 100", &mut state);
        assert!(
            result.is_some(),
            "conversion with trailing math should work"
        );
        let (val, _) = result.unwrap();
        assert!(
            val.to_uppercase().contains("USD"),
            "result should keep USD unit: {}",
            val
        );
        assert!(val.contains("800"), "expected around 800, got {}", val);
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

    #[test]
    fn test_variable_multiplication_with_units() {
        let config = Config::default();
        let registry = AgentRegistry::new(&config).expect("Failed to create registry");
        let mut state = AppStateBuilder::new(&config).build();

        // Test case: room_length = 5 meters to feet
        let result = registry.evaluate("room_length = 5 meters to feet", &mut state);
        assert!(result.is_some());
        std::thread::sleep(std::time::Duration::from_millis(51));

        // room_width = 4 meters to feet
        let result = registry.evaluate("room_width = 4 meters to feet", &mut state);
        assert!(result.is_some());
        std::thread::sleep(std::time::Duration::from_millis(51));

        // area = room_length * room_width
        let result = registry.evaluate("area = room_length * room_width", &mut state);
        assert!(result.is_some(), "Failed to multiply variables with units");
        let (area_str, _) = result.unwrap();
        // 16.40 feet * 13.12 feet ≈ 215.2 square feet
        assert!(area_str.contains("215") || area_str.contains("214"));
        std::thread::sleep(std::time::Duration::from_millis(51));

        // cost_per_sqft = 8.50 USD
        let result = registry.evaluate("cost_per_sqft = 8.50 USD", &mut state);
        assert!(result.is_some());
        std::thread::sleep(std::time::Duration::from_millis(51));

        // total_cost = area * cost_per_sqft
        let result = registry.evaluate("total_cost = area * cost_per_sqft", &mut state);
        assert!(result.is_some(), "Failed to multiply area by cost");
        let (total_str, _) = result.unwrap();
        // 215.2 * 8.50 ≈ 1829 USD
        // Result should be in USD, not feet
        assert!(
            total_str.contains("USD") || total_str.to_uppercase().contains("USD"),
            "Result should be in USD, got: {}",
            total_str
        );
        assert!(
            total_str.contains("1") && total_str.contains("8"),
            "Result should be around 1829, got: {}",
            total_str
        );
    }

    #[test]
    fn test_comma_separated_numbers() {
        let config = Config::default();
        let registry = AgentRegistry::new(&config).expect("Failed to create registry");
        let mut state = AppStateBuilder::new(&config).build();

        // Test single number with comma
        let result = registry.evaluate("10,000", &mut state);
        assert!(result.is_some(), "Failed to parse number with comma");
        std::thread::sleep(std::time::Duration::from_millis(51));

        // Test addition with comma-separated numbers
        let result = registry.evaluate("10,000 + 5,000", &mut state);
        assert!(result.is_some(), "Failed to add comma-separated numbers");
        let (sum_str, _) = result.unwrap();
        assert!(sum_str.contains("15"), "Result should contain 15");
        std::thread::sleep(std::time::Duration::from_millis(51));

        // Test with currency unit
        let result = registry.evaluate("10,000 USD", &mut state);
        assert!(
            result.is_some(),
            "Failed to parse comma number with currency"
        );
        let (val_str, _) = result.unwrap();
        assert!(
            val_str.contains("10") && val_str.contains("USD"),
            "Result should contain 10 and USD, got: {}",
            val_str
        );
    }

    #[test]
    fn test_variable_copy() {
        let config = Config::default();
        let registry = AgentRegistry::new(&config).expect("Failed to create registry");
        let mut state = AppStateBuilder::new(&config).build();

        // Create variable x = 5
        let result = registry.evaluate("x = 5", &mut state);
        assert!(result.is_some(), "Failed to create variable x");
        std::thread::sleep(std::time::Duration::from_millis(51));

        // Verify x exists
        let vars = state.variables.read().unwrap();
        assert!(vars.contains_key("x"), "Variable x should exist");
        assert_eq!(vars.get("x").unwrap().0, 5.0);
        drop(vars);

        // Copy x to y
        let result = registry.evaluate("y = x", &mut state);
        assert!(result.is_some(), "Failed to copy variable x to y");
        std::thread::sleep(std::time::Duration::from_millis(51));

        // Verify both x and y exist
        let vars = state.variables.read().unwrap();
        assert!(vars.contains_key("x"), "Variable x should still exist");
        assert!(vars.contains_key("y"), "Variable y should exist");
        assert_eq!(vars.get("x").unwrap().0, 5.0);
        assert_eq!(vars.get("y").unwrap().0, 5.0);
    }

    #[test]
    fn test_variable_line_cleanup() {
        let config = Config::default();
        let registry = AgentRegistry::new(&config).expect("Failed to create registry");
        let mut state = AppStateBuilder::new(&config).build();

        // Simulate line 0 creating variable n = 10
        {
            let mut current_line = state.current_line.write().unwrap();
            *current_line = Some(0);
        }
        let result = registry.evaluate("n = 10", &mut state);
        assert!(result.is_some(), "Failed to create variable n");
        {
            let mut current_line = state.current_line.write().unwrap();
            *current_line = None;
        }
        std::thread::sleep(std::time::Duration::from_millis(51));

        // Verify n exists
        let vars = state.variables.read().unwrap();
        assert!(vars.contains_key("n"), "Variable n should exist");
        assert_eq!(vars.get("n").unwrap().0, 10.0);
        drop(vars);

        // Now simulate editing line 0 to create ns = 10 instead
        {
            let mut current_line = state.current_line.write().unwrap();
            *current_line = Some(0);
        }
        let result = registry.evaluate("ns = 10", &mut state);
        assert!(result.is_some(), "Failed to create variable ns");
        {
            let mut current_line = state.current_line.write().unwrap();
            *current_line = None;
        }
        std::thread::sleep(std::time::Duration::from_millis(51));

        // Verify n is deleted and ns exists
        let vars = state.variables.read().unwrap();
        assert!(!vars.contains_key("n"), "Variable n should be deleted");
        assert!(vars.contains_key("ns"), "Variable ns should exist");
        assert_eq!(vars.get("ns").unwrap().0, 10.0);
    }
}
