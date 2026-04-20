#!/usr/bin/env bash
set -euo pipefail

APP_NAME="macSudoku"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_BUNDLE="$ROOT_DIR/dist/$APP_NAME.app"
STATE_FILE="$(mktemp "${TMPDIR:-/tmp}/macSudoku-level-state.XXXXXX.json")"
SAVE_FILE="$(mktemp "${TMPDIR:-/tmp}/macSudoku-level-save.XXXXXX.json")"

cleanup() {
  pkill -x "$APP_NAME" >/dev/null 2>&1 || true
  rm -f "$STATE_FILE"
  rm -f "$SAVE_FILE"
}
trap cleanup EXIT

"$ROOT_DIR/script/build_and_run.sh" --verify
pkill -x "$APP_NAME" >/dev/null 2>&1 || true

wait_for_state() {
  local expression="$1"
  local label="$2"

  for _ in $(seq 1 100); do
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

  echo "Level difficulty smoke test failed while waiting for: $label" >&2
  [[ -f "$STATE_FILE" ]] && cat "$STATE_FILE" >&2
  exit 1
}

write_nearly_complete_save() {
  local level="$1"

  /usr/bin/python3 - "$SAVE_FILE" "$level" <<'PY'
import json
import sys

path, level = sys.argv[1], int(sys.argv[2])

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
    "livesRemaining": 3,
    "level": {"number": level},
}

with open(path, "w", encoding="utf-8") as handle:
    json.dump(snapshot, handle)
PY
}

press_accessibility_button() {
  local match="$1"
  local pid
  pid="$(pgrep -x "$APP_NAME" | head -n 1)"

  /usr/bin/swift - "$pid" "$match" <<'SWIFT'
import AppKit
import Foundation

let pid = pid_t(Int32(CommandLine.arguments[1])!)
let match = CommandLine.arguments[2]

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

func isButton(_ element: AXUIElement) -> Bool {
    stringAttribute(kAXRoleAttribute, of: element) == kAXButtonRole
}

func matches(_ element: AXUIElement) -> Bool {
    [stringAttribute("AXIdentifier", of: element),
     stringAttribute(kAXDescriptionAttribute, of: element),
     stringAttribute(kAXTitleAttribute, of: element)]
        .compactMap { $0 }
        .contains(match)
        && isButton(element)
}

func findButton(in element: AXUIElement) -> AXUIElement? {
    if matches(element) {
        return element
    }

    for child in children(of: element) {
        if let match = findButton(in: child) {
            return match
        }
    }

    return nil
}

NSRunningApplication(processIdentifier: pid)?.activate()
Thread.sleep(forTimeInterval: 0.2)

let appElement = AXUIElementCreateApplication(pid)
guard let button = findButton(in: appElement) else {
    fputs("Could not find accessibility button: \(match)\n", stderr)
    exit(2)
}

let result = AXUIElementPerformAction(button, kAXPressAction as CFString)
guard result == .success else {
    fputs("Could not press \(match). Result: \(result.rawValue)\n", stderr)
    exit(2)
}
SWIFT
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

NSRunningApplication(processIdentifier: pid)?.activate()
Thread.sleep(forTimeInterval: 0.2)

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

send_text() {
  local text="$1"
  /usr/bin/osascript <<OSA
tell application "$APP_NAME" to activate
delay 0.1
tell application "System Events" to keystroke "$text"
OSA
}

advance_from_level_and_assert_next() {
  local current_level="$1"
  local next_level="$2"
  local expected_filled="$3"

  pkill -x "$APP_NAME" >/dev/null 2>&1 || true
  : > "$STATE_FILE"
  write_nearly_complete_save "$current_level"

  /usr/bin/open -n \
    --env "MACSUDOKU_UI_STATE_PATH=$STATE_FILE" \
    --env "MACSUDOKU_SAVE_PATH=$SAVE_FILE" \
    "$APP_BUNDLE"

  wait_for_state 'state["level"] == '"$current_level"' and state["isComplete"] == False' "level $current_level nearly complete state"
  click_cell 0 3
  wait_for_state 'state["selected"]["row"] == 0 and state["selected"]["column"] == 3' "level $current_level final cell selected"
  send_text "4"
  wait_for_state 'state["isComplete"] == False and state["cells"][3]["candidateValue"] == 4' "level $current_level final candidate"
  press_accessibility_button "lock-candidate-cell-0-3"
  wait_for_state 'state["isComplete"] == True and state["isConfirmingNewBoard"] == True' "level $current_level completion prompt"
  press_accessibility_button "confirm-new-board-button"
  wait_for_state 'state["level"] == '"$next_level"' and state["filledCellCount"] == '"$expected_filled"' and state["isComplete"] == False' "level $next_level generated with $expected_filled givens"
}

pkill -x "$APP_NAME" >/dev/null 2>&1 || true
rm -f "$SAVE_FILE"

/usr/bin/open -n \
  --env "MACSUDOKU_UI_STATE_PATH=$STATE_FILE" \
  --env "MACSUDOKU_SAVE_PATH=$SAVE_FILE" \
  "$APP_BUNDLE"

wait_for_state 'state["level"] == 1 and state["filledCellCount"] == 44' "fresh level 1 is easiest with 44 givens"

advance_from_level_and_assert_next 1 2 41
advance_from_level_and_assert_next 2 3 38
advance_from_level_and_assert_next 3 4 35
advance_from_level_and_assert_next 6 7 26
advance_from_level_and_assert_next 7 8 26

echo "Level difficulty smoke test passed: level 1 starts with 44 givens, later levels reduce givens to a 26-given floor."
