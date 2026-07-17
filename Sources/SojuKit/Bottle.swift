import Foundation

public struct Pin: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var exePath: String   // absolute unix path inside the prefix

    public init(name: String, exePath: String) {
        self.id = UUID()
        self.name = name
        self.exePath = exePath
    }
}

public struct BottleMeta: Codable, Hashable, Sendable {
    public var name: String
    public var created: Date
    public var enginePath: String?   // last engine used; nil = pick current default
    public var pins: [Pin]

    public init(name: String, created: Date = .now, enginePath: String? = nil, pins: [Pin] = []) {
        self.name = name
        self.created = created
        self.enginePath = enginePath
        self.pins = pins
    }
}

public struct Bottle: Identifiable, Hashable, Sendable {
    public let url: URL          // Bottles/<uuid>/
    public var meta: BottleMeta

    public var id: String { url.lastPathComponent }
    public var prefixURL: URL { url.appendingPathComponent("prefix", isDirectory: true) }
    public var driveC: URL { prefixURL.appendingPathComponent("drive_c", isDirectory: true) }

    public init(url: URL, meta: BottleMeta) {
        self.url = url
        self.meta = meta
    }
}

public enum BottleStore {
    static let metaFilename = "metadata.json"

    public static func load() -> [Bottle] {
        let fm = FileManager.default
        guard let dirs = try? fm.contentsOfDirectory(
            at: SojuPaths.bottles, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]
        ) else { return [] }

        return dirs.compactMap { dir in
            guard let data = try? Data(contentsOf: dir.appendingPathComponent(metaFilename)),
                  let meta = try? JSONDecoder().decode(BottleMeta.self, from: data)
            else { return nil }
            return Bottle(url: dir, meta: meta)
        }
        .sorted { $0.meta.created < $1.meta.created }
    }

    /// Creates the bottle directory and metadata. The wine prefix itself is
    /// initialized separately by WineRunner.initPrefix (slow, needs an engine).
    public static func create(name: String) throws -> Bottle {
        try SojuPaths.ensure()
        let dir = SojuPaths.bottles.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let bottle = Bottle(url: dir, meta: BottleMeta(name: name))
        try save(bottle)
        return bottle
    }

    public static func save(_ bottle: Bottle) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(bottle.meta)
        try data.write(to: bottle.url.appendingPathComponent(metaFilename))
    }

    public static func delete(_ bottle: Bottle) throws {
        try FileManager.default.removeItem(at: bottle.url)
    }

    /// Installed Windows programs, for the pin picker. Shallow scan of the
    /// usual install roots; system and uninstaller executables are skipped.
    public static func installedPrograms(in bottle: Bottle) -> [URL] {
        let fm = FileManager.default
        let roots = [
            bottle.driveC.appendingPathComponent("Program Files", isDirectory: true),
            bottle.driveC.appendingPathComponent("Program Files (x86)", isDirectory: true),
            bottle.driveC.appendingPathComponent("users", isDirectory: true),
        ]
        let skip = ["unins", "uninstall", "setup", "vcredist", "dxsetup", "crashpad", "redist"]

        var found: [URL] = []
        for root in roots {
            guard let enumerator = fm.enumerator(
                at: root, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]
            ) else { continue }
            for case let url as URL in enumerator {
                if enumerator.level > 4 { enumerator.skipDescendants(); continue }
                guard url.pathExtension.lowercased() == "exe" else { continue }
                let name = url.lastPathComponent.lowercased()
                if skip.contains(where: { name.contains($0) }) { continue }
                found.append(url)
            }
        }
        return found.sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
    }
}
