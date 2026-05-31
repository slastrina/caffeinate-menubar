#!/usr/bin/env bash
# Submit a signed .app to Apple's notary service, wait for the result, then
# staple the notarization ticket so the bundle is trusted offline.
#
# Required env:
#   APPLE_ID            — Apple Developer account email
#   APPLE_TEAM_ID       — 10-character Team ID
#   APPLE_APP_PASSWORD  — app-specific password generated at appleid.apple.com
#
# Usage:
#   ./scripts/notarize.sh path/to/CaffeinateMenubar.app
#
# Notarytool accepts .zip / .dmg / .pkg, not raw .app bundles, so we build a
# disposable submission zip with ditto, submit, then staple the original .app.

set -euo pipefail

APP_PATH="${1:-build/CaffeinateMenubar.app}"

if [ ! -d "$APP_PATH" ]; then
    echo "ERROR: $APP_PATH does not exist" >&2
    exit 1
fi

: "${APPLE_ID:?APPLE_ID must be set}"
: "${APPLE_TEAM_ID:?APPLE_TEAM_ID must be set}"
: "${APPLE_APP_PASSWORD:?APPLE_APP_PASSWORD must be set}"

SUBMIT_ZIP="${APP_PATH%.app}-notarize.zip"

echo "==> Building submission zip: ${SUBMIT_ZIP}"
rm -f "$SUBMIT_ZIP"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$SUBMIT_ZIP"

echo "==> Submitting to notarytool (this may take a few minutes)"
xcrun notarytool submit "$SUBMIT_ZIP" \
    --apple-id "$APPLE_ID" \
    --team-id "$APPLE_TEAM_ID" \
    --password "$APPLE_APP_PASSWORD" \
    --wait

echo "==> Stapling ticket onto ${APP_PATH}"
xcrun stapler staple "$APP_PATH"

echo "==> Validating stapled bundle"
xcrun stapler validate "$APP_PATH"
spctl --assess --type execute --verbose=4 "$APP_PATH" 2>&1 | tail -3 || true

rm -f "$SUBMIT_ZIP"
echo "==> Notarization complete"
