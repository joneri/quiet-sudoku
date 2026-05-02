#!/usr/bin/env bash
set -euo pipefail

APP_NAME="StillgridSudoku"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUNDLE_ID="${STILLGRID_SUDOKU_BUNDLE_ID:-se.jonaseriksson.macSudoku}"
PROFILE_PATH="${STILLGRID_SUDOKU_PROVISIONING_PROFILE_PATH:-}"
SIGNING_IDENTITY="${STILLGRID_SUDOKU_SIGNING_IDENTITY:-}"
INSTALLER_SIGNING_IDENTITY="${STILLGRID_SUDOKU_INSTALLER_SIGNING_IDENTITY:-}"
ASC_USERNAME="${STILLGRID_SUDOKU_ASC_USERNAME:-}"
ASC_PASSWORD="${STILLGRID_SUDOKU_ASC_PASSWORD:-}"
ASC_API_KEY="${STILLGRID_SUDOKU_ASC_API_KEY:-}"
ASC_API_ISSUER="${STILLGRID_SUDOKU_ASC_API_ISSUER:-}"
ASC_P8_FILE_PATH="${STILLGRID_SUDOKU_ASC_P8_FILE_PATH:-}"
ASC_PROVIDER_PUBLIC_ID="${STILLGRID_SUDOKU_ASC_PROVIDER_PUBLIC_ID:-}"

failures=0
warnings=0

pass() {
  printf "PASS: %s\n" "$1"
}

fail() {
  printf "FAIL: %s\n" "$1"
  failures=$((failures + 1))
}

warn() {
  printf "WARN: %s\n" "$1"
  warnings=$((warnings + 1))
}

plist_value() {
  /usr/libexec/PlistBuddy -c "Print :$1" "$2" 2>/dev/null || true
}

auth_args=()
if [[ -n "$ASC_API_KEY" && -n "$ASC_API_ISSUER" ]]; then
  auth_args=(--api-key "$ASC_API_KEY" --api-issuer "$ASC_API_ISSUER")
  [[ -n "$ASC_P8_FILE_PATH" ]] && auth_args+=(--p8-file-path "$ASC_P8_FILE_PATH")
elif [[ -n "$ASC_USERNAME" && -n "$ASC_PASSWORD" ]]; then
  auth_args=(-u "$ASC_USERNAME" -p "$ASC_PASSWORD")
else
  auth_args=()
fi

[[ -d /Applications/Xcode.app ]] && pass "Xcode.app is installed" || fail "Xcode.app is missing"
if xcrun -f altool >/dev/null 2>&1; then
  pass "altool is available through xcrun"
else
  fail "altool is not available; select full Xcode with xcode-select"
fi

if security find-identity -p codesigning -v | grep -Fq "$SIGNING_IDENTITY"; then
  pass "app signing identity is available"
else
  fail "app signing identity is unavailable: ${SIGNING_IDENTITY:-unset}"
fi

if [[ -n "$INSTALLER_SIGNING_IDENTITY" ]] && security find-identity -p basic -v | grep -Fq "$INSTALLER_SIGNING_IDENTITY"; then
  pass "installer signing identity is available"
else
  fail "installer signing identity is unavailable: ${INSTALLER_SIGNING_IDENTITY:-unset}"
fi

if [[ -z "$PROFILE_PATH" ]]; then
  fail "STILLGRID_SUDOKU_PROVISIONING_PROFILE_PATH is unset"
elif [[ ! -f "$PROFILE_PATH" ]]; then
  fail "provisioning profile not found: $PROFILE_PATH"
else
  profile_plist="$(mktemp)"
  if security cms -D -i "$PROFILE_PATH" >"$profile_plist"; then
    pass "provisioning profile can be decoded"

    profile_name="$(plist_value Name "$profile_plist")"
    profile_uuid="$(plist_value UUID "$profile_plist")"
    profile_expiration="$(plist_value ExpirationDate "$profile_plist")"
    app_identifier="$(plist_value Entitlements:com.apple.application-identifier "$profile_plist")"
    team_identifier="$(plist_value TeamIdentifier:0 "$profile_plist")"
    provisioned_devices="$(plist_value ProvisionedDevices "$profile_plist")"

    [[ -n "$profile_name" ]] && pass "profile name: $profile_name" || warn "profile name is missing"
    [[ -n "$profile_uuid" ]] && pass "profile UUID: $profile_uuid" || warn "profile UUID is missing"
    [[ -n "$profile_expiration" ]] && pass "profile expires: $profile_expiration" || warn "profile expiration is missing"

    if [[ "$app_identifier" == *".$BUNDLE_ID" ]]; then
      pass "profile app identifier matches $BUNDLE_ID"
    else
      fail "profile app identifier '$app_identifier' does not match $BUNDLE_ID"
    fi

    [[ -n "$team_identifier" ]] && pass "profile team identifier: $team_identifier" || warn "profile team identifier is missing"

    if [[ -z "$provisioned_devices" ]]; then
      pass "profile is not device-limited, as expected for App Store distribution"
    else
      fail "profile appears device-limited; create a Mac App Store Connect provisioning profile"
    fi
  else
    fail "provisioning profile could not be decoded"
  fi
  rm -f "$profile_plist"
fi

if [[ -n "$PROFILE_PATH" && -f "$PROFILE_PATH" && -n "$SIGNING_IDENTITY" ]]; then
  if STILLGRID_SUDOKU_SIGNING_IDENTITY="$SIGNING_IDENTITY" \
    STILLGRID_SUDOKU_PROVISIONING_PROFILE_PATH="$PROFILE_PATH" \
    "$ROOT_DIR/script/build_and_run.sh" --build >/dev/null; then
    signed_entitlements="$(codesign -d --entitlements :- "$ROOT_DIR/dist/$APP_NAME.app" 2>/dev/null || true)"
    profile_plist="$(mktemp)"
    security cms -D -i "$PROFILE_PATH" >"$profile_plist"
    expected_app_identifier="$(/usr/libexec/PlistBuddy -c 'Print :Entitlements:com.apple.application-identifier' "$profile_plist" 2>/dev/null || true)"
    rm -f "$profile_plist"

    if [[ -n "$expected_app_identifier" && "$signed_entitlements" == *"$expected_app_identifier"* ]]; then
      pass "signed app application identifier matches provisioning profile"
    else
      fail "signed app is missing the provisioning profile application identifier"
    fi

  else
    fail "could not build a signed app with the provisioning profile"
  fi
fi

if [[ -n "$PROFILE_PATH" && -f "$PROFILE_PATH" ]]; then
  if xattr -p com.apple.quarantine "$PROFILE_PATH" >/dev/null 2>&1; then
    warn "source provisioning profile has quarantine metadata; package step will strip extended attributes"
  fi
fi

if ((${#auth_args[@]})); then
  list_args=(--list-apps --filter-bundle-id "$BUNDLE_ID" --filter-platform macos --output-format json)
  [[ -n "$ASC_PROVIDER_PUBLIC_ID" ]] && list_args+=(--provider-public-id "$ASC_PROVIDER_PUBLIC_ID")

  if xcrun altool "${list_args[@]}" "${auth_args[@]}" >/tmp/stillgrid_sudoku_appstore_apps.json; then
    if grep -q "$BUNDLE_ID" /tmp/stillgrid_sudoku_appstore_apps.json; then
      pass "App Store Connect app record exists for $BUNDLE_ID"
    else
      fail "App Store Connect is reachable, but no macOS app record was found for $BUNDLE_ID"
    fi
  else
    fail "could not query App Store Connect app records with the provided credentials"
  fi
else
  warn "App Store Connect credentials are unset; app record existence could not be checked"
fi

if (( failures > 0 )); then
  echo "App Store preflight failed with $failures blocking issue(s) and $warnings warning(s)."
  exit 1
fi

echo "App Store preflight completed with $warnings warning(s)."
