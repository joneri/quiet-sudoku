import AppKit
import SwiftUI

struct LeaderboardEntryView: View {
    let levelsCompleted: Int
    let entries: [LeaderboardEntry]
    let onSubmit: (String) -> Void

    @State private var initials = ""

    var body: some View {
        VStack(spacing: 12) {
            Text("Game Over")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(Color.red.opacity(0.95))

            scoreText

            Text("Enter 3 initials for the high score list.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.primary.opacity(0.74))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("leaderboard-entry-instructions")

            InitialsTextField(text: $initials)
                .frame(width: 104, height: 42)
                .background(fieldBackground)
                .background(InitialsKeyboardBridge(text: $initials))
                .accessibilityLabel("Leaderboard initials")
                .accessibilityIdentifier("leaderboard-initials-field")
                .onChange(of: initials) { _, newValue in
                    let normalized = LeaderboardEntry.normalizedInitials(newValue)
                    if normalized != newValue {
                        initials = normalized
                    }
                }

            Button("Save score") {
                onSubmit(LeaderboardEntry.normalizedInitials(initials).paddingToThreeCharacters())
            }
            .buttonStyle(.plain)
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .frame(width: 120, height: 32)
            .background(buttonBackground)
            .accessibilityIdentifier("submit-leaderboard-button")

            if !entries.isEmpty {
                VStack(spacing: 5) {
                    Text("Top scores")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)

                    ForEach(Array(entries.prefix(5).enumerated()), id: \.element.id) { index, entry in
                        HStack {
                            Text("\(index + 1). \(entry.initials)")
                            Spacer()
                            Text("\(entry.levelsCompleted)")
                                .monospacedDigit()
                        }
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                    }
                }
                .frame(width: 150)
                .accessibilityIdentifier("leaderboard-list")
            }
        }
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.regularMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.24), lineWidth: 1)
                }
        }
        .shadow(color: Color.black.opacity(0.24), radius: 22)
    }

    private var scoreText: some View {
        Text("Levels cleared: " + String(levelsCompleted))
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(.primary.opacity(0.82))
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(.thinMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Color.green.opacity(0.36), lineWidth: 1)
            }
    }

    private var buttonBackground: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(.thinMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.20), lineWidth: 1)
            }
    }
}

private struct InitialsTextField: NSViewRepresentable {
    @Binding var text: String

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.delegate = context.coordinator
        textField.isBordered = false
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.alignment = .center
        textField.placeholderString = "ABC"
        textField.font = NSFont.monospacedSystemFont(ofSize: 28, weight: .black)
        textField.focusRingType = .none
        textField.maximumNumberOfLines = 1
        textField.setAccessibilityIdentifier("leaderboard-initials-field")

        DispatchQueue.main.async {
            textField.window?.makeFirstResponder(textField)
        }

        return textField
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }

        DispatchQueue.main.async {
            if nsView.window?.firstResponder !== nsView.currentEditor() {
                nsView.window?.makeFirstResponder(nsView)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        @Binding private var text: String

        init(text: Binding<String>) {
            _text = text
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let textField = notification.object as? NSTextField else { return }
            let normalized = LeaderboardEntry.normalizedInitials(textField.stringValue)
            text = normalized

            if textField.stringValue != normalized {
                textField.stringValue = normalized
            }
        }
    }
}

private struct InitialsKeyboardBridge: NSViewRepresentable {
    @Binding var text: String

    func makeNSView(context: Context) -> InitialsKeyboardInputView {
        let view = InitialsKeyboardInputView()
        view.onTextChange = { text = $0 }
        view.currentText = text
        view.installMonitorIfNeeded()
        return view
    }

    func updateNSView(_ nsView: InitialsKeyboardInputView, context: Context) {
        nsView.onTextChange = { text = $0 }
        nsView.currentText = text
        nsView.installMonitorIfNeeded()
    }

    static func dismantleNSView(_ nsView: InitialsKeyboardInputView, coordinator: ()) {
        nsView.invalidateMonitor()
    }
}

private final class InitialsKeyboardInputView: NSView {
    var currentText = ""
    var onTextChange: ((String) -> Void)?
    private var monitor: Any?

    func installMonitorIfNeeded() {
        guard monitor == nil else { return }

        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.handle(event) else {
                return event
            }

            return nil
        }
    }

    func invalidateMonitor() {
        guard let monitor else { return }
        NSEvent.removeMonitor(monitor)
        self.monitor = nil
    }

    private func handle(_ event: NSEvent) -> Bool {
        let disallowedModifiers: NSEvent.ModifierFlags = [.command, .control, .option]
        guard event.modifierFlags.intersection(disallowedModifiers).isEmpty else {
            return false
        }

        if event.keyCode == 51 || event.keyCode == 117 {
            currentText = String(currentText.dropLast())
            onTextChange?(currentText)
            return true
        }

        guard
            currentText.count < 3,
            let character = event.charactersIgnoringModifiers?.first,
            character.isLetter || character.isNumber
        else {
            return false
        }

        currentText = LeaderboardEntry.normalizedInitials(currentText + String(character))
        onTextChange?(currentText)
        return true
    }
}

private extension String {
    func paddingToThreeCharacters() -> String {
        let normalized = LeaderboardEntry.normalizedInitials(self)
        guard !normalized.isEmpty else { return "AAA" }
        return normalized.padding(toLength: 3, withPad: "A", startingAt: 0)
    }
}
