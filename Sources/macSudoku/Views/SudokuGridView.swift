import SwiftUI

struct SudokuGridView: View {
    let game: SudokuGame
    let selectedCell: SudokuGame.Cell.ID?
    let onSelectCell: (SudokuGame.Cell.ID) -> Void

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)

            VStack(spacing: 0) {
                ForEach(0..<9, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<9, id: \.self) { column in
                            let cell = game.cell(at: row, column: column)

                            Button {
                                onSelectCell(cell.id)
                            } label: {
                                SudokuCellView(
                                    cell: cell,
                                    isSelected: selectedCell == cell.id,
                                    isPeer: selectedCell.map { isPeer(cell.id, $0) } ?? false,
                                    isMatched: game.isMatchingSelectedValue(cell, selectedCellID: selectedCell),
                                    hasConflict: game.hasConflict(at: row, column: column)
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Sudoku cell row \(row + 1) column \(column + 1)")
                            .accessibilityIdentifier("sudoku-cell-\(row)-\(column)")
                        }
                    }
                }
            }
            .frame(width: side, height: side)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(SudokuGridLinesView())
            .overlay(completionGlow)
        }
    }

    @ViewBuilder
    private var completionGlow: some View {
        if game.isComplete {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.green.opacity(0.95), lineWidth: 4)
                .shadow(color: Color.green.opacity(0.55), radius: 18)
                .padding(2)
                .allowsHitTesting(false)
        }
    }

    private func isPeer(_ lhs: SudokuGame.Cell.ID, _ rhs: SudokuGame.Cell.ID) -> Bool {
        let lhsRow = lhs / 9
        let lhsColumn = lhs % 9
        let rhsRow = rhs / 9
        let rhsColumn = rhs % 9

        return lhsRow == rhsRow
            || lhsColumn == rhsColumn
            || (lhsRow / 3 == rhsRow / 3 && lhsColumn / 3 == rhsColumn / 3)
    }
}

