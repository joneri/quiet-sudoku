import Foundation

enum UITestProbe {
    private static let statePathKey = "MACSUDOKU_UI_STATE_PATH"

    static var isEnabled: Bool {
        statePath != nil
    }

    static func record(game: SudokuGame, selectedCellID: SudokuGame.Cell.ID?, boardSize: BoardSize) {
        guard let statePath else { return }

        let selected: [String: Any]
        if let selectedCellID {
            selected = [
                "id": selectedCellID,
                "row": selectedCellID / 9,
                "column": selectedCellID % 9
            ]
        } else {
            selected = [
                "id": NSNull(),
                "row": NSNull(),
                "column": NSNull()
            ]
        }

        let cells = game.cells.map { cell -> [String: Any] in
            [
                "row": cell.row,
                "column": cell.column,
                "given": cell.given ?? NSNull(),
                "value": cell.value ?? NSNull(),
                "displayValue": cell.displayValue ?? NSNull()
            ]
        }

        let payload: [String: Any] = [
            "selected": selected,
            "boardSize": boardSize.rawValue,
            "isComplete": game.isComplete,
            "cells": cells
        ]

        do {
            let data = try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
            try data.write(to: URL(fileURLWithPath: statePath), options: [.atomic])
        } catch {
            fputs("macSudoku UI test probe failed: \(error)\n", stderr)
        }
    }

    private static var statePath: String? {
        ProcessInfo.processInfo.environment[statePathKey]
    }
}
