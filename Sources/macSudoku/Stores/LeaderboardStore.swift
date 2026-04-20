import Foundation

struct LeaderboardStore {
    private let fileURL: URL
    private let limit: Int

    init(fileURL: URL = Self.defaultFileURL(), limit: Int = 15) {
        self.fileURL = fileURL
        self.limit = limit
    }

    func load() -> [LeaderboardEntry] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        let entries = (try? JSONDecoder().decode([LeaderboardEntry].self, from: data)) ?? []
        return sorted(entries)
    }

    func save(_ entries: [LeaderboardEntry]) {
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(sorted(entries))
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            fputs("macSudoku failed to save leaderboard: \(error)\n", stderr)
        }
    }

    func adding(_ entry: LeaderboardEntry, to entries: [LeaderboardEntry]) -> [LeaderboardEntry] {
        sorted(entries + [entry])
    }

    func upserting(_ entry: LeaderboardEntry, in entries: [LeaderboardEntry]) -> [LeaderboardEntry] {
        var bestEntries = entries.filter { $0.initials != entry.initials }
        if let existing = entries.filter({ $0.initials == entry.initials }).max(by: { $0.levelsCompleted < $1.levelsCompleted }),
           existing.levelsCompleted >= entry.levelsCompleted {
            bestEntries.append(existing)
        } else {
            bestEntries.append(entry)
        }

        return sorted(bestEntries)
    }

    func qualifies(levelsCompleted: Int, against entries: [LeaderboardEntry]) -> Bool {
        guard levelsCompleted > 0 else { return false }
        let sortedEntries = sorted(entries)
        guard sortedEntries.count >= limit, let lowest = sortedEntries.last else {
            return true
        }

        return levelsCompleted > lowest.levelsCompleted
    }

    private func sorted(_ entries: [LeaderboardEntry]) -> [LeaderboardEntry] {
        Array(
            entries.sorted { lhs, rhs in
                if lhs.levelsCompleted == rhs.levelsCompleted {
                    return lhs.achievedAt < rhs.achievedAt
                }

                return lhs.levelsCompleted > rhs.levelsCompleted
            }
            .prefix(limit)
        )
    }

    static func defaultFileURL() -> URL {
        if let override = ProcessInfo.processInfo.environment["MACSUDOKU_LEADERBOARD_PATH"], !override.isEmpty {
            return URL(fileURLWithPath: override)
        }

        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return baseURL
            .appendingPathComponent("macSudoku", isDirectory: true)
            .appendingPathComponent("leaderboard.json", isDirectory: false)
    }
}
