#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIGURATION="${CONFIGURATION:-release}"
APP_NAME="macOS"
PRODUCT_NAME="MOSMacApp"
APP_DIR="$ROOT_DIR/.build/${APP_NAME}.app"

cd "$ROOT_DIR"
swift build -c "$CONFIGURATION" --product "$PRODUCT_NAME"

BIN="$ROOT_DIR/.build/$CONFIGURATION/$PRODUCT_NAME"
if [[ ! -x "$BIN" ]]; then
  BIN="$(find "$ROOT_DIR/.build" -path "*/$CONFIGURATION/$PRODUCT_NAME" -type f | head -n 1)"
fi

if [[ ! -x "$BIN" ]]; then
  echo "Unable to locate built executable for $PRODUCT_NAME" >&2
  exit 1
fi

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$BIN" "$APP_DIR/Contents/MacOS/macOS"

cat > "$APP_DIR/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>macOS</string>
  <key>CFBundleIdentifier</key>
  <string>com.macos.androidemulator</string>
  <key>CFBundleName</key>
  <string>macOS</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

echo "$APP_DIR"
