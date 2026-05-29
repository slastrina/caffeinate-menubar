#!/usr/bin/env bash
# Package the release binary into a CaffeinateMenubar.app bundle suitable for
# distribution (drag-to-Applications install). Output: build/CaffeinateMenubar.app
#
# Usage:
#   ./scripts/make-app.sh [version]
#
# If [version] is omitted, it defaults to whatever is in $RELEASE_VERSION or 0.0.0.

set -euo pipefail

VERSION="${1:-${RELEASE_VERSION:-0.0.0}}"
VERSION="${VERSION#v}"  # strip leading "v" if passed something like "v0.1.0"

APP_NAME="CaffeinateMenubar"
BUNDLE_ID="com.samuellastrina.caffeinatemenubar"
OUT_DIR="build"
APP_PATH="${OUT_DIR}/${APP_NAME}.app"

# Allow the caller (e.g. GitHub Actions building a universal binary) to point us
# at a pre-built binary. Default to a fresh local build at .build/release/.
BIN_PATH="${BIN_PATH:-.build/release/${APP_NAME}}"
if [ ! -f "$BIN_PATH" ]; then
    echo "==> Building release binary"
    swift build -c release
    BIN_PATH=".build/release/${APP_NAME}"
fi
if [ ! -f "$BIN_PATH" ]; then
    echo "ERROR: release binary not found at $BIN_PATH" >&2
    exit 1
fi

echo "==> Assembling ${APP_PATH}"
rm -rf "$APP_PATH"
mkdir -p "${APP_PATH}/Contents/MacOS"
mkdir -p "${APP_PATH}/Contents/Resources"

cp "$BIN_PATH" "${APP_PATH}/Contents/MacOS/${APP_NAME}"
chmod +x "${APP_PATH}/Contents/MacOS/${APP_NAME}"

# Icon
if [ -f "Resources/AppIcon.icns" ]; then
    cp "Resources/AppIcon.icns" "${APP_PATH}/Contents/Resources/AppIcon.icns"
    echo "==> Bundled AppIcon.icns"
else
    echo "WARN: Resources/AppIcon.icns not found — app will use the generic icon" >&2
fi

cat > "${APP_PATH}/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIconName</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © Samuel La Strina. All rights reserved.</string>
</dict>
</plist>
EOF

# Ad-hoc sign so the binary is valid per Apple's "arm64 binaries must be signed"
# rule. This does NOT make Gatekeeper trust the app (would need a paid Developer
# ID Application certificate + notarization) — it just makes the binary loadable
# once the quarantine attribute is removed.
echo "==> Ad-hoc codesigning"
codesign --force --deep --sign - --timestamp=none "${APP_PATH}"
codesign --verify --verbose "${APP_PATH}" 2>&1 | tail -3 || true

echo "==> Built ${APP_PATH} (version ${VERSION})"
ls -lh "${APP_PATH}/Contents/MacOS/${APP_NAME}"
