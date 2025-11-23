use nu_ansi_term::Color;

use crate::models::AppState;

/// Evaluate an expression and print the result.
/// Supports multi-line expressions separated by newlines.
pub fn evaluate_expression(
    expression: &str,
    state: &mut AppState,
    registry: &crate::evaluator::AgentRegistry,
    format: &str,
) {
    // Collect evaluated lines
    let mut rows: Vec<(String, Option<String>)> = Vec::new();
    for line in expression.lines() {
        let trimmed = line.trim();
        if trimmed.is_empty() || trimmed.starts_with("//") || trimmed.starts_with("#") {
            continue;
        }
        let result = registry.evaluate(trimmed, state).map(|(r, _)| r);
        rows.push((trimmed.to_string(), result));
    }

    if rows.is_empty() {
        eprintln!(
            "{}",
            Color::Red.paint(crate::fl!("error-evaluating-expression"))
        );
        return;
    }

    match format.to_lowercase().as_str() {
        "markdown" => print_markdown(&rows),
        "table" => print_table(&rows),
        _ => print_plain(&rows),
    }
}

fn print_plain(rows: &[(String, Option<String>)]) {
    for (_expr, res) in rows {
        if let Some(r) = res {
            println!("{}", Color::Green.paint(r));
        } else {
            eprintln!(
                "{}",
                Color::Red.paint(crate::fl!("error-evaluating-expression"))
            );
        }
    }
}

fn print_markdown(rows: &[(String, Option<String>)]) {
    println!("| Expression | Result |\n|---|---|");
    for (expr, res) in rows {
        let result = res
            .clone()
            .unwrap_or_else(|| crate::fl!("error-evaluating-expression"));
        println!(
            "| `{}` | `{}` |",
            expr.replace("|", "\\|"),
            result.replace("|", "\\|")
        );
    }
}

fn print_table(rows: &[(String, Option<String>)]) {
    let expr_width = rows.iter().map(|(e, _)| e.len()).max().unwrap_or(0).max(10);
    let res_width = rows
        .iter()
        .map(|(_, r)| r.as_ref().map(|s| s.len()).unwrap_or(5))
        .max()
        .unwrap_or(5)
        .max(6);
    let sep = format!(
        "+-{:->expr$}-+-{:->res$}-+",
        "",
        "",
        expr = expr_width,
        res = res_width
    );
    println!("{}", sep);
    println!(
        "| {:expr_width$} | {:res_width$} |",
        "Expression",
        "Result",
        expr_width = expr_width,
        res_width = res_width
    );
    println!("{}", sep);
    for (expr, res) in rows {
        let result = res
            .clone()
            .unwrap_or_else(|| crate::fl!("error-evaluating-expression"));
        println!(
            "| {:expr_width$} | {:res_width$} |",
            expr,
            result,
            expr_width = expr_width,
            res_width = res_width
        );
    }
    println!("{}", sep);
}
