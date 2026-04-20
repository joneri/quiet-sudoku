import SwiftUI

struct LifeLossFeedbackView: View {
    let triggerCount: Int

    @State private var isVisible = false
    @State private var shakeOffset: CGFloat = 0

    var body: some View {
        ZStack {
            edgeGlow
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.14), value: isVisible)

            Color.red
                .opacity(isVisible ? 0.08 : 0)
                .blendMode(.plusLighter)
                .animation(.easeOut(duration: 0.14), value: isVisible)
        }
        .offset(x: shakeOffset)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onChange(of: triggerCount) { _, newValue in
            guard newValue > 0 else { return }
            play()
        }
    }

    private var edgeGlow: some View {
        ZStack {
            VStack(spacing: 0) {
                edgeBand(edge: .top)
                Spacer(minLength: 0)
                edgeBand(edge: .bottom)
            }

            HStack(spacing: 0) {
                edgeBand(edge: .leading)
                Spacer(minLength: 0)
                edgeBand(edge: .trailing)
            }
        }
    }

    private func edgeBand(edge: Edge) -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.red.opacity(0.72),
                        Color.red.opacity(0.30),
                        Color.clear
                    ],
                    startPoint: edge.startPoint,
                    endPoint: edge.endPoint
                )
            )
            .frame(width: edge.width, height: edge.height)
            .shadow(color: Color.red.opacity(0.68), radius: 18)
            .blendMode(.plusLighter)
    }

    private func play() {
        Task { @MainActor in
            withAnimation(.easeOut(duration: 0.12)) {
                isVisible = true
                shakeOffset = -5
            }

            try? await Task.sleep(nanoseconds: 70_000_000)
            withAnimation(.easeInOut(duration: 0.08)) {
                shakeOffset = 5
            }

            try? await Task.sleep(nanoseconds: 80_000_000)
            withAnimation(.easeInOut(duration: 0.08)) {
                shakeOffset = -2
            }

            try? await Task.sleep(nanoseconds: 120_000_000)
            withAnimation(.easeOut(duration: 0.42)) {
                isVisible = false
                shakeOffset = 0
            }
        }
    }
}

private extension Edge {
    var startPoint: UnitPoint {
        switch self {
        case .top:
            return .top
        case .bottom:
            return .bottom
        case .leading:
            return .leading
        case .trailing:
            return .trailing
        }
    }

    var endPoint: UnitPoint {
        switch self {
        case .top:
            return .bottom
        case .bottom:
            return .top
        case .leading:
            return .trailing
        case .trailing:
            return .leading
        }
    }

    var width: CGFloat? {
        switch self {
        case .top, .bottom:
            return nil
        case .leading, .trailing:
            return 38
        }
    }

    var height: CGFloat? {
        switch self {
        case .top, .bottom:
            return 38
        case .leading, .trailing:
            return nil
        }
    }
}
