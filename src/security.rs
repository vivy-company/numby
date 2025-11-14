use std::path::{Path, PathBuf};
use std::io;

/// Validates and canonicalizes a file path to prevent path traversal attacks
pub fn validate_file_path(filename: &str) -> Result<PathBuf, String> {
    // Check for null bytes (path injection)
    if filename.contains('\0') {
        return Err(crate::fl!("invalid-path"));
    }

    // Check for excessively long paths
    if filename.len() > 4096 {
        return Err(crate::fl!("path-too-long"));
    }

    let path = Path::new(filename);

    // Get current directory
    let current_dir = std::env::current_dir()
        .map_err(|_| crate::fl!("cannot-determine-cwd"))?;

    // Get home directory for allowed paths
    let home_dir = dirs::home_dir();

    // Create full path
    let full_path = if path.is_absolute() {
        path.to_path_buf()
    } else {
        current_dir.join(path)
    };

    // Try to canonicalize to resolve all .. and symlinks
    let canonical = match full_path.canonicalize() {
        Ok(p) => p,
        Err(e) if e.kind() == io::ErrorKind::NotFound => {
            // File doesn't exist yet, validate parent directory
            if let Some(parent) = full_path.parent() {
                let parent_canonical = parent.canonicalize()
                    .map_err(|_| crate::fl!("parent-dir-not-exist"))?;

                // Check parent is in allowed directories
                let parent_allowed = parent_canonical.starts_with(&current_dir) ||
                    home_dir.as_ref().is_some_and(|h| parent_canonical.starts_with(h));

                if !parent_allowed {
                    return Err(crate::fl!("path-outside-allowed"));
                }

                // Reconstruct with filename
                if let Some(file_name) = full_path.file_name() {
                    parent_canonical.join(file_name)
                } else {
                    return Err(crate::fl!("invalid-path"));
                }
            } else {
                return Err(crate::fl!("invalid-path"));
            }
        }
        Err(_) => return Err(crate::fl!("invalid-path")),
    };

    // Final validation: ensure canonical path is within allowed directories
    let is_allowed = canonical.starts_with(&current_dir) ||
        home_dir.as_ref().is_some_and(|h| canonical.starts_with(h));

    if !is_allowed {
        return Err(crate::fl!("path-outside-allowed"));
    }

    Ok(canonical)
}

/// Sanitize string for terminal output (prevent escape sequence injection)
pub fn sanitize_terminal_string(s: &str) -> String {
    s.chars()
        .filter(|c| !c.is_control()) // Remove ALL control characters
        .take(200) // Limit length
        .collect()
}

/// Validate input size limits
pub const MAX_EXPR_LENGTH: usize = 10_000;

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
