# macSudoku Development Rules

## Architecture Quality Rule

Every new increment in this repository must leave the code more reusable, readable, and componentized than it found it.

When changing Swift code:

- Prefer small, named SwiftUI views over large computed `some View` fragments.
- Keep view state ownership explicit and close to the scene or feature root.
- Put reusable value types in `Models/`, focused view components in `Views/`, and narrow platform bridges in `Support/`.
- Pass explicit data and closures into child views instead of giving them broad ownership of parent state.
- Keep AppKit interop isolated behind small wrappers.
- Add or update UI smoke tests when changing user interaction.
- Treat readability and future reuse as acceptance criteria, not cleanup for later.

For AIM work, every Done Increment should include a short architecture note in its review when it touches app code.

