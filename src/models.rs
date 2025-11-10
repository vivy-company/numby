use ratatui::text::Span;
use std::collections::HashMap;
use std::sync::{Arc, RwLock};

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
    pub display_cache: Arc<RwLock<HashMap<String, Option<String>>>>,
    pub highlight_cache: Arc<RwLock<HashMap<String, Vec<Span<'static>>>>>,

}

impl AppState {
    pub fn new(config: &crate::config::Config) -> Self {
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
            display_cache: Arc::new(RwLock::new(HashMap::new())),
            highlight_cache: Arc::new(RwLock::new(HashMap::new())),
        }
    }
}
