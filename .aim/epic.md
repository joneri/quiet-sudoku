# Epic: Continuous high score progression

Mode: Auto
Cost profile: Cost Control

Make the high score system reward players who keep winning level after level.

Desired behavior:
- A player can be asked for initials after a completed level when they qualify and are not already part of the current run's high score identity.
- Once initials are known, later completed levels update that same high score automatically.
- The leaderboard keeps only the highest 15 scores.
- The Scores button gives a soft pleasant animation whenever the leaderboard changes.

The implementation must preserve the existing Game Over high score flow and keep the code readable, componentized, and testable.
