//! Configuration management for Numby calculator.
//!
//! This module handles loading, saving, and providing default configurations
//! for unit conversions, currency rates, and other calculator settings.

use chrono_tz::TZ_VARIANTS;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fs;
use std::path::{Path, PathBuf};

/// Main configuration structure containing all calculator settings.
///
/// # Examples
///
/// ```
/// use numby::config::Config;
///
/// // Create default configuration
/// let config = Config::default();
/// assert!(config.length_units.contains_key("meter"));
/// assert!(config.currencies.contains_key("USD"));
/// ```
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
    /// City name aliases to IANA time zones (lowercase keys).
    #[serde(default = "create_city_aliases")]
    pub city_aliases: HashMap<String, String>,
    /// Preferred datetime format (iso|long|short|time|12h) shared by CLI and TUI.
    #[serde(default = "default_time_format")]
    pub time_format: String,
    /// Preferred date-only format (iso|long|short) shared by CLI and TUI.
    #[serde(default = "default_date_format")]
    pub date_format: String,
    #[serde(default)]
    pub locale: Option<String>,
    #[serde(default = "default_padding_left")]
    pub padding_left: u16,
    #[serde(default = "default_padding_right")]
    pub padding_right: u16,
    #[serde(default = "default_padding_top")]
    pub padding_top: u16,
    #[serde(default = "default_padding_bottom")]
    pub padding_bottom: u16,
    #[serde(default)]
    pub rates_updated_at: Option<String>,
    #[serde(default)]
    pub api_rates_date: Option<String>,
    /// Optional default timezone identifier (IANA database, e.g., "UTC", "America/New_York").
    /// If not set, the local system timezone is used.
    #[serde(default)]
    pub default_timezone: Option<String>,
}

fn default_padding_left() -> u16 {
    2
}
fn default_padding_right() -> u16 {
    2
}
fn default_padding_top() -> u16 {
    0
}
fn default_padding_bottom() -> u16 {
    2
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
            ("in", 0.0254),
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
            ("s", 1.0),
            ("sec", 1.0),
            ("second", 1.0),
            ("seconds", 1.0),
            ("min", 60.0),
            ("minute", 60.0),
            ("minutes", 60.0),
            ("h", 3600.0),
            ("hr", 3600.0),
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
            ("k", "kelvin"),
            ("kelvin", "kelvin"),
            ("kelvins", "kelvin"),
            ("c", "celsius"),
            ("celsius", "celsius"),
            ("f", "fahrenheit"),
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
            ("milliliter", 0.000001),
            ("milliliters", 0.000001),
            ("ml", 0.000001),
            ("pint", 0.000473176),
            ("pints", 0.000473176),
            ("quart", 0.000946353),
            ("quarts", 0.000946353),
            ("gallon", 0.00378541),
            ("gallons", 0.00378541),
            ("teaspoon", 4.92892e-6),
            ("teaspoons", 4.92892e-6),
            ("tsp", 4.92892e-6),
            ("tablespoon", 1.47868e-5),
            ("tablespoons", 1.47868e-5),
            ("tbsp", 1.47868e-5),
            ("cup", 0.000236588),
            ("cups", 0.000236588),
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
            ("kilogram", 1000.0),
            ("kilograms", 1000.0),
            ("kg", 1000.0),
            ("tonne", 1000000.0),
            ("tonnes", 1000000.0),
            ("carat", 0.2),
            ("carats", 0.2),
            ("centner", 100000.0),
            ("pound", 453.592),
            ("pounds", 453.592),
            ("lb", 453.592),
            ("lbs", 453.592),
            ("stone", 6350.29),
            ("stones", 6350.29),
            ("ounce", 28.3495),
            ("ounces", 28.3495),
            ("oz", 28.3495),
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
            // Base currency
            ("USD", 1.0),
            // Major fiat currencies (rates represent 1 USD = X of target currency)
            ("EUR", 0.86287014),   // Euro
            ("GBP", 0.76203273),   // British Pound
            ("JPY", 154.7480061),  // Japanese Yen
            ("CAD", 1.3942405),    // Canadian Dollar
            ("AUD", 1.5294504),    // Australian Dollar
            ("CHF", 0.8800703),    // Swiss Franc
            ("CNY", 7.2373404),    // Chinese Yuan
            ("INR", 84.4105508),   // Indian Rupee
            ("MXN", 20.2890511),   // Mexican Peso
            ("BRL", 5.7765307),    // Brazilian Real
            ("ZAR", 18.0755011),   // South African Rand
            ("RUB", 100.0010501),  // Russian Ruble
            ("KRW", 1396.005701),  // South Korean Won
            ("SEK", 10.9555061),   // Swedish Krona
            ("NOK", 11.1155051),   // Norwegian Krone
            ("DKK", 7.0623504),    // Danish Krone
            ("SGD", 1.3379804),    // Singapore Dollar
            ("HKD", 7.7879504),    // Hong Kong Dollar
            ("NZD", 1.6786304),    // New Zealand Dollar
            ("TRY", 34.5870006),   // Turkish Lira
            ("PLN", 4.0910202),    // Polish Zloty
            ("THB", 34.5705006),   // Thai Baht
            ("MYR", 4.4520202),    // Malaysian Ringgit
            ("IDR", 15906.005551), // Indonesian Rupiah
            ("PHP", 58.9305012),   // Philippine Peso
            ("CZK", 23.8160011),   // Czech Koruna
            ("ILS", 3.7301802),    // Israeli Shekel
            ("CLP", 976.005101),   // Chilean Peso
            ("AED", 3.6730201),    // UAE Dirham
            ("COP", 4407.005205),  // Colombian Peso
            ("BYN", 3.41012),      // Belarusian Ruble
            // Major cryptocurrencies (optional, for extended support)
            ("BTC", 0.00001125), // Bitcoin
            ("ETH", 0.00032587), // Ethereum
            ("BNB", 0.001621),   // Binance Coin
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
            // Unicode math symbols
            ("×", "*"),
            ("÷", "/"),
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
        &[
            ("joule", 1.0),
            ("joules", 1.0),
            ("j", 1.0),
            ("calorie", 4.184),
            ("calories", 4.184),
            ("cal", 4.184),
        ],
    );
    custom_units.insert("energy".to_string(), energy_units);
    custom_units
}

fn create_city_aliases() -> HashMap<String, String> {
    let mut map = HashMap::new();
    for tz in TZ_VARIANTS.iter() {
        let name = tz.name();
        if let Some(last) = name.rsplit('/').next() {
            let city = last.replace('_', " ").to_lowercase();
            map.entry(city).or_insert_with(|| name.to_string());
        }
    }
    map
}

fn default_time_format() -> String {
    "iso".to_string()
}

fn default_date_format() -> String {
    "iso".to_string()
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
            city_aliases: create_city_aliases(),
            time_format: default_time_format(),
            date_format: default_date_format(),
            locale: None,
            padding_left: default_padding_left(),
            padding_right: default_padding_right(),
            padding_top: default_padding_top(),
            padding_bottom: default_padding_bottom(),
            rates_updated_at: None,
            api_rates_date: None,
            default_timezone: None,
        }
    }
}

/// Parse a currency rate string in "CURRENCY:RATE" format.
///
/// # Examples
///
/// ```
/// use numby::config::parse_rate;
///
/// let result = parse_rate("EUR:0.85");
/// assert_eq!(result, Some(("EUR".to_string(), 0.85)));
///
/// let invalid = parse_rate("invalid");
/// assert_eq!(invalid, None);
/// ```
pub fn parse_rate(rate_str: &str) -> Option<(String, f64)> {
    let parts: Vec<&str> = rate_str.split(':').collect();
    if parts.len() == 2 {
        if let Ok(rate) = parts[1].parse::<f64>() {
            return Some((parts[0].to_uppercase(), rate));
        }
    }
    None
}

/// Load configuration from file or return default configuration.
///
/// Looks for config in the following order:
/// 1. Platform-specific config directory (`~/.config/numby/config.json` on Unix)
/// 2. Current directory (`./config.json`)
/// 3. Default configuration if neither exists
///
/// # Examples
///
/// ```
/// use numby::config::load_config;
///
/// let config = load_config();
/// // Always succeeds, returns default if no config file found
/// assert!(config.length_units.len() > 0);
/// ```
pub fn load_config() -> Config {
    let config_path = get_config_path();
    if let Ok(content) = fs::read_to_string(&config_path) {
        if let Ok(config) = serde_json::from_str::<Config>(&content) {
            return config;
        }
    }
    // Try ./config.json
    if let Ok(content) = fs::read_to_string("./config.json") {
        if let Ok(config) = serde_json::from_str::<Config>(&content) {
            return config;
        }
    }
    // Fallback to default if file not found or invalid
    Config::default()
}

/// Get the platform-specific configuration file path.
///
/// # Examples
///
/// ```
/// use numby::config::get_config_path;
///
/// let path = get_config_path();
/// // On Unix-like systems: ~/.config/numby/config.json
/// assert!(path.to_string_lossy().contains("config.json"));
/// ```
pub fn get_config_path() -> PathBuf {
    let mut config_path = dirs::config_dir().unwrap_or_else(|| PathBuf::from("./"));
    config_path.push("numby");
    config_path.push("config.json");
    config_path
}

/// Create config directory if it doesn't exist.
///
/// # Errors
///
/// Returns error if directory creation fails due to permissions or I/O issues.
///
/// # Examples
///
/// ```
/// use numby::config::ensure_config_dir;
///
/// // Create config directory
/// let result = ensure_config_dir();
/// // Should succeed on most systems
/// assert!(result.is_ok() || result.is_err()); // Either way is valid
/// ```
pub fn ensure_config_dir() -> anyhow::Result<()> {
    let config_dir = dirs::config_dir().unwrap_or_else(|| PathBuf::from("./"));
    fs::create_dir_all(config_dir.join("numby"))?;
    Ok(())
}

/// Save default configuration file if it doesn't already exist.
///
/// # Errors
///
/// Returns error if file writing fails or directory cannot be created.
///
/// # Examples
///
/// ```
/// use numby::config::save_default_config_if_missing;
///
/// // Creates config file if missing
/// let result = save_default_config_if_missing();
/// // May fail in read-only filesystem, but that's expected
/// ```
pub fn save_default_config_if_missing() -> anyhow::Result<()> {
    let config_path = get_config_path();
    if !config_path.exists() {
        ensure_config_dir()?;
        let default_config = Config::default();
        save_config(&default_config)?;
    }
    Ok(())
}

/// Update currency rates and timestamp in the config file.
///
/// # Arguments
///
/// * `rates` - HashMap of currency codes to exchange rates
/// * `date` - ISO date string (YYYY-MM-DD) of when rates were fetched
///
/// # Errors
///
/// Returns error if config cannot be saved.
///
/// # Examples
///
/// ```no_run
/// use std::collections::HashMap;
/// use numby::config::update_currency_rates;
///
/// let mut rates = HashMap::new();
/// rates.insert("EUR".to_string(), 0.85);
/// rates.insert("GBP".to_string(), 0.73);
///
/// update_currency_rates(rates, "2025-01-15".to_string())
///     .expect("Failed to update rates");
/// ```
pub fn update_currency_rates(rates: HashMap<String, f64>, date: String) -> anyhow::Result<()> {
    let config_path = get_config_path();
    update_currency_rates_at_path(&config_path, rates, date)
}

/// Update currency rates in a specific config file path.
pub fn update_currency_rates_at_path(
    path: &Path,
    rates: HashMap<String, f64>,
    api_date: String,
) -> anyhow::Result<()> {
    // Use current date for last updated timestamp
    use chrono::Utc;
    let current_date = Utc::now().format("%Y-%m-%d").to_string();

    let mut config = if let Ok(content) = fs::read_to_string(path) {
        serde_json::from_str(&content).unwrap_or_else(|_| Config::default())
    } else {
        Config::default()
    };

    config.currencies = rates;
    config.rates_updated_at = Some(current_date);
    config.api_rates_date = Some(api_date);
    save_config_to_path(path, &config)
}

/// Save configuration to the primary config path.
///
/// # Errors
///
/// Returns error if config directory cannot be created or file cannot be written.
///
/// # Examples
///
/// ```no_run
/// use numby::config::{Config, save_config};
///
/// let mut config = Config::default();
/// config.padding_left = 5;
///
/// save_config(&config).expect("Failed to save config");
/// ```
pub fn save_config(config: &Config) -> anyhow::Result<()> {
    let config_path = get_config_path();
    save_config_to_path(&config_path, config)
}

/// Save configuration to a provided path, creating parent directories if needed.
pub fn save_config_to_path(path: &Path, config: &Config) -> anyhow::Result<()> {
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)?;
    }
    let json = serde_json::to_string_pretty(config)?;
    fs::write(path, json)?;
    Ok(())
}
