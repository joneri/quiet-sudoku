import Foundation

struct SudokuGamePersistence {
    private let fileURL: URL

    init(fileURL: URL = Self.defaultFileURL()) {
        self.fileURL = fileURL
    }

    func load() -> SudokuSessionSnapshot? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(SudokuSessionSnapshot.self, from: data)
    }

    func save(_ snapshot: SudokuSessionSnapshot) {
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            fputs("macSudoku failed to save game: \(error)\n", stderr)
        }
    }

    static func defaultFileURL() -> URL {
        if let override = ProcessInfo.processInfo.environment["MACSUDOKU_SAVE_PATH"], !override.isEmpty {
            return URL(fileURLWithPath: override)
        }

        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return baseURL
            .appendingPathComponent("macSudoku", isDirectory: true)
            .appendingPathComponent("game.json", isDirectory: false)
    }
}

