use ratatui::text::Span;
use std::collections::HashMap;
use std::sync::RwLock;
use super::events::{EventSubscriber, StateEvent};

const MAX_CACHE_SIZE: usize = 1000;

pub struct CacheManager {
    display: RwLock<HashMap<String, Option<String>>>,
    highlight: RwLock<HashMap<String, Vec<Span<'static>>>>,
    display_access: RwLock<HashMap<String, u64>>,
    highlight_access: RwLock<HashMap<String, u64>>,
    counter: RwLock<u64>,
}

impl CacheManager {
    pub fn new() -> Self {
        Self {
            display: RwLock::new(HashMap::new()),
            highlight: RwLock::new(HashMap::new()),
            display_access: RwLock::new(HashMap::new()),
            highlight_access: RwLock::new(HashMap::new()),
            counter: RwLock::new(0),
        }
    }

    fn evict_lru_display(&self) {
        if let (Ok(mut cache), Ok(mut access)) = (self.display.write(), self.display_access.write()) {
            if cache.len() >= MAX_CACHE_SIZE {
                // Find LRU entry
                if let Some((lru_key, _)) = access.iter().min_by_key(|(_, &v)| v) {
                    let lru_key = lru_key.clone();
                    cache.remove(&lru_key);
                    access.remove(&lru_key);
                }
            }
        }
    }

    fn evict_lru_highlight(&self) {
        if let (Ok(mut cache), Ok(mut access)) = (self.highlight.write(), self.highlight_access.write()) {
            if cache.len() >= MAX_CACHE_SIZE {
                // Find LRU entry
                if let Some((lru_key, _)) = access.iter().min_by_key(|(_, &v)| v) {
                    let lru_key = lru_key.clone();
                    cache.remove(&lru_key);
                    access.remove(&lru_key);
                }
            }
        }
    }

    pub fn get_display(&self, key: &str) -> Option<Option<String>> {
        let result = self.display.read().ok()?.get(key).cloned();
        if result.is_some() {
            // Update access time
            if let (Ok(mut counter), Ok(mut access)) = (self.counter.write(), self.display_access.write()) {
                *counter += 1;
                access.insert(key.to_string(), *counter);
            }
        }
        result
    }

    pub fn set_display(&self, key: String, value: Option<String>) {
        self.evict_lru_display();

        if let (Ok(mut cache), Ok(mut counter), Ok(mut access)) =
            (self.display.write(), self.counter.write(), self.display_access.write()) {
            *counter += 1;
            cache.insert(key.clone(), value);
            access.insert(key, *counter);
        }
    }

    pub fn get_highlight(&self, key: &str) -> Option<Vec<Span<'static>>> {
        let result = self.highlight.read().ok()?.get(key).cloned();
        if result.is_some() {
            // Update access time
            if let (Ok(mut counter), Ok(mut access)) = (self.counter.write(), self.highlight_access.write()) {
                *counter += 1;
                access.insert(key.to_string(), *counter);
            }
        }
        result
    }

    pub fn set_highlight(&self, key: String, value: Vec<Span<'static>>) {
        self.evict_lru_highlight();

        if let (Ok(mut cache), Ok(mut counter), Ok(mut access)) =
            (self.highlight.write(), self.counter.write(), self.highlight_access.write()) {
            *counter += 1;
            cache.insert(key.clone(), value);
            access.insert(key, *counter);
        }
    }

    pub fn invalidate_all(&self) {
        if let Ok(mut cache) = self.display.write() {
            cache.clear();
        }
        if let Ok(mut cache) = self.highlight.write() {
            cache.clear();
        }
        if let Ok(mut access) = self.display_access.write() {
            access.clear();
        }
        if let Ok(mut access) = self.highlight_access.write() {
            access.clear();
        }
    }

    pub fn invalidate_prefix(&self, prefix: &str) {
        if let (Ok(mut cache), Ok(mut access)) = (self.display.write(), self.display_access.write()) {
            cache.retain(|k, _| !k.starts_with(prefix));
            access.retain(|k, _| !k.starts_with(prefix));
        }
        if let (Ok(mut cache), Ok(mut access)) = (self.highlight.write(), self.highlight_access.write()) {
            cache.retain(|k, _| !k.starts_with(prefix));
            access.retain(|k, _| !k.starts_with(prefix));
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
