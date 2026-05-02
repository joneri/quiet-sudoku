#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_ICON="${1:-$ROOT_DIR/Config/StillgridSudoku_app_icon_source.png}"
ICONSET="$ROOT_DIR/Config/StillgridSudoku.iconset"
ICON_FILE="$ROOT_DIR/Config/StillgridSudoku.icns"

if [[ ! -f "$SOURCE_ICON" ]]; then
  echo "Source icon not found: $SOURCE_ICON" >&2
  exit 1
fi

width="$(/usr/bin/sips -g pixelWidth "$SOURCE_ICON" 2>/dev/null | awk '/pixelWidth/ { print $2 }')"
height="$(/usr/bin/sips -g pixelHeight "$SOURCE_ICON" 2>/dev/null | awk '/pixelHeight/ { print $2 }')"

if [[ "$width" != "1024" || "$height" != "1024" ]]; then
  echo "Source icon must be 1024x1024 px. Found ${width}x${height}." >&2
  exit 1
fi

rm -rf "$ICONSET"
mkdir -p "$ICONSET"

while read -r size name; do
  /usr/bin/sips -z "$size" "$size" "$SOURCE_ICON" --out "$ICONSET/$name" >/dev/null
done <<'EOF'
16 icon_16x16.png
32 icon_16x16@2x.png
32 icon_32x32.png
64 icon_32x32@2x.png
128 icon_128x128.png
256 icon_128x128@2x.png
256 icon_256x256.png
512 icon_256x256@2x.png
512 icon_512x512.png
1024 icon_512x512@2x.png
EOF

/usr/bin/iconutil -c icns "$ICONSET" -o "$ICON_FILE"
rm -rf "$ICONSET"

echo "Generated $ICON_FILE from $SOURCE_ICON"
