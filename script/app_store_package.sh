#!/usr/bin/env bash
set -euo pipefail

APP_NAME="StillgridSudoku"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
PKG_PATH="${STILLGRID_SUDOKU_APP_STORE_PKG_PATH:-$DIST_DIR/StillgridSudoku-app-store.pkg}"
SIGNING_IDENTITY="${STILLGRID_SUDOKU_SIGNING_IDENTITY:-}"
INSTALLER_SIGNING_IDENTITY="${STILLGRID_SUDOKU_INSTALLER_SIGNING_IDENTITY:-}"
PROFILE_PATH="${STILLGRID_SUDOKU_PROVISIONING_PROFILE_PATH:-}"

if [[ -z "$SIGNING_IDENTITY" ]]; then
  echo "STILLGRID_SUDOKU_SIGNING_IDENTITY must be set to an Apple Distribution or Mac App Distribution identity." >&2
  exit 1
fi

if [[ -z "$INSTALLER_SIGNING_IDENTITY" ]]; then
  echo "STILLGRID_SUDOKU_INSTALLER_SIGNING_IDENTITY must be set to a Mac Installer Distribution identity." >&2
  exit 1
fi

if [[ -z "$PROFILE_PATH" || ! -f "$PROFILE_PATH" ]]; then
  echo "STILLGRID_SUDOKU_PROVISIONING_PROFILE_PATH must point to a Mac App Store Connect provisioning profile." >&2
  exit 1
fi

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
