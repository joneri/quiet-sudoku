#!/usr/bin/env bash
set -euo pipefail

APP_NAME="StillgridSudoku"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_BUNDLE="$ROOT_DIR/dist/$APP_NAME.app"
STATE_FILE="$(mktemp "${TMPDIR:-/tmp}/StillgridSudoku-lock-state.XXXXXX.json")"
SAVE_FILE="$(mktemp "${TMPDIR:-/tmp}/StillgridSudoku-lock-save.XXXXXX.json")"

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

snapshot = {
    "puzzle": {
        "puzzle": [[0 for _ in range(9)] for _ in range(9)],
        "solution": solution,
    },
    "values": [None for _ in range(81)],
    "candidateValues": [None if index != 1 else 3 for index in range(81)],
    "selectedCellID": 0,
    "boardSize": "large",
    "livesRemaining": 3,
}

with open(sys.argv[1], "w", encoding="utf-8") as handle:
    json.dump(snapshot, handle)
PY

/usr/bin/open -n \
  --env "STILLGRID_SUDOKU_UI_STATE_PATH=$STATE_FILE" \
  --env "STILLGRID_SUDOKU_SAVE_PATH=$SAVE_FILE" \
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

  echo "Lock/lives smoke test failed while waiting for: $label" >&2
  [[ -f "$STATE_FILE" ]] && cat "$STATE_FILE" >&2
  exit 1
}

press_accessibility_button() {
  local match="$1"
  local pid
  pid="$(pgrep -x "$APP_NAME" | head -n 1)"

  /usr/bin/swift - "$pid" "$match" <<'SWIFT'
import AppKit
import CoreGraphics
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

send_text() {
  local text="$1"
  /usr/bin/osascript <<OSA
tell application "$APP_NAME" to activate
delay 0.1
tell application "System Events" to keystroke "$text"
OSA
}

wait_for_state 'state["livesRemaining"] == 3 and state["candidateCellCount"] == 1 and state["isLockAllEnabled"] == False and state["lifeLossFeedbackTriggerCount"] == 0 and cell(0, 0)["value"] is None and cell(0, 0)["candidateValue"] is None' "initial lock test state with Lock all disabled for one candidate"
send_text "2"
wait_for_state 'state["livesRemaining"] == 3 and state["candidateCellCount"] == 2 and state["isLockAllEnabled"] == True and cell(0, 0)["value"] is None and cell(0, 0)["candidateValue"] == 2' "second floating candidate enables Lock all without counting"
press_accessibility_button "lock-candidate-cell-0-0"
wait_for_state 'state["livesRemaining"] == 2 and state["isLockAllEnabled"] == True and state["lifeLossFeedbackTriggerCount"] == 1 and cell(0, 0)["value"] is None and cell(0, 0)["candidateValue"] == 2' "wrong cell lock loses one life, triggers feedback, and keeps candidate unlocked"
send_text "1"
wait_for_state 'state["livesRemaining"] == 2 and state["isLockAllEnabled"] == True and cell(0, 0)["value"] is None and cell(0, 0)["candidateValue"] == 1' "correct candidate floats before lock"
press_accessibility_button "lock-candidate-cell-0-0"
wait_for_state 'state["livesRemaining"] == 2 and state["candidateCellCount"] == 1 and state["isLockAllEnabled"] == False and cell(0, 0)["value"] == 1 and cell(0, 0)["candidateValue"] is None' "correct cell lock commits value and disables Lock all again"

echo "Lock/lives smoke test passed: Lock all is disabled below two candidates, wrong locks cost a life with feedback, correct locks commit."
