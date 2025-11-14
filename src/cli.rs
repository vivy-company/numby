use nu_ansi_term::Color;

use crate::models::AppState;

/// Evaluate an expression and print the result.
pub fn evaluate_expression(
    expression: &str,
    state: &mut AppState,
    registry: &crate::evaluator::AgentRegistry,
) {
    if let Some((result, _)) = registry.evaluate(expression, state) {
        println!("{}", Color::Green.paint(result));
    } else {
        eprintln!(
            "{}",
            Color::Red.paint(crate::fl!("error-evaluating-expression"))
        );
    }
}
