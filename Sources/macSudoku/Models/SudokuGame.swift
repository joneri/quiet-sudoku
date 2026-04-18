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
    private let solution: [[Int]]

    init(puzzle: [[Int]], solution: [[Int]]) {
        self.solution = solution
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

    func hasConflict(at row: Int, column: Int) -> Bool {
        let current = cell(at: row, column: column)
        guard let value = current.displayValue else { return false }

        return peers(for: row, column: column).contains { peer in
            peer.id != current.id && peer.displayValue == value
        }
    }

    func isMatchingSelectedValue(_ cell: Cell, selectedCellID: Cell.ID?) -> Bool {
        guard
            let selectedCellID,
            cells.indices.contains(selectedCellID),
            let selectedValue = cells[selectedCellID].displayValue
        else {
            return false
        }

        return cell.displayValue == selectedValue
    }

    var isComplete: Bool {
        cells.allSatisfy { $0.displayValue != nil }
            && !cells.contains { hasConflict(at: $0.row, column: $0.column) }
            && cells.allSatisfy { $0.displayValue == solution[$0.row][$0.column] }
    }

    private func peers(for row: Int, column: Int) -> [Cell] {
        cells.filter { cell in
            cell.row == row
                || cell.column == column
                || (cell.row / 3 == row / 3 && cell.column / 3 == column / 3)
        }
    }
}

extension SudokuGame {
    static var sample: SudokuGame {
        SudokuGame(
            puzzle: [
                [0, 0, 6, 0, 0, 0, 1, 0, 0],
                [0, 7, 0, 0, 6, 0, 0, 3, 0],
                [8, 0, 0, 3, 0, 4, 0, 0, 6],
                [0, 0, 8, 6, 0, 7, 4, 0, 0],
                [0, 6, 0, 0, 0, 0, 0, 1, 0],
                [0, 0, 2, 1, 0, 9, 5, 0, 0],
                [5, 0, 0, 7, 0, 2, 0, 0, 3],
                [0, 4, 0, 0, 9, 0, 0, 8, 0],
                [0, 0, 7, 0, 0, 0, 9, 0, 0]
            ],
            solution: [
                [3, 2, 6, 9, 5, 8, 1, 7, 4],
                [4, 7, 5, 2, 6, 1, 8, 3, 9],
                [8, 1, 9, 3, 7, 4, 2, 5, 6],
                [1, 5, 8, 6, 3, 7, 4, 9, 2],
                [9, 6, 4, 8, 2, 5, 3, 1, 7],
                [7, 3, 2, 1, 4, 9, 5, 6, 8],
                [5, 9, 1, 7, 8, 2, 6, 4, 3],
                [2, 4, 3, 5, 9, 6, 7, 8, 1],
                [6, 8, 7, 4, 1, 3, 9, 2, 5]
            ]
        )
    }
}
