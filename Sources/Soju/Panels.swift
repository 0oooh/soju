import AppKit
import UniformTypeIdentifiers

enum Panels {
    static func chooseExe(startingAt directory: URL? = nil) -> URL? {
        let panel = NSOpenPanel()
        panel.title = "Choose a Windows Executable"
        panel.allowedContentTypes = [UTType(filenameExtension: "exe"), UTType(filenameExtension: "msi")]
            .compactMap { $0 }
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if let directory { panel.directoryURL = directory }
        return panel.runModal() == .OK ? panel.url : nil
    }

    /// Destination folder for exported apps; defaults to ~/Applications.
    static func chooseExportFolder() -> URL? {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let userApps = home.appendingPathComponent("Applications", isDirectory: true)
        try? FileManager.default.createDirectory(at: userApps, withIntermediateDirectories: true)

        let panel = NSOpenPanel()
        panel.title = "Choose Where to Save the App"
        panel.prompt = "Export"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.directoryURL = userApps
        return panel.runModal() == .OK ? panel.url : nil
    }
}
