#!/usr/bin/env bash
set -euo pipefail

APP_NAME="macSudoku"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_BUNDLE="$ROOT_DIR/dist/$APP_NAME.app"
STATE_FILE="$(mktemp "${TMPDIR:-/tmp}/macSudoku-new-state.XXXXXX.json")"
SAVE_FILE="$(mktemp "${TMPDIR:-/tmp}/macSudoku-new-save.XXXXXX.json")"

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

sys.exit(0 if eval(expression, {"__builtins__": {}}, {"state": state}) else 1)
PY
    then
      return 0
    fi

    sleep 0.1
  done

  echo "New board smoke test failed while waiting for: $label" >&2
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

print(eval(sys.argv[2], {"__builtins__": {}}, {"state": state}))
PY
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
if result == .success {
    exit(0)
}

var positionValue: CFTypeRef?
var sizeValue: CFTypeRef?
guard
    AXUIElementCopyAttributeValue(button, kAXPositionAttribute as CFString, &positionValue) == .success,
    AXUIElementCopyAttributeValue(button, kAXSizeAttribute as CFString, &sizeValue) == .success,
    let rawPosition = positionValue,
    let rawSize = sizeValue,
    CFGetTypeID(rawPosition) == AXValueGetTypeID(),
    CFGetTypeID(rawSize) == AXValueGetTypeID()
else {
    fputs("Could not press \(match). AXPress result: \(result.rawValue), and no button geometry was available.\n", stderr)
    exit(2)
}

var origin = CGPoint.zero
var size = CGSize.zero
AXValueGetValue((rawPosition as! AXValue), .cgPoint, &origin)
AXValueGetValue((rawSize as! AXValue), .cgSize, &size)

let point = CGPoint(x: origin.x + size.width / 2, y: origin.y + size.height / 2)
let source = CGEventSource(stateID: .hidSystemState)
let down = CGEvent(mouseEventSource: source, mouseType: .leftMouseDown, mouseCursorPosition: point, mouseButton: .left)
let up = CGEvent(mouseEventSource: source, mouseType: .leftMouseUp, mouseCursorPosition: point, mouseButton: .left)
down?.post(tap: .cghidEventTap)
up?.post(tap: .cghidEventTap)
SWIFT
}

wait_for_state 'state["boardSize"] == "large"' "initial generated game"
initial_signature="$(state_value 'state["puzzleSignature"]')"

press_accessibility_button "new-board-button"
wait_for_state 'state["isConfirmingNewBoard"] == True' "new board confirmation appears"
press_accessibility_button "cancel-new-board-button"
wait_for_state 'state["isConfirmingNewBoard"] == False and state["puzzleSignature"] == "'"$initial_signature"'"' "cancelling keeps the current puzzle"

press_accessibility_button "new-board-button"
wait_for_state 'state["isConfirmingNewBoard"] == True' "new board confirmation appears again"
press_accessibility_button "confirm-new-board-button"
wait_for_state 'state["puzzleSignature"] != "'"$initial_signature"'"' "confirmed new board changes puzzle"

echo "New board smoke test passed: cancel preserves the puzzle, confirmation changes it."
