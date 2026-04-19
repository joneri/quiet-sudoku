import SwiftUI

struct SudokuBoardEdgeCompletionLightsView: View {
    let progression: SudokuProgression
    let boardSide: CGFloat
    let topInset: CGFloat

    private var cellSide: CGFloat {
        boardSide / 9
    }

    private var windowHeight: CGFloat {
        topInset + boardSide
    }

    var body: some View {
        ZStack {
            rowEdgeLights
            columnEdgeLights
        }
        .frame(width: boardSide, height: windowHeight)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var rowEdgeLights: some View {
        ZStack {
            ForEach(0..<9, id: \.self) { row in
                if progression.completedRows.contains(row) {
                    horizontalEndLights(for: row)
                }
            }
        }
    }

    private func horizontalEndLights(for row: Int) -> some View {
        let y = topInset + cellSide * CGFloat(row) + cellSide / 2

        return ZStack {
            edgeLamp
                .frame(width: 7, height: max(cellSide * 0.52, 16))
                .position(x: 5, y: y)

            edgeLamp
                .frame(width: 7, height: max(cellSide * 0.52, 16))
                .position(x: boardSide - 5, y: y)
        }
    }

    private var columnEdgeLights: some View {
        ZStack {
            ForEach(0..<9, id: \.self) { column in
                if progression.completedColumns.contains(column) {
                    verticalEndLights(for: column)
                }
            }
        }
    }

    private func verticalEndLights(for column: Int) -> some View {
        let x = cellSide * CGFloat(column) + cellSide / 2

        return ZStack {
            edgeLamp
                .frame(width: max(cellSide * 0.52, 16), height: 7)
                .position(x: x, y: 5)

            edgeLamp
                .frame(width: max(cellSide * 0.52, 16), height: 7)
                .position(x: x, y: windowHeight - 5)
        }
    }

    private var edgeLamp: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.92),
                        Color.green.opacity(0.88),
                        Color.cyan.opacity(0.38)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(color: Color.green.opacity(0.78), radius: 10)
            .shadow(color: Color.cyan.opacity(0.36), radius: 16)
            .overlay {
                Capsule()
                    .strokeBorder(Color.white.opacity(0.45), lineWidth: 1)
            }
    }
}

extension SudokuBoardEdgeCompletionLightsView {
    struct Endpoint: Equatable {
        let axis: Axis
        let index: Int
        let first: CGPoint
        let second: CGPoint

        enum Axis: String {
            case row
            case column
        }
    }

    var endpoints: [Endpoint] {
        rowEndpoints + columnEndpoints
    }

    private var rowEndpoints: [Endpoint] {
        progression.completedRows.sorted().map { row in
            let y = topInset + cellSide * CGFloat(row) + cellSide / 2
            return Endpoint(
                axis: .row,
                index: row,
                first: CGPoint(x: 5, y: y),
                second: CGPoint(x: boardSide - 5, y: y)
            )
        }
    }

    private var columnEndpoints: [Endpoint] {
        progression.completedColumns.sorted().map { column in
            let x = cellSide * CGFloat(column) + cellSide / 2
            return Endpoint(
                axis: .column,
                index: column,
                first: CGPoint(x: x, y: 5),
                second: CGPoint(x: x, y: windowHeight - 5)
            )
        }
    }
}
