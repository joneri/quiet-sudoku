Purpose: Keep Stillgrid Sudoku visually calm while still behaving like a normal macOS window during review and everyday use.

How it works: The app uses the default macOS window style and leaves the native title-bar/toolbar system in place so the standard window controls remain visible. The floating window configurator only tunes window level, shadow, opacity, sizing, and space behavior. It must avoid title-bar customizations that can suppress or visually obscure the standard close, minimize, and zoom buttons.

Key decisions: Apple review expects normal title bar controls to remain available. We keep the lightweight floating feel through material and window level, but prefer standard macOS title-bar behavior over transparent or full-size-content customizations.

Inputs/outputs: SwiftUI creates the window scene in `Sources/StillgridSudoku/App/StillgridSudokuApp.swift`, and `Sources/StillgridSudoku/Support/FloatingWindowConfigurator.swift` applies AppKit-level window tuning after the window exists.

Edge cases: Avoid `.windowStyle(.plain)`, avoid hiding the window toolbar/title-bar system, avoid manually hiding standard window buttons, and avoid title-bar or full-size-content tweaks that can make the traffic-light controls disappear or become unreadable.

Debugging: Launch the app locally and confirm the red, yellow, and green title bar buttons are visible in the top-left corner while the board still uses the intended floating material look.

Related files: `Sources/StillgridSudoku/App/StillgridSudokuApp.swift`, `Sources/StillgridSudoku/Support/FloatingWindowConfigurator.swift`
