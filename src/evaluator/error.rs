use std::fmt;

#[derive(Debug)]
pub enum EvaluatorError {
    LockError(String),
    InvalidExpression(String),
    ParseError(String),
    ConfigError(String),
    EvaluationError(String),
}

impl fmt::Display for EvaluatorError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            EvaluatorError::LockError(details) => {
                write!(f, "{}", crate::fl!("error-lock", "details" => details))
            }
            EvaluatorError::InvalidExpression(details) => {
                write!(f, "{}", crate::fl!("error-invalid-expression", "details" => details))
            }
            EvaluatorError::ParseError(details) => {
                write!(f, "{}", crate::fl!("error-parse", "details" => details))
            }
            EvaluatorError::ConfigError(details) => {
                write!(f, "{}", crate::fl!("error-config", "details" => details))
            }
            EvaluatorError::EvaluationError(details) => {
                write!(f, "{}", crate::fl!("error-evaluation", "details" => details))
            }
        }
    }
}

impl std::error::Error for EvaluatorError {}

pub type Result<T> = std::result::Result<T, EvaluatorError>;
