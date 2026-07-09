import Foundation

/// JSON save file in ~/Library/Application Support/CloutEmpire/save.json.
enum Persistence {
    static var saveURL: URL {
        let dir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CloutEmpire", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("save.json")
    }

    static func load() -> GameState? {
        guard let data = try? Data(contentsOf: saveURL),
              var state = try? JSONDecoder().decode(GameState.self, from: data) else { return nil }
        // If the hustle list grew since this save, pad with fresh entries.
        while state.hustles.count < Hustle.all.count {
            state.hustles.append(HustleState())
        }
        return state
    }

    static func save(_ state: GameState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        try? data.write(to: saveURL, options: .atomic)
    }
}
