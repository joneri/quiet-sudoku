import SwiftUI

struct LeaderboardListView: View {
    let entries: [LeaderboardEntry]
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Text("High scores")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(Color.green.opacity(0.92))

            if entries.isEmpty {
                Text("No scores yet.")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(width: 170, height: 70)
            } else {
                VStack(spacing: entries.count > 8 ? 4 : 7) {
                    ForEach(Array(entries.prefix(15).enumerated()), id: \.element.id) { index, entry in
                        HStack {
                            Text("\(index + 1).")
                                .frame(width: 24, alignment: .leading)
                            Text(entry.initials)
                                .frame(width: 42, alignment: .leading)
                            Spacer()
                            Text("\(entry.levelsCompleted)")
                                .monospacedDigit()
                        }
                        .font(.system(size: entries.count > 8 ? 11 : 13, weight: .semibold, design: .rounded))
                    }
                }
                .frame(width: 170)
            }

            Button("Close") {
                onClose()
            }
            .buttonStyle(.plain)
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .frame(width: 96, height: 32)
            .background(buttonBackground)
            .accessibilityLabel("Close high scores")
            .accessibilityIdentifier("close-leaderboard-button")
        }
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.regularMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.24), lineWidth: 1)
                }
        }
        .shadow(color: Color.black.opacity(0.24), radius: 22)
        .accessibilityIdentifier("leaderboard-view")
    }

    private var buttonBackground: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(.thinMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.20), lineWidth: 1)
            }
    }
}
