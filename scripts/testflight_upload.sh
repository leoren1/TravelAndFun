#!/usr/bin/env bash
#
# testflight_upload.sh — Build a signed App Store (distribution) IPA and upload
# it to TestFlight via App Store Connect. Used by the Jenkins TestFlight job.
#
# Requirements:
#   - Flutter SDK + Xcode + a paid Apple Developer account (team 7XWG24CTXD)
#   - App Store Connect API Key:
#       ~/.appstoreconnect/private_keys/AuthKey_<KEYID>.p8
#       ~/.appstoreconnect/config.env  with:  export TF_KEY_ID=...; export TF_ISSUER_ID=...
#   - The app must already exist in App Store Connect (bundle id below).
#
set -euo pipefail

FLUTTER_BIN_DIR="${FLUTTER_BIN_DIR:-$HOME/development/flutter/bin}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="$FLUTTER_BIN_DIR:/opt/homebrew/bin:$PATH"
cd "$PROJECT_DIR"

# --- App Store Connect API key config (kept OUTSIDE the repo) ---------------
CONFIG="${ASC_CONFIG:-$HOME/.appstoreconnect/config.env}"
# shellcheck disable=SC1090
[ -f "$CONFIG" ] && source "$CONFIG"
: "${TF_KEY_ID:?Set TF_KEY_ID in $CONFIG (App Store Connect API Key ID)}"
: "${TF_ISSUER_ID:?Set TF_ISSUER_ID in $CONFIG (App Store Connect Issuer ID)}"

TEAM_ID="${DEVELOPMENT_TEAM:-7XWG24CTXD}"
KEY_PATH="$HOME/.appstoreconnect/private_keys/AuthKey_${TF_KEY_ID}.p8"
[ -f "$KEY_PATH" ] || { echo "ERROR: API key not found at $KEY_PATH"; exit 1; }

echo "==> Project: $PROJECT_DIR"
echo "==> Flutter: $(flutter --version | head -1)"
echo "==> Team: $TEAM_ID  KeyID: $TF_KEY_ID"

# --- Unique, increasing TestFlight build number ----------------------------
BUILD_NO="$(date +%y%m%d%H%M)"   # e.g. 2605301230 — monotonic, < 2^32
echo "==> TestFlight build number: $BUILD_NO"

# --- Flutter assets / config -----------------------------------------------
flutter pub get
flutter build ios --release --config-only --build-number="$BUILD_NO"

OUT="build/testflight"
ARCHIVE="$OUT/Runner.xcarchive"
rm -rf "$OUT"; mkdir -p "$OUT"

# --- Archive (distribution signing, auto-created via the API key) ----------
echo "==> Archiving (Release)..."
xcodebuild \
  -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE" \
  -allowProvisioningUpdates \
  -authenticationKeyPath "$KEY_PATH" \
  -authenticationKeyID "$TF_KEY_ID" \
  -authenticationKeyIssuerID "$TF_ISSUER_ID" \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  CURRENT_PROJECT_VERSION="$BUILD_NO" \
  archive

# --- Export + upload to TestFlight (destination=upload uploads directly) ----
cat > "$OUT/ExportOptions.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key><string>app-store-connect</string>
  <key>destination</key><string>upload</string>
  <key>teamID</key><string>$TEAM_ID</string>
  <key>signingStyle</key><string>automatic</string>
  <key>uploadSymbols</key><true/>
  <key>manageAppVersionAndBuildNumber</key><false/>
</dict>
</plist>
PLIST

echo "==> Exporting & uploading to TestFlight..."
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportPath "$OUT/export" \
  -exportOptionsPlist "$OUT/ExportOptions.plist" \
  -allowProvisioningUpdates \
  -authenticationKeyPath "$KEY_PATH" \
  -authenticationKeyID "$TF_KEY_ID" \
  -authenticationKeyIssuerID "$TF_ISSUER_ID"

echo "==> DONE: build $BUILD_NO uploaded to TestFlight (now processing in App Store Connect)."
