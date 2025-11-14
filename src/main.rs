mod cli;
mod config;
mod conversions;
mod currency_fetcher;
mod evaluator;
mod i18n;
mod models;
mod parser;
mod prettify;
mod security;
mod tui;
mod utils;

use anyhow::Result;
use clap::Parser;
use models::AppState;

#[derive(Parser)]
#[command(
    name = "Numby",
    about = "Numby - A powerful natural language calculator",
    version = concat!("v", env!("CARGO_PKG_VERSION"))
)]
struct Args {
    /// Expression to evaluate
    #[arg(allow_hyphen_values = true)]
    expression: Option<String>,

    /// File to open
    #[arg(short, long)]
    file: Option<String>,

    /// Currency rate in format CURR:RATE
    #[arg(short, long)]
    rate: Vec<String>,

    /// Locale to use (e.g., en-US, es, zh-CN)
    #[arg(long)]
    locale: Option<String>,

    /// Force update currency rates from API
    #[arg(long)]
    update_rates: bool,

    /// Skip automatic rate update check on startup
    #[arg(long)]
    no_update: bool,
}

fn determine_filename(file_arg: Option<String>, expression_arg: Option<&String>) -> Option<String> {
    if let Some(file) = file_arg {
        return Some(file);
    }

    if let Some(expr) = expression_arg {
        if expr.ends_with(".numby") || std::fs::metadata(expr).is_ok() {
            return Some(expr.clone());
        }
    }

    None
}

fn main() -> Result<()> {
    let args = Args::parse();

    config::save_default_config_if_missing()?;

    let mut config = config::load_config();

    // Initialize locale from CLI arg, config, or system default
    let locale_str = args.locale.as_deref().or(config.locale.as_deref());
    i18n::init_locale(locale_str);

    // Handle currency rate updates
    if args.update_rates {
        eprintln!("Updating currency rates...");
        match currency_fetcher::fetch_latest_rates() {
            Ok((rates, date)) => {
                eprintln!("Fetched {} currency rates (date: {})", rates.len(), date);
                config::update_currency_rates(rates.clone(), date.clone())?;
                eprintln!("Currency rates updated successfully");
                config.currencies = rates;
            }
            Err(e) => {
                eprintln!("Failed to update currency rates: {}", e);
                eprintln!("Using cached rates from config");
            }
        }
    } else if !args.no_update {
        // Automatic background update if rates are stale
        let should_update = if let Some(date) = &config.rates_updated_at {
            currency_fetcher::are_rates_stale(date)
        } else {
            true // No timestamp = first run or old config
        };

        if should_update {
            eprintln!("Currency rates are stale, updating in background...");
            std::thread::spawn(|| {
                if let Ok((rates, date)) = currency_fetcher::fetch_latest_rates() {
                    let count = rates.len();
                    if config::update_currency_rates(rates, date.clone()).is_ok() {
                        eprintln!(
                            "Currency rates updated in background ({} currencies, date: {})",
                            count, date
                        );
                    }
                }
            });
        }
    }

    // Override with CLI rates
    let mut rates = config.currencies;
    for rate_str in &args.rate {
        if let Some((curr, rate)) = config::parse_rate(rate_str) {
            rates.insert(curr, rate);
        }
    }
    config.currencies = rates;

    let current_filename = determine_filename(args.file, args.expression.as_ref());

    let registry =
        crate::evaluator::AgentRegistry::new(&config).expect("Failed to initialize agent registry");
    let mut state = AppState::builder(&config).build();
    state.current_filename = current_filename;

    if let Some(expr) = args.expression {
        cli::evaluate_expression(&expr, &mut state, &registry);
        return Ok(());
    }

    tui::run(&mut state, &config, &registry)
}
