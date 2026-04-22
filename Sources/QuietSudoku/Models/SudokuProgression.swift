import Foundation

struct SudokuProgression: Equatable {
    let completedDigits: Set<Int>
    let completedBlocks: Set<Int>
    let completedRows: Set<Int>
    let completedColumns: Set<Int>

    static let empty = SudokuProgression(completedDigits: [], completedBlocks: [], completedRows: [], completedColumns: [])
}
