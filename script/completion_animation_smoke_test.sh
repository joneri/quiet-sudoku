#!/usr/bin/env bash
set -euo pipefail

APP_NAME="macSudoku"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_BUNDLE="$ROOT_DIR/dist/$APP_NAME.app"
STATE_FILE="$(mktemp "${TMPDIR:-/tmp}/macSudoku-complete-state.XXXXXX.json")"
SAVE_FILE="$(mktemp "${TMPDIR:-/tmp}/macSudoku-complete-save.XXXXXX.json")"

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

values = [value for row in solution for value in row]
values[3] = None

snapshot = {
    "puzzle": {
        "puzzle": [[0 for _ in range(9)] for _ in range(9)],
        "solution": solution,
    },
    "values": values,
    "selectedCellID": 3,
    "boardSize": "large",
}

with open(sys.argv[1], "w", encoding="utf-8") as handle:
    json.dump(snapshot, handle)
PY

/usr/bin/open -n \
  --env "MACSUDOKU_UI_STATE_PATH=$STATE_FILE" \
  --env "MACSUDOKU_SAVE_PATH=$SAVE_FILE" \
  "$APP_BUNDLE"

wait_for_state() {
  local expression="$1"
  local label="$2"

  for _ in $(seq 1 80); do
    if [[ -s "$STATE_FILE" ]] && /usr/bin/python3 - "$STATE_FILE" "$expression" <<'PY'
import json
import sys

path, expression = sys.argv[1], sys.argv[2]

try:
    with open(path, "r", encoding="utf-8") as handle:
        state = json.load(handle)
except Exception:
    sys.exit(1)

sys.exit(0 if eval(expression, {"__builtins__": {}}, {"state": state}) else 1)
PY
    then
      return 0
    fi

    sleep 0.1
  done

  echo "Completion animation smoke test failed while waiting for: $label" >&2
  [[ -f "$STATE_FILE" ]] && cat "$STATE_FILE" >&2
  exit 1
}

send_text() {
  local text="$1"
  /usr/bin/osascript <<OSA
tell application "$APP_NAME" to activate
delay 0.1
tell application "System Events" to keystroke "$text"
OSA
}

click_cell() {
  local row="$1"
  local column="$2"
  local pid
  pid="$(pgrep -x "$APP_NAME" | head -n 1)"

  /usr/bin/swift - "$pid" "$row" "$column" <<'SWIFT'
import AppKit
import Foundation

let pid = pid_t(Int32(CommandLine.arguments[1])!)
let row = CommandLine.arguments[2]
let column = CommandLine.arguments[3]
let targetIdentifier = "sudoku-cell-\(row)-\(column)"

func children(of element: AXUIElement) -> [AXUIElement] {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &value) == .success else {
        return []
    }

    return (value as? [AXUIElement]) ?? []
}

func stringAttribute(_ name: String, of element: AXUIElement) -> String? {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else {
        return nil
    }

    return value as? String
}

func findElement(identifier: String, in element: AXUIElement) -> AXUIElement? {
    if stringAttribute("AXIdentifier", of: element) == identifier {
        return element
    }

    for child in children(of: element) {
        if let match = findElement(identifier: identifier, in: child) {
            return match
        }
    }

    return nil
}

guard let app = NSRunningApplication(processIdentifier: pid) else {
    fputs("Could not find running macSudoku app\n", stderr)
    exit(1)
}

app.activate()
Thread.sleep(forTimeInterval: 0.1)

let appElement = AXUIElementCreateApplication(pid)
guard let cell = findElement(identifier: targetIdentifier, in: appElement) else {
    fputs("Could not find \(targetIdentifier) through Accessibility\n", stderr)
    exit(2)
}

let result = AXUIElementPerformAction(cell, kAXPressAction as CFString)
guard result == .success else {
    fputs("Could not press \(targetIdentifier). Result: \(result.rawValue)\n", stderr)
    exit(2)
}
SWIFT
}

wait_for_state 'state["isComplete"] == False and state["sparkleTriggerCount"] == 0' "nearly complete puzzle starts without completion sparkle"
click_cell 0 3
wait_for_state 'state["selected"]["row"] == 0 and state["selected"]["column"] == 3' "last empty cell is selected"
send_text "4"
wait_for_state 'state["isComplete"] == True and state["sparkleTriggerCount"] == 1' "final correct digit solves puzzle and triggers exactly one sparkle"

echo "Completion animation smoke test passed: sparkle triggers only when the puzzle becomes complete."
