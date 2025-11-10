/// Prettify a number for display with appropriate suffixes.
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
        // For 100+, no decimal if whole
        if num.fract() == 0.0 {
            format!("{:.0}", num)
        } else {
            format!("{}", num)
        }
    } else {
        format!("{:.2}", num) // For smaller, 2 decimals
    }
}