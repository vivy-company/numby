use arboard::Clipboard;
use ropey::Rope;

pub fn copy_to_clipboard(text: &str) {
    match Clipboard::new() {
        Ok(mut clipboard) => {
            if let Err(e) = clipboard.set_text(text) {
                eprintln!(
                    "{}",
                    crate::fl!("clipboard-copy-failed", "error" => &e.to_string())
                );
            }
        }
        Err(e) => {
            eprintln!(
                "{}",
                crate::fl!("clipboard-not-available", "error" => &e.to_string())
            );
        }
    }
}

pub fn find_line_start(rope: &Rope, pos: usize) -> usize {
    let line_idx = rope.char_to_line(pos);
    rope.line_to_char(line_idx)
}

pub fn find_line_end(rope: &Rope, pos: usize) -> usize {
    let line_idx = rope.char_to_line(pos);
    let line_len = rope.line(line_idx).len_chars();
    rope.line_to_char(line_idx) + line_len
}

pub fn get_current_line(rope: &Rope, cursor_pos: usize) -> String {
    let line_idx = rope.char_to_line(cursor_pos);
    rope.line(line_idx).to_string()
}

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
    matches!(
        trimmed.chars().next(),
        Some('+') | Some('-') | Some('*') | Some('/') | Some('%') | Some('^')
    )
}

fn line_ends_with_operator(line: &str) -> bool {
    let trimmed = strip_line_comments_for_continuation(line);
    let trimmed = trimmed.trim_end();
    if trimmed.is_empty() {
        return false;
    }
    matches!(
        trimmed.chars().last(),
        Some('+') | Some('-') | Some('*') | Some('/') | Some('%') | Some('^') | Some('(')
    )
}

fn is_comment_or_empty(line: &str) -> bool {
    let stripped = strip_line_comments_for_continuation(line);
    stripped.trim().is_empty()
}

pub fn group_multiline_expressions(lines: &[String]) -> Vec<LineGroup> {
    let mut groups = Vec::new();
    let mut current_start: Option<usize> = None;
    let mut current_parts: Vec<String> = Vec::new();
    let mut prev_line: Option<String> = None;

    for (idx, line) in lines.iter().enumerate() {
        if is_comment_or_empty(line) {
            if let Some(start) = current_start {
                let expr = current_parts.join("\n");
                groups.push(LineGroup {
                    start,
                    end: idx.saturating_sub(1),
                    expr,
                });
                current_start = None;
                current_parts.clear();
            }
            prev_line = None;
            continue;
        }

        let starts_with_op = line_starts_with_operator(line);
        let prev_ends_with_op = prev_line
            .as_ref()
            .map(|p| line_ends_with_operator(p))
            .unwrap_or(false);

        let is_continuation = starts_with_op || prev_ends_with_op;

        if current_start.is_none() || !is_continuation {
            if let Some(start) = current_start {
                let expr = current_parts.join("\n");
                groups.push(LineGroup {
                    start,
                    end: idx.saturating_sub(1),
                    expr,
                });
                current_parts.clear();
            }
            current_start = Some(idx);
        }

        current_parts.push(line.trim().to_string());
        prev_line = Some(line.to_string());
    }

    if let Some(start) = current_start {
        let expr = current_parts.join("\n");
        groups.push(LineGroup {
            start,
            end: lines.len().saturating_sub(1),
            expr,
        });
    }

    groups
}
