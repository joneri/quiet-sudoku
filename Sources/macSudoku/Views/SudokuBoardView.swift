import SwiftUI

struct SudokuBoardView: View {
    @State var game: SudokuGame
    @State private var selectedCell: SudokuGame.Cell.ID?
    @FocusState private var boardHasFocus: Bool

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
                                    isPeer: selectedCell.map { isPeer(cell.id, $0) } ?? false
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedCell = cell.id
                                    boardHasFocus = true
                                }
                            }
                        }
                    }
                }
                .frame(width: side, height: side)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(gridLines)
                .padding(0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
        .focusable()
        .focused($boardHasFocus)
        .focusEffectDisabled()
        .onAppear {
            boardHasFocus = true
            selectedCell = selectedCell ?? game.cells.first(where: { !$0.isGiven })?.id
        }
        .onKeyPress { press in
            handleKeyPress(press)
        }
    }

    private var boardBackground: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
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
        .allowsHitTesting(false)
    }

    private func handleKeyPress(_ press: KeyPress) -> KeyPress.Result {
        guard let selectedCell else {
            return .ignored
        }

        let row = selectedCell / 9
        let column = selectedCell % 9

        if let character = press.characters.first, let value = Int(String(character)), (1...9).contains(value) {
            game.setValue(value, row: row, column: column)
            return .handled
        }

        switch press.key {
        case .delete, .deleteForward:
            game.setValue(nil, row: row, column: column)
            return .handled
        case .upArrow:
            moveSelection(rowDelta: -1, columnDelta: 0)
            return .handled
        case .downArrow:
            moveSelection(rowDelta: 1, columnDelta: 0)
            return .handled
        case .leftArrow:
            moveSelection(rowDelta: 0, columnDelta: -1)
            return .handled
        case .rightArrow:
            moveSelection(rowDelta: 0, columnDelta: 1)
            return .handled
        default:
            if press.characters == "0" || press.characters == " " {
                game.setValue(nil, row: row, column: column)
                return .handled
            }

            return .ignored
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
