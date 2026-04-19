import SwiftUI

struct SudokuTopBarView: View {
    let boardSize: BoardSize
    let livesRemaining: Int
    let level: SudokuLevel
    let onCycleBoardSize: () -> Void
    let onLockAllCandidates: () -> Void
    let onRequestNewBoard: () -> Void
    let onShowLeaderboard: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let metrics = TopBarMetrics(width: proxy.size.width)

            ZStack {
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(WindowDragGesture())
                    .allowsWindowActivationEvents(true)

                HStack(spacing: metrics.groupSpacing) {
                    newBoardButton(metrics: metrics)
                    levelBadge(metrics: metrics)

                    Spacer(minLength: metrics.minimumSpacer)
                    lifeHearts(metrics: metrics)
                    Spacer(minLength: metrics.minimumSpacer)

                    HStack(spacing: metrics.trailingButtonSpacing) {
                        lockAllButton(metrics: metrics)
                        leaderboardButton(metrics: metrics)
                        sizeButton(metrics: metrics)
                    }
                }
                .padding(.horizontal, metrics.horizontalPadding)
            }
            .frame(height: BoardSize.topBarHeight)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color.primary.opacity(0.14))
                    .frame(height: 1)
            }
        }
        .frame(height: BoardSize.topBarHeight)
    }

    private func newBoardButton(metrics: TopBarMetrics) -> some View {
        Button(action: onRequestNewBoard) {
            Text("New")
                .font(.system(size: metrics.buttonFontSize, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)
                .frame(width: metrics.newButtonWidth, height: metrics.buttonHeight)
                .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("New board")
        .accessibilityIdentifier("new-board-button")
        .background(buttonBackground)
    }

    private func sizeButton(metrics: TopBarMetrics) -> some View {
        Button(action: onCycleBoardSize) {
            Text(boardSize.buttonTitle)
                .font(.system(size: metrics.buttonFontSize, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .frame(width: metrics.sizeButtonWidth, height: metrics.buttonHeight)
                .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Board size")
        .accessibilityValue(boardSize.accessibilityValue)
        .accessibilityIdentifier("board-size-button")
        .background(buttonBackground)
    }

    private func levelBadge(metrics: TopBarMetrics) -> some View {
        Text(metrics.usesCompactLevelTitle ? level.compactTitle : level.displayTitle)
            .font(.system(size: metrics.buttonFontSize, weight: .semibold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(Color.green.opacity(0.92))
            .frame(width: metrics.levelBadgeWidth, height: metrics.buttonHeight)
            .background(buttonBackground)
            .accessibilityLabel("Level")
            .accessibilityValue("\(level.number)")
            .accessibilityIdentifier("level-badge")
    }

    private func lockAllButton(metrics: TopBarMetrics) -> some View {
        Button(action: onLockAllCandidates) {
            Text("Lock all")
                .font(.system(size: metrics.buttonFontSize, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)
                .frame(width: metrics.lockButtonWidth, height: metrics.buttonHeight)
                .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Lock all numbers")
        .accessibilityIdentifier("lock-all-candidates-button")
        .background(buttonBackground)
    }

    private func leaderboardButton(metrics: TopBarMetrics) -> some View {
        Button(action: onShowLeaderboard) {
            Text(metrics.usesCompactScoresTitle ? "Top" : "Scores")
                .font(.system(size: metrics.buttonFontSize, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)
                .frame(width: metrics.leaderboardButtonWidth, height: metrics.buttonHeight)
                .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("High scores")
        .accessibilityIdentifier("show-leaderboard-button")
        .background(buttonBackground)
    }


    private func lifeHearts(metrics: TopBarMetrics) -> some View {
        HStack(spacing: metrics.heartSpacing) {
            ForEach(0..<heartCount, id: \.self) { index in
                Image(systemName: index < livesRemaining ? "heart.fill" : "heart")
                    .font(.system(size: metrics.heartFontSize, weight: .semibold))
                    .foregroundStyle(index < livesRemaining ? Color.red.opacity(0.94) : Color.primary.opacity(0.42))
                    .accessibilityHidden(true)
            }
        }
        .frame(width: metrics.heartRackWidth, height: metrics.buttonHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Lives")
        .accessibilityValue("\(livesRemaining)")
        .accessibilityIdentifier("life-hearts")
    }

    private var heartCount: Int {
        max(SudokuSessionStore.maximumLives, livesRemaining)
    }

    private var buttonBackground: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(.regularMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
            }
    }
}

private struct TopBarMetrics {
    let width: CGFloat

    var isCompact: Bool {
        width < 420
    }

    var isMedium: Bool {
        (420..<620).contains(width)
    }

    var usesCompactLevelTitle: Bool {
        isCompact || isMedium
    }

    var usesCompactScoresTitle: Bool {
        isCompact || isMedium
    }

    var horizontalPadding: CGFloat {
        if isCompact { return 5 }
        if isMedium { return 8 }
        return 12
    }

    var groupSpacing: CGFloat {
        if isCompact { return 2 }
        if isMedium { return 4 }
        return 8
    }

    var trailingButtonSpacing: CGFloat {
        if isCompact { return 3 }
        if isMedium { return 5 }
        return 8
    }

    var minimumSpacer: CGFloat {
        if isCompact { return 1 }
        if isMedium { return 3 }
        return 8
    }

    var buttonHeight: CGFloat {
        isCompact ? 26 : 30
    }

    var buttonFontSize: CGFloat {
        if isCompact { return 11 }
        if isMedium { return 12 }
        return 13
    }

    var newButtonWidth: CGFloat {
        if isCompact { return 41 }
        if isMedium { return 58 }
        return 72
    }

    var levelBadgeWidth: CGFloat {
        if isCompact { return 30 }
        if isMedium { return 36 }
        return 70
    }

    var lockButtonWidth: CGFloat {
        if isCompact { return 50 }
        if isMedium { return 68 }
        return 82
    }

    var leaderboardButtonWidth: CGFloat {
        if isCompact { return 34 }
        if isMedium { return 44 }
        return 68
    }

    var sizeButtonWidth: CGFloat {
        if isCompact { return 45 }
        if isMedium { return 68 }
        return 88
    }

    var heartFontSize: CGFloat {
        if isCompact { return 10 }
        if isMedium { return 13 }
        return 15
    }

    var heartSpacing: CGFloat {
        if isCompact { return 2 }
        if isMedium { return 4 }
        return 5
    }

    var heartRackWidth: CGFloat {
        let heartSlots = CGFloat(SudokuSessionStore.maximumLives)
        let spacing = CGFloat(SudokuSessionStore.maximumLives - 1) * heartSpacing
        let sidePadding: CGFloat = isCompact ? 2 : (isMedium ? 6 : 12)
        return heartSlots * heartFontSize + spacing + sidePadding
    }

    var minimumRequiredWidth: CGFloat {
        horizontalPadding * 2
            + newButtonWidth
            + levelBadgeWidth
            + heartRackWidth
            + lockButtonWidth
            + leaderboardButtonWidth
            + sizeButtonWidth
            + groupSpacing
            + trailingButtonSpacing * 2
            + minimumSpacer * 2
    }
}

extension SudokuTopBarView {
    static func metricsSnapshot(width: CGFloat) -> [String: Any] {
        let metrics = TopBarMetrics(width: width)
        return [
            "heartRackWidth": metrics.heartRackWidth,
            "minimumRequiredWidth": metrics.minimumRequiredWidth,
            "usesCompactLevelTitle": metrics.usesCompactLevelTitle,
            "usesCompactScoresTitle": metrics.usesCompactScoresTitle
        ]
    }
}
