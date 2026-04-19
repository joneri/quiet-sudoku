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
    let puzzle: SudokuPuzzle

    init(puzzle: [[Int]], solution: [[Int]]) {
        self.puzzle = SudokuPuzzle(puzzle: puzzle, solution: solution)
        cells = puzzle.enumerated().flatMap { rowIndex, row in
            row.enumerated().map { columnIndex, number in
                let given = number == 0 ? nil : number
                return Cell(row: rowIndex, column: columnIndex, given: given, value: nil)
            }
        }
    }

    convenience init(puzzle: SudokuPuzzle) {
        self.init(puzzle: puzzle.puzzle, solution: puzzle.solution)
    }

    convenience init?(snapshot: SudokuSessionSnapshot) {
        guard snapshot.values.count == 81 else { return nil }
        self.init(puzzle: snapshot.puzzle)

        for index in snapshot.values.indices {
            if !cells[index].isGiven {
                cells[index].value = snapshot.values[index]
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
            && cells.allSatisfy { $0.displayValue == puzzle.solution[$0.row][$0.column] }
    }

    var firstEditableCellID: Cell.ID? {
        cells.first(where: { !$0.isGiven })?.id
    }

    var values: [Int?] {
        cells.map(\.value)
    }

    var progression: SudokuProgression {
        SudokuProgression(
            completedDigits: Set((1...9).filter(isDigitComplete(_:))),
            completedBlocks: Set((0..<9).filter(isBlockComplete(_:)))
        )
    }

    private func isDigitComplete(_ digit: Int) -> Bool {
        cells.allSatisfy { cell in
            if puzzle.solution[cell.row][cell.column] == digit {
                return cell.displayValue == digit && !hasConflict(at: cell.row, column: cell.column)
            }

            return cell.displayValue != digit
        }
    }

    private func isBlockComplete(_ block: Int) -> Bool {
        let rowStart = (block / 3) * 3
        let columnStart = (block % 3) * 3
        let blockCells = cells.filter { cell in
            (rowStart..<(rowStart + 3)).contains(cell.row)
                && (columnStart..<(columnStart + 3)).contains(cell.column)
        }

        return blockCells.allSatisfy { cell in
            guard let value = cell.displayValue else { return false }
            return value == puzzle.solution[cell.row][cell.column]
                && !hasConflict(at: cell.row, column: cell.column)
        }
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
        SudokuGame(puzzle: SudokuPuzzleGenerator().generate())
    }
}
