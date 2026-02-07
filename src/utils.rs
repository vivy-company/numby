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
