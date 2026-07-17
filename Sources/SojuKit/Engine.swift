import Foundation

public struct Engine: Identifiable, Hashable, Sendable {
    public enum Source: String, Sendable {
        case downloaded   // installed by Soju under SojuPaths.engines
        case detected     // found elsewhere on the system
    }

    public let name: String
    public let wineBin: URL
    public let source: Source

    public var id: String { wineBin.path }

    public init(name: String, wineBin: URL, source: Source) {
        self.name = name
        self.wineBin = wineBin
        self.source = source
    }
}

public enum EngineStore {
    /// All usable engines, Soju-installed first.
    public static func discover() -> [Engine] {
        downloadedEngines() + detectedEngines()
    }

    static func downloadedEngines() -> [Engine] {
        let fm = FileManager.default
        guard let dirs = try? fm.contentsOfDirectory(
            at: SojuPaths.engines, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]
        ) else { return [] }

        return dirs.compactMap { dir in
            guard let bin = findWineBin(under: dir) else { return nil }
            return Engine(name: dir.lastPathComponent, wineBin: bin, source: .downloaded)
        }
        .sorted { $0.name.localizedStandardCompare($1.name) == .orderedDescending }
    }

    static func detectedEngines() -> [Engine] {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        // Known layouts only; a filesystem-wide hunt is not worth the startup cost.
        let candidates: [(name: String, path: String)] = [
            ("Wine Staging", "/Applications/Wine Staging.app/Contents/Resources/wine/bin"),
            ("Wine Devel", "/Applications/Wine Devel.app/Contents/Resources/wine/bin"),
            ("Wine Stable", "/Applications/Wine Stable.app/Contents/Resources/wine/bin"),
            ("CrossOver", "/Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin"),
            ("WhiskyWine", "\(home)/Library/Application Support/com.isaacmarovitz.Whisky/Libraries/Wine/bin"),
        ]

        return candidates.compactMap { candidate in
            let bin = URL(fileURLWithPath: candidate.path)
            for exe in ["wine64", "wine"] {
                let url = bin.appendingPathComponent(exe)
                if FileManager.default.isExecutableFile(atPath: url.path) {
                    return Engine(name: candidate.name, wineBin: url, source: .detected)
                }
            }
            return nil
        }
    }

    /// Locate wine inside an extracted engine directory (layout varies by build).
    static func findWineBin(under root: URL) -> URL? {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(
            at: root, includingPropertiesForKeys: [.isExecutableKey], options: [.skipsHiddenFiles]
        ) else { return nil }

        var fallback: URL?
        for case let url as URL in enumerator {
            let path = url.path
            if path.hasSuffix("/bin/wine64") { return url }
            if path.hasSuffix("/bin/wine") { fallback = fallback ?? url }
        }
        return fallback
    }
}
