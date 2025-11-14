//! Security utilities for input validation and path sanitization.
//!
//! This module provides functions to prevent common security vulnerabilities
//! including path traversal attacks, command injection, and excessive input sizes.

use std::io;
use std::path::{Path, PathBuf};

fn canonicalize_or_same(path: &Path) -> PathBuf {
    path.canonicalize().unwrap_or_else(|_| path.to_path_buf())
}

fn build_allowed_roots(current_dir: &Path) -> Vec<PathBuf> {
    let mut roots = Vec::new();
    roots.push(canonicalize_or_same(current_dir));
    if let Some(home) = dirs::home_dir() {
        roots.push(canonicalize_or_same(&home));
    }
    roots.extend(extra_allowed_roots());
    roots
}

#[cfg(target_os = "macos")]
fn extra_allowed_roots() -> Vec<PathBuf> {
    if let Ok(exe_path) = std::env::current_exe() {
        for ancestor in exe_path.ancestors() {
            if let Some(name) = ancestor.file_name() {
                if name.to_string_lossy().ends_with(".app") {
                    let resources = ancestor.join("Contents").join("Resources");
                    if resources.exists() {
                        return vec![canonicalize_or_same(&resources)];
                    }
                    return vec![canonicalize_or_same(ancestor)];
                }
            }
        }
    }
    Vec::new()
}

#[cfg(not(target_os = "macos"))]
fn extra_allowed_roots() -> Vec<PathBuf> {
    Vec::new()
}

/// Validate and canonicalize a file path to prevent path traversal attacks.
///
/// This function checks for:
/// - Null bytes in path (path injection)
/// - Excessively long paths (> 4096 bytes)
/// - Path traversal attempts (..)
/// - Access outside allowed directories (current directory or home)
///
/// # Arguments
///
/// * `filename` - The file path to validate
///
/// # Errors
///
/// Returns error string if validation fails or path is outside allowed directories.
///
/// # Examples
///
/// ```
/// use numby::security::validate_file_path;
///
/// // Valid relative path
/// let result = validate_file_path("data.txt");
/// assert!(result.is_ok());
///
/// // Path traversal attempt - should fail
/// let result = validate_file_path("../../../etc/passwd");
/// assert!(result.is_err());
///
/// // Null byte injection - should fail
/// let result = validate_file_path("file\0.txt");
/// assert!(result.is_err());
/// ```
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
    let current_dir = std::env::current_dir().map_err(|_| crate::fl!("cannot-determine-cwd"))?;

    // Determine allowed root directories (cwd, home, bundle resources, ...)
    let allowed_roots = build_allowed_roots(&current_dir);

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
                let parent_canonical = parent
                    .canonicalize()
                    .map_err(|_| crate::fl!("parent-dir-not-exist"))?;

                // Check parent is in allowed directories
                let parent_allowed = allowed_roots
                    .iter()
                    .any(|root| parent_canonical.starts_with(root));

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
    let is_allowed = allowed_roots.iter().any(|root| canonical.starts_with(root));

    if !is_allowed {
        return Err(crate::fl!("path-outside-allowed"));
    }

    Ok(canonical)
}

/// Sanitize string for terminal output to prevent escape sequence injection.
///
/// Removes all control characters and limits string length to prevent terminal attacks.
///
/// # Examples
///
/// ```
/// use numby::security::sanitize_terminal_string;
///
/// // Normal text passes through
/// let result = sanitize_terminal_string("Hello World");
/// assert_eq!(result, "Hello World");
///
/// // Control characters removed
/// let dangerous = "Hello\x1b[31m World";
/// let safe = sanitize_terminal_string(dangerous);
/// assert!(!safe.contains('\x1b'));
///
/// // Length limited to 200 chars
/// let long = "x".repeat(300);
/// let safe = sanitize_terminal_string(&long);
/// assert_eq!(safe.len(), 200);
/// ```
pub fn sanitize_terminal_string(s: &str) -> String {
    s.chars()
        .filter(|c| !c.is_control()) // Remove ALL control characters
        .take(200) // Limit length
        .collect()
}

/// Maximum allowed expression length in characters.
pub const MAX_EXPR_LENGTH: usize = 10_000;

/// Validate input size to prevent excessive memory usage.
///
/// # Arguments
///
/// * `input` - The input string to validate
///
/// # Errors
///
/// Returns error if input exceeds [`MAX_EXPR_LENGTH`].
///
/// # Examples
///
/// ```
/// use numby::security::validate_input_size;
///
/// // Short input is valid
/// assert!(validate_input_size("2 + 2").is_ok());
///
/// // Extremely long input fails
/// let huge = "x".repeat(20_000);
/// assert!(validate_input_size(&huge).is_err());
/// ```
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
