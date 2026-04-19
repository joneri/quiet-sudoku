#!/usr/bin/env bash
set -euo pipefail

APP_NAME="macSudoku"
BUNDLE_ID="dev.jonaseriksson.macSudoku"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_BUNDLE="$ROOT_DIR/dist/$APP_NAME.app"
STATE_FILE="$(mktemp "${TMPDIR:-/tmp}/macSudoku-ui-state.XXXXXX.json")"
SAVE_FILE="$(mktemp "${TMPDIR:-/tmp}/macSudoku-ui-save.XXXXXX.json")"

cleanup() {
  pkill -x "$APP_NAME" >/dev/null 2>&1 || true
  rm -f "$STATE_FILE"
  rm -f "$SAVE_FILE"
}
trap cleanup EXIT

"$ROOT_DIR/script/build_and_run.sh" --verify
pkill -x "$APP_NAME" >/dev/null 2>&1 || true

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

def cell(row, column):
    for item in state["cells"]:
        if item["row"] == row and item["column"] == column:
            return item
    raise KeyError((row, column))

sys.exit(0 if eval(expression, {"__builtins__": {}}, {"state": state, "cell": cell}) else 1)
PY
    then
      return 0
    fi

    sleep 0.1
  done

  echo "UI smoke test failed while waiting for: $label" >&2
  echo "State file: $STATE_FILE" >&2
  [[ -f "$STATE_FILE" ]] && cat "$STATE_FILE" >&2
  exit 1
}

state_value() {
  local expression="$1"
  /usr/bin/python3 - "$STATE_FILE" "$expression" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as handle:
    state = json.load(handle)

def editable_cells():
    return [cell for cell in state["cells"] if cell["given"] is None]

print(eval(sys.argv[2], {"__builtins__": {}}, {"state": state, "editable_cells": editable_cells}))
PY
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

wait_for_state 'state["boardSize"] == "large"' "initial large board size"
first_cell="$(state_value '"{} {}".format(editable_cells()[0]["row"], editable_cells()[0]["column"])')"
first_row="${first_cell%% *}"
first_column="${first_cell##* }"

click_cell "$first_row" "$first_column"
wait_for_state "state[\"selected\"][\"row\"] == $first_row and state[\"selected\"][\"column\"] == $first_column" "mouse click selects first editable cell"
send_text "4"
wait_for_state 'cell('"$first_row"', '"$first_column"')["value"] is None and cell('"$first_row"', '"$first_column"')["candidateValue"] == 4' "typing 4 creates a floating candidate"

pkill -x "$APP_NAME" >/dev/null 2>&1 || true
rm -f "$STATE_FILE"
touch "$STATE_FILE"

/usr/bin/open -n \
  --env "MACSUDOKU_UI_STATE_PATH=$STATE_FILE" \
  --env "MACSUDOKU_SAVE_PATH=$SAVE_FILE" \
  "$APP_BUNDLE"

wait_for_state 'cell('"$first_row"', '"$first_column"')["value"] is None and cell('"$first_row"', '"$first_column"')["candidateValue"] == 4' "saved floating candidate restores after relaunch"

echo "UI smoke test passed: keyboard candidate entry, mouse selection, and relaunch restore work."
