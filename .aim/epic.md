# Epic

Investigate and introduce delightful board animation for the macSudoku glass board.

The app should be able to show a temporary magical shimmer, like a wand sweeping over the board, with glittering light that briefly illuminates the glass surface without adding menus, clutter, or a disruptive interaction model.

## Acceptance Criteria

- The animation feels native to the existing floating glass-board design.
- The animation is temporary and non-blocking.
- The board remains usable with mouse and keyboard while animation support exists.
- Animation code is isolated in reusable SwiftUI components rather than embedded into cell logic.
- UI test support can detect when the animation is triggered so regressions are testable before manual review.
- Existing persistence, board sizing, new-board confirmation, keyboard input, mouse selection, and progression behavior continue to work.

## Non-goals

- No new menu, settings panel, or visible animation controls in this increment.
- No audio, particle engine dependency, or broad redesign.
- No change to Sudoku rules or saved-game semantics.
