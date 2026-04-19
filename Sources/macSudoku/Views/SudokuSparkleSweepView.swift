import SwiftUI

struct SudokuSparkleSweepView: View {
    let triggerCount: Int

    @State private var progress: CGFloat = 0
    @State private var visibility = 0.0

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)

            ZStack {
                waveGlow(side: side)
                sparkleTrail(in: proxy.size)
            }
            .frame(width: side, height: side)
            .opacity(visibility)
            .blendMode(.plusLighter)
            .allowsHitTesting(false)
            .onChange(of: triggerCount) {
                if triggerCount > 0 {
                    runSweep()
                }
            }
        }
        .accessibilityHidden(true)
    }

    private func waveGlow(side: CGFloat) -> some View {
        ZStack {
            MagicWaveShape(progress: progress)
                .stroke(
                    Color.cyan.opacity(0.20),
                    style: StrokeStyle(lineWidth: max(side * 0.060, 28), lineCap: .round, lineJoin: .round)
                )
                .blur(radius: max(side * 0.018, 8))

            MagicWaveShape(progress: progress)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.95),
                            Color.cyan.opacity(0.72),
                            Color.green.opacity(0.45),
                            Color.white.opacity(0.70)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: max(side * 0.012, 6), lineCap: .round, lineJoin: .round)
                )
                .shadow(color: Color.white.opacity(0.70), radius: max(side * 0.020, 8))
                .shadow(color: Color.cyan.opacity(0.40), radius: max(side * 0.050, 18))
        }
    }

    private func sparkleTrail(in size: CGSize) -> some View {
        let side = min(size.width, size.height)

        return ZStack {
            ForEach(SparkleParticle.all) { particle in
                SparkleParticleView(
                    particle: particle,
                    side: side,
                    point: MagicWavePath.point(at: max(0, min(progress - particle.trailingOffset, 1)), in: size)
                )
            }
        }
    }

    private func runSweep() {
        progress = 0
        visibility = 1

        withAnimation(.smooth(duration: 1.55)) {
            progress = 1
        }

        withAnimation(.easeOut(duration: 0.48).delay(1.10)) {
            visibility = 0
        }
    }
}

private struct SparkleParticleView: View {
    let particle: SparkleParticle
    let side: CGFloat
    let point: CGPoint

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.95),
                        particle.tint.opacity(0.52),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: max(side * particle.size, 6)
                )
            )
            .frame(width: max(side * particle.size, 5), height: max(side * particle.size, 5))
            .shadow(color: particle.tint.opacity(0.62), radius: max(side * 0.018, 7))
            .position(
                x: point.x + side * particle.xDrift,
                y: point.y + side * particle.yDrift
            )
            .scaleEffect(0.72 + particle.twinkle * 0.38)
            .opacity(point.x <= 0 ? 0 : 1)
    }
}

private struct SparkleParticle: Identifiable {
    let id: Int
    let trailingOffset: CGFloat
    let xDrift: CGFloat
    let yDrift: CGFloat
    let size: CGFloat
    let twinkle: CGFloat
    let tint: Color

    static let all: [SparkleParticle] = [
        SparkleParticle(id: 0, trailingOffset: 0.04, xDrift: -0.02, yDrift: -0.08, size: 0.030, twinkle: 0.30, tint: .white),
        SparkleParticle(id: 1, trailingOffset: 0.09, xDrift: -0.04, yDrift: 0.04, size: 0.018, twinkle: 0.78, tint: .cyan),
        SparkleParticle(id: 2, trailingOffset: 0.15, xDrift: -0.07, yDrift: 0.10, size: 0.024, twinkle: 0.52, tint: .green),
        SparkleParticle(id: 3, trailingOffset: 0.21, xDrift: -0.09, yDrift: -0.13, size: 0.014, twinkle: 0.92, tint: .white),
        SparkleParticle(id: 4, trailingOffset: 0.27, xDrift: -0.12, yDrift: 0.16, size: 0.020, twinkle: 0.46, tint: .cyan),
        SparkleParticle(id: 5, trailingOffset: 0.34, xDrift: -0.15, yDrift: -0.03, size: 0.012, twinkle: 0.82, tint: .green),
        SparkleParticle(id: 6, trailingOffset: 0.41, xDrift: -0.17, yDrift: 0.20, size: 0.016, twinkle: 0.64, tint: .white)
    ]
}

private struct MagicWaveShape: Shape {
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        MagicWavePath.path(in: rect).trimmedPath(from: 0, to: max(0, min(progress, 1)))
    }
}

private enum MagicWavePath {
    static func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX - rect.width * 0.08, y: rect.maxY - rect.height * 0.22))
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.44, y: rect.midY - rect.height * 0.02),
            control1: CGPoint(x: rect.minX + rect.width * 0.06, y: rect.maxY - rect.height * 0.58),
            control2: CGPoint(x: rect.minX + rect.width * 0.31, y: rect.maxY - rect.height * 0.02)
        )
        path.addCurve(
            to: CGPoint(x: rect.maxX + rect.width * 0.10, y: rect.minY + rect.height * 0.16),
            control1: CGPoint(x: rect.minX + rect.width * 0.63, y: rect.minY + rect.height * 0.02),
            control2: CGPoint(x: rect.minX + rect.width * 0.84, y: rect.minY + rect.height * 0.42)
        )
        return path
    }

    static func point(at progress: CGFloat, in size: CGSize) -> CGPoint {
        let rect = CGRect(origin: .zero, size: size)
        let clamped = max(0, min(progress, 1))
        let samples = 80
        let index = Int(round(clamped * CGFloat(samples)))
        let step = 1 / CGFloat(samples)
        var current = CGPoint.zero

        for sample in 0...index {
            current = cubicPoint(at: CGFloat(sample) * step, in: rect)
        }

        return current
    }

    private static func cubicPoint(at t: CGFloat, in rect: CGRect) -> CGPoint {
        if t <= 0.5 {
            return firstCurvePoint(at: t * 2, in: rect)
        }

        return secondCurvePoint(at: (t - 0.5) * 2, in: rect)
    }

    private static func firstCurvePoint(at t: CGFloat, in rect: CGRect) -> CGPoint {
        bezierPoint(
            t: t,
            p0: CGPoint(x: rect.minX - rect.width * 0.08, y: rect.maxY - rect.height * 0.22),
            p1: CGPoint(x: rect.minX + rect.width * 0.06, y: rect.maxY - rect.height * 0.58),
            p2: CGPoint(x: rect.minX + rect.width * 0.31, y: rect.maxY - rect.height * 0.02),
            p3: CGPoint(x: rect.minX + rect.width * 0.44, y: rect.midY - rect.height * 0.02)
        )
    }

    private static func secondCurvePoint(at t: CGFloat, in rect: CGRect) -> CGPoint {
        bezierPoint(
            t: t,
            p0: CGPoint(x: rect.minX + rect.width * 0.44, y: rect.midY - rect.height * 0.02),
            p1: CGPoint(x: rect.minX + rect.width * 0.63, y: rect.minY + rect.height * 0.02),
            p2: CGPoint(x: rect.minX + rect.width * 0.84, y: rect.minY + rect.height * 0.42),
            p3: CGPoint(x: rect.maxX + rect.width * 0.10, y: rect.minY + rect.height * 0.16)
        )
    }

    private static func bezierPoint(t: CGFloat, p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint) -> CGPoint {
        let oneMinusT = 1 - t
        let a = oneMinusT * oneMinusT * oneMinusT
        let b = 3 * oneMinusT * oneMinusT * t
        let c = 3 * oneMinusT * t * t
        let d = t * t * t

        return CGPoint(
            x: a * p0.x + b * p1.x + c * p2.x + d * p3.x,
            y: a * p0.y + b * p1.y + c * p2.y + d * p3.y
        )
    }
}
