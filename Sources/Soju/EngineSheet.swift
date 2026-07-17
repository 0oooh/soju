import SojuKit
import SwiftUI

/// Engine onboarding and management. Shown automatically on first run.
struct EngineSheet: View {
    @EnvironmentObject private var state: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Wine Engine")
                .font(.title3.bold())

            content

            HStack {
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
        }
        .padding(20)
        .frame(width: 420)
    }

    @ViewBuilder
    private var content: some View {
        switch state.engineSetup {
        case .missingRosetta:
            VStack(alignment: .leading, spacing: 10) {
                Label("Rosetta is required", systemImage: "exclamationmark.triangle")
                    .font(.headline)
                Text("Wine builds are Intel binaries, so Apple Silicon needs Rosetta. Run this once in Terminal, then reopen Soju:")
                    .foregroundStyle(.secondary)
                HStack {
                    Text(verbatim: "softwareupdate --install-rosetta")
                        .font(.system(.callout, design: .monospaced))
                        .textSelection(.enabled)
                    Button("Copy") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString("softwareupdate --install-rosetta", forType: .string)
                    }
                    .controlSize(.small)
                }
                .padding(10)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
            }

        case .none:
            VStack(alignment: .leading, spacing: 10) {
                Text("Soju needs a Wine engine to run Windows software. Engines are downloaded from their upstream releases and kept inside Soju's own folder.")
                    .foregroundStyle(.secondary)
                Button {
                    state.installEngine(.wineStaging)
                } label: {
                    Label("Install Wine Engine", systemImage: "arrow.down.circle")
                        .padding(.horizontal, 4)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                Text("You can add the DirectX 12 engine (Game Porting Toolkit) here later.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

        case .downloading(let fraction):
            VStack(alignment: .leading, spacing: 8) {
                ProgressView(value: fraction) {
                    Text("Downloading engine")
                } currentValueLabel: {
                    Text("\(Int(fraction * 100)) percent")
                }
                Text("The engine is installed once and shared by every bottle.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

        case .ready:
            VStack(alignment: .leading, spacing: 10) {
                ForEach(state.engines) { engine in
                    HStack {
                        Image(systemName: engine.source == .downloaded ? "checkmark.seal" : "magnifyingglass")
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(engine.name)
                            Text(engine.source == .downloaded ? "Installed by Soju" : "Detected on this Mac")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }
                Divider()
                ForEach(EngineFlavor.allCases) { flavor in
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(flavor.displayName)
                            Text(flavor.summary)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Install") { state.installEngine(flavor) }
                            .controlSize(.small)
                    }
                }
            }
        }
    }
}
