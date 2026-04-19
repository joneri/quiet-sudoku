# Epic

Add levels and a local leaderboard to macSudoku.

The player starts at level 1 on an easy board. Each solved board advances the player to the next level, and later levels become progressively harder. The current level must be visible while playing. When the player reaches Game Over, they can enter three characters for a local leaderboard. Leaderboard score is based on how many levels were completed in that run. A timer may be added in the future, but it is intentionally out of scope for this epic.

## Acceptance Criteria

- A new run starts at level 1.
- Level 1 has an easier board than later levels.
- Solving a board advances to the next level after the existing congratulations and new-board confirmation flow.
- The current level is visible in the top shelf.
- Game Over shows a three-character initials entry before starting over.
- Submitted leaderboard entries store initials and completed-level count.
- The leaderboard is persisted locally and sorted by completed levels descending.
- Existing hearts, candidate locking, completion animation, New confirmation, board sizing, persistence, mouse selection, and keyboard input continue to work.

## Non-goals

- No timer.
- No online leaderboard.
- No player profiles.
