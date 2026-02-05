use ratatui::{
    style::{Color, Style, Stylize},
    text::Span,
};

use crate::highlight::{highlight_spans, HighlightKind};
use crate::models::AppState;

pub fn compute_spans(
    line: &str,
    state: &AppState,
    config: &crate::config::Config,
) -> Vec<Span<'static>> {
    let spans = highlight_spans(line, state, config);
    if spans.is_empty() {
        return vec![Span::raw(line.to_string())];
    }

    let mut out: Vec<Span<'static>> = Vec::with_capacity(spans.len());
    for span in spans {
        let start = span.start as usize;
        let end = start.saturating_add(span.len as usize).min(line.len());
        if start >= end || start >= line.len() {
            continue;
        }
        let text = &line[start..end];
        let styled = match span.kind {
            HighlightKind::Text | HighlightKind::Number => {
                Span::styled(text.to_string(), Style::default().fg(Color::Gray))
            }
            HighlightKind::Operator
            | HighlightKind::Function
            | HighlightKind::Keyword
            | HighlightKind::Scale
            | HighlightKind::Assignment => {
                Span::styled(text.to_string(), Style::default().fg(Color::Green).bold())
            }
            HighlightKind::Constant | HighlightKind::Datetime => {
                Span::styled(text.to_string(), Style::default().fg(Color::Cyan).bold())
            }
            HighlightKind::Variable | HighlightKind::VariableUsage => {
                Span::styled(text.to_string(), Style::default().fg(Color::Blue).bold())
            }
            HighlightKind::Currency => {
                Span::styled(text.to_string(), Style::default().fg(Color::Magenta).bold())
            }
            HighlightKind::Unit => {
                Span::styled(text.to_string(), Style::default().fg(Color::Yellow).bold())
            }
            HighlightKind::Comment => {
                Span::styled(text.to_string(), Style::default().fg(Color::Gray))
            }
        };
        out.push(styled);
    }

    out
}
