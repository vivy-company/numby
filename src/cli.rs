use ansi_term::Colour;


use crate::models::AppState;

/// Evaluate an expression and print the result.
pub fn evaluate_expression(expression: &str, state: &mut AppState, registry: &crate::evaluator::AgentRegistry) {
    if let Some((result, _)) = registry.evaluate(expression, state) {
        println!("{}", Colour::Green.paint(result));
    } else {
        eprintln!("{}", Colour::Red.paint("Error evaluating expression"));
    }
}
