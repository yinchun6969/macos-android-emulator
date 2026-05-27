import Foundation

public enum MacroStepKind: String, Sendable, Hashable, Codable {
    case tap
    case swipe
    case wait
}

public struct MacroStep: Identifiable, Sendable, Hashable, Codable {
    public var id: UUID
    public var kind: MacroStepKind
    public var x: Int
    public var y: Int
    public var x2: Int?
    public var y2: Int?
    public var durationMS: Int
    public var delayAfterMS: Int

    public init(
        id: UUID = UUID(),
        kind: MacroStepKind,
        x: Int = 0,
        y: Int = 0,
        x2: Int? = nil,
        y2: Int? = nil,
        durationMS: Int = 80,
        delayAfterMS: Int = 250
    ) {
        self.id = id
        self.kind = kind
        self.x = x
        self.y = y
        self.x2 = x2
        self.y2 = y2
        self.durationMS = durationMS
        self.delayAfterMS = delayAfterMS
    }
}

public struct MacroScript: Identifiable, Sendable, Hashable, Codable {
    public var id: UUID
    public var name: String
    public var targetPackage: String
    public var baseWidth: Int
    public var baseHeight: Int
    public var steps: [MacroStep]
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        targetPackage: String = "",
        baseWidth: Int,
        baseHeight: Int,
        steps: [MacroStep] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.targetPackage = targetPackage
        self.baseWidth = baseWidth
        self.baseHeight = baseHeight
        self.steps = steps
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public enum MacroScriptStore {
    public static func list() throws -> [MacroScript] {
        try StorageLayout.ensureInstanceDirectories()
        let directory = StorageLayout.macroDirectory()
        let urls = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        .filter { $0.pathExtension == "json" }

        return urls.compactMap { try? read(from: $0) }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    public static func read(from url: URL) throws -> MacroScript {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(MacroScript.self, from: data)
    }

    @discardableResult
    public static func write(_ script: MacroScript) throws -> URL {
        try StorageLayout.ensureInstanceDirectories()
        let directory = StorageLayout.macroDirectory()
        let url = directory.appendingPathComponent(fileName(for: script)).appendingPathExtension("json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(script)
        try data.write(to: url, options: [.atomic])
        return url
    }

    public static func delete(_ script: MacroScript) throws {
        let url = StorageLayout.macroDirectory().appendingPathComponent(fileName(for: script)).appendingPathExtension("json")
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }

    private static func fileName(for script: MacroScript) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_-"))
        let normalized = script.name.unicodeScalars.map { allowed.contains($0) ? Character($0) : "_" }
        let name = String(normalized).trimmingCharacters(in: CharacterSet(charactersIn: "_"))
        return "\(name.isEmpty ? "macro" : name)_\(script.id.uuidString)"
    }
}
