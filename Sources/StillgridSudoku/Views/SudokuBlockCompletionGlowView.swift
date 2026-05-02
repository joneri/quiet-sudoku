import SwiftUI

struct SudokuBlockCompletionGlowView: View {
    let progression: SudokuProgression

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let cell = side / 9

            blockGlows(cell: cell)
                .frame(width: side, height: side)
        }
        .allowsHitTesting(false)
    }

    private func blockGlows(cell: CGFloat) -> some View {
        ZStack {
            ForEach(0..<9, id: \.self) { block in
                if progression.completedBlocks.contains(block) {
                    blockGlow(for: block, cell: cell)
                }
            }
        }
    }

    private func blockGlow(for block: Int, cell: CGFloat) -> some View {
        let blockSide = cell * 3
        let row = CGFloat(block / 3)
        let column = CGFloat(block % 3)

        return RoundedRectangle(cornerRadius: 8, style: .continuous)
            .stroke(Color.green.opacity(0.60), lineWidth: 3)
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.green.opacity(0.10))
            }
            .shadow(color: Color.green.opacity(0.40), radius: 16)
            .frame(width: blockSide, height: blockSide)
            .position(
                x: column * blockSide + blockSide / 2,
                y: row * blockSide + blockSide / 2
            )
    }
}
