use crate::config::Config;
use crate::highlight::{highlight_spans, HighlightKind};
use crate::models::AppState;
use crate::security::MAX_EXPR_LENGTH;

/// Return only the common suffix, so ambiguous names never pick an arbitrary variable.
pub(crate) fn variable_suffix(
    input: &str,
    cursor: usize,
    state: &AppState,
    config: &Config,
) -> Option<String> {
    if input.len() > MAX_EXPR_LENGTH || !input.is_char_boundary(cursor) {
        return None;
    }
    let identifier = |c: char| c.is_alphanumeric() || c == '_';
    if input[cursor..].chars().next().is_some_and(identifier) {
        return None;
    }
    let start = input[..cursor]
        .char_indices()
        .rev()
        .take_while(|(_, c)| identifier(*c))
        .last()?
        .0;
    let prefix = &input[start..cursor];
    if !crate::parser::is_variable_name(prefix) {
        return None;
    }
    let spans = highlight_spans(input, state, config);
    if spans.iter().any(|span| {
        span.kind == HighlightKind::Comment
            && (span.start as usize) <= start
            && start < (span.start + span.len) as usize
    }) {
        return None;
    }
    let variables = state.variables.read().ok()?;
    let definitions = spans
        .iter()
        .filter(|span| span.kind == HighlightKind::Variable)
        .filter_map(|span| input.get(span.start as usize..(span.start + span.len) as usize));
    let mut matches = variables
        .keys()
        .map(String::as_str)
        .chain(definitions)
        .filter(|name| name.starts_with(prefix));
    let mut common = matches.next()?.to_string();
    for name in matches {
        let count = common
            .chars()
            .zip(name.chars())
            .take_while(|(a, b)| a == b)
            .count();
        common = common.chars().take(count).collect();
    }
    let suffix = common.get(prefix.len()..)?;
    if suffix.is_empty() || input.len().checked_add(suffix.len())? > MAX_EXPR_LENGTH {
        return None;
    }
    Some(suffix.to_string())
}
