#!/usr/bin/env bash
set -euo pipefail

APP_NAME="StillgridSudoku"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_BUNDLE="$ROOT_DIR/dist/$APP_NAME.app"
INFO_PLIST="$APP_BUNDLE/Contents/Info.plist"
ENTITLEMENTS_PATH="${STILLGRID_SUDOKU_ENTITLEMENTS_PATH:-${MACSUDOKU_ENTITLEMENTS_PATH:-$ROOT_DIR/Config/StillgridSudoku.entitlements}}"
EXPECTED_BUNDLE_ID="${STILLGRID_SUDOKU_BUNDLE_ID:-${MACSUDOKU_BUNDLE_ID:-se.jonaseriksson.macSudoku}}"

failures=0

pass() {
  printf "PASS: %s\n" "$1"
}

fail() {
  printf "FAIL: %s\n" "$1"
  failures=$((failures + 1))
}

warn() {
  printf "WARN: %s\n" "$1"
}

STILLGRID_SUDOKU_AD_HOC_SIGN="${STILLGRID_SUDOKU_AD_HOC_SIGN:-1}" "$ROOT_DIR/script/build_and_run.sh" --verify >/dev/null
pkill -x "$APP_NAME" >/dev/null 2>&1 || true

[[ -d "$APP_BUNDLE" ]] && pass "app bundle exists" || fail "app bundle missing"
[[ -f "$INFO_PLIST" ]] && pass "Info.plist exists" || fail "Info.plist missing"
[[ -f "$ENTITLEMENTS_PATH" ]] && pass "distribution entitlements exist" || fail "distribution entitlements missing"

actual_bundle_id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$INFO_PLIST" 2>/dev/null || true)"
[[ "$actual_bundle_id" == "$EXPECTED_BUNDLE_ID" ]] \
  && pass "bundle identifier is $EXPECTED_BUNDLE_ID" \
  || fail "bundle identifier is '$actual_bundle_id', expected '$EXPECTED_BUNDLE_ID'"

for key in CFBundleShortVersionString CFBundleVersion LSApplicationCategoryType LSMinimumSystemVersion; do
  value="$(/usr/libexec/PlistBuddy -c "Print :$key" "$INFO_PLIST" 2>/dev/null || true)"
  [[ -n "$value" ]] && pass "Info.plist has $key=$value" || fail "Info.plist missing $key"
done

icon_file="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIconFile' "$INFO_PLIST" 2>/dev/null || true)"
if [[ -n "$icon_file" && -f "$APP_BUNDLE/Contents/Resources/$icon_file" ]]; then
  pass "app icon is bundled as $icon_file"
else
  fail "app icon missing from bundle resources"
fi

sandbox_enabled="$(/usr/libexec/PlistBuddy -c 'Print :com.apple.security.app-sandbox' "$ENTITLEMENTS_PATH" 2>/dev/null || true)"
[[ "$sandbox_enabled" == "true" ]] \
  && pass "App Sandbox entitlement enabled" \
  || fail "App Sandbox entitlement missing or false"

if security find-identity -p codesigning -v | grep -q "Apple Distribution"; then
  pass "Apple Distribution signing identity available"
else
  warn "No Apple Distribution signing identity found in this keychain"
fi

signature_output="$(codesign -dvvv --entitlements :- "$APP_BUNDLE" 2>&1 || true)"
if grep -q "Signature=adhoc" <<<"$signature_output"; then
  warn "app is ad-hoc signed for local validation; set STILLGRID_SUDOKU_SIGNING_IDENTITY for Apple Distribution signing"
elif grep -q "Authority=Apple Distribution" <<<"$signature_output"; then
  pass "app is signed with Apple Distribution authority"
else
  warn "app signing state is not Apple Distribution; inspect codesign output"
fi

if grep -q "com.apple.security.app-sandbox" <<<"$signature_output"; then
  pass "signed app includes sandbox entitlement"
else
  fail "signed app does not include sandbox entitlement"
fi

if (( failures > 0 )); then
  echo "Distribution readiness check failed with $failures blocking issue(s)."
  exit 1
fi

echo "Distribution readiness check completed. Warnings may still require Apple account or signing setup."
