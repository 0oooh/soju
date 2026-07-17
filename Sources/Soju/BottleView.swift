import SojuKit
import SwiftUI

struct BottleView: View {
    @EnvironmentObject private var state: AppState
    let bottle: Bottle

    @State private var confirmDelete = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                actions
                pins
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .confirmationDialog(
            "Delete \u{201C}\(bottle.meta.name)\u{201D}?",
            isPresented: $confirmDelete
        ) {
            Button("Delete Bottle", role: .destructive) { state.delete(bottle) }
        } message: {
            Text("Everything installed in this bottle will be removed. This cannot be undone.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(bottle.meta.name)
                .font(.title2.bold())
            Text("\(state.engine(for: bottle)?.name ?? "No engine")  \u{00B7}  \(state.windowsVersion(of: bottle).displayName)")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private var actions: some View {
        HStack(spacing: 10) {
            Button {
                if let exe = Panels.chooseExe(startingAt: bottle.driveC) {
                    state.run(exe: exe, in: bottle)
                }
            } label: {
                Label("Run Program", systemImage: "play.fill")
                    .padding(.horizontal, 4)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button("C: Drive") { state.openCDrive(bottle) }
                .controlSize(.large)

            Button("Wine Settings") { state.winecfg(bottle) }
                .controlSize(.large)

            if SteamInstaller.steamExe(in: bottle) == nil {
                Button("Install Steam") { state.installSteam(in: bottle) }
                    .controlSize(.large)
                    .help("Downloads the official installer from Valve and runs it in this bottle")
            }

            Spacer()

            Menu {
                Picker("Windows Version", selection: Binding(
                    get: { state.windowsVersion(of: bottle) },
                    set: { state.changeWindowsVersion($0, for: bottle) }
                )) {
                    ForEach(WindowsVersion.allCases) { version in
                        Text(version.displayName).tag(version)
                    }
                }
                .pickerStyle(.menu)
                Divider()
                Button("Install Korean Fonts") { state.installKoreanFonts(in: bottle) }
                    .disabled(CJKFonts.isInstalled(in: bottle))
                Button("Stop All Processes") { state.killProcesses(in: bottle) }
                Divider()
                Button("Delete Bottle", role: .destructive) { confirmDelete = true }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
    }

    private var pins: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Programs")
                    .font(.headline)
                Spacer()
                Button {
                    if let exe = Panels.chooseExe(startingAt: bottle.driveC) {
                        state.pin(exe: exe, in: bottle)
                    }
                } label: {
                    Label("Add Program", systemImage: "plus")
                }
                .controlSize(.small)
            }

            if bottle.meta.pins.isEmpty {
                Text("Programs you add appear here. Right-click one to export it as a real Mac app you can keep in the Dock.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: 420, alignment: .leading)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 12)], spacing: 12) {
                    ForEach(bottle.meta.pins) { pin in
                        PinTile(pin: pin, bottle: bottle)
                    }
                }
                .animation(.spring(response: 0.35, dampingFraction: 1.0), value: bottle.meta.pins)
            }
        }
    }
}

struct PinTile: View {
    @EnvironmentObject private var state: AppState
    let pin: Pin
    let bottle: Bottle

    @State private var icon: NSImage?

    var body: some View {
        Button {
            state.run(exe: URL(fileURLWithPath: pin.exePath), in: bottle)
        } label: {
            VStack(spacing: 8) {
                Group {
                    if let icon {
                        Image(nsImage: icon)
                            .resizable()
                            .interpolation(.high)
                    } else {
                        Image(systemName: "app.dashed")
                            .resizable()
                            .foregroundStyle(.secondary)
                            .padding(8)
                    }
                }
                .frame(width: 48, height: 48)

                Text(pin.name)
                    .font(.callout)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 104, height: 96)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Run \(pin.name)")
        .contextMenu {
            Button("Run") { state.run(exe: URL(fileURLWithPath: pin.exePath), in: bottle) }
            Button("Export as Mac App") {
                if let folder = Panels.chooseExportFolder() {
                    state.export(pin: pin, from: bottle, to: folder)
                }
            }
            Button("Show in Finder") {
                NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: pin.exePath)])
            }
            Divider()
            Button("Remove", role: .destructive) { state.unpin(pin, from: bottle) }
        }
        .task(id: pin.exePath) {
            let path = pin.exePath
            icon = await Task.detached { PEIcon.image(for: URL(fileURLWithPath: path)) }.value
        }
    }
}
