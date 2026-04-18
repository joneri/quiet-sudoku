import AppKit
import SwiftUI

enum SudokuKeyboardInput {
    case digit(Int)
    case clear
    case move(rowDelta: Int, columnDelta: Int)
}

struct KeyboardInputBridge: NSViewRepresentable {
    let onInput: (SudokuKeyboardInput) -> Bool

    func makeNSView(context: Context) -> KeyboardInputView {
        let view = KeyboardInputView()
        view.onInput = onInput
        view.requestFocus()
        return view
    }

    func updateNSView(_ nsView: KeyboardInputView, context: Context) {
        nsView.onInput = onInput
        nsView.requestFocus()
    }
}

final class KeyboardInputView: NSView {
    var onInput: ((SudokuKeyboardInput) -> Bool)?

    override var acceptsFirstResponder: Bool {
        true
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        requestFocus()
    }

    func requestFocus() {
        DispatchQueue.main.async { [weak self] in
            guard let self, self.window?.firstResponder !== self else { return }
            self.window?.makeFirstResponder(self)
        }
    }

    override func keyDown(with event: NSEvent) {
        if let input = input(from: event), onInput?(input) == true {
            return
        }

        super.keyDown(with: event)
    }

    private func input(from event: NSEvent) -> SudokuKeyboardInput? {
        switch event.keyCode {
        case 51, 117:
            return .clear
        case 123:
            return .move(rowDelta: 0, columnDelta: -1)
        case 124:
            return .move(rowDelta: 0, columnDelta: 1)
        case 125:
            return .move(rowDelta: 1, columnDelta: 0)
        case 126:
            return .move(rowDelta: -1, columnDelta: 0)
        default:
            break
        }

        guard let characters = event.charactersIgnoringModifiers else { return nil }

        if characters == "0" || characters == " " {
            return .clear
        }

        if let character = characters.first, let value = Int(String(character)), (1...9).contains(value) {
            return .digit(value)
        }

        return nil
    }
}

