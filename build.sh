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
IOS_DEVICE_LIB="Numby/iOS/libnumby-ios.a"
IOS_SIM_LIB="Numby/iOS/libnumby-ios-sim.a"
VISIONOS_DEVICE_LIB="Numby/visionOS/libnumby-visionos.a"
VISIONOS_SIM_LIB="Numby/visionOS/libnumby-visionos-sim.a"
XCFRAMEWORK_PATH="Numby/libnumby.xcframework"

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

build_macos() {
    echo -e "${BLUE}📚 Building static library for macOS (ARM64 only)...${NC}"
    export MACOSX_DEPLOYMENT_TARGET=13.5
    export RUSTFLAGS="-C embed-bitcode=no"
    cargo build --profile release-lib --lib --target aarch64-apple-darwin
    unset RUSTFLAGS
    unset MACOSX_DEPLOYMENT_TARGET

    cp target/aarch64-apple-darwin/release-lib/libnumby.a "$MACOS_APP_LIB"

    LIB_SIZE=$(ls -lh "$MACOS_APP_LIB" | awk '{print $5}')
    echo -e "${GREEN}✓ macOS library (ARM64): ${MACOS_APP_LIB} (${LIB_SIZE})${NC}"
}

build_ios() {
    echo -e "${BLUE}📱 Building static library for iOS (ARM64 only)...${NC}"

    # iOS device (arm64)
    echo "  Building for iOS device (arm64)..."
    export IPHONEOS_DEPLOYMENT_TARGET=17.0
    cargo build --profile release-lib --lib --target aarch64-apple-ios
    unset IPHONEOS_DEPLOYMENT_TARGET

    # iOS simulator (arm64 only)
    echo "  Building for iOS simulator (arm64)..."
    cargo build --profile release-lib --lib --target aarch64-apple-ios-sim

    # Create iOS device library
    mkdir -p "$(dirname "$IOS_DEVICE_LIB")"
    cp target/aarch64-apple-ios/release-lib/libnumby.a "$IOS_DEVICE_LIB"

    # Create iOS simulator library
    mkdir -p "$(dirname "$IOS_SIM_LIB")"
    cp target/aarch64-apple-ios-sim/release-lib/libnumby.a "$IOS_SIM_LIB"

    IOS_DEV_SIZE=$(ls -lh "$IOS_DEVICE_LIB" | awk '{print $5}')
    IOS_SIM_SIZE=$(ls -lh "$IOS_SIM_LIB" | awk '{print $5}')
    echo -e "${GREEN}✓ iOS device (ARM64): ${IOS_DEVICE_LIB} (${IOS_DEV_SIZE})${NC}"
    echo -e "${GREEN}✓ iOS simulator (ARM64): ${IOS_SIM_LIB} (${IOS_SIM_SIZE})${NC}"
}

build_visionos() {
    echo -e "${BLUE}🥽 Building static library for visionOS (ARM64 only)...${NC}"

    # visionOS device (arm64)
    echo "  Building for visionOS device (arm64)..."
    export XROS_DEPLOYMENT_TARGET=1.0
    cargo +nightly build --profile release-lib --lib --target aarch64-apple-visionos \
        -Zbuild-std=std,panic_abort --no-default-features --features visionos
    unset XROS_DEPLOYMENT_TARGET

    # visionOS simulator (arm64)
    echo "  Building for visionOS simulator (arm64)..."
    cargo +nightly build --profile release-lib --lib --target aarch64-apple-visionos-sim \
        -Zbuild-std=std,panic_abort --no-default-features --features visionos

    # Create visionOS device library
    mkdir -p "$(dirname "$VISIONOS_DEVICE_LIB")"
    cp target/aarch64-apple-visionos/release-lib/libnumby.a "$VISIONOS_DEVICE_LIB"

    # Create visionOS simulator library
    mkdir -p "$(dirname "$VISIONOS_SIM_LIB")"
    cp target/aarch64-apple-visionos-sim/release-lib/libnumby.a "$VISIONOS_SIM_LIB"

    VISIONOS_DEV_SIZE=$(ls -lh "$VISIONOS_DEVICE_LIB" | awk '{print $5}')
    VISIONOS_SIM_SIZE=$(ls -lh "$VISIONOS_SIM_LIB" | awk '{print $5}')
    echo -e "${GREEN}✓ visionOS device (ARM64): ${VISIONOS_DEVICE_LIB} (${VISIONOS_DEV_SIZE})${NC}"
    echo -e "${GREEN}✓ visionOS simulator (ARM64): ${VISIONOS_SIM_LIB} (${VISIONOS_SIM_SIZE})${NC}"
}

create_xcframework() {
    echo -e "${BLUE}📦 Creating XCFramework...${NC}"

    rm -rf "$XCFRAMEWORK_PATH"

    xcodebuild -create-xcframework \
        -library "$MACOS_APP_LIB" \
        -library "$IOS_DEVICE_LIB" \
        -library "$IOS_SIM_LIB" \
        -library "$VISIONOS_DEVICE_LIB" \
        -library "$VISIONOS_SIM_LIB" \
        -output "$XCFRAMEWORK_PATH"

    echo -e "${GREEN}✓ XCFramework created: ${XCFRAMEWORK_PATH}${NC}"
}

# Build all platforms
build_macos
build_ios
build_visionos
create_xcframework

echo ""
echo -e "${GREEN}✅ Build complete!${NC}"
echo ""
echo "Artifacts:"
echo "  • macOS library:        ${MACOS_APP_LIB}"
echo "  • iOS device:           ${IOS_DEVICE_LIB}"
echo "  • iOS simulator:        ${IOS_SIM_LIB}"
echo "  • visionOS device:      ${VISIONOS_DEVICE_LIB}"
echo "  • visionOS simulator:   ${VISIONOS_SIM_LIB}"
echo "  • XCFramework:          ${XCFRAMEWORK_PATH}"
echo ""
echo "To build the app, open Numby.xcodeproj in Xcode and select your target."
