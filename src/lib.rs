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
pub mod models;
pub mod prettify;
pub mod parser;
pub mod conversions;
pub mod evaluator;
pub mod security;
pub mod i18n;

#[cfg(test)]
mod event_tests {
    use crate::evaluator::{StateEvent, EventSubscriber};
    use crate::models::AppState;
    use crate::config::Config;
    use std::sync::Arc;
    use std::sync::atomic::{AtomicUsize, Ordering};

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
        state.cache.set_display("test_key".to_string(), Some("cached_value".to_string()));

        // Verify it's cached
        assert_eq!(
            state.cache.get_display("test_key"),
            Some(Some("cached_value".to_string()))
        );

        // Trigger a variable change event
        state.publish_event(StateEvent::VariableChanged("test".to_string()));

        // Cache should be invalidated for prefix "test"
        // Keys that don't start with "test" should still be there
        state.cache.set_display("other_key".to_string(), Some("other_value".to_string()));

        // Set a cache with "test" prefix
        state.cache.set_display("test_key".to_string(), Some("new_value".to_string()));

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
        let _ = state.add_history(42.0);

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
        assert!(locale.to_string().len() > 0);
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
        assert_eq!(msg1, "Path traversal detected", "Expected English, got: {}", msg1);
        assert_eq!(msg2, "Invalid path", "Expected English, got: {}", msg2);
    }

    #[test]
    fn test_spanish_security_messages() {
        i18n::init_locale(Some("es"));
        assert_eq!(i18n::get_locale().to_string(), "es");
        let msg1 = crate::fl!("path-traversal-detected");
        let msg2 = crate::fl!("invalid-path");
        assert_eq!(msg1, "Traversal de ruta detectado", "Expected Spanish, got: {}", msg1);
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
        assert!(msg.contains("quit"), "Expected 'quit' in English message, got: {}", msg);
        assert!(msg.contains("save"), "Expected 'save' in English message, got: {}", msg);
    }

    #[test]
    fn test_spanish_tui_messages() {
        i18n::init_locale(Some("es"));
        assert_eq!(i18n::get_locale().to_string(), "es");
        let msg = crate::fl!("commands-help");
        assert!(msg.contains("salir"), "Expected 'salir' in Spanish message, got: {}", msg);
        assert!(msg.contains("guardar"), "Expected 'guardar' in Spanish message, got: {}", msg);
    }

    #[test]
    fn test_chinese_tui_messages() {
        i18n::init_locale(Some("zh-CN"));
        assert_eq!(i18n::get_locale().to_string(), "zh-CN");
        let msg = crate::fl!("commands-help");
        assert!(msg.contains("退出"), "Expected '退出' in Chinese message, got: {}", msg);
        assert!(msg.contains("保存"), "Expected '保存' in Chinese message, got: {}", msg);
    }

    #[test]
    fn test_message_with_variable() {
        i18n::init_locale(Some("en-US"));
        assert_eq!(i18n::get_locale().to_string(), "en-US");
        let msg = crate::fl!("input-too-long", "actual" => "150000", "max" => "100000");
        assert!(msg.contains("150000"));
        assert!(msg.contains("100000"));
        assert!(msg.contains("chars"), "Expected 'chars' in English message, got: {}", msg);
    }

    #[test]
    fn test_spanish_message_with_variable() {
        i18n::init_locale(Some("es"));
        assert_eq!(i18n::get_locale().to_string(), "es");
        let msg = crate::fl!("input-too-long", "actual" => "150000", "max" => "100000");
        assert!(msg.contains("150000"));
        assert!(msg.contains("100000"));
        assert!(msg.contains("caracteres"), "Expected 'caracteres' in Spanish message, got: {}", msg);
    }

    #[test]
    fn test_chinese_message_with_variable() {
        i18n::init_locale(Some("zh-CN"));
        assert_eq!(i18n::get_locale().to_string(), "zh-CN");
        let msg = crate::fl!("input-too-long", "actual" => "150000", "max" => "100000");
        assert!(msg.contains("150000"));
        assert!(msg.contains("100000"));
        assert!(msg.contains("字符"), "Expected '字符' in Chinese message, got: {}", msg);
    }

    #[test]
    fn test_fallback_for_missing_key() {
        i18n::init_locale(Some("en-US"));
        let msg = crate::fl!("non-existent-key");
        // Should return the key itself as fallback
        assert_eq!(msg, "non-existent-key");
    }
}