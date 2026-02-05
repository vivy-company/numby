//! Number formatting utilities for pretty display.

/// Format a number with appropriate scale suffixes (k, M, B, T).
///
/// This function formats numbers in a human-readable way:
/// - Numbers >= 1 trillion use 'T' suffix
/// - Numbers >= 1 billion use 'B' suffix
/// - Numbers >= 1 million use 'M' suffix
/// - Numbers >= 1 thousand use 'k' suffix
/// - Numbers >= 100 show no decimal places
/// - Numbers < 100 show 2 decimal places
///
/// # Examples
///
/// ```
/// use numby::prettify::prettify_number;
///
/// assert_eq!(prettify_number(1500.0), "1.5k");
/// assert_eq!(prettify_number(2500000.0), "2.5M");
/// assert_eq!(prettify_number(3200000000.0), "3.2B");
/// assert_eq!(prettify_number(42.5), "42.50");
/// assert_eq!(prettify_number(150.0), "150");
/// ```
pub fn prettify_number(num: f64) -> String {
    let abs_num = num.abs();
    if abs_num >= 1e12 {
        format!("{:.1}T", num / 1e12)
    } else if abs_num >= 1e9 {
        format!("{:.1}B", num / 1e9)
    } else if abs_num >= 1e6 {
        format!("{:.1}M", num / 1e6)
    } else if abs_num >= 1e3 {
        format!("{:.1}k", num / 1e3)
    } else if abs_num >= 1e2 {
        // For 100+, round to nearest integer
        format!("{:.0}", num)
    } else {
        format!("{:.2}", num) // For smaller, 2 decimals
    }
}

/// Default maximum decimals for precision formatting.
pub const DEFAULT_MAX_DECIMALS: usize = 12;

/// Maximum decimals cap to keep outputs reasonable for f64.
pub const MAX_DECIMALS_CAP: usize = 15;

/// Normalize a number format string.
/// Returns Some("pretty") or Some("precision") if supported.
pub fn normalize_number_format(mode: &str) -> Option<&'static str> {
    if mode.eq_ignore_ascii_case("pretty") {
        Some("pretty")
    } else if mode.eq_ignore_ascii_case("precision") {
        Some("precision")
    } else {
        None
    }
}

/// Clamp max decimals to a safe upper bound.
pub fn clamp_max_decimals(max_decimals: usize) -> usize {
    max_decimals.min(MAX_DECIMALS_CAP)
}

/// Format a number using the given mode and max decimals.
pub fn format_number(num: f64, mode: &str, max_decimals: usize) -> String {
    if normalize_number_format(mode) == Some("precision") {
        format_precision(num, max_decimals)
    } else {
        prettify_number(num)
    }
}

fn format_precision(num: f64, max_decimals: usize) -> String {
    if !num.is_finite() {
        return num.to_string();
    }
    let decimals = clamp_max_decimals(max_decimals);
    if decimals == 0 {
        return format!("{:.0}", num);
    }
    let mut s = format!("{:.1$}", num, decimals);
    if s.contains('.') {
        while s.ends_with('0') {
            s.pop();
        }
        if s.ends_with('.') {
            s.pop();
        }
    }
    if s == "-0" {
        return "0".to_string();
    }
    s
}
