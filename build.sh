#!/bin/bash
set -e

echo "🔨 Building Numby..."

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Paths
MACOS_APP_LIB="Numby/Numby/libnumby.a"
MACOS_APP_RESOURCES="Numby/Numby/Resources"

echo -e "${BLUE}📚 Building static library (size-optimized for macOS app)...${NC}"
cargo build --profile release-lib --lib

LIB_SIZE=$(ls -lh target/release-lib/libnumby.a | awk '{print $5}')
echo -e "${GREEN}✓ Library built: target/release-lib/libnumby.a (${LIB_SIZE})${NC}"

echo -e "${BLUE}🚀 Building CLI binary (performance-optimized)...${NC}"
export RUSTFLAGS=""  # Clear bitcode flags for CLI build
cargo build --profile release-cli --bin numby

CLI_SIZE=$(ls -lh target/release-cli/numby | awk '{print $5}')
echo -e "${GREEN}✓ CLI built: target/release-cli/numby (${CLI_SIZE})${NC}"

echo -e "${BLUE}📦 Copying artifacts for macOS app...${NC}"
cp target/release-lib/libnumby.a "$MACOS_APP_LIB"
echo -e "${GREEN}✓ Copied library to ${MACOS_APP_LIB}${NC}"

# Xcode expects CLI binary at target/release/numby
mkdir -p target/release
cp target/release-cli/numby target/release/numby

# Sign the CLI binary if a signing identity is available
if [ -n "$SIGNING_IDENTITY" ]; then
    echo -e "${BLUE}🔐 Signing CLI binary...${NC}"
    codesign --force --sign "$SIGNING_IDENTITY" --timestamp --options runtime target/release/numby
    echo -e "${GREEN}✓ CLI binary signed${NC}"
elif security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
    echo -e "${BLUE}🔐 Signing CLI binary with Developer ID Application certificate...${NC}"
    codesign --force --sign "Developer ID Application" --timestamp --options runtime target/release/numby
    echo -e "${GREEN}✓ CLI binary signed${NC}"
elif security find-identity -v -p codesigning | grep -q "Apple Development"; then
    echo -e "${BLUE}🔐 Signing CLI binary with Apple Development certificate...${NC}"
    codesign --force --sign "Apple Development" --timestamp --options runtime target/release/numby
    echo -e "${GREEN}✓ CLI binary signed${NC}"
else
    echo -e "${YELLOW}⚠️  No signing identity found, CLI will be ad-hoc signed${NC}"
fi

echo -e "${GREEN}✓ Copied CLI to target/release/numby for Xcode${NC}"

echo -e "${BLUE}🍎 Building macOS app...${NC}"
xcodebuild -project Numby/Numby.xcodeproj \
  -scheme Numby \
  -configuration Debug \
  -derivedDataPath Numby/build \
  clean build

APP_PATH="Numby/build/Build/Products/Debug/Numby.app"
if [ -d "$APP_PATH" ]; then
  echo -e "${GREEN}✓ macOS app built: ${APP_PATH}${NC}"

  # Re-sign the CLI binary in the app bundle (Xcode may have overwritten it)
  CLI_IN_APP="$APP_PATH/Contents/Resources/numby"
  if [ -f "$CLI_IN_APP" ]; then
    echo -e "${BLUE}🔐 Re-signing CLI binary in app bundle...${NC}"
    if [ -n "$SIGNING_IDENTITY" ]; then
      codesign --force --sign "$SIGNING_IDENTITY" --timestamp --options runtime "$CLI_IN_APP"
    elif security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
      codesign --force --sign "Developer ID Application" --timestamp --options runtime "$CLI_IN_APP"
    elif security find-identity -v -p codesigning | grep -q "Apple Development"; then
      codesign --force --sign "Apple Development" --timestamp --options runtime "$CLI_IN_APP"
    fi
    echo -e "${GREEN}✓ CLI binary in app bundle signed${NC}"

    # Notarize the CLI binary (requires Developer ID)
    if security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
      echo -e "${BLUE}📤 Notarizing CLI binary (this may take a few minutes)...${NC}"
      echo -e "${YELLOW}Note: You need to store your Apple ID credentials first:${NC}"
      echo -e "${YELLOW}  xcrun notarytool store-credentials --apple-id YOUR_APPLE_ID --team-id QW4U57CXJX${NC}"
      echo ""

      # Create a zip for notarization
      ZIP_PATH="$PROJECT_DIR/numby-cli.zip"
      (cd "$(dirname "$CLI_IN_APP")" && zip -q "$ZIP_PATH" "$(basename "$CLI_IN_APP")")

      # Try to notarize (will fail if credentials not set up)
      if xcrun notarytool submit "$ZIP_PATH" --keychain-profile "notarytool-profile" --wait 2>/dev/null; then
        echo -e "${GREEN}✓ CLI binary notarized${NC}"
        rm "$ZIP_PATH"
      else
        echo -e "${YELLOW}⚠️  Notarization skipped (set up credentials with: xcrun notarytool store-credentials)${NC}"
        rm -f "$ZIP_PATH"
      fi
    fi
  fi

  # Show app bundle size
  APP_SIZE=$(du -sh "$APP_PATH" | awk '{print $1}')
  echo -e "${GREEN}  App bundle size: ${APP_SIZE}${NC}"
else
  echo -e "${YELLOW}⚠ App not found at expected location${NC}"
fi

echo ""
echo -e "${GREEN}✅ Build complete!${NC}"
echo ""
echo "Artifacts:"
echo "  • Library:  target/release-lib/libnumby.a (${LIB_SIZE})"
echo "  • CLI:      target/release-cli/numby (${CLI_SIZE})"
echo "  • macOS:    ${APP_PATH}"
