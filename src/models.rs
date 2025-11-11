use std::collections::HashMap;
use std::sync::{Arc, RwLock};
use crate::evaluator::{EvaluatorError, Result, CacheManager, EventSubscriber, StateEvent};

pub type VarMap = Arc<RwLock<HashMap<String, (f64, Option<String>)>>>;
pub type Units = HashMap<String, f64>;
pub type Rates = HashMap<String, f64>;
pub type TempUnits = HashMap<String, String>;

pub trait Agent: Send + Sync {
    fn priority(&self) -> i32;
    fn can_handle(&self, input: &str, state: &AppState) -> bool;
    fn process(&self, input: &str, state: &mut AppState, config: &crate::config::Config) -> Option<(String, bool)>;
}

#[derive(Clone)]
pub enum Mode {
    Normal,
    Command(String),
}

#[derive(Clone)]
pub struct AppState {
    pub variables: VarMap,
    pub history: Arc<RwLock<Vec<f64>>>,
    pub status: Arc<RwLock<String>>,
    pub current_filename: Option<String>,
    pub length_units: HashMap<String, f64>,
    pub time_units: HashMap<String, f64>,
    pub temperature_units: HashMap<String, String>, // for special conversions
    pub area_units: HashMap<String, f64>,
    pub volume_units: HashMap<String, f64>,
    pub weight_units: HashMap<String, f64>,
    pub angular_units: HashMap<String, f64>,
    pub data_units: HashMap<String, f64>,
    pub speed_units: HashMap<String, f64>,
    pub rates: HashMap<String, f64>,
    pub cache: Arc<CacheManager>,
    pub subscribers: Arc<RwLock<Vec<Arc<dyn EventSubscriber>>>>,
}

pub struct AppStateBuilder {
    config: Arc<crate::config::Config>,
}

impl AppStateBuilder {
    pub fn new(config: &crate::config::Config) -> Self {
        Self { config: Arc::new(config.clone()) }
    }

    pub fn build(self) -> AppState {
        let cache = Arc::new(CacheManager::new());
        let subscribers = Arc::new(RwLock::new(vec![cache.clone() as Arc<dyn EventSubscriber>]));
        AppState {
            variables: Arc::new(RwLock::new(HashMap::new())),
            history: Arc::new(RwLock::new(Vec::new())),
            status: Arc::new(RwLock::new(String::new())),
            current_filename: None,
            length_units: self.config.length_units.clone(),
            time_units: self.config.time_units.clone(),
            temperature_units: self.config.temperature_units.clone(),
            area_units: self.config.area_units.clone(),
            volume_units: self.config.volume_units.clone(),
            weight_units: self.config.weight_units.clone(),
            angular_units: self.config.angular_units.clone(),
            data_units: self.config.data_units.clone(),
            speed_units: self.config.speed_units.clone(),
            rates: self.config.currencies.clone(),
            cache,
            subscribers,
        }
    }
}

impl AppState {
    /// Create a new AppState from a configuration.
    ///
    /// # Example
    /// ```ignore
    /// let config = Config::load()?;
    /// let state = AppState::new(&config);
    /// ```
    #[allow(unused)]
    pub fn new(config: &crate::config::Config) -> Self {
        let cache = Arc::new(CacheManager::new());
        let subscribers = Arc::new(RwLock::new(vec![cache.clone() as Arc<dyn EventSubscriber>]));
        Self {
            variables: Arc::new(RwLock::new(HashMap::new())),
            history: Arc::new(RwLock::new(Vec::new())),
            status: Arc::new(RwLock::new(String::new())),
            current_filename: None,
            length_units: config.length_units.clone(),
            time_units: config.time_units.clone(),
            temperature_units: config.temperature_units.clone(),
            area_units: config.area_units.clone(),
            volume_units: config.volume_units.clone(),
            weight_units: config.weight_units.clone(),
            angular_units: config.angular_units.clone(),
            data_units: config.data_units.clone(),
            speed_units: config.speed_units.clone(),
            rates: config.currencies.clone(),
            cache,
            subscribers,
        }
    }

    /// Create a builder for AppState.
    ///
    /// # Example
    /// ```ignore
    /// let config = Config::load()?;
    /// let state = AppState::builder(&config).build();
    /// ```
    pub fn builder(config: &crate::config::Config) -> AppStateBuilder {
        AppStateBuilder::new(config)
    }

    /// Set the status message.
    ///
    /// # Example
    /// ```ignore
    /// state.set_status("Processing...".to_string())?;
    /// ```
    pub fn set_status(&self, msg: String) -> Result<()> {
        self.status.write()
            .map_err(|e| EvaluatorError::LockError(format!("Status lock: {}", e)))?
            .clear();
        *self.status.write()
            .map_err(|e| EvaluatorError::LockError(format!("Status lock: {}", e)))? = msg;
        Ok(())
    }

    /// Get the current status message.
    ///
    /// # Example
    /// ```ignore
    /// let status = state.get_status()?;
    /// ```
    #[allow(unused)]
    pub fn get_status(&self) -> Result<String> {
        Ok(self.status.read()
            .map_err(|e| EvaluatorError::LockError(format!("Status lock: {}", e)))?
            .clone())
    }

    /// Get a variable value and its unit.
    ///
    /// # Example
    /// ```ignore
    /// if let Some((value, unit)) = state.get_variable("x")? {
    ///     println!("x = {} {:?}", value, unit);
    /// }
    /// ```
    #[allow(unused)]
    pub fn get_variable(&self, name: &str) -> Result<Option<(f64, Option<String>)>> {
        Ok(self.variables.read()
            .map_err(|e| EvaluatorError::LockError(format!("Variable lock: {}", e)))?
            .get(name)
            .cloned())
    }

    /// Set a variable with value and optional unit. Publishes VariableChanged event.
    ///
    /// # Example
    /// ```ignore
    /// state.set_variable("x".to_string(), 42.0, Some("m".to_string()))?;
    /// ```
    #[allow(unused)]
    pub fn set_variable(&self, name: String, value: f64, unit: Option<String>) -> Result<()> {
        self.variables.write()
            .map_err(|e| EvaluatorError::LockError(format!("Variable lock: {}", e)))?
            .insert(name.clone(), (value, unit));
        self.publish_event(StateEvent::VariableChanged(name));
        Ok(())
    }

    /// Add a value to history. Publishes HistoryAdded event.
    ///
    /// # Example
    /// ```ignore
    /// state.add_history(42.0)?;
    /// ```
    pub fn add_history(&self, value: f64) -> Result<()> {
        self.history.write()
            .map_err(|e| EvaluatorError::LockError(format!("History lock: {}", e)))?
            .push(value);
        self.publish_event(StateEvent::HistoryAdded(value));
        Ok(())
    }

    /// Get all history values.
    ///
    /// # Example
    /// ```ignore
    /// let history = state.get_history()?;
    /// ```
    #[allow(unused)]
    pub fn get_history(&self) -> Result<Vec<f64>> {
        Ok(self.history.read()
            .map_err(|e| EvaluatorError::LockError(format!("History lock: {}", e)))?
            .clone())
    }

    /// Publish an event to all subscribers.
    ///
    /// # Example
    /// ```ignore
    /// state.publish_event(StateEvent::ConfigReloaded);
    /// ```
    pub fn publish_event(&self, event: StateEvent) {
        if let Ok(subscribers) = self.subscribers.read() {
            for subscriber in subscribers.iter() {
                subscriber.on_event(&event);
            }
        }
    }

    /// Subscribe to state change events.
    ///
    /// # Example
    /// ```ignore
    /// let subscriber = Arc::new(MySubscriber::new());
    /// state.subscribe(subscriber)?;
    /// ```
    #[allow(unused)]
    pub fn subscribe(&self, subscriber: Arc<dyn EventSubscriber>) -> Result<()> {
        self.subscribers.write()
            .map_err(|e| EvaluatorError::LockError(format!("Subscribers lock: {}", e)))?
            .push(subscriber);
        Ok(())
    }
}
