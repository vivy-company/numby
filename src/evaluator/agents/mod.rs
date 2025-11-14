mod history;
mod math;
mod percentage;
mod unit;
mod variable;

pub use history::HistoryAgent;
pub use math::MathAgent;
pub use percentage::PercentageAgent;
pub use unit::UnitAgent;
pub use variable::VariableAgent;

/// Agent priority constants. Lower priority values run first.
/// The order is designed to process high-specificity agents before fallback math evaluation.
pub const PRIORITY_HISTORY: i32 = 10;
pub const PRIORITY_VARIABLE: i32 = 20;
pub const PRIORITY_PERCENTAGE: i32 = 30;
pub const PRIORITY_UNIT: i32 = 40;
pub const PRIORITY_MATH: i32 = 50;
