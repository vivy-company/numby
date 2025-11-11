use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fs;
use std::path::PathBuf;

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct Config {
    pub length_units: HashMap<String, f64>,
    pub time_units: HashMap<String, f64>,
    pub temperature_units: HashMap<String, String>,
    pub area_units: HashMap<String, f64>,
    pub volume_units: HashMap<String, f64>,
    pub weight_units: HashMap<String, f64>,
    pub angular_units: HashMap<String, f64>,
    pub data_units: HashMap<String, f64>,
    pub speed_units: HashMap<String, f64>,
    pub currencies: HashMap<String, f64>,
    pub operators: HashMap<String, String>,
    pub scales: HashMap<String, f64>,
    pub functions: HashMap<String, String>,
    pub custom_units: HashMap<String, HashMap<String, f64>>,
    #[serde(default)]
    pub locale: Option<String>,
}

fn insert_numeric_units(map: &mut HashMap<String, f64>, units: &[(&str, f64)]) {
    for (key, value) in units {
        map.insert(key.to_string(), *value);
    }
}

fn insert_string_units(map: &mut HashMap<String, String>, units: &[(&str, &str)]) {
    for (key, value) in units {
        map.insert(key.to_string(), value.to_string());
    }
}

fn create_length_units() -> HashMap<String, f64> {
    let mut map = HashMap::new();
    insert_numeric_units(
        &mut map,
        &[
            ("m", 1.0),
            ("meter", 1.0),
            ("meters", 1.0),
            ("cm", 0.01),
            ("centimeter", 0.01),
            ("centimeters", 0.01),
            ("mm", 0.001),
            ("millimeter", 0.001),
            ("millimeters", 0.001),
            ("km", 1000.0),
            ("kilometer", 1000.0),
            ("kilometers", 1000.0),
            ("ft", 0.3048),
            ("foot", 0.3048),
            ("feet", 0.3048),
            ("inch", 0.0254),
            ("inches", 0.0254),
            ("yard", 0.9144),
            ("yards", 0.9144),
            ("mile", 1609.344),
            ("miles", 1609.344),
        ],
    );
    map
}

fn create_time_units() -> HashMap<String, f64> {
    let mut map = HashMap::new();
    insert_numeric_units(
        &mut map,
        &[
            ("second", 1.0),
            ("seconds", 1.0),
            ("minute", 60.0),
            ("minutes", 60.0),
            ("hour", 3600.0),
            ("hours", 3600.0),
            ("day", 86400.0),
            ("days", 86400.0),
            ("week", 604800.0),
            ("weeks", 604800.0),
            ("month", 2592000.0),
            ("months", 2592000.0),
            ("year", 31536000.0),
            ("years", 31536000.0),
        ],
    );
    map
}

fn create_temperature_units() -> HashMap<String, String> {
    let mut map = HashMap::new();
    insert_string_units(
        &mut map,
        &[
            ("kelvin", "kelvin"),
            ("kelvins", "kelvin"),
            ("celsius", "celsius"),
            ("fahrenheit", "fahrenheit"),
        ],
    );
    map
}

fn create_area_units() -> HashMap<String, f64> {
    let mut map = HashMap::new();
    insert_numeric_units(
        &mut map,
        &[
            ("m2", 1.0),
            ("square meter", 1.0),
            ("square meters", 1.0),
            ("hectare", 10000.0),
            ("hectares", 10000.0),
            ("are", 100.0),
            ("ares", 100.0),
            ("acre", 4046.86),
            ("acres", 4046.86),
        ],
    );
    map
}

fn create_volume_units() -> HashMap<String, f64> {
    let mut map = HashMap::new();
    insert_numeric_units(
        &mut map,
        &[
            ("m3", 1.0),
            ("cubic meter", 1.0),
            ("cubic meters", 1.0),
            ("liter", 0.001),
            ("liters", 0.001),
            ("l", 0.001),
            ("pint", 0.000473176),
            ("pints", 0.000473176),
            ("quart", 0.000946353),
            ("quarts", 0.000946353),
            ("gallon", 0.00378541),
            ("gallons", 0.00378541),
            ("tea spoon", 4.92892e-6),
            ("table spoon", 1.47868e-5),
            ("cup", 0.000236588),
        ],
    );
    map
}

fn create_weight_units() -> HashMap<String, f64> {
    let mut map = HashMap::new();
    insert_numeric_units(
        &mut map,
        &[
            ("gram", 1.0),
            ("grams", 1.0),
            ("g", 1.0),
            ("tonne", 1000000.0),
            ("tonnes", 1000000.0),
            ("carat", 0.2),
            ("carats", 0.2),
            ("centner", 100000.0),
            ("pound", 453.592),
            ("pounds", 453.592),
            ("stone", 6350.29),
            ("stones", 6350.29),
            ("ounce", 28.3495),
            ("ounces", 28.3495),
        ],
    );
    map
}

fn create_angular_units() -> HashMap<String, f64> {
    let mut map = HashMap::new();
    insert_numeric_units(
        &mut map,
        &[
            ("radian", 1.0),
            ("radians", 1.0),
            ("degree", 0.0174533),
            ("degrees", 0.0174533),
            ("°", 0.0174533),
        ],
    );
    map
}

fn create_data_units() -> HashMap<String, f64> {
    let mut map = HashMap::new();
    insert_numeric_units(
        &mut map,
        &[
            ("bit", 1.0),
            ("bits", 1.0),
            ("byte", 8.0),
            ("bytes", 8.0),
            ("b", 1.0),
            ("B", 8.0),
        ],
    );
    map
}

fn create_speed_units() -> HashMap<String, f64> {
    let mut map = HashMap::new();
    insert_numeric_units(
        &mut map,
        &[
            ("m/s", 1.0),
            ("meter per second", 1.0),
            ("meters per second", 1.0),
            ("km/h", 0.277778),
            ("kilometer per hour", 0.277778),
            ("kilometers per hour", 0.277778),
            ("mph", 0.44704),
            ("mile per hour", 0.44704),
            ("miles per hour", 0.44704),
            ("knot", 0.514444),
            ("knots", 0.514444),
        ],
    );
    map
}

fn create_currencies() -> HashMap<String, f64> {
    let mut map = HashMap::new();
    insert_numeric_units(
        &mut map,
        &[
            ("USD", 1.0),
            ("EUR", 0.85),
            ("GBP", 0.73),
            ("JPY", 0.0065),
            ("CAD", 0.68),
        ],
    );
    map
}

fn create_operators() -> HashMap<String, String> {
    let mut map = HashMap::new();
    insert_string_units(
        &mut map,
        &[
            ("plus", "+"),
            ("minus", "-"),
            ("times", "*"),
            ("multiplied by", "*"),
            ("divided by", "/"),
            ("divide by", "/"),
            ("subtract", "-"),
            ("and", "+"),
            ("with", "+"),
            ("mod", "%"),
        ],
    );
    map
}

fn create_scales() -> HashMap<String, f64> {
    let mut map = HashMap::new();
    insert_numeric_units(
        &mut map,
        &[
            ("k", 1000.0),
            ("kilo", 1000.0),
            ("thousand", 1000.0),
            ("M", 1000000.0),
            ("mega", 1000000.0),
            ("million", 1000000.0),
            ("G", 1000000000.0),
            ("giga", 1000000000.0),
            ("billion", 1000000000.0),
            ("T", 1000000000000.0),
            ("tera", 1000000000000.0),
            ("b", 1000000000.0),
        ],
    );
    map
}

fn create_functions() -> HashMap<String, String> {
    let mut map = HashMap::new();
    insert_string_units(
        &mut map,
        &[
            ("log", "log10("),
            ("ln", "ln("),
            ("abs", "abs("),
            ("round", "round("),
            ("ceil", "ceil("),
            ("floor", "floor("),
            ("sinh", "sinh("),
            ("cosh", "cosh("),
            ("tanh", "tanh("),
            ("arcsin", "asin("),
            ("arccos", "acos("),
            ("arctan", "atan("),
        ],
    );
    map
}

fn create_custom_units() -> HashMap<String, HashMap<String, f64>> {
    let mut custom_units = HashMap::new();
    let mut energy_units = HashMap::new();
    insert_numeric_units(
        &mut energy_units,
        &[("joule", 1.0), ("calorie", 4.184)],
    );
    custom_units.insert("energy".to_string(), energy_units);
    custom_units
}

impl Default for Config {
    fn default() -> Self {
        Config {
            length_units: create_length_units(),
            time_units: create_time_units(),
            temperature_units: create_temperature_units(),
            area_units: create_area_units(),
            volume_units: create_volume_units(),
            weight_units: create_weight_units(),
            angular_units: create_angular_units(),
            data_units: create_data_units(),
            speed_units: create_speed_units(),
            currencies: create_currencies(),
            operators: create_operators(),
            scales: create_scales(),
            functions: create_functions(),
            custom_units: create_custom_units(),
            locale: None,
        }
    }
}

pub fn parse_rate(rate_str: &str) -> Option<(String, f64)> {
    let parts: Vec<&str> = rate_str.split(':').collect();
    if parts.len() == 2 {
        if let Ok(rate) = parts[1].parse::<f64>() {
            return Some((parts[0].to_uppercase(), rate));
        }
    }
    None
}

pub fn load_config() -> Config {
    let config_path = get_config_path();
    if let Ok(content) = fs::read_to_string(&config_path) {
        if let Ok(config) = serde_json::from_str(&content) {
            return config;
        }
    }
    // Try ./config.json
    if let Ok(content) = fs::read_to_string("./config.json") {
        if let Ok(config) = serde_json::from_str(&content) {
            return config;
        }
    }
    // Fallback to default if file not found or invalid
    Config::default()
}

pub fn get_config_path() -> PathBuf {
    let mut config_path = dirs::config_dir().unwrap_or_else(|| PathBuf::from("./"));
    config_path.push("numby");
    config_path.push("config.json");
    config_path
}

pub fn ensure_config_dir() -> anyhow::Result<()> {
    let config_dir = dirs::config_dir().unwrap_or_else(|| PathBuf::from("./"));
    fs::create_dir_all(config_dir.join("numby"))?;
    Ok(())
}

pub fn save_default_config_if_missing() -> anyhow::Result<()> {
    let config_path = get_config_path();
    if !config_path.exists() {
        ensure_config_dir()?;
        let default_config = Config::default();
        let json = serde_json::to_string_pretty(&default_config)?;
        fs::write(config_path, json)?;
    }
    Ok(())
}
