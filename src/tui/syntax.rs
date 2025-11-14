use ratatui::{
    style::{Color, Style, Stylize},
    text::Span,
};

use crate::models::AppState;
use crate::utils;

/// Tokenizes variable name part (left of =) with blue bold styling
fn tokenize_variable_name(var_part: &str) -> Vec<Span<'static>> {
    let chars: Vec<(usize, char)> = var_part.char_indices().collect();
    let mut spans = Vec::new();
    let mut pos = 0;

    while pos < chars.len() {
        if chars[pos].1.is_whitespace() {
            let start = chars[pos].0;
            while pos < chars.len() && chars[pos].1.is_whitespace() {
                pos += 1;
            }
            let end_byte = if pos < chars.len() {
                chars[pos].0
            } else {
                var_part.len()
            };
            spans.push(Span::raw(var_part[start..end_byte].to_string()));
        } else {
            let start = chars[pos].0;
            while pos < chars.len() && !chars[pos].1.is_whitespace() {
                pos += 1;
            }
            let end_byte = if pos < chars.len() {
                chars[pos].0
            } else {
                var_part.len()
            };
            let word = &var_part[start..end_byte];
            spans.push(Span::styled(
                word.to_string(),
                Style::default().fg(Color::Blue).bold(),
            ));
        }
    }

    spans
}

/// Tokenizes with highlighting for expression parts (right side of =)
fn tokenize_with_highlight(
    text: &str,
    end: usize,
    state: &AppState,
    config: &crate::config::Config,
) -> Vec<Span<'static>> {
    let chars: Vec<(usize, char)> = text.char_indices().collect();
    let mut spans = Vec::new();
    let mut pos = 0;

    while pos < chars.len() && chars[pos].0 < end {
        if chars[pos].1.is_whitespace() {
            let start = chars[pos].0;
            while pos < chars.len() && chars[pos].0 < end && chars[pos].1.is_whitespace() {
                pos += 1;
            }
            let end_byte = if pos < chars.len() {
                chars[pos].0
            } else {
                text.len()
            };
            spans.push(Span::raw(text[start..end_byte].to_string()));
        } else {
            let start = chars[pos].0;
            while pos < chars.len() && chars[pos].0 < end && !chars[pos].1.is_whitespace() {
                pos += 1;
            }
            let end_byte = if pos < chars.len() {
                chars[pos].0
            } else {
                text.len()
            };
            let word = &text[start..end_byte];
            spans.push(utils::highlight_word_owned(word, &state.variables, config));
        }
    }

    spans
}

/// Computes syntax-highlighted spans for a line of code
pub fn compute_spans(
    line: &str,
    state: &AppState,
    config: &crate::config::Config,
) -> Vec<Span<'static>> {
    let mut spans = Vec::new();

    // Find comment position
    let comment_pos = line.find("//").or_else(|| line.find("#"));
    let code_part_end = comment_pos.unwrap_or(line.len());
    let code_part = &line[..code_part_end];

    // Check for variable assignment
    if let Some(eq_pos) = code_part.find('=') {
        // Variable name part (left of =) - styled blue and bold
        let var_part = &code_part[..eq_pos];
        spans.extend(tokenize_variable_name(var_part));

        // Equals sign
        spans.push(Span::raw("=".to_string()));

        // Expression part (right of =) - with variable highlighting
        let expr_part = &code_part[eq_pos + 1..];
        spans.extend(tokenize_with_highlight(
            expr_part,
            expr_part.len(),
            state,
            config,
        ));
    } else {
        // No assignment - highlight all tokens
        spans.extend(tokenize_with_highlight(
            code_part,
            code_part_end,
            state,
            config,
        ));
    }

    // Add comment in gray
    if let Some(comment) = comment_pos.map(|p| &line[p..]) {
        spans.push(Span::styled(
            comment.to_string(),
            Style::default().fg(Color::Gray),
        ));
    }

    spans
}
