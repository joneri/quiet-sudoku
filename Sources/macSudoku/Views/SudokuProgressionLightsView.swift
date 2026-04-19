import SwiftUI

struct SudokuProgressionLightsView: View {
    let progression: SudokuProgression

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let cell = side / 9

            ZStack {
                rowLights(cell: cell, side: side)
                columnLights(cell: cell, side: side)
                blockGlows(cell: cell)
            }
            .frame(width: side, height: side)
        }
        .allowsHitTesting(false)
    }

    private func rowLights(cell: CGFloat, side: CGFloat) -> some View {
        ZStack {
            ForEach(0..<9, id: \.self) { row in
                if progression.completedRows.contains(row) {
                    rowLight(for: row, cell: cell, side: side)
                }
            }
        }
    }

    private func rowLight(for row: Int, cell: CGFloat, side: CGFloat) -> some View {
        let y = cell * CGFloat(row) + cell / 2

        return ZStack {
            Capsule()
                .fill(Color.green.opacity(0.82))
                .frame(width: 5, height: max(cell * 0.46, 12))
                .position(x: 3, y: y)

            Capsule()
                .fill(Color.green.opacity(0.82))
                .frame(width: 5, height: max(cell * 0.46, 12))
                .position(x: side - 3, y: y)
        }
        .shadow(color: Color.green.opacity(0.65), radius: 9)
    }

    private func columnLights(cell: CGFloat, side: CGFloat) -> some View {
        ZStack {
            ForEach(0..<9, id: \.self) { column in
                if progression.completedColumns.contains(column) {
                    columnLight(for: column, cell: cell, side: side)
                }
            }
        }
    }

    private func columnLight(for column: Int, cell: CGFloat, side: CGFloat) -> some View {
        let x = cell * CGFloat(column) + cell / 2

        return ZStack {
            Capsule()
                .fill(Color.green.opacity(0.82))
                .frame(width: max(cell * 0.46, 12), height: 5)
                .position(x: x, y: 3)

            Capsule()
                .fill(Color.green.opacity(0.82))
                .frame(width: max(cell * 0.46, 12), height: 5)
                .position(x: x, y: side - 3)
        }
        .shadow(color: Color.green.opacity(0.65), radius: 9)
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
