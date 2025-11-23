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
use clap::{CommandFactory, FromArgMatches, Parser};
use models::AppState;

#[derive(Parser)]
#[command(
    name = "Numby",
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

    /// Output format for CLI mode: pretty (default), markdown, table/box, plain
    #[arg(long, default_value = "pretty")]
    format: String,
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

fn detect_cli_locale_arg() -> Option<String> {
    let mut args = std::env::args().peekable();
    let _ = args.next(); // skip binary name

    while let Some(arg) = args.next() {
        if arg == "--locale" {
            return args.next();
        }
        if let Some(value) = arg.strip_prefix("--locale=") {
            return Some(value.to_string());
        }
    }

    None
}

fn main() -> Result<()> {
    config::save_default_config_if_missing()?;
    let mut config = config::load_config();

    let cli_locale = detect_cli_locale_arg();
    let initial_locale = cli_locale
        .as_deref()
        .or(config.locale.as_deref());
    i18n::init_locale(initial_locale);

    let command = Args::command().about(crate::fl!("app-description-long"));
    let matches = command.clone().get_matches();
    let args = Args::from_arg_matches(&matches)?;

    let run_cli = args.expression.is_some();
    let mut startup_msgs: Vec<String> = Vec::new();

    // Initialize locale from CLI arg, config, or system default (re-apply after parsing)
    let locale_str = args.locale.as_deref().or(config.locale.as_deref());
    i18n::init_locale(locale_str);

    // Handle currency rate updates
    if args.update_rates {
        eprintln!("{}", crate::fl!("main-currency-updating"));
        match currency_fetcher::fetch_latest_rates() {
            Ok((rates, date)) => {
                eprintln!(
                    "{}",
                    crate::fl!(
                        "main-currency-fetched",
                        "count" => &rates.len().to_string(),
                        "date" => &date
                    )
                );
                config::update_currency_rates(rates.clone(), date.clone())?;
                eprintln!("{}", crate::fl!("main-currency-updated-success"));
                config.currencies = rates;
            }
            Err(e) => {
                eprintln!("{}", crate::fl!("main-currency-update-failed", "error" => &e.to_string()));
                eprintln!("{}", crate::fl!("main-currency-using-cache"));
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
            let msg = crate::fl!("main-currency-stale-updating");
            if run_cli {
                eprintln!("{}", msg);
            } else {
                startup_msgs.push(msg);
            }
            std::thread::spawn(|| {
                if let Ok((rates, date)) = currency_fetcher::fetch_latest_rates() {
                    if config::update_currency_rates(rates, date.clone()).is_ok() {}
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

    if !run_cli && !startup_msgs.is_empty() {
        let _ = state.set_status(startup_msgs.join(" | "));
    }

    if let Some(expr) = args.expression {
        cli::evaluate_expression(&expr, &mut state, &registry, &args.format);
        return Ok(());
    }

    tui::run(&mut state, &config, &registry)
}
