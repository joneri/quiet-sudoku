import AppKit
import SwiftUI

@main
struct macSudokuApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup("Sudoku") {
            SudokuBoardView(game: SudokuGame.sample)
                .background(FloatingWindowConfigurator())
                .toolbarVisibility(.hidden, for: .windowToolbar)
                .containerBackground(.thinMaterial, for: .window)
        }
        .windowStyle(.plain)
        .windowResizability(.contentSize)
        .defaultWindowPlacement { content, context in
            let ideal = content.sizeThatFits(.unspecified)
            let visible = context.defaultDisplay.visibleRect
            let width = min(ideal.width, visible.width * 0.70)
            let height = min(ideal.height, visible.height * 0.70)
            return WindowPlacement(size: CGSize(width: width, height: height))
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
