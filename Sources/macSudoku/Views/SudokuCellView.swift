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
                    .font(.system(size: fontSize, weight: fontWeight, design: .rounded))
                    .minimumScaleFactor(0.32)
                    .foregroundStyle(foregroundStyle)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .shadow(color: digitGlowColor, radius: isDigitComplete ? 11 : 0)
                    .shadow(color: candidateShadowColor, radius: cell.hasCandidate ? 13 : 0, y: cell.hasCandidate ? 13 : 0)
                    .shadow(color: Color.black.opacity(cell.hasCandidate ? 0.34 : 0), radius: cell.hasCandidate ? 4 : 0, y: cell.hasCandidate ? 6 : 0)
                    .offset(y: cell.hasCandidate ? -7 : 0)
                    .animation(.snappy(duration: 0.22), value: cell.hasCandidate)
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

        if cell.hasCandidate {
            return Color(red: 0.86, green: 0.34, blue: 0.05)
        }

        return cell.isGiven ? Color.primary : Color.green.opacity(0.88)
    }

    private var digitGlowColor: Color {
        hasConflict ? .clear : Color.green.opacity(0.75)
    }

    private var candidateShadowColor: Color {
        Color.black.opacity(0.58)
    }

    private var fontSize: CGFloat {
        cell.hasCandidate ? 34 : 28
    }

    private var fontWeight: Font.Weight {
        if cell.hasCandidate {
            return .bold
        }

        return cell.isGiven ? .semibold : .medium
    }
}
