use regex::Regex;
use std::process::Command;

fn run_command(args: &[&str]) -> (String, String) {
    let output = Command::new("cargo")
        .args(args)
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
    let (stdout, _) = run_command(&["run", "--", "10 usd in eur"]);
    assert!(stdout.contains("eur"));
    // Check for a number followed by eur
    let re = Regex::new(r"\d+\.\d+ eur").unwrap();
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
    assert!(stdout.contains("8"));
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
    let (stdout, _) = run_command(&["run", "--", "100 usd in eur"]);
    assert!(stdout.contains("eur"));
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
    assert!(stdout.contains("8"));
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
    let (stdout, _) = run_command(&["run", "--", "10 + 200000 usd in jpy"]);
    assert!(stdout.contains("jpy"));
    // Should be 30.8M jpy
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
    let (stdout, _) = run_command(&["run", "--", "1M usd in eur"]);
    assert!(stdout.contains("eur"));
    // 1000000 usd to eur: 1.2M eur
    let re = Regex::new(r"1\.2M eur").unwrap();
    assert!(re.is_match(stdout.trim()));
}

#[test]
fn test_mixed_operations_with_conversion() {
    let (stdout, _) = run_command(&["run", "--", "100 usd * 2 in jpy"]);
    assert!(stdout.contains("jpy"));
    // 200 usd in jpy: 30.8k jpy
    let re = Regex::new(r"30\.8k jpy").unwrap();
    assert!(re.is_match(stdout.trim()));
}

#[test]
fn test_negative_with_conversion() {
    let (stdout, _) = run_command(&["run", "--", "-100 usd in eur"]);
    assert!(stdout.contains("eur"));
    let re = Regex::new(r"-118 eur").unwrap();
    assert!(re.is_match(stdout.trim()));
}

#[test]
fn test_history_commands_dont_add_to_history() {
    let config = numby::config::Config::default();
    let registry = numby::evaluator::AgentRegistry::new(&config)
        .expect("Failed to initialize agent registry");
    let mut state = numby::models::AppState::builder(&config).build();
    *state.history.write().unwrap() = vec![10.0, 20.0, 30.0];

    // Test sum command
    let result = registry.evaluate("sum", &mut state);
    assert_eq!(result, Some(("60".to_string(), true)));
    // History should still have 3 items (not 4)
    assert_eq!(state.history.read().unwrap().len(), 3);

    // Test average command
    let result = registry.evaluate("average", &mut state);
    assert_eq!(result, Some(("20".to_string(), true)));
    // History should still have 3 items
    assert_eq!(state.history.read().unwrap().len(), 3);

    // Test prev command
    let result = registry.evaluate("prev", &mut state);
    assert_eq!(result, Some(("30".to_string(), true)));
    // History should still have 3 items
    assert_eq!(state.history.read().unwrap().len(), 3);

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
    let registry = numby::evaluator::AgentRegistry::new(&config)
        .expect("Failed to initialize agent registry");
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

    // Now simulate actual execution of sum (should not add sum result to history)
    let result2 = registry.evaluate("sum", &mut state);
    assert_eq!(result2, Some(("180".to_string(), true)));
    // History should still have 3 items
    assert_eq!(state.history.read().unwrap().len(), 3);
    assert_eq!(*state.history.read().unwrap(), vec![40.0, 50.0, 90.0]);
}
