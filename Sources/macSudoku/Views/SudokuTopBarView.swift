import SwiftUI

struct SudokuTopBarView: View {
    let boardSize: BoardSize
    let onCycleBoardSize: () -> Void

    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .gesture(WindowDragGesture())
                .allowsWindowActivationEvents(true)

            HStack {
                Spacer()
                sizeButton
            }
            .padding(.horizontal, 12)
        }
        .frame(height: BoardSize.topBarHeight)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.primary.opacity(0.14))
                .frame(height: 1)
        }
    }

    private var sizeButton: some View {
        Button(action: onCycleBoardSize) {
            Text(boardSize.buttonTitle)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .frame(width: 88, height: 30)
                .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Board size")
        .accessibilityValue(boardSize.accessibilityValue)
        .accessibilityIdentifier("board-size-button")
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.regularMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
                }
        }
    }
}

