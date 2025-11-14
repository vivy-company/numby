use std::process::Command;

fn run_numby_with_locale(locale: &str, expr: &str) -> (String, String, i32) {
    let output = Command::new("cargo")
        .args(["run", "--quiet", "--", "--locale", locale, expr])
        .output()
        .expect("Failed to execute numby");

    let stdout = String::from_utf8_lossy(&output.stdout).to_string();
    let stderr = String::from_utf8_lossy(&output.stderr).to_string();
    let exit_code = output.status.code().unwrap_or(-1);

    (stdout, stderr, exit_code)
}

fn run_numby(expr: &str) -> (String, String, i32) {
    let output = Command::new("cargo")
        .args(["run", "--quiet", "--", expr])
        .output()
        .expect("Failed to execute numby");

    let stdout = String::from_utf8_lossy(&output.stdout).to_string();
    let stderr = String::from_utf8_lossy(&output.stderr).to_string();
    let exit_code = output.status.code().unwrap_or(-1);

    (stdout, stderr, exit_code)
}

#[test]
fn test_basic_calculation_english() {
    let (stdout, _stderr, exit_code) = run_numby_with_locale("en-US", "2 + 2");
    assert_eq!(exit_code, 0);
    assert!(stdout.contains("4"));
}

#[test]
fn test_basic_calculation_spanish() {
    let (stdout, _stderr, exit_code) = run_numby_with_locale("es", "2 + 2");
    assert_eq!(exit_code, 0);
    assert!(stdout.contains("4"));
}

#[test]
fn test_basic_calculation_chinese() {
    let (stdout, _stderr, exit_code) = run_numby_with_locale("zh-CN", "2 + 2");
    assert_eq!(exit_code, 0);
    assert!(stdout.contains("4"));
}

#[test]
fn test_unit_conversion_english() {
    let (stdout, _stderr, exit_code) = run_numby_with_locale("en-US", "100 meters in feet");
    assert_eq!(exit_code, 0);
    // Should contain the result
    assert!(stdout.contains("feet") || stdout.contains("ft"));
}

#[test]
fn test_unit_conversion_spanish() {
    let (stdout, _stderr, exit_code) = run_numby_with_locale("es", "100 meters in feet");
    assert_eq!(exit_code, 0);
    // Unit conversion still works regardless of locale
    assert!(stdout.contains("feet") || stdout.contains("ft"));
}

#[test]
fn test_unit_conversion_chinese() {
    let (stdout, _stderr, exit_code) = run_numby_with_locale("zh-CN", "100 meters in feet");
    assert_eq!(exit_code, 0);
    // Unit conversion still works regardless of locale
    assert!(stdout.contains("feet") || stdout.contains("ft"));
}

#[test]
fn test_error_message_english() {
    let (stdout, stderr, _exit_code) = run_numby_with_locale("en-US", "invalid!!!syntax");
    // Error should be in English
    let output = format!("{}{}", stdout, stderr);
    assert!(
        output.contains("Error evaluating expression") || output.contains("Error"),
        "Expected English error message, got: {}",
        output
    );
}

#[test]
fn test_error_message_spanish() {
    let (stdout, stderr, _exit_code) = run_numby_with_locale("es", "invalid!!!syntax");
    // Error should be in Spanish
    let output = format!("{}{}", stdout, stderr);
    assert!(
        output.contains("Error al evaluar") || output.contains("expresión"),
        "Expected Spanish error message, got: {}",
        output
    );
}

#[test]
fn test_error_message_chinese() {
    let (stdout, stderr, _exit_code) = run_numby_with_locale("zh-CN", "invalid!!!syntax");
    // Error should be in Chinese
    let output = format!("{}{}", stdout, stderr);
    assert!(
        output.contains("求值") || output.contains("出错") || output.contains("表达式"),
        "Expected Chinese error message, got: {}",
        output
    );
}

#[test]
fn test_version_english() {
    let output = Command::new("cargo")
        .args(["run", "--quiet", "--", "--locale", "en-US", "--version"])
        .output()
        .expect("Failed to execute numby");

    let stdout = String::from_utf8_lossy(&output.stdout).to_string();
    assert!(stdout.contains("v") || stdout.contains("0.1.0"));
}

#[test]
fn test_version_spanish() {
    let output = Command::new("cargo")
        .args(["run", "--quiet", "--", "--locale", "es", "--version"])
        .output()
        .expect("Failed to execute numby");

    let stdout = String::from_utf8_lossy(&output.stdout).to_string();
    // Version output should be same regardless of locale (just the version number)
    assert!(stdout.contains("v") || stdout.contains("0.1.0"));
}

#[test]
fn test_version_chinese() {
    let output = Command::new("cargo")
        .args(["run", "--quiet", "--", "--locale", "zh-CN", "--version"])
        .output()
        .expect("Failed to execute numby");

    let stdout = String::from_utf8_lossy(&output.stdout).to_string();
    // Version output should be same regardless of locale (just the version number)
    assert!(stdout.contains("v") || stdout.contains("0.1.0"));
}

#[test]
fn test_default_locale_fallback() {
    // Test without specifying locale - should default to system or en-US
    let (stdout, _stderr, exit_code) = run_numby("5 * 10");
    assert_eq!(exit_code, 0);
    assert!(stdout.contains("50"));
}

#[test]
fn test_complex_expression_all_locales() {
    let test_cases = vec![
        ("en-US", "10 + 20 * 2"),
        ("es", "10 + 20 * 2"),
        ("zh-CN", "10 + 20 * 2"),
    ];

    for (locale, expr) in test_cases {
        let (stdout, _stderr, exit_code) = run_numby_with_locale(locale, expr);
        assert_eq!(exit_code, 0, "Failed for locale: {}", locale);
        assert!(
            stdout.contains("50"),
            "Incorrect result for locale: {}",
            locale
        );
    }
}

#[test]
fn test_percentage_calculation_all_locales() {
    let test_cases = vec![
        ("en-US", "50% of 100"),
        ("es", "50% of 100"),
        ("zh-CN", "50% of 100"),
    ];

    for (locale, expr) in test_cases {
        let (stdout, _stderr, exit_code) = run_numby_with_locale(locale, expr);
        assert_eq!(exit_code, 0, "Failed for locale: {}", locale);
        assert!(
            stdout.contains("50"),
            "Incorrect result for locale: {}",
            locale
        );
    }
}

// Tests for newly added languages

#[test]
fn test_basic_calculation_french() {
    let (stdout, _stderr, exit_code) = run_numby_with_locale("fr", "2 + 2");
    assert_eq!(exit_code, 0);
    assert!(stdout.contains("4"));
}

#[test]
fn test_basic_calculation_german() {
    let (stdout, _stderr, exit_code) = run_numby_with_locale("de", "2 + 2");
    assert_eq!(exit_code, 0);
    assert!(stdout.contains("4"));
}

#[test]
fn test_basic_calculation_japanese() {
    let (stdout, _stderr, exit_code) = run_numby_with_locale("ja", "2 + 2");
    assert_eq!(exit_code, 0);
    assert!(stdout.contains("4"));
}

#[test]
fn test_basic_calculation_russian() {
    let (stdout, _stderr, exit_code) = run_numby_with_locale("ru", "2 + 2");
    assert_eq!(exit_code, 0);
    assert!(stdout.contains("4"));
}

#[test]
fn test_basic_calculation_belarusian() {
    let (stdout, _stderr, exit_code) = run_numby_with_locale("be", "2 + 2");
    assert_eq!(exit_code, 0);
    assert!(stdout.contains("4"));
}

#[test]
fn test_basic_calculation_chinese_traditional() {
    let (stdout, _stderr, exit_code) = run_numby_with_locale("zh-TW", "2 + 2");
    assert_eq!(exit_code, 0);
    assert!(stdout.contains("4"));
}

#[test]
fn test_all_nine_locales() {
    let locales = vec!["en-US", "es", "zh-CN", "zh-TW", "fr", "de", "ja", "ru", "be"];

    for locale in locales {
        let (stdout, _stderr, exit_code) = run_numby_with_locale(locale, "10 * 5");
        assert_eq!(exit_code, 0, "Failed for locale: {}", locale);
        assert!(
            stdout.contains("50"),
            "Incorrect result for locale: {}",
            locale
        );
    }
}
