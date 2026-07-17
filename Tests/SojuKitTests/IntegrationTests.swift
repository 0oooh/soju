import XCTest
@testable import SojuKit

/// Full-path integration test against a real wine engine on this machine.
/// Opt-in (slow, touches real app data): SOJU_IT=1 swift test --filter Integration
final class IntegrationTests: XCTestCase {
    func testEndToEndBottleLifecycle() async throws {
        guard ProcessInfo.processInfo.environment["SOJU_IT"] == "1" else {
            throw XCTSkip("Set SOJU_IT=1 to run the integration test")
        }

        let engines = EngineStore.discover()
        guard let engine = engines.first else {
            throw XCTSkip("No wine engine on this machine")
        }
        print("IT: engine = \(engine.name) at \(engine.wineBin.path)")

        // Reuse the demo bottle across runs instead of piling up prefixes.
        let bottleName = "Windows"
        var bottle = BottleStore.load().first { $0.meta.name == bottleName }
            ?? { () -> Bottle in
                var created = try! BottleStore.create(name: bottleName)
                created.meta.enginePath = engine.id
                try! BottleStore.save(created)
                return created
            }()

        if !FileManager.default.fileExists(atPath: bottle.driveC.path) {
            print("IT: booting prefix (first run is slow)")
            try await WineRunner.initPrefix(engine: engine, bottle: bottle)
        }
        XCTAssertTrue(FileManager.default.fileExists(atPath: bottle.driveC.path), "drive_c missing after wineboot")

        // A real PE notepad ships inside the prefix with modern wine builds.
        let notepad = bottle.driveC.appendingPathComponent("windows/notepad.exe")
        XCTAssertTrue(FileManager.default.fileExists(atPath: notepad.path), "notepad.exe missing in prefix")

        if !bottle.meta.pins.contains(where: { $0.name == "Notepad" }) {
            bottle.meta.pins.append(Pin(name: "Notepad", exePath: notepad.path))
            try BottleStore.save(bottle)
        }
        let pin = bottle.meta.pins.first { $0.name == "Notepad" }!

        // Launch notepad, give wine a moment, then confirm it is alive.
        let process = try WineRunner.launch(exe: notepad, engine: engine, bottle: bottle)
        try await Task.sleep(for: .seconds(12))
        XCTAssertTrue(process.isRunning || process.terminationStatus == 0,
                      "notepad died: \(WineRunner.logTail(for: bottle))")
        WineRunner.killBottle(engine: engine, bottle: bottle)

        // Icon extraction from the real PE binary.
        let ico = PEIcon.extractICO(from: notepad)
        print("IT: notepad icon extracted = \(ico != nil), bytes = \(ico?.count ?? 0)")

        // Export the wrapper app and verify its structure.
        let exportDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("soju-it-export", isDirectory: true)
        try? FileManager.default.removeItem(at: exportDir)
        try FileManager.default.createDirectory(at: exportDir, withIntermediateDirectories: true)
        let app = try AppExporter.export(pin: pin, bottle: bottle, engine: engine, to: exportDir)

        let launcher = app.appendingPathComponent("Contents/MacOS/launcher")
        XCTAssertTrue(FileManager.default.isExecutableFile(atPath: launcher.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: app.appendingPathComponent("Contents/Info.plist").path))
        print("IT: exported wrapper at \(app.path)")
        print("IT: wrapper icon exists = \(FileManager.default.fileExists(atPath: app.appendingPathComponent("Contents/Resources/AppIcon.icns").path))")
    }

    /// SOJU_IT=1: install the Korean font fix into the demo bottle and verify
    /// both the font file and the registry substitutes landed.
    func testKoreanFontInstall() async throws {
        guard ProcessInfo.processInfo.environment["SOJU_IT"] == "1" else {
            throw XCTSkip("Set SOJU_IT=1 to run the integration test")
        }
        guard let engine = EngineStore.discover().first,
              let bottle = BottleStore.load().first(where: { $0.meta.name == "Windows" })
        else { throw XCTSkip("Demo bottle missing") }

        try await CJKFonts.install(into: bottle, engine: engine)
        XCTAssertTrue(CJKFonts.isInstalled(in: bottle), "font file missing in prefix")
        print("IT: font installed = \(CJKFonts.isInstalled(in: bottle))")
    }

    /// SOJU_IT_GPTK=1: download the Game Porting Toolkit engine flavor and
    /// boot a throwaway bottle with it. Slow (about 240 MB download).
    func testGPTKEngineDownloadAndBoot() async throws {
        guard ProcessInfo.processInfo.environment["SOJU_IT_GPTK"] == "1" else {
            throw XCTSkip("Set SOJU_IT_GPTK=1 to run the GPTK engine test")
        }

        let release = try await EngineDownloader.latestRelease(.gptk)
        print("IT: gptk release = \(release.version), \(release.size / 1_000_000) MB")
        let engine = try await EngineDownloader.install(release) { received, total in
            if received % (50 << 20) < (1 << 16) {
                print("IT: gptk download \(received / 1_000_000)/\(total / 1_000_000) MB")
            }
        }
        print("IT: gptk wine bin = \(engine.wineBin.path)")

        var bottle = try BottleStore.create(name: "GPTK-IT")
        bottle.meta.enginePath = engine.id
        try BottleStore.save(bottle)
        defer { try? BottleStore.delete(bottle) }

        try await WineRunner.initPrefix(engine: engine, bottle: bottle)
        XCTAssertTrue(FileManager.default.fileExists(atPath: bottle.driveC.path), "gptk prefix failed to boot")
        WineRunner.killBottle(engine: engine, bottle: bottle)
        print("IT: gptk prefix booted OK")
    }
}
