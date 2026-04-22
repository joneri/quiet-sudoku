import SwiftUI

struct NewBoardConfirmationView: View {
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Text("Generate a new board?")
                .font(.system(size: 17, weight: .semibold, design: .rounded))

            Text("Your current numbers will be replaced.")
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                Button("Keep") {
                    onCancel()
                }
                .buttonStyle(.plain)
                .frame(width: 88, height: 32)
                .background(buttonBackground)
                .accessibilityIdentifier("cancel-new-board-button")

                Button("Generate") {
                    onConfirm()
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.red.opacity(0.95))
                .frame(width: 104, height: 32)
                .background(buttonBackground)
                .accessibilityIdentifier("confirm-new-board-button")
            }
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
        .shadow(color: Color.black.opacity(0.22), radius: 20)
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

