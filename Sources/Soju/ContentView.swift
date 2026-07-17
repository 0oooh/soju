import SojuKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var state: AppState
    @State private var showCreateSheet = false
    @State private var showEngineSheet = false

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detail
        }
        .navigationTitle("Soju")
        .onAppear {
            if state.engineSetup != .ready { showEngineSheet = true }
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateBottleSheet()
        }
        .sheet(isPresented: $showEngineSheet) {
            EngineSheet()
        }
        .alert(
            "Something Went Wrong",
            isPresented: Binding(
                get: { state.lastError != nil },
                set: { if !$0 { state.lastError = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(state.lastError ?? "")
        }
    }

    private var sidebar: some View {
        List(selection: $state.selectedBottleID) {
            Section("Bottles") {
                ForEach(state.bottles) { bottle in
                    Label(bottle.meta.name, systemImage: "waterbottle")
                        .tag(bottle.id)
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            engineFooter
        }
        .toolbar {
            ToolbarItem {
                Button {
                    showCreateSheet = true
                } label: {
                    Label("New Bottle", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: .command)
                .disabled(state.engines.isEmpty)
                .help(state.engines.isEmpty ? "Install a Wine engine first" : "Create a new bottle")
            }
            ToolbarItem {
                importMenu
            }
        }
    }

    private var importMenu: some View {
        Menu {
            if state.whiskyBottles.isEmpty {
                Text("No Whisky bottles found")
            } else {
                ForEach(state.whiskyBottles) { whisky in
                    Button(whisky.name) { state.importWhisky(whisky) }
                }
            }
        } label: {
            if state.importingWhisky {
                ProgressView().controlSize(.small)
            } else {
                Label("Import from Whisky", systemImage: "square.and.arrow.down")
            }
        }
        .disabled(state.importingWhisky)
        .help("Import an old Whisky bottle")
    }

    private var engineFooter: some View {
        Button {
            showEngineSheet = true
        } label: {
            HStack(spacing: 8) {
                Circle()
                    .fill(state.engineSetup == .ready ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
                Text(footerText)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer()
                Image(systemName: "gearshape")
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(.bar)
        .help("Engine settings")
    }

    private var footerText: String {
        switch state.engineSetup {
        case .ready: return state.engines.first?.name ?? "Engine ready"
        case .downloading: return "Installing engine"
        case .missingRosetta: return "Rosetta required"
        case .none: return "No engine installed"
        }
    }

    @ViewBuilder
    private var detail: some View {
        if let bottle = state.selectedBottle {
            if state.bootingBottleIDs.contains(bottle.id) {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Setting up \(bottle.meta.name)")
                        .font(.headline)
                    Text("Wine is creating the Windows environment. This takes a minute the first time.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                BottleView(bottle: bottle)
            }
        } else {
            ContentUnavailableView {
                Label("No Bottles", systemImage: "waterbottle")
            } description: {
                Text("A bottle is a self-contained Windows environment. Create one to run Windows apps and games.")
            } actions: {
                Button("Create Bottle") { showCreateSheet = true }
                    .buttonStyle(.borderedProminent)
                    .disabled(state.engines.isEmpty)
            }
        }
    }
}

struct CreateBottleSheet: View {
    @EnvironmentObject private var state: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var engineID: String?
    @State private var windowsVersion: WindowsVersion = .win10

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("New Bottle")
                .font(.title3.bold())

            TextField("Name", text: $name, prompt: Text("My Games"))
                .textFieldStyle(.roundedBorder)

            Picker("Engine", selection: $engineID) {
                ForEach(state.engines) { engine in
                    Text(engine.name).tag(Optional(engine.id))
                }
            }

            Picker("Windows", selection: $windowsVersion) {
                ForEach(WindowsVersion.allCases) { version in
                    Text(version.displayName).tag(version)
                }
            }

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                Button("Create") {
                    let engine = state.engines.first { $0.id == engineID } ?? state.engines.first
                    if let engine {
                        state.createBottle(
                            name: name.trimmingCharacters(in: .whitespaces),
                            engine: engine,
                            windowsVersion: windowsVersion
                        )
                    }
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 340)
        .onAppear { engineID = state.engines.first?.id }
    }
}
