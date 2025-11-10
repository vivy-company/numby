use clipboard::{ClipboardContext, ClipboardProvider};
use ratatui::style::{Color, Style, Stylize};
use ratatui::text::Span;
use ropey::Rope;

#[allow(clippy::too_many_arguments)]
pub fn highlight_word_owned(
    word: &str,
    variables: &crate::models::VarMap,
    config: &crate::config::Config,
) -> Span<'static> {
    let clean_word = word.trim_matches(|c: char| !c.is_alphanumeric());
    let lower = clean_word.to_lowercase();
    if variables.read().unwrap().contains_key(clean_word) {
        Span::styled(word.to_string(), Style::default().fg(Color::Blue).bold())
    } else if config.operators.contains_key(clean_word) || config.functions.contains_key(clean_word) || config.scales.contains_key(clean_word) {
        Span::styled(word.to_string(), Style::default().fg(Color::Green).bold())
    } else if config.length_units.contains_key(&lower) || config.time_units.contains_key(&lower) || config.temperature_units.contains_key(&lower) ||
              config.area_units.contains_key(&lower) || config.volume_units.contains_key(&lower) || config.weight_units.contains_key(&lower) ||
              config.angular_units.contains_key(&lower) || config.data_units.contains_key(&lower) || config.speed_units.contains_key(&lower) {
        Span::styled(word.to_string(), Style::default().fg(Color::Yellow).bold())
    } else if config.currencies.contains_key(&clean_word.to_uppercase()) {
        Span::styled(word.to_string(), Style::default().fg(Color::Magenta).bold())
    } else {
        Span::raw(word.to_string())
    }
}

pub fn copy_to_clipboard(text: &str) {
    match ClipboardContext::new() {
        Ok(mut ctx) => {
            if let Err(e) = ctx.set_contents(text.to_string()) {
                eprintln!("Failed to copy to clipboard: {}", e);
            }
        }
        Err(e) => {
            eprintln!("Clipboard not available: {}", e);
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
