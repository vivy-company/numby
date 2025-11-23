use anyhow::Result;
use crossterm::{
    event::{self, Event, KeyCode, KeyModifiers},
    execute,
    terminal::{
        disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen, SetTitle,
    },
};
use ratatui::{backend::CrosstermBackend, Terminal};
use ropey::Rope;
use std::fs;
use std::io;

use crate::{i18n, models::AppState};

mod input;
mod render;
mod syntax;

use render::RenderContext;

const STATUS_TIMER_DURATION: u32 = 30; // 3 seconds at 100ms polling

pub fn run(
    state: &mut AppState,
    config: &crate::config::Config,
    registry: &crate::evaluator::AgentRegistry,
) -> Result<()> {
    // Setup terminal
    enable_raw_mode()?;
    let mut stdout = io::stdout();

    use crate::security::sanitize_terminal_string;
    let title = state.current_filename.as_deref().unwrap_or("numby");
    let sanitized_title = sanitize_terminal_string(title);

    execute!(stdout, SetTitle(&sanitized_title))?;
    execute!(stdout, EnterAlternateScreen)?;
    let backend = CrosstermBackend::new(stdout);
    let mut terminal = Terminal::new(backend)?;

    // Initialize state
    let mut input = if let Some(ref filename) = state.current_filename {
        Rope::from(fs::read_to_string(filename).unwrap_or_else(|_| String::new()))
    } else {
        Rope::new()
    };
    let mut cursor_pos = input.len_chars();
    // Command mode removed; keep cursor/input only
    let mut status_timer: u32 = 0;
    // If a status message is already set when the TUI starts (e.g., startup messages),
    // ensure the status bar is visible long enough for the user to read it.
    if state
        .get_status()
        .map(|s| !s.trim().is_empty())
        .unwrap_or(false)
    {
        status_timer = STATUS_TIMER_DURATION;
    }
    let mut scroll_offset = 0;
    let mut selection_start: Option<usize> = None;
    let mut last_edit_time: Option<std::time::Instant> = None;
    let mut pending_eval_line: Option<usize> = None;
    let mut help_visible = false;
    let mut locale_picker_visible = false;
    let mut format_picker_visible = false;
    let mut format_selection_time: usize = 0;
    let mut format_selection_date: usize = 0;
    let mut format_time_offset: usize = 0;
    let mut format_date_offset: usize = 0;
    let mut format_focus_time: bool = true;
    let mut locale_selection: usize = 0;
    let mut locale_scroll_offset: usize = 0;
    let mut save_prompt_active = false;
    let mut save_prompt = String::new();
    let mut last_esc_time: Option<std::time::Instant> = None;
    let mut last_ctrlc_time: Option<std::time::Instant> = None;

    // Main event loop
    loop {
        // Check if we should re-evaluate a pending line (after 150ms of no typing)
        if let (Some(edit_time), Some(line_idx)) = (last_edit_time, pending_eval_line) {
            if edit_time.elapsed() >= std::time::Duration::from_millis(150) {
                // Re-evaluate the pending line
                if line_idx < input.len_lines() {
                    let line_text = input.line(line_idx).to_string();
                    let trimmed = line_text.trim();
                    if !trimmed.is_empty() && input::contains_assignment_check(trimmed) {
                        if let Ok(mut current_line) = state.current_line.write() {
                            *current_line = Some(line_idx);
                        }
                        // Re-evaluate without mutating history
                        registry.evaluate_without_history(trimmed, state);
                        if let Ok(mut current_line) = state.current_line.write() {
                            *current_line = None;
                        }
                    }
                }
                // Clear pending evaluation
                last_edit_time = None;
                pending_eval_line = None;
            }
        }

        // Render UI
        let current_locale_string = i18n::get_locale().to_string();

        terminal.draw(|f| {
            render::render_ui(
                f,
                RenderContext {
                    input: &input,
                    cursor_pos,
                    state,
                    config,
                    registry,
                    show_status: status_timer > 0,
                    scroll_offset: &mut scroll_offset,
                    help_visible,
                    format_picker_visible,
                    format_selection_time,
                    format_selection_date,
                    format_time_offset,
                    format_date_offset,
                    format_focus_time,
                    locale_picker_visible,
                    locale_selection,
                    current_locale: &current_locale_string,
                    locale_scroll_offset,
                    locale_visible: 8,
                    save_prompt_active,
                    save_prompt: &save_prompt,
                    available_locales: i18n::AVAILABLE_LOCALES,
                },
            )
        })?;

        // Update status timer
        if status_timer > 0 {
            status_timer -= 1;
            if status_timer == 0 {
                let _ = state.set_status(String::new());
            }
        }

                // Handle input events (16ms = ~60fps for smooth updates)
                if event::poll(std::time::Duration::from_millis(16))? {
                    if let Event::Key(key) = event::read()? {
                        if format_picker_visible {
                            const TIME_OPTS: [&str; 5] = ["iso", "long", "short", "time", "12h"];
                            const DATE_OPTS: [&str; 3] = ["iso", "long", "short"];
                            const VISIBLE: usize = 6;
                            match key.code {
                                KeyCode::Up => {
                                    if format_focus_time {
                                        if format_selection_time > 0 {
                                            format_selection_time -= 1;
                                            if format_selection_time < format_time_offset {
                                                format_time_offset = format_selection_time;
                                            }
                                        }
                                    } else if format_selection_date > 0 {
                                        format_selection_date -= 1;
                                        if format_selection_date < format_date_offset {
                                            format_date_offset = format_selection_date;
                                        }
                                    }
                                }
                                KeyCode::Down => {
                                    if format_focus_time {
                                        let max = TIME_OPTS.len() - 1;
                                        if format_selection_time < max {
                                            format_selection_time += 1;
                                            if format_selection_time
                                                >= format_time_offset + VISIBLE
                                            {
                                                format_time_offset =
                                                    format_selection_time + 1 - VISIBLE;
                                            }
                                        }
                                    } else {
                                        let max = DATE_OPTS.len() - 1;
                                        if format_selection_date < max {
                                            format_selection_date += 1;
                                            if format_selection_date
                                                >= format_date_offset + VISIBLE
                                            {
                                                format_date_offset =
                                                    format_selection_date + 1 - VISIBLE;
                                            }
                                        }
                                    }
                                }
                                KeyCode::Left => {
                                    format_focus_time = true;
                                }
                                KeyCode::Right => {
                                    format_focus_time = false;
                                }
                                KeyCode::Enter => {
                                    state.time_format =
                                        TIME_OPTS[format_selection_time].to_string();
                                    state.date_format =
                                        DATE_OPTS[format_selection_date].to_string();
                                    let _ = state.set_status(crate::fl!(
                                        "tui-format-set-status",
                                        "time" => &state.time_format,
                                        "date" => &state.date_format
                                    ));
                                    status_timer = STATUS_TIMER_DURATION;
                                    format_picker_visible = false;
                                }
                                KeyCode::Esc => {
                                    format_picker_visible = false;
                                }
                                _ => {}
                            }
                            continue;
                        }

                        // Handle save prompt input first
                        if save_prompt_active {
                    match key.code {
                        KeyCode::Esc => {
                            save_prompt_active = false;
                            save_prompt.clear();
                        }
                        KeyCode::Enter => {
                            if !save_prompt.trim().is_empty() {
                                input::save_file(state, &input, Some(save_prompt.trim()));
                                status_timer = STATUS_TIMER_DURATION;
                            }
                            save_prompt_active = false;
                            save_prompt.clear();
                        }
                        KeyCode::Backspace => {
                            save_prompt.pop();
                        }
                        KeyCode::Char(c) => {
                            save_prompt.push(c);
                        }
                        _ => {}
                    }
                    continue;
                }

                // Locale picker interactions
                if locale_picker_visible {
                    match key.code {
                        KeyCode::Up => {
                            if locale_selection > 0 {
                                locale_selection -= 1;
                            }
                            if locale_selection < locale_scroll_offset {
                                locale_scroll_offset = locale_selection;
                            }
                        }
                        KeyCode::Down => {
                            if locale_selection + 1 < i18n::AVAILABLE_LOCALES.len() {
                                locale_selection += 1;
                                let max_offset = locale_selection.saturating_sub(7);
                                if locale_selection >= locale_scroll_offset + 8 {
                                    locale_scroll_offset = max_offset;
                                }
                            }
                        }
                        KeyCode::Enter => {
                            if let Some((code, name)) =
                                i18n::AVAILABLE_LOCALES.get(locale_selection)
                            {
                                if i18n::set_locale(code).is_ok() {
                                    let _ = state.set_status(crate::fl!(
                                        "tui-locale-set-status",
                                        "name" => *name
                                    ));
                                    status_timer = STATUS_TIMER_DURATION;
                                }
                            }
                            locale_picker_visible = false;
                            locale_scroll_offset = 0;
                        }
                        KeyCode::Esc => {
                            locale_picker_visible = false;
                            locale_scroll_offset = 0;
                        }
                        _ => {}
                    }
                    continue;
                }

                // Global shortcuts (independent of mode)
                if key.modifiers.contains(KeyModifiers::CONTROL) {
                    match key.code {
                        KeyCode::Char('q') => break,
                        KeyCode::Char('s') => {
                            if state.current_filename.is_some() {
                                input::save_file(state, &input, None);
                                status_timer = STATUS_TIMER_DURATION;
                            } else {
                                save_prompt_active = true;
                                save_prompt.clear();
                                save_prompt.push_str(&crate::fl!("tui-save-default-filename"));
                            }
                            continue;
                        }
                        KeyCode::Char('c') => {
                            let now = std::time::Instant::now();
                            let should_quit = last_ctrlc_time
                                .map(|t| {
                                    now.duration_since(t) <= std::time::Duration::from_millis(800)
                                })
                                .unwrap_or(false);
                            if should_quit {
                                break;
                            } else {
                                last_ctrlc_time = Some(now);
                                let _ = state.set_status(crate::fl!("tui-quit-ctrlc"));
                                status_timer = STATUS_TIMER_DURATION;
                            }
                            continue;
                        }
                        // Toggle help with Ctrl+H (preserves '?' for typing).
                        KeyCode::Char('h') => {
                            help_visible = !help_visible;
                            locale_picker_visible = false;
                            status_timer = STATUS_TIMER_DURATION;
                            continue;
                        }
                        KeyCode::Char('l') if key.modifiers.contains(KeyModifiers::SHIFT) => {
                            help_visible = false;
                            locale_picker_visible = true;
                            format_picker_visible = false;
                            let current = i18n::get_locale().to_string();
                            locale_selection = i18n::AVAILABLE_LOCALES
                                .iter()
                                .position(|(code, _)| *code == current)
                                .unwrap_or(0);
                            locale_scroll_offset = locale_selection.saturating_sub(3);
                            continue;
                        }
                        KeyCode::Char('t') if key.modifiers.contains(KeyModifiers::SHIFT) => {
                            help_visible = false;
                            locale_picker_visible = false;
                            format_picker_visible = true;
                            let time_opts = ["iso", "long", "short", "time", "12h"];
                            let date_opts = ["iso", "long", "short"];
                            format_selection_time = time_opts
                                .iter()
                                .position(|o| *o == state.time_format)
                                .unwrap_or(0);
                            format_selection_date = date_opts
                                .iter()
                                .position(|o| *o == state.date_format)
                                .unwrap_or(0);
                            format_focus_time = true;
                            format_time_offset = format_selection_time.saturating_sub(2);
                            format_date_offset = format_selection_date.saturating_sub(2);
                            continue;
                        }
                        KeyCode::Char('d') if key.modifiers.contains(KeyModifiers::SHIFT) => {
                            help_visible = false;
                            locale_picker_visible = false;
                            format_picker_visible = true;
                            let time_opts = ["iso", "long", "short", "time", "12h"];
                            let date_opts = ["iso", "long", "short"];
                            format_selection_time = time_opts
                                .iter()
                                .position(|o| *o == state.time_format)
                                .unwrap_or(0);
                            format_selection_date = date_opts
                                .iter()
                                .position(|o| *o == state.date_format)
                                .unwrap_or(0);
                            format_focus_time = false;
                            format_time_offset = format_selection_time.saturating_sub(2);
                            format_date_offset = format_selection_date.saturating_sub(2);
                            continue;
                        }
                        _ => {}
                    }
                }

                // F1 also toggles help (no modifiers needed)
                if matches!(key.code, KeyCode::F(1)) {
                    help_visible = !help_visible;
                    locale_picker_visible = false;
                    format_picker_visible = false;
                    status_timer = STATUS_TIMER_DURATION;
                    continue;
                }

                if help_visible && matches!(key.code, KeyCode::Esc) {
                    help_visible = false;
                    continue;
                }

                if format_picker_visible && matches!(key.code, KeyCode::Esc) {
                    format_picker_visible = false;
                    continue;
                }

                if matches!(key.code, KeyCode::Esc) {
                    let now = std::time::Instant::now();
                    let should_quit = last_esc_time
                        .map(|t| now.duration_since(t) <= std::time::Duration::from_millis(800))
                        .unwrap_or(false);
                    if should_quit {
                        break;
                    } else {
                        last_esc_time = Some(now);
                        let _ = state.set_status(crate::fl!("tui-quit-esc"));
                        status_timer = STATUS_TIMER_DURATION;
                    }
                    continue;
                }

                {
                    let changed = input::handle_normal_mode(
                        key,
                        &mut input,
                        &mut cursor_pos,
                        state,
                        registry,
                        &mut selection_start,
                    );

                    // If text was edited, mark for re-evaluation
                    if changed {
                        last_edit_time = Some(std::time::Instant::now());
                        pending_eval_line = Some(input.char_to_line(cursor_pos));
                    }
                }
            }
        }
    }

    // Cleanup
    disable_raw_mode()?;
    execute!(terminal.backend_mut(), LeaveAlternateScreen)?;
    terminal.show_cursor()?;
    Ok(())
}
