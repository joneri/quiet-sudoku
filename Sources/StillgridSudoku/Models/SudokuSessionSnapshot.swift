import Foundation

struct SudokuSessionSnapshot: Codable, Equatable {
    let puzzle: SudokuPuzzle
    let values: [Int?]
    let candidateValues: [Int?]
    let selectedCellID: SudokuGame.Cell.ID?
    let boardSize: BoardSize
    let livesRemaining: Int
    let level: SudokuLevel
    let leaderboardInitials: String?

    init(
        puzzle: SudokuPuzzle,
        values: [Int?],
        candidateValues: [Int?],
        selectedCellID: SudokuGame.Cell.ID?,
        boardSize: BoardSize,
        livesRemaining: Int,
        level: SudokuLevel,
        leaderboardInitials: String? = nil
    ) {
        self.puzzle = puzzle
        self.values = values
        self.candidateValues = candidateValues
        self.selectedCellID = selectedCellID
        self.boardSize = boardSize
        self.livesRemaining = livesRemaining
        self.level = level
        self.leaderboardInitials = leaderboardInitials
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        puzzle = try container.decode(SudokuPuzzle.self, forKey: .puzzle)
        values = try container.decode([Int?].self, forKey: .values)
        candidateValues = try container.decodeIfPresent([Int?].self, forKey: .candidateValues) ?? Array(repeating: nil, count: 81)
        selectedCellID = try container.decodeIfPresent(SudokuGame.Cell.ID.self, forKey: .selectedCellID)
        boardSize = try container.decodeIfPresent(BoardSize.self, forKey: .boardSize) ?? .large
        livesRemaining = try container.decodeIfPresent(Int.self, forKey: .livesRemaining) ?? SudokuSessionStore.startingLives
        level = try container.decodeIfPresent(SudokuLevel.self, forKey: .level) ?? SudokuLevel(1)
        leaderboardInitials = try container.decodeIfPresent(String.self, forKey: .leaderboardInitials)
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
