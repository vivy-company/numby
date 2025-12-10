//! # Numby Library
//!
//! This library provides the core functionality for the Numby natural language calculator.
//!
//! ## Modules
//!
//! - `config`: Configuration loading and management.
//! - `evaluator`: Expression evaluation and conversions.
//! - `models`: Data structures and state management.
//! - `parser`: Parsing utilities and regex replacements.
//! - `conversions`: Unit and currency conversion functions.
//! - `prettify`: Number formatting for display.
//! - `security`: Path validation and input sanitization.
//! - `i18n`: Internationalization and localization support.

pub mod config;
pub mod conversions;
pub mod currency_fetcher;
pub mod evaluator;
pub mod i18n;
pub mod models;
pub mod parser;
pub mod prettify;
pub mod security;

#[cfg(test)]
mod event_tests {
    use crate::config::Config;
    use crate::evaluator::{EventSubscriber, StateEvent};
    use crate::models::AppState;
    use std::sync::atomic::{AtomicUsize, Ordering};
    use std::sync::Arc;

    struct TestSubscriber {
        event_count: Arc<AtomicUsize>,
    }

    impl EventSubscriber for TestSubscriber {
        fn on_event(&self, _event: &StateEvent) {
            self.event_count.fetch_add(1, Ordering::SeqCst);
        }
    }

    #[test]
    fn test_event_publishing() {
        let config = Config::default();
        let state = AppState::builder(&config).build();

        let event_count = Arc::new(AtomicUsize::new(0));
        let subscriber = Arc::new(TestSubscriber {
            event_count: event_count.clone(),
        });

        let _ = state.subscribe(subscriber);

        // Publish an event
        state.publish_event(StateEvent::HistoryAdded(42.0));

        assert_eq!(event_count.load(Ordering::SeqCst), 1);
    }

    #[test]
    fn test_cache_invalidation_on_variable_change() {
        let config = Config::default();
        let state = AppState::builder(&config).build();

        // Set a cache value
        state
            .cache
            .set_display("test_key".to_string(), Some("cached_value".to_string()));

        // Verify it's cached
        assert_eq!(
            state.cache.get_display("test_key"),
            Some(Some("cached_value".to_string()))
        );

        // Trigger a variable change event
        state.publish_event(StateEvent::VariableChanged("test".to_string()));

        // Cache should be invalidated for prefix "test"
        // Keys that don't start with "test" should still be there
        state
            .cache
            .set_display("other_key".to_string(), Some("other_value".to_string()));

        // Set a cache with "test" prefix
        state
            .cache
            .set_display("test_key".to_string(), Some("new_value".to_string()));

        // Trigger event
        state.publish_event(StateEvent::VariableChanged("test".to_string()));

        // The key with "test" prefix should be cleared
        assert_eq!(state.cache.get_display("test_key"), None);

        // But other keys should remain
        assert_eq!(
            state.cache.get_display("other_key"),
            Some(Some("other_value".to_string()))
        );
    }

    #[test]
    fn test_set_variable_publishes_event() {
        let config = Config::default();
        let state = AppState::builder(&config).build();

        let event_count = Arc::new(AtomicUsize::new(0));
        let subscriber = Arc::new(TestSubscriber {
            event_count: event_count.clone(),
        });

        let _ = state.subscribe(subscriber);

        // Setting a variable should publish an event
        let _ = state.set_variable("x".to_string(), 10.0, None);

        assert_eq!(event_count.load(Ordering::SeqCst), 1);
    }

    #[test]
    fn test_add_history_publishes_event() {
        let config = Config::default();
        let state = AppState::builder(&config).build();

        let event_count = Arc::new(AtomicUsize::new(0));
        let subscriber = Arc::new(TestSubscriber {
            event_count: event_count.clone(),
        });

        let _ = state.subscribe(subscriber);

        // Adding to history should publish an event
        let _ = state.add_history(42.0, None);

        assert_eq!(event_count.load(Ordering::SeqCst), 1);
    }

    #[test]
    fn test_multiple_subscribers() {
        let config = Config::default();
        let state = AppState::builder(&config).build();

        let count1 = Arc::new(AtomicUsize::new(0));
        let count2 = Arc::new(AtomicUsize::new(0));

        let sub1 = Arc::new(TestSubscriber {
            event_count: count1.clone(),
        });
        let sub2 = Arc::new(TestSubscriber {
            event_count: count2.clone(),
        });

        let _ = state.subscribe(sub1);
        let _ = state.subscribe(sub2);

        state.publish_event(StateEvent::HistoryAdded(42.0));

        assert_eq!(count1.load(Ordering::SeqCst), 1);
        assert_eq!(count2.load(Ordering::SeqCst), 1);
    }
}

// C FFI API for Swift integration

use once_cell::sync::Lazy;
use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use std::path::PathBuf;
use std::sync::Mutex;

static CONFIG_OVERRIDE_PATH: Lazy<Mutex<Option<PathBuf>>> = Lazy::new(|| Mutex::new(None));

fn set_config_override_path(path: PathBuf) {
    if let Ok(mut guard) = CONFIG_OVERRIDE_PATH.lock() {
        *guard = Some(path);
    }
}

fn get_config_override_path() -> Option<PathBuf> {
    CONFIG_OVERRIDE_PATH
        .lock()
        .ok()
        .and_then(|guard| guard.clone())
}

type NumbyContext = crate::models::AppState; // Use AppState as context

#[no_mangle]
pub extern "C" fn libnumby_context_new() -> *mut NumbyContext {
    let config = crate::config::Config::default();
    Box::into_raw(Box::new(crate::models::AppState::builder(&config).build()))
}

/// # Safety
///
/// This function dereferences raw pointers and must be called with valid pointers.
#[no_mangle]
pub unsafe extern "C" fn libnumby_evaluate(
    ctx: *mut NumbyContext,
    input: *const c_char,
    out_formatted: *mut *mut c_char,
    out_unit: *mut *mut c_char,
    out_error: *mut *mut c_char,
) -> f64 {
    // Validate all pointers
    if ctx.is_null()
        || input.is_null()
        || out_formatted.is_null()
        || out_unit.is_null()
        || out_error.is_null()
    {
        if !out_error.is_null() {
            if let Ok(s) = CString::new("Invalid null pointer") {
                *out_error = s.into_raw();
            }
        }
        return 0.0;
    }

    // Convert C string to Rust string with validation
    let input_str = match CStr::from_ptr(input).to_str() {
        Ok(s) => s,
        Err(_) => {
            if let Ok(s) = CString::new("Invalid UTF-8 input") {
                *out_error = s.into_raw();
            }
            return 0.0;
        }
    };

    // Validate input size
    if let Err(e) = crate::security::validate_input_size(input_str) {
        if let Ok(s) = CString::new(e) {
            *out_error = s.into_raw();
        }
        return 0.0;
    }

    let context = &mut *ctx;
    let config = crate::config::Config::default();

    let registry = match crate::evaluator::AgentRegistry::new(&config) {
        Ok(r) => r,
        Err(_) => {
            if let Ok(s) = CString::new("Failed to initialize registry") {
                *out_error = s.into_raw();
            }
            return 0.0;
        }
    };

    match registry.evaluate(input_str, context) {
        Some((result_str, _)) => {
            // Parse result_str, e.g., "3.11 miles" -> value=3.11, formatted="3.11 miles", unit="miles"
            let parts: Vec<&str> = result_str.split_whitespace().collect();
            let value = parts
                .first()
                .and_then(|s| crate::conversions::parse_number_with_scale(s))
                .unwrap_or(0.0);

            // Safe string conversion
            if let Ok(formatted_cstr) = CString::new(result_str.clone()) {
                *out_formatted = formatted_cstr.into_raw();
            }

            if parts.len() > 1 {
                let unit_str = parts[1..].join(" ");
                if let Ok(unit_cstr) = CString::new(unit_str) {
                    *out_unit = unit_cstr.into_raw();
                }
            }

            value
        }
        None => {
            if let Ok(s) = CString::new("Evaluation failed") {
                *out_error = s.into_raw();
            }
            0.0
        }
    }
}

/// # Safety
///
/// This function dereferences raw pointers and must be called with valid pointers.
#[no_mangle]
pub unsafe extern "C" fn libnumby_set_variable(
    ctx: *mut NumbyContext,
    name: *const c_char,
    value: f64,
    unit: *const c_char,
) -> i32 {
    if ctx.is_null() || name.is_null() {
        return -1;
    }

    let name_str = match CStr::from_ptr(name).to_str() {
        Ok(s) => s,
        Err(_) => return -1,
    };

    let unit_str = if unit.is_null() {
        None
    } else {
        CStr::from_ptr(unit).to_str().ok().map(|s| s.to_string())
    };

    let context = &mut *ctx;
    match context.set_variable(name_str.to_string(), value, unit_str) {
        Ok(_) => 0,
        Err(_) => -1,
    }
}

/// # Safety
///
/// This function dereferences raw pointers and must be called with valid pointers.
#[no_mangle]
pub unsafe extern "C" fn libnumby_load_config(ctx: *mut NumbyContext, path: *const c_char) -> i32 {
    if ctx.is_null() || path.is_null() {
        return -1;
    }

    let path_str = match CStr::from_ptr(path).to_str() {
        Ok(s) => s,
        Err(_) => return -1,
    };

    // Validate path length
    if path_str.len() > 4096 {
        return -1;
    }

    // Validate path to prevent path traversal
    let validated_path = match crate::security::validate_file_path(path_str) {
        Ok(p) => p,
        Err(_) => return -1,
    };

    // Load config from validated file
    match std::fs::read_to_string(&validated_path) {
        Ok(contents) => {
            // Check file size limit (1MB max for config)
            if contents.len() > 1_048_576 {
                return -1;
            }

            match serde_json::from_str::<crate::config::Config>(&contents) {
                Ok(config) => {
                    let context = &mut *ctx;
                    // Update context with new config values
                    context.length_units = config.length_units;
                    context.time_units = config.time_units;
                    context.temperature_units = config.temperature_units;
                    context.area_units = config.area_units;
                    context.volume_units = config.volume_units;
                    context.weight_units = config.weight_units;
                    context.angular_units = config.angular_units;
                    context.data_units = config.data_units;
                    context.speed_units = config.speed_units;
                    context.rates = config.currencies;
                    set_config_override_path(validated_path);
                    0
                }
                Err(_) => -1,
            }
        }
        Err(_) => -1,
    }
}

/// # Safety
///
/// This function dereferences raw pointers and must be called with valid pointers.
#[no_mangle]
pub unsafe extern "C" fn libnumby_set_locale(ctx: *mut NumbyContext, locale: *const c_char) -> i32 {
    if ctx.is_null() || locale.is_null() {
        return -1;
    }

    let locale_str = match CStr::from_ptr(locale).to_str() {
        Ok(s) => s,
        Err(_) => return -1,
    };

    // Set the locale using i18n module
    match crate::i18n::set_locale(locale_str) {
        Ok(_) => 0,
        Err(_) => -1,
    }
}

/// Get the current locale
///
/// # Safety
///
/// Returns a C string that must be freed with libnumby_free_string
#[no_mangle]
pub unsafe extern "C" fn libnumby_get_locale() -> *mut c_char {
    let locale = crate::i18n::get_locale();
    CString::new(locale.to_string())
        .map(|s| s.into_raw())
        .unwrap_or(std::ptr::null_mut())
}

/// Get the number of available locales
///
/// # Safety
///
/// This function is safe to call
#[no_mangle]
pub unsafe extern "C" fn libnumby_get_locales_count() -> i32 {
    crate::i18n::AVAILABLE_LOCALES.len() as i32
}

/// Get locale code at index
///
/// # Safety
///
/// Returns a C string that must be freed with libnumby_free_string
#[no_mangle]
pub unsafe extern "C" fn libnumby_get_locale_code(index: i32) -> *mut c_char {
    let locales = crate::i18n::AVAILABLE_LOCALES;
    if index < 0 || index >= locales.len() as i32 {
        return std::ptr::null_mut();
    }

    let (locale, _) = locales[index as usize];
    CString::new(locale)
        .map(|s| s.into_raw())
        .unwrap_or(std::ptr::null_mut())
}

/// Get locale display name at index
///
/// # Safety
///
/// Returns a C string that must be freed with libnumby_free_string
#[no_mangle]
pub unsafe extern "C" fn libnumby_get_locale_name(index: i32) -> *mut c_char {
    let locales = crate::i18n::AVAILABLE_LOCALES;
    if index < 0 || index >= locales.len() as i32 {
        return std::ptr::null_mut();
    }

    let (_, display_name) = locales[index as usize];
    CString::new(display_name)
        .map(|s| s.into_raw())
        .unwrap_or(std::ptr::null_mut())
}

/// # Safety
///
/// This function takes ownership of the raw pointer and frees it.
#[no_mangle]
pub unsafe extern "C" fn libnumby_free_string(s: *mut c_char) {
    if !s.is_null() {
        let _ = CString::from_raw(s);
    }
}

/// # Safety
///
/// This function dereferences raw pointers and must be called with valid pointers.
#[no_mangle]
pub unsafe extern "C" fn libnumby_clear_history(ctx: *mut NumbyContext) -> i32 {
    if ctx.is_null() {
        return -1;
    }

    let context = &mut *ctx;
    match context.history.write() {
        Ok(mut history) => {
            history.clear();
            0
        }
        Err(_) => -1,
    }
}

/// Clear all variables from the context
///
/// # Safety
///
/// This function dereferences raw pointers and must be called with valid pointers.
#[no_mangle]
pub unsafe extern "C" fn libnumby_clear_variables(ctx: *mut NumbyContext) -> i32 {
    if ctx.is_null() {
        return -1;
    }

    let context = &mut *ctx;
    match context.variables.write() {
        Ok(mut variables) => {
            variables.clear();
            0
        }
        Err(_) => -1,
    }
}

/// # Safety
///
/// This function dereferences raw pointers and must be called with valid pointers.
#[no_mangle]
pub unsafe extern "C" fn libnumby_get_history_count(ctx: *mut NumbyContext) -> i32 {
    if ctx.is_null() {
        return -1;
    }

    let context = &*ctx;
    match context.history.read() {
        Ok(history) => history.len() as i32,
        Err(_) => -1,
    }
}

/// # Safety
///
/// This function takes ownership of the raw pointer and frees it.
#[no_mangle]
pub unsafe extern "C" fn libnumby_context_free(ctx: *mut NumbyContext) {
    if !ctx.is_null() {
        drop(Box::from_raw(ctx));
    }
}

/// Fetches latest currency rates from the API and updates the config file
///
/// Returns 0 on success, -1 on failure
/// On success, updates both the config file and the context's rates
///
/// # Safety
///
/// This function dereferences raw pointers and must be called with valid pointers.
#[no_mangle]
pub unsafe extern "C" fn libnumby_update_currency_rates(ctx: *mut NumbyContext) -> i32 {
    if ctx.is_null() {
        return -1;
    }

    // Fetch rates from API
    let (rates, date) = match crate::currency_fetcher::fetch_latest_rates() {
        Ok(result) => result,
        Err(_) => return -1,
    };

    // Determine candidate paths (override first, fallback to default)
    let mut candidate_paths = Vec::new();
    if let Some(path) = get_config_override_path() {
        candidate_paths.push(path);
    }
    let default_path = crate::config::get_config_path();
    if candidate_paths
        .first()
        .map(|p| p != &default_path)
        .unwrap_or(true)
    {
        candidate_paths.push(default_path);
    }

    let mut persisted_path: Option<PathBuf> = None;
    for path in candidate_paths {
        match crate::config::update_currency_rates_at_path(&path, rates.clone(), date.clone()) {
            Ok(_) => {
                persisted_path = Some(path);
                break;
            }
            Err(_) => continue,
        }
    }

    let Some(saved_path) = persisted_path else {
        return -1;
    };

    set_config_override_path(saved_path.clone());

    // Update context with new rates
    let context = &mut *ctx;
    context.rates = rates;

    0
}

/// Returns the default config path used by the Rust core.
#[no_mangle]
pub extern "C" fn libnumby_get_default_config_path() -> *mut c_char {
    let path = crate::config::get_config_path();
    match CString::new(path.to_string_lossy().to_string()) {
        Ok(cstr) => cstr.into_raw(),
        Err(_) => std::ptr::null_mut(),
    }
}

/// Sets currency rates from JSON data provided by the caller (e.g., from Swift URLSession)
///
/// Expected JSON format: {"date": "2025-01-01", "usd": {"eur": 0.92, "gbp": 0.79, ...}}
///
/// Returns 0 on success, -1 on failure
///
/// # Safety
///
/// This function dereferences raw pointers and must be called with valid pointers.
#[no_mangle]
pub unsafe extern "C" fn libnumby_set_currency_rates_json(
    ctx: *mut NumbyContext,
    json_data: *const c_char,
) -> i32 {
    if ctx.is_null() || json_data.is_null() {
        return -1;
    }

    let json_str = match CStr::from_ptr(json_data).to_str() {
        Ok(s) => s,
        Err(_) => return -1,
    };

    // Parse JSON in the same format as the currency API
    #[derive(serde::Deserialize)]
    struct CurrencyApiResponse {
        date: String,
        usd: std::collections::HashMap<String, f64>,
    }

    let api_response: CurrencyApiResponse = match serde_json::from_str(json_str) {
        Ok(r) => r,
        Err(_) => return -1,
    };

    // Convert to uppercase keys
    let mut rates: std::collections::HashMap<String, f64> = std::collections::HashMap::new();
    rates.insert("USD".to_string(), 1.0);
    for (currency_code, rate) in api_response.usd {
        rates.insert(currency_code.to_uppercase(), rate);
    }

    let date = api_response.date;

    // Update config file
    let config_path = get_config_override_path().unwrap_or_else(crate::config::get_config_path);
    if crate::config::update_currency_rates_at_path(&config_path, rates.clone(), date).is_err() {
        return -1;
    }

    // Update context
    let context = &mut *ctx;
    context.rates = rates;

    0
}

/// Checks if currency rates are stale (older than 24 hours)
///
/// Returns 1 if stale, 0 if fresh, -1 on error
///
/// # Safety
///
/// This function is safe to call from C code.
#[no_mangle]
pub extern "C" fn libnumby_are_rates_stale() -> i32 {
    let config = crate::config::load_config();
    match config.rates_updated_at {
        Some(date) => {
            if crate::currency_fetcher::are_rates_stale(&date) {
                1 // Stale
            } else {
                0 // Fresh
            }
        }
        None => 1, // No date = stale
    }
}

/// Gets the last update date for currency rates
///
/// Returns a C string with the date in YYYY-MM-DD format, or null if unavailable
/// Caller must free the returned string with libnumby_free_string
///
/// # Safety
///
/// This function is safe to call from C code.
#[no_mangle]
pub extern "C" fn libnumby_get_rates_update_date() -> *mut c_char {
    let config = crate::config::load_config();
    match config.rates_updated_at {
        Some(date) => {
            if let Ok(cstr) = CString::new(date) {
                cstr.into_raw()
            } else {
                std::ptr::null_mut()
            }
        }
        None => std::ptr::null_mut(),
    }
}

#[cfg(test)]
mod i18n_tests {
    // NOTE: These tests modify global locale state and should be run with:
    // cargo test --lib i18n -- --test-threads=1
    use crate::i18n;

    #[test]
    fn test_locale_detection() {
        // Init with default
        i18n::init_locale(None);
        let locale = i18n::get_locale();
        // Should be either system locale or en-US fallback
        assert!(!locale.to_string().is_empty());
    }

    #[test]
    fn test_init_locale_english() {
        i18n::init_locale(Some("en-US"));
        let locale = i18n::get_locale();
        assert_eq!(locale.to_string(), "en-US");
    }

    #[test]
    fn test_init_locale_spanish() {
        i18n::init_locale(Some("es"));
        let locale = i18n::get_locale();
        assert_eq!(locale.to_string(), "es");
    }

    #[test]
    fn test_init_locale_chinese() {
        i18n::init_locale(Some("zh-CN"));
        let locale = i18n::get_locale();
        assert_eq!(locale.to_string(), "zh-CN");
    }

    #[test]
    fn test_fl_macro_simple() {
        i18n::init_locale(Some("en-US"));
        let msg = crate::fl!("app-description");
        assert!(msg.contains("Numby"));
        assert!(msg.contains("calculator"));
    }

    #[test]
    fn test_fl_macro_with_args() {
        i18n::init_locale(Some("en-US"));
        let msg = crate::fl!("version-output", "version" => "0.1.0");
        assert!(msg.contains("0.1.0"));
    }

    #[test]
    fn test_english_error_message() {
        i18n::init_locale(Some("en-US"));
        let msg = crate::fl!("error-evaluating-expression");
        assert_eq!(msg, "Error evaluating expression");
    }

    #[test]
    fn test_spanish_error_message() {
        i18n::init_locale(Some("es"));
        let msg = crate::fl!("error-evaluating-expression");
        assert_eq!(msg, "Error al evaluar la expresión");
    }

    #[test]
    fn test_chinese_error_message() {
        i18n::init_locale(Some("zh-CN"));
        let msg = crate::fl!("error-evaluating-expression");
        assert_eq!(msg, "求值表达式时出错");
    }

    #[test]
    fn test_english_security_messages() {
        i18n::init_locale(Some("en-US"));
        // Re-check locale was actually set
        assert_eq!(i18n::get_locale().to_string(), "en-US");
        let msg1 = crate::fl!("path-traversal-detected");
        let msg2 = crate::fl!("invalid-path");
        assert_eq!(
            msg1, "Path traversal detected",
            "Expected English, got: {}",
            msg1
        );
        assert_eq!(msg2, "Invalid path", "Expected English, got: {}", msg2);
    }

    #[test]
    fn test_spanish_security_messages() {
        i18n::init_locale(Some("es"));
        assert_eq!(i18n::get_locale().to_string(), "es");
        let msg1 = crate::fl!("path-traversal-detected");
        let msg2 = crate::fl!("invalid-path");
        assert_eq!(
            msg1, "Se detectó un recorrido de ruta",
            "Expected Spanish, got: {}",
            msg1
        );
        assert_eq!(msg2, "Ruta inválida", "Expected Spanish, got: {}", msg2);
    }

    #[test]
    fn test_chinese_security_messages() {
        i18n::init_locale(Some("zh-CN"));
        assert_eq!(i18n::get_locale().to_string(), "zh-CN");
        let msg1 = crate::fl!("path-traversal-detected");
        let msg2 = crate::fl!("invalid-path");
        assert_eq!(msg1, "检测到路径遍历", "Expected Chinese, got: {}", msg1);
        assert_eq!(msg2, "无效路径", "Expected Chinese, got: {}", msg2);
    }

    #[test]
    fn test_english_tui_messages() {
        i18n::init_locale(Some("en-US"));
        assert_eq!(i18n::get_locale().to_string(), "en-US");
        let msg = crate::fl!("commands-help");
        assert!(
            msg.contains("quit"),
            "Expected 'quit' in English message, got: {}",
            msg
        );
        assert!(
            msg.contains("save"),
            "Expected 'save' in English message, got: {}",
            msg
        );
    }

    #[test]
    fn test_spanish_tui_messages() {
        i18n::init_locale(Some("es"));
        assert_eq!(i18n::get_locale().to_string(), "es");
        let msg = crate::fl!("commands-help");
        assert!(
            msg.contains("salir"),
            "Expected 'salir' in Spanish message, got: {}",
            msg
        );
        assert!(
            msg.contains("guardar"),
            "Expected 'guardar' in Spanish message, got: {}",
            msg
        );
    }

    #[test]
    fn test_chinese_tui_messages() {
        i18n::init_locale(Some("zh-CN"));
        assert_eq!(i18n::get_locale().to_string(), "zh-CN");
        let msg = crate::fl!("commands-help");
        assert!(
            msg.contains("退出"),
            "Expected '退出' in Chinese message, got: {}",
            msg
        );
        assert!(
            msg.contains("保存"),
            "Expected '保存' in Chinese message, got: {}",
            msg
        );
    }

    #[test]
    fn test_message_with_variable() {
        i18n::init_locale(Some("en-US"));
        assert_eq!(i18n::get_locale().to_string(), "en-US");
        let msg = crate::fl!("input-too-long", "actual" => "150000", "max" => "100000");
        assert!(msg.contains("150000"));
        assert!(msg.contains("100000"));
        assert!(
            msg.contains("chars"),
            "Expected 'chars' in English message, got: {}",
            msg
        );
    }

    #[test]
    fn test_spanish_message_with_variable() {
        i18n::init_locale(Some("es"));
        assert_eq!(i18n::get_locale().to_string(), "es");
        let msg = crate::fl!("input-too-long", "actual" => "150000", "max" => "100000");
        assert!(msg.contains("150000"));
        assert!(msg.contains("100000"));
        assert!(
            msg.contains("caracteres"),
            "Expected 'caracteres' in Spanish message, got: {}",
            msg
        );
    }

    #[test]
    fn test_chinese_message_with_variable() {
        i18n::init_locale(Some("zh-CN"));
        assert_eq!(i18n::get_locale().to_string(), "zh-CN");
        let msg = crate::fl!("input-too-long", "actual" => "150000", "max" => "100000");
        assert!(msg.contains("150000"));
        assert!(msg.contains("100000"));
        assert!(
            msg.contains("字符"),
            "Expected '字符' in Chinese message, got: {}",
            msg
        );
    }

    #[test]
    fn test_fallback_for_missing_key() {
        i18n::init_locale(Some("en-US"));
        let msg = crate::fl!("non-existent-key");
        // Should return the key itself as fallback
        assert_eq!(msg, "non-existent-key");
    }
}
