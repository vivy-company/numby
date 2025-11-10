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

pub mod config;
pub mod models;
pub mod prettify;
pub mod parser;
pub mod conversions;
pub mod evaluator;