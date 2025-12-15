//! Currency exchange rate fetching from external APIs.
//!
//! This module fetches live currency exchange rates from free APIs
//! and checks for stale rates.

use anyhow::{Context, Result};
use crate::fl;
use serde::Deserialize;
use std::collections::HashMap;
use std::sync::Mutex;
use std::time::{Duration, Instant};

/// Rate limiter to prevent API spam
static LAST_REQUEST: Mutex<Option<Instant>> = Mutex::new(None);
const MIN_REQUEST_INTERVAL: Duration = Duration::from_secs(60);

/// Response format from fawazahmed0/currency-api.
#[derive(Debug, Deserialize)]
struct CurrencyApiResponse {
    date: String,
    usd: HashMap<String, f64>,
}

/// Primary and fallback URLs for currency API
const PRIMARY_URL: &str =
    "https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/usd.min.json";
const FALLBACK_URL: &str = "https://latest.currency-api.pages.dev/v1/currencies/usd.min.json";

/// Timeout for HTTP requests (5 seconds)
const REQUEST_TIMEOUT: Duration = Duration::from_secs(5);

/// Fetch latest currency exchange rates from the API.
///
/// Uses USD as base currency. Returns rates where 1 USD = X units of target currency.
/// Tries primary URL first, falls back to secondary if primary fails.
///
/// # Returns
///
/// Returns a tuple of (rates_map, date_string) on success.
///
/// # Errors
///
/// Returns error if both primary and fallback URLs fail.
///
/// # Examples
///
/// ```no_run
/// use numby::currency_fetcher::fetch_latest_rates;
///
/// let result = fetch_latest_rates();
/// match result {
///     Ok((rates, date)) => {
///         println!("Fetched rates from {}", date);
///         assert!(rates.contains_key("EUR"));
///         assert!(rates.contains_key("GBP"));
///     }
///     Err(e) => eprintln!("Failed to fetch rates: {}", e),
/// }
/// ```
pub fn fetch_latest_rates() -> Result<(HashMap<String, f64>, String)> {
    // Rate limiting check
    {
        let mut last_req = LAST_REQUEST.lock().unwrap();
        if let Some(last_time) = *last_req {
            let elapsed = last_time.elapsed();
            if elapsed < MIN_REQUEST_INTERVAL {
                anyhow::bail!(
                    "{}",
                    fl!(
                        "currency-rate-limit",
                        "seconds" => &(MIN_REQUEST_INTERVAL - elapsed).as_secs().to_string()
                    )
                );
            }
        }
        *last_req = Some(Instant::now());
    }

    // Try primary URL first
    match fetch_from_url(PRIMARY_URL) {
        Ok(result) => return Ok(result),
        Err(e) => {
            eprintln!(
                "{}",
                crate::fl!("currency-primary-fallback", "error" => &e.to_string())
            );
        }
    }

    // Fallback to secondary URL
    fetch_from_url(FALLBACK_URL).context("Both primary and fallback URLs failed")
}

/// Fetches rates from a specific URL
fn fetch_from_url(url: &str) -> Result<(HashMap<String, f64>, String)> {
    let response = ureq::get(url)
        .timeout(REQUEST_TIMEOUT)
        .call()
        .map_err(|e| {
            anyhow::anyhow!(fl!(
                "currency-http-request-failed",
                "error" => &e.to_string()
            ))
        })?;

    if response.status() != 200 {
        anyhow::bail!(fl!(
            "currency-http-status",
            "status" => &response.status().to_string()
        ));
    }

    let api_response: CurrencyApiResponse = response
        .into_json()
        .context(fl!("currency-parse-json"))?;

    // Convert to uppercase keys and invert rates (API gives USD->X, we store as rate to convert TO USD)
    let mut rates: HashMap<String, f64> = HashMap::new();

    // USD is always 1.0 (base currency)
    rates.insert("USD".to_string(), 1.0);

    for (currency_code, rate) in api_response.usd {
        let upper_code = currency_code.to_uppercase();
        // API gives us "1 USD = X target_currency"
        // We store it as-is for our conversion formula
        rates.insert(upper_code, rate);
    }

    Ok((rates, api_response.date))
}

/// Check if currency rates are stale (older than 24 hours).
///
/// Compares the stored date (YYYY-MM-DD) with today's date.
/// Returns true if the rates are from yesterday or earlier.
///
/// # Arguments
///
/// * `stored_date` - ISO date string in YYYY-MM-DD format
///
/// # Examples
///
/// ```
/// use numby::currency_fetcher::are_rates_stale;
///
/// // Old date is stale
/// assert!(are_rates_stale("2020-01-01"));
///
/// // Future date is not stale
/// assert!(!are_rates_stale("2030-12-31"));
///
/// // Invalid date is considered stale
/// assert!(are_rates_stale("invalid-date"));
/// ```
pub fn are_rates_stale(stored_date: &str) -> bool {
    use std::time::{SystemTime, UNIX_EPOCH};

    // Get today's date in YYYY-MM-DD format
    let now = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap()
        .as_secs();

    let seconds_per_day = 86400;
    let today_days = now / seconds_per_day;

    // Parse stored date (YYYY-MM-DD format)
    let stored_days = match parse_date_to_days(stored_date) {
        Some(days) => days,
        None => return true, // If we can't parse, consider it stale
    };

    // Handle API date errors - allow up to 7 days difference in either direction
    let tolerance_days = 7;
    let day_difference = if today_days > stored_days {
        today_days - stored_days
    } else {
        stored_days - today_days
    };

    // Consider stale only if more than tolerance_days behind
    day_difference > tolerance_days as u64
}

/// Converts YYYY-MM-DD format to days since Unix epoch
fn parse_date_to_days(date_str: &str) -> Option<u64> {
    let parts: Vec<&str> = date_str.split('-').collect();
    if parts.len() != 3 {
        return None;
    }

    let year: i32 = parts[0].parse().ok()?;
    let month: u32 = parts[1].parse().ok()?;
    let day: u32 = parts[2].parse().ok()?;

    if !(1..=12).contains(&month) || !(1..=31).contains(&day) {
        return None;
    }

    // Calculate days since Unix epoch (Jan 1, 1970)
    let mut days = 0u64;

    // Add days for complete years
    for y in 1970..year {
        days += if is_leap_year(y) { 366 } else { 365 };
    }

    // Add days for complete months in the current year
    let is_leap = is_leap_year(year);
    days += days_in_months_before(month, is_leap) as u64;

    // Add remaining days
    days += day as u64;

    Some(days)
}

/// Check if a year is a leap year
fn is_leap_year(year: i32) -> bool {
    (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
}

/// Helper to count days in months before the given month
fn days_in_months_before(month: u32, is_leap: bool) -> u32 {
    let days_non_leap = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
    let days_leap = [0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335];

    if month > 0 && month <= 12 {
        if is_leap {
            days_leap[(month - 1) as usize]
        } else {
            days_non_leap[(month - 1) as usize]
        }
    } else {
        0
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_staleness_check() {
        // A date from yesterday should be stale
        assert!(are_rates_stale("2020-01-01"));

        // A date from far future should not be stale
        assert!(!are_rates_stale("2030-12-31"));
    }

    #[test]
    fn test_date_parsing() {
        let days = parse_date_to_days("2025-01-01");
        assert!(days.is_some());
        assert!(days.unwrap() > 0);
    }

    #[test]
    fn test_invalid_date_is_stale() {
        assert!(are_rates_stale("invalid-date"));
        assert!(are_rates_stale(""));
    }
}
