#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PKG_PATH="${MACSUDOKU_APP_STORE_PKG_PATH:-$ROOT_DIR/dist/QuietSudoku-app-store.pkg}"
ACTION="${MACSUDOKU_UPLOAD_ACTION:-validate}"
ASC_USERNAME="${MACSUDOKU_ASC_USERNAME:-}"
ASC_PASSWORD="${MACSUDOKU_ASC_PASSWORD:-}"
ASC_API_KEY="${MACSUDOKU_ASC_API_KEY:-}"
ASC_API_ISSUER="${MACSUDOKU_ASC_API_ISSUER:-}"
ASC_P8_FILE_PATH="${MACSUDOKU_ASC_P8_FILE_PATH:-}"
ASC_PROVIDER_PUBLIC_ID="${MACSUDOKU_ASC_PROVIDER_PUBLIC_ID:-}"

if [[ ! -f "$PKG_PATH" ]]; then
  echo "Package not found: $PKG_PATH" >&2
  echo "Run ./script/app_store_package.sh first." >&2
  exit 1
fi

auth_args=()
if [[ -n "$ASC_API_KEY" && -n "$ASC_API_ISSUER" ]]; then
  auth_args=(--api-key "$ASC_API_KEY" --api-issuer "$ASC_API_ISSUER")
  [[ -n "$ASC_P8_FILE_PATH" ]] && auth_args+=(--p8-file-path "$ASC_P8_FILE_PATH")
elif [[ -n "$ASC_USERNAME" && -n "$ASC_PASSWORD" ]]; then
  auth_args=(-u "$ASC_USERNAME" -p "$ASC_PASSWORD")
else
  echo "Set either App Store Connect API credentials or username/password credentials." >&2
  echo "Preferred for local use: MACSUDOKU_ASC_USERNAME plus MACSUDOKU_ASC_PASSWORD=@keychain:<item>." >&2
  exit 1
fi

[[ -n "$ASC_PROVIDER_PUBLIC_ID" ]] && auth_args+=(--provider-public-id "$ASC_PROVIDER_PUBLIC_ID")

case "$ACTION" in
  validate)
    xcrun altool --validate-app "$PKG_PATH" "${auth_args[@]}" --output-format normal
    ;;
  upload)
    xcrun altool --upload-package "$PKG_PATH" "${auth_args[@]}" --show-progress --output-format normal
    ;;
  *)
    echo "MACSUDOKU_UPLOAD_ACTION must be 'validate' or 'upload'." >&2
    exit 2
    ;;
esac
