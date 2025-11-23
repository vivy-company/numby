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
    pub format_picker_visible: bool,
    pub format_selection_time: usize,
    pub format_selection_date: usize,
    pub format_focus_time: bool,
    pub format_time_offset: usize,
    pub format_date_offset: usize,
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
    } else if ctx.format_picker_visible {
        render_format_overlay(
            f,
            size,
            ctx.format_selection_time,
            ctx.format_selection_date,
            ctx.format_time_offset,
            ctx.format_date_offset,
            ctx.format_focus_time,
            ctx.state,
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
        ("Ctrl+Shift+T", "time format picker"),
        ("Ctrl+Shift+D", "date format picker"),
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
    f.render_widget(&block, area);

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
    f.render_widget(&block, area);

    // Vertical split: header / list / footer
    let regions = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(1),
            Constraint::Min(1),
            Constraint::Length(1),
        ])
        .split(area);

    let header = Paragraph::new(Line::from(vec![Span::styled(
        "Locale",
        Style::default().fg(Color::LightCyan).bold(),
    )]))
    .style(bg_style);

    // Compute how many rows fit
    let max_rows = regions[1].height as usize;
    let rows_to_show = visible.min(max_rows);

    let mut lines: Vec<Line> = Vec::new();

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

    // Trim to rows_to_show
    let lines: Vec<Line> = lines.into_iter().take(rows_to_show).collect();

    // Draw header
    f.render_widget(header, regions[0]);

    // Draw list
    f.render_widget(Paragraph::new(lines).style(bg_style), regions[1]);

    // Controls footer
    let footer = Paragraph::new(Line::from(vec![Span::raw(
        "↑/↓ select   Enter apply   Esc close",
    )]))
    .style(bg_style)
    .alignment(Alignment::Center);
    f.render_widget(footer, regions[2]);
}

fn render_format_overlay(
    f: &mut Frame,
    size: Rect,
    time_idx: usize,
    date_idx: usize,
    time_offset: usize,
    date_offset: usize,
    focus_time: bool,
    _state: &AppState,
) {
    let options_time = ["iso", "long", "short", "time", "12h"];
    let options_date = ["iso", "long", "short"];

    let height = 12u16;
    let area = Rect {
        x: 0,
        y: size.height.saturating_sub(height).saturating_sub(2),
        width: size.width,
        height,
    };

    let bg_style = Style::default().bg(Color::Rgb(16, 18, 24)).fg(Color::White);
    let block = Block::default().style(bg_style);
    f.render_widget(block, area);

    let selected_style = Style::default().fg(Color::Yellow).bold();
    let focus_bg = Color::Rgb(48, 52, 63);

    // Split area into two columns below the header
    let columns = Layout::default()
        .direction(Direction::Horizontal)
        .constraints([Constraint::Percentage(50), Constraint::Percentage(50)])
        .split(Rect {
            x: area.x,
            y: area.y + 1,
            width: area.width,
            height: area.height.saturating_sub(1),
        });

    // Time list with scrolling
    let mut time_lines: Vec<Line> = Vec::new();
    time_lines.push(Line::from(vec![Span::styled(
        "Time",
        Style::default().fg(Color::LightCyan).bold(),
    )]));
    let time_visible = columns[0].height as usize - 1;
    for (i, opt) in options_time
        .iter()
        .enumerate()
        .skip(time_offset)
        .take(time_visible)
    {
        let is_selected = i == time_idx;
        let marker = if is_selected { "●" } else { "○" };
        let preview = match *opt {
            "iso" => "2025-11-23 14:05 +00:00",
            "long" => "Sunday, 2025-11-23 14:05 +00:00",
            "short" => "11/23 14:05 UTC",
            "time" => "14:05 +00:00",
            "12h" => "2025-11-23 02:05 PM +00:00",
            _ => "",
        };
        let mut line = Line::from(vec![
            Span::styled(marker, Style::default().fg(Color::Gray)),
            Span::raw(" "),
            Span::styled(*opt, Style::default().fg(Color::White)),
            Span::raw("   "),
            Span::styled(preview, Style::default().fg(Color::Gray)),
        ]);
        if focus_time {
            line = line.style(Style::default().bg(focus_bg));
        }
        if is_selected {
            line = line.style(selected_style);
        }
        time_lines.push(line);
    }

    // Date list with scrolling
    let mut date_lines: Vec<Line> = Vec::new();
    date_lines.push(Line::from(vec![Span::styled(
        "Date",
        Style::default().fg(Color::LightCyan).bold(),
    )]));
    let date_visible = columns[1].height as usize - 1;
    for (i, opt) in options_date
        .iter()
        .enumerate()
        .skip(date_offset)
        .take(date_visible)
    {
        let is_selected = i == date_idx;
        let marker = if is_selected { "●" } else { "○" };
        let preview = match *opt {
            "iso" => "2025-11-23",
            "long" => "Sunday, 2025-11-23",
            "short" => "11/23/25",
            _ => "",
        };
        let mut line = Line::from(vec![
            Span::styled(marker, Style::default().fg(Color::Gray)),
            Span::raw(" "),
            Span::styled(*opt, Style::default().fg(Color::White)),
            Span::raw("   "),
            Span::styled(preview, Style::default().fg(Color::Gray)),
        ]);
        if !focus_time {
            line = line.style(Style::default().bg(focus_bg));
        }
        if is_selected {
            line = line.style(selected_style);
        }
        date_lines.push(line);
    }

    // Draw lists
    f.render_widget(Paragraph::new(time_lines).style(bg_style), columns[0]);
    f.render_widget(Paragraph::new(date_lines).style(bg_style), columns[1]);

    // Controls footer at bottom of overlay
    let controls = Paragraph::new(Line::from(vec![Span::raw(
        "↑/↓ select   ←/→ switch list   Enter apply   Esc close",
    )]))
    .style(bg_style)
    .alignment(Alignment::Left);
    let footer_area = Rect {
        x: area.x,
        y: area.y + area.height.saturating_sub(1),
        width: area.width,
        height: 1,
    };
    f.render_widget(controls, footer_area);
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
