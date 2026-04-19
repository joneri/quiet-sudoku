import Foundation

struct SudokuProgression: Equatable {
    let completedDigits: Set<Int>
    let completedBlocks: Set<Int>

    static let empty = SudokuProgression(completedDigits: [], completedBlocks: [])
}

