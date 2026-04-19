import Foundation

struct SudokuPuzzleGenerator {
    func generate(level: SudokuLevel = SudokuLevel(1)) -> SudokuPuzzle {
        let solution = shuffledSolution()
        var puzzle = solution
        var positions = Array(0..<81)
        positions.shuffle()

        for position in positions.dropFirst(level.filledCellCount) {
            puzzle[position / 9][position % 9] = 0
        }

        return SudokuPuzzle(puzzle: puzzle, solution: solution)
    }

    private func shuffledSolution() -> [[Int]] {
        let digitMap = Array(1...9).shuffled()
        let rowBands = [0, 1, 2].shuffled()
        let columnBands = [0, 1, 2].shuffled()
        let rows = rowBands.flatMap { band in [0, 1, 2].shuffled().map { band * 3 + $0 } }
        let columns = columnBands.flatMap { band in [0, 1, 2].shuffled().map { band * 3 + $0 } }

        return rows.map { row in
            columns.map { column in
                let baseValue = (row * 3 + row / 3 + column) % 9
                return digitMap[baseValue]
            }
        }
    }
}
