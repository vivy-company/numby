use crate::config::Config;
use crate::models::AppState;

#[repr(u8)]
#[derive(Copy, Clone, Debug, Eq, PartialEq)]
pub enum HighlightKind {
    Text = 0,
    Number = 1,
    Operator = 2,
    Keyword = 3,
    Function = 4,
    Constant = 5,
    Variable = 6,
    VariableUsage = 7,
    Assignment = 8,
    Currency = 9,
    Unit = 10,
    Comment = 11,
    Scale = 12,
    Datetime = 13,
}

#[repr(C)]
#[derive(Copy, Clone, Debug, Eq, PartialEq)]
pub struct HighlightSpan {
    pub start: u32,
    pub len: u32,
    pub kind: HighlightKind,
    pub _pad: [u8; 3],
}

impl HighlightSpan {
    fn new(start: usize, end: usize, kind: HighlightKind) -> Self {
        HighlightSpan {
            start: start as u32,
            len: (end - start) as u32,
            kind,
            _pad: [0; 3],
        }
    }
}

#[derive(Copy, Clone, Eq, PartialEq)]
enum PrevKind {
    None,
    Value,
    Operator,
}

#[derive(Copy, Clone, Eq, PartialEq)]
enum TokenKind {
    Whitespace,
    Operator,
    Word,
}

#[derive(Clone)]
struct Token {
    start: usize,
    end: usize,
    kind: TokenKind,
}

#[derive(Clone)]
struct LineInfo {
    end: usize,
    assignment_pos: Option<usize>,
}

pub fn highlight_spans(input: &str, state: &AppState, config: &Config) -> Vec<HighlightSpan> {
    let mut spans = Vec::new();
    let mut idx = 0;
    let bytes = input.as_bytes();
    let mut last_code_start = 0;
    let mut prev_kind = PrevKind::None;

    while idx < bytes.len() {
        if bytes[idx..].starts_with(b"/*") {
            if last_code_start < idx {
                spans.extend(highlight_code_segment(
                    input,
                    last_code_start,
                    idx,
                    state,
                    config,
                    &mut prev_kind,
                ));
            }
            if let Some(end) = find_subslice(bytes, b"*/", idx + 2) {
                spans.push(HighlightSpan::new(idx, end + 2, HighlightKind::Comment));
                if input[idx..end + 2].contains('\n') {
                    prev_kind = PrevKind::None;
                }
                idx = end + 2;
                last_code_start = idx;
                continue;
            } else {
                spans.push(HighlightSpan::new(idx, bytes.len(), HighlightKind::Comment));
                return spans;
            }
        }

        if bytes[idx..].starts_with(b"//") || bytes[idx] == b'#' {
            if last_code_start < idx {
                spans.extend(highlight_code_segment(
                    input,
                    last_code_start,
                    idx,
                    state,
                    config,
                    &mut prev_kind,
                ));
            }
            let line_end = find_newline(bytes, idx).unwrap_or(bytes.len());
            spans.push(HighlightSpan::new(idx, line_end, HighlightKind::Comment));
            idx = line_end;
            last_code_start = idx;
            continue;
        }

        idx += 1;
    }

    if last_code_start < bytes.len() {
        spans.extend(highlight_code_segment(
            input,
            last_code_start,
            bytes.len(),
            state,
            config,
            &mut prev_kind,
        ));
    }

    spans
}

fn highlight_code_segment(
    input: &str,
    start: usize,
    end: usize,
    state: &AppState,
    config: &Config,
    prev_kind: &mut PrevKind,
) -> Vec<HighlightSpan> {
    let segment = &input[start..end];
    let tokens = tokenize_segment(segment, start);
    if tokens.is_empty() {
        return Vec::new();
    }

    let line_infos = compute_line_infos(segment, start);
    let token_line_indices = assign_line_indices(&tokens, input);
    let non_ws_indices: Vec<usize> = tokens
        .iter()
        .enumerate()
        .filter_map(|(idx, token)| {
            if token.kind == TokenKind::Whitespace {
                None
            } else {
                Some(idx)
            }
        })
        .collect();

    let mut spans = Vec::with_capacity(tokens.len());
    let mut line_idx = 0usize;

    for (idx, token) in tokens.iter().enumerate() {
        while line_idx + 1 < line_infos.len() && token.start >= line_infos[line_idx].end {
            line_idx += 1;
            *prev_kind = PrevKind::None;
        }

        let token_text = &input[token.start..token.end];

        if token.kind == TokenKind::Whitespace {
            spans.push(HighlightSpan::new(
                token.start,
                token.end,
                HighlightKind::Text,
            ));
            if token_text.contains('\n') {
                let newlines = token_text.chars().filter(|c| *c == '\n').count();
                for _ in 0..newlines {
                    if line_idx + 1 < line_infos.len() {
                        line_idx += 1;
                    }
                    *prev_kind = PrevKind::None;
                }
            }
            continue;
        }

        let assignment_pos = line_infos
            .get(line_idx)
            .and_then(|info| info.assignment_pos);
        let is_lhs = assignment_pos.map(|pos| token.start < pos).unwrap_or(false);

        if is_lhs && token.kind == TokenKind::Word && is_variable_like(token_text) {
            spans.push(HighlightSpan::new(
                token.start,
                token.end,
                HighlightKind::Variable,
            ));
            continue;
        }

        match token.kind {
            TokenKind::Operator => {
                let kind = if token_text == "="
                    && assignment_pos
                        .map(|pos| pos == token.start)
                        .unwrap_or(false)
                {
                    HighlightKind::Assignment
                } else {
                    HighlightKind::Operator
                };
                spans.push(HighlightSpan::new(token.start, token.end, kind));
                *prev_kind = PrevKind::Operator;
            }
            TokenKind::Word => {
                let cleaned =
                    token_text.trim_matches(|c: char| !c.is_alphanumeric() && c != '/' && c != '_');
                if cleaned.is_empty() {
                    spans.push(HighlightSpan::new(
                        token.start,
                        token.end,
                        HighlightKind::Text,
                    ));
                    *prev_kind = PrevKind::Operator;
                    continue;
                }

                let lower = cleaned.to_lowercase();
                let upper = cleaned.to_uppercase();
                let next_is_conversion = next_is_conversion(
                    idx,
                    &non_ws_indices,
                    &tokens,
                    &token_line_indices,
                    line_idx,
                    input,
                );

                let has_digits = cleaned.chars().any(|c| c.is_ascii_digit());
                let is_known_operator = is_operator_word(cleaned, config);
                let is_known_function = config.functions.contains_key(cleaned);
                let is_known_scale = config.scales.contains_key(cleaned);
                let is_known_unit = state.length_units.contains_key(&lower)
                    || state.time_units.contains_key(&lower)
                    || state.temperature_units.contains_key(&lower)
                    || state.area_units.contains_key(&lower)
                    || state.volume_units.contains_key(&lower)
                    || state.weight_units.contains_key(&lower)
                    || state.angular_units.contains_key(&lower)
                    || state.data_units.contains_key(&lower)
                    || state.speed_units.contains_key(&lower);
                let is_known_currency =
                    state.rates.contains_key(&upper) || is_currency_word(&lower);
                let is_known_keyword = is_history_keyword(&lower)
                    || is_inline_operator_keyword(&lower)
                    || is_general_keyword(&lower);
                let is_datetime =
                    is_datetime_keyword(&lower) || is_timezone_keyword(&lower, config);
                let is_constant = is_constant_keyword(&lower);
                let is_known_variable = state
                    .variables
                    .read()
                    .ok()
                    .map(|vars| vars.contains_key(cleaned))
                    .unwrap_or(false);

                let looks_like_code =
                    cleaned.len() >= 2 && cleaned.chars().all(|c| c.is_uppercase());

                if has_digits {
                    spans.push(HighlightSpan::new(
                        token.start,
                        token.end,
                        HighlightKind::Number,
                    ));
                    *prev_kind = PrevKind::Value;
                    continue;
                }

                if is_known_operator {
                    spans.push(HighlightSpan::new(
                        token.start,
                        token.end,
                        HighlightKind::Operator,
                    ));
                    *prev_kind = PrevKind::Operator;
                    continue;
                }

                if is_known_function {
                    spans.push(HighlightSpan::new(
                        token.start,
                        token.end,
                        HighlightKind::Function,
                    ));
                    *prev_kind = PrevKind::Operator;
                    continue;
                }

                if is_known_scale {
                    spans.push(HighlightSpan::new(
                        token.start,
                        token.end,
                        HighlightKind::Scale,
                    ));
                    *prev_kind = PrevKind::Value;
                    continue;
                }

                if is_known_unit {
                    spans.push(HighlightSpan::new(
                        token.start,
                        token.end,
                        HighlightKind::Unit,
                    ));
                    *prev_kind = PrevKind::Value;
                    continue;
                }

                if is_known_currency {
                    spans.push(HighlightSpan::new(
                        token.start,
                        token.end,
                        HighlightKind::Currency,
                    ));
                    *prev_kind = PrevKind::Value;
                    continue;
                }

                if is_datetime {
                    spans.push(HighlightSpan::new(
                        token.start,
                        token.end,
                        HighlightKind::Datetime,
                    ));
                    *prev_kind = PrevKind::Value;
                    continue;
                }

                if is_known_keyword {
                    spans.push(HighlightSpan::new(
                        token.start,
                        token.end,
                        HighlightKind::Keyword,
                    ));
                    if is_inline_operator_keyword(&lower) {
                        *prev_kind = PrevKind::Operator;
                    } else {
                        *prev_kind = PrevKind::Value;
                    }
                    continue;
                }

                if is_constant {
                    spans.push(HighlightSpan::new(
                        token.start,
                        token.end,
                        HighlightKind::Constant,
                    ));
                    *prev_kind = PrevKind::Value;
                    continue;
                }

                if is_known_variable {
                    spans.push(HighlightSpan::new(
                        token.start,
                        token.end,
                        HighlightKind::VariableUsage,
                    ));
                    *prev_kind = PrevKind::Value;
                    continue;
                }

                if looks_like_code {
                    spans.push(HighlightSpan::new(
                        token.start,
                        token.end,
                        HighlightKind::Text,
                    ));
                    *prev_kind = PrevKind::Value;
                    continue;
                }

                if *prev_kind == PrevKind::Value && !next_is_conversion {
                    spans.push(HighlightSpan::new(
                        token.start,
                        token.end,
                        HighlightKind::Comment,
                    ));
                    continue;
                }

                spans.push(HighlightSpan::new(
                    token.start,
                    token.end,
                    HighlightKind::Text,
                ));
                *prev_kind = PrevKind::Value;
            }
            TokenKind::Whitespace => {}
        }
    }

    spans
}

fn tokenize_segment(segment: &str, offset: usize) -> Vec<Token> {
    let mut tokens = Vec::new();
    let mut idx = 0;
    let bytes = segment.as_bytes();
    while idx < bytes.len() {
        let ch = segment[idx..].chars().next().unwrap();
        if ch.is_whitespace() {
            let start = idx;
            idx += ch.len_utf8();
            while idx < bytes.len() {
                let next = segment[idx..].chars().next().unwrap();
                if next.is_whitespace() {
                    idx += next.len_utf8();
                } else {
                    break;
                }
            }
            tokens.push(Token {
                start: offset + start,
                end: offset + idx,
                kind: TokenKind::Whitespace,
            });
        } else {
            let start = idx;
            idx += ch.len_utf8();
            while idx < bytes.len() {
                let next = segment[idx..].chars().next().unwrap();
                if next.is_whitespace() {
                    break;
                }
                idx += next.len_utf8();
            }
            tokens.extend(split_non_whitespace(&segment[start..idx], offset + start));
        }
    }
    tokens
}

fn split_non_whitespace(token: &str, offset: usize) -> Vec<Token> {
    let mut tokens = Vec::new();
    let mut idx = 0;
    while idx < token.len() {
        let ch = token[idx..].chars().next().unwrap();
        let is_op = is_operator_char(ch);
        let start = idx;
        idx += ch.len_utf8();
        while idx < token.len() {
            let next = token[idx..].chars().next().unwrap();
            if is_operator_char(next) == is_op {
                idx += next.len_utf8();
            } else {
                break;
            }
        }

        let part = &token[start..idx];
        if is_op {
            tokens.push(Token {
                start: offset + start,
                end: offset + idx,
                kind: TokenKind::Operator,
            });
        } else {
            tokens.extend(split_alpha_numeric(part, offset + start));
        }
    }
    tokens
}

fn split_alpha_numeric(segment: &str, offset: usize) -> Vec<Token> {
    let mut tokens = Vec::new();
    let mut idx = 0;
    while idx < segment.len() {
        let ch = segment[idx..].chars().next().unwrap();
        let start = idx;
        let mut kind = CharClass::Other;
        if ch.is_ascii_digit() || ch == '.' {
            kind = CharClass::Digit;
        } else if ch.is_alphabetic() || ch == '_' {
            kind = CharClass::Alpha;
        }
        idx += ch.len_utf8();

        while idx < segment.len() {
            let next = segment[idx..].chars().next().unwrap();
            let next_class = if next.is_ascii_digit() || next == '.' || next == '_' {
                CharClass::Digit
            } else if next.is_alphabetic() || next == '_' {
                CharClass::Alpha
            } else {
                CharClass::Other
            };

            if kind == CharClass::Digit {
                if next_class == CharClass::Digit {
                    idx += next.len_utf8();
                } else {
                    break;
                }
            } else if kind == CharClass::Alpha {
                if next_class == CharClass::Alpha || next_class == CharClass::Digit {
                    idx += next.len_utf8();
                } else {
                    break;
                }
            } else {
                break;
            }
        }

        tokens.push(Token {
            start: offset + start,
            end: offset + idx,
            kind: TokenKind::Word,
        });
    }
    tokens
}

#[derive(Copy, Clone, Eq, PartialEq)]
enum CharClass {
    Digit,
    Alpha,
    Other,
}

fn compute_line_infos(segment: &str, offset: usize) -> Vec<LineInfo> {
    let mut infos = Vec::new();
    let mut line_start = 0usize;
    for (idx, ch) in segment.char_indices() {
        if ch == '\n' {
            let line = &segment[line_start..idx];
            infos.push(LineInfo {
                end: offset + idx,
                assignment_pos: find_assignment_pos(line).map(|pos| offset + line_start + pos),
            });
            line_start = idx + ch.len_utf8();
        }
    }

    let line = &segment[line_start..];
    infos.push(LineInfo {
        end: offset + segment.len(),
        assignment_pos: find_assignment_pos(line).map(|pos| offset + line_start + pos),
    });

    infos
}

fn assign_line_indices(tokens: &[Token], input: &str) -> Vec<usize> {
    let mut indices = Vec::with_capacity(tokens.len());
    let mut line_idx = 0usize;
    for token in tokens {
        indices.push(line_idx);
        if token.kind == TokenKind::Whitespace {
            let text = &input[token.start..token.end];
            let count = text.chars().filter(|c| *c == '\n').count();
            line_idx += count;
        }
    }
    indices
}

fn next_is_conversion(
    token_index: usize,
    non_ws_indices: &[usize],
    tokens: &[Token],
    token_line_indices: &[usize],
    current_line_idx: usize,
    input: &str,
) -> bool {
    let pos_in_non_ws = non_ws_indices.iter().position(|idx| *idx == token_index);
    let pos_in_non_ws = match pos_in_non_ws {
        Some(pos) => pos,
        None => return false,
    };

    let next_index = match non_ws_indices.get(pos_in_non_ws + 1) {
        Some(idx) => *idx,
        None => return false,
    };

    if token_line_indices
        .get(next_index)
        .copied()
        .unwrap_or(current_line_idx + 1)
        != current_line_idx
    {
        return false;
    }

    let next_text = &input[tokens[next_index].start..tokens[next_index].end];
    let cleaned = next_text
        .trim_matches(|c: char| !c.is_alphanumeric() && c != '/' && c != '_')
        .to_lowercase();
    cleaned == "in" || cleaned == "to"
}

fn find_assignment_pos(line: &str) -> Option<usize> {
    let bytes = line.as_bytes();
    for i in 0..bytes.len() {
        if bytes[i] == b'=' {
            let has_op_before = i > 0 && matches!(bytes[i - 1], b'!' | b'<' | b'>' | b'=');
            let has_eq_after = i + 1 < bytes.len() && bytes[i + 1] == b'=';
            if !has_op_before && !has_eq_after {
                return Some(i);
            }
        }
    }
    None
}

fn is_variable_like(word: &str) -> bool {
    let mut chars = word.chars();
    let first = match chars.next() {
        Some(c) => c,
        None => return false,
    };
    if !(first.is_alphabetic() || first == '_') {
        return false;
    }
    chars.all(|c| c.is_alphanumeric() || c == '_')
}

fn is_operator_char(ch: char) -> bool {
    matches!(ch, '+' | '-' | '*' | '/' | '(' | ')' | '^' | '%' | '=')
}

fn find_subslice(haystack: &[u8], needle: &[u8], start: usize) -> Option<usize> {
    haystack[start..]
        .windows(needle.len())
        .position(|w| w == needle)
        .map(|pos| pos + start)
}

fn find_newline(haystack: &[u8], start: usize) -> Option<usize> {
    haystack[start..]
        .iter()
        .position(|b| *b == b'\n')
        .map(|pos| pos + start)
}

fn is_operator_word(word: &str, config: &Config) -> bool {
    config.operators.keys().any(|op| {
        op.eq_ignore_ascii_case(word)
            || op
                .split_whitespace()
                .any(|part| part.eq_ignore_ascii_case(word))
    })
}

fn is_history_keyword(word: &str) -> bool {
    matches!(word, "sum" | "total" | "average" | "avg" | "prev")
}

fn is_inline_operator_keyword(word: &str) -> bool {
    matches!(word, "in" | "to" | "of" | "from" | "per")
}

fn is_general_keyword(word: &str) -> bool {
    matches!(word, "in" | "to" | "as" | "of" | "per" | "from")
}

fn is_constant_keyword(word: &str) -> bool {
    matches!(word, "pi" | "e" | "phi" | "tau" | "true" | "false")
}

fn is_currency_word(word: &str) -> bool {
    matches!(
        word,
        "dollar"
            | "dollars"
            | "euro"
            | "euros"
            | "pound"
            | "pounds"
            | "yen"
            | "yuan"
            | "rmb"
            | "rupee"
            | "rupees"
            | "ruble"
            | "rubles"
            | "won"
            | "franc"
            | "francs"
            | "peso"
            | "pesos"
            | "krona"
            | "krone"
            | "lira"
            | "bitcoin"
            | "btc"
            | "ethereum"
            | "eth"
    )
}

fn is_datetime_keyword(word: &str) -> bool {
    matches!(
        word,
        "time"
            | "now"
            | "today"
            | "tomorrow"
            | "yesterday"
            | "ago"
            | "before"
            | "after"
            | "next"
            | "last"
            | "this"
            | "between"
            | "from"
            | "in"
            | "to"
    )
}

fn is_timezone_keyword(word: &str, config: &Config) -> bool {
    let abbrs = [
        "utc", "gmt", "est", "edt", "cst", "cdt", "mst", "mdt", "pst", "pdt", "bst", "cet", "cest",
        "eet", "eest", "ist", "jst", "kst", "aest", "aedt", "acst", "acdt", "awst",
    ];
    if abbrs.contains(&word) {
        return true;
    }
    if config.city_aliases.contains_key(word) {
        return true;
    }
    word.contains('/')
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::config::Config;
    use crate::models::AppState;

    #[test]
    fn highlights_inline_annotations() {
        let config = Config::default();
        let state = AppState::builder(&config).build();
        let input = "14.50 CAD internet + 16 USD spotify";
        let spans = highlight_spans(input, &state, &config);

        let mut internet_comment = false;
        let mut spotify_comment = false;
        for span in spans {
            let start = span.start as usize;
            let end = start + span.len as usize;
            let text = &input[start..end];
            if text == "internet" && span.kind == HighlightKind::Comment {
                internet_comment = true;
            }
            if text == "spotify" && span.kind == HighlightKind::Comment {
                spotify_comment = true;
            }
        }

        assert!(internet_comment);
        assert!(spotify_comment);
    }

    #[test]
    fn highlights_assignment_variable() {
        let config = Config::default();
        let state = AppState::builder(&config).build();
        let input = "foo = 10";
        let spans = highlight_spans(input, &state, &config);
        let mut found = false;
        for span in spans {
            let start = span.start as usize;
            let end = start + span.len as usize;
            let text = &input[start..end];
            if text == "foo" && span.kind == HighlightKind::Variable {
                found = true;
            }
        }
        assert!(found);
    }
}
