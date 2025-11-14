use fluent_bundle::FluentValue;
use fluent_templates::{static_loader, Loader};
use std::cell::RefCell;
use std::collections::HashMap;
use unic_langid::{langid, LanguageIdentifier};

static_loader! {
    static LOCALES = {
        locales: "./locales",
        fallback_language: "en-US",
    };
}

thread_local! {
    static CURRENT_LOCALE: RefCell<LanguageIdentifier> = const { RefCell::new(langid!("en-US")) };
}

/// Set the current locale
#[allow(dead_code)]
pub fn set_locale(locale: &str) -> Result<(), String> {
    let lang_id = locale
        .parse::<LanguageIdentifier>()
        .map_err(|e| format!("Invalid locale: {}", e))?;

    CURRENT_LOCALE.with(|cell| {
        *cell.borrow_mut() = lang_id;
    });

    Ok(())
}

/// Get the current locale
pub fn get_locale() -> LanguageIdentifier {
    CURRENT_LOCALE.with(|cell| cell.borrow().clone())
}

/// Detect system locale with fallback to en-US
pub fn detect_system_locale() -> LanguageIdentifier {
    std::env::var("LANG")
        .ok()
        .and_then(|lang| {
            // Extract locale from formats like "en_US.UTF-8"
            let locale = lang.split('.').next()?.replace('_', "-");
            locale.parse::<LanguageIdentifier>().ok()
        })
        .unwrap_or_else(|| langid!("en-US"))
}

/// Initialize locale from config or system
pub fn init_locale(config_locale: Option<&str>) {
    let locale = config_locale
        .and_then(|l| l.parse::<LanguageIdentifier>().ok())
        .unwrap_or_else(detect_system_locale);

    CURRENT_LOCALE.with(|cell| {
        *cell.borrow_mut() = locale;
    });
}

/// Get a localized string with arguments
pub fn fl(message_id: &str, args: Option<&HashMap<String, String>>) -> String {
    let locale = get_locale();

    let result = if let Some(args_map) = args {
        // Convert HashMap<String, String> to HashMap<String, FluentValue>
        let fluent_map: HashMap<String, FluentValue> = args_map
            .iter()
            .map(|(k, v)| (k.clone(), FluentValue::from(v.as_str())))
            .collect();
        LOCALES.try_lookup_with_args(&locale, message_id, &fluent_map)
    } else {
        LOCALES.try_lookup(&locale, message_id)
    };

    result.unwrap_or_else(|| {
        // Fallback to message_id if translation not found
        eprintln!("Missing translation: {} for locale: {}", message_id, locale);
        message_id.to_string()
    })
}

/// Macro for easy localization without arguments
#[macro_export]
macro_rules! fl {
    ($message_id:expr) => {
        $crate::i18n::fl($message_id, None)
    };
    ($message_id:expr, $($key:expr => $value:expr),+ $(,)?) => {{
        let mut args = ::std::collections::HashMap::new();
        $(
            args.insert($key.to_string(), $value.to_string());
        )+
        $crate::i18n::fl($message_id, Some(&args))
    }};
}
