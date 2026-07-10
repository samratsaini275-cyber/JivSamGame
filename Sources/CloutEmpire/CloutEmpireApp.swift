import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

@main
struct CloutEmpireApp: App {
    @StateObject private var game: Game

    init() {
        // Dev: DEV_SEED=1|locked fabricates a game state (persona, hustles,
        // affordability bands) so SNAPSHOT_PATH captures real UI states.
        let game = Game.loadOrNew()
        switch ProcessInfo.processInfo.environment["DEV_SEED"] {
        case "locked": Self.seedEarlyGame(game)
        case .some: Self.seedMidGame(game)
        case nil: break
        }
        _game = StateObject(wrappedValue: game)
        #if canImport(AppKit)
        // Running from `swift run` has no app bundle; this makes the window
        // appear in front with a Dock icon like a real app.
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
        }
        // Dev: SNAPSHOT_PATH=/tmp/shot.png renders the window to a PNG and
        // quits — lets UI changes be eyeballed without screen-recording perms.
        if let path = ProcessInfo.processInfo.environment["SNAPSHOT_PATH"] {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                if let view = NSApp.windows.first?.contentView,
                   let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) {
                    view.cacheDisplay(in: view.bounds, to: rep)
                    try? rep.representation(using: .png, properties: [:])?
                        .write(to: URL(fileURLWithPath: path))
                }
                NSApp.terminate(nil)
            }
        }
        #endif
    }

    /// Dev-only: walk the normal player actions to a representative mid-game.
    private static func seedMidGame(_ game: Game) {
        game.createPersona(handle: "wavycheckz", look: BaseLook.all.first?.id ?? "", colorway: "gold")
        game.devAddCash(9_100)
        game.buyMode = .ten
        for _ in 0..<3 { game.buy(0) }   // 30 Bootleg Tees (past first milestone)
        game.buy(1)                       // 10 Sneaker Resells
        game.hireGhostwriter(0)
        game.buyMode = .one
        // Leftover ≈ $6.1K: Custom Hoodies ($720) affordable, Hyped Drops
        // ($8.6K) sits in the ≥80% "almost affordable" shimmer band.
    }

    /// Dev-only: early game — first hustle owned, the next ones locked across
    /// all three affordability bands (affordable / almost / far).
    private static func seedEarlyGame(_ game: Game) {
        game.createPersona(handle: "wavycheckz", look: BaseLook.all.first?.id ?? "", colorway: "gold")
        game.devAddCash(610)
        game.buy(0)
        // ≈$600 left: Sneaker Resells ($60) affordable, Custom Hoodies ($720)
        // in the ≥80% shimmer band, Hyped Drops ($8.6K) at 7%.
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
