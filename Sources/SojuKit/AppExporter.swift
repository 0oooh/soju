import AppKit
import Foundation

public enum AppExporter {
    /// Generate a standalone launcher .app for a pinned Windows program.
    /// The wrapper execs wine directly with paths baked in at export time,
    /// so it works with Soju closed. See docs/decisions/003.
    @discardableResult
    public static func export(pin: Pin, bottle: Bottle, engine: Engine, to destDir: URL) throws -> URL {
        let fm = FileManager.default
        let appName = sanitized(pin.name)
        let bundle = destDir.appendingPathComponent("\(appName).app", isDirectory: true)
        let contents = bundle.appendingPathComponent("Contents", isDirectory: true)
        let macos = contents.appendingPathComponent("MacOS", isDirectory: true)
        let resources = contents.appendingPathComponent("Resources", isDirectory: true)

        try? fm.removeItem(at: bundle)
        try fm.createDirectory(at: macos, withIntermediateDirectories: true)
        try fm.createDirectory(at: resources, withIntermediateDirectories: true)

        let plist: [String: Any] = [
            "CFBundleName": appName,
            "CFBundleDisplayName": pin.name,
            "CFBundleIdentifier": "io.github.0oooh.Soju.wrapper.\(UUID().uuidString)",
            "CFBundleExecutable": "launcher",
            "CFBundleIconFile": "AppIcon",
            "CFBundlePackageType": "APPL",
            "CFBundleShortVersionString": "1.0",
            "LSMinimumSystemVersion": "11.0",
            "NSHighResolutionCapable": true,
            // Without these, macOS kills the wine process the moment the program
            // opens a mic or camera, instead of prompting the user.
            "NSMicrophoneUsageDescription": "\(pin.name) needs this to use your microphone.",
            "NSCameraUsageDescription": "\(pin.name) needs this to use your camera.",
        ]
        let plistData = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        try plistData.write(to: contents.appendingPathComponent("Info.plist"))

        let script = """
        #!/bin/zsh
        WINE=\(quoted(engine.wineBin.path))
        EXE=\(quoted(pin.exePath))
        export WINEPREFIX=\(quoted(bottle.prefixURL.path))
        export WINEDEBUG=fixme-all
        if [[ ! -x "$WINE" || ! -e "$EXE" ]]; then
          /usr/bin/osascript -e 'display alert "\(appName) cannot start" message "Its Soju engine or bottle moved. Open Soju and re-export this app."'
          exit 1
        fi
        cd "$(dirname "$EXE")"
        exec "$WINE" "$EXE"
        """
        let launcher = macos.appendingPathComponent("launcher")
        try script.write(to: launcher, atomically: true, encoding: .utf8)
        try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: launcher.path)

        let icon = PEIcon.image(for: URL(fileURLWithPath: pin.exePath)) ?? fallbackIcon()
        if let icon {
            try? Icns.write(icon, to: resources.appendingPathComponent("AppIcon.icns"))
        }

        let codesign = Process()
        codesign.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        codesign.arguments = ["--force", "-s", "-", bundle.path]
        try? codesign.run()
        codesign.waitUntilExit()

        return bundle
    }

    static func fallbackIcon() -> NSImage? {
        guard let own = Bundle.main.url(forResource: "AppIcon", withExtension: "icns") else { return nil }
        return NSImage(contentsOf: own)
    }

    static func sanitized(_ name: String) -> String {
        let cleaned = name
            .components(separatedBy: CharacterSet(charactersIn: "/:"))
            .joined(separator: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? "Windows App" : cleaned
    }

    /// Single-quote a path for zsh, escaping embedded single quotes.
    static func quoted(_ path: String) -> String {
        "'" + path.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
