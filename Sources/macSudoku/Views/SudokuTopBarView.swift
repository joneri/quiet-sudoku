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
        Text(metrics.isCompact ? level.compactTitle : level.displayTitle)
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
            Text(metrics.isCompact ? "Top" : "Scores")
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

    var horizontalPadding: CGFloat {
        isCompact ? 5 : 12
    }

    var groupSpacing: CGFloat {
        isCompact ? 2 : 8
    }

    var trailingButtonSpacing: CGFloat {
        isCompact ? 3 : 8
    }

    var minimumSpacer: CGFloat {
        isCompact ? 1 : 8
    }

    var buttonHeight: CGFloat {
        isCompact ? 26 : 30
    }

    var buttonFontSize: CGFloat {
        isCompact ? 11 : 13
    }

    var newButtonWidth: CGFloat {
        isCompact ? 41 : 72
    }

    var levelBadgeWidth: CGFloat {
        isCompact ? 30 : 70
    }

    var lockButtonWidth: CGFloat {
        isCompact ? 50 : 82
    }

    var leaderboardButtonWidth: CGFloat {
        isCompact ? 34 : 68
    }

    var sizeButtonWidth: CGFloat {
        isCompact ? 45 : 88
    }

    var heartFontSize: CGFloat {
        isCompact ? 10 : 15
    }

    var heartSpacing: CGFloat {
        isCompact ? 2 : 5
    }

    var heartRackWidth: CGFloat {
        let heartSlots = CGFloat(SudokuSessionStore.maximumLives)
        let spacing = CGFloat(SudokuSessionStore.maximumLives - 1) * heartSpacing
        let sidePadding: CGFloat = isCompact ? 2 : 12
        return heartSlots * heartFontSize + spacing + sidePadding
    }
}
