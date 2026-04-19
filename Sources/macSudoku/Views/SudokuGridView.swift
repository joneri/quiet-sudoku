import SwiftUI

struct SudokuGridView: View {
    let game: SudokuGame
    let selectedCell: SudokuGame.Cell.ID?
    let sparkleTriggerCount: Int
    let onLockCandidate: (SudokuGame.Cell.ID) -> Void
    let onSelectCell: (SudokuGame.Cell.ID) -> Void
    private var progression: SudokuProgression {
        game.progression
    }

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)

            VStack(spacing: 0) {
                ForEach(0..<9, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<9, id: \.self) { column in
                            let cell = game.cell(at: row, column: column)

                            ZStack {
                                Button {
                                    onSelectCell(cell.id)
                                } label: {
                                    SudokuCellView(
                                        cell: cell,
                                        isSelected: selectedCell == cell.id,
                                        isPeer: selectedCell.map { isPeer(cell.id, $0) } ?? false,
                                        isMatched: game.isMatchingSelectedValue(cell, selectedCellID: selectedCell),
                                        hasConflict: game.hasConflict(at: row, column: column),
                                        isDigitComplete: cell.displayValue.map { progression.completedDigits.contains($0) } ?? false
                                    )
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Sudoku cell row \(row + 1) column \(column + 1)")
                                .accessibilityIdentifier("sudoku-cell-\(row)-\(column)")

                                if cell.hasCandidate {
                                    CandidateLockButton {
                                        onLockCandidate(cell.id)
                                    }
                                    .padding(5)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                                    .accessibilityLabel("Lock cell row \(row + 1) column \(column + 1)")
                                    .accessibilityIdentifier("lock-candidate-cell-\(row)-\(column)")
                                }
                            }
                        }
                    }
                }
            }
            .frame(width: side, height: side)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(SudokuBlockCompletionGlowView(progression: progression))
            .overlay(SudokuSparkleSweepView(triggerCount: sparkleTriggerCount))
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

private struct CandidateLockButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.down.to.line.compact")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.95))
                .frame(width: 24, height: 24)
                .background {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.green.opacity(0.72))
                        .shadow(color: Color.black.opacity(0.32), radius: 7, y: 4)
                }
                .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
