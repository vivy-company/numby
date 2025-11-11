use anyhow::Result;
use crossterm::{
    event::{self, Event},
    execute,
    terminal::{
        disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen, SetTitle,
    },
};
use ratatui::{backend::CrosstermBackend, Terminal};
use ropey::Rope;
use std::fs;
use std::io;

use crate::models::{AppState, Mode};

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
    let mut mode = Mode::Normal;
    let mut status_timer: u32 = 0;
    let mut scroll_offset = 0;

    // Main event loop
    loop {
        // Render UI
        terminal.draw(|f| {
            render::render_ui(
                f,
                RenderContext {
                    input: &input,
                    cursor_pos,
                    state,
                    config,
                    registry,
                    mode: &mode,
                    show_status: status_timer > 0,
                    scroll_offset: &mut scroll_offset,
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

        // Handle input events
        if event::poll(std::time::Duration::from_millis(100))? {
            if let Event::Key(key) = event::read()? {
                match mode {
                    Mode::Normal => {
                        input::handle_normal_mode(
                            key,
                            &mut input,
                            &mut cursor_pos,
                            &mut mode,
                            state,
                            registry,
                        );

                        // Set status timer when entering command mode
                        if matches!(mode, Mode::Command(_)) {
                            status_timer = STATUS_TIMER_DURATION;
                        }
                    }
                    Mode::Command(_) => {
                        let should_quit = input::handle_command_mode(
                            key,
                            &mut mode,
                            state,
                            &input,
                        );

                        if should_quit {
                            break;
                        }

                        // Set status timer after command execution
                        if matches!(mode, Mode::Normal) {
                            status_timer = 300; // 30 seconds for save messages
                        }
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
