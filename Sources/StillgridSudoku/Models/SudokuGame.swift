import Foundation

@Observable
final class SudokuGame {
    struct Cell: Identifiable {
        let row: Int
        let column: Int
        let given: Int?
        var value: Int?
        var candidateValue: Int?

        var id: Int { row * 9 + column }
        var isGiven: Bool { given != nil }
        var isLocked: Bool { given != nil || value != nil }
        var displayValue: Int? { given ?? value ?? candidateValue }
        var lockedValue: Int? { given ?? value }
        var hasCandidate: Bool { !isLocked && candidateValue != nil }
    }

    private(set) var cells: [Cell]
    let puzzle: SudokuPuzzle

    init(puzzle: [[Int]], solution: [[Int]]) {
        self.puzzle = SudokuPuzzle(puzzle: puzzle, solution: solution)
        cells = puzzle.enumerated().flatMap { rowIndex, row in
            row.enumerated().map { columnIndex, number in
                let given = number == 0 ? nil : number
                return Cell(row: rowIndex, column: columnIndex, given: given, value: nil, candidateValue: nil)
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

        let candidateValues = snapshot.normalizedCandidateValues
        for index in candidateValues.indices {
            if !cells[index].isLocked {
                cells[index].candidateValue = candidateValues[index]
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
        cells[index].candidateValue = nil
    }

    func setCandidateValue(_ value: Int?, row: Int, column: Int) {
        let index = row * 9 + column
        guard cells.indices.contains(index), !cells[index].isLocked else { return }
        cells[index].candidateValue = value
    }

    func lockCandidate(row: Int, column: Int) -> Bool? {
        let index = row * 9 + column
        return lockCandidate(cellID: index)
    }

    func lockCandidate(cellID: Cell.ID) -> Bool? {
        guard cells.indices.contains(cellID) else { return nil }
        let row = cells[cellID].row
        let column = cells[cellID].column

        guard
            !cells[cellID].isLocked,
            let candidateValue = cells[cellID].candidateValue
        else {
            return nil
        }

        guard candidateValue == puzzle.solution[row][column] else {
            return false
        }

        cells[cellID].value = candidateValue
        cells[cellID].candidateValue = nil
        return true
    }

    var candidateCellIDs: [Cell.ID] {
        cells.filter(\.hasCandidate).map(\.id)
    }

    func hasConflict(at row: Int, column: Int) -> Bool {
        let current = cell(at: row, column: column)
        guard let value = current.lockedValue else { return false }

        return peers(for: row, column: column).contains { peer in
            peer.id != current.id && peer.lockedValue == value
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
        cells.allSatisfy { $0.lockedValue != nil }
            && !cells.contains { hasConflict(at: $0.row, column: $0.column) }
            && cells.allSatisfy { $0.lockedValue == puzzle.solution[$0.row][$0.column] }
    }

    var firstEditableCellID: Cell.ID? {
        cells.first(where: { !$0.isGiven })?.id
    }

    var values: [Int?] {
        cells.map(\.value)
    }

    var candidateValues: [Int?] {
        cells.map(\.candidateValue)
    }

    var progression: SudokuProgression {
        SudokuProgression(
            completedDigits: Set((1...9).filter(isDigitComplete(_:))),
            completedBlocks: Set((0..<9).filter(isBlockComplete(_:))),
            completedRows: Set((0..<9).filter(isRowComplete(_:))),
            completedColumns: Set((0..<9).filter(isColumnComplete(_:)))
        )
    }

    private func isDigitComplete(_ digit: Int) -> Bool {
        cells.allSatisfy { cell in
            if puzzle.solution[cell.row][cell.column] == digit {
                return cell.lockedValue == digit && !hasConflict(at: cell.row, column: cell.column)
            }

            return cell.lockedValue != digit
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
            guard let value = cell.lockedValue else { return false }
            return value == puzzle.solution[cell.row][cell.column]
                && !hasConflict(at: cell.row, column: cell.column)
        }
    }

    private func isRowComplete(_ row: Int) -> Bool {
        cells
            .filter { $0.row == row }
            .allSatisfy(isCellCorrectAndConflictFree(_:))
    }

    private func isColumnComplete(_ column: Int) -> Bool {
        cells
            .filter { $0.column == column }
            .allSatisfy(isCellCorrectAndConflictFree(_:))
    }

    private func isCellCorrectAndConflictFree(_ cell: Cell) -> Bool {
        guard let value = cell.lockedValue else { return false }
        return value == puzzle.solution[cell.row][cell.column]
            && !hasConflict(at: cell.row, column: cell.column)
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
