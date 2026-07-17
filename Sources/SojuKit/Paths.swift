import Foundation

public enum SojuPaths {
    public static let appSupport = FileManager.default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("Soju", isDirectory: true)

    public static let engines = appSupport.appendingPathComponent("Engines", isDirectory: true)
    public static let bottles = appSupport.appendingPathComponent("Bottles", isDirectory: true)

    public static let logs = FileManager.default
        .urls(for: .libraryDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("Logs/Soju", isDirectory: true)

    public static func ensure() throws {
        for dir in [engines, bottles, logs] {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }
}
