use ratatui::text::Span;
use std::collections::HashMap;
use std::sync::RwLock;
use super::events::{EventSubscriber, StateEvent};

pub struct CacheManager {
    display: RwLock<HashMap<String, Option<String>>>,
    highlight: RwLock<HashMap<String, Vec<Span<'static>>>>,
}

impl CacheManager {
    pub fn new() -> Self {
        Self {
            display: RwLock::new(HashMap::new()),
            highlight: RwLock::new(HashMap::new()),
        }
    }

    pub fn get_display(&self, key: &str) -> Option<Option<String>> {
        self.display.read().ok()?.get(key).cloned()
    }

    pub fn set_display(&self, key: String, value: Option<String>) {
        if let Ok(mut cache) = self.display.write() {
            cache.insert(key, value);
        }
    }

    pub fn get_highlight(&self, key: &str) -> Option<Vec<Span<'static>>> {
        self.highlight.read().ok()?.get(key).cloned()
    }

    pub fn set_highlight(&self, key: String, value: Vec<Span<'static>>) {
        if let Ok(mut cache) = self.highlight.write() {
            cache.insert(key, value);
        }
    }

    pub fn invalidate_all(&self) {
        if let Ok(mut cache) = self.display.write() {
            cache.clear();
        }
        if let Ok(mut cache) = self.highlight.write() {
            cache.clear();
        }
    }

    pub fn invalidate_prefix(&self, prefix: &str) {
        if let Ok(mut cache) = self.display.write() {
            cache.retain(|k, _| !k.starts_with(prefix));
        }
        if let Ok(mut cache) = self.highlight.write() {
            cache.retain(|k, _| !k.starts_with(prefix));
        }
    }
}

impl Default for CacheManager {
    fn default() -> Self {
        Self::new()
    }
}

impl EventSubscriber for CacheManager {
    fn on_event(&self, event: &StateEvent) {
        match event {
            StateEvent::VariableChanged(var_name) => {
                self.invalidate_prefix(var_name);
            }
            StateEvent::VariableDeleted(var_name) => {
                self.invalidate_prefix(var_name);
            }
            StateEvent::AllVariablesCleared => {
                self.invalidate_all();
            }
            StateEvent::ConfigReloaded => {
                self.invalidate_all();
            }
            StateEvent::HistoryAdded(_) => {
                // History changes don't affect variable/unit caches
            }
        }
    }
}
