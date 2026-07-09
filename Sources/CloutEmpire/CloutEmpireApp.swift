import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

@main
struct CloutEmpireApp: App {
    @StateObject private var game = Game.loadOrNew()

    init() {
        #if canImport(AppKit)
        // Running from `swift run` has no app bundle; this makes the window
        // appear in front with a Dock icon like a real app.
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(game)
                .preferredColorScheme(.dark)
                // Phone-shaped mobile layout; stretches on wider windows.
                .frame(minWidth: 390, idealWidth: 390, maxWidth: 480,
                       minHeight: 780, idealHeight: 844)
        }
        #if os(macOS)
        .windowResizability(.contentSize)
        #endif
    }
}
