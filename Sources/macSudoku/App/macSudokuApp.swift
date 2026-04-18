import AppKit
import SwiftUI

@main
struct macSudokuApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup("Sudoku") {
            SudokuBoardView(game: SudokuGame.sample)
                .frame(minWidth: 380, idealWidth: 540, maxWidth: 740, minHeight: 380, idealHeight: 540, maxHeight: 740)
                .background(FloatingWindowConfigurator())
                .toolbarVisibility(.hidden, for: .windowToolbar)
                .containerBackground(.thinMaterial, for: .window)
        }
        .windowStyle(.plain)
        .windowResizability(.contentSize)
        .defaultWindowPlacement { content, context in
            let ideal = content.sizeThatFits(.unspecified)
            let visible = context.defaultDisplay.visibleRect
            let side = min(max(ideal.width, ideal.height, 540), min(visible.width, visible.height) * 0.70)
            return WindowPlacement(size: CGSize(width: side, height: side))
        }
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(replacing: .toolbar) {}
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
