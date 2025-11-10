use crossterm::event::{KeyCode, KeyEvent, KeyModifiers};
use ropey::Rope;
use std::fs;

use crate::models::{AppState, Mode};
use crate::utils;

/// Finds the current line index and column from cursor position
fn find_cursor_line_col(input: &Rope, cursor_pos: usize) -> (usize, usize) {
    let lines: Vec<ropey::RopeSlice> = input.lines().collect();
    let mut pos = 0;

    for (i, line) in lines.iter().enumerate() {
        let line_len = line.len_chars();
        if pos <= cursor_pos && cursor_pos < pos + line_len {
            return (i, cursor_pos - pos);
        }
        pos += line_len + 1; // +1 for newline
    }

    // Cursor at end of document
    if cursor_pos == input.len_chars() {
        if let Some(last_line) = lines.last() {
            return (lines.len() - 1, last_line.len_chars());
        }
    }

    (0, 0)
}

/// Calculates cursor position from line index and column
fn cursor_pos_from_line_col(input: &Rope, line_idx: usize, col: usize) -> usize {
    let lines: Vec<ropey::RopeSlice> = input.lines().collect();
    let mut pos = 0;

    for (i, line) in lines.iter().enumerate() {
        if i == line_idx {
            return pos + col.min(line.len_chars());
        }
        pos += line.len_chars() + 1;
    }

    pos
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
pub fn handle_normal_mode(
    key: KeyEvent,
    input: &mut Rope,
    cursor_pos: &mut usize,
    mode: &mut Mode,
    state: &mut AppState,
    registry: &crate::evaluator::AgentRegistry,
) {
    if key.modifiers.contains(KeyModifiers::CONTROL) {
        match key.code {
            KeyCode::Char(':') => {
                *mode = Mode::Command(String::new());
                *state.status.write().unwrap() =
                    "Commands: :q quit, :w save current, :w filename save as".to_string();
            }
            KeyCode::Char('y') => {
                let current_line = utils::get_current_line(input, *cursor_pos);
                if let Some((result, _)) = registry.evaluate(current_line.trim(), state) {
                    utils::copy_to_clipboard(&result);
                }
            }
            KeyCode::Char('i') | KeyCode::Char('a') => {
                utils::copy_to_clipboard(&input.to_string());
            }
            _ => {}
        }
    } else {
        match key.code {
            KeyCode::Char(':') => {
                *mode = Mode::Command(String::new());
            }
            KeyCode::Char(c) => {
                input.insert(*cursor_pos, &c.to_string());
                *cursor_pos += 1;
            }
            KeyCode::Backspace => {
                if *cursor_pos > 0 {
                    input.remove(*cursor_pos - 1..*cursor_pos);
                    *cursor_pos = cursor_pos.saturating_sub(1);
                }
            }
            KeyCode::Delete => {
                if *cursor_pos < input.len_chars() {
                    input.remove(*cursor_pos..*cursor_pos + 1);
                }
            }
            KeyCode::Left => {
                *cursor_pos = cursor_pos.saturating_sub(1);
            }
            KeyCode::Right => {
                if *cursor_pos < input.len_chars() {
                    *cursor_pos += 1;
                }
            }
            KeyCode::Up => {
                *cursor_pos = move_cursor_up(input, *cursor_pos);
            }
            KeyCode::Down => {
                *cursor_pos = move_cursor_down(input, *cursor_pos);
            }
            KeyCode::Home => {
                *cursor_pos = utils::find_line_start(input, *cursor_pos);
            }
            KeyCode::End => {
                *cursor_pos = utils::find_line_end(input, *cursor_pos);
            }
            KeyCode::Enter => {
                let current_line = utils::get_current_line(input, *cursor_pos);
                let trimmed = current_line.trim();
                if !trimmed.is_empty() {
                    registry.evaluate(trimmed, state);
                }
                input.insert(*cursor_pos, "\n");
                *cursor_pos += 1;
            }
            _ => {}
        }
    }
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
                    save_file(state, input, Some(filename.trim()));
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

/// Saves the current file
fn save_file(state: &mut AppState, input: &Rope, new_filename: Option<&str>) {
    let filename = if let Some(new_name) = new_filename {
        state.current_filename = Some(new_name.to_string());
        // Update terminal title
        use crossterm::execute;
        use crossterm::terminal::SetTitle;
        let _ = execute!(std::io::stdout(), SetTitle(new_name));
        new_name
    } else if let Some(ref current) = state.current_filename {
        current.as_str()
    } else {
        *state.status.write().unwrap() = "No file to save to. Use :w filename".to_string();
        return;
    };

    match fs::write(filename, input.to_string().as_bytes()) {
        Ok(_) => {
            *state.status.write().unwrap() = format!("File saved: {}", filename);
        }
        Err(e) => {
            *state.status.write().unwrap() = format!("Error saving file: {}", e);
        }
    }
}
