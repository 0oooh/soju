import Foundation

public enum WineError: LocalizedError {
    case exited(code: Int32, logTail: String)

    public var errorDescription: String? {
        switch self {
        case .exited(let code, let logTail):
            return "Wine exited with code \(code).\n\(logTail)"
        }
    }
}

public enum WineRunner {
    /// Environment for a wine process in this bottle.
    static func environment(for bottle: Bottle) -> [String: String] {
        var env = ProcessInfo.processInfo.environment
        env["WINEPREFIX"] = bottle.prefixURL.path
        env["WINEDEBUG"] = "fixme-all"
        return env
    }

    public static func logURL(for bottle: Bottle) -> URL {
        SojuPaths.logs.appendingPathComponent("\(bottle.id).log")
    }

    static func makeProcess(engine: Engine, bottle: Bottle, args: [String], workingDir: URL? = nil) -> Process {
        let process = Process()
        process.executableURL = engine.wineBin
        process.arguments = args
        process.environment = environment(for: bottle)
        if let workingDir { process.currentDirectoryURL = workingDir }

        try? SojuPaths.ensure()
        let logURL = logURL(for: bottle)
        if !FileManager.default.fileExists(atPath: logURL.path) {
            FileManager.default.createFile(atPath: logURL.path, contents: nil)
        }
        if let log = try? FileHandle(forWritingTo: logURL) {
            log.seekToEndOfFile()
            if let header = "\n=== \(Date()) \(engine.name): \(args.joined(separator: " "))\n".data(using: .utf8) {
                log.write(header)
            }
            process.standardOutput = log
            process.standardError = log
        }
        return process
    }

    /// Launch a Windows executable and return immediately (GUI programs run long).
    @discardableResult
    public static func launch(exe: URL, engine: Engine, bottle: Bottle) throws -> Process {
        let process = makeProcess(
            engine: engine, bottle: bottle,
            args: [exe.path],
            workingDir: exe.deletingLastPathComponent()
        )
        try process.run()
        return process
    }

    /// Run a wine command to completion (winecfg /v, wineboot, regedit ...).
    public static func runAndWait(args: [String], engine: Engine, bottle: Bottle) async throws {
        let process = makeProcess(engine: engine, bottle: bottle, args: args)
        try process.run()
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            process.terminationHandler = { _ in continuation.resume() }
        }
        if process.terminationStatus != 0 {
            throw WineError.exited(code: process.terminationStatus, logTail: logTail(for: bottle))
        }
    }

    /// First boot of a new prefix. Slow (30-90 s under Rosetta); callers show progress.
    public static func initPrefix(engine: Engine, bottle: Bottle) async throws {
        try await runAndWait(args: ["wineboot", "--init"], engine: engine, bottle: bottle)
    }

    /// Set the Windows version this bottle reports to programs.
    public static func setWindowsVersion(_ version: WindowsVersion, engine: Engine, bottle: Bottle) async throws {
        try await runAndWait(args: ["winecfg", "/v", version.rawValue], engine: engine, bottle: bottle)
    }

    /// Open the winecfg control panel (returns immediately).
    public static func winecfg(engine: Engine, bottle: Bottle) throws {
        let process = makeProcess(engine: engine, bottle: bottle, args: ["winecfg"])
        try process.run()
    }

    /// Force-stop everything running in this bottle.
    public static func killBottle(engine: Engine, bottle: Bottle) {
        let wineserver = engine.wineBin.deletingLastPathComponent().appendingPathComponent("wineserver")
        let process = Process()
        process.executableURL = wineserver
        process.arguments = ["-k"]
        process.environment = environment(for: bottle)
        try? process.run()
    }

    public static func logTail(for bottle: Bottle, lines: Int = 12) -> String {
        guard let text = try? String(contentsOf: logURL(for: bottle), encoding: .utf8) else { return "" }
        return text.split(separator: "\n").suffix(lines).joined(separator: "\n")
    }
}
