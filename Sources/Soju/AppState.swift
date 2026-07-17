import AppKit
import SojuKit
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    enum EngineSetup: Equatable {
        case missingRosetta
        case none                  // Rosetta fine, no engine installed
        case downloading(Double)   // 0...1
        case ready
    }

    @Published var bottles: [Bottle] = []
    @Published var engines: [Engine] = []
    @Published var selectedBottleID: String?
    @Published var engineSetup: EngineSetup = .none
    @Published var bootingBottleIDs: Set<String> = []
    @Published var importingWhisky = false
    @Published var lastError: String?

    var selectedBottle: Bottle? { bottles.first { $0.id == selectedBottleID } }

    init() {
        try? SojuPaths.ensure()
        refresh()
    }

    func refresh() {
        bottles = BottleStore.load()
        engines = EngineStore.discover()
        if selectedBottleID == nil || !bottles.contains(where: { $0.id == selectedBottleID }) {
            selectedBottleID = bottles.first?.id
        }
        if case .downloading = engineSetup { return }
        if engines.isEmpty {
            engineSetup = EngineDownloader.isRosettaAvailable() ? .none : .missingRosetta
        } else {
            engineSetup = .ready
        }
    }

    func engine(for bottle: Bottle) -> Engine? {
        if let path = bottle.meta.enginePath, let match = engines.first(where: { $0.id == path }) {
            return match
        }
        return engines.first
    }

    // MARK: - Bottles

    func createBottle(name: String, engine: Engine, windowsVersion: WindowsVersion = .win10) {
        do {
            var bottle = try BottleStore.create(name: name)
            bottle.meta.enginePath = engine.id
            bottle.meta.windowsVersion = windowsVersion.rawValue
            try BottleStore.save(bottle)
            refresh()
            selectedBottleID = bottle.id
            bootingBottleIDs.insert(bottle.id)
            let target = bottle
            Task {
                do {
                    try await WineRunner.initPrefix(engine: engine, bottle: target)
                    if windowsVersion != .win10 {   // wine's own default
                        try await WineRunner.setWindowsVersion(windowsVersion, engine: engine, bottle: target)
                    }
                } catch {
                    lastError = "Bottle setup failed. \(error.localizedDescription)"
                }
                bootingBottleIDs.remove(target.id)
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    func windowsVersion(of bottle: Bottle) -> WindowsVersion {
        bottle.meta.windowsVersion.flatMap(WindowsVersion.init(rawValue:)) ?? .win10
    }

    func changeWindowsVersion(_ version: WindowsVersion, for bottle: Bottle) {
        guard let engine = engine(for: bottle) else { return }
        var updated = bottle
        updated.meta.windowsVersion = version.rawValue
        save(updated)
        Task {
            do {
                try await WineRunner.setWindowsVersion(version, engine: engine, bottle: bottle)
            } catch {
                lastError = "Could not change Windows version. \(error.localizedDescription)"
            }
        }
    }

    func delete(_ bottle: Bottle) {
        if let engine = engine(for: bottle) {
            WineRunner.killBottle(engine: engine, bottle: bottle)
        }
        do {
            try BottleStore.delete(bottle)
        } catch {
            lastError = error.localizedDescription
        }
        refresh()
    }

    // MARK: - Running

    func run(exe: URL, in bottle: Bottle) {
        guard let engine = engine(for: bottle) else {
            lastError = "No Wine engine installed. Install one in Engine settings."
            return
        }
        do {
            try WineRunner.launch(exe: exe, engine: engine, bottle: bottle)
        } catch {
            lastError = error.localizedDescription
        }
    }

    func winecfg(_ bottle: Bottle) {
        guard let engine = engine(for: bottle) else { return }
        try? WineRunner.winecfg(engine: engine, bottle: bottle)
    }

    func killProcesses(in bottle: Bottle) {
        guard let engine = engine(for: bottle) else { return }
        WineRunner.killBottle(engine: engine, bottle: bottle)
    }

    func openCDrive(_ bottle: Bottle) {
        NSWorkspace.shared.open(bottle.driveC)
    }

    // MARK: - Pins

    func pin(exe: URL, in bottle: Bottle) {
        var updated = bottle
        updated.meta.pins.append(Pin(name: exe.deletingPathExtension().lastPathComponent, exePath: exe.path))
        save(updated)
    }

    func unpin(_ pin: Pin, from bottle: Bottle) {
        var updated = bottle
        updated.meta.pins.removeAll { $0.id == pin.id }
        save(updated)
    }

    private func save(_ bottle: Bottle) {
        do {
            try BottleStore.save(bottle)
        } catch {
            lastError = error.localizedDescription
        }
        refresh()
    }

    // MARK: - Export

    func export(pin: Pin, from bottle: Bottle, to directory: URL) {
        guard let engine = engine(for: bottle) else {
            lastError = "No Wine engine installed."
            return
        }
        do {
            let app = try AppExporter.export(pin: pin, bottle: bottle, engine: engine, to: directory)
            NSWorkspace.shared.activateFileViewerSelecting([app])
        } catch {
            lastError = "Export failed. \(error.localizedDescription)"
        }
    }

    // MARK: - Engine install

    func installEngine() {
        engineSetup = .downloading(0)
        Task {
            do {
                let release = try await EngineDownloader.latestRelease()
                _ = try await EngineDownloader.install(release) { received, total in
                    let fraction = total > 0 ? Double(received) / Double(total) : 0
                    Task { @MainActor in
                        if case .downloading = self.engineSetup {
                            self.engineSetup = .downloading(fraction)
                        }
                    }
                }
                engineSetup = .ready
                refresh()
            } catch {
                lastError = "Engine install failed. \(error.localizedDescription)"
                engineSetup = .none
                refresh()
            }
        }
    }

    // MARK: - Whisky import

    var whiskyBottles: [WhiskyBottle] { WhiskyImporter.detect() }

    func importWhisky(_ whisky: WhiskyBottle) {
        importingWhisky = true
        Task.detached {
            do {
                let imported = try WhiskyImporter.importBottle(whisky)
                await MainActor.run {
                    self.importingWhisky = false
                    self.refresh()
                    self.selectedBottleID = imported.id
                }
            } catch {
                await MainActor.run {
                    self.importingWhisky = false
                    self.lastError = "Import failed. \(error.localizedDescription)"
                }
            }
        }
    }
}
