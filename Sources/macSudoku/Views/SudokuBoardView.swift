import SwiftUI

struct SudokuBoardView: View {
    @State var game: SudokuGame
    @State private var selectedCell: SudokuGame.Cell.ID?

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)

            ZStack {
                boardBackground

                VStack(spacing: 0) {
                    ForEach(0..<9, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<9, id: \.self) { column in
                                let cell = game.cell(at: row, column: column)

                                SudokuCellView(
                                    cell: cell,
                                    isSelected: selectedCell == cell.id,
                                    isPeer: selectedCell.map { isPeer(cell.id, $0) } ?? false,
                                    isMatched: game.isMatchingSelectedValue(cell, selectedCellID: selectedCell),
                                    hasConflict: game.hasConflict(at: row, column: column)
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedCell = cell.id
                                }
                            }
                        }
                    }
                }
                .frame(width: side, height: side)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(gridLines)
                .overlay(completionGlow)
                .padding(0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
        .background {
            KeyboardInputBridge { input in
                handleKeyboardInput(input)
            }
        }
        .onAppear {
            selectedCell = selectedCell ?? game.cells.first(where: { !$0.isGiven })?.id
        }
    }

    private var boardBackground: some View {
        Rectangle()
            .fill(.thinMaterial)
            .overlay {
                LinearGradient(
                    colors: [
                        Color.primary.opacity(0.08),
                        Color.cyan.opacity(0.10),
                        Color.green.opacity(0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .blendMode(.plusLighter)
            }
            .overlay(alignment: .topLeading) {
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.22),
                        Color.clear
                    ],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 420
                )
                .blendMode(.screen)
                .allowsHitTesting(false)
            }
            .overlay(alignment: .bottomTrailing) {
                RadialGradient(
                    colors: [
                        Color.black.opacity(0.16),
                        Color.clear
                    ],
                    center: .bottomTrailing,
                    startRadius: 0,
                    endRadius: 520
                )
                .blendMode(.softLight)
                .allowsHitTesting(false)
            }
            .ignoresSafeArea()
    }

    private var gridLines: some View {
        GeometryReader { proxy in
            Path { path in
                let cell = proxy.size.width / 9

                for index in 1..<9 {
                    let position = CGFloat(index) * cell
                    path.move(to: CGPoint(x: position, y: 0))
                    path.addLine(to: CGPoint(x: position, y: proxy.size.height))
                    path.move(to: CGPoint(x: 0, y: position))
                    path.addLine(to: CGPoint(x: proxy.size.width, y: position))
                }
            }
            .stroke(Color.primary.opacity(0.22), lineWidth: 1)

            Path { path in
                let block = proxy.size.width / 3

                for index in 1..<3 {
                    let position = CGFloat(index) * block
                    path.move(to: CGPoint(x: position, y: 0))
                    path.addLine(to: CGPoint(x: position, y: proxy.size.height))
                    path.move(to: CGPoint(x: 0, y: position))
                    path.addLine(to: CGPoint(x: proxy.size.width, y: position))
                }
            }
                .stroke(Color.primary.opacity(0.62), lineWidth: 2.5)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.white.opacity(0.20), lineWidth: 1)
                .blendMode(.plusLighter)
        }
        .allowsHitTesting(false)
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

    private func handleKeyboardInput(_ input: SudokuKeyboardInput) -> Bool {
        guard let selectedCell else {
            return false
        }

        let row = selectedCell / 9
        let column = selectedCell % 9

        switch input {
        case .digit(let value):
            game.setValue(value, row: row, column: column)
            return true
        case .clear:
            game.setValue(nil, row: row, column: column)
            return true
        case .move(let rowDelta, let columnDelta):
            moveSelection(rowDelta: rowDelta, columnDelta: columnDelta)
            return true
        }
    }

    private func moveSelection(rowDelta: Int, columnDelta: Int) {
        let current = selectedCell ?? 0
        let row = max(0, min(8, current / 9 + rowDelta))
        let column = max(0, min(8, current % 9 + columnDelta))
        selectedCell = row * 9 + column
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
