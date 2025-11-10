#!/bin/bash
set -eu

# Numby CLI Installer
# This script detects your OS and architecture, downloads the appropriate binary from GitHub releases,
# and installs it to a local bin directory.

REPO="wiedymi/numby"
VERSION="latest"  # Or specify a version like "v0.1.0"

# Detect OS
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
case $OS in
    linux)
        OS="linux"
        ;;
    darwin)
        OS="macos"
        ;;
    mingw*|msys*|cygwin*)
        OS="windows"
        ;;
    *)
        echo "Unsupported OS: $OS"
        exit 1
        ;;
esac

# Detect architecture
ARCH=$(uname -m)
case $ARCH in
    x86_64)
        ARCH="x86_64"
        ;;
    aarch64|arm64)
        ARCH="aarch64"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

# Set binary name and download URL
BINARY_NAME="numby-${ARCH}-${OS}"
if [ "$OS" = "windows" ]; then
    BINARY_NAME="${BINARY_NAME}.exe"
fi

DOWNLOAD_URL="https://github.com/${REPO}/releases/${VERSION}/download/${BINARY_NAME}"

echo "Detected OS: $OS, Architecture: $ARCH"
echo "Downloading $BINARY_NAME from $DOWNLOAD_URL"

# Create temp directory
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Download binary
if ! curl --fail -L -o numby "$DOWNLOAD_URL"; then
    echo "Error: Failed to download binary from $DOWNLOAD_URL"
    exit 1
fi

# Make executable (skip on Windows)
if [ "$OS" != "windows" ]; then
    chmod +x numby
fi

# Determine install directory
if [ "$OS" = "windows" ]; then
    INSTALL_DIR="$HOME/bin"
else
    INSTALL_DIR="$HOME/.local/bin"
fi

mkdir -p "$INSTALL_DIR"

# Move binary
mv numby "$INSTALL_DIR/"

echo "Installed numby to $INSTALL_DIR"
echo "Make sure $INSTALL_DIR is in your PATH"
echo "You can add it with: export PATH=\"$INSTALL_DIR:\$PATH\""
echo "To make it permanent, add the export to your shell profile (e.g., ~/.bashrc or ~/.zshrc)"

# Cleanup
cd /
rm -rf "$TEMP_DIR"