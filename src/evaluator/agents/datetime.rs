use chrono::offset::FixedOffset;
use chrono::{DateTime, Datelike, Duration, Local, Months, NaiveDate, NaiveDateTime, TimeZone, Utc, Weekday};
use chrono_tz::Tz;
use chrono::Offset;
use lazy_static::lazy_static;
use regex::Regex;

use crate::config::Config;
use crate::evaluator::agents::PRIORITY_DATETIME;
use crate::models::{Agent, AppState};

/// Human-friendly date/time agent.
///
/// Supports:
/// - now / now in UTC
/// - today / tomorrow / yesterday
/// - relative offsets: "100 days from today", "2 weeks ago", "3 hours from now"
/// - arithmetic with explicit date: "2025-01-01 + 30 days"
/// - day-of-week shorthands: "next monday", "last friday", "this sunday"
/// - differences: "days between 2025-01-01 and 2025-01-31"
pub struct DateTimeAgent;

impl Agent for DateTimeAgent {
    fn priority(&self) -> i32 {
        PRIORITY_DATETIME
    }

    fn can_handle(&self, input: &str, _state: &AppState) -> bool {
        let lower = input.to_lowercase();
        lower.contains("now")
            || lower.contains("today")
            || lower.contains("tomorrow")
            || lower.contains("yesterday")
            || lower.contains("days between")
            || lower.contains("next ")
            || lower.contains("last ")
            || lower.contains("this ")
            || TIME_IN_RE.is_match(&lower)
            || RELATIVE_RE.is_match(&lower)
            || DATE_ARITH_RE.is_match(&lower)
    }

    fn process(
        &self,
        input: &str,
        state: &mut AppState,
        config: &Config,
    ) -> Option<(String, bool, Option<f64>, Option<String>)> {
        let lower = input.trim().to_lowercase();

        // Diff: "days between A and B"
        if let Some(caps) = DAYS_BETWEEN_RE.captures(&lower) {
            let left = caps.name("left")?.as_str().trim();
            let right = caps.name("right")?.as_str().trim();
            if let (Some(d1), Some(d2)) =
                (parse_any_datetime(left, config), parse_any_datetime(right, config))
            {
                let delta = d2 - d1;
                let days = delta.num_seconds() as f64 / 86_400.0;
                return Some((
                    format!("{} days", crate::prettify::prettify_number(days)),
                    false,
                    None,
                    None,
                ));
            }
        }

        // Now / today / tomorrow / yesterday / next/last weekday
        if let Some(result) = handle_named_keywords(&lower, config, state) {
            return Some(result);
        }

        // Relative expressions: "10 days from now", "5 hours ago"
        if let Some(result) = handle_relative(&lower, config, state) {
            return Some(result);
        }

        // Date arithmetic: "2025-01-01 + 30 days"
        if let Some(result) = handle_date_arith(&lower, config, state) {
            return Some(result);
        }

        None
    }
}

lazy_static! {
    static ref RELATIVE_RE: Regex = Regex::new(
        r"(?P<num>-?\d+)\s+(?P<unit>seconds?|minutes?|hours?|days?|weeks?|months?|years?)\s+(?P<dir>from now|from today|from tomorrow|later|in|ago|before now|before today|before tomorrow)"
    )
    .expect("relative regex");
    static ref DATE_ARITH_RE: Regex = Regex::new(
        r"(?P<date>.+?)\s*(?P<op>\+|plus|-|minus)\s*(?P<num>\d+)\s+(?P<unit>seconds?|minutes?|hours?|days?|weeks?|months?|years?)"
    )
    .expect("date arithmetic regex");
    static ref DAYS_BETWEEN_RE: Regex =
        Regex::new(r"days between (?P<left>.+) and (?P<right>.+)").expect("days between regex");
    static ref WEEKDAY_RE: Regex =
        Regex::new(r"^(next|last|this)\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b")
            .expect("weekday regex");
    static ref NOW_RE: Regex =
        Regex::new(r"^now(?:\s+(?:in|to)\s+(?P<tz>.+))?$").expect("now regex");
    static ref TIME_IN_RE: Regex =
        Regex::new(r"^time\s+(?:in|at|for)\s+(?P<loc>.+)$").expect("time in regex");
    static ref TODAY_RE: Regex =
        Regex::new(r"^today(?:\s+in\s+(?P<tz>.+))?$").expect("today regex");
    static ref TOMORROW_RE: Regex =
        Regex::new(r"^tomorrow(?:\s+in\s+(?P<tz>.+))?$").expect("tomorrow regex");
    static ref YESTERDAY_RE: Regex =
        Regex::new(r"^yesterday(?:\s+in\s+(?P<tz>.+))?$").expect("yesterday regex");
}

fn handle_named_keywords(
    lower: &str,
    config: &Config,
    state: &AppState,
) -> Option<(String, bool, Option<f64>, Option<String>)> {
    if let Some(caps) = TIME_IN_RE.captures(lower) {
        let loc = caps.name("loc")?.as_str().trim();
        if let Some(tz) = resolve_tz(Some(loc), config) {
            let now_fixed = fixed_from_tz(&tz, Utc::now().naive_utc());
            let fmt = current_time_format(state);
            return Some((format_datetime(now_fixed, true, fmt), false, None, None));
        }
    }
    if let Some(caps) = NOW_RE.captures(lower) {
        let tz = caps.name("tz").map(|m| m.as_str().trim());
        let fmt = current_time_format(state);
        let dt = now_in_tz(tz, config);
        let rendered = render_datetime_pair(dt, tz.is_none(), fmt);
        return Some((rendered, false, None, None));
    }
    if let Some(caps) = TODAY_RE.captures(lower) {
        let tz = caps.name("tz").map(|m| m.as_str().trim());
        let dt = now_in_tz(tz, config).date_naive();
        let fmt = current_date_format(state);
        return Some((format_date(dt, fmt), false, None, None));
    }
    if let Some(caps) = TOMORROW_RE.captures(lower) {
        let tz = caps.name("tz").map(|m| m.as_str().trim());
        let dt = now_in_tz(tz, config).date_naive() + Duration::days(1);
        let fmt = current_date_format(state);
        return Some((format_date(dt, fmt), false, None, None));
    }
    if let Some(caps) = YESTERDAY_RE.captures(lower) {
        let tz = caps.name("tz").map(|m| m.as_str().trim());
        let dt = now_in_tz(tz, config).date_naive() - Duration::days(1);
        let fmt = current_date_format(state);
        return Some((format_date(dt, fmt), false, None, None));
    }
    if let Some(caps) = WEEKDAY_RE.captures(lower) {
        let direction = caps.get(1).unwrap().as_str();
        let weekday_str = caps.get(2).unwrap().as_str();
        let target = parse_weekday(weekday_str)?;
        let base = now_in_tz(None, config).date_naive();
        let offset = match direction {
            "next" => days_until_weekday(base.weekday(), target, 1),
            "last" => -days_until_weekday(base.weekday(), target, -1),
            "this" => {
                if base.weekday() == target {
                    0
                } else {
                    days_until_weekday(base.weekday(), target, 1)
                }
            }
            _ => 0,
        };
        let result = base + Duration::days(offset as i64);
        let fmt = current_date_format(state);
        return Some((format_date(result, fmt), false, None, None));
    }
    None
}

fn handle_relative(
    lower: &str,
    config: &Config,
    state: &AppState,
) -> Option<(String, bool, Option<f64>, Option<String>)> {
    if let Some(caps) = RELATIVE_RE.captures(lower) {
        let num: i64 = caps["num"].parse().ok()?;
        let unit = caps["unit"].trim();
        let dir = caps["dir"].trim();
        let tz = extract_tz_suffix(lower);
        let signed_num = if dir.contains("ago") || dir.contains("before") {
            -num
        } else {
            num
        };
        let base = if dir.contains("tomorrow") {
            (now_in_tz(tz, config).date_naive() + Duration::days(1)).and_hms_opt(0, 0, 0)?
        } else if dir.contains("today") {
            now_in_tz(tz, config).date_naive().and_hms_opt(0, 0, 0)?
        } else {
            now_in_tz(tz, config).naive_utc()
        };
        let adjusted = apply_offset(base, signed_num, unit)?;
        let fmt = current_time_format(state);
        let output =
            if dir.contains("today") || dir.contains("tomorrow") || dir.contains("before tomorrow")
                || unit.starts_with("day") && !lower.contains("hour")
            {
                let dfmt = current_date_format(state);
                format_date(adjusted.date(), dfmt)
            } else {
                let fixed = utc_to_fixed(adjusted, tz, config);
                render_datetime_pair(fixed, tz.is_none(), fmt)
            };
        return Some((output, false, None, None));
    }
    None
}

fn handle_date_arith(
    lower: &str,
    config: &Config,
    state: &AppState,
) -> Option<(String, bool, Option<f64>, Option<String>)> {
    if let Some(caps) = DATE_ARITH_RE.captures(lower) {
        let date_str = caps.name("date")?.as_str().trim();
        let num: i64 = caps.name("num")?.as_str().parse().ok()?;
        let unit = caps.name("unit")?.as_str().trim();
        let op = caps.name("op")?.as_str();

        let sign = match op {
            "+" | "plus" => 1,
            "-" | "minus" => -1,
            _ => 1,
        };

        if let Some(base) = parse_any_datetime(date_str, config) {
            let naive = base.naive_utc();
            let adjusted = apply_offset(naive, sign * num, unit)?;
            let with_tz = utc_to_fixed(adjusted, None, config);
            let fmt = current_time_format(state);
            if unit.starts_with("day") || unit.starts_with("week") || unit.starts_with("month") || unit.starts_with("year") {
                let dfmt = current_date_format(state);
                return Some((format_date(with_tz.date_naive(), dfmt), false, None, None));
            } else {
                return Some((render_datetime_pair(with_tz, true, fmt), false, None, None));
            }
        }
    }
    None
}

fn now_in_tz(tz_opt: Option<&str>, config: &Config) -> DateTime<FixedOffset> {
    let now_utc = Utc::now().naive_utc();
    utc_to_fixed(now_utc, tz_opt, config)
}

fn resolve_tz(tz_opt: Option<&str>, config: &Config) -> Option<Tz> {
    let candidate = tz_opt
        .filter(|s| !s.is_empty())
        .map(|s| s.to_string())
        .or_else(|| config.default_timezone.clone());
    candidate.and_then(|name| try_parse_tz(&name, config))
}

fn try_parse_tz(name: &str, config: &Config) -> Option<Tz> {
    // Abbreviation map
    let abbr_map = [
        ("utc", "UTC"),
        ("gmt", "UTC"),
        ("est", "America/New_York"),
        ("edt", "America/New_York"),
        ("cst", "America/Chicago"),
        ("cdt", "America/Chicago"),
        ("mst", "America/Denver"),
        ("mdt", "America/Denver"),
        ("pst", "America/Los_Angeles"),
        ("pdt", "America/Los_Angeles"),
        ("bst", "Europe/London"),
        ("cet", "Europe/Paris"),
        ("cest", "Europe/Paris"),
        ("eet", "Europe/Athens"),
        ("eest", "Europe/Athens"),
        ("ist", "Asia/Kolkata"),
        ("jst", "Asia/Tokyo"),
        ("kst", "Asia/Seoul"),
        ("aest", "Australia/Sydney"),
        ("aedt", "Australia/Sydney"),
        ("acst", "Australia/Adelaide"),
        ("acdt", "Australia/Adelaide"),
        ("awst", "Australia/Perth"),
    ];
    let lower = name.to_lowercase();
    if let Some((_, target)) = abbr_map.iter().find(|(abbr, _)| *abbr == lower) {
        if let Ok(tz) = target.parse::<Tz>() {
            return Some(tz);
        }
    }

    if let Some(target) = config.city_aliases.get(&lower) {
        if let Ok(tz) = target.parse::<Tz>() {
            return Some(tz);
        }
    }

    if let Ok(tz) = name.parse::<Tz>() {
        return Some(tz);
    }
    // Title-case each path segment (europe/berlin -> Europe/Berlin)
    let title = name
        .split('/')
        .map(|seg| {
            let mut chars = seg.chars();
            match chars.next() {
                Some(first) => first.to_uppercase().collect::<String>() + chars.as_str(),
                None => String::new(),
            }
        })
        .collect::<Vec<_>>()
        .join("/");
    if let Ok(tz) = title.parse::<Tz>() {
        return Some(tz);
    }
    // Uppercase fallback
    name.to_uppercase().parse::<Tz>().ok()
}

fn parse_any_datetime(input: &str, config: &Config) -> Option<DateTime<FixedOffset>> {
    // try RFC3339/ISO with offset
    if let Ok(dt) = DateTime::parse_from_rfc3339(input) {
        return Some(dt);
    }

    // try known date-time formats without offset
    let formats = [
        "%Y-%m-%d %H:%M:%S",
        "%Y-%m-%d %H:%M",
        "%Y/%m/%d %H:%M",
        "%d %b %Y %H:%M",
        "%Y-%m-%d",
        "%Y/%m/%d",
        "%d %b %Y",
        "%d %B %Y",
    ];

    for fmt in &formats {
        if let Ok(dt) = NaiveDateTime::parse_from_str(input, fmt) {
            return Some(utc_to_fixed(dt, None, config));
        }
        if let Ok(date) = NaiveDate::parse_from_str(input, fmt) {
            let dt = date.and_hms_opt(0, 0, 0)?;
            return Some(utc_to_fixed(dt, None, config));
        }
    }
    None
}

fn apply_offset(base: NaiveDateTime, num: i64, unit: &str) -> Option<NaiveDateTime> {
    match unit {
        u if u.starts_with("second") => Some(base + Duration::seconds(num)),
        u if u.starts_with("minute") => Some(base + Duration::minutes(num)),
        u if u.starts_with("hour") => Some(base + Duration::hours(num)),
        u if u.starts_with("day") => Some(base + Duration::days(num)),
        u if u.starts_with("week") => Some(base + Duration::weeks(num)),
        u if u.starts_with("month") => {
            if num >= 0 {
                Some(base + Months::new(num as u32))
            } else {
                Some(base - Months::new((-num) as u32))
            }
        }
        u if u.starts_with("year") => {
            let months = 12 * num.abs() as u32;
            if num >= 0 {
                Some(base + Months::new(months))
            } else {
                Some(base - Months::new(months))
            }
        }
        _ => None,
    }
}

fn format_date(date: NaiveDate, fmt_key: &str) -> String {
    match fmt_key {
        "iso" => date.format("%Y-%m-%d").to_string(),
        "long" => date.format("%A, %Y-%m-%d").to_string(),
        "short" => date.format("%m/%d/%y").to_string(),
        _ => date.format("%Y-%m-%d").to_string(),
    }
}

fn current_time_format(state: &AppState) -> &str {
    state.time_format.as_str()
}

fn current_date_format(state: &AppState) -> &str {
    state.date_format.as_str()
}

fn format_datetime(dt: DateTime<FixedOffset>, include_time: bool, fmt_key: &str) -> String {
    match fmt_key {
        "iso" => {
            if include_time {
                dt.format("%Y-%m-%d %H:%M %:z").to_string()
            } else {
                dt.format("%Y-%m-%d").to_string()
            }
        }
        "long" => {
            if include_time {
                dt.format("%A, %Y-%m-%d %H:%M %:z").to_string()
            } else {
                dt.format("%A, %Y-%m-%d").to_string()
            }
        }
        "short" => {
            if include_time {
                dt.format("%m/%d %H:%M %Z").to_string()
            } else {
                dt.format("%m/%d/%y").to_string()
            }
        }
        "time" => dt.format("%H:%M %:z").to_string(),
        "12h" => dt.format("%Y-%m-%d %I:%M %p %:z").to_string(),
        _ => {
            if include_time {
                dt.format("%Y-%m-%d %H:%M %:z").to_string()
            } else {
                dt.format("%Y-%m-%d").to_string()
            }
        }
    }
}

/// Render a human-friendly string. When show_utc is true, include both local and UTC lines.
fn render_datetime_pair(dt: DateTime<FixedOffset>, show_utc: bool, fmt_key: &str) -> String {
    if show_utc {
        let utc = dt.with_timezone(&Utc.fix());
        format!(
            "Local {}\nUTC   {}",
            format_datetime(dt, true, fmt_key),
            format_datetime(utc, true, fmt_key)
        )
    } else {
        format_datetime(dt, true, fmt_key)
    }
}

fn parse_weekday(input: &str) -> Option<Weekday> {
    match input {
        "monday" => Some(Weekday::Mon),
        "tuesday" => Some(Weekday::Tue),
        "wednesday" => Some(Weekday::Wed),
        "thursday" => Some(Weekday::Thu),
        "friday" => Some(Weekday::Fri),
        "saturday" => Some(Weekday::Sat),
        "sunday" => Some(Weekday::Sun),
        _ => None,
    }
}

fn days_until_weekday(current: Weekday, target: Weekday, direction: i32) -> i64 {
    let current_num = current.num_days_from_monday() as i32;
    let target_num = target.num_days_from_monday() as i32;
    let mut delta = target_num - current_num;
    if direction > 0 && delta <= 0 {
        delta += 7;
    } else if direction < 0 && delta >= 0 {
        delta -= 7;
    }
    delta as i64
}

fn extract_tz_suffix(input: &str) -> Option<&str> {
    if let Some(pos) = input.rfind(" in ") {
        return Some(input[pos + 4..].trim());
    }
    if let Some(pos) = input.rfind(" to ") {
        return Some(input[pos + 4..].trim());
    }
    None
}

fn now_offset_seconds(tz_opt: Option<&str>, config: &Config) -> i32 {
    if let Some(tz) = resolve_tz(tz_opt, config) {
        tz.offset_from_utc_datetime(&Utc::now().naive_utc())
            .fix()
            .local_minus_utc()
    } else {
        Local::now().offset().local_minus_utc()
    }
}

fn utc_to_fixed(naive: NaiveDateTime, tz_opt: Option<&str>, config: &Config) -> DateTime<FixedOffset> {
    if let Some(tz) = resolve_tz(tz_opt, config) {
        fixed_from_tz(&tz, naive)
    } else {
        let offset = FixedOffset::east_opt(now_offset_seconds(None, config))
            .unwrap_or_else(|| FixedOffset::east_opt(0).unwrap());
        DateTime::<Utc>::from_naive_utc_and_offset(naive, Utc).with_timezone(&offset)
    }
}

fn fixed_from_tz(tz: &Tz, naive: NaiveDateTime) -> DateTime<FixedOffset> {
    let offset = tz
        .offset_from_utc_datetime(&naive)
        .fix();
    DateTime::<Utc>::from_naive_utc_and_offset(naive, Utc).with_timezone(&offset)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::models::AppState;

    #[test]
    fn test_days_between() {
        let cfg = Config::default();
        let agent = DateTimeAgent;
        let res = agent.process("days between 2025-01-01 and 2025-01-31", &mut AppState::builder(&cfg).build(), &cfg);
        assert!(res.is_some());
        let (out, add_hist, raw, unit) = res.unwrap();
        assert!(out.contains("30"));
        assert!(!add_hist);
        assert!(unit.is_none());
        assert!(raw.is_none());
    }

    #[test]
    fn test_next_monday() {
        let cfg = Config::default();
        let agent = DateTimeAgent;
        let res = agent.process("next monday", &mut AppState::builder(&cfg).build(), &cfg);
        assert!(res.is_some());
        let (out, _, _, _) = res.unwrap();
        assert!(out.contains("-"));
    }

    #[test]
    fn test_now_includes_local_and_utc() {
        let cfg = Config::default();
        let agent = DateTimeAgent;
        let res = agent.process("now", &mut AppState::builder(&cfg).build(), &cfg);
        let (out, _, _, _) = res.expect("should parse now");
        assert!(out.contains("Local "));
        assert!(out.contains("UTC"));
    }

    #[test]
    fn test_now_in_utc_single_line() {
        let cfg = Config::default();
        let agent = DateTimeAgent;
        let res = agent.process("now in utc", &mut AppState::builder(&cfg).build(), &cfg);
        let (out, _, _, _) = res.expect("should parse now in utc");
        assert!(!out.contains("Local "));
        assert!(out.ends_with("+00:00") || out.ends_with("Z")); // chrono prints +00:00
    }

    #[test]
    fn test_relative_days_from_today() {
        use chrono::NaiveDate;
        let cfg = Config::default();
        let agent = DateTimeAgent;
        let res = agent.process("5 days from today", &mut AppState::builder(&cfg).build(), &cfg);
        let (out, _, _, _) = res.expect("should parse relative days");
        let parsed = NaiveDate::parse_from_str(&out, "%Y-%m-%d").expect("formatted date");
        let expected = chrono::Local::now().date_naive() + chrono::Duration::days(5);
        assert_eq!(parsed, expected);
    }

    #[test]
    fn test_date_arith_month_rollover() {
        use chrono::NaiveDate;
        let cfg = Config::default();
        let agent = DateTimeAgent;
        let res = agent.process("2024-01-31 + 1 month", &mut AppState::builder(&cfg).build(), &cfg);
        let (out, _, _, _) = res.expect("should parse month add");
        let parsed = NaiveDate::parse_from_str(&out, "%Y-%m-%d").expect("formatted date");
        assert_eq!(parsed, NaiveDate::from_ymd_opt(2024, 2, 29).unwrap());
    }

    #[test]
    fn test_hours_from_now_in_utc() {
        let cfg = Config::default();
        let agent = DateTimeAgent;
        let res =
            agent.process("3 hours from now in UTC", &mut AppState::builder(&cfg).build(), &cfg);
        let (out, _, _, _) = res.expect("should parse hours from now");
        assert!(out.ends_with("+00:00") || out.ends_with("Z"));
    }

    #[test]
    fn test_time_in_tokyo() {
        let cfg = Config::default();
        let agent = DateTimeAgent;
        let res =
            agent.process("time in Tokyo", &mut AppState::builder(&cfg).build(), &cfg);
        let (out, _, _, _) = res.expect("time in tokyo should work");
        assert!(!out.contains("Local "));
        // offset should match Asia/Tokyo
        let parsed = chrono::DateTime::parse_from_str(&out, "%Y-%m-%d %H:%M %:z").unwrap();
        let expected_offset = chrono_tz::Asia::Tokyo
            .offset_from_utc_datetime(&Utc::now().naive_utc())
            .fix()
            .local_minus_utc();
        assert_eq!(parsed.offset().local_minus_utc(), expected_offset);
    }

    #[test]
    fn test_from_tomorrow_relative() {
        let cfg = Config::default();
        let agent = DateTimeAgent;
        let res =
            agent.process("5 weeks from tomorrow", &mut AppState::builder(&cfg).build(), &cfg);
        let (out, _, _, _) = res.expect("should parse from tomorrow");
        // Output could be date or datetime; check contains tomorrow+5weeks date
        let expected_date = chrono::Local::now().date_naive() + chrono::Duration::days(1) + chrono::Duration::weeks(5);
        assert!(out.contains(&expected_date.format("%Y-%m-%d").to_string()));
    }

    #[test]
    fn test_weeks_ago_is_past() {
        use chrono::NaiveDateTime;
        let cfg = Config::default();
        let agent = DateTimeAgent;
        let res = agent.process("5 weeks ago", &mut AppState::builder(&cfg).build(), &cfg);
        let (out, _, _, _) = res.expect("should parse weeks ago");
        let lines: Vec<&str> = out.lines().collect();
        let out_copy = out.clone();
        let first_line = lines.get(0).copied().unwrap_or_else(|| out_copy.as_str());
        // Extract datetime from "Local: 2025-10-19 12:00 +00:00" or single line
        let dt_str = first_line.trim().trim_start_matches("Local ").trim();
        let parsed =
            chrono::DateTime::parse_from_str(dt_str, "%Y-%m-%d %H:%M %z").unwrap_or_else(|_| {
                let nd = NaiveDateTime::parse_from_str(dt_str, "%Y-%m-%d %H:%M").unwrap();
                chrono::DateTime::<Utc>::from_naive_utc_and_offset(nd, Utc).with_timezone(&Utc.fix())
            });
        assert!(parsed < Utc::now(), "weeks ago should be in the past");
    }

    #[test]
    fn test_now_in_europe_berlin() {
        let cfg = Config::default();
        let agent = DateTimeAgent;
        let res =
            agent.process("now in Europe/Berlin", &mut AppState::builder(&cfg).build(), &cfg);
        let (out, _, _, _) = res.expect("should parse tz with slash and casing");
        assert!(!out.contains("Local:"));
        // Should parse back and match offset sign
        let parsed = chrono::DateTime::parse_from_str(&out, "%Y-%m-%d %H:%M %:z")
            .expect("parse berlin output");
        let expected_offset = chrono_tz::Europe::Berlin
            .offset_from_utc_datetime(&Utc::now().naive_utc())
            .fix()
            .local_minus_utc();
        assert_eq!(parsed.offset().local_minus_utc(), expected_offset);
    }

    #[test]
    fn test_now_to_utc_alias() {
        let cfg = Config::default();
        let agent = DateTimeAgent;
        let res = agent.process("now to utc", &mut AppState::builder(&cfg).build(), &cfg);
        let (out, _, _, _) = res.expect("now to utc should work");
        assert!(out.ends_with("+00:00") || out.ends_with("Z"));
    }
}
