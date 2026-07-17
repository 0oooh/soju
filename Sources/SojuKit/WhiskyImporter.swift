import Foundation

public struct WhiskyBottle: Identifiable, Hashable, Sendable {
    public let url: URL     // the Whisky bottle directory (which is itself a wine prefix)
    public let name: String

    public var id: String { url.path }
}

public enum WhiskyImporter {
    static var whiskyBottlesDir: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Containers/com.isaacmarovitz.Whisky/Bottles", isDirectory: true)
    }

    /// Old Whisky bottles found on this machine.
    public static func detect() -> [WhiskyBottle] {
        let fm = FileManager.default
        guard let dirs = try? fm.contentsOfDirectory(
            at: whiskyBottlesDir, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]
        ) else { return [] }

        return dirs.compactMap { dir in
            guard fm.fileExists(atPath: dir.appendingPathComponent("drive_c").path) else { return nil }
            return WhiskyBottle(url: dir, name: metadataName(of: dir) ?? dir.lastPathComponent)
        }
    }

    static func metadataName(of dir: URL) -> String? {
        guard let data = try? Data(contentsOf: dir.appendingPathComponent("Metadata.plist")),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil)
        else { return nil }
        // Whisky's metadata is a nested struct; find a "name" string wherever it sits.
        return findName(in: plist)
    }

    private static func findName(in value: Any) -> String? {
        if let dict = value as? [String: Any] {
            for key in ["name", "Name"] where dict[key] is String {
                return dict[key] as? String
            }
            for child in dict.values {
                if let found = findName(in: child) { return found }
            }
        }
        return nil
    }

    /// Copy a Whisky bottle into a new Soju bottle. Slow for big prefixes;
    /// callers run it off the main thread and show progress.
    public static func importBottle(_ whisky: WhiskyBottle) throws -> Bottle {
        var bottle = try BottleStore.create(name: whisky.name)
        try FileManager.default.copyItem(at: whisky.url, to: bottle.prefixURL)
        // The copy brought Whisky's metadata along; it is harmless but not ours.
        try? FileManager.default.removeItem(at: bottle.prefixURL.appendingPathComponent("Metadata.plist"))
        bottle.meta.name = whisky.name
        try BottleStore.save(bottle)
        return bottle
    }
}
