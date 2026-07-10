import SwiftUI

struct ContentView: View {
    @EnvironmentObject var game: Game
    @StateObject private var particles = ParticleField()
    @StateObject private var wire = TickerFeed()
    // Dev: DEV_TAB=rebrand|rex|profile opens on that tab for snapshots.
    @State private var tab: MainTab = ProcessInfo.processInfo
        .environment["DEV_TAB"].flatMap(MainTab.init(rawValue:)) ?? .empire
    @State private var previousTabIndex = 0
    @State private var showingCreation = false
    @State private var cardFrames: [Int: CGRect] = [:]
    @State private var toast: GameEvent?
    @State private var takeover: GameEvent?

    var body: some View {
        ZStack {
            Theme.backdrop(game.theme)

            VStack(spacing: 0) {
                tabContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                GameTabBar(
                    selection: $tab,
                    colorway: game.theme,
                    rexBadge: game.rexUnreadCount > 0,
                    rexUnlocked: game.rexUnlocked,
                    rebrandBadge: game.cloutOnRebrand > 0
                )
            }

            ParticleOverlay()
                .environmentObject(particles)

            if let takeover { HypeTakeoverOverlay(event: takeover) }
            if let toast { toastOverlay(toast) }
        }
        .coordinateSpace(name: "game")
        .onPreferenceChange(CardFramesKey.self) { cardFrames = $0 }
        .onChange(of: game.lastEvent) { event in
            if let event {
                celebrate(event)
                wire.report(event, game: game)
            }
        }
        .sheet(isPresented: $showingCreation) {
            PersonaCreationView().environmentObject(game)
        }
        .onAppear {
            if !game.personaCreated { showingCreation = true }
        }
        .onChange(of: tab) { newTab in
            if newTab == .rex, game.rexUnlocked { game.markRexMet() }
            previousTabIndex = newTab.index
        }
        .onChange(of: game.rexUnlocked) { unlocked in
            if !unlocked, tab == .rex { tab = .empire }
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        let forward = tab.index >= previousTabIndex
        ZStack {
            Group {
                switch tab {
                case .empire: empireTab
                case .rex:
                    if game.rexUnlocked {
                        RexChatView(embedded: true).environmentObject(game)
                    } else {
                        dmsLockedPlaceholder
                    }
                case .rebrand: RebrandView(embedded: true).environmentObject(game)
                case .profile: PersonaView(embedded: true).environmentObject(game)
                }
            }
            .id(tab)
            .transition(
                .asymmetric(
                    insertion: .offset(x: forward ? 14 : -14).combined(with: .opacity),
                    removal: .opacity
                )
            )
        }
        .animation(.easeOut(duration: 0.18), value: tab)
    }

    private var dmsLockedPlaceholder: some View {
        VStack(spacing: 14) {
            Spacer()
            ZStack {
                GameImage(name: "tab_rex", size: 72)
                    .opacity(0.3)
                Image(systemName: "lock.fill")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white.opacity(0.85))
            }
            Text("DMS LOCKED")
                .font(Theme.display(20))
                .kerning(1)
                .foregroundStyle(Theme.textPrimary)
            Text("Unlock Sneaker Resells to hear from Vinnie.")
                .font(Theme.mono(10))
                .foregroundStyle(Theme.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var empireTab: some View {
        VStack(spacing: 0) {
            HeaderView(onProfileTap: { tab = .profile }, onCloutTap: { tab = .rebrand })

            TickerTape(feed: wire)
                .padding(.top, 2)

            VStack(spacing: 9) {
                HStack(alignment: .lastTextBaseline) {
                    Text("THE HUSTLES")
                        .font(Theme.display(18))
                        .kerning(1)
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Text("\(game.hustles.filter { game.state.hustles[$0.id].unitsOwned > 0 }.count)/\(game.hustles.count) LIVE")
                        .font(Theme.mono(8.5, weight: .semibold))
                        .kerning(0.8)
                        .foregroundStyle(Theme.textFaint)
                }

                GameSegmentedControl(
                    selection: Binding(get: { game.buyMode }, set: { game.buyMode = $0 }),
                    options: BuyMode.allCases,
                    colorway: game.theme
                )
            }
            .padding(.horizontal, Theme.screenPadding)
            .padding(.top, 12)
            .padding(.bottom, 10)

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 10) {
                    FlexCard()
                    ForEach(game.hustles) { hustle in
                        HustleRowView(index: hustle.id)
                            .reportCardFrame(hustle.id)
                    }
                }
                .padding(.horizontal, Theme.screenPadding)
                .padding(.bottom, 16)
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
                    at: CGPoint(x: frame.midX + .random(in: -25...25), y: frame.minY + 16),
                    color: Theme.go
                )
            }
        case .milestone(let index, let tier):
            if let frame = cardFrames[index] {
                particles.spawnConfetti(
                    at: CGPoint(x: frame.midX, y: frame.midY),
                    colors: [Theme.tierColor(min(tier, 4)), Theme.hype, .white]
                )
            }
            show(event)
        case .hypeWave:
            particles.spawnConfetti(
                at: CGPoint(x: 200, y: 150),
                colors: [Theme.hype, Theme.moneyHigh, .white],
                count: 40
            )
            showTakeover(event)
        case .rebranded:
            particles.spawnConfetti(
                at: CGPoint(x: 200, y: 170),
                colors: [Theme.hype, Theme.moneyHigh, .white],
                count: 48
            )
            showTakeover(event)
        case .newDM:
            show(event)
        case .flexHit:
            particles.spawnConfetti(
                at: CGPoint(x: 200, y: 150),
                colors: [Theme.hypeSoft, Theme.hype, .white],
                count: 24
            )
            show(event)
        case .flexViral:
            particles.spawnConfetti(
                at: CGPoint(x: 200, y: 150),
                colors: [Theme.hype, Theme.moneyHigh, .white],
                count: 40
            )
            show(event)
        case .flexExposed, .flexSaved:
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

    /// The big moments (Hype Wave, Rebrand) get a ≤1.2s screen-wide treatment.
    private func showTakeover(_ event: GameEvent) {
        withAnimation(.easeOut(duration: 0.15)) { takeover = event }
        Task {
            try? await Task.sleep(nanoseconds: 1_100_000_000)
            if takeover?.id == event.id {
                withAnimation(.easeOut(duration: 0.25)) { takeover = nil }
            }
        }
    }
}
