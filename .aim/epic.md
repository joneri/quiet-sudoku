# Epic

Add a candidate-locking life system to macSudoku.

Players should be able to type any digit into an editable cell at any time, but typed digits should start as unlocked candidates that float above the glass board. Candidates only count toward the Sudoku solution after the player presses a lock button. Locking a correct candidate commits it calmly into the board. Locking an incorrect candidate costs one life. The player starts with three lives, shown as centered hearts in the top button shelf; each lost life removes the red fill from one heart. Solving a board awards one extra heart.

## Acceptance Criteria

- Typing a digit into an editable cell creates an unlocked candidate instead of an immediately committed value.
- Unlocked candidates are visually distinct and float slightly above the board with a shadow.
- Each candidate cell has a clear inline lock button that pushes that candidate into place.
- A top-shelf Lock all button attempts to commit all currently unlocked candidates.
- Correct locked candidates become committed Sudoku values.
- Incorrect locked candidates remain unlocked and reduce lives by one.
- Lives start at three and are visible as hearts centered in the top shelf.
- Lost lives are represented by removing the red fill from one heart per lost life.
- Completing a board awards one extra heart for the next board.
- Candidates, committed values, selected cell, board size, and lives persist across relaunch.
- New boards clear old candidates. Game Over resets lives to three, while normal new boards preserve any earned extra hearts.
- Existing progression, completion animation, new-board confirmation, mouse selection, keyboard input, and sizing behavior continue to work.

## Non-goals

- No sound effects.
- No menu or settings surface.
