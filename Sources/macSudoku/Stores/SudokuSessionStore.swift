import Foundation

@Observable
final class SudokuSessionStore {
    private let generator: SudokuPuzzleGenerator
    private let persistence: SudokuGamePersistence

    var game: SudokuGame
    var selectedCell: SudokuGame.Cell.ID?
    var boardSize: BoardSize

    init(
        generator: SudokuPuzzleGenerator = SudokuPuzzleGenerator(),
        persistence: SudokuGamePersistence = SudokuGamePersistence()
    ) {
        self.generator = generator
        self.persistence = persistence

        if let snapshot = persistence.load(), let restoredGame = SudokuGame(snapshot: snapshot) {
            game = restoredGame
            selectedCell = snapshot.selectedCellID
            boardSize = snapshot.boardSize
        } else {
            game = SudokuGame(puzzle: generator.generate())
            selectedCell = nil
            boardSize = .large
        }

        ensureSelection()
        save()
    }

    func selectCell(_ cellID: SudokuGame.Cell.ID) {
        selectedCell = cellID
        save()
    }

    func cycleBoardSize() {
        boardSize = boardSize.next
        save()
    }

    func handleKeyboardInput(_ input: SudokuKeyboardInput) -> Bool {
        ensureSelection()

        guard let selectedCell else {
            return false
        }

        let row = selectedCell / 9
        let column = selectedCell % 9

        switch input {
        case .digit(let value):
            game.setValue(value, row: row, column: column)
        case .clear:
            game.setValue(nil, row: row, column: column)
        case .move(let rowDelta, let columnDelta):
            moveSelection(rowDelta: rowDelta, columnDelta: columnDelta)
        }

        save()
        return true
    }

    func generateNewBoard() {
        game = SudokuGame(puzzle: generator.generate())
        selectedCell = game.firstEditableCellID
        save()
    }

    func snapshot() -> SudokuSessionSnapshot {
        SudokuSessionSnapshot(
            puzzle: game.puzzle,
            values: game.values,
            selectedCellID: selectedCell,
            boardSize: boardSize
        )
    }

    private func ensureSelection() {
        selectedCell = selectedCell ?? game.firstEditableCellID
    }

    private func moveSelection(rowDelta: Int, columnDelta: Int) {
        let current = selectedCell ?? game.firstEditableCellID ?? 0
        let row = max(0, min(8, current / 9 + rowDelta))
        let column = max(0, min(8, current % 9 + columnDelta))
        selectedCell = row * 9 + column
    }

    private func save() {
        persistence.save(snapshot())
    }
}

