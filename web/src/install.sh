#!/bin/bash
set -eu

# Numby CLI Installer
# This script detects your OS and architecture, downloads the appropriate binary from GitHub releases,
# and installs it to a local bin directory.

REPO="vivy-company/numby"

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

# Get latest release tag
echo "Fetching latest release..."
VERSION=$(curl -sSL "https://api.github.com/repos/${REPO}/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
if [ -z "$VERSION" ]; then
    echo "Error: Could not fetch latest version"
    exit 1
fi

# Set binary name and download URL
BINARY_NAME="numby-${VERSION}-${OS}-${ARCH}"
if [ "$OS" = "windows" ]; then
    BINARY_NAME="${BINARY_NAME}.exe"
    DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${VERSION}/${BINARY_NAME}"
else
    DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${VERSION}/${BINARY_NAME}.tar.gz"
fi

echo "Detected OS: $OS, Architecture: $ARCH"
echo "Downloading $BINARY_NAME from $DOWNLOAD_URL"

# Create temp directory
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Download and extract binary
if [ "$OS" = "windows" ]; then
    if ! curl --fail -L -o numby.exe "$DOWNLOAD_URL"; then
        echo "Error: Failed to download binary from $DOWNLOAD_URL"
        exit 1
    fi
else
    if ! curl --fail -L -o archive.tar.gz "$DOWNLOAD_URL"; then
        echo "Error: Failed to download binary from $DOWNLOAD_URL"
        exit 1
    fi
    tar -xzf archive.tar.gz
    rm archive.tar.gz
    chmod +x "numby-${VERSION}-${OS}-${ARCH}"
    mv "numby-${VERSION}-${OS}-${ARCH}" numby
fi

# Determine install directory
if [ "$OS" = "windows" ]; then
    INSTALL_DIR="$HOME/bin"
    BINARY_FILE="numby.exe"
else
    INSTALL_DIR="$HOME/.local/bin"
    BINARY_FILE="numby"
fi

mkdir -p "$INSTALL_DIR"

# Move binary
mv "$BINARY_FILE" "$INSTALL_DIR/"

echo "Successfully installed numby ${VERSION} to $INSTALL_DIR"
echo ""
echo "Make sure $INSTALL_DIR is in your PATH"
echo "You can add it with: export PATH=\"$INSTALL_DIR:\$PATH\""
echo "To make it permanent, add the export to your shell profile (e.g., ~/.bashrc or ~/.zshrc)"
echo ""
echo "Run 'numby' to start the calculator!"

# Cleanup
cd /
rm -rf "$TEMP_DIR"