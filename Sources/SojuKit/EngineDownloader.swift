import Foundation

public struct EngineRelease: Sendable {
    public let version: String        // e.g. "wine-staging-11.10"
    public let downloadURL: URL
    public let size: Int64
}

public enum EngineDownloadError: LocalizedError {
    case noAsset
    case badArchive(String)

    public var errorDescription: String? {
        switch self {
        case .noAsset: return "No wine-staging build found in the latest Gcenx release."
        case .badArchive(let detail): return "Engine archive could not be installed: \(detail)"
        }
    }
}

public enum EngineDownloader {
    static let releaseAPI = URL(string: "https://api.github.com/repos/Gcenx/macOS_Wine_builds/releases/latest")!

    /// True when x86_64 wine binaries can run on this machine.
    public static func isRosettaAvailable() -> Bool {
        #if arch(x86_64)
        return true
        #else
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/arch")
        process.arguments = ["-x86_64", "/usr/bin/true"]
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
        #endif
    }

    public static func latestRelease() async throws -> EngineRelease {
        var request = URLRequest(url: releaseAPI)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        let (data, _) = try await URLSession.shared.data(for: request)

        struct Release: Decodable {
            struct Asset: Decodable { let name: String; let browser_download_url: URL; let size: Int64 }
            let tag_name: String
            let assets: [Asset]
        }
        let release = try JSONDecoder().decode(Release.self, from: data)
        guard let asset = release.assets.first(where: {
            $0.name.hasPrefix("wine-staging-") && $0.name.hasSuffix("osx64.tar.xz")
        }) else { throw EngineDownloadError.noAsset }

        return EngineRelease(
            version: "wine-staging-\(release.tag_name)",
            downloadURL: asset.browser_download_url,
            size: asset.size
        )
    }

    /// Download and install an engine. Progress is reported as (received, total) bytes.
    public static func install(
        _ release: EngineRelease,
        progress: @escaping @Sendable (Int64, Int64) -> Void
    ) async throws -> Engine {
        try SojuPaths.ensure()

        let tarURL = SojuPaths.engines.appendingPathComponent("\(release.version).tar.xz")
        try await download(release.downloadURL, to: tarURL, expectedSize: release.size, progress: progress)

        // Extract next to it, then verify a wine binary is actually inside.
        let engineDir = SojuPaths.engines.appendingPathComponent(release.version, isDirectory: true)
        try? FileManager.default.removeItem(at: engineDir)
        try FileManager.default.createDirectory(at: engineDir, withIntermediateDirectories: true)

        let tar = Process()
        tar.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
        tar.arguments = ["-xJf", tarURL.path, "-C", engineDir.path]
        try tar.run()
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            tar.terminationHandler = { _ in continuation.resume() }
        }
        try? FileManager.default.removeItem(at: tarURL)

        guard tar.terminationStatus == 0 else {
            throw EngineDownloadError.badArchive("tar exited with \(tar.terminationStatus)")
        }
        guard let bin = EngineStore.findWineBin(under: engineDir) else {
            throw EngineDownloadError.badArchive("no wine binary found after extraction")
        }
        return Engine(name: release.version, wineBin: bin, source: .downloaded)
    }

    static func download(
        _ url: URL, to destination: URL, expectedSize: Int64,
        progress: @escaping @Sendable (Int64, Int64) -> Void
    ) async throws {
        final class Delegate: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
            let destination: URL
            let expectedSize: Int64
            let progress: @Sendable (Int64, Int64) -> Void
            var continuation: CheckedContinuation<Void, Error>?

            init(destination: URL, expectedSize: Int64, progress: @escaping @Sendable (Int64, Int64) -> Void) {
                self.destination = destination
                self.expectedSize = expectedSize
                self.progress = progress
            }

            func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                            didWriteData bytesWritten: Int64, totalBytesWritten: Int64,
                            totalBytesExpectedToWrite: Int64) {
                let total = totalBytesExpectedToWrite > 0 ? totalBytesExpectedToWrite : expectedSize
                progress(totalBytesWritten, total)
            }

            func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                            didFinishDownloadingTo location: URL) {
                do {
                    try? FileManager.default.removeItem(at: destination)
                    try FileManager.default.moveItem(at: location, to: destination)
                } catch {
                    continuation?.resume(throwing: error)
                    continuation = nil
                }
            }

            func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
                if let error {
                    continuation?.resume(throwing: error)
                } else {
                    continuation?.resume()
                }
                continuation = nil
            }
        }

        let delegate = Delegate(destination: destination, expectedSize: expectedSize, progress: progress)
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        defer { session.finishTasksAndInvalidate() }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            delegate.continuation = continuation
            session.downloadTask(with: url).resume()
        }
    }
}
