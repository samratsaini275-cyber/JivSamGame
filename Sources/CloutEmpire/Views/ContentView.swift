import SwiftUI

struct ContentView: View {
    @EnvironmentObject var game: Game
    @StateObject private var particles = ParticleField()
    @State private var tab: MainTab = .empire
    @State private var showingCreation = false
    @State private var cardFrames: [Int: CGRect] = [:]
    @State private var toast: GameEvent?

    var body: some View {
        ZStack {
            Theme.backdrop(game.theme)

            VStack(spacing: 0) {
                tabContent
                GameTabBar(
                    selection: $tab,
                    colorway: game.theme,
                    rexBadge: !game.state.rexMet && game.rexUnlocked,
                    rexUnlocked: game.rexUnlocked
                )
            }

            ParticleOverlay()
                .environmentObject(particles)

            if let toast { toastOverlay(toast) }
        }
        .coordinateSpace(name: "game")
        .onPreferenceChange(CardFramesKey.self) { cardFrames = $0 }
        .onChange(of: game.lastEvent) { event in
            if let event { celebrate(event) }
        }
        .sheet(isPresented: $showingCreation) {
            PersonaCreationView().environmentObject(game)
        }
        .onAppear {
            if !game.personaCreated { showingCreation = true }
        }
        .onChange(of: tab) { newTab in
            if newTab == .rex { game.markRexMet() }
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch tab {
        case .empire: empireTab
        case .rex: RexShopView(embedded: true).environmentObject(game)
        case .rebrand: RebrandView(embedded: true).environmentObject(game)
        case .profile: PersonaView(embedded: true).environmentObject(game)
        }
    }

    private var empireTab: some View {
        VStack(spacing: 0) {
            HeaderView(onProfileTap: { tab = .profile })

            GameSegmentedControl(
                selection: Binding(get: { game.buyMode }, set: { game.buyMode = $0 }),
                options: BuyMode.allCases,
                colorway: game.theme
            )
            .padding(.horizontal, Theme.screenPadding)
            .padding(.vertical, 8)

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 10) {
                    ForEach(game.hustles) { hustle in
                        HustleRowView(index: hustle.id)
                            .reportCardFrame(hustle.id)
                    }
                }
                .padding(.horizontal, Theme.screenPadding)
                .padding(.bottom, 14)
            }
        }
    }

    private func toastOverlay(_ event: GameEvent) -> some View {
        VStack {
            Spacer().frame(height: 110)
            EventToast(event: event, colorway: game.theme)
            Spacer()
        }
        .transition(.scale(scale: 0.8).combined(with: .opacity))
        .allowsHitTesting(false)
    }

    private func celebrate(_ event: GameEvent) {
        switch event.kind {
        case .payout(let index, let amount):
            if let frame = cardFrames[index] {
                particles.spawnCashPop(
                    "+\(money(amount))",
                    at: CGPoint(x: frame.midX + .random(in: -25...25), y: frame.minY + 16)
                )
            }
        case .milestone(let index, let tier):
            if let frame = cardFrames[index] {
                particles.spawnConfetti(
                    at: CGPoint(x: frame.midX, y: frame.midY),
                    colors: [Theme.tierColor(min(tier, 4)), game.theme.accent, .white]
                )
            }
            show(event)
        case .hypeWave:
            particles.spawnConfetti(
                at: CGPoint(x: 200, y: 150),
                colors: [Theme.hypeBlue, game.theme.accent, .white],
                count: 40
            )
            show(event)
        case .rebranded:
            particles.spawnConfetti(
                at: CGPoint(x: 200, y: 170),
                colors: [Theme.cloutPink, game.theme.accent, .white],
                count: 48
            )
            show(event)
        }
    }

    private func show(_ event: GameEvent) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) { toast = event }
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if toast?.id == event.id {
                withAnimation(.easeOut(duration: 0.25)) { toast = nil }
            }
        }
    }
}
