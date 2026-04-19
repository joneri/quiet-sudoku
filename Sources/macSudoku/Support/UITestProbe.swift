import Foundation

enum UITestProbe {
    private static let statePathKey = "MACSUDOKU_UI_STATE_PATH"

    static var isEnabled: Bool {
        statePath != nil
    }

    static func record(snapshot: SudokuSessionSnapshot, isConfirmingNewBoard: Bool) {
        guard let statePath else { return }

        let selected: [String: Any]
        if let selectedCellID = snapshot.selectedCellID {
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

        let cells = snapshot.puzzle.puzzle.enumerated().flatMap { row, puzzleRow in
            puzzleRow.enumerated().map { column, given -> [String: Any] in
                let index = row * 9 + column
                let value = snapshot.values[index]
                let displayValue: Any = given == 0 ? (value.map { $0 as Any } ?? NSNull()) : given

                return [
                    "row": row,
                    "column": column,
                    "given": given == 0 ? NSNull() : given,
                    "value": value ?? NSNull(),
                    "displayValue": displayValue
                ]
            }
        }

        let payload: [String: Any] = [
            "selected": selected,
            "boardSize": snapshot.boardSize.rawValue,
            "completedBlocks": Array(snapshot.progression.completedBlocks).sorted(),
            "completedDigits": Array(snapshot.progression.completedDigits).sorted(),
            "isConfirmingNewBoard": isConfirmingNewBoard,
            "puzzleSignature": snapshot.puzzle.puzzle.flatMap { $0 }.map(String.init).joined(separator: ","),
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
