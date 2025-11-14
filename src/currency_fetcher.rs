use anyhow::{Context, Result};
use serde::Deserialize;
use std::collections::HashMap;
use std::time::Duration;

/// Response format from fawazahmed0/currency-api
#[derive(Debug, Deserialize)]
struct CurrencyApiResponse {
    date: String,
    usd: HashMap<String, f64>,
}

/// Primary and fallback URLs for currency API
const PRIMARY_URL: &str =
    "https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/usd.min.json";
const FALLBACK_URL: &str =
    "https://latest.currency-api.pages.dev/v1/currencies/usd.min.json";

/// Timeout for HTTP requests (5 seconds)
const REQUEST_TIMEOUT: Duration = Duration::from_secs(5);

/// Fetches latest currency exchange rates from the API
///
/// Uses USD as base currency. Returns rates where 1 USD = X units of target currency.
/// Tries primary URL first, falls back to secondary if primary fails.
pub fn fetch_latest_rates() -> Result<(HashMap<String, f64>, String)> {
    // Try primary URL first
    match fetch_from_url(PRIMARY_URL) {
        Ok(result) => return Ok(result),
        Err(e) => {
            eprintln!("Primary URL failed: {}, trying fallback...", e);
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
        .map_err(|e| anyhow::anyhow!("HTTP request failed: {}", e))?;

    if response.status() != 200 {
        anyhow::bail!("HTTP request returned status: {}", response.status());
    }

    let api_response: CurrencyApiResponse = response
        .into_json()
        .context("Failed to parse JSON response")?;

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

/// Checks if rates are stale (older than 24 hours from today)
///
/// Compares the stored date (YYYY-MM-DD) with today's date.
/// Returns true if the rates are from yesterday or earlier.
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

    // Stale if stored date is from yesterday or earlier
    today_days > stored_days
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

    // Approximate days since Unix epoch (Jan 1, 1970)
    // This is a simple approximation, good enough for staleness checks
    let days_since_epoch = ((year - 1970) * 365) as u64
        + ((year - 1970) / 4) as u64 // Leap years approximation
        + days_in_months_before(month) as u64
        + day as u64;

    Some(days_since_epoch)
}

/// Helper to count days in months before the given month
fn days_in_months_before(month: u32) -> u32 {
    let days = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
    if month > 0 && month <= 12 {
        days[(month - 1) as usize]
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
