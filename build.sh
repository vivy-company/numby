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
ANDROID_JNILIBS_DIR="Android/app/src/main/jniLibs"

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
    # Build without TUI dependencies (ratatui, crossterm, arboard) - not needed for Swift app
    cargo build --profile release-lib --lib --target aarch64-apple-darwin --no-default-features
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
    # Build without TUI dependencies - not needed for Swift app
    cargo build --profile release-lib --lib --target aarch64-apple-ios --no-default-features
    unset IPHONEOS_DEPLOYMENT_TARGET

    # iOS simulator (arm64 only)
    echo "  Building for iOS simulator (arm64)..."
    cargo build --profile release-lib --lib --target aarch64-apple-ios-sim --no-default-features

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

build_android() {
    echo -e "${BLUE}🤖 Building shared library for Android...${NC}"

    # Check if cargo-ndk is installed
    if ! command -v cargo-ndk &> /dev/null; then
        echo -e "${YELLOW}⚠️  cargo-ndk not found. Install with: cargo install cargo-ndk${NC}"
        echo -e "${YELLOW}   Also ensure Android NDK is installed and ANDROID_NDK_HOME is set${NC}"
        return 1
    fi

    # Check if Android targets are installed
    if ! rustup target list --installed | grep -q "aarch64-linux-android"; then
        echo -e "${YELLOW}⚠️  Android targets not installed. Installing...${NC}"
        rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android
    fi

    # Create jniLibs directories
    mkdir -p "$ANDROID_JNILIBS_DIR/arm64-v8a"
    mkdir -p "$ANDROID_JNILIBS_DIR/armeabi-v7a"
    mkdir -p "$ANDROID_JNILIBS_DIR/x86_64"

    # Build for all Android ABIs (--lib to skip TUI binary which doesn't compile for Android)
    echo "  Building for arm64-v8a (ARM64)..."
    cargo ndk -t arm64-v8a --platform 26 -o "$ANDROID_JNILIBS_DIR" build --release --lib --no-default-features --features android

    echo "  Building for armeabi-v7a (ARM32)..."
    cargo ndk -t armeabi-v7a --platform 26 -o "$ANDROID_JNILIBS_DIR" build --release --lib --no-default-features --features android

    echo "  Building for x86_64 (emulator)..."
    cargo ndk -t x86_64 --platform 26 -o "$ANDROID_JNILIBS_DIR" build --release --lib --no-default-features --features android

    # Report sizes
    if [ -f "$ANDROID_JNILIBS_DIR/arm64-v8a/libnumby.so" ]; then
        ARM64_SIZE=$(ls -lh "$ANDROID_JNILIBS_DIR/arm64-v8a/libnumby.so" | awk '{print $5}')
        echo -e "${GREEN}✓ Android arm64-v8a: ${ANDROID_JNILIBS_DIR}/arm64-v8a/libnumby.so (${ARM64_SIZE})${NC}"
    fi
    if [ -f "$ANDROID_JNILIBS_DIR/armeabi-v7a/libnumby.so" ]; then
        ARM32_SIZE=$(ls -lh "$ANDROID_JNILIBS_DIR/armeabi-v7a/libnumby.so" | awk '{print $5}')
        echo -e "${GREEN}✓ Android armeabi-v7a: ${ANDROID_JNILIBS_DIR}/armeabi-v7a/libnumby.so (${ARM32_SIZE})${NC}"
    fi
    if [ -f "$ANDROID_JNILIBS_DIR/x86_64/libnumby.so" ]; then
        X86_64_SIZE=$(ls -lh "$ANDROID_JNILIBS_DIR/x86_64/libnumby.so" | awk '{print $5}')
        echo -e "${GREEN}✓ Android x86_64: ${ANDROID_JNILIBS_DIR}/x86_64/libnumby.so (${X86_64_SIZE})${NC}"
    fi
}

# Parse command line arguments
BUILD_ANDROID=false
BUILD_APPLE=true

while [[ $# -gt 0 ]]; do
    case $1 in
        --android)
            BUILD_ANDROID=true
            shift
            ;;
        --android-only)
            BUILD_ANDROID=true
            BUILD_APPLE=false
            shift
            ;;
        --help)
            echo "Usage: ./build.sh [options]"
            echo "Options:"
            echo "  --android       Build Android libraries in addition to Apple"
            echo "  --android-only  Build only Android libraries"
            echo "  --help          Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Build platforms
if [ "$BUILD_APPLE" = true ]; then
    build_macos
    build_ios
    build_visionos
    create_xcframework
fi

if [ "$BUILD_ANDROID" = true ]; then
    build_android
fi

echo ""
echo -e "${GREEN}✅ Build complete!${NC}"
echo ""
echo "Artifacts:"
if [ "$BUILD_APPLE" = true ]; then
    echo "  • macOS library:        ${MACOS_APP_LIB}"
    echo "  • iOS device:           ${IOS_DEVICE_LIB}"
    echo "  • iOS simulator:        ${IOS_SIM_LIB}"
    echo "  • visionOS device:      ${VISIONOS_DEVICE_LIB}"
    echo "  • visionOS simulator:   ${VISIONOS_SIM_LIB}"
    echo "  • XCFramework:          ${XCFRAMEWORK_PATH}"
fi
if [ "$BUILD_ANDROID" = true ]; then
    echo "  • Android arm64-v8a:    ${ANDROID_JNILIBS_DIR}/arm64-v8a/libnumby.so"
    echo "  • Android armeabi-v7a:  ${ANDROID_JNILIBS_DIR}/armeabi-v7a/libnumby.so"
    echo "  • Android x86_64:       ${ANDROID_JNILIBS_DIR}/x86_64/libnumby.so"
fi
echo ""
if [ "$BUILD_APPLE" = true ]; then
    echo "To build the iOS/macOS app, open Numby.xcodeproj in Xcode and select your target."
fi
if [ "$BUILD_ANDROID" = true ]; then
    echo "To build the Android app, open the Android folder in Android Studio."
fi
