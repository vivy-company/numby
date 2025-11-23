#!/bin/bash
set -euo pipefail

# Numby CLI Installer
# Downloads and installs the latest Numby binary from GitHub releases

REPO="vivy-company/numby"

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Cleanup handler
TEMP_DIR=""
cleanup() {
    local exit_code=$?
    if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
    if [ $exit_code -ne 0 ]; then
        echo -e "${RED}x Installation failed${NC}"
    fi
    return $exit_code
}
trap cleanup EXIT

# Logging helpers
log_info() {
    echo -e "${BLUE}>${NC} $1"
}

log_success() {
    echo -e "${GREEN}+${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}!${NC} $1"
}

log_error() {
    echo -e "${RED}x${NC} $1"
}

log_step() {
    echo -e "${BLUE}[$1/$2]${NC} $3"
}

track_analytics() {
    local name="$1"
    local os="$2"
    local arch="$3"
    local version="$4"
    local data='{"name":"'"${name}"'"}'
    [ -n "$os" ] && data+=',"os":"'"${os}"'"'
    [ -n "$arch" ] && data+=',"arch":"'"${arch}"'"'
    [ -n "$version" ] && data+=',"version":"'"${version}"'"'
    if command -v curl >/dev/null 2>&1; then
        curl -s --max-time 5 -X POST https://analytics.vivy.app/api/send \
            -H "Content-Type: application/json" \
            -d "{\"type\":\"event\",\"payload\":{\"website\":\"077e9dc0-07f8-440e-935e-a74cd5f170d6\",\"hostname\":\"numby.vivy.app\",\"url\":\"/install\",\"data\":${data}}}" \
            > /dev/null 2>&1 || true
    fi
}

# Check prerequisites
check_prerequisites() {
    local missing_deps=()

    for cmd in curl tar sed; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done

    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "Missing required commands: ${missing_deps[*]}"
        exit 1
    fi
}

# Retry wrapper for network operations
retry_download() {
    local max_attempts=3
    local timeout=15
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if [ $attempt -gt 1 ]; then
            log_info "Attempt $attempt of $max_attempts..."
        fi

        if curl --fail --connect-timeout $timeout --max-time 60 -# -L "$@"; then
            return 0
        fi

        if [ $attempt -lt $max_attempts ]; then
            log_warn "Download failed, retrying in 2 seconds..."
            sleep 2
        fi

        attempt=$((attempt + 1))
    done

    log_error "Download failed after $max_attempts attempts"
    return 1
}

# Detect OS
detect_os() {
    local os_raw=$(uname -s | tr '[:upper:]' '[:lower:]')
    case $os_raw in
        linux)
            echo "linux"
            ;;
        darwin)
            echo "macos"
            ;;
        mingw*|msys*|cygwin*)
            echo "windows"
            ;;
        *)
            log_error "Unsupported OS: $os_raw"
            exit 1
            ;;
    esac
}

# Detect architecture
detect_arch() {
    local arch_raw=$(uname -m)
    case $arch_raw in
        x86_64)
            echo "x86_64"
            ;;
        aarch64|arm64)
            echo "aarch64"
            ;;
        *)
            log_error "Unsupported architecture: $arch_raw"
            exit 1
            ;;
    esac
}

# Get shell config file
get_shell_config() {
    local shell_name=$(basename "$SHELL")
    case "$shell_name" in
        bash)
            echo "$HOME/.bashrc"
            ;;
        zsh)
            echo "$HOME/.zshrc"
            ;;
        fish)
            echo "$HOME/.config/fish/config.fish"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Check PATH configuration
check_path() {
    local install_dir="$1"

    if echo "$PATH" | grep -q "$install_dir"; then
        log_success "$install_dir is in your PATH"
        return 0
    fi

    echo ""
    log_warn "$install_dir is not in your PATH"
    echo ""

    local shell_config=$(get_shell_config)
    if [ -n "$shell_config" ]; then
        echo "  Add this line to $shell_config:"
        echo "    export PATH=\"$install_dir:\$PATH\""
        echo ""
        echo "  Then run: source $shell_config"
    else
        echo "  Add $install_dir to your PATH in your shell configuration"
    fi
    echo ""
}

# Main installation
main() {
    echo ""
    echo "Numby CLI Installer"
    echo ""

    # Step 1: Check prerequisites
    log_step 1 6 "Checking prerequisites..."
    check_prerequisites
    log_success "Prerequisites OK"

    # Step 2: Detect system
    log_step 2 6 "Detecting system..."
    OS=$(detect_os)
    ARCH=$(detect_arch)
    log_success "Detected: $OS / $ARCH"

        track_analytics "cli_install_start" "$OS" "$ARCH"

    # Step 3: Fetch latest release
    log_step 3 6 "Fetching latest release..."
    if command -v jq &> /dev/null; then
        VERSION=$(curl -sSL "https://api.github.com/repos/${REPO}/releases/latest" | jq -r '.tag_name')
    else
        VERSION=$(curl -sSL "https://api.github.com/repos/${REPO}/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
    fi

    if [ -z "$VERSION" ]; then
        log_error "Could not fetch latest version"
        exit 1
    fi
    log_success "Latest version: $VERSION"

    # Step 4: Download binary
    log_step 4 6 "Downloading binary..."

    BINARY_NAME="numby-${VERSION}-${OS}-${ARCH}"
    if [ "$OS" = "windows" ]; then
        BINARY_NAME="${BINARY_NAME}.exe"
        DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${VERSION}/${BINARY_NAME}"
    else
        DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${VERSION}/${BINARY_NAME}.tar.gz"
    fi

    TEMP_DIR=$(mktemp -d) || {
        log_error "Could not create temporary directory"
        exit 1
    }
    cd "$TEMP_DIR"

    if [ "$OS" = "windows" ]; then
        if ! retry_download -o numby.exe "$DOWNLOAD_URL"; then
            log_error "Failed to download binary"
            exit 1
        fi
        BINARY_FILE="numby.exe"
    else
        if ! retry_download -o archive.tar.gz "$DOWNLOAD_URL"; then
            log_error "Failed to download binary"
            exit 1
        fi

        if ! tar -xzf archive.tar.gz; then
            log_error "Failed to extract archive"
            exit 1
        fi

        rm archive.tar.gz
        mv "numby-${VERSION}-${OS}-${ARCH}" numby
        chmod +x numby
        BINARY_FILE="numby"
    fi

    log_success "Downloaded $BINARY_NAME"

    # Step 5: Install binary
    log_step 5 6 "Installing binary..."

    if [ "$OS" = "windows" ]; then
        INSTALL_DIR="$HOME/bin"
    else
        INSTALL_DIR="$HOME/.local/bin"
    fi

    mkdir -p "$INSTALL_DIR"
    mv "$BINARY_FILE" "$INSTALL_DIR/"

    # Make sure binary is executable
    if [ "$OS" != "windows" ]; then
        chmod +x "$INSTALL_DIR/numby"
    fi

    log_success "Installed to $INSTALL_DIR/numby"

    # Step 6: Verify installation
    log_step 6 6 "Verifying installation..."

    if [ ! -f "$INSTALL_DIR/$BINARY_FILE" ]; then
        log_error "Binary not found after installation"
        exit 1
    fi

    log_success "Installation verified"

        track_analytics "cli_install_success" "$OS" "$ARCH" "$VERSION"

    # Final status
    echo ""
    echo -e "${GREEN}Numby $VERSION installed successfully!${NC}"
    echo ""

    check_path "$INSTALL_DIR"

    echo "Run 'numby' to start the calculator!"
    echo ""
}

main
