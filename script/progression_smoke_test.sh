#!/usr/bin/env bash
set -euo pipefail

APP_NAME="macSudoku"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_BUNDLE="$ROOT_DIR/dist/$APP_NAME.app"
STATE_FILE="$(mktemp "${TMPDIR:-/tmp}/macSudoku-progression-state.XXXXXX.json")"
SAVE_FILE="$(mktemp "${TMPDIR:-/tmp}/macSudoku-progression-save.XXXXXX.json")"

cleanup() {
  pkill -x "$APP_NAME" >/dev/null 2>&1 || true
  rm -f "$STATE_FILE"
  rm -f "$SAVE_FILE"
}
trap cleanup EXIT

"$ROOT_DIR/script/build_and_run.sh" --verify
pkill -x "$APP_NAME" >/dev/null 2>&1 || true

/usr/bin/python3 - "$SAVE_FILE" <<'PY'
import json
import sys

solution = [
    [1, 2, 3, 4, 5, 6, 7, 8, 9],
    [4, 5, 6, 7, 8, 9, 1, 2, 3],
    [7, 8, 9, 1, 2, 3, 4, 5, 6],
    [2, 3, 4, 5, 6, 7, 8, 9, 1],
    [5, 6, 7, 8, 9, 1, 2, 3, 4],
    [8, 9, 1, 2, 3, 4, 5, 6, 7],
    [3, 4, 5, 6, 7, 8, 9, 1, 2],
    [6, 7, 8, 9, 1, 2, 3, 4, 5],
    [9, 1, 2, 3, 4, 5, 6, 7, 8],
]

values = []
for row in range(9):
    for column in range(9):
        value = solution[row][column]
        if value == 3 or (row < 3 and column < 3):
            values.append(value)
        else:
            values.append(None)

snapshot = {
    "puzzle": {
        "puzzle": [[0 for _ in range(9)] for _ in range(9)],
        "solution": solution,
    },
    "values": values,
    "selectedCellID": 0,
    "boardSize": "large",
}

with open(sys.argv[1], "w", encoding="utf-8") as handle:
    json.dump(snapshot, handle)
PY

/usr/bin/open -n \
  --env "MACSUDOKU_UI_STATE_PATH=$STATE_FILE" \
  --env "MACSUDOKU_SAVE_PATH=$SAVE_FILE" \
  "$APP_BUNDLE"

for _ in $(seq 1 80); do
  if [[ -s "$STATE_FILE" ]] && /usr/bin/python3 - "$STATE_FILE" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as handle:
    state = json.load(handle)

assert 3 in state["completedDigits"]
assert 0 in state["completedBlocks"]
assert 1 not in state["completedDigits"]
assert 1 not in state["completedBlocks"]
PY
  then
    echo "Progression smoke test passed: completed digit and block are detected."
    exit 0
  fi

  sleep 0.1
done

echo "Progression smoke test failed." >&2
[[ -f "$STATE_FILE" ]] && cat "$STATE_FILE" >&2
exit 1

