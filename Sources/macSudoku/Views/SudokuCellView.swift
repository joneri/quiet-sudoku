import SwiftUI

struct SudokuCellView: View {
    let cell: SudokuGame.Cell
    let isSelected: Bool
    let isPeer: Bool

    var body: some View {
        ZStack {
            Rectangle()
                .fill(backgroundStyle)

            if let value = cell.displayValue {
                Text("\(value)")
                    .font(.system(size: 28, weight: cell.isGiven ? .semibold : .medium, design: .rounded))
                    .minimumScaleFactor(0.45)
                    .foregroundStyle(cell.isGiven ? .primary : Color.cyan)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .stroke(Color.green.opacity(0.9), lineWidth: 3)
                    .padding(3)
            }
        }
    }

    private var backgroundStyle: Color {
        if isSelected {
            return Color.green.opacity(0.22)
        }

        if isPeer {
            return Color.primary.opacity(0.06)
        }

        return Color.primary.opacity(cell.isGiven ? 0.025 : 0.01)
    }
}

