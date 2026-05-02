#!/usr/bin/env bash
set -euo pipefail

APP_NAME="StillgridSudoku"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_BUNDLE="$ROOT_DIR/dist/$APP_NAME.app"
STATE_FILE="$(mktemp "${TMPDIR:-/tmp}/StillgridSudoku-size-state.XXXXXX.json")"
SAVE_FILE="$(mktemp "${TMPDIR:-/tmp}/StillgridSudoku-size-save.XXXXXX.json")"

cleanup() {
  pkill -x "$APP_NAME" >/dev/null 2>&1 || true
  rm -f "$STATE_FILE"
  rm -f "$SAVE_FILE"
}
trap cleanup EXIT

"$ROOT_DIR/script/build_and_run.sh" --verify
pkill -x "$APP_NAME" >/dev/null 2>&1 || true

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

sys.exit(0 if eval(expression, {"__builtins__": {}}, {"state": state}) else 1)
PY
    then
      return 0
    fi

    sleep 0.1
  done

  echo "Size button smoke test failed while waiting for: $label" >&2
  [[ -f "$STATE_FILE" ]] && cat "$STATE_FILE" >&2
  exit 1
}

press_size_button() {
  local pid
  pid="$(pgrep -x "$APP_NAME" | head -n 1)"

  /usr/bin/swift - "$pid" <<'SWIFT'
import AppKit
import Foundation

let pid = pid_t(Int32(CommandLine.arguments[1])!)

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

func findSizeButton(in element: AXUIElement) -> AXUIElement? {
    let identifier = stringAttribute("AXIdentifier", of: element)
    let description = stringAttribute(kAXDescriptionAttribute, of: element)
    let title = stringAttribute(kAXTitleAttribute, of: element)

    if identifier == "board-size-button" || description == "Board size" || ["Small", "Medium", "Large"].contains(title) {
        return element
    }

    for child in children(of: element) {
        if let match = findSizeButton(in: child) {
            return match
        }
    }

    return nil
}

guard let app = NSRunningApplication(processIdentifier: pid) else {
    fputs("Could not find running Stillgrid Sudoku app\n", stderr)
    exit(1)
}

app.activate()
Thread.sleep(forTimeInterval: 0.2)

let appElement = AXUIElementCreateApplication(pid)
guard let button = findSizeButton(in: appElement) else {
    fputs("Could not find board size button through Accessibility\n", stderr)
    exit(2)
}

let result = AXUIElementPerformAction(button, kAXPressAction as CFString)
guard result == .success else {
    fputs("Could not press board size button. Result: \(result.rawValue)\n", stderr)
    exit(2)
}
SWIFT
}

wait_for_state 'state["boardSize"] == "large" and state["visibleHeartSlots"] == 5 and state["maximumLives"] == 5 and state["topBarMetrics"]["minimumRequiredWidth"] <= 700' "initial large board size with five heart slots"
press_size_button
wait_for_state 'state["boardSize"] == "small" and state["visibleHeartSlots"] == 5 and state["maximumLives"] == 5 and state["topBarMetrics"]["minimumRequiredWidth"] <= 320 and state["topBarMetrics"]["usesCompactLevelTitle"] == True and state["topBarMetrics"]["usesCompactScoresTitle"] == True' "button cycles large to small with five heart slots"
press_size_button
wait_for_state 'state["boardSize"] == "medium" and state["visibleHeartSlots"] == 5 and state["maximumLives"] == 5 and state["topBarMetrics"]["minimumRequiredWidth"] <= 520 and state["topBarMetrics"]["usesCompactLevelTitle"] == True and state["topBarMetrics"]["usesCompactScoresTitle"] == True' "button cycles small to medium with five heart slots and fitting controls"

echo "Size button smoke test passed: large -> small -> medium with five heart slots and fitting top bar controls."
