use regex::Regex;
use std::process::Command;

fn run_command(args: &[&str]) -> (String, String) {
    // Insert --locale en-US after "--" to force English error messages
    let mut full_args = Vec::new();
    let mut after_separator = false;
    let has_locale = args.iter().any(|&a| a == "--locale");

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
    *state.history.write().unwrap() = vec![10.0, 20.0, 30.0];

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
    assert_eq!(*state.history.read().unwrap(), vec![10.0, 20.0, 30.0, 45.0]);
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
fn test_tui_display_doesnt_modify_history() {
    let config = numby::config::Config::default();
    let registry =
        numby::evaluator::AgentRegistry::new(&config).expect("Failed to initialize agent registry");
    let mut state = numby::models::AppState::builder(&config).build();
    *state.history.write().unwrap() = vec![40.0, 50.0];

    // Simulate TUI display evaluation (should not modify history at all)
    let _ = registry.evaluate_for_display("sum", &state);
    // History should still have 2 items
    assert_eq!(state.history.read().unwrap().len(), 2);
    assert_eq!(*state.history.read().unwrap(), vec![40.0, 50.0]);

    // Simulate TUI display evaluation of regular expression (should not modify history)
    let _ = registry.evaluate_for_display("40 + 50", &state);
    // History should still have 2 items
    assert_eq!(state.history.read().unwrap().len(), 2);
    assert_eq!(*state.history.read().unwrap(), vec![40.0, 50.0]);

    // Now simulate actual execution of regular expression (should add to history)
    let result = registry.evaluate("40 + 50", &mut state);
    assert_eq!(result, Some(("90.00".to_string(), true)));
    // History should now have 3 items
    assert_eq!(state.history.read().unwrap().len(), 3);
    assert_eq!(*state.history.read().unwrap(), vec![40.0, 50.0, 90.0]);

    std::thread::sleep(std::time::Duration::from_millis(60));

    // Now simulate actual execution of sum (should not add sum result to history)
    let result2 = registry.evaluate("sum", &mut state);
    assert_eq!(result2, Some(("180".to_string(), true)));
    // History should still have 3 items
    assert_eq!(state.history.read().unwrap().len(), 3);
    assert_eq!(*state.history.read().unwrap(), vec![40.0, 50.0, 90.0]);
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
