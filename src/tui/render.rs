use ratatui::{
    layout::{Alignment, Constraint, Direction, Layout, Rect},
    style::{Color, Style, Stylize},
    text::{Line, Span, Text},
    widgets::{Block, Paragraph},
    Frame,
};
use ropey::Rope;

use super::syntax;
use crate::models::AppState;

/// Context for rendering to reduce parameter count
pub struct RenderContext<'a> {
    pub input: &'a Rope,
    pub cursor_pos: usize,
    pub state: &'a AppState,
    pub config: &'a crate::config::Config,
    pub registry: &'a crate::evaluator::AgentRegistry,
    pub show_status: bool,
    pub scroll_offset: &'a mut usize,
    pub help_visible: bool,
    pub locale_picker_visible: bool,
    pub locale_selection: usize,
    pub current_locale: &'a str,
    pub locale_scroll_offset: usize,
    pub locale_visible: usize,
    pub save_prompt_active: bool,
    pub save_prompt: &'a str,
    pub available_locales: &'static [(&'static str, &'static str)],
}

/// Main UI rendering function
pub fn render_ui(f: &mut Frame, mut ctx: RenderContext) {
    let show_status = ctx.show_status;
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
    render_status_bar(f, ctx.state, size, show_status);

    // Minimal footer with core shortcuts (fixed position)
    render_footer(f, size);

    // Calculate cursor line for highlighting across both panels
    let cursor_line = ctx.input.char_to_line(ctx.cursor_pos);

    // Render full-width background for current line first (ignores padding, spans entire width)
    if cursor_line >= *ctx.scroll_offset && cursor_line < *ctx.scroll_offset + text_height as usize
    {
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

    // Overlays
    if ctx.locale_picker_visible {
        render_locale_overlay(
            f,
            size,
            ctx.available_locales,
            ctx.locale_selection,
            ctx.current_locale,
            ctx.locale_scroll_offset,
            ctx.locale_visible,
        );
    } else if ctx.help_visible {
        render_help_overlay(f, size);
    }

    // Save prompt overlay (status-line style)
    if ctx.save_prompt_active {
        render_save_prompt(f, size, ctx.save_prompt);
    }

    // Render cursor
    render_cursor(f, &mut ctx, text_height, size);
}

/// Renders the status bar at the bottom
fn render_status_bar(f: &mut Frame, state: &AppState, size: Rect, show_status: bool) {
    if !show_status {
        return;
    }

    let status_text = state
        .status
        .read()
        .expect("Failed to acquire read lock on status")
        .clone();

    if status_text.is_empty() {
        return;
    }

    let status_rect = Rect {
        x: 0,
        y: size.height - 1,
        width: size.width,
        height: 1,
    };

    let status_paragraph = Paragraph::new(status_text).style(Style::default().fg(Color::Green));
    f.render_widget(status_paragraph, status_rect);
}

/// Renders a minimal footer with core shortcuts
fn render_footer(f: &mut Frame, size: Rect) {
    // Fixed two lines from bottom: last line reserved for status
    let y = size.height.saturating_sub(2);
    let footer_rect = Rect {
        x: 0,
        y,
        width: size.width,
        height: 1,
    };

    let key_style = Style::default().fg(Color::Cyan).bold();
    let segments = vec![Span::styled("Ctrl+H", key_style), Span::raw(" help")];

    let footer = Paragraph::new(Line::from(segments)).alignment(Alignment::Left);
    f.render_widget(footer, footer_rect);
}

fn render_help_overlay(f: &mut Frame, size: Rect) {
    // Bottom sheet style like Helix command palette
    let height = 8u16;
    let area = Rect {
        x: 0,
        y: size.height.saturating_sub(height),
        width: size.width,
        height,
    };

    let entries = [
        ("Enter", "newline / eval"),
        ("Ctrl+S", "save (prompt if unnamed)"),
        ("Ctrl+Q", "quit"),
        ("Ctrl+I", "copy shareable markdown"),
        ("Ctrl+Y", "copy current result"),
        ("Ctrl+L", "clear cache"),
        ("Ctrl+H", "toggle help"),
        ("Ctrl+Shift+L", "locale picker"),
        ("F1", "toggle help"),
        ("Esc", "close help or prompt"),
    ];

    let mid = entries.len().div_ceil(2);
    let (left, right) = entries.split_at(mid);

    let key = |k: &str| Span::styled(k.to_string(), Style::default().fg(Color::LightCyan).bold());
    let row_line = |(k, v): (&str, &str)| {
        Line::from(vec![
            key(k),
            Span::raw("  "),
            Span::styled(v.to_string(), Style::default().fg(Color::White)),
        ])
    };

    let left_lines: Vec<Line> = left.iter().map(|&(k, v)| row_line((k, v))).collect();
    let right_lines: Vec<Line> = right.iter().map(|&(k, v)| row_line((k, v))).collect();

    let body_chunks = Layout::default()
        .direction(Direction::Horizontal)
        .constraints([Constraint::Percentage(50), Constraint::Percentage(50)])
        .split(area);

    let bg_style = Style::default().bg(Color::Rgb(20, 22, 30)).fg(Color::White);
    let block = Block::default().style(bg_style);
    f.render_widget(block, area);

    let left_p = Paragraph::new(left_lines).style(bg_style);
    let right_p = Paragraph::new(right_lines).style(bg_style);

    f.render_widget(left_p, body_chunks[0]);
    f.render_widget(right_p, body_chunks[1]);
}

fn render_locale_overlay(
    f: &mut Frame,
    size: Rect,
    locales: &[(&str, &str)],
    selected: usize,
    current_locale: &str,
    scroll_offset: usize,
    visible: usize,
) {
    let height = 12u16; // taller to sit above footer/status
    let area = Rect {
        x: 0,
        y: size.height.saturating_sub(height).saturating_sub(2), // sit above footer + status
        width: size.width,
        height,
    };

    let bg_style = Style::default().bg(Color::Rgb(16, 18, 24)).fg(Color::White);
    let block = Block::default().style(bg_style);
    f.render_widget(block, area);

    let mut lines: Vec<Line> = Vec::new();
    lines.push(Line::from(vec![
        Span::styled("Locale", Style::default().fg(Color::LightCyan).bold()),
        Span::raw("  ↑/↓ select   Enter apply   Esc close"),
    ]));
    lines.push(Line::from(vec![
        Span::raw(" "),
        Span::styled("Ctrl+Shift+L", Style::default().fg(Color::Gray)),
        Span::raw(" to open"),
    ]));

    for (idx, (code, name)) in locales.iter().enumerate().skip(scroll_offset).take(visible) {
        let is_selected = idx == selected;
        let is_active = *code == current_locale;
        let marker = if is_active { "●" } else { "○" };
        let spans = vec![
            Span::styled(
                marker,
                Style::default().fg(if is_active {
                    Color::LightGreen
                } else {
                    Color::Gray
                }),
            ),
            Span::raw(" "),
            Span::styled(*name, Style::default().fg(Color::White)),
            Span::raw("  "),
            Span::styled(format!("({})", code), Style::default().fg(Color::Gray)),
        ];

        let line = Line::from(spans);
        if is_selected {
            lines.push(line.style(Style::default().bg(Color::Rgb(48, 52, 63))));
        } else {
            lines.push(line);
        }
    }

    let paragraph = Paragraph::new(lines).style(bg_style);
    f.render_widget(paragraph, area);
}

fn render_save_prompt(f: &mut Frame, size: Rect, prompt: &str) {
    let area = Rect {
        x: 0,
        y: size.height.saturating_sub(1),
        width: size.width,
        height: 1,
    };

    let filename_span = if prompt.is_empty() {
        Span::styled("untitled.numby", Style::default().fg(Color::White))
    } else {
        Span::styled(prompt.to_string(), Style::default().fg(Color::White))
    };

    let content = Line::from(vec![
        Span::styled("Save as:", Style::default().fg(Color::LightCyan).bold()),
        Span::raw(" "),
        filename_span,
        Span::raw("  "),
        Span::styled(
            "(Enter to save, Esc to cancel)",
            Style::default().fg(Color::Gray),
        ),
    ]);

    let paragraph = Paragraph::new(content).style(Style::default().bg(Color::Rgb(48, 52, 63)));
    f.render_widget(paragraph, area);
}

/// Renders the left panel with syntax-highlighted input
fn render_input_panel(f: &mut Frame, rect: Rect, ctx: &RenderContext) {
    let mut left_text = Text::default();

    for line in ctx
        .input
        .lines()
        .skip(*ctx.scroll_offset)
        .take(rect.height as usize)
    {
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

    for line in ctx
        .input
        .lines()
        .skip(*ctx.scroll_offset)
        .take(rect.height as usize)
    {
        let line_str = line.to_string();
        let line_trim = line_str.trim();

        if line_trim.is_empty() {
            right_text.lines.push(Line::default());
            continue;
        }

        // Create cache key that includes variables state
        let vars = ctx
            .state
            .variables
            .read()
            .expect("Failed to acquire read lock on variables");
        // Use sorted BTreeMap for deterministic cache key generation
        let vars_sorted: std::collections::BTreeMap<_, _> =
            vars.iter().map(|(k, v)| (k.as_str(), v)).collect();
        let vars_hash = format!("{:?}", vars_sorted);
        drop(vars); // Release read lock

        let cache_key = format!(
            "{}::{}::{}",
            line_trim,
            vars_hash,
            ctx.state.cache.generation()
        );

        // Check display cache
        let result = if let Some(cached) = ctx.state.cache.get_display(&cache_key) {
            cached
        } else {
            // Evaluate and cache
            let eval_result = ctx
                .registry
                .evaluate_for_display(line_trim, ctx.state)
                .map(|(r, _)| r);
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

    if ctx.save_prompt_active {
        const LABEL: &str = "Save as: ";
        let x = LABEL.len() as u16 + ctx.save_prompt.len() as u16;
        let y = size.height.saturating_sub(1);
        f.set_cursor(x, y);
    } else {
        f.set_cursor(cursor_x + padding_left, cursor_y as u16 + padding_top);
    }
}
