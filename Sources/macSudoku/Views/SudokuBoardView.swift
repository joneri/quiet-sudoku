import SwiftUI

struct SudokuBoardView: View {
    @State private var store: SudokuSessionStore
    @State private var isConfirmingNewBoard = false

    init(store: SudokuSessionStore = SudokuSessionStore()) {
        _store = State(initialValue: store)
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                boardBackground

                VStack(spacing: 0) {
                    SudokuTopBarView(
                        boardSize: store.boardSize,
                        onCycleBoardSize: cycleBoardSize,
                        onRequestNewBoard: requestNewBoard
                    )

                    SudokuGridView(
                        game: store.game,
                        selectedCell: store.selectedCell,
                        onSelectCell: selectCell
                    )
                    .frame(width: store.boardSize.boardSide, height: store.boardSize.boardSide)
                }

                if isConfirmingNewBoard {
                    Color.black.opacity(0.10)
                        .ignoresSafeArea()

                    NewBoardConfirmationView(
                        onConfirm: confirmNewBoard,
                        onCancel: cancelNewBoard
                    )
                    .transition(.scale(scale: 0.96).combined(with: .opacity))
                }
            }
        }
        .frame(width: store.boardSize.boardSide, height: store.boardSize.windowHeight)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .contentShape(Rectangle())
        .aspectRatio(nil, contentMode: .fit)
        .background {
            KeyboardInputBridge { input in
                let handled = store.handleKeyboardInput(input)
                if handled {
                    recordUITestState()
                }
                return handled
            }
        }
        .onAppear {
            recordUITestState()
        }
        .animation(.snappy(duration: 0.24), value: store.boardSize)
        .animation(.snappy(duration: 0.18), value: isConfirmingNewBoard)
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
        store.cycleBoardSize()
        recordUITestState()
    }

    private func selectCell(_ cellID: SudokuGame.Cell.ID) {
        store.selectCell(cellID)
        recordUITestState()
    }

    private func requestNewBoard() {
        isConfirmingNewBoard = true
        recordUITestState()
    }

    private func confirmNewBoard() {
        isConfirmingNewBoard = false
        store.generateNewBoard()
        recordUITestState()
    }

    private func cancelNewBoard() {
        isConfirmingNewBoard = false
        recordUITestState()
    }

    private func recordUITestState() {
        UITestProbe.record(snapshot: store.snapshot(), isConfirmingNewBoard: isConfirmingNewBoard)
    }
}
