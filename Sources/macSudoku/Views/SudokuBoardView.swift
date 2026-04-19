import SwiftUI

struct SudokuBoardView: View {
    @State var game: SudokuGame
    @State private var selectedCell: SudokuGame.Cell.ID?
    @State private var boardSize: BoardSize = .large

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                boardBackground

                VStack(spacing: 0) {
                    SudokuTopBarView(
                        boardSize: boardSize,
                        onCycleBoardSize: cycleBoardSize
                    )

                    SudokuGridView(
                        game: game,
                        selectedCell: selectedCell,
                        onSelectCell: selectCell
                    )
                    .frame(width: boardSize.boardSide, height: boardSize.boardSide)
                }
            }
        }
        .frame(width: boardSize.boardSide, height: boardSize.windowHeight)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .contentShape(Rectangle())
        .aspectRatio(nil, contentMode: .fit)
        .background {
            KeyboardInputBridge { input in
                handleKeyboardInput(input)
            }
        }
        .onAppear {
            selectedCell = selectedCell ?? game.cells.first(where: { !$0.isGiven })?.id
            recordUITestState()
        }
        .animation(.snappy(duration: 0.24), value: boardSize)
    }

    private var boardBackground: some View {
        Rectangle()
            .fill(.thinMaterial)
            .overlay {
                LinearGradient(
                    colors: [
                        Color.primary.opacity(0.08),
                        Color.cyan.opacity(0.10),
                        Color.green.opacity(0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .blendMode(.plusLighter)
            }
            .overlay(alignment: .topLeading) {
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.22),
                        Color.clear
                    ],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 420
                )
                .blendMode(.screen)
                .allowsHitTesting(false)
            }
            .overlay(alignment: .bottomTrailing) {
                RadialGradient(
                    colors: [
                        Color.black.opacity(0.16),
                        Color.clear
                    ],
                    center: .bottomTrailing,
                    startRadius: 0,
                    endRadius: 520
                )
                .blendMode(.softLight)
                .allowsHitTesting(false)
            }
            .ignoresSafeArea()
    }

    private func cycleBoardSize() {
        boardSize = boardSize.next
        recordUITestState()
    }

    private func selectCell(_ cellID: SudokuGame.Cell.ID) {
        selectedCell = cellID
        recordUITestState()
    }

    private func handleKeyboardInput(_ input: SudokuKeyboardInput) -> Bool {
        guard let selectedCell else {
            return false
        }

        let row = selectedCell / 9
        let column = selectedCell % 9

        switch input {
        case .digit(let value):
            game.setValue(value, row: row, column: column)
            recordUITestState()
            return true
        case .clear:
            game.setValue(nil, row: row, column: column)
            recordUITestState()
            return true
        case .move(let rowDelta, let columnDelta):
            moveSelection(rowDelta: rowDelta, columnDelta: columnDelta)
            recordUITestState()
            return true
        }
    }

    private func moveSelection(rowDelta: Int, columnDelta: Int) {
        let current = selectedCell ?? 0
        let row = max(0, min(8, current / 9 + rowDelta))
        let column = max(0, min(8, current % 9 + columnDelta))
        selectedCell = row * 9 + column
    }

    private func recordUITestState() {
        UITestProbe.record(game: game, selectedCellID: selectedCell, boardSize: boardSize)
    }
}
