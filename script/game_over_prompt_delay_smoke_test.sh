#!/usr/bin/env bash
set -euo pipefail

APP_NAME="StillgridSudoku"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_BUNDLE="$ROOT_DIR/dist/$APP_NAME.app"
STATE_FILE="$(mktemp "${TMPDIR:-/tmp}/StillgridSudoku-game-over-delay-state.XXXXXX.json")"
SAVE_FILE="$(mktemp "${TMPDIR:-/tmp}/StillgridSudoku-game-over-delay-save.XXXXXX.json")"
LEADERBOARD_FILE="$(mktemp "${TMPDIR:-/tmp}/StillgridSudoku-game-over-delay-leaderboard.XXXXXX.json")"

cleanup() {
  pkill -x "$APP_NAME" >/dev/null 2>&1 || true
  rm -f "$STATE_FILE"
  rm -f "$SAVE_FILE"
  rm -f "$LEADERBOARD_FILE"
}
trap cleanup EXIT

"$ROOT_DIR/script/build_and_run.sh" --verify
pkill -x "$APP_NAME" >/dev/null 2>&1 || true

/usr/bin/python3 - "$SAVE_FILE" "$LEADERBOARD_FILE" <<'PY'
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

candidate_values = [None for _ in range(81)]
candidate_values[0] = 2

snapshot = {
    "puzzle": {
        "puzzle": [[0 for _ in range(9)] for _ in range(9)],
        "solution": solution,
    },
    "values": [None for _ in range(81)],
    "candidateValues": candidate_values,
    "selectedCellID": 0,
    "boardSize": "large",
    "livesRemaining": 1,
    "level": {"number": 1},
}

entries = []
for index in range(15):
    entries.append({
        "id": f"00000000-0000-0000-0000-{index + 1:012d}",
        "initials": f"H{index % 10}I",
        "levelsCompleted": 20 - index,
        "achievedAt": 766756800 + index,
    })

with open(sys.argv[1], "w", encoding="utf-8") as handle:
    json.dump(snapshot, handle)

with open(sys.argv[2], "w", encoding="utf-8") as handle:
    json.dump(entries, handle)
PY

/usr/bin/open -n \
  --env "STILLGRID_SUDOKU_UI_STATE_PATH=$STATE_FILE" \
  --env "STILLGRID_SUDOKU_SAVE_PATH=$SAVE_FILE" \
  --env "STILLGRID_SUDOKU_LEADERBOARD_PATH=$LEADERBOARD_FILE" \
  "$APP_BUNDLE"

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

  echo "Game Over prompt delay smoke test failed while waiting for: $label" >&2
  [[ -f "$STATE_FILE" ]] && cat "$STATE_FILE" >&2
  exit 1
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

wait_for_state 'state["livesRemaining"] == 1 and state["isGameOver"] == False and state["isConfirmingNewBoard"] == False and state["isEnteringLeaderboard"] == False' "one life game starts without Game Over"
press_accessibility_button "lock-candidate-cell-0-0"
wait_for_state 'state["livesRemaining"] == 0 and state["isGameOver"] == True and state["isEnteringLeaderboard"] == False and state["isConfirmingNewBoard"] == False' "Game Over is visible before new-board prompt"
wait_for_state 'state["livesRemaining"] == 0 and state["isGameOver"] == True and state["isEnteringLeaderboard"] == False and state["isConfirmingNewBoard"] == True' "new-board prompt appears after Game Over delay"

echo "Game Over prompt delay smoke test passed: Game Over appears before the new-board dialog."
