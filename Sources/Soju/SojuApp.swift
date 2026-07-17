import AppKit
import SwiftUI

@main
struct SojuApp: App {
    @StateObject private var state = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(state)
                .frame(minWidth: 780, minHeight: 500)
                .onAppear {
                    // No-op inside a real bundle; makes `swift run` behave like an app.
                    NSApp.setActivationPolicy(.regular)
                    NSApp.activate(ignoringOtherApps: true)
                }
        }
    }
}
