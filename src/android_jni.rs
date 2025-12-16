//! JNI bindings for Android integration
//!
//! This module provides JNI-compatible wrappers around the existing C FFI functions
//! for use with Android/Kotlin applications.

#![cfg(feature = "android")]

use jni::objects::{JClass, JObject, JString, JValue};
use jni::sys::{jdouble, jint, jlong};
use jni::JNIEnv;
use std::ffi::CString;

use crate::config::Config;
use crate::models::AppState;

/// Helper to convert JString to Rust String
fn jstring_to_string(env: &mut JNIEnv, jstr: &JString) -> Option<String> {
    if jstr.is_null() {
        return None;
    }
    env.get_string(jstr).ok().map(|s| s.into())
}

/// Create a new Numby context
///
/// Returns a pointer to the context as a long
#[no_mangle]
pub extern "system" fn Java_com_numby_NumbyWrapper_contextNew(
    _env: JNIEnv,
    _class: JClass,
) -> jlong {
    let config = Config::default();
    let state = Box::new(AppState::builder(&config).build());
    Box::into_raw(state) as jlong
}

/// Free the Numby context
#[no_mangle]
pub extern "system" fn Java_com_numby_NumbyWrapper_contextFree(
    _env: JNIEnv,
    _class: JClass,
    ctx: jlong,
) {
    if ctx != 0 {
        unsafe {
            drop(Box::from_raw(ctx as *mut AppState));
        }
    }
}

/// Evaluate an expression
///
/// Returns an EvaluationResult object with value, formatted, unit, and error fields
#[no_mangle]
pub extern "system" fn Java_com_numby_NumbyWrapper_evaluate<'local>(
    mut env: JNIEnv<'local>,
    _class: JClass<'local>,
    ctx: jlong,
    input: JString<'local>,
) -> JObject<'local> {
    // Get the EvaluationResult class
    let result_class = match env.find_class("com/numby/EvaluationResult") {
        Ok(c) => c,
        Err(_) => return JObject::null(),
    };

    // Default error result
    let create_error_result = |env: &mut JNIEnv<'local>, error: &str| -> JObject<'local> {
        let error_str = env.new_string(error).unwrap_or_else(|_| JObject::null().into());
        env.new_object(
            &result_class,
            "(DLjava/lang/String;Ljava/lang/String;Ljava/lang/String;)V",
            &[
                JValue::Double(0.0),
                JValue::Object(&JObject::null()),
                JValue::Object(&JObject::null()),
                JValue::Object(&error_str),
            ],
        )
        .unwrap_or_else(|_| JObject::null())
    };

    if ctx == 0 {
        return create_error_result(&mut env, "Invalid context");
    }

    let input_str = match jstring_to_string(&mut env, &input) {
        Some(s) => s,
        None => return create_error_result(&mut env, "Invalid input string"),
    };

    // Validate input size
    if let Err(e) = crate::security::validate_input_size(&input_str) {
        return create_error_result(&mut env, &e);
    }

    let context = unsafe { &mut *(ctx as *mut AppState) };
    let config = Config::default();

    let registry = match crate::evaluator::AgentRegistry::new(&config) {
        Ok(r) => r,
        Err(_) => return create_error_result(&mut env, "Failed to initialize registry"),
    };

    match registry.evaluate(&input_str, context) {
        Some((result_str, _)) => {
            // Parse result_str, e.g., "3.11 miles" -> value=3.11, formatted="3.11 miles", unit="miles"
            let parts: Vec<&str> = result_str.split_whitespace().collect();
            let value = parts
                .first()
                .and_then(|s| crate::conversions::parse_number_with_scale(s))
                .unwrap_or(0.0);

            let formatted = env
                .new_string(&result_str)
                .unwrap_or_else(|_| JObject::null().into());

            let unit = if parts.len() > 1 {
                let unit_str = parts[1..].join(" ");
                env.new_string(&unit_str)
                    .unwrap_or_else(|_| JObject::null().into())
            } else {
                JObject::null().into()
            };

            env.new_object(
                &result_class,
                "(DLjava/lang/String;Ljava/lang/String;Ljava/lang/String;)V",
                &[
                    JValue::Double(value),
                    JValue::Object(&formatted),
                    JValue::Object(&unit),
                    JValue::Object(&JObject::null()),
                ],
            )
            .unwrap_or_else(|_| JObject::null())
        }
        None => create_error_result(&mut env, "Evaluation failed"),
    }
}

/// Set a variable in the context
#[no_mangle]
pub extern "system" fn Java_com_numby_NumbyWrapper_setVariable(
    mut env: JNIEnv,
    _class: JClass,
    ctx: jlong,
    name: JString,
    value: jdouble,
    unit: JString,
) -> jint {
    if ctx == 0 {
        return -1;
    }

    let name_str = match jstring_to_string(&mut env, &name) {
        Some(s) => s,
        None => return -1,
    };

    let unit_str = jstring_to_string(&mut env, &unit);

    let context = unsafe { &mut *(ctx as *mut AppState) };
    match context.set_variable(name_str, value, unit_str) {
        Ok(_) => 0,
        Err(_) => -1,
    }
}

/// Load configuration from a file path
#[no_mangle]
pub extern "system" fn Java_com_numby_NumbyWrapper_loadConfig(
    mut env: JNIEnv,
    _class: JClass,
    ctx: jlong,
    path: JString,
) -> jint {
    if ctx == 0 {
        return -1;
    }

    let path_str = match jstring_to_string(&mut env, &path) {
        Some(s) => s,
        None => return -1,
    };

    // Validate path length
    if path_str.len() > 4096 {
        return -1;
    }

    // Validate path to prevent path traversal
    let validated_path = match crate::security::validate_file_path(&path_str) {
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

            match serde_json::from_str::<Config>(&contents) {
                Ok(config) => {
                    let context = unsafe { &mut *(ctx as *mut AppState) };
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
                    // Store the config path for later use (currency rate saving)
                    context.config_override_path = Some(path_str.clone());
                    // Set global config path override for load_config() calls
                    crate::config::set_config_path_override(&path_str);
                    0
                }
                Err(_) => -1,
            }
        }
        Err(_) => -1,
    }
}

/// Set the locale
#[no_mangle]
pub extern "system" fn Java_com_numby_NumbyWrapper_setLocale(
    mut env: JNIEnv,
    _class: JClass,
    _ctx: jlong,
    locale: JString,
) -> jint {
    let locale_str = match jstring_to_string(&mut env, &locale) {
        Some(s) => s,
        None => return -1,
    };

    match crate::i18n::set_locale(&locale_str) {
        Ok(_) => 0,
        Err(_) => -1,
    }
}

/// Get the current locale
#[no_mangle]
pub extern "system" fn Java_com_numby_NumbyWrapper_getLocale<'local>(
    mut env: JNIEnv<'local>,
    _class: JClass<'local>,
) -> JString<'local> {
    let locale = crate::i18n::get_locale();
    env.new_string(locale.to_string())
        .unwrap_or_else(|_| JObject::null().into())
}

/// Get the number of available locales
#[no_mangle]
pub extern "system" fn Java_com_numby_NumbyWrapper_getLocalesCount(
    _env: JNIEnv,
    _class: JClass,
) -> jint {
    crate::i18n::AVAILABLE_LOCALES.len() as jint
}

/// Get locale code at index
#[no_mangle]
pub extern "system" fn Java_com_numby_NumbyWrapper_getLocaleCode<'local>(
    mut env: JNIEnv<'local>,
    _class: JClass<'local>,
    index: jint,
) -> JString<'local> {
    let locales = crate::i18n::AVAILABLE_LOCALES;
    if index < 0 || index >= locales.len() as jint {
        return JObject::null().into();
    }

    let (locale, _) = locales[index as usize];
    env.new_string(locale)
        .unwrap_or_else(|_| JObject::null().into())
}

/// Get locale display name at index
#[no_mangle]
pub extern "system" fn Java_com_numby_NumbyWrapper_getLocaleName<'local>(
    mut env: JNIEnv<'local>,
    _class: JClass<'local>,
    index: jint,
) -> JString<'local> {
    let locales = crate::i18n::AVAILABLE_LOCALES;
    if index < 0 || index >= locales.len() as jint {
        return JObject::null().into();
    }

    let (_, display_name) = locales[index as usize];
    env.new_string(display_name)
        .unwrap_or_else(|_| JObject::null().into())
}

/// Clear history
#[no_mangle]
pub extern "system" fn Java_com_numby_NumbyWrapper_clearHistory(
    _env: JNIEnv,
    _class: JClass,
    ctx: jlong,
) -> jint {
    if ctx == 0 {
        return -1;
    }

    let context = unsafe { &mut *(ctx as *mut AppState) };
    match context.history.write() {
        Ok(mut history) => {
            history.clear();
            0
        }
        Err(_) => -1,
    }
}

/// Clear variables
#[no_mangle]
pub extern "system" fn Java_com_numby_NumbyWrapper_clearVariables(
    _env: JNIEnv,
    _class: JClass,
    ctx: jlong,
) -> jint {
    if ctx == 0 {
        return -1;
    }

    let context = unsafe { &mut *(ctx as *mut AppState) };
    match context.variables.write() {
        Ok(mut variables) => {
            variables.clear();
            0
        }
        Err(_) => -1,
    }
}

/// Get history count
#[no_mangle]
pub extern "system" fn Java_com_numby_NumbyWrapper_getHistoryCount(
    _env: JNIEnv,
    _class: JClass,
    ctx: jlong,
) -> jint {
    if ctx == 0 {
        return -1;
    }

    let context = unsafe { &*(ctx as *const AppState) };
    match context.history.read() {
        Ok(history) => history.len() as jint,
        Err(_) => -1,
    }
}

/// Set currency rates from JSON data
#[no_mangle]
pub extern "system" fn Java_com_numby_NumbyWrapper_setCurrencyRatesJson(
    mut env: JNIEnv,
    _class: JClass,
    ctx: jlong,
    json_data: JString,
) -> jint {
    if ctx == 0 {
        return -1;
    }

    let json_str = match jstring_to_string(&mut env, &json_data) {
        Some(s) => s,
        None => return -1,
    };

    // Parse JSON in the same format as the currency API
    #[derive(serde::Deserialize)]
    struct CurrencyApiResponse {
        date: String,
        usd: std::collections::HashMap<String, f64>,
    }

    let api_response: CurrencyApiResponse = match serde_json::from_str(&json_str) {
        Ok(r) => r,
        Err(_) => return -1,
    };

    let api_date = api_response.date.clone();

    // Convert to uppercase keys
    let mut rates: std::collections::HashMap<String, f64> = std::collections::HashMap::new();
    rates.insert("USD".to_string(), 1.0);
    for (currency_code, rate) in api_response.usd {
        rates.insert(currency_code.to_uppercase(), rate);
    }

    // Update context
    let context = unsafe { &mut *(ctx as *mut AppState) };
    context.rates = rates.clone();

    // Save to config file if override path is set
    if let Some(ref config_path) = context.config_override_path {
        let path = std::path::Path::new(config_path);
        let _ = crate::config::update_currency_rates_at_path(path, rates, api_date);
    } else {
        // Save to default config path
        let config_path = crate::config::get_config_path();
        let _ = crate::config::update_currency_rates_at_path(&config_path, rates, api_date);
    }

    0
}

/// Check if currency rates are stale
#[no_mangle]
pub extern "system" fn Java_com_numby_NumbyWrapper_areRatesStale(
    _env: JNIEnv,
    _class: JClass,
) -> jint {
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

/// Get the rates update date
#[no_mangle]
pub extern "system" fn Java_com_numby_NumbyWrapper_getRatesUpdateDate<'local>(
    mut env: JNIEnv<'local>,
    _class: JClass<'local>,
) -> JString<'local> {
    let config = crate::config::load_config();
    match config.rates_updated_at {
        Some(date) => env
            .new_string(&date)
            .unwrap_or_else(|_| JObject::null().into()),
        None => JObject::null().into(),
    }
}

/// Get the API rates date
#[no_mangle]
pub extern "system" fn Java_com_numby_NumbyWrapper_getApiRatesDate<'local>(
    mut env: JNIEnv<'local>,
    _class: JClass<'local>,
) -> JString<'local> {
    let config = crate::config::load_config();
    match config.api_rates_date {
        Some(date) => env
            .new_string(&date)
            .unwrap_or_else(|_| JObject::null().into()),
        None => JObject::null().into(),
    }
}

/// Get the default config path
#[no_mangle]
pub extern "system" fn Java_com_numby_NumbyWrapper_getDefaultConfigPath<'local>(
    mut env: JNIEnv<'local>,
    _class: JClass<'local>,
) -> JString<'local> {
    let path = crate::config::get_config_path();
    env.new_string(path.to_string_lossy().to_string())
        .unwrap_or_else(|_| JObject::null().into())
}

/// Set the global config path override (call this early on Android)
#[no_mangle]
pub extern "system" fn Java_com_numby_NumbyWrapper_setConfigPath(
    mut env: JNIEnv,
    _class: JClass,
    path: JString,
) -> jint {
    let path_str = match jstring_to_string(&mut env, &path) {
        Some(s) => s,
        None => return -1,
    };

    crate::config::set_config_path_override(&path_str);
    0
}
