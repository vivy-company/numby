mod cli;
mod config;
mod conversions;
mod evaluator;
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
#[command(name = "Numby", about = "Numby - A natural language calculator")]
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

    /// Show version
    #[arg(short, long)]
    version: bool,
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

    if args.version {
        println!("v{}", env!("CARGO_PKG_VERSION"));
        return Ok(());
    }

    config::save_default_config_if_missing()?;

    let mut config = config::load_config();

    let mut rates = config.currencies;
    for rate_str in &args.rate {
        if let Some((curr, rate)) = config::parse_rate(rate_str) {
            rates.insert(curr, rate);
        }
    }
    config.currencies = rates;

    let current_filename = determine_filename(args.file, args.expression.as_ref());

    let registry = crate::evaluator::AgentRegistry::new(&config);
    let mut state = AppState::new(&config);
    state.current_filename = current_filename;

    if let Some(expr) = args.expression {
        cli::evaluate_expression(&expr, &mut state, &registry);
        return Ok(());
    }

    tui::run(&mut state, &config, &registry)
}
