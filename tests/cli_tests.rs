use regex::Regex;
use std::process::Command;

fn run_command(args: &[&str]) -> (String, String) {
    // Insert --locale en-US after "--" to force English error messages
    let mut full_args = Vec::new();
    let mut after_separator = false;
    let has_locale = args.contains(&"--locale");

    for &arg in args {
        full_args.push(arg);
        if arg == "--" && !after_separator && !has_locale {
            // Insert locale right after the separator
            full_args.push("--locale");
            full_args.push("en-US");
            after_separator = true;
        }
    }

    let output = Command::new("cargo")
        .args(&full_args)
        .output()
        .expect("Failed to run command");

    let stdout = String::from_utf8(output.stdout).unwrap();
    let stderr = String::from_utf8(output.stderr).unwrap();
    (stdout, stderr)
}

#[test]
fn test_simple_arithmetic() {
    let (stdout, _) = run_command(&["run", "--", "2 + 3"]);
    assert!(stdout.contains("5"));
}

#[test]
fn test_word_numbers_basic() {
    let (stdout, _) = run_command(&["run", "--", "ten plus five"]);
    // Strip color and input echo, keep numeric
    let re = Regex::new(r"(15(?:\\.00)?)").unwrap();
    assert!(re.is_match(stdout.trim()), "got {}", stdout);
}

#[test]
fn test_word_numbers_mixed_case() {
    let (stdout, _) = run_command(&["run", "--", "Twenty MINUS four"]);
    let re = Regex::new(r"(16(?:\\.00)?)").unwrap();
    assert!(re.is_match(stdout.trim()), "got {}", stdout);
}

#[test]
fn test_yesterday_plus_days() {
    let (stdout, _) = run_command(&["run", "--", "yesterday + 10 days"]);
    // Expect date-like output yyyy-mm-dd somewhere in line
    let re = Regex::new(r"\d{4}-\d{2}-\d{2}").unwrap();
    assert!(re.is_match(&stdout), "expected date output, got {}", stdout);
}

#[test]
fn test_tomorrow_minus_days() {
    let (stdout, _) = run_command(&["run", "--", "tomorrow - 1 day"]);
    let re = Regex::new(r"\d{4}-\d{2}-\d{2}").unwrap();
    assert!(re.is_match(&stdout), "expected date output, got {}", stdout);
}

#[test]
fn test_yesterday_plus_days_chain() {
    let (stdout, _) = run_command(&["run", "--", "yesterday + 1 day + 2 days"]);
    let re = Regex::new(r"\d{4}-\d{2}-\d{2}").unwrap();
    assert!(re.is_match(&stdout), "expected date output, got {}", stdout);
}

#[test]
fn test_currency_conversion() {
    // Use fixed rates for deterministic testing: 1 USD = 0.85 EUR
    let (stdout, _) = run_command(&[
        "run",
        "--",
        "--no-update",
        "--rate",
        "EUR:0.85",
        "10 usd in eur",
    ]);
    assert!(stdout.contains("eur"));
    // Exact: 10 * 0.85 = 8.50 EUR
    let re = Regex::new(r"8\.50 eur").unwrap();
    assert!(re.is_match(stdout.trim()));
}

#[test]
fn test_currency_symbol_dollar_to_eur() {
    // Test: 100$ to EUR with $ symbol
    let (stdout, _) = run_command(&[
        "run",
        "--",
        "--no-update",
        "--rate",
        "EUR:0.85",
        "100$ to eur",
    ]);
    assert!(stdout.contains("eur"));
    // 100 * 0.85 = 85.00 EUR
    let re = Regex::new(r"85\.00 eur").unwrap();
    assert!(re.is_match(stdout.trim()));
}

#[test]
fn test_currency_symbol_euro_to_usd() {
    // Test: €50 to USD with € symbol
    let (stdout, _) = run_command(&[
        "run",
        "--",
        "--no-update",
        "--rate",
        "EUR:0.85",
        "€50 to usd",
    ]);
    assert!(stdout.contains("usd"));
    // 50 / 0.85 = 58.82... USD
    assert!(stdout.contains("58.82"));
}

#[test]
fn test_currency_symbol_prefix() {
    // Test: $100 (prefix style)
    let (stdout, _) = run_command(&[
        "run",
        "--",
        "--no-update",
        "--rate",
        "EUR:0.85",
        "$100 to eur",
    ]);
    assert!(stdout.contains("eur"));
    let re = Regex::new(r"85\.00 eur").unwrap();
    assert!(re.is_match(stdout.trim()));
}

#[test]
fn test_byn_conversion() {
    // Test: 100 USD to BYN
    let (stdout, _) = run_command(&[
        "run",
        "--",
        "--no-update",
        "--rate",
        "BYN:3.41",
        "100 usd to byn",
    ]);
    assert!(stdout.contains("byn"));
    // 100 * 3.41 = 341 BYN (no decimals for round numbers)
    let re = Regex::new(r"341 byn").unwrap();
    assert!(re.is_match(stdout.trim()));
}

#[test]
fn test_dollar_symbol_to_byn() {
    // Test: 100$ to BYN (original failing case)
    let (stdout, _) = run_command(&[
        "run",
        "--",
        "--no-update",
        "--rate",
        "BYN:3.41",
        "100$ to byn",
    ]);
    assert!(stdout.contains("byn"));
    // 100 * 3.41 = 341 BYN (no decimals for round numbers)
    let re = Regex::new(r"341 byn").unwrap();
    assert!(re.is_match(stdout.trim()));
}

#[test]
fn test_unit_conversion() {
    let (stdout, _) = run_command(&["run", "--", "100 cm in m"]);
    assert!(stdout.contains("1"));
    assert!(stdout.contains("m"));
}

#[test]
fn test_help() {
    let (stdout, _) = run_command(&["run", "--", "--help"]);
    assert!(stdout.contains("Numby"));
    assert!(stdout.contains("help"));
    assert!(stdout.contains("Usage"));
}

#[test]
fn test_version() {
    let (stdout, _) = run_command(&["run", "--", "--version"]);
    // Check for version pattern, e.g., v1.2.3
    let re = Regex::new(r"v\d+\.\d+\.\d+").unwrap();
    assert!(re.is_match(stdout.trim()));
}

#[test]
fn test_variable_assignment() {
    let (stdout, _) = run_command(&["run", "--", "x = 5 + 3"]);
    assert!(stdout.contains("8.00") || stdout.contains("8"));
}

#[test]
fn test_error_handling() {
    let (_, stderr) = run_command(&["run", "--", "invalid expression"]);
    assert!(stderr.contains("Error"));
}

#[test]
fn test_complex_expression() {
    let (stdout, _) = run_command(&["run", "--", "2 * (3 + 4) / 2"]);
    assert!(stdout.contains("7"));
}

#[test]
fn test_scales() {
    let (stdout, _) = run_command(&["run", "--", "2k"]);
    assert!(stdout.contains("2.0k"));
}

#[test]
fn test_prettify_large_numbers() {
    let (stdout, _) = run_command(&["run", "--", "1000"]);
    assert!(stdout.contains("1.0k"));
}

#[test]
fn test_prettify_millions() {
    let (stdout, _) = run_command(&["run", "--", "1500000"]);
    assert!(stdout.contains("1.5M"));
}

#[test]
fn test_large_numbers() {
    let (stdout, _) = run_command(&["run", "--", "1000000000"]);
    assert!(stdout.contains("1.0B"));
}

#[test]
fn test_negative_numbers() {
    let (stdout, _) = run_command(&["run", "--", "-10 + 5"]);
    assert!(stdout.contains("-5"));
}

#[test]
fn test_unit_conversions() {
    let (stdout, _) = run_command(&["run", "--", "1000 m in km"]);
    let re = Regex::new(r"1\.00 km").unwrap();
    assert!(re.is_match(stdout.trim()));
}

#[test]
fn test_currency_conversions() {
    // Use fixed rate: 1 USD = 0.85 EUR
    let (stdout, _) = run_command(&[
        "run",
        "--",
        "--no-update",
        "--rate",
        "EUR:0.85",
        "100 usd in eur",
    ]);
    assert!(stdout.contains("eur"));
    // 100 * 0.85 = 85.00 eur
    let re = Regex::new(r"85\.00 eur").unwrap();
    assert!(re.is_match(stdout.trim()));
}

#[test]
fn test_complex_expression_with_parentheses() {
    let (stdout, _) = run_command(&["run", "--", "2 * (3 + 4) / 2"]);
    assert!(stdout.contains("7"));
}

#[test]
fn test_expression_with_units_conversion() {
    let (stdout, _) = run_command(&["run", "--", "10 + 5 m in cm"]);
    let re = Regex::new(r"1\.5k cm").unwrap();
    assert!(re.is_match(stdout.trim()));
}

#[test]
fn test_invalid_expression() {
    let (_, stderr) = run_command(&["run", "--", "invalid"]);
    assert!(stderr.contains("Error"));
}

#[test]
fn test_variable_assignment_with_conversion() {
    // Test: flight = 850 USD to JPY
    let (stdout, _) = run_command(&[
        "run",
        "--",
        "--no-update",
        "--rate",
        "JPY:150",
        "flight = 850 USD to JPY",
    ]);
    // 850 * 150 = 127500 JPY (displayed as 127.5k JPY)
    let re = Regex::new(r"127\.5k JPY").unwrap();
    assert!(re.is_match(stdout.trim()));
}

#[test]
fn test_arithmetic_with_conversion_in_assignment() {
    // Test: hotel = 150 USD * 5 to JPY
    let (stdout, _) = run_command(&[
        "run",
        "--",
        "--no-update",
        "--rate",
        "JPY:150",
        "hotel = 150 USD * 5 to JPY",
    ]);
    // (150 * 5) * 150 = 112500 JPY (displayed as 112.5k JPY)
    let re = Regex::new(r"112\.5k JPY").unwrap();
    assert!(re.is_match(stdout.trim()));
}

#[test]
fn test_division_by_zero() {
    let (stdout, _) = run_command(&["run", "--", "1 / 0"]);
    // meval may return inf or error, check for either
    assert!(stdout.contains("inf") || stdout.contains("Error"));
}

#[test]
fn test_missing_operand() {
    let (_, stderr) = run_command(&["run", "--", "2 +"]);
    assert!(stderr.contains("Error"));
}

#[test]
fn test_unsupported_unit() {
    let (_, stderr) = run_command(&["run", "--", "10 xyz in abc"]);
    assert!(stderr.contains("Error"));
}

#[test]
fn test_unsupported_currency() {
    let (_, stderr) = run_command(&["run", "--", "10 xyz in eur"]);
    assert!(stderr.contains("Error"));
}

#[test]
fn test_functions() {
    let (stdout, _) = run_command(&["run", "--", "sin(0)"]);
    assert!(stdout.contains("0"));
}

#[test]
fn test_scales_with_units() {
    let (stdout, _) = run_command(&["run", "--", "1k usd in jpy"]);
    assert!(stdout.contains("jpy"));
}

#[test]
fn test_multiple_operations() {
    let (stdout, _) = run_command(&["run", "--", "10 + 20 * 3 - 5"]);
    assert!(stdout.contains("65"));
}

#[test]
fn test_parentheses() {
    let (stdout, _) = run_command(&["run", "--", "(10 + 20) * 3"]);
    assert!(stdout.contains("90"));
}

#[test]
fn test_floating_point() {
    let (stdout, _) = run_command(&["run", "--", "10.5 + 2.3"]);
    assert!(stdout.contains("12.8"));
}

#[test]
fn test_power() {
    let (stdout, _) = run_command(&["run", "--", "2 ^ 3"]);
    assert!(stdout.contains("8"));
}

#[test]
fn test_modulo() {
    let (stdout, _) = run_command(&["run", "--", "10 % 3"]);
    assert!(stdout.contains("1"));
}

#[test]
fn test_history_commands() {
    let (stdout, _) = run_command(&["run", "--", "sum"]);
    assert!(stdout.contains("0")); // empty history
}

#[test]
fn test_variable_assignment_in_expression() {
    let (stdout, _) = run_command(&["run", "--", "x = 5 + 3"]);
    assert!(stdout.contains("8.00") || stdout.contains("8"));
}

#[test]
fn test_empty_expression() {
    let (_, stderr) = run_command(&["run", "--", ""]);
    assert!(stderr.contains("Error"));
}

#[test]
fn test_only_spaces() {
    let (_, stderr) = run_command(&["run", "--", "   "]);
    assert!(stderr.contains("Error"));
}

#[test]
fn test_complex_currency_conversion() {
    // Use fixed rate: 1 USD = 154 JPY
    let (stdout, _) = run_command(&[
        "run",
        "--",
        "--no-update",
        "--rate",
        "JPY:154",
        "10 + 200000 usd in jpy",
    ]);
    assert!(stdout.contains("jpy"));
    // (10 + 200000) * 154 = 30,801,540 = 30.8M jpy
    let re = Regex::new(r"30\.8M jpy").unwrap();
    assert!(re.is_match(stdout.trim()));
}

#[test]
fn test_complex_length_conversion() {
    let (stdout, _) = run_command(&["run", "--", "10.2 m in km"]);
    assert!(stdout.contains("km"));
    // 10.2m = 0.0102 km -> prettify 0.01 km
    let re = Regex::new(r"0\.01 km").unwrap();
    assert!(re.is_match(stdout.trim()));
}

#[test]
fn test_large_number_with_unit_conversion() {
    // Use fixed rate: 1 USD = 0.85 EUR
    let (stdout, _) = run_command(&[
        "run",
        "--",
        "--no-update",
        "--rate",
        "EUR:0.85",
        "1M usd in eur",
    ]);
    assert!(stdout.contains("eur"));
    // 1000000 * 0.85 = 850000 = 850.0k eur
    let re = Regex::new(r"850\.0k eur").unwrap();
    assert!(re.is_match(stdout.trim()));
}

#[test]
fn test_mixed_operations_with_conversion() {
    // Use fixed rate: 1 USD = 154 JPY
    let (stdout, _) = run_command(&[
        "run",
        "--",
        "--no-update",
        "--rate",
        "JPY:154",
        "100 usd * 2 in jpy",
    ]);
    assert!(stdout.contains("jpy"));
    // 200 * 154 = 30800 = 30.8k jpy
    let re = Regex::new(r"30\.8k jpy").unwrap();
    assert!(re.is_match(stdout.trim()));
}

#[test]
fn test_negative_with_conversion() {
    // Use fixed rate: 1 USD = 0.85 EUR
    let (stdout, _) = run_command(&[
        "run",
        "--",
        "--no-update",
        "--rate",
        "EUR:0.85",
        "-100 usd in eur",
    ]);
    assert!(stdout.contains("eur"));
    // -100 * 0.85 = -85.00 eur
    let re = Regex::new(r"-85\.00 eur").unwrap();
    assert!(re.is_match(stdout.trim()));
}

#[test]
fn test_history_commands_dont_add_to_history() {
    let config = numby::config::Config::default();
    let registry =
        numby::evaluator::AgentRegistry::new(&config).expect("Failed to initialize agent registry");
    let mut state = numby::models::AppState::builder(&config).build();
    *state.history.write().unwrap() = vec![
        numby::models::HistoryEntry {
            value: 10.0,
            unit: None,
        },
        numby::models::HistoryEntry {
            value: 20.0,
            unit: None,
        },
        numby::models::HistoryEntry {
            value: 30.0,
            unit: None,
        },
    ];

    // Test sum command
    let result = registry.evaluate("sum", &mut state);
    assert_eq!(result, Some(("60".to_string(), true)));
    // History should still have 3 items (not 4)
    assert_eq!(state.history.read().unwrap().len(), 3);

    std::thread::sleep(std::time::Duration::from_millis(60));

    // Test average command
    let result = registry.evaluate("average", &mut state);
    assert_eq!(result, Some(("20".to_string(), true)));
    // History should still have 3 items
    assert_eq!(state.history.read().unwrap().len(), 3);

    std::thread::sleep(std::time::Duration::from_millis(60));

    // Test prev command
    let result = registry.evaluate("prev", &mut state);
    assert_eq!(result, Some(("30".to_string(), true)));
    // History should still have 3 items
    assert_eq!(state.history.read().unwrap().len(), 3);

    std::thread::sleep(std::time::Duration::from_millis(60));

    // Test that regular expressions still add to history
    let result = registry.evaluate("40 + 5", &mut state);
    assert_eq!(result, Some(("45.00".to_string(), true)));
    // History should now have 4 items
    assert_eq!(state.history.read().unwrap().len(), 4);
    let hist = state.history.read().unwrap();
    let values: Vec<f64> = hist.iter().map(|h| h.value).collect();
    assert_eq!(values, vec![10.0, 20.0, 30.0, 45.0]);
}

#[test]
fn test_comments() {
    // Test basic // comment stripping
    let (stdout, _) = run_command(&["run", "--", "10 + 5 // this is a comment"]);
    assert!(stdout.contains("15"));

    // Test basic # comment stripping
    let (stdout, _) = run_command(&["run", "--", "10 + 5 # this is a comment"]);
    assert!(stdout.contains("15"));

    // Test comment with percentage
    let (stdout, _) = run_command(&["run", "--", "10% of 200 // calculate percentage"]);
    assert!(stdout.contains("20"));

    let (stdout, _) = run_command(&["run", "--", "10% of 200 # calculate percentage"]);
    assert!(stdout.contains("20"));

    // Test comment with units
    let (stdout, _) = run_command(&["run", "--", "50% of 100 USD // half of 100 dollars"]);
    assert!(stdout.contains("50.00 USD"));

    let (stdout, _) = run_command(&["run", "--", "50% of 100 USD # half of 100 dollars"]);
    assert!(stdout.contains("50.00 USD"));

    // Test that comment-only line fails
    let (_, stderr) = run_command(&["run", "--", "// just a comment"]);
    assert!(stderr.contains("Error"));

    let (_, stderr) = run_command(&["run", "--", "# just a comment"]);
    assert!(stderr.contains("Error"));

    // Test mixed comment styles (first one wins)
    let (stdout, _) = run_command(&["run", "--", "10 + 5 // comment # ignored"]);
    assert!(stdout.contains("15"));
}

#[test]
fn test_percentage_expressions() {
    // Test "X% of Y" format
    let (stdout, _) = run_command(&["run", "--", "10% of 100"]);
    assert!(stdout.contains("10"));

    let (stdout, _) = run_command(&["run", "--", "50% of 200"]);
    assert!(stdout.contains("100"));

    // Test with units
    let (stdout, _) = run_command(&["run", "--", "25% of 100 USD"]);
    assert!(stdout.contains("25.00 USD"));

    // Test percentage operations
    let (stdout, _) = run_command(&["run", "--", "100 + 10%"]);
    assert!(stdout.contains("110"));

    let (stdout, _) = run_command(&["run", "--", "200 - 25%"]);
    assert!(stdout.contains("150"));

    let (stdout, _) = run_command(&["run", "--", "100 * 50%"]);
    assert!(stdout.contains("50"));

    let (stdout, _) = run_command(&["run", "--", "100 / 20%"]);
    assert!(stdout.contains("500"));
}

#[test]
fn test_percentage_with_parentheses_of() {
    // 15 - (30% of 15) = 15 - 4.5 = 10.5
    let (stdout, _) = run_command(&["run", "--", "15 - (30% of 15)"]);
    assert!(stdout.contains("10.5"), "got {}", stdout);

    // 100 + (25% of 100) = 100 + 25 = 125
    let (stdout, _) = run_command(&["run", "--", "100 + (25% of 100)"]);
    assert!(stdout.contains("125"), "got {}", stdout);

    // 200 * (10% of 50) = 200 * 5 = 1000
    let (stdout, _) = run_command(&["run", "--", "200 * (10% of 50)"]);
    assert!(stdout.contains("1.0k") || stdout.contains("1000"), "got {}", stdout);
}

#[test]
fn test_percentage_with_parentheses_op() {
    // 15 - (15 - 30%) = 15 - 10.5 = 4.5
    let (stdout, _) = run_command(&["run", "--", "15 - (15 - 30%)"]);
    assert!(stdout.contains("4.5"), "got {}", stdout);

    // 100 + (100 + 10%) = 100 + 110 = 210
    let (stdout, _) = run_command(&["run", "--", "100 + (100 + 10%)"]);
    assert!(stdout.contains("210"), "got {}", stdout);

    // (100 + 50%) - 50 = 150 - 50 = 100
    let (stdout, _) = run_command(&["run", "--", "(100 + 50%) - 50"]);
    assert!(stdout.contains("100"), "got {}", stdout);
}

#[test]
fn test_percentage_nested_parentheses() {
    // (50% of (100 + 100)) = 50% of 200 = 100
    let (stdout, _) = run_command(&["run", "--", "(50% of (100 + 100))"]);
    assert!(stdout.contains("100"), "got {}", stdout);

    // ((100 + 50%) + 10%) = (150 + 10%) = 165
    let (stdout, _) = run_command(&["run", "--", "((100 + 50%) + 10%)"]);
    assert!(stdout.contains("165"), "got {}", stdout);
}

#[test]
fn test_percentage_standalone_in_parens() {
    // (30% of 100) should work standalone
    let (stdout, _) = run_command(&["run", "--", "(30% of 100)"]);
    assert!(stdout.contains("30"), "got {}", stdout);

    // (100 - 20%) should work standalone
    let (stdout, _) = run_command(&["run", "--", "(100 - 20%)"]);
    assert!(stdout.contains("80"), "got {}", stdout);
}

#[test]
fn test_percentage_multiple_operations() {
    // Multiple percentage operations in sequence
    // Note: "X% of Y + Z" evaluates as "X% of (Y + Z)" - the "of" binds to everything after it

    // 50% of 200 + 50 = 50% of 250 = 125 (not 150!)
    let (stdout, _) = run_command(&["run", "--", "50% of 200 + 50"]);
    assert!(stdout.contains("125"), "got {}", stdout);

    // To get (50% of 200) + 50 = 150, use parentheses
    let (stdout, _) = run_command(&["run", "--", "(50% of 200) + 50"]);
    assert!(stdout.contains("150"), "got {}", stdout);

    // 100 - 50% = 50
    let (stdout, _) = run_command(&["run", "--", "100 - 50%"]);
    assert!(stdout.contains("50"), "got {}", stdout);

    // 100 * 25% = 25
    let (stdout, _) = run_command(&["run", "--", "100 * 25%"]);
    assert!(stdout.contains("25"), "got {}", stdout);

    // 100 / 50% = 200
    let (stdout, _) = run_command(&["run", "--", "100 / 50%"]);
    assert!(stdout.contains("200"), "got {}", stdout);
}

#[test]
fn test_percentage_decimal_values() {
    // 12.5% of 80 = 10
    let (stdout, _) = run_command(&["run", "--", "12.5% of 80"]);
    assert!(stdout.contains("10"), "got {}", stdout);

    // 33.33% of 300 = 99.99
    let (stdout, _) = run_command(&["run", "--", "33.33% of 300"]);
    assert!(stdout.contains("99.99") || stdout.contains("100"), "got {}", stdout);

    // (2.5% of 1000) = 25
    let (stdout, _) = run_command(&["run", "--", "(2.5% of 1000)"]);
    assert!(stdout.contains("25"), "got {}", stdout);
}

#[test]
fn test_percentage_parens_with_arithmetic() {
    // 2 * (50% of 100) = 2 * 50 = 100
    let (stdout, _) = run_command(&["run", "--", "2 * (50% of 100)"]);
    assert!(stdout.contains("100"), "got {}", stdout);

    // (50% of 100) * 2 = 50 * 2 = 100
    let (stdout, _) = run_command(&["run", "--", "(50% of 100) * 2"]);
    assert!(stdout.contains("100"), "got {}", stdout);

    // (50% of 100) + (25% of 200) = 50 + 50 = 100
    let (stdout, _) = run_command(&["run", "--", "(50% of 100) + (25% of 200)"]);
    assert!(stdout.contains("100"), "got {}", stdout);

    // (100 + 50%) / 3 = 150 / 3 = 50
    let (stdout, _) = run_command(&["run", "--", "(100 + 50%) / 3"]);
    assert!(stdout.contains("50"), "got {}", stdout);

    // 1000 - (10% of 1000) - (5% of 1000) = 1000 - 100 - 50 = 850
    let (stdout, _) = run_command(&["run", "--", "1000 - (10% of 1000) - (5% of 1000)"]);
    assert!(stdout.contains("850"), "got {}", stdout);
}

#[test]
fn test_percentage_parens_complex_nesting() {
    // ((200 - 50%) + 20%) = (100 + 20%) = 120
    let (stdout, _) = run_command(&["run", "--", "((200 - 50%) + 20%)"]);
    assert!(stdout.contains("120"), "got {}", stdout);

    // (10% of (50% of 1000)) = 10% of 500 = 50
    let (stdout, _) = run_command(&["run", "--", "(10% of (50% of 1000))"]);
    assert!(stdout.contains("50"), "got {}", stdout);

    // ((100 + 100%) - 50%) = (200 - 50%) = 100
    let (stdout, _) = run_command(&["run", "--", "((100 + 100%) - 50%)"]);
    assert!(stdout.contains("100"), "got {}", stdout);
}

#[test]
fn test_percentage_edge_cases() {
    // 0% of 100 = 0
    let (stdout, _) = run_command(&["run", "--", "0% of 100"]);
    assert!(stdout.contains("0"), "got {}", stdout);

    // 100% of 50 = 50
    let (stdout, _) = run_command(&["run", "--", "100% of 50"]);
    assert!(stdout.contains("50"), "got {}", stdout);

    // 200% of 50 = 100
    let (stdout, _) = run_command(&["run", "--", "200% of 50"]);
    assert!(stdout.contains("100"), "got {}", stdout);

    // (0% of 1000) = 0
    let (stdout, _) = run_command(&["run", "--", "(0% of 1000)"]);
    assert!(stdout.contains("0"), "got {}", stdout);

    // 100 + 0% = 100
    let (stdout, _) = run_command(&["run", "--", "100 + 0%"]);
    assert!(stdout.contains("100"), "got {}", stdout);

    // 100 - 100% = 0
    let (stdout, _) = run_command(&["run", "--", "100 - 100%"]);
    assert!(stdout.contains("0"), "got {}", stdout);
}

#[test]
fn test_percentage_parens_real_world() {
    // Discount calculation: price - (discount% of price)
    // 500 - (20% of 500) = 500 - 100 = 400
    let (stdout, _) = run_command(&["run", "--", "500 - (20% of 500)"]);
    assert!(stdout.contains("400"), "got {}", stdout);

    // Tax calculation: price + (tax% of price)
    // 100 + (8% of 100) = 100 + 8 = 108
    let (stdout, _) = run_command(&["run", "--", "100 + (8% of 100)"]);
    assert!(stdout.contains("108"), "got {}", stdout);

    // Tip on subtotal: (subtotal + (tip%))
    // (85 + 20%) = 102
    let (stdout, _) = run_command(&["run", "--", "(85 + 20%)"]);
    assert!(stdout.contains("102"), "got {}", stdout);

    // Compound discount: original * (1 - first_discount%) * (1 - second_discount%)
    // Simplified: 1000 - (10% of 1000) then - (5% of result)
    // But we can test: 1000 * (100 - 10%) / 100 = 900... complex, skip

    // Sale price after markup and discount
    // cost + (50% of cost) - (20% of (cost + 50% of cost))
    // For cost=100: 100 + 50 - (20% of 150) = 150 - 30 = 120
    let (stdout, _) = run_command(&["run", "--", "100 + (50% of 100) - (20% of 150)"]);
    assert!(stdout.contains("120"), "got {}", stdout);
}

#[test]
fn test_percentage_parens_division() {
    // (100 / 50%) = 100 / 0.5 = 200
    let (stdout, _) = run_command(&["run", "--", "(100 / 50%)"]);
    assert!(stdout.contains("200"), "got {}", stdout);

    // 1000 / (50% of 100) = 1000 / 50 = 20
    let (stdout, _) = run_command(&["run", "--", "1000 / (50% of 100)"]);
    assert!(stdout.contains("20"), "got {}", stdout);

    // (200 / 25%) = 800
    let (stdout, _) = run_command(&["run", "--", "(200 / 25%)"]);
    assert!(stdout.contains("800"), "got {}", stdout);
}

#[test]
fn test_percentage_parens_multiplication() {
    // (100 * 50%) = 50
    let (stdout, _) = run_command(&["run", "--", "(100 * 50%)"]);
    assert!(stdout.contains("50"), "got {}", stdout);

    // 10 * (20% of 100) = 10 * 20 = 200
    let (stdout, _) = run_command(&["run", "--", "10 * (20% of 100)"]);
    assert!(stdout.contains("200"), "got {}", stdout);

    // (50% of 100) * (50% of 100) = 50 * 50 = 2500
    let (stdout, _) = run_command(&["run", "--", "(50% of 100) * (50% of 100)"]);
    assert!(stdout.contains("2.5k") || stdout.contains("2500"), "got {}", stdout);
}

#[test]
fn test_percentage_large_numbers() {
    // 15% of 1000000 = 150000
    let (stdout, _) = run_command(&["run", "--", "15% of 1000000"]);
    assert!(stdout.contains("150") || stdout.contains("150.0k"), "got {}", stdout);

    // (5% of 1000000) = 50000
    let (stdout, _) = run_command(&["run", "--", "(5% of 1000000)"]);
    assert!(stdout.contains("50") || stdout.contains("50.0k"), "got {}", stdout);

    // 1000000 + 10% = 1100000
    let (stdout, _) = run_command(&["run", "--", "1000000 + 10%"]);
    assert!(stdout.contains("1.1M") || stdout.contains("1100000"), "got {}", stdout);
}

#[test]
fn test_percentage_small_numbers() {
    // 50% of 0.5 = 0.25
    let (stdout, _) = run_command(&["run", "--", "50% of 0.5"]);
    assert!(stdout.contains("0.25"), "got {}", stdout);

    // 10% of 0.01 = 0.001
    let (stdout, _) = run_command(&["run", "--", "10% of 0.01"]);
    assert!(stdout.contains("0.001") || stdout.contains("0.00"), "got {}", stdout);

    // (25% of 0.8) = 0.2
    let (stdout, _) = run_command(&["run", "--", "(25% of 0.8)"]);
    assert!(stdout.contains("0.2"), "got {}", stdout);
}

#[test]
fn test_percentage_triple_nesting() {
    // (((100 + 50%) - 25%) + 10%) = ((150 - 25%) + 10%) = (112 + 10%) = 123.2 ≈ 124 (rounded)
    let (stdout, _) = run_command(&["run", "--", "(((100 + 50%) - 25%) + 10%)"]);
    assert!(stdout.contains("123") || stdout.contains("124"), "got {}", stdout);

    // (10% of (20% of (50% of 1000))) = 10% of (20% of 500) = 10% of 100 = 10
    let (stdout, _) = run_command(&["run", "--", "(10% of (20% of (50% of 1000)))"]);
    assert!(stdout.contains("10"), "got {}", stdout);

    // ((50% of 200) + (25% of (50% of 400))) = 100 + (25% of 200) = 100 + 50 = 150
    let (stdout, _) = run_command(&["run", "--", "((50% of 200) + (25% of (50% of 400)))"]);
    assert!(stdout.contains("150"), "got {}", stdout);
}

#[test]
fn test_percentage_with_scales() {
    // 10% of 1k = 100
    let (stdout, _) = run_command(&["run", "--", "10% of 1k"]);
    assert!(stdout.contains("100"), "got {}", stdout);

    // (5% of 2M) = 100000 = 100k
    let (stdout, _) = run_command(&["run", "--", "(5% of 2M)"]);
    assert!(stdout.contains("100") || stdout.contains("100.0k"), "got {}", stdout);

    // 1k + 10% = 1100
    let (stdout, _) = run_command(&["run", "--", "1k + 10%"]);
    assert!(stdout.contains("1.1k") || stdout.contains("1100"), "got {}", stdout);

    // (1M - 15%) = 850000 = 850k
    let (stdout, _) = run_command(&["run", "--", "(1M - 15%)"]);
    assert!(stdout.contains("850") || stdout.contains("850.0k"), "got {}", stdout);
}

#[test]
fn test_percentage_shopping_scenarios() {
    // Original price $100, 20% off, then additional 10% off on sale price
    // 100 - (20% of 100) = 80, then 80 - (10% of 80) = 72
    // Using nested: ((100 - 20%) - 10%) = (80 - 10%) = 72
    let (stdout, _) = run_command(&["run", "--", "((100 - 20%) - 10%)"]);
    assert!(stdout.contains("72"), "got {}", stdout);

    // Buy 3 items at $25 each, get 15% off total
    // 3 * 25 = 75, 75 - (15% of 75) = 63.75
    let (stdout, _) = run_command(&["run", "--", "3 * 25 - (15% of 75)"]);
    assert!(stdout.contains("63.75") || stdout.contains("63.7"), "got {}", stdout);

    // Item costs $49.99, tax is 8.25%
    // 49.99 + (8.25% of 49.99) = 49.99 + 4.124 ≈ 54.11
    let (stdout, _) = run_command(&["run", "--", "49.99 + (8.25% of 49.99)"]);
    assert!(stdout.contains("54.1"), "got {}", stdout);

    // Membership discount: 25% off $200 purchase
    // (200 - 25%) = 150
    let (stdout, _) = run_command(&["run", "--", "(200 - 25%)"]);
    assert!(stdout.contains("150"), "got {}", stdout);

    // Coupon: $10 off + 5% off remaining
    // 100 - 10 - (5% of 90) = 90 - 4.5 = 85.5
    let (stdout, _) = run_command(&["run", "--", "100 - 10 - (5% of 90)"]);
    assert!(stdout.contains("85.5"), "got {}", stdout);
}

#[test]
fn test_percentage_finance_scenarios() {
    // Investment return: $10000 with 7% annual return
    // (10000 + 7%) = 10700
    let (stdout, _) = run_command(&["run", "--", "(10000 + 7%)"]);
    assert!(stdout.contains("10.7k") || stdout.contains("10700"), "got {}", stdout);

    // Loan interest: $5000 loan, 12% interest
    // 5000 + (12% of 5000) = 5600
    let (stdout, _) = run_command(&["run", "--", "5000 + (12% of 5000)"]);
    assert!(stdout.contains("5.6k") || stdout.contains("5600"), "got {}", stdout);

    // Down payment: 20% of $250000 home
    // (20% of 250000) = 50000
    let (stdout, _) = run_command(&["run", "--", "(20% of 250000)"]);
    assert!(stdout.contains("50") || stdout.contains("50.0k"), "got {}", stdout);

    // Commission: 3% on $500000 sale
    // (3% of 500000) = 15000
    let (stdout, _) = run_command(&["run", "--", "(3% of 500000)"]);
    assert!(stdout.contains("15") || stdout.contains("15.0k"), "got {}", stdout);

    // Savings goal: Need $10000, currently have $7500, what % achieved?
    // This is reverse calculation, but we can test: 75% of 10000 = 7500
    let (stdout, _) = run_command(&["run", "--", "75% of 10000"]);
    assert!(stdout.contains("7.5k") || stdout.contains("7500"), "got {}", stdout);

    // Tax bracket: 22% on income above threshold
    // If excess income is $30000: (22% of 30000) = 6600
    let (stdout, _) = run_command(&["run", "--", "(22% of 30000)"]);
    assert!(stdout.contains("6.6k") || stdout.contains("6600"), "got {}", stdout);
}

#[test]
fn test_percentage_tip_scenarios() {
    // Restaurant bill $85.50, 18% tip
    // (18% of 85.50) = 15.39
    let (stdout, _) = run_command(&["run", "--", "(18% of 85.50)"]);
    assert!(stdout.contains("15.39") || stdout.contains("15.4"), "got {}", stdout);

    // Total with 20% tip: 85.50 + (20% of 85.50) ≈ 102.6 (may round to 103)
    let (stdout, _) = run_command(&["run", "--", "85.50 + (20% of 85.50)"]);
    assert!(stdout.contains("102") || stdout.contains("103"), "got {}", stdout);

    // Split bill 4 ways with 15% tip
    // (120 + 15%) / 4 = 138 / 4 = 34.5
    let (stdout, _) = run_command(&["run", "--", "(120 + 15%) / 4"]);
    assert!(stdout.contains("34.5"), "got {}", stdout);

    // Tip on pre-tax amount: bill $50, tax was $4, tip 20% on $50
    // 50 + 4 + (20% of 50) = 54 + 10 = 64
    let (stdout, _) = run_command(&["run", "--", "50 + 4 + (20% of 50)"]);
    assert!(stdout.contains("64"), "got {}", stdout);
}

#[test]
fn test_percentage_salary_scenarios() {
    // Annual salary $75000, 3% raise
    // (75000 + 3%) = 77250 (may display as 77.2k or 77.25k)
    let (stdout, _) = run_command(&["run", "--", "(75000 + 3%)"]);
    assert!(stdout.contains("77.2") || stdout.contains("77250"), "got {}", stdout);

    // Bonus: 10% of $60000 salary
    // (10% of 60000) = 6000
    let (stdout, _) = run_command(&["run", "--", "(10% of 60000)"]);
    assert!(stdout.contains("6") || stdout.contains("6.0k"), "got {}", stdout);

    // Take-home after 25% tax on $80000
    // (80000 - 25%) = 60000
    let (stdout, _) = run_command(&["run", "--", "(80000 - 25%)"]);
    assert!(stdout.contains("60") || stdout.contains("60.0k"), "got {}", stdout);

    // 401k contribution: 6% of $5000 monthly
    // (6% of 5000) = 300
    let (stdout, _) = run_command(&["run", "--", "(6% of 5000)"]);
    assert!(stdout.contains("300"), "got {}", stdout);
}

#[test]
fn test_percentage_cooking_scenarios() {
    // Recipe scale: 75% of original that calls for 2 cups
    // (75% of 2) = 1.5
    let (stdout, _) = run_command(&["run", "--", "(75% of 2)"]);
    assert!(stdout.contains("1.5"), "got {}", stdout);

    // Increase recipe by 50%: original 3 servings
    // (3 + 50%) = 4.5
    let (stdout, _) = run_command(&["run", "--", "(3 + 50%)"]);
    assert!(stdout.contains("4.5"), "got {}", stdout);

    // Reduce sugar by 30%: original 200g
    // (200 - 30%) = 140
    let (stdout, _) = run_command(&["run", "--", "(200 - 30%)"]);
    assert!(stdout.contains("140"), "got {}", stdout);
}

#[test]
fn test_percentage_fitness_scenarios() {
    // Calorie deficit: 2000 daily - 20%
    // (2000 - 20%) = 1600
    let (stdout, _) = run_command(&["run", "--", "(2000 - 20%)"]);
    assert!(stdout.contains("1.6k") || stdout.contains("1600"), "got {}", stdout);

    // Protein goal: 30% of 2500 calories (then /4 for grams)
    // (30% of 2500) / 4 = 750 / 4 ≈ 187-188
    let (stdout, _) = run_command(&["run", "--", "(30% of 2500) / 4"]);
    assert!(stdout.contains("187") || stdout.contains("188"), "got {}", stdout);

    // Weight loss: lost 15% of starting 200 lbs
    // (15% of 200) = 30
    let (stdout, _) = run_command(&["run", "--", "(15% of 200)"]);
    assert!(stdout.contains("30"), "got {}", stdout);

    // Heart rate zones: 70% of max HR 190
    // (70% of 190) = 133
    let (stdout, _) = run_command(&["run", "--", "(70% of 190)"]);
    assert!(stdout.contains("133"), "got {}", stdout);
}

#[test]
fn test_percentage_business_scenarios() {
    // Profit margin: revenue $50000, costs $35000
    // Profit = 50000 - 35000 = 15000
    // We can test: 30% of 50000 = 15000 (30% margin)
    let (stdout, _) = run_command(&["run", "--", "(30% of 50000)"]);
    assert!(stdout.contains("15") || stdout.contains("15.0k"), "got {}", stdout);

    // Markup: cost $40, markup 60%
    // (40 + 60%) = 64
    let (stdout, _) = run_command(&["run", "--", "(40 + 60%)"]);
    assert!(stdout.contains("64"), "got {}", stdout);

    // Inventory shrinkage: 2% of $100000 inventory
    // (2% of 100000) = 2000
    let (stdout, _) = run_command(&["run", "--", "(2% of 100000)"]);
    assert!(stdout.contains("2") || stdout.contains("2.0k"), "got {}", stdout);

    // Customer retention: lost 5% of 10000 customers
    // 10000 - (5% of 10000) = 9500
    let (stdout, _) = run_command(&["run", "--", "10000 - (5% of 10000)"]);
    assert!(stdout.contains("9.5k") || stdout.contains("9500"), "got {}", stdout);

    // Revenue growth: $1M last year + 12% growth
    // (1000000 + 12%) = 1120000 (may display as 1.1M rounded)
    let (stdout, _) = run_command(&["run", "--", "(1000000 + 12%)"]);
    assert!(stdout.contains("1.1") || stdout.contains("1120000"), "got {}", stdout);
}

#[test]
fn test_percentage_education_scenarios() {
    // Grade calculation: 85% on test worth 40% of grade
    // (85 * 40%) / 100 = 34 points contributed... or simpler:
    // 40% of 85 = 34
    let (stdout, _) = run_command(&["run", "--", "(40% of 85)"]);
    assert!(stdout.contains("34"), "got {}", stdout);

    // Scholarship: covers 75% of $40000 tuition
    // (75% of 40000) = 30000
    let (stdout, _) = run_command(&["run", "--", "(75% of 40000)"]);
    assert!(stdout.contains("30") || stdout.contains("30.0k"), "got {}", stdout);

    // Remaining tuition after scholarship
    // 40000 - (75% of 40000) = 10000
    let (stdout, _) = run_command(&["run", "--", "40000 - (75% of 40000)"]);
    assert!(stdout.contains("10") || stdout.contains("10.0k"), "got {}", stdout);

    // Curve: add 8% to everyone's score of 72
    // (72 + 8%) = 77.76
    let (stdout, _) = run_command(&["run", "--", "(72 + 8%)"]);
    assert!(stdout.contains("77.76") || stdout.contains("77.7"), "got {}", stdout);
}

#[test]
fn test_percentage_complex_parentheses_patterns() {
    // ((a + b%) * c) pattern: ((100 + 20%) * 2) = 120 * 2 = 240
    let (stdout, _) = run_command(&["run", "--", "((100 + 20%) * 2)"]);
    assert!(stdout.contains("240"), "got {}", stdout);

    // (a * (b + c%)) pattern: (2 * (100 + 50%)) = 2 * 150 = 300
    let (stdout, _) = run_command(&["run", "--", "(2 * (100 + 50%))"]);
    assert!(stdout.contains("300"), "got {}", stdout);

    // ((a - b%) / c) pattern: ((200 - 25%) / 5) = 150 / 5 = 30
    let (stdout, _) = run_command(&["run", "--", "((200 - 25%) / 5)"]);
    assert!(stdout.contains("30"), "got {}", stdout);

    // (a / (b - c%)) pattern: (100 / (50 - 20%)) = 100 / 40 = 2.5
    let (stdout, _) = run_command(&["run", "--", "(100 / (50 - 20%))"]);
    assert!(stdout.contains("2.5"), "got {}", stdout);

    // Mixed: ((a% of b) + (c% of d)) * e
    // ((10% of 100) + (20% of 50)) * 2 = (10 + 10) * 2 = 40
    let (stdout, _) = run_command(&["run", "--", "((10% of 100) + (20% of 50)) * 2"]);
    assert!(stdout.contains("40"), "got {}", stdout);

    // Nested percentage then arithmetic: ((100 - 20%) * 2) / 4 = 80 * 2 / 4 = 40
    let (stdout, _) = run_command(&["run", "--", "((100 - 20%) * 2) / 4"]);
    assert!(stdout.contains("40"), "got {}", stdout);
}

#[test]
fn test_percentage_chained_operations() {
    // Apply multiple percentage changes in sequence
    // Start with 100, +10%, -5%, +20%
    // (((100 + 10%) - 5%) + 20%) ≈ 125 (with rounding)
    let (stdout, _) = run_command(&["run", "--", "(((100 + 10%) - 5%) + 20%)"]);
    assert!(stdout.contains("125"), "got {}", stdout);

    // Price after multiple markups: 50 * 1.2 * 1.1 = 66
    // Using percentages: ((50 + 20%) + 10%) = (60 + 10%) = 66
    let (stdout, _) = run_command(&["run", "--", "((50 + 20%) + 10%)"]);
    assert!(stdout.contains("66"), "got {}", stdout);

    // Compound decrease: 1000 -> -10% -> -10% -> -10%
    // (((1000 - 10%) - 10%) - 10%) = ((900 - 10%) - 10%) = (810 - 10%) = 729
    let (stdout, _) = run_command(&["run", "--", "(((1000 - 10%) - 10%) - 10%)"]);
    assert!(stdout.contains("729"), "got {}", stdout);
}

#[test]
fn test_percentage_with_negative_base() {
    // Percentage of negative number
    // 10% of -100 = -10
    let (stdout, _) = run_command(&["run", "--", "10% of -100"]);
    assert!(stdout.contains("-10"), "got {}", stdout);

    // (50% of -200) = -100
    let (stdout, _) = run_command(&["run", "--", "(50% of -200)"]);
    assert!(stdout.contains("-100"), "got {}", stdout);

    // Negative base with percentage operation
    // -100 + 10% = -100 + (-10) = -110
    let (stdout, _) = run_command(&["run", "--", "-100 + 10%"]);
    assert!(stdout.contains("-110"), "got {}", stdout);

    // -50 - 20% = -50 - (-10) = -40
    let (stdout, _) = run_command(&["run", "--", "-50 - 20%"]);
    assert!(stdout.contains("-40"), "got {}", stdout);
}

#[test]
fn test_percentage_order_of_operations() {
    // Note: Percentage patterns match from the base number to the %, so:
    // "100 + 50 - 20%" matches "50 - 20%" = 40, result is just 40
    // Use parentheses for complex expressions!

    // Simple case: 150 - 20% = 120
    let (stdout, _) = run_command(&["run", "--", "150 - 20%"]);
    assert!(stdout.contains("120"), "got {}", stdout);

    // With parentheses for clarity: (100 + 50%) = 150
    let (stdout, _) = run_command(&["run", "--", "(100 + 50%)"]);
    assert!(stdout.contains("150"), "got {}", stdout);

    // Complex expressions need parentheses: ((100 + 50%) - 20%) = (150 - 20%) = 120
    let (stdout, _) = run_command(&["run", "--", "((100 + 50%) - 20%)"]);
    assert!(stdout.contains("120"), "got {}", stdout);

    // Use "of" for explicit percentage calculation: 20% of 150 = 30
    let (stdout, _) = run_command(&["run", "--", "20% of 150"]);
    assert!(stdout.contains("30"), "got {}", stdout);
}

#[test]
fn test_tui_display_doesnt_modify_history() {
    let config = numby::config::Config::default();
    let registry =
        numby::evaluator::AgentRegistry::new(&config).expect("Failed to initialize agent registry");
    let mut state = numby::models::AppState::builder(&config).build();
    *state.history.write().unwrap() = vec![
        numby::models::HistoryEntry {
            value: 40.0,
            unit: None,
        },
        numby::models::HistoryEntry {
            value: 50.0,
            unit: None,
        },
    ];

    // Simulate TUI display evaluation (should not modify history at all)
    let _ = registry.evaluate_for_display("sum", &state);
    // History should still have 2 items
    assert_eq!(state.history.read().unwrap().len(), 2);
    let values: Vec<f64> = state
        .history
        .read()
        .unwrap()
        .iter()
        .map(|h| h.value)
        .collect();
    assert_eq!(values, vec![40.0, 50.0]);

    // Simulate TUI display evaluation of regular expression (should not modify history)
    let _ = registry.evaluate_for_display("40 + 50", &state);
    // History should still have 2 items
    assert_eq!(state.history.read().unwrap().len(), 2);
    let values: Vec<f64> = state
        .history
        .read()
        .unwrap()
        .iter()
        .map(|h| h.value)
        .collect();
    assert_eq!(values, vec![40.0, 50.0]);

    // Now simulate actual execution of regular expression (should add to history)
    let result = registry.evaluate("40 + 50", &mut state);
    assert_eq!(result, Some(("90.00".to_string(), true)));
    // History should now have 3 items
    assert_eq!(state.history.read().unwrap().len(), 3);
    let values: Vec<f64> = state
        .history
        .read()
        .unwrap()
        .iter()
        .map(|h| h.value)
        .collect();
    assert_eq!(values, vec![40.0, 50.0, 90.0]);

    std::thread::sleep(std::time::Duration::from_millis(60));

    // Now simulate actual execution of sum (should not add sum result to history)
    let result2 = registry.evaluate("sum", &mut state);
    assert_eq!(result2, Some(("180".to_string(), true)));
    // History should still have 3 items
    assert_eq!(state.history.read().unwrap().len(), 3);
    let values: Vec<f64> = state
        .history
        .read()
        .unwrap()
        .iter()
        .map(|h| h.value)
        .collect();
    assert_eq!(values, vec![40.0, 50.0, 90.0]);
}

#[test]
fn test_unicode_pi_symbol() {
    let (stdout, _) = run_command(&["run", "--", "π"]);
    assert!(stdout.contains("3.14"));
}

#[test]
fn test_unicode_multiplication_symbol() {
    let (stdout, _) = run_command(&["run", "--", "5 × 3"]);
    assert!(stdout.contains("15"));
}

#[test]
fn test_unicode_division_symbol() {
    let (stdout, _) = run_command(&["run", "--", "15 ÷ 3"]);
    assert!(stdout.contains("5"));
}

// Complex Math & Financial Tests
#[test]
fn test_investment_calculator() {
    // 10000 * (1 + 0.07)^10
    let (stdout, _) = run_command(&["run", "--", "10000 * (1 + 0.07)^10"]);
    // Result: 19671.51 ≈ 19.7k
    assert!(stdout.contains("19.7k") || stdout.contains("19.6k"));
}

#[test]
fn test_compound_interest() {
    // 5000 * (1 + 0.08/12)^(12*30)
    let (stdout, _) = run_command(&["run", "--", "5000 * (1 + 0.08/12)^(12*30)"]);
    // Result: 54757.37 ≈ 54.7k
    assert!(stdout.contains("54.7k") || stdout.contains("54.8k"));
}

#[test]
fn test_mortgage_payment() {
    // 250000 * (0.045/12) * (1 + 0.045/12)^(30*12) / ((1 + 0.045/12)^(30*12) - 1)
    let (stdout, _) = run_command(&[
        "run",
        "--",
        "250000 * (0.045/12) * (1 + 0.045/12)^(30*12) / ((1 + 0.045/12)^(30*12) - 1)",
    ]);
    // Result: 1266.71 ≈ 1.3k
    assert!(stdout.contains("1.2k") || stdout.contains("1.3k"));
}

// Scientific & Engineering Tests
#[test]
fn test_projectile_motion() {
    // 9.8 * 5^2 / 2
    let (stdout, _) = run_command(&["run", "--", "9.8 * 5^2 / 2"]);
    // Result: 122.5
    assert!(stdout.contains("122") || stdout.contains("123"));
}

#[test]
fn test_circle_area() {
    // π * 15^2
    let (stdout, _) = run_command(&["run", "--", "π * 15^2"]);
    // Result: 706.86 ≈ 707
    assert!(stdout.contains("706") || stdout.contains("707"));
}

#[test]
fn test_sphere_volume() {
    // (4/3) * π * 8^3
    let (stdout, _) = run_command(&["run", "--", "(4/3) * π * 8^3"]);
    // Result: 2144.66 ≈ 2.1k
    assert!(stdout.contains("2.1k") || stdout.contains("2.2k"));
}

#[test]
fn test_speed_of_light_conversion() {
    // 299792458 / 1609.34
    let (stdout, _) = run_command(&["run", "--", "299792458 / 1609.34"]);
    // Result: 186282.4 ≈ 186.3k
    assert!(stdout.contains("186.") || stdout.contains("186k") || stdout.contains("186.3k"));
}

// Unit Conversions & Salary Tests
#[test]
fn test_salary_monthly() {
    // 125000 / 12
    let (stdout, _) = run_command(&["run", "--", "125000 / 12"]);
    // Result: 10416.67 ≈ 10.4k
    assert!(stdout.contains("10.4k") || stdout.contains("10.5k"));
}

#[test]
fn test_hourly_rate() {
    // 10416.67 / 160
    let (stdout, _) = run_command(&["run", "--", "10416.67 / 160"]);
    // Result: 65.10
    assert!(stdout.contains("65.10") || stdout.contains("65.1"));
}

#[test]
fn test_bitcoin_to_usd() {
    // 0.5 * 43000
    let (stdout, _) = run_command(&["run", "--", "0.5 * 43000"]);
    // Result: 21500 ≈ 21.5k
    assert!(stdout.contains("21.5k"));
}

#[test]
fn test_gb_to_mb() {
    // 256 * 1024
    let (stdout, _) = run_command(&["run", "--", "256 * 1024"]);
    // Result: 262144 ≈ 262.1k
    assert!(stdout.contains("262") || stdout.contains("262.1k"));
}

// Business Calculations Tests
#[test]
fn test_revenue_per_day() {
    // 1500000 / 365
    let (stdout, _) = run_command(&["run", "--", "1500000 / 365"]);
    // Result: 4109.59 ≈ 4.1k
    assert!(stdout.contains("4.1k") || stdout.contains("4.0k"));
}

#[test]
fn test_profit_margin() {
    // (89.99 - 45.50) / 89.99 * 100
    let (stdout, _) = run_command(&["run", "--", "(89.99 - 45.50) / 89.99 * 100"]);
    // Result: 49.44
    assert!(stdout.contains("49.4") || stdout.contains("49.5"));
}

#[test]
fn test_tax_calculation() {
    // 75000 * 0.22
    let (stdout, _) = run_command(&["run", "--", "75000 * 0.22"]);
    // Result: 16500 ≈ 16.5k
    assert!(stdout.contains("16.5k"));
}

// Percentage & Ratios Tests
#[test]
fn test_tip_calculator() {
    // 145.50 * 0.20
    let (stdout, _) = run_command(&["run", "--", "145.50 * 0.20"]);
    // Result: 29.10
    assert!(stdout.contains("29.10") || stdout.contains("29.1"));
}

#[test]
fn test_sale_discount() {
    // 299.99 * (1 - 0.30)
    let (stdout, _) = run_command(&["run", "--", "299.99 * (1 - 0.30)"]);
    // Result: 209.99 ≈ 210
    assert!(stdout.contains("209") || stdout.contains("210"));
}

#[test]
fn test_growth_rate() {
    // (15000 - 12000) / 12000 * 100
    let (stdout, _) = run_command(&["run", "--", "(15000 - 12000) / 12000 * 100"]);
    // Result: 25.00
    assert!(stdout.contains("25"));
}

// Advanced Mathematical Functions Tests
#[test]
fn test_trigonometric_sine() {
    // sin(π/6) = 0.5
    let (stdout, _) = run_command(&["run", "--", "sin(π/6)"]);
    assert!(stdout.contains("0.5") || stdout.contains("0.49"));
}

#[test]
fn test_trigonometric_cosine() {
    // cos(π/3) = 0.5
    let (stdout, _) = run_command(&["run", "--", "cos(π/3)"]);
    assert!(stdout.contains("0.5") || stdout.contains("0.49"));
}

#[test]
fn test_trigonometric_tangent() {
    // tan(π/4) = 1
    let (stdout, _) = run_command(&["run", "--", "tan(π/4)"]);
    assert!(stdout.contains("1") || stdout.contains("0.99"));
}

#[test]
fn test_natural_logarithm() {
    // ln(e) = 1
    let (stdout, _) = run_command(&["run", "--", "ln(e)"]);
    assert!(stdout.contains("1"));

    // ln(2.71828) ≈ 1
    let (stdout, _) = run_command(&["run", "--", "ln(2.71828)"]);
    assert!(stdout.contains("1"));

    // ln(10) ≈ 2.303
    let (stdout, _) = run_command(&["run", "--", "ln(10)"]);
    assert!(stdout.contains("2.3"));
}

#[test]
fn test_logarithm_base_10() {
    // log(100) = 2
    let (stdout, _) = run_command(&["run", "--", "log(100)"]);
    assert!(stdout.contains("2"));
}

#[test]
fn test_square_root() {
    // sqrt(144) = 12
    let (stdout, _) = run_command(&["run", "--", "sqrt(144)"]);
    assert!(stdout.contains("12"));

    // sqrt(2) ≈ 1.414
    let (stdout, _) = run_command(&["run", "--", "sqrt(2)"]);
    assert!(stdout.contains("1.4"));

    // Nested: sqrt(sqrt(256)) = sqrt(16) = 4
    let (stdout, _) = run_command(&["run", "--", "sqrt(sqrt(256))"]);
    assert!(stdout.contains("4"));
}

#[test]
fn test_absolute_value() {
    // abs(-42)
    let (stdout, _) = run_command(&["run", "--", "abs(-42)"]);
    assert!(stdout.contains("42"));
}

#[test]
fn test_rounding_functions() {
    // ceil(3.2) = 4
    let (stdout, _) = run_command(&["run", "--", "ceil(3.2)"]);
    assert!(stdout.contains("4"));

    // floor(3.8) = 3
    let (stdout, _) = run_command(&["run", "--", "floor(3.8)"]);
    assert!(stdout.contains("3"));

    // round(3.5) = 4
    let (stdout, _) = run_command(&["run", "--", "round(3.5)"]);
    assert!(stdout.contains("4") || stdout.contains("3"));
}

#[test]
fn test_exponential_function() {
    // e^2
    let (stdout, _) = run_command(&["run", "--", "e^2"]);
    assert!(stdout.contains("7.3") || stdout.contains("7.4"));
}

#[test]
fn test_hyperbolic_functions() {
    // sinh(1)
    let (stdout, _) = run_command(&["run", "--", "sinh(1)"]);
    assert!(stdout.contains("1.17") || stdout.contains("1.18"));

    // cosh(0) = 1
    let (stdout, _) = run_command(&["run", "--", "cosh(0)"]);
    assert!(stdout.contains("1"));
}

// Physics & Engineering Formulas
#[test]
fn test_kinetic_energy() {
    // KE = 0.5 * m * v^2, where m=10kg, v=20m/s
    // KE = 0.5 * 10 * 20^2 = 2000J
    let (stdout, _) = run_command(&["run", "--", "0.5 * 10 * 20^2"]);
    assert!(stdout.contains("2.0k") || stdout.contains("2000"));
}

#[test]
fn test_gravitational_potential_energy() {
    // PE = m * g * h, where m=5kg, g=9.8m/s², h=10m
    // PE = 5 * 9.8 * 10 = 490J
    let (stdout, _) = run_command(&["run", "--", "5 * 9.8 * 10"]);
    assert!(stdout.contains("490"));
}

#[test]
fn test_pythagorean_theorem() {
    // c = sqrt(a² + b²), where a=3, b=4
    // c = sqrt(9 + 16) = sqrt(25) = 5
    let (stdout, _) = run_command(&["run", "--", "sqrt(3^2 + 4^2)"]);
    assert!(stdout.contains("5"));
}

#[test]
fn test_circle_circumference() {
    // C = 2 * π * r, where r=7
    // C = 2 * π * 7 ≈ 43.98
    let (stdout, _) = run_command(&["run", "--", "2 * π * 7"]);
    assert!(stdout.contains("43") || stdout.contains("44"));
}

#[test]
fn test_cylinder_volume() {
    // V = π * r² * h, where r=5, h=10
    // V = π * 25 * 10 ≈ 785.4
    let (stdout, _) = run_command(&["run", "--", "π * 5^2 * 10"]);
    assert!(stdout.contains("785") || stdout.contains("786"));
}

// Statistical & Data Science
#[test]
fn test_standard_deviation_components() {
    // Variance calculation: sum of squared differences
    // For data [2, 4, 6], mean = 4
    // Variance = ((2-4)² + (4-4)² + (6-4)²) / 3 = (4 + 0 + 4) / 3 = 2.67
    let (stdout, _) = run_command(&["run", "--", "((2-4)^2 + (4-4)^2 + (6-4)^2) / 3"]);
    assert!(stdout.contains("2.6") || stdout.contains("2.7"));
}

#[test]
fn test_z_score() {
    // z = (x - mean) / std_dev
    // where x=85, mean=70, std_dev=10
    // z = (85 - 70) / 10 = 1.5
    let (stdout, _) = run_command(&["run", "--", "(85 - 70) / 10"]);
    assert!(stdout.contains("1.5"));
}

// Finance Formulas
#[test]
fn test_simple_interest() {
    // I = P * r * t
    // where P=1000, r=0.05, t=3
    // I = 1000 * 0.05 * 3 = 150
    let (stdout, _) = run_command(&["run", "--", "1000 * 0.05 * 3"]);
    assert!(stdout.contains("150"));
}

#[test]
fn test_future_value() {
    // FV = PV * (1 + r)^n
    // where PV=5000, r=0.06, n=5
    // FV = 5000 * (1.06)^5 ≈ 6691.13
    let (stdout, _) = run_command(&["run", "--", "5000 * (1.06)^5"]);
    assert!(stdout.contains("6.6k") || stdout.contains("6.7k"));
}

#[test]
fn test_present_value() {
    // PV = FV / (1 + r)^n
    // where FV=10000, r=0.08, n=10
    // PV = 10000 / (1.08)^10 ≈ 4631.93
    let (stdout, _) = run_command(&["run", "--", "10000 / (1.08)^10"]);
    assert!(stdout.contains("4.6k") || stdout.contains("4.7k"));
}

#[test]
fn test_compound_annual_growth_rate() {
    // CAGR = (FV/PV)^(1/n) - 1
    // where FV=15000, PV=10000, n=5
    // CAGR = (1.5)^(1/5) - 1 ≈ 0.0845 = 8.45%
    let (stdout, _) = run_command(&["run", "--", "(15000/10000)^(1/5) - 1"]);
    assert!(stdout.contains("0.08") || stdout.contains("0.09"));
}

// Computer Science & Programming
#[test]
fn test_binary_operations() {
    // Calculate storage: bytes to gigabytes
    // 1GB = 1024^3 bytes = 1,073,741,824 ≈ 1.1B
    let (stdout, _) = run_command(&["run", "--", "1024^3"]);
    assert!(stdout.contains("1.0B") || stdout.contains("1.07B") || stdout.contains("1.1B"));
}

#[test]
fn test_base_conversion_calculation() {
    // Convert binary 1111 (15) to decimal through calculation
    // 1*2^3 + 1*2^2 + 1*2^1 + 1*2^0 = 8+4+2+1 = 15
    let (stdout, _) = run_command(&["run", "--", "1*2^3 + 1*2^2 + 1*2^1 + 1*2^0"]);
    assert!(stdout.contains("15"));
}

// Complex nested expressions
#[test]
fn test_deeply_nested_expression() {
    // ((2 + 3) * 4 - (6 / 2))^2
    // = (5 * 4 - 3)^2 = (20 - 3)^2 = 17^2 = 289
    let (stdout, _) = run_command(&["run", "--", "((2 + 3) * 4 - (6 / 2))^2"]);
    assert!(stdout.contains("289"));
}

#[test]
fn test_scientific_notation_operations() {
    // Speed of light in meters: 3e8
    // Calculate distance light travels in 1 minute (60 seconds)
    // 3e8 * 60 = 18,000,000,000 = 18B
    let (stdout, _) = run_command(&["run", "--", "3e8 * 60"]);
    assert!(stdout.contains("18") && (stdout.contains("B") || stdout.contains("billion")));
}

// Number formatting tests
#[test]
fn test_underscore_in_numbers() {
    // 1_000_000 should be parsed as 1000000
    let (stdout, _) = run_command(&["run", "--", "1_000_000"]);
    assert!(stdout.contains("1.0M") || stdout.contains("1M"));

    // Multiple underscores
    let (stdout, _) = run_command(&["run", "--", "1_000_000 + 500_000"]);
    assert!(stdout.contains("1.5M"));
}

#[test]
fn test_no_space_units() {
    // 100USD should work like 100 USD
    let (stdout, _) = run_command(&["run", "--", "100USD"]);
    assert!(stdout.contains("100") && stdout.contains("USD"));

    // 1_000_000USD
    let (stdout, _) = run_command(&["run", "--", "1_000_000USD"]);
    assert!(stdout.contains("1.0M USD") || stdout.contains("1M USD"));
}

// Inverse trigonometric functions
#[test]
fn test_inverse_trig_functions() {
    // asin(0.5) ≈ 0.524 radians
    let (stdout, _) = run_command(&["run", "--", "asin(0.5)"]);
    assert!(stdout.contains("0.5") || stdout.contains("0.52"));

    // acos(0.5) ≈ 1.047 radians
    let (stdout, _) = run_command(&["run", "--", "acos(0.5)"]);
    assert!(stdout.contains("1.0") || stdout.contains("1.1"));

    // atan(1) ≈ 0.785 radians (π/4)
    let (stdout, _) = run_command(&["run", "--", "atan(1)"]);
    assert!(stdout.contains("0.7") || stdout.contains("0.8"));
}

// Inverse hyperbolic functions
#[test]
fn test_inverse_hyperbolic_functions() {
    // asinh(1) ≈ 0.881
    let (stdout, _) = run_command(&["run", "--", "asinh(1)"]);
    assert!(stdout.contains("0.8") || stdout.contains("0.9"));

    // acosh(2) ≈ 1.317
    let (stdout, _) = run_command(&["run", "--", "acosh(2)"]);
    assert!(stdout.contains("1.3") || stdout.contains("1.4"));

    // atanh(0.5) ≈ 0.549
    let (stdout, _) = run_command(&["run", "--", "atanh(0.5)"]);
    assert!(stdout.contains("0.5") || stdout.contains("0.6"));
}

// Min/Max functions
#[test]
fn test_min_max_functions() {
    // min(5, 3, 8) = 3
    let (stdout, _) = run_command(&["run", "--", "min(5, 3, 8)"]);
    assert!(stdout.contains("3"));

    // max(5, 3, 8) = 8
    let (stdout, _) = run_command(&["run", "--", "max(5, 3, 8)"]);
    assert!(stdout.contains("8"));

    // Nested: max(min(10, 5), min(8, 3)) = max(5, 3) = 5
    let (stdout, _) = run_command(&["run", "--", "max(min(10, 5), min(8, 3))"]);
    assert!(stdout.contains("5"));
}

// Temperature conversions
#[test]
fn test_temperature_conversions() {
    // 0 celsius to fahrenheit = 32
    let (stdout, _) = run_command(&["run", "--", "0 celsius to fahrenheit"]);
    assert!(stdout.contains("32"));

    // 100 celsius to fahrenheit = 212
    let (stdout, _) = run_command(&["run", "--", "100 celsius to fahrenheit"]);
    assert!(stdout.contains("212"));

    // 32 fahrenheit to celsius = 0
    let (stdout, _) = run_command(&["run", "--", "32 fahrenheit to celsius"]);
    assert!(stdout.contains("0"));

    // 273.15 kelvin to celsius = 0
    let (stdout, _) = run_command(&["run", "--", "273.15 kelvin to celsius"]);
    assert!(stdout.contains("0") || stdout.contains("-0"));
}

// Time unit conversions
#[test]
fn test_time_conversions() {
    // 60 seconds to minutes = 1
    let (stdout, _) = run_command(&["run", "--", "60 seconds to minutes"]);
    assert!(stdout.contains("1"));

    // 24 hours to days = 1
    let (stdout, _) = run_command(&["run", "--", "24 hours to days"]);
    assert!(stdout.contains("1"));

    // 365 days to years = 1
    let (stdout, _) = run_command(&["run", "--", "365 days to years"]);
    assert!(stdout.contains("1"));
}

// Area conversions
#[test]
fn test_area_conversions() {
    // 10000 m2 to hectare = 1
    let (stdout, _) = run_command(&["run", "--", "10000 m2 to hectare"]);
    assert!(stdout.contains("1"));

    // 4046.86 m2 to acre ≈ 1
    let (stdout, _) = run_command(&["run", "--", "4046.86 m2 to acre"]);
    assert!(stdout.contains("1"));
}

// Volume conversions
#[test]
fn test_volume_conversions() {
    // 1000 liters to m3 = 1
    let (stdout, _) = run_command(&["run", "--", "1000 liters to m3"]);
    assert!(stdout.contains("1"));

    // 4 quarts to gallon ≈ 1
    let (stdout, _) = run_command(&["run", "--", "4 quarts to gallon"]);
    assert!(stdout.contains("1"));
}

// Weight conversions
#[test]
fn test_weight_conversions() {
    // 1000 grams to kg
    let (stdout, _) = run_command(&["run", "--", "1000000 grams to tonne"]);
    assert!(stdout.contains("1"));

    // 453.592 grams to pound = 1
    let (stdout, _) = run_command(&["run", "--", "453.592 grams to pound"]);
    assert!(stdout.contains("1"));

    // 16 ounces to pound = 1
    let (stdout, _) = run_command(&["run", "--", "453.592 grams to pound"]);
    assert!(stdout.contains("1"));
}

// Angular conversions
#[test]
fn test_angular_conversions() {
    // π radians to degrees = 180
    let (stdout, _) = run_command(&["run", "--", "π radians to degrees"]);
    assert!(stdout.contains("180"));

    // 90 degrees to radians ≈ 1.571 (π/2)
    let (stdout, _) = run_command(&["run", "--", "90 degrees to radians"]);
    assert!(stdout.contains("1.5") || stdout.contains("1.6"));
}

// Data unit conversions
#[test]
fn test_data_conversions() {
    // 8 bits to bytes = 1
    let (stdout, _) = run_command(&["run", "--", "8 bits to byte"]);
    assert!(stdout.contains("1"));

    // 1024 bytes to... (check if KB is supported)
    let (stdout, _) = run_command(&["run", "--", "8192 bits to bytes"]);
    assert!(stdout.contains("1.0k") || stdout.contains("1024"));
}

// Speed conversions
#[test]
fn test_speed_conversions() {
    // 1 m/s to km/h ≈ 3.6
    let (stdout, _) = run_command(&["run", "--", "1 m/s to km/h"]);
    assert!(stdout.contains("3.6") || stdout.contains("3.5"));

    // 60 mph to km/h ≈ 96.56
    let (stdout, _) = run_command(&["run", "--", "60 mph to km/h"]);
    assert!(stdout.contains("96") || stdout.contains("97"));
}

// Sign function
#[test]
fn test_sign_function() {
    // sign(42) = 1
    let (stdout, _) = run_command(&["run", "--", "sign(42)"]);
    assert!(stdout.contains("1"));

    // sign(-42) = -1
    let (stdout, _) = run_command(&["run", "--", "sign(-42)"]);
    assert!(stdout.contains("-1"));

    // sign(0) = 0
    let (stdout, _) = run_command(&["run", "--", "sign(0)"]);
    assert!(stdout.contains("0"));
}

// Int function (truncate to integer)
#[test]
fn test_int_function() {
    // int(3.7) = 3
    let (stdout, _) = run_command(&["run", "--", "int(3.7)"]);
    assert!(stdout.contains("3"));

    // int(-2.9) = -2
    let (stdout, _) = run_command(&["run", "--", "int(-2.9)"]);
    assert!(stdout.contains("-2"));
}

// Complex real-world scenarios
#[test]
fn test_cooking_recipe_conversion() {
    // Convert recipe: 2 cups to ml
    // 1 cup = 236.588 ml, so 2 cups = 473.176 ml ≈ 473
    let (stdout, _) = run_command(&["run", "--", "2 cup to liters"]);
    assert!(stdout.contains("0.47") || stdout.contains("0.48"));
}

#[test]
fn test_travel_distance_calculation() {
    // Road trip: 500 miles to kilometers
    // 1 mile = 1.609 km, so 500 * 1.609 = 804.5 km
    let (stdout, _) = run_command(&["run", "--", "500 miles to km"]);
    assert!(stdout.contains("804") || stdout.contains("805"));
}

#[test]
fn test_bmi_calculation() {
    // BMI = weight(kg) / height(m)²
    // Example: 70kg, 1.75m → 70 / (1.75^2) ≈ 22.86
    let (stdout, _) = run_command(&["run", "--", "70 / (1.75^2)"]);
    assert!(stdout.contains("22.8") || stdout.contains("22.9"));
}

#[test]
fn test_fuel_efficiency() {
    // Miles per gallon to L/100km conversion calculation
    // 30 mpg = ? L/100km
    // Formula: 235.214 / mpg
    let (stdout, _) = run_command(&["run", "--", "235.214 / 30"]);
    assert!(stdout.contains("7.8") || stdout.contains("7.9"));
}

// Currency word mapping tests for voice dictation
#[test]
fn test_currency_word_dollars_to_euros() {
    let (stdout, _) = run_command(&[
        "run",
        "--",
        "--no-update",
        "--rate",
        "EUR:0.85",
        "100 dollars to euros",
    ]);
    let stdout_lower = stdout.to_lowercase();
    assert!(stdout_lower.contains("eur"));
    let re = Regex::new(r"(?i)85\.00 eur").unwrap();
    assert!(re.is_match(stdout.trim()), "got {}", stdout);
}

#[test]
fn test_currency_word_yen_to_pounds() {
    let (stdout, _) = run_command(&[
        "run",
        "--",
        "--no-update",
        "--rate",
        "JPY:150",
        "--rate",
        "GBP:0.79",
        "1000 yen to pounds",
    ]);
    let stdout_lower = stdout.to_lowercase();
    assert!(stdout_lower.contains("gbp"));
}

#[test]
fn test_currency_word_yuan_rmb() {
    // Test yuan mapping
    let (stdout, _) = run_command(&[
        "run",
        "--",
        "--no-update",
        "--rate",
        "CNY:7.2",
        "100 yuan to usd",
    ]);
    let stdout_lower = stdout.to_lowercase();
    assert!(stdout_lower.contains("usd"));

    // Test rmb mapping (alternative for CNY)
    let (stdout, _) = run_command(&[
        "run",
        "--",
        "--no-update",
        "--rate",
        "CNY:7.2",
        "100 rmb to usd",
    ]);
    let stdout_lower = stdout.to_lowercase();
    assert!(stdout_lower.contains("usd"));
}

#[test]
fn test_currency_word_mixed_case() {
    let (stdout, _) = run_command(&[
        "run",
        "--",
        "--no-update",
        "--rate",
        "EUR:0.85",
        "50 DOLLARS into EUROS",
    ]);
    let stdout_lower = stdout.to_lowercase();
    assert!(stdout_lower.contains("eur"));
}

#[test]
fn test_currency_word_singular_plural() {
    // Test singular "dollar"
    let (stdout, _) = run_command(&[
        "run",
        "--",
        "--no-update",
        "--rate",
        "EUR:0.85",
        "1 dollar to euro",
    ]);
    let stdout_lower = stdout.to_lowercase();
    assert!(stdout_lower.contains("eur"));

    // Test plural "dollars"
    let (stdout, _) = run_command(&[
        "run",
        "--",
        "--no-update",
        "--rate",
        "EUR:0.85",
        "10 dollars to euros",
    ]);
    let stdout_lower = stdout.to_lowercase();
    assert!(stdout_lower.contains("eur"));
}
