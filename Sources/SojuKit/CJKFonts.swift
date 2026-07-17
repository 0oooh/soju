import Foundation

/// Korean text in fresh Wine prefixes renders as boxes because no CJK font is
/// installed. This installs Noto Sans CJK KR (SIL Open Font License, so freely
/// redistributable) into a bottle and maps the common Korean Windows font
/// names onto it.
public enum CJKFonts {
    static let notoKR = URL(string: "https://github.com/notofonts/noto-cjk/raw/main/Sans/OTF/Korean/NotoSansCJKkr-Regular.otf")!
    static let familyName = "Noto Sans CJK KR"
    static let fileName = "NotoSansCJKkr-Regular.otf"

    public static var cacheURL: URL {
        SojuPaths.appSupport.appendingPathComponent("Fonts/\(fileName)")
    }

    public static func isInstalled(in bottle: Bottle) -> Bool {
        FileManager.default.fileExists(
            atPath: bottle.driveC.appendingPathComponent("windows/Fonts/\(fileName)").path
        )
    }

    /// Download the font once into Soju's cache; every bottle reuses it.
    static func ensureCached() async throws -> URL {
        if FileManager.default.fileExists(atPath: cacheURL.path) { return cacheURL }
        try FileManager.default.createDirectory(
            at: cacheURL.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        let (temp, response) = try await URLSession.shared.download(from: notoKR)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        try? FileManager.default.removeItem(at: cacheURL)
        try FileManager.default.moveItem(at: temp, to: cacheURL)
        return cacheURL
    }

    public static func install(into bottle: Bottle, engine: Engine) async throws {
        let font = try await ensureCached()

        let fontsDir = bottle.driveC.appendingPathComponent("windows/Fonts", isDirectory: true)
        try FileManager.default.createDirectory(at: fontsDir, withIntermediateDirectories: true)
        let dest = fontsDir.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: dest)
        try FileManager.default.copyItem(at: font, to: dest)

        // Map the Korean font names Windows programs actually ask for.
        let substitutes = [
            "맑은 고딕", "Malgun Gothic", "굴림", "Gulim", "굴림체", "GulimChe",
            "돋움", "Dotum", "돋움체", "DotumChe", "바탕", "Batang", "궁서", "Gungsuh",
        ]
        var reg = "Windows Registry Editor Version 5.00\r\n\r\n"
        reg += "[HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows NT\\CurrentVersion\\FontSubstitutes]\r\n"
        for name in substitutes {
            reg += "\"\(name)\"=\"\(familyName)\"\r\n"
        }

        // regedit needs UTF-16LE with a BOM to accept non-ASCII value names.
        var data = Data([0xFF, 0xFE])
        data.append(reg.data(using: .utf16LittleEndian)!)
        let regFile = bottle.url.appendingPathComponent("korean-fonts.reg")
        try data.write(to: regFile)
        defer { try? FileManager.default.removeItem(at: regFile) }

        try await WineRunner.runAndWait(args: ["regedit", "/S", regFile.path], engine: engine, bottle: bottle)
    }
}
