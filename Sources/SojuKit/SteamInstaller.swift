import Foundation

public enum SteamInstaller {
    /// Valve's official installer CDN — the same file steampowered.com serves.
    static let installerURL = URL(string: "https://cdn.cloudflare.steamstatic.com/client/installer/SteamSetup.exe")!

    public static func steamExe(in bottle: Bottle) -> URL? {
        for path in ["Program Files (x86)/Steam/steam.exe", "Program Files/Steam/steam.exe"] {
            let url = bottle.driveC.appendingPathComponent(path)
            if FileManager.default.fileExists(atPath: url.path) { return url }
        }
        return nil
    }

    /// Download the official installer and launch it in the bottle. The user
    /// completes Valve's own setup wizard from there.
    @discardableResult
    public static func run(engine: Engine, bottle: Bottle) async throws -> Process {
        let (temp, response) = try await URLSession.shared.download(from: installerURL)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let downloads = bottle.driveC.appendingPathComponent("users/Public/Downloads", isDirectory: true)
        try FileManager.default.createDirectory(at: downloads, withIntermediateDirectories: true)
        let dest = downloads.appendingPathComponent("SteamSetup.exe")
        try? FileManager.default.removeItem(at: dest)
        try FileManager.default.moveItem(at: temp, to: dest)
        return try WineRunner.launch(exe: dest, engine: engine, bottle: bottle)
    }
}
