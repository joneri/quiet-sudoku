import Foundation

@Observable
final class SudokuSessionStore {
    static let startingLives = 3
    static let maximumLives = 5

    private let generator: SudokuPuzzleGenerator
    private let persistence: SudokuGamePersistence
    private let leaderboardStore: LeaderboardStore

    var game: SudokuGame
    var selectedCell: SudokuGame.Cell.ID?
    var boardSize: BoardSize
    var livesRemaining: Int
    var level: SudokuLevel
    var leaderboardEntries: [LeaderboardEntry]

    var isGameOver: Bool {
        livesRemaining == 0
    }

    init(
        generator: SudokuPuzzleGenerator = SudokuPuzzleGenerator(),
        persistence: SudokuGamePersistence = SudokuGamePersistence(),
        leaderboardStore: LeaderboardStore = LeaderboardStore()
    ) {
        self.generator = generator
        self.persistence = persistence
        self.leaderboardStore = leaderboardStore
        leaderboardEntries = leaderboardStore.load()

        if let snapshot = persistence.load(), let restoredGame = SudokuGame(snapshot: snapshot) {
            game = restoredGame
            selectedCell = snapshot.selectedCellID
            boardSize = snapshot.boardSize
            livesRemaining = snapshot.livesRemaining
            level = snapshot.level
        } else {
            let startingLevel = SudokuLevel(1)
            level = startingLevel
            game = SudokuGame(puzzle: generator.generate(level: startingLevel))
            selectedCell = nil
            boardSize = .large
            livesRemaining = Self.startingLives
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
        guard !isGameOver else { return false }
        ensureSelection()

        guard let selectedCell else {
            return false
        }

        let row = selectedCell / 9
        let column = selectedCell % 9

        switch input {
        case .digit(let value):
            game.setCandidateValue(value, row: row, column: column)
        case .clear:
            game.setCandidateValue(nil, row: row, column: column)
        case .move(let rowDelta, let columnDelta):
            moveSelection(rowDelta: rowDelta, columnDelta: columnDelta)
        }

        save()
        return true
    }

    func lockSelectedCandidate() {
        guard let selectedCell else {
            ensureSelection()
            return
        }

        lockCandidate(cellID: selectedCell)
    }

    func lockCandidate(cellID: SudokuGame.Cell.ID) {
        guard !isGameOver else { return }

        if game.lockCandidate(cellID: cellID) == false {
            livesRemaining = max(0, livesRemaining - 1)
        }

        save()
    }

    func lockAllCandidates() {
        guard !isGameOver else { return }

        for cellID in game.candidateCellIDs {
            guard !isGameOver else { break }
            if game.lockCandidate(cellID: cellID) == false {
                livesRemaining = max(0, livesRemaining - 1)
            }
        }

        save()
    }

    func generateNewBoard() {
        startNewRun()
    }

    func startNewRun() {
        level = SudokuLevel(1)
        game = SudokuGame(puzzle: generator.generate(level: level))
        selectedCell = game.firstEditableCellID
        livesRemaining = Self.startingLives
        save()
    }

    func advanceToNextLevel() {
        level = level.next()
        let nextLives = isGameOver
            ? Self.startingLives
            : min(Self.maximumLives, max(Self.startingLives, livesRemaining))
        game = SudokuGame(puzzle: generator.generate(level: level))
        selectedCell = game.firstEditableCellID
        livesRemaining = nextLives
        save()
    }

    func awardCompletionLife() {
        guard livesRemaining < Self.maximumLives else { return }

        livesRemaining += 1
        save()
    }

    var levelsCompleted: Int {
        level.completedCountBeforeLevel
    }

    @discardableResult
    func submitLeaderboardEntry(initials: String) -> LeaderboardEntry {
        let entry = LeaderboardEntry(initials: initials, levelsCompleted: levelsCompleted)
        leaderboardEntries = leaderboardStore.adding(entry, to: leaderboardEntries)
        leaderboardStore.save(leaderboardEntries)
        return entry
    }

    func snapshot() -> SudokuSessionSnapshot {
        SudokuSessionSnapshot(
            puzzle: game.puzzle,
            values: game.values,
            candidateValues: game.candidateValues,
            selectedCellID: selectedCell,
            boardSize: boardSize,
            livesRemaining: livesRemaining,
            level: level
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
