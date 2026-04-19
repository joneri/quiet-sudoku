import SwiftUI

struct SudokuCellView: View {
    let cell: SudokuGame.Cell
    let isSelected: Bool
    let isPeer: Bool
    let isMatched: Bool
    let hasConflict: Bool
    let isDigitComplete: Bool

    var body: some View {
        ZStack {
            Rectangle()
                .fill(backgroundStyle)

            if let value = cell.displayValue {
                Text("\(value)")
                    .font(.system(size: 28, weight: cell.isGiven ? .semibold : .medium, design: .rounded))
                    .minimumScaleFactor(0.32)
                    .foregroundStyle(foregroundStyle)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .shadow(color: digitGlowColor, radius: isDigitComplete ? 11 : 0)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .stroke(Color.green.opacity(0.9), lineWidth: 3)
                    .padding(2)
            }
        }
    }

    private var backgroundStyle: Color {
        if hasConflict {
            return Color.red.opacity(isSelected ? 0.30 : 0.18)
        }

        if isSelected {
            return Color.green.opacity(0.22)
        }

        if isMatched {
            return Color.cyan.opacity(0.14)
        }

        if isPeer {
            return Color.primary.opacity(0.06)
        }

        return Color.primary.opacity(cell.isGiven ? 0.025 : 0.01)
    }

    private var foregroundStyle: Color {
        if hasConflict {
            return Color.red.opacity(0.95)
        }

        return cell.isGiven ? Color.primary : Color.cyan.opacity(0.95)
    }

    private var digitGlowColor: Color {
        hasConflict ? .clear : Color.green.opacity(0.75)
    }
}
