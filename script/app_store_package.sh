#!/usr/bin/env bash
set -euo pipefail

APP_NAME="StillgridSudoku"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
PKG_PATH="${STILLGRID_SUDOKU_APP_STORE_PKG_PATH:-${MACSUDOKU_APP_STORE_PKG_PATH:-$DIST_DIR/StillgridSudoku-app-store.pkg}}"
SIGNING_IDENTITY="${STILLGRID_SUDOKU_SIGNING_IDENTITY:-${MACSUDOKU_SIGNING_IDENTITY:-}}"
INSTALLER_SIGNING_IDENTITY="${STILLGRID_SUDOKU_INSTALLER_SIGNING_IDENTITY:-${MACSUDOKU_INSTALLER_SIGNING_IDENTITY:-}}"
PROFILE_PATH="${STILLGRID_SUDOKU_PROVISIONING_PROFILE_PATH:-${MACSUDOKU_PROVISIONING_PROFILE_PATH:-}}"

if [[ -z "$SIGNING_IDENTITY" ]]; then
  SIGNING_IDENTITY="$(security find-identity -p codesigning -v | sed -n 's/.*"\(Apple Distribution: [^"]*\)".*/\1/p' | head -n 1)"
fi

if [[ -z "$INSTALLER_SIGNING_IDENTITY" ]]; then
  INSTALLER_SIGNING_IDENTITY="$(security find-identity -p basic -v | sed -n 's/.*"\(3rd Party Mac Developer Installer: [^"]*\)".*/\1/p' | head -n 1)"
fi

if [[ -z "$INSTALLER_SIGNING_IDENTITY" ]]; then
  INSTALLER_SIGNING_IDENTITY="$(security find-identity -p basic -v | sed -n 's/.*"\(Mac Installer Distribution: [^"]*\)".*/\1/p' | head -n 1)"
fi

if [[ -z "$PROFILE_PATH" && -f "$HOME/Downloads/macSudoku_Mac_App_Store.provisionprofile" ]]; then
  PROFILE_PATH="$HOME/Downloads/macSudoku_Mac_App_Store.provisionprofile"
fi

if [[ -z "$SIGNING_IDENTITY" ]]; then
  echo "Set STILLGRID_SUDOKU_SIGNING_IDENTITY or MACSUDOKU_SIGNING_IDENTITY to an Apple Distribution or Mac App Distribution identity." >&2
  exit 1
fi

if [[ -z "$INSTALLER_SIGNING_IDENTITY" ]]; then
  echo "Set STILLGRID_SUDOKU_INSTALLER_SIGNING_IDENTITY or MACSUDOKU_INSTALLER_SIGNING_IDENTITY to a Mac installer signing identity." >&2
  exit 1
fi

if [[ -z "$PROFILE_PATH" || ! -f "$PROFILE_PATH" ]]; then
  echo "Set STILLGRID_SUDOKU_PROVISIONING_PROFILE_PATH or MACSUDOKU_PROVISIONING_PROFILE_PATH to a Mac App Store Connect provisioning profile." >&2
  exit 1
fi

export STILLGRID_SUDOKU_SIGNING_IDENTITY="$SIGNING_IDENTITY"
export STILLGRID_SUDOKU_INSTALLER_SIGNING_IDENTITY="$INSTALLER_SIGNING_IDENTITY"
export STILLGRID_SUDOKU_PROVISIONING_PROFILE_PATH="$PROFILE_PATH"

"$ROOT_DIR/script/app_store_preflight.sh"
"$ROOT_DIR/script/build_and_run.sh" --build

if [[ ! -f "$APP_BUNDLE/Contents/embedded.provisionprofile" ]]; then
  echo "Built app is missing Contents/embedded.provisionprofile." >&2
  exit 1
fi

/usr/bin/xattr -cr "$APP_BUNDLE"
if /usr/bin/xattr -pr com.apple.quarantine "$APP_BUNDLE" >/dev/null 2>&1; then
  echo "Built app still contains com.apple.quarantine extended attributes." >&2
  exit 1
fi

rm -f "$PKG_PATH"
/usr/bin/productbuild \
  --component "$APP_BUNDLE" /Applications \
  --sign "$INSTALLER_SIGNING_IDENTITY" \
  "$PKG_PATH"

/usr/sbin/pkgutil --check-signature "$PKG_PATH"

echo "Created Mac App Store package: $PKG_PATH"
