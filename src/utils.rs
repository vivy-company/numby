use arboard::Clipboard;
use ropey::Rope;

#[cfg(all(unix, not(target_os = "android"), not(target_os = "ios")))]
fn try_wayland_copy(text: &str) -> bool {
    if std::env::var_os("WAYLAND_DISPLAY").is_some() {
        if let Ok(mut child) = std::process::Command::new("wl-copy")
            .stdin(std::process::Stdio::piped())
            .spawn()
        {
            use std::io::Write;
            if let Some(mut stdin) = child.stdin.take() {
                let _ = stdin.write_all(text.as_bytes());
            }
            if let Ok(status) = child.wait() {
                return status.success();
            }
        }
    }
    false
}

#[cfg(not(all(unix, not(target_os = "android"), not(target_os = "ios"))))]
fn try_wayland_copy(_text: &str) -> bool {
    false
}

pub fn copy_to_clipboard(text: &str) {
    if try_wayland_copy(text) {
        return;
    }

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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_copy_to_clipboard() {
        copy_to_clipboard("test_wayland_clipboard");
        #[cfg(all(unix, not(target_os = "android"), not(target_os = "ios")))]
        if std::env::var_os("WAYLAND_DISPLAY").is_some() {
            if let Ok(output) = std::process::Command::new("wl-paste").output() {
                let text = String::from_utf8_lossy(&output.stdout);
                assert_eq!(text.trim(), "test_wayland_clipboard");
            }
        }
    }
}
