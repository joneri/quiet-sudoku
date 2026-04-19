import Foundation

struct SudokuSessionSnapshot: Codable, Equatable {
    let puzzle: SudokuPuzzle
    let values: [Int?]
    let selectedCellID: SudokuGame.Cell.ID?
    let boardSize: BoardSize

    var progression: SudokuProgression {
        SudokuGame(snapshot: self)?.progression ?? .empty
    }
}
