#!/bin/bash
set -euo pipefail

echo "🔨 Building Numby..."

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Paths
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MACOS_APP_LIB="Numby/Numby/libnumby.a"
MACOS_APP_RESOURCES="Numby/Numby/Resources"

# Temp file tracking for cleanup
ZIP_PATH=""
NOTARIZE_OUTPUT=""
SIGNING_IDENTITY="${SIGNING_IDENTITY:-}"

# Cleanup trap
cleanup() {
    if [ -n "$ZIP_PATH" ] && [ -f "$ZIP_PATH" ]; then
        rm -f "$ZIP_PATH"
    fi
    if [ -n "$NOTARIZE_OUTPUT" ] && [ -f "$NOTARIZE_OUTPUT" ]; then
        rm -f "$NOTARIZE_OUTPUT"
    fi
}
trap cleanup EXIT

echo -e "${BLUE}📚 Building static library (size-optimized for macOS app)...${NC}"
# Apply embed-bitcode=no for staticlib to reduce size (conflicts with LTO, so only for lib)
# Set deployment target to match Xcode project (prevents version mismatch warnings)
export MACOSX_DEPLOYMENT_TARGET=13.5
export RUSTFLAGS="-C embed-bitcode=no"
cargo build --profile release-lib --lib
unset RUSTFLAGS
unset MACOSX_DEPLOYMENT_TARGET

LIB_SIZE=$(ls -lh target/release-lib/libnumby.a | awk '{print $5}')
echo -e "${GREEN}✓ Library built: target/release-lib/libnumby.a (${LIB_SIZE})${NC}"

echo -e "${BLUE}📦 Copying library for macOS app...${NC}"
cp target/release-lib/libnumby.a "$MACOS_APP_LIB"
echo -e "${GREEN}✓ Copied library to ${MACOS_APP_LIB}${NC}"

echo ""
echo -e "${GREEN}✅ Build complete!${NC}"
echo ""
echo "Artifacts:"
echo "  • Library:  target/release-lib/libnumby.a (${LIB_SIZE})"
echo ""
echo "To build the macOS app, open Numby.xcodeproj in Xcode and build from there."
