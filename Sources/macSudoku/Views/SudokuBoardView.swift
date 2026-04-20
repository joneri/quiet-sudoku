import SwiftUI

struct SudokuBoardView: View {
    @State private var store: SudokuSessionStore
    @State private var isConfirmingNewBoard = false
    @State private var isShowingCompletionMessage = false
    @State private var isEnteringLeaderboard = false
    @State private var isShowingLeaderboard = false
    @State private var newBoardIntent: NewBoardIntent = .newRun
    @State private var sparkleTriggerCount = 0
    @State private var lifeLossFeedbackTriggerCount = 0
    @State private var wasComplete = false

    init(store: SudokuSessionStore = SudokuSessionStore()) {
        _store = State(initialValue: store)
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                boardBackground

                VStack(spacing: 0) {
                    SudokuTopBarView(
                        boardSize: store.boardSize,
                        livesRemaining: store.livesRemaining,
                        level: store.level,
                        leaderboardUpdateCount: store.leaderboardUpdateCount,
                        onCycleBoardSize: cycleBoardSize,
                        onLockAllCandidates: lockAllCandidates,
                        onRequestNewBoard: requestNewBoard,
                        onShowLeaderboard: showLeaderboard
                    )

                    SudokuGridView(
                        game: store.game,
                        selectedCell: store.selectedCell,
                        sparkleTriggerCount: sparkleTriggerCount,
                        onLockCandidate: lockCandidate,
                        onSelectCell: selectCell
                    )
                    .frame(width: store.boardSize.boardSide, height: store.boardSize.boardSide)
                }

                SudokuBoardEdgeCompletionLightsView(
                    progression: store.game.progression,
                    boardSide: store.boardSize.boardSide,
                    topInset: BoardSize.topBarHeight
                )

                LifeLossFeedbackView(triggerCount: lifeLossFeedbackTriggerCount)

                if store.isGameOver {
                    gameOverOverlay
                }

                if isEnteringLeaderboard {
                    Color.black.opacity(0.10)
                        .ignoresSafeArea()

                    LeaderboardEntryView(
                        title: store.isGameOver ? "Game Over" : "High Score",
                        levelsCompleted: leaderboardPromptScore,
                        entries: store.leaderboardEntries,
                        onSubmit: submitLeaderboardEntry
                    )
                    .transition(.scale(scale: 0.96).combined(with: .opacity))
                }

                if isShowingLeaderboard {
                    Color.black.opacity(0.10)
                        .ignoresSafeArea()

                    LeaderboardListView(
                        entries: store.leaderboardEntries,
                        onClose: hideLeaderboard
                    )
                    .transition(.scale(scale: 0.96).combined(with: .opacity))
                }

                if isShowingCompletionMessage && !isConfirmingNewBoard {
                    completionOverlay
                }

                if isConfirmingNewBoard {
                    Color.black.opacity(0.10)
                        .ignoresSafeArea()

                    NewBoardConfirmationView(
                        onConfirm: confirmNewBoard,
                        onCancel: cancelNewBoard
                    )
                    .transition(.scale(scale: 0.96).combined(with: .opacity))
                }
            }
        }
        .frame(width: store.boardSize.boardSide, height: store.boardSize.windowHeight)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .contentShape(Rectangle())
        .aspectRatio(nil, contentMode: .fit)
        .background {
            KeyboardInputBridge { input in
                let handled = store.handleKeyboardInput(input)
                if handled {
                    triggerSparkleWhenPuzzleBecomesComplete()
                    recordUITestState()
                }
                return handled
            }
        }
        .onAppear {
            wasComplete = store.game.isComplete
            if store.isGameOver {
                prepareGameOverNextStep()
            }
            recordUITestState()
        }
        .onChange(of: store.livesRemaining) { previousLives, livesRemaining in
            if livesRemaining < previousLives {
                lifeLossFeedbackTriggerCount += 1
            }

            if livesRemaining == 0 {
                isShowingCompletionMessage = false
                isConfirmingNewBoard = false
                prepareGameOverNextStep()
            }
            recordUITestState()
        }
        .animation(.snappy(duration: 0.24), value: store.boardSize)
        .animation(.snappy(duration: 0.18), value: isConfirmingNewBoard)
        .animation(.snappy(duration: 0.18), value: isEnteringLeaderboard)
        .animation(.snappy(duration: 0.18), value: isShowingLeaderboard)
        .animation(.smooth(duration: 0.24), value: isShowingCompletionMessage)
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

    private var gameOverOverlay: some View {
        VStack(spacing: 8) {
            Text("Game Over")
                .font(.system(size: 46, weight: .black, design: .rounded))
                .foregroundStyle(Color.red.opacity(0.94))
                .shadow(color: Color.black.opacity(0.40), radius: 14, y: 6)

            Text("Generate a new board to play again.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.primary.opacity(0.78))
        }
        .frame(width: store.boardSize.boardSide, height: store.boardSize.windowHeight)
        .background(Color.black.opacity(0.18))
        .allowsHitTesting(false)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Game Over")
        .accessibilityIdentifier("game-over-overlay")
    }

    private var leaderboardPromptScore: Int {
        store.game.isComplete ? store.completedLevelScore : store.levelsCompleted
    }

    private var completionOverlay: some View {
        Text("Congratulations!")
            .font(.system(size: 42, weight: .black, design: .rounded))
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.98),
                        Color.green.opacity(0.94),
                        Color.cyan.opacity(0.78)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(color: Color.green.opacity(0.62), radius: 18)
            .shadow(color: Color.black.opacity(0.32), radius: 12, y: 6)
            .frame(width: store.boardSize.boardSide, height: store.boardSize.windowHeight)
            .background(Color.black.opacity(0.08))
            .allowsHitTesting(false)
            .accessibilityLabel("Congratulations!")
            .accessibilityIdentifier("completion-congratulations-overlay")
    }

    private func cycleBoardSize() {
        store.cycleBoardSize()
        recordUITestState()
    }

    private func lockCandidate(_ cellID: SudokuGame.Cell.ID) {
        store.lockCandidate(cellID: cellID)
        triggerSparkleWhenPuzzleBecomesComplete()
        recordUITestState()
    }

    private func lockAllCandidates() {
        store.lockAllCandidates()
        triggerSparkleWhenPuzzleBecomesComplete()
        recordUITestState()
    }

    private func selectCell(_ cellID: SudokuGame.Cell.ID) {
        store.selectCell(cellID)
        recordUITestState()
    }

    private func requestNewBoard() {
        isShowingCompletionMessage = false
        isShowingLeaderboard = false
        newBoardIntent = .newRun
        isConfirmingNewBoard = true
        recordUITestState()
    }

    private func confirmNewBoard() {
        isShowingCompletionMessage = false
        isConfirmingNewBoard = false
        switch newBoardIntent {
        case .newRun, .gameOverRestart:
            store.startNewRun()
        case .nextLevel:
            store.advanceToNextLevel()
        }
        wasComplete = store.game.isComplete
        recordUITestState()
    }

    private func cancelNewBoard() {
        isShowingCompletionMessage = false
        if store.isGameOver {
            prepareGameOverNextStep()
        }
        isConfirmingNewBoard = false
        recordUITestState()
    }

    private func prepareGameOverNextStep() {
        if store.shouldPromptForGameOverLeaderboard() {
            isEnteringLeaderboard = true
        } else {
            newBoardIntent = .gameOverRestart
            isConfirmingNewBoard = true
        }
    }

    private func submitLeaderboardEntry(_ initials: String) {
        store.submitLeaderboardEntry(initials: initials)
        isEnteringLeaderboard = false
        newBoardIntent = store.isGameOver ? .gameOverRestart : .nextLevel
        isConfirmingNewBoard = true
        recordUITestState()
    }

    private func showLeaderboard() {
        isShowingCompletionMessage = false
        isShowingLeaderboard = true
        recordUITestState()
    }

    private func hideLeaderboard() {
        isShowingLeaderboard = false
        recordUITestState()
    }

    private func recordUITestState() {
        UITestProbe.record(
            snapshot: store.snapshot(),
            isConfirmingNewBoard: isConfirmingNewBoard,
            isEnteringLeaderboard: isEnteringLeaderboard,
            isShowingLeaderboard: isShowingLeaderboard,
            isShowingCompletionMessage: isShowingCompletionMessage,
            isGameOver: store.isGameOver,
            leaderboardEntries: store.leaderboardEntries,
            leaderboardInitials: store.leaderboardInitials,
            leaderboardUpdateCount: store.leaderboardUpdateCount,
            lifeLossFeedbackTriggerCount: lifeLossFeedbackTriggerCount,
            sparkleTriggerCount: sparkleTriggerCount
        )
    }

    private func triggerSparkle() {
        sparkleTriggerCount += 1
    }

    private func triggerSparkleWhenPuzzleBecomesComplete() {
        let isComplete = store.game.isComplete
        if isComplete && !wasComplete {
            store.awardCompletionLife()
            triggerSparkle()
            _ = store.recordCompletedLevelForActiveLeaderboardPlayer()
            showCompletionMessageThenPrompt()
        }
        wasComplete = isComplete
    }

    private func showCompletionMessageThenPrompt() {
        isShowingCompletionMessage = true
        recordUITestState()

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_700_000_000)
            guard store.game.isComplete, !store.isGameOver else { return }

            isShowingCompletionMessage = false
            if store.shouldPromptForCompletedLevelLeaderboard() {
                isEnteringLeaderboard = true
            } else {
                newBoardIntent = .nextLevel
                isConfirmingNewBoard = true
            }
            recordUITestState()
        }
    }
}

private enum NewBoardIntent {
    case newRun
    case nextLevel
    case gameOverRestart
}
