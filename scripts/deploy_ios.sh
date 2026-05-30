#!/usr/bin/env bash
#
# deploy_ios.sh — Build the Flutter app and install it on a physically
# connected iPhone (USB). Used both locally and by the Jenkins pipeline.
#
# Requirements:
#   - Flutter SDK on PATH (or at ~/development/flutter/bin)
#   - Xcode with a signed-in Apple Developer Team (automatic signing)
#   - An iPhone connected via cable and trusted ("Trust This Computer")
#
# Env overrides:
#   DEVICE_ID        Flutter device id to target (default: first attached iOS device)
#   FLUTTER_BIN_DIR  Path to flutter/bin (default: ~/development/flutter/bin)
#   BUILD_MODE       release | debug | profile (default: release)
#
set -euo pipefail

FLUTTER_BIN_DIR="${FLUTTER_BIN_DIR:-$HOME/development/flutter/bin}"
BUILD_MODE="${BUILD_MODE:-release}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

export PATH="$FLUTTER_BIN_DIR:/opt/homebrew/bin:$PATH"

echo "==> Project: $PROJECT_DIR"
cd "$PROJECT_DIR"

command -v flutter >/dev/null 2>&1 || { echo "ERROR: flutter not found on PATH"; exit 1; }
echo "==> Flutter: $(flutter --version | head -1)"

# --- Resolve target device -------------------------------------------------
if [[ -z "${DEVICE_ID:-}" ]]; then
  # Pick the first attached physical iOS device (id pattern like 00008110-...)
  DEVICE_ID="$(flutter devices --machine 2>/dev/null \
    | grep -Eo '"id"[[:space:]]*:[[:space:]]*"[0-9A-Fa-f]{8}-[0-9A-Fa-f]{16}"' \
    | head -1 | sed -E 's/.*"([0-9A-Fa-f-]+)".*/\1/')"
fi

if [[ -z "${DEVICE_ID:-}" ]]; then
  echo "ERROR: No physical iOS device detected. Connect the iPhone via cable,"
  echo "       unlock it and tap 'Trust This Computer'."
  echo "Attached devices:"
  flutter devices || true
  exit 2
fi
echo "==> Target device: $DEVICE_ID"

# --- Dependencies ----------------------------------------------------------
echo "==> flutter pub get"
flutter pub get

# --- Build -----------------------------------------------------------------
# Build the signed device app with xcodebuild so we can pass the provisioning
# flags (auto-create/refresh profile, register new devices). Flutter assets are
# produced by the project's "Run Script" build phase (flutter assemble).
echo "==> flutter build (config + assets)"
flutter build ios --"$BUILD_MODE" --config-only

DERIVED="build/ios_signing"
echo "==> xcodebuild ($BUILD_MODE, signed) for device $DEVICE_ID"
xcodebuild \
  -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration "$(tr '[:lower:]' '[:upper:]' <<< ${BUILD_MODE:0:1})${BUILD_MODE:1}" \
  -destination "id=$DEVICE_ID" \
  -allowProvisioningUpdates \
  -allowProvisioningDeviceRegistration \
  -derivedDataPath "$DERIVED" \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM:-7XWG24CTXD}" \
  build

APP_PATH="$DERIVED/Build/Products/$(tr '[:lower:]' '[:upper:]' <<< ${BUILD_MODE:0:1})${BUILD_MODE:1}-iphoneos/Runner.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "ERROR: Build did not produce $APP_PATH"
  exit 3
fi
echo "==> Built & signed: $APP_PATH"

# --- Install on device -----------------------------------------------------
echo "==> Installing on device $DEVICE_ID via devicectl"
xcrun devicectl device install app --device "$DEVICE_ID" "$APP_PATH"

echo "==> DONE: app installed on $DEVICE_ID"
