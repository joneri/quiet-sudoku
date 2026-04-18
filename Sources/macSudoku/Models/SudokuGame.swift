import Foundation

@Observable
final class SudokuGame {
    struct Cell: Identifiable {
        let row: Int
        let column: Int
        let given: Int?
        var value: Int?

        var id: Int { row * 9 + column }
        var isGiven: Bool { given != nil }
        var displayValue: Int? { given ?? value }
    }

    private(set) var cells: [Cell]

    init(puzzle: [[Int]]) {
        cells = puzzle.enumerated().flatMap { rowIndex, row in
            row.enumerated().map { columnIndex, number in
                let given = number == 0 ? nil : number
                return Cell(row: rowIndex, column: columnIndex, given: given, value: nil)
            }
        }
    }

    func cell(at row: Int, column: Int) -> Cell {
        cells[row * 9 + column]
    }

    func setValue(_ value: Int?, row: Int, column: Int) {
        let index = row * 9 + column
        guard cells.indices.contains(index), !cells[index].isGiven else { return }
        cells[index].value = value
    }
}

extension SudokuGame {
    static var sample: SudokuGame {
        SudokuGame(puzzle: [
            [0, 0, 6, 0, 0, 0, 1, 0, 0],
            [0, 7, 0, 0, 6, 0, 0, 3, 0],
            [8, 0, 0, 3, 0, 4, 0, 0, 6],
            [0, 0, 8, 6, 0, 7, 4, 0, 0],
            [0, 6, 0, 0, 0, 0, 0, 1, 0],
            [0, 0, 2, 1, 0, 9, 5, 0, 0],
            [5, 0, 0, 7, 0, 2, 0, 0, 3],
            [0, 4, 0, 0, 9, 0, 0, 8, 0],
            [0, 0, 7, 0, 0, 0, 9, 0, 0]
        ])
    }
}

