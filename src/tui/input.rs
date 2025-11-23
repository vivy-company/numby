use crossterm::event::{KeyCode, KeyEvent, KeyModifiers};
use ropey::Rope;
use std::fs;

use crate::models::{AppState, Mode};
use crate::security::{
    sanitize_terminal_string, validate_file_path, validate_input_size, MAX_EXPR_LENGTH,
};
use crate::utils;

/// Helper function to delete a text selection
fn delete_selection(
    input: &mut Rope,
    cursor_pos: &mut usize,
    selection_start: Option<usize>,
) -> bool {
    if let Some(start) = selection_start {
        let (from, to) = if start < *cursor_pos {
            (start, *cursor_pos)
        } else {
            (*cursor_pos, start)
        };
        input.remove(from..to);
        *cursor_pos = from;
        true
    } else {
        false
    }
}

/// Helper function to clear selection
fn clear_selection(selection_start: &mut Option<usize>) {
    *selection_start = None;
}

/// Check if string contains an assignment operator (not comparison)
pub fn contains_assignment_check(s: &str) -> bool {
    // Look for '=' that is not part of ==, !=, <=, >=
    let bytes = s.as_bytes();
    for i in 0..bytes.len() {
        if bytes[i] == b'=' {
            // Check character before
            let has_op_before = i > 0 && matches!(bytes[i - 1], b'!' | b'<' | b'>' | b'=');
            // Check character after
            let has_eq_after = i + 1 < bytes.len() && bytes[i + 1] == b'=';

            if !has_op_before && !has_eq_after {
                return true;
            }
        }
    }
    false
}

/// Re-evaluate current line if it has been edited and contains an assignment
fn reevaluate_if_changed(
    input: &ropey::Rope,
    cursor_pos: usize,
    state: &mut AppState,
    registry: &crate::evaluator::AgentRegistry,
) {
    let line_idx = input.char_to_line(cursor_pos);
    let current_line = utils::get_current_line(input, cursor_pos);
    let trimmed = current_line.trim();

    // Only re-evaluate if line contains an assignment (not comparison)
    if trimmed.is_empty() || !contains_assignment_check(trimmed) {
        return;
    }

    // Check if this line's content has changed from last evaluation
    if let Ok(line_content) = state.line_content.read() {
        if let Some(last_content) = line_content.get(&line_idx) {
            // If content hasn't changed, no need to re-evaluate
            if last_content == trimmed {
                return;
            }
        }
    }

    // Line was edited and contains assignment - re-evaluate
    if validate_input_size(trimmed).is_ok() {
        if let Ok(mut current_line) = state.current_line.write() {
            *current_line = Some(line_idx);
        }
        // Re-evaluate without touching history to avoid double-counting
        registry.evaluate_without_history(trimmed, state);
        if let Ok(mut current_line) = state.current_line.write() {
            *current_line = None;
        }
    }
}

/// Finds the current line index and column from cursor position
fn find_cursor_line_col(input: &Rope, cursor_pos: usize) -> (usize, usize) {
    let line_idx = input.char_to_line(cursor_pos);
    let line_start = input.line_to_char(line_idx);
    let col = cursor_pos - line_start;
    (line_idx, col)
}

/// Calculates cursor position from line index and column
fn cursor_pos_from_line_col(input: &Rope, line_idx: usize, col: usize) -> usize {
    let line_start = input.line_to_char(line_idx);
    let line_len = input.line(line_idx).len_chars();
    line_start + col.min(line_len)
}

/// Moves cursor up one line
pub fn move_cursor_up(input: &Rope, cursor_pos: usize) -> usize {
    let (line_idx, col) = find_cursor_line_col(input, cursor_pos);

    if line_idx > 0 {
        cursor_pos_from_line_col(input, line_idx - 1, col)
    } else {
        cursor_pos
    }
}

/// Moves cursor down one line
pub fn move_cursor_down(input: &Rope, cursor_pos: usize) -> usize {
    let lines: Vec<ropey::RopeSlice> = input.lines().collect();
    let (line_idx, col) = find_cursor_line_col(input, cursor_pos);

    if line_idx < lines.len() - 1 {
        cursor_pos_from_line_col(input, line_idx + 1, col)
    } else {
        cursor_pos
    }
}

/// Handles keyboard input in Normal mode
/// Returns true if the text was modified
pub fn handle_normal_mode(
    key: KeyEvent,
    input: &mut Rope,
    cursor_pos: &mut usize,
    mode: &mut Mode,
    state: &mut AppState,
    registry: &crate::evaluator::AgentRegistry,
    selection_start: &mut Option<usize>,
) -> bool {
    let mut text_changed = false;
    if key.modifiers.contains(KeyModifiers::CONTROL) {
        match key.code {
            KeyCode::Char(':') => {
                *mode = Mode::Command(String::new());
                let _ = state.set_status(crate::fl!("commands-help"));
                clear_selection(selection_start);
            }
            KeyCode::Char('a') => {
                // Select all
                *selection_start = Some(0);
                *cursor_pos = input.len_chars();
            }
            KeyCode::Char('y') => {
                let current_line = utils::get_current_line(input, *cursor_pos);
                let trimmed = current_line.trim();
                // Validate before evaluation
                if validate_input_size(trimmed).is_ok() {
                    if let Some((result, _)) = registry.evaluate(trimmed, state) {
                        utils::copy_to_clipboard(&result);
                    }
                }
                clear_selection(selection_start);
            }
            KeyCode::Char('i') => {
                // If a selection exists, copy it raw. Otherwise, copy a formatted
                // expression/result table for sharing.
                let buf_len = input.len_chars();
                if let Some(start) = selection_start {
                    let start_idx = *start;
                    let end_idx = *cursor_pos;
                    let (from, to) = if start_idx < end_idx {
                        (start_idx, end_idx)
                    } else {
                        (end_idx, start_idx)
                    };

                    // If user selected the whole buffer, share a formatted table instead of raw text
                    if from == 0 && to == buf_len {
                        let formatted = format_buffer_as_markdown_list(input, state, registry);
                        utils::copy_to_clipboard(&formatted);
                    } else {
                        let snippet = input.slice(from..to).to_string();
                        utils::copy_to_clipboard(&snippet);
                    }
                } else {
                    let formatted = format_buffer_as_markdown_list(input, state, registry);
                    utils::copy_to_clipboard(&formatted);
                }
                clear_selection(selection_start);
            }
            _ => {}
        }
    } else {
        match key.code {
            KeyCode::Char(':') => {
                *mode = Mode::Command(String::new());
                clear_selection(selection_start);
            }
            KeyCode::Char(c) => {
                // Delete selection if exists
                if delete_selection(input, cursor_pos, *selection_start) {
                    clear_selection(selection_start);
                    text_changed = true;
                }

                // Prevent input from exceeding maximum size
                if input.len_chars() < MAX_EXPR_LENGTH {
                    input.insert(*cursor_pos, &c.to_string());
                    *cursor_pos += 1;
                    text_changed = true;
                } else {
                    let _ = state.set_status(
                        crate::fl!("input-size-limit", "max" => &MAX_EXPR_LENGTH.to_string()),
                    );
                }
            }
            KeyCode::Backspace => {
                if !delete_selection(input, cursor_pos, *selection_start) {
                    if *cursor_pos > 0 {
                        // Check if we're deleting a newline
                        let char_before = input.char(*cursor_pos - 1);
                        let deleting_newline = char_before == '\n';
                        let line_idx = if deleting_newline {
                            input.char_to_line(*cursor_pos)
                        } else {
                            0
                        };

                        input.remove(*cursor_pos - 1..*cursor_pos);
                        *cursor_pos = cursor_pos.saturating_sub(1);
                        text_changed = true;

                        // If we deleted a newline, shift line tracking
                        if deleting_newline {
                            let _ = state.shift_lines_on_delete(line_idx);
                        }
                    }
                } else {
                    clear_selection(selection_start);
                    text_changed = true;
                }
            }
            KeyCode::Delete => {
                if !delete_selection(input, cursor_pos, *selection_start) {
                    if *cursor_pos < input.len_chars() {
                        // Check if we're deleting a newline
                        let char_at_cursor = input.char(*cursor_pos);
                        let deleting_newline = char_at_cursor == '\n';
                        let line_idx = if deleting_newline {
                            input.char_to_line(*cursor_pos) + 1
                        } else {
                            0
                        };

                        input.remove(*cursor_pos..*cursor_pos + 1);
                        text_changed = true;

                        // If we deleted a newline, shift line tracking
                        if deleting_newline {
                            let _ = state.shift_lines_on_delete(line_idx);
                        }
                    }
                } else {
                    clear_selection(selection_start);
                    text_changed = true;
                }
            }
            KeyCode::Left => {
                // Re-evaluate if moving to a different line
                let old_line = input.char_to_line(*cursor_pos);
                let old_cursor = *cursor_pos;
                *cursor_pos = cursor_pos.saturating_sub(1);
                let new_line = input.char_to_line(*cursor_pos);
                if old_line != new_line {
                    reevaluate_if_changed(input, old_cursor, state, registry);
                }
                clear_selection(selection_start);
            }
            KeyCode::Right => {
                if *cursor_pos < input.len_chars() {
                    let old_line = input.char_to_line(*cursor_pos);
                    let old_cursor = *cursor_pos;
                    *cursor_pos += 1;
                    let new_line = input.char_to_line(*cursor_pos);
                    if old_line != new_line {
                        reevaluate_if_changed(input, old_cursor, state, registry);
                    }
                }
                clear_selection(selection_start);
            }
            KeyCode::Up => {
                // Re-evaluate current line if it was edited
                reevaluate_if_changed(input, *cursor_pos, state, registry);
                *cursor_pos = move_cursor_up(input, *cursor_pos);
                clear_selection(selection_start);
            }
            KeyCode::Down => {
                // Re-evaluate current line if it was edited
                reevaluate_if_changed(input, *cursor_pos, state, registry);
                *cursor_pos = move_cursor_down(input, *cursor_pos);
                clear_selection(selection_start);
            }
            KeyCode::Home => {
                *cursor_pos = utils::find_line_start(input, *cursor_pos);
                clear_selection(selection_start);
            }
            KeyCode::End => {
                *cursor_pos = utils::find_line_end(input, *cursor_pos);
                clear_selection(selection_start);
            }
            KeyCode::Enter => {
                clear_selection(selection_start);
                let current_line = utils::get_current_line(input, *cursor_pos);
                let trimmed = current_line.trim();
                if !trimmed.is_empty() {
                    // Validate current line before evaluation
                    if let Err(e) = validate_input_size(trimmed) {
                        let _ = state.set_status(
                            crate::fl!("line-validation-error", "error" => &e.to_string()),
                        );
                    } else {
                        // Set current line index for variable tracking
                        let line_idx = input.char_to_line(*cursor_pos);
                        if let Ok(mut current_line) = state.current_line.write() {
                            *current_line = Some(line_idx);
                        }
                        registry.evaluate(trimmed, state);
                        // Clear current line after evaluation
                        if let Ok(mut current_line) = state.current_line.write() {
                            *current_line = None;
                        }
                    }
                }
                // Insert newline - shift line tracking
                let line_idx = input.char_to_line(*cursor_pos);
                input.insert(*cursor_pos, "\n");
                *cursor_pos += 1;
                text_changed = true;
                // Shift all lines after the insertion point
                let _ = state.shift_lines_on_insert(line_idx + 1);
            }
            _ => {
                clear_selection(selection_start);
            }
        }
    }

    text_changed
}

/// Format the entire buffer as a Markdown bullet list with expression and result.
/// Uses evaluate_for_display to avoid mutating state.
fn format_buffer_as_markdown_list(
    input: &Rope,
    state: &AppState,
    registry: &crate::evaluator::AgentRegistry,
) -> String {
    let mut rows: Vec<(String, String)> = Vec::new();
    for line in input.lines() {
        let expr = line.to_string();
        let trimmed = expr.trim();
        if trimmed.is_empty() || trimmed.starts_with("//") || trimmed.starts_with('#') {
            continue;
        }
        let result = registry
            .evaluate_for_display(trimmed, state)
            .map(|(r, _)| r)
            .unwrap_or_else(|| crate::fl!("error-evaluating-expression"));
        rows.push((trimmed.to_string(), result));
    }

    if rows.is_empty() {
        return String::new();
    }

    let mut out = String::from("### Results\n\n");
    for (expr, res) in rows {
        out.push_str(&format!("- `{}` → `{}`\n", expr, res));
    }
    out
}

/// Handles keyboard input in Command mode
pub fn handle_command_mode(
    key: KeyEvent,
    mode: &mut Mode,
    state: &mut AppState,
    input: &Rope,
) -> bool {
    if let Mode::Command(ref mut cmd) = mode {
        match key.code {
            KeyCode::Char(c) => {
                cmd.push(c);
            }
            KeyCode::Backspace => {
                cmd.pop();
            }
            KeyCode::Enter => {
                let command = cmd.clone();
                *mode = Mode::Normal;

                if command == "q" || command == "q!" {
                    return true; // Signal to quit
                } else if command == "w" {
                    save_file(state, input, None);
                } else if let Some(filename) = command.strip_prefix("w ") {
                    let filename = filename.trim();
                    match validate_file_path(filename) {
                        Ok(validated_path) => {
                            save_file(state, input, Some(validated_path.to_str().unwrap()));
                        }
                        Err(e) => {
                            let _ = state.set_status(
                                crate::fl!("invalid-file-path", "error" => &e.to_string()),
                            );
                        }
                    }
                } else if command == "langs" {
                    list_languages(state);
                } else if let Some(locale) = command.strip_prefix("lang ") {
                    set_language(state, locale.trim());
                } else if command == "lang" {
                    show_current_language(state);
                }
            }
            KeyCode::Esc => {
                *mode = Mode::Normal;
            }
            _ => {}
        }
    }

    false // Don't quit
}

/// Shows the current language
fn show_current_language(state: &mut AppState) {
    let locale = crate::i18n::get_locale();
    let display_name = crate::i18n::get_locale_display_name(&locale.to_string());
    let _ = state.set_status(crate::fl!("current-language", "name" => display_name));
}

/// Lists all available languages
fn list_languages(state: &mut AppState) {
    let locales = crate::i18n::get_available_locales();
    let langs: Vec<String> = locales
        .iter()
        .map(|locale| crate::i18n::get_locale_display_name(locale).to_string())
        .collect();

    let _ = state.set_status(crate::fl!("available-languages", "list" => &langs.join(", ")));
}

/// Sets the current language
fn set_language(state: &mut AppState, locale: &str) {
    match crate::i18n::set_locale(locale) {
        Ok(_) => {
            let display_name = crate::i18n::get_locale_display_name(locale);
            let _ = state.set_status(crate::fl!("language-changed", "name" => display_name));

            // Try to update and save config
            let mut config = crate::config::load_config();
            config.locale = Some(locale.to_string());
            let _ = crate::config::save_config(&config);
        }
        Err(e) => {
            let _ = state.set_status(crate::fl!("failed-set-language", "error" => &e.to_string()));
        }
    }
}

/// Saves the current file
fn save_file(state: &mut AppState, input: &Rope, new_filename: Option<&str>) {
    let filename = if let Some(new_name) = new_filename {
        state.current_filename = Some(new_name.to_string());
        // Update terminal title with sanitized string
        use crossterm::execute;
        use crossterm::terminal::SetTitle;
        let sanitized_title = sanitize_terminal_string(new_name);
        let _ = execute!(std::io::stdout(), SetTitle(&sanitized_title));
        new_name
    } else if let Some(ref current) = state.current_filename {
        current.as_str()
    } else {
        let _ = state.set_status(crate::fl!("no-file-to-save"));
        return;
    };

    match fs::write(filename, input.to_string().as_bytes()) {
        Ok(_) => {
            let _ = state.set_status(crate::fl!("file-saved", "path" => filename));
        }
        Err(e) => {
            let _ = state.set_status(crate::fl!("error-saving-file", "error" => &e.to_string()));
        }
    }
}
