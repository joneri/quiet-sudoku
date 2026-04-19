import Foundation

struct SudokuLevel: Codable, Equatable, Comparable {
    let number: Int

    init(_ number: Int) {
        self.number = max(1, number)
    }

    var completedCountBeforeLevel: Int {
        number - 1
    }

    var filledCellCount: Int {
        max(26, 44 - completedCountBeforeLevel * 3)
    }

    var displayTitle: String {
        "Level \(number)"
    }

    var compactTitle: String {
        "L\(number)"
    }

    func next() -> SudokuLevel {
        SudokuLevel(number + 1)
    }

    static func < (lhs: SudokuLevel, rhs: SudokuLevel) -> Bool {
        lhs.number < rhs.number
    }
}
