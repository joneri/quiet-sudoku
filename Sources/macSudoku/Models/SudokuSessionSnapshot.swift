import Foundation

struct SudokuSessionSnapshot: Codable, Equatable {
    let puzzle: SudokuPuzzle
    let values: [Int?]
    let candidateValues: [Int?]
    let selectedCellID: SudokuGame.Cell.ID?
    let boardSize: BoardSize
    let livesRemaining: Int

    init(
        puzzle: SudokuPuzzle,
        values: [Int?],
        candidateValues: [Int?],
        selectedCellID: SudokuGame.Cell.ID?,
        boardSize: BoardSize,
        livesRemaining: Int
    ) {
        self.puzzle = puzzle
        self.values = values
        self.candidateValues = candidateValues
        self.selectedCellID = selectedCellID
        self.boardSize = boardSize
        self.livesRemaining = livesRemaining
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        puzzle = try container.decode(SudokuPuzzle.self, forKey: .puzzle)
        values = try container.decode([Int?].self, forKey: .values)
        candidateValues = try container.decodeIfPresent([Int?].self, forKey: .candidateValues) ?? Array(repeating: nil, count: 81)
        selectedCellID = try container.decodeIfPresent(SudokuGame.Cell.ID.self, forKey: .selectedCellID)
        boardSize = try container.decodeIfPresent(BoardSize.self, forKey: .boardSize) ?? .large
        livesRemaining = try container.decodeIfPresent(Int.self, forKey: .livesRemaining) ?? SudokuSessionStore.startingLives
    }

    var normalizedCandidateValues: [Int?] {
        candidateValues.count == 81 ? candidateValues : Array(repeating: nil, count: 81)
    }

    var progression: SudokuProgression {
        SudokuGame(snapshot: self)?.progression ?? .empty
    }

    var isComplete: Bool {
        SudokuGame(snapshot: self)?.isComplete ?? false
    }
}
