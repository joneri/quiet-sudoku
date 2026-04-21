import SwiftUI

struct SudokuCellView: View {
    let cell: SudokuGame.Cell
    let isSelected: Bool
    let isPeer: Bool
    let isMatched: Bool
    let hasConflict: Bool
    let isDigitComplete: Bool

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)

            ZStack {
                Rectangle()
                    .fill(backgroundStyle)

                if let value = cell.displayValue {
                    let digitText = Text("\(value)")
                        .font(.system(size: fontSize(for: side), weight: fontWeight, design: .rounded))

                    let shadowStyle = SudokuDigitShadowStyle(
                        candidateShadowColor: candidateShadowColor,
                        candidateShadowRadius: cell.hasCandidate ? min(side * 0.24, 13) : 0,
                        candidateShadowOffset: cell.hasCandidate ? min(side * 0.24, 13) : 0,
                        candidateGroundShadowColor: Color.black.opacity(cell.hasCandidate ? 0.34 : 0),
                        candidateGroundShadowRadius: cell.hasCandidate ? min(side * 0.10, 4) : 0,
                        candidateGroundShadowOffset: cell.hasCandidate ? min(side * 0.14, 6) : 0
                    )

                    ZStack {
                        digitText
                            .foregroundStyle(foregroundStyle)
                            .modifier(lockedDigitReadabilityStyle(for: side))
                    }
                    .minimumScaleFactor(0.32)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .modifier(shadowStyle)
                        .offset(y: cell.hasCandidate ? -candidateLift(for: side) : 0)
                        .animation(.snappy(duration: 0.22), value: cell.hasCandidate)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
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

        return cell.isGiven ? Color.primary : lockedDigitColor
    }

    private var lockedDigitColor: Color {
        if isDigitComplete {
            return Color(red: 0.00, green: 0.46, blue: 0.16)
        }

        return Color(red: 0.00, green: 0.42, blue: 0.14)
    }

    private var candidateShadowColor: Color {
        Color.black.opacity(0.58)
    }

    private var usesLockedDigitHalo: Bool {
        !cell.isGiven && !cell.hasCandidate && !hasConflict
    }

    private func fontSize(for side: CGFloat) -> CGFloat {
        if cell.hasCandidate {
            return min(max(side * 0.66, 21), 34)
        }

        return min(max(side * 0.56, 19), 29)
    }

    private func candidateLift(for side: CGFloat) -> CGFloat {
        min(max(side * 0.13, 3), 7)
    }

    private var fontWeight: Font.Weight {
        if cell.hasCandidate {
            return .bold
        }

        return cell.isGiven ? .semibold : .bold
    }

    private func lockedDigitReadabilityStyle(for side: CGFloat) -> SudokuLockedDigitReadabilityStyle {
        SudokuLockedDigitReadabilityStyle(
            isEnabled: usesLockedDigitHalo,
            edgeColor: Color.white.opacity(0.78),
            edgeRadius: min(max(side * 0.012, 0.6), 1.0),
            haloColor: Color.white.opacity(0.38),
            haloRadius: min(max(side * 0.036, 1.5), 2.6)
        )
    }
}

private struct SudokuLockedDigitReadabilityStyle: ViewModifier {
    let isEnabled: Bool
    let edgeColor: Color
    let edgeRadius: CGFloat
    let haloColor: Color
    let haloRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .shadow(color: isEnabled ? edgeColor : .clear, radius: edgeRadius)
            .shadow(color: isEnabled ? haloColor : .clear, radius: haloRadius)
    }
}

private struct SudokuDigitShadowStyle: ViewModifier {
    let candidateShadowColor: Color
    let candidateShadowRadius: CGFloat
    let candidateShadowOffset: CGFloat
    let candidateGroundShadowColor: Color
    let candidateGroundShadowRadius: CGFloat
    let candidateGroundShadowOffset: CGFloat

    func body(content: Content) -> some View {
        content
            .shadow(color: candidateShadowColor, radius: candidateShadowRadius, y: candidateShadowOffset)
            .shadow(color: candidateGroundShadowColor, radius: candidateGroundShadowRadius, y: candidateGroundShadowOffset)
    }
}
