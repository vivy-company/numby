// Integration test for live currency API
// Run with: cargo test --test currency_api_integration -- --ignored

use numby::currency_fetcher;

#[test]
#[ignore] // Ignored by default, run explicitly with --ignored flag
fn test_live_api_fetch() {
    // This test actually calls the live API
    match currency_fetcher::fetch_latest_rates() {
        Ok((rates, date)) => {
            println!("Successfully fetched {} rates dated {}", rates.len(), date);

            // Verify we got a reasonable number of currencies
            assert!(rates.len() > 300, "Expected 300+ currencies, got {}", rates.len());

            // Verify USD exists as base currency
            assert_eq!(rates.get("USD"), Some(&1.0), "USD should be 1.0 (base currency)");

            // Verify some common currencies exist
            assert!(rates.contains_key("EUR"), "EUR should be present");
            assert!(rates.contains_key("GBP"), "GBP should be present");
            assert!(rates.contains_key("JPY"), "JPY should be present");
            assert!(rates.contains_key("BTC"), "BTC should be present");

            // Verify rates are reasonable (not zero or negative)
            for (currency, rate) in rates.iter() {
                assert!(*rate > 0.0, "{} rate should be positive, got {}", currency, rate);
            }

            // Verify date format is YYYY-MM-DD
            let date_parts: Vec<&str> = date.split('-').collect();
            assert_eq!(date_parts.len(), 3, "Date should be YYYY-MM-DD format");
            assert_eq!(date_parts[0].len(), 4, "Year should be 4 digits");
            assert_eq!(date_parts[1].len(), 2, "Month should be 2 digits");
            assert_eq!(date_parts[2].len(), 2, "Day should be 2 digits");
        }
        Err(e) => {
            panic!("Failed to fetch rates from live API: {}", e);
        }
    }
}

#[test]
#[ignore]
fn test_staleness_detection() {
    // Test with yesterday's date - should be stale
    let yesterday = "2020-01-01";
    assert!(currency_fetcher::are_rates_stale(yesterday), "Old date should be stale");

    // Test with future date - should not be stale
    let future = "2030-12-31";
    assert!(!currency_fetcher::are_rates_stale(future), "Future date should not be stale");
}

#[test]
#[ignore]
fn test_api_response_structure() {
    // Verify the API returns data in the expected format
    match currency_fetcher::fetch_latest_rates() {
        Ok((rates, _date)) => {
            // Test a few expected currency conversions make sense
            let usd = rates.get("USD").unwrap();
            let eur = rates.get("EUR").unwrap();
            let jpy = rates.get("JPY").unwrap();

            // EUR should be less than 1 USD (typically 0.8-0.95)
            assert!(*eur < *usd, "EUR should be less than USD");
            assert!(*eur > 0.5, "EUR should be reasonable (> 0.5 USD)");
            assert!(*eur < 1.2, "EUR should be reasonable (< 1.2 USD)");

            // JPY should be much more than 1 USD (typically 100-160)
            assert!(*jpy > *usd, "JPY should be more than USD");
            assert!(*jpy > 80.0, "JPY should be reasonable (> 80)");
            assert!(*jpy < 200.0, "JPY should be reasonable (< 200)");
        }
        Err(e) => {
            panic!("Failed to fetch rates: {}", e);
        }
    }
}
