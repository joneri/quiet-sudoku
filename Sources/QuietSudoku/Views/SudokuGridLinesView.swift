import SwiftUI

struct SudokuGridLinesView: View {
    var body: some View {
        GeometryReader { proxy in
            thinLines(in: proxy.size)
                .stroke(Color.primary.opacity(0.22), lineWidth: 1)

            blockLines(in: proxy.size)
                .stroke(Color.primary.opacity(0.62), lineWidth: 2.5)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.white.opacity(0.20), lineWidth: 1)
                .blendMode(.plusLighter)
        }
        .allowsHitTesting(false)
    }

    private func thinLines(in size: CGSize) -> Path {
        Path { path in
            let cell = size.width / 9

            for index in 1..<9 {
                let position = CGFloat(index) * cell
                path.move(to: CGPoint(x: position, y: 0))
                path.addLine(to: CGPoint(x: position, y: size.height))
                path.move(to: CGPoint(x: 0, y: position))
                path.addLine(to: CGPoint(x: size.width, y: position))
            }
        }
    }

    private func blockLines(in size: CGSize) -> Path {
        Path { path in
            let block = size.width / 3

            for index in 1..<3 {
                let position = CGFloat(index) * block
                path.move(to: CGPoint(x: position, y: 0))
                path.addLine(to: CGPoint(x: position, y: size.height))
                path.move(to: CGPoint(x: 0, y: position))
                path.addLine(to: CGPoint(x: size.width, y: position))
            }
        }
    }
}

