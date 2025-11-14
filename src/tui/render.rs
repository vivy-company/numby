use ratatui::{
    Frame,
    layout::{Alignment, Rect},
    style::{Color, Style, Stylize},
    text::{Line, Span, Text},
    widgets::{Block, Paragraph},
};
use ropey::Rope;

use crate::models::{AppState, Mode};
use super::syntax;

/// Context for rendering to reduce parameter count
pub struct RenderContext<'a> {
    pub input: &'a Rope,
    pub cursor_pos: usize,
    pub state: &'a AppState,
    pub config: &'a crate::config::Config,
    pub registry: &'a crate::evaluator::AgentRegistry,
    pub mode: &'a Mode,
    pub show_status: bool,
    pub scroll_offset: &'a mut usize,
}

/// Main UI rendering function
pub fn render_ui(f: &mut Frame, mut ctx: RenderContext) {
    let show_status = ctx.show_status && !matches!(ctx.mode, Mode::Command(cmd) if !cmd.is_empty());
    let size = f.size();

    let padding_top = ctx.config.padding_top;
    let padding_bottom = ctx.config.padding_bottom;
    let padding_left = ctx.config.padding_left;
    let padding_right = ctx.config.padding_right;

    let text_height = if show_status {
        size.height.saturating_sub(1 + padding_top + padding_bottom)
    } else {
        size.height.saturating_sub(padding_top + padding_bottom)
    };

    // Split screen into left (input) and right (results) - 70/30 ratio
    let available_width = size.width.saturating_sub(padding_left + padding_right);
    let left_width = (available_width * 70) / 100;
    let left_rect = Rect {
        x: padding_left,
        y: padding_top,
        width: left_width,
        height: text_height,
    };
    let right_rect = Rect {
        x: padding_left + left_width,
        y: padding_top,
        width: available_width - left_width,
        height: text_height,
    };

    // Render status bar if needed
    if show_status {
        render_status_bar(f, ctx.state, size);
    }

    // Calculate cursor line for highlighting across both panels
    let cursor_line = ctx.input.char_to_line(ctx.cursor_pos);

    // Render full-width background for current line first (ignores padding, spans entire width)
    if cursor_line >= *ctx.scroll_offset && cursor_line < *ctx.scroll_offset + text_height as usize {
        let line_y = cursor_line - *ctx.scroll_offset;
        let highlight_rect = Rect {
            x: 0,
            y: padding_top + line_y as u16,
            width: size.width,
            height: 1,
        };
        let bg_block = Block::default().style(Style::default().bg(Color::Black));
        f.render_widget(bg_block, highlight_rect);
    }

    // Render input and results on top of the background
    render_input_panel(f, left_rect, &ctx);
    render_results_panel(f, right_rect, &ctx);

    // Render cursor
    render_cursor(f, &mut ctx, text_height, size);
}

/// Renders the status bar at the bottom
fn render_status_bar(f: &mut Frame, state: &AppState, size: Rect) {
    let status_text = state.status.read().expect("Failed to acquire read lock on status").clone();
    if !status_text.is_empty() {
        let status_rect = Rect {
            x: 0,
            y: size.height - 1,
            width: size.width,
            height: 1,
        };
        let status_paragraph = Paragraph::new(status_text).style(Style::default().fg(Color::Green));
        f.render_widget(status_paragraph, status_rect);
    }
}

/// Renders the left panel with syntax-highlighted input
fn render_input_panel(f: &mut Frame, rect: Rect, ctx: &RenderContext) {
    let mut left_text = Text::default();

    for line in ctx.input.lines().skip(*ctx.scroll_offset).take(rect.height as usize) {
        let line_str = line.to_string();

        // Check highlight cache first
        let cache_key = line_str.to_string();
        let spans = if let Some(cached_spans) = ctx.state.cache.get_highlight(&cache_key) {
            cached_spans
        } else {
            // Compute and cache
            let computed = syntax::compute_spans(&line_str, ctx.state, ctx.config);
            ctx.state.cache.set_highlight(cache_key, computed.clone());
            computed
        };

        left_text.lines.push(Line::from(spans));
    }

    let left_paragraph = Paragraph::new(left_text).block(Block::default());
    f.render_widget(left_paragraph, rect);
}

/// Renders the right panel with evaluation results
fn render_results_panel(f: &mut Frame, rect: Rect, ctx: &RenderContext) {
    let mut right_text = Text::default();

    for line in ctx.input.lines().skip(*ctx.scroll_offset).take(rect.height as usize) {
        let line_str = line.to_string();
        let line_trim = line_str.trim();

        if line_trim.is_empty() {
            right_text.lines.push(Line::default());
            continue;
        }

        // Create cache key that includes variables state
        let vars = ctx.state.variables.read().expect("Failed to acquire read lock on variables");
        // Use sorted BTreeMap for deterministic cache key generation
        let vars_sorted: std::collections::BTreeMap<_, _> = vars.iter()
            .map(|(k, v)| (k.as_str(), v))
            .collect();
        let vars_hash = format!("{:?}", vars_sorted);
        drop(vars); // Release read lock

        let cache_key = format!("{}::{}", line_trim, vars_hash);

        // Check display cache
        let result = if let Some(cached) = ctx.state.cache.get_display(&cache_key) {
            cached
        } else {
            // Evaluate and cache
            let eval_result = ctx.registry.evaluate_for_display(line_trim, ctx.state).map(|(r, _)| r);
            if let Some(ref res) = eval_result {
                ctx.state.cache.set_display(cache_key, Some(res.clone()));
            } else {
                ctx.state.cache.set_display(cache_key, None);
            }
            eval_result
        };

        if let Some(result) = result {
            right_text.lines.push(Line::from(Span::styled(
                result,
                Style::default().fg(Color::Green).bold(),
            )));
        } else {
            right_text.lines.push(Line::default());
        }
    }

    let right_paragraph = Paragraph::new(right_text).alignment(Alignment::Right);
    f.render_widget(right_paragraph, rect);
}

/// Calculates cursor position in the visible area and renders it
fn render_cursor(f: &mut Frame, ctx: &mut RenderContext, text_height: u16, size: Rect) {
    let line_idx = ctx.input.char_to_line(ctx.cursor_pos);
    let line_start = ctx.input.line_to_char(line_idx);
    let col = ctx.cursor_pos - line_start;

    // Adjust scroll offset
    if line_idx >= *ctx.scroll_offset + text_height as usize {
        *ctx.scroll_offset = line_idx - text_height as usize + 1;
    } else if line_idx < *ctx.scroll_offset {
        *ctx.scroll_offset = line_idx;
    }

    let cursor_y = line_idx - *ctx.scroll_offset;
    let cursor_x = col as u16;

    let padding_left = ctx.config.padding_left;
    let padding_top = ctx.config.padding_top;

    // Command mode UI
    if let Mode::Command(cmd) = ctx.mode {
        render_command_mode(f, cmd, size);
        f.set_cursor((cmd.len() + 1) as u16, size.height - 1);
    } else {
        f.set_cursor(cursor_x + padding_left, cursor_y as u16 + padding_top);
    }
}

/// Renders the command mode interface
fn render_command_mode(f: &mut Frame, cmd: &str, size: Rect) {
    // Help tooltip above command
    let help_rect = Rect {
        x: 0,
        y: size.height - 3,
        width: size.width,
        height: 2,
    };
    let help_block = Block::default().style(Style::default().bg(Color::Black).fg(Color::White));
    let help_text = format!(
        "{}\n{}",
        crate::fl!("help-commands"),
        crate::fl!("help-shortcuts")
    );
    let help_paragraph = Paragraph::new(help_text).block(help_block);
    f.render_widget(help_paragraph, help_rect);

    // Command prompt
    let prompt = format!(":{}", cmd);
    let prompt_rect = Rect {
        x: 0,
        y: size.height - 1,
        width: size.width,
        height: 1,
    };
    let prompt_paragraph = Paragraph::new(prompt).block(Block::default());
    f.render_widget(prompt_paragraph, prompt_rect);
}
