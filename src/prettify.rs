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
