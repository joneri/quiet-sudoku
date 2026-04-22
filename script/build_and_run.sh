#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="QuietSudoku"
DISPLAY_NAME="Quiet Sudoku"
BUNDLE_ID="${MACSUDOKU_BUNDLE_ID:-se.jonaseriksson.macSudoku}"
MARKETING_VERSION="${MACSUDOKU_MARKETING_VERSION:-1.0}"
BUILD_NUMBER="${MACSUDOKU_BUILD_NUMBER:-1}"
MIN_SYSTEM_VERSION="15.0"
SIGNING_IDENTITY="${MACSUDOKU_SIGNING_IDENTITY:-}"
AD_HOC_SIGN="${MACSUDOKU_AD_HOC_SIGN:-0}"
ENTITLEMENTS_PATH="${MACSUDOKU_ENTITLEMENTS_PATH:-}"
PROVISIONING_PROFILE_PATH="${MACSUDOKU_PROVISIONING_PROFILE_PATH:-}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
DEFAULT_ENTITLEMENTS="$ROOT_DIR/Config/QuietSudoku.entitlements"
GENERATED_ENTITLEMENTS="$DIST_DIR/$APP_NAME.generated.entitlements"
APP_ICON_SOURCE="$ROOT_DIR/Config/QuietSudoku.icns"
APP_ICON_NAME="QuietSudoku.icns"

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

swift build
BUILD_BINARY="$(swift build --show-bin-path)/$APP_NAME"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS" "$APP_RESOURCES"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"

if [[ -f "$APP_ICON_SOURCE" ]]; then
  cp "$APP_ICON_SOURCE" "$APP_RESOURCES/$APP_ICON_NAME"
fi

if [[ -n "$PROVISIONING_PROFILE_PATH" ]]; then
  if [[ ! -f "$PROVISIONING_PROFILE_PATH" ]]; then
    echo "Provisioning profile not found: $PROVISIONING_PROFILE_PATH" >&2
    exit 1
  fi

  cp "$PROVISIONING_PROFILE_PATH" "$APP_CONTENTS/embedded.provisionprofile"
fi

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleDisplayName</key>
  <string>$DISPLAY_NAME</string>
  <key>CFBundleName</key>
  <string>$DISPLAY_NAME</string>
  <key>CFBundleIconFile</key>
  <string>$APP_ICON_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$MARKETING_VERSION</string>
  <key>CFBundleVersion</key>
  <string>$BUILD_NUMBER</string>
  <key>LSApplicationCategoryType</key>
  <string>public.app-category.puzzle-games</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
  <key>NSSupportsAutomaticGraphicsSwitching</key>
  <true/>
</dict>
</plist>
PLIST

sign_app_if_requested() {
  local entitlements="${ENTITLEMENTS_PATH:-$DEFAULT_ENTITLEMENTS}"

  if [[ -z "$SIGNING_IDENTITY" && "$AD_HOC_SIGN" != "1" ]]; then
    return 0
  fi

  if [[ -n "$PROVISIONING_PROFILE_PATH" ]]; then
    local profile_plist
    profile_plist="$(mktemp)"
    security cms -D -i "$PROVISIONING_PROFILE_PATH" >"$profile_plist"

    local app_identifier
    local team_identifier
    local keychain_group
    app_identifier="$(/usr/libexec/PlistBuddy -c 'Print :Entitlements:com.apple.application-identifier' "$profile_plist")"
    team_identifier="$(/usr/libexec/PlistBuddy -c 'Print :Entitlements:com.apple.developer.team-identifier' "$profile_plist")"
    keychain_group="$(/usr/libexec/PlistBuddy -c 'Print :Entitlements:keychain-access-groups:0' "$profile_plist")"
    rm -f "$profile_plist"

    cat >"$GENERATED_ENTITLEMENTS" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>com.apple.application-identifier</key>
  <string>$app_identifier</string>
  <key>com.apple.developer.team-identifier</key>
  <string>$team_identifier</string>
  <key>com.apple.security.app-sandbox</key>
  <true/>
  <key>com.apple.security.files.user-selected.read-write</key>
  <true/>
  <key>keychain-access-groups</key>
  <array>
    <string>$keychain_group</string>
  </array>
</dict>
</plist>
PLIST
    entitlements="$GENERATED_ENTITLEMENTS"
  fi

  local identity="$SIGNING_IDENTITY"
  if [[ -z "$identity" ]]; then
    identity="-"
  fi

  /usr/bin/codesign \
    --force \
    --options runtime \
    --timestamp \
    --entitlements "$entitlements" \
    --sign "$identity" \
    "$APP_BUNDLE"
}

sign_app_if_requested

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  --build|build)
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify|--build]" >&2
    exit 2
    ;;
esac
