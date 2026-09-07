use numby::{config::Config, evaluator::AgentRegistry, models::AppState};

#[test]
fn data_rates_and_units_use_dimensions_and_preserve_case() {
    let config = Config {
        number_format: "precision".into(),
        number_max_decimals: 6,
        ..Config::default()
    };
    let registry = AgentRegistry::new(&config).unwrap();
    let mut state = AppState::builder(&config).build();
    for (input, expected) in [
        ("3 Gb / 15 Mbps", "200 seconds"),
        ("3GB / 15Mbps", "1600 seconds"),
        ("3 Gb / 15 Mb/s", "200 seconds"),
        ("1 MB in bits", "8000000 bits"),
        ("1 Mb in bytes", "125000 bytes"),
        ("1 GiB in MiB", "1024 MiB"),
        ("8 b in B", "1 B"),
        ("1 B in b", "8 b"),
        ("5b", "5000000000"),
        ("3 Gb / 15 Mb", "200"),
        ("3 GB / 2 minutes in Mbps", "200 Mbps"),
        ("15 Mbps * 2 minutes in MB", "225 MB"),
        ("2 minutes * 15 Mbps in MB", "225 MB"),
        ("8 Mbps in MBps", "1 MBps"),
        ("0 Gb / 15 Mbps", "0 seconds"),
    ] {
        let result = registry.evaluate(input, &mut state).map(|r| r.0);
        assert_eq!(result.as_deref(), Some(expected), "{input}");
    }
    for input in [
        "3 Gb / 0 Mbps",
        "3 Gb * 15 Mbps",
        "3 Mbps / 15 Gb",
        "3 Gb / 2 meters",
    ] {
        assert!(registry.evaluate(input, &mut state).is_none(), "{input}");
    }
    registry.evaluate("download = 3 GB", &mut state).unwrap();
    registry
        .evaluate("bandwidth = 15 Mbps", &mut state)
        .unwrap();
    assert_eq!(
        registry
            .evaluate("download / bandwidth", &mut state)
            .unwrap()
            .0,
        "1600 seconds"
    );
}

#[test]
fn data_units_are_highlighted_and_large_input_is_bounded() {
    use numby::highlight::{highlight_spans, HighlightKind};
    let config = Config::default();
    let state = AppState::builder(&config).build();
    for unit in ["Gb", "Mb", "GB", "MB", "Mbps", "MBps", "GiB", "bytes"] {
        let input = format!("3 {unit}");
        assert!(
            highlight_spans(&input, &state, &config)
                .iter()
                .any(|span| span.kind == HighlightKind::Unit
                    && &input[span.start as usize..(span.start + span.len) as usize] == unit),
            "{unit}"
        );
    }
    let input = "x".repeat(numby::security::MAX_HIGHLIGHT_LENGTH + 1);
    assert!(highlight_spans(&input, &state, &config).is_empty());
}

#[test]
fn completion_ffi_handles_unicode_comments_and_invalid_cursor() {
    use std::ffi::{CStr, CString};
    unsafe {
        let ctx = numby::libnumby_context_new();
        for (input, cursor, expected) in [
            ("price = 10\npric", 15, Some("e")),
            ("price = 10\nprincipal = 20\npr", 28, Some("i")),
            ("сумма = 10\nсу", 13, Some("мма")),
            ("price = 10\n// pric", 18, None),
            ("price = 10\npric", 999, None),
            ("price = 10\n😀", 12, None),
        ] {
            let input = CString::new(input).unwrap();
            let suffix = numby::libnumby_complete_variable(ctx, input.as_ptr(), cursor);
            let result = if suffix.is_null() {
                None
            } else {
                Some(CStr::from_ptr(suffix).to_str().unwrap().to_string())
            };
            assert_eq!(result.as_deref(), expected, "{input:?}");
            if !suffix.is_null() {
                numby::libnumby_free_string(suffix);
            }
        }
        numby::libnumby_context_free(ctx);
    }
}

#[test]
fn cli_keeps_word_math_and_completed_variables_but_skips_notes() {
    let output = std::process::Command::new(env!("CARGO_BIN_EXE_numby"))
        .args([
            "--no-update",
            "--locale",
            "en-US",
            "--format",
            "plain",
            "--number-format",
            "precision",
            "Shopping notes\nten plus five\nTwenty MINUS four\nprice = 10\nprice\nprice plus five",
        ])
        .output()
        .unwrap();
    assert!(output.status.success());
    let stdout = String::from_utf8(output.stdout).unwrap();
    let plain = regex::Regex::new(r"\x1b\[[0-9;]*m")
        .unwrap()
        .replace_all(&stdout, "");
    assert_eq!(
        plain.lines().collect::<Vec<_>>(),
        ["15", "16", "10", "10", "15"]
    );
}
