#!/usr/bin/env bash
#
# Local release build script — archives, signs, creates DMG, notarizes.
#
# Always required:
#   APPLE_TEAM_ID      10-character Apple Team ID
#   NOTARY_APPLE_ID    Apple ID used for notarization
#   NOTARY_PASSWORD    App-specific password (appleid.apple.com → App-Specific Passwords)
#
# Optional — only needed if your Developer ID cert is NOT already in your login keychain
# (e.g. on a fresh machine or to test the CI cert-import path):
#   DEVELOPER_ID_CERTIFICATE_P12       Base64-encoded .p12 certificate
#   DEVELOPER_ID_CERTIFICATE_PASSWORD  Password for the .p12
#
# Usage (typical local run — Xcode already has your Apple ID and cert):
#   export APPLE_TEAM_ID="ABCDE12345"
#   export NOTARY_APPLE_ID="you@example.com"
#   export NOTARY_PASSWORD="xxxx-xxxx-xxxx-xxxx"
#   ./scripts/build-release.sh

set -euo pipefail

XCPRETTY=$(command -v xcpretty || true)
format() { if [[ -n "$XCPRETTY" ]]; then xcpretty; else cat; fi; }

# ── Validate required env vars ─────────────────────────────────────────────────

for var in APPLE_TEAM_ID NOTARY_APPLE_ID NOTARY_PASSWORD; do
    if [[ -z "${!var:-}" ]]; then
        echo "Error: $var is not set." >&2
        exit 1
    fi
done

# ── Config ─────────────────────────────────────────────────────────────────────

APP_NAME="HealthKitExporter"
SCHEME="HealthKitExporter"
VERSION=$(grep 'CFBundleShortVersionString' project.yml | sed 's/.*"\(.*\)".*/\1/')

BUILD_DIR="$(pwd)/build"
WORK_DIR=$(mktemp -d)
ARCHIVE_PATH="$WORK_DIR/$APP_NAME.xcarchive"
EXPORT_PATH="$WORK_DIR/export"
DMG_PATH="$WORK_DIR/$APP_NAME.dmg"
FINAL_DMG="$BUILD_DIR/$APP_NAME-v$VERSION.dmg"

echo "==> Building $APP_NAME v$VERSION"
echo "    Work dir: $WORK_DIR"

# ── Cleanup on exit ────────────────────────────────────────────────────────────

KEYCHAIN_PATH=""
# Capture existing keychains immediately so cleanup can always restore them
EXISTING_KEYCHAINS=$(security list-keychain -d user | tr -d '"' | tr -s ' \n' ' ' | xargs)

cleanup() {
    if [[ -n "$KEYCHAIN_PATH" ]]; then
        echo "==> Cleaning up keychain"
        security delete-keychain "$KEYCHAIN_PATH" 2>/dev/null || true
    fi
    # Always restore the original keychain list
    if [[ -n "$EXISTING_KEYCHAINS" ]]; then
        security list-keychain -d user -s $EXISTING_KEYCHAINS 2>/dev/null || true
    fi
    rm -rf "$WORK_DIR"
}
trap cleanup EXIT

# ── Import certificate (optional) ──────────────────────────────────────────────

if [[ -n "${DEVELOPER_ID_CERTIFICATE_P12:-}" && -n "${DEVELOPER_ID_CERTIFICATE_PASSWORD:-}" ]]; then
    echo "==> Importing Developer ID certificate"

    KEYCHAIN_PASSWORD=$(openssl rand -base64 32)
    KEYCHAIN_PATH="$WORK_DIR/app-signing.keychain-db"
    CERT_PATH="$WORK_DIR/certificate.p12"

    echo "$DEVELOPER_ID_CERTIFICATE_P12" | base64 --decode > "$CERT_PATH"

    security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
    security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
    security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
    security import "$CERT_PATH" -P "$DEVELOPER_ID_CERTIFICATE_PASSWORD" -A -t cert -f pkcs12 -k "$KEYCHAIN_PATH"
    # Prepend new keychain but keep existing ones (login keychain holds Apple ID credentials)
    security list-keychain -d user -s "$KEYCHAIN_PATH" $EXISTING_KEYCHAINS
    security set-key-partition-list -S apple-tool:,apple: -s -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
else
    echo "==> Using existing keychain (no P12 provided)"
fi

# ── Generate project ───────────────────────────────────────────────────────────

echo "==> Generating Xcode project"
xcodegen generate --spec project.yml

# ── Archive ────────────────────────────────────────────────────────────────────

echo "==> Archiving"
xcodebuild archive \
    -scheme "$SCHEME" \
    -destination "generic/platform=macOS" \
    -archivePath "$ARCHIVE_PATH" \
    -allowProvisioningUpdates \
    -allowProvisioningDeviceRegistration \
    DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
    ENABLE_HARDENED_RUNTIME=YES \
    | format

# ── Export ─────────────────────────────────────────────────────────────────────

echo "==> Exporting archive"
EXPORT_PLIST="$WORK_DIR/ExportOptions.plist"
sed "s/\$(APPLE_TEAM_ID)/$APPLE_TEAM_ID/g" ExportOptions.plist > "$EXPORT_PLIST"

xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$EXPORT_PLIST" \
    -allowProvisioningUpdates \
    -allowProvisioningDeviceRegistration \
    | format

# ── Create DMG ─────────────────────────────────────────────────────────────────

echo "==> Creating DMG"
mkdir -p "$BUILD_DIR"

create-dmg \
    --volname "HealthKit Exporter" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon "$APP_NAME.app" 150 200 \
    --app-drop-link 450 200 \
    --no-internet-enable \
    --codesign "Developer ID Application" \
    "$DMG_PATH" \
    "$EXPORT_PATH/$APP_NAME.app"

# ── Notarize ───────────────────────────────────────────────────────────────────

echo "==> Notarizing DMG (this may take a few minutes)"
xcrun notarytool submit "$DMG_PATH" \
    --apple-id "$NOTARY_APPLE_ID" \
    --password "$NOTARY_PASSWORD" \
    --team-id "$APPLE_TEAM_ID" \
    --wait

# ── Staple ─────────────────────────────────────────────────────────────────────

echo "==> Stapling notarization ticket"
xcrun stapler staple "$DMG_PATH"

# ── Copy to build/ ─────────────────────────────────────────────────────────────

cp "$DMG_PATH" "$FINAL_DMG"

echo ""
echo "==> Done: $FINAL_DMG"
