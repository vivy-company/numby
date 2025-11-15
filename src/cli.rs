use nu_ansi_term::Color;

use crate::models::AppState;

/// Evaluate an expression and print the result.
/// Supports multi-line expressions separated by newlines.
pub fn evaluate_expression(
    expression: &str,
    state: &mut AppState,
    registry: &crate::evaluator::AgentRegistry,
) {
    // Split by newlines and evaluate each line
    let lines: Vec<&str> = expression.lines().collect();
    let mut evaluated_any = false;

    for line in lines {
        let trimmed = line.trim();

        // Skip empty lines and comments
        if trimmed.is_empty() || trimmed.starts_with("//") || trimmed.starts_with("#") {
            continue;
        }

        evaluated_any = true;

        if let Some((result, _)) = registry.evaluate(trimmed, state) {
            println!("{}", Color::Green.paint(result));
        } else {
            eprintln!(
                "{}",
                Color::Red.paint(crate::fl!("error-evaluating-expression"))
            );
        }
    }

    // If no lines were evaluated, show an error
    if !evaluated_any {
        eprintln!(
            "{}",
            Color::Red.paint(crate::fl!("error-evaluating-expression"))
        );
    }
}
