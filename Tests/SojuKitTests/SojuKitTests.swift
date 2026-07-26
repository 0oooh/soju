import XCTest
@testable import SojuKit

final class SojuKitTests: XCTestCase {
    func testBottleMetaRoundtrip() throws {
        var meta = BottleMeta(name: "Games")
        meta.pins.append(Pin(name: "Notepad", exePath: "/tmp/prefix/drive_c/windows/notepad.exe"))
        let data = try JSONEncoder().encode(meta)
        let decoded = try JSONDecoder().decode(BottleMeta.self, from: data)
        XCTAssertEqual(decoded, meta)
    }

    func testShellQuoting() {
        XCTAssertEqual(AppExporter.quoted("/plain/path"), "'/plain/path'")
        XCTAssertEqual(AppExporter.quoted("/it's here"), "'/it'\\''s here'")
    }

    func testSanitizedAppName() {
        XCTAssertEqual(AppExporter.sanitized("Half-Life 2"), "Half-Life 2")
        XCTAssertEqual(AppExporter.sanitized("a/b:c"), "a-b-c")
        XCTAssertEqual(AppExporter.sanitized("   "), "Windows App")
    }

    /// macOS kills the wine process outright when a Windows program opens the mic
    /// or camera and the responsible bundle has no usage description, so every
    /// wrapper we generate must declare them.
    func testExportedWrapperDeclaresCaptureUsage() throws {
        let temp = FileManager.default.temporaryDirectory
            .appendingPathComponent("soju-export-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temp) }

        let bottle = Bottle(url: temp.appendingPathComponent("bottle"), meta: BottleMeta(name: "Test"))
        let engine = Engine(name: "Test", wineBin: URL(fileURLWithPath: "/usr/bin/true"), source: .detected)
        let pin = Pin(name: "Voice Chat Game", exePath: "/tmp/game.exe")

        let app = try AppExporter.export(pin: pin, bottle: bottle, engine: engine, to: temp)
        let data = try Data(contentsOf: app.appendingPathComponent("Contents/Info.plist"))
        let plist = try XCTUnwrap(
            PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        )
        XCTAssertNotNil(plist["NSMicrophoneUsageDescription"])
        XCTAssertNotNil(plist["NSCameraUsageDescription"])
    }

    func testPEIconRejectsGarbage() {
        let garbage = Data(repeating: 0x41, count: 4096)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("garbage.exe")
        try? garbage.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        XCTAssertNil(PEIcon.extractICO(from: url))
    }

    /// If a real PE executable ships with an installed wine build, the parser
    /// must at least not crash on it (icon presence varies by build).
    func testPEParserOnWineBinariesIfPresent() {
        let candidates = [
            "/Applications/Wine Staging.app/Contents/Resources/wine/lib/wine/x86_64-windows/notepad.exe",
            "/Applications/Wine Staging.app/Contents/Resources/wine/lib64/wine/x86_64-windows/notepad.exe",
        ]
        for path in candidates where FileManager.default.fileExists(atPath: path) {
            _ = PEIcon.extractICO(from: URL(fileURLWithPath: path))
        }
    }
}
