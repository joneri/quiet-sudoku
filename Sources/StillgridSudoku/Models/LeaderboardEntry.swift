import Foundation

struct LeaderboardEntry: Codable, Equatable, Identifiable {
    let id: UUID
    let initials: String
    let levelsCompleted: Int
    let achievedAt: Date

    init(
        id: UUID = UUID(),
        initials: String,
        levelsCompleted: Int,
        achievedAt: Date = Date()
    ) {
        self.id = id
        self.initials = Self.normalizedInitials(initials)
        self.levelsCompleted = max(0, levelsCompleted)
        self.achievedAt = achievedAt
    }

    static func normalizedInitials(_ initials: String) -> String {
        String(initials.uppercased().filter { $0.isLetter || $0.isNumber }.prefix(3))
    }
}
