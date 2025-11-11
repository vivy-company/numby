use std::path::{Path, PathBuf};
use std::io;

/// Validates and canonicalizes a file path to prevent path traversal attacks
pub fn validate_file_path(filename: &str) -> Result<PathBuf, String> {
    let path = Path::new(filename);

    // Reject paths that try to escape
    if filename.contains("..") {
        return Err(crate::fl!("path-traversal-detected"));
    }

    // Get current directory
    let current_dir = std::env::current_dir()
        .map_err(|_| crate::fl!("cannot-determine-cwd"))?;

    // Create full path
    let full_path = if path.is_absolute() {
        path.to_path_buf()
    } else {
        current_dir.join(path)
    };

    // Try to canonicalize
    let canonical = match full_path.canonicalize() {
        Ok(p) => p,
        Err(e) if e.kind() == io::ErrorKind::NotFound => {
            // File doesn't exist yet, validate parent directory
            if let Some(parent) = full_path.parent() {
                parent.canonicalize()
                    .map_err(|_| crate::fl!("parent-dir-not-exist"))?;
                full_path
            } else {
                return Err(crate::fl!("invalid-path"));
            }
        }
        Err(_) => return Err(crate::fl!("invalid-path")),
    };

    // Ensure the path is within current directory or user's home
    if !canonical.starts_with(&current_dir) {
        if let Some(home_dir) = dirs::home_dir() {
            if !canonical.starts_with(&home_dir) {
                return Err(crate::fl!("path-outside-allowed"));
            }
        } else {
            return Err(crate::fl!("path-outside-allowed"));
        }
    }

    Ok(canonical)
}

/// Sanitize string for terminal output (prevent escape sequence injection)
pub fn sanitize_terminal_string(s: &str) -> String {
    s.chars()
        .filter(|c| !c.is_control() || *c == '\n' || *c == '\t')
        .take(200) // Limit length
        .collect()
}

/// Validate input size limits
pub const MAX_EXPR_LENGTH: usize = 100_000;

pub fn validate_input_size(input: &str) -> Result<(), String> {
    if input.len() > MAX_EXPR_LENGTH {
        return Err(crate::fl!(
            "input-too-long",
            "actual" => &input.len().to_string(),
            "max" => &MAX_EXPR_LENGTH.to_string()
        ));
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_path_traversal() {
        assert!(validate_file_path("../../../etc/passwd").is_err());
        assert!(validate_file_path("../../.ssh/id_rsa").is_err());
    }

    #[test]
    fn test_valid_relative_path() {
        let result = validate_file_path("test.txt");
        assert!(result.is_ok());
    }

    #[test]
    fn test_sanitize_terminal() {
        let dangerous = "test\x1b[31mred\x07";
        let safe = sanitize_terminal_string(dangerous);
        assert!(!safe.contains('\x1b'));
        assert!(!safe.contains('\x07'));
    }

    #[test]
    fn test_input_size_validation() {
        assert!(validate_input_size("hello").is_ok());
        let huge = "x".repeat(MAX_EXPR_LENGTH + 1);
        assert!(validate_input_size(&huge).is_err());
    }
}
