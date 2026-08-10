use crate::evaluator::contains_word_numbers;

#[derive(Clone, Debug)]
pub struct LineGroup {
    pub start: usize,
    pub end: usize,
    pub expr: String,
}

fn strip_inline_block_comments(line: &str) -> String {
    let mut out = String::with_capacity(line.len());
    let mut rest = line;

    loop {
        if let Some(start) = rest.find("/*") {
            out.push_str(&rest[..start]);
            let after_start = &rest[start + 2..];
            if let Some(end) = after_start.find("*/") {
                rest = &after_start[end + 2..];
                continue;
            }
            return out;
        }

        out.push_str(rest);
        break;
    }

    out
}

fn strip_line_comments_for_continuation(line: &str) -> String {
    let without_block = strip_inline_block_comments(line);
    let mut end = without_block.len();
    if let Some(pos) = without_block.find("//") {
        end = end.min(pos);
    }
    if let Some(pos) = without_block.find('#') {
        end = end.min(pos);
    }
    without_block[..end].to_string()
}

fn line_starts_with_operator(line: &str) -> bool {
    let trimmed = strip_line_comments_for_continuation(line);
    let trimmed = trimmed.trim_start();
    trimmed
        .chars()
        .next()
        .map(|c| "+-*/%^".contains(c))
        .unwrap_or(false)
}

fn line_ends_with_operator(line: &str) -> bool {
    let trimmed = strip_line_comments_for_continuation(line);
    let trimmed = trimmed.trim_end();
    trimmed
        .chars()
        .last()
        .map(|c| "+-*/%^(".contains(c))
        .unwrap_or(false)
}

fn is_comment_line(line: &str) -> bool {
    let trimmed = line.trim();
    trimmed.starts_with("//") || trimmed.starts_with('#') || trimmed.starts_with("/*")
}

fn is_annotation_only_line(line: &str) -> bool {
    let stripped = strip_line_comments_for_continuation(line);
    let trimmed = stripped.trim();
    if trimmed.is_empty() {
        return false;
    }

    if trimmed.chars().any(|c| c.is_ascii_digit()) {
        return false;
    }

    if contains_word_numbers(trimmed) {
        return false;
    }

    if trimmed
        .chars()
        .any(|c| "+-*/%^=()[]{}<>".contains(c) || c == '.' || c == ',' || c == ':')
    {
        return false;
    }

    if trimmed
        .chars()
        .any(|c| !(c.is_ascii_alphabetic() || c.is_whitespace() || c == '_' || c == '-'))
    {
        return false;
    }

    let lower = trimmed.to_lowercase();
    !matches!(
        lower.as_str(),
        "sum"
            | "total"
            | "avg"
            | "average"
            | "prev"
            | "now"
            | "today"
            | "tomorrow"
            | "yesterday"
            | "time"
            | "date"
            | "next"
            | "last"
            | "this"
            | "monday"
            | "tuesday"
            | "wednesday"
            | "thursday"
            | "friday"
            | "saturday"
            | "sunday"
            | "utc"
            | "gmt"
            | "pi"
            | "e"
    )
}

pub fn group_multiline_expressions(lines: &[String]) -> Vec<LineGroup> {
    let mut groups = Vec::new();
    let mut current_start: Option<usize> = None;
    let mut current_parts: Vec<String> = Vec::new();
    let mut last_content_idx: Option<usize> = None;
    let mut prev_line: Option<String> = None;

    for (idx, line) in lines.iter().enumerate() {
        let trimmed = line.trim();
        if trimmed.is_empty() {
            continue;
        }
        if is_comment_line(line) {
            if let (Some(start), Some(end)) = (current_start, last_content_idx) {
                let expr = current_parts.join("\n");
                groups.push(LineGroup { start, end, expr });
                current_parts.clear();
            }
            current_start = None;
            last_content_idx = None;
            prev_line = None;
            continue;
        }
        if is_annotation_only_line(line) {
            continue;
        }

        let starts_with_op = line_starts_with_operator(line);
        let prev_ends_with_op = prev_line
            .as_ref()
            .map(|p| line_ends_with_operator(p))
            .unwrap_or(false);

        let is_continuation = starts_with_op || prev_ends_with_op;

        if current_start.is_none() || !is_continuation {
            if let (Some(start), Some(end)) = (current_start, last_content_idx) {
                let expr = current_parts.join("\n");
                groups.push(LineGroup { start, end, expr });
                current_parts.clear();
            }
            current_start = Some(idx);
        }

        current_parts.push(line.trim().to_string());
        last_content_idx = Some(idx);
        prev_line = Some(line.to_string());
    }

    if let (Some(start), Some(end)) = (current_start, last_content_idx) {
        let expr = current_parts.join("\n");
        groups.push(LineGroup { start, end, expr });
    }

    groups
}

#[allow(dead_code)]
pub fn group_bounds_for_line(lines: &[String], line_index: usize) -> (usize, usize) {
    let groups = group_multiline_expressions(lines);
    for group in groups {
        if line_index >= group.start && line_index <= group.end {
            return (group.start, group.end);
        }
    }
    (line_index, line_index)
}
