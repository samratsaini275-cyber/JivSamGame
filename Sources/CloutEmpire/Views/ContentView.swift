import SwiftUI

struct ContentView: View {
    @EnvironmentObject var game: Game
    @StateObject private var particles = ParticleField()
    @State private var showingRebrand = false
    @State private var showingRex = false
    @State private var showingPersona = false
    @State private var showingCreation = false
    @State private var cardFrames: [Int: CGRect] = [:]
    @State private var toast: GameEvent?

    var body: some View {
        ZStack {
            Theme.backdrop(game.theme)

            VStack(spacing: 0) {
                HeaderView(onProfileTap: { showingPersona = true })

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 12) {
                        ForEach(game.hustles) { hustle in
                            HustleRowView(index: hustle.id)
                                .reportCardFrame(hustle.id)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                }

                dock
            }

            ParticleOverlay()
                .environmentObject(particles)

            if let toast {
                VStack {
                    Spacer().frame(height: 150)
                    EventToast(event: toast, colorway: game.theme)
                    Spacer()
                }
                .transition(.scale(scale: 0.7).combined(with: .opacity))
            }
        }
        .coordinateSpace(name: "game")
        .onPreferenceChange(CardFramesKey.self) { cardFrames = $0 }
        .onChange(of: game.lastEvent) { event in
            if let event { celebrate(event) }
        }
        .sheet(isPresented: $showingRebrand) { RebrandView().environmentObject(game) }
        .sheet(isPresented: $showingRex) { RexShopView().environmentObject(game) }
        .sheet(isPresented: $showingPersona) { PersonaView().environmentObject(game) }
        .sheet(isPresented: $showingCreation) { PersonaCreationView().environmentObject(game) }
        .onAppear {
            if !game.personaCreated { showingCreation = true }
        }
    }

    // MARK: Celebrations

    private func celebrate(_ event: GameEvent) {
        switch event.kind {
        case .payout(let index, let amount):
            if let frame = cardFrames[index] {
                particles.spawnCashPop("+\(money(amount))",
                                       at: CGPoint(x: frame.midX + .random(in: -40...40), y: frame.minY + 14))
            }
        case .milestone(let index, let tier):
            if let frame = cardFrames[index] {
                particles.spawnConfetti(at: CGPoint(x: frame.midX, y: frame.midY),
                                        colors: [Theme.tierColor(min(tier, 4)), game.theme.accent, .white])
            }
            show(event)
        case .hypeWave:
            particles.spawnConfetti(at: CGPoint(x: 215, y: 180),
                                    colors: [Theme.hypeOrange, game.theme.accent, .white], count: 50)
            show(event)
        case .rebranded:
            particles.spawnConfetti(at: CGPoint(x: 215, y: 200),
                                    colors: [Theme.cloutPurple, game.theme.accent, .white], count: 60)
            show(event)
        }
    }

    private func show(_ event: GameEvent) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { toast = event }
        Task {
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            if toast?.id == event.id {
                withAnimation(.easeOut(duration: 0.3)) { toast = nil }
            }
        }
    }

    // MARK: Floating glass dock

    private var dock: some View {
        HStack(spacing: 10) {
            buyModeSwitch

            Spacer(minLength: 4)

            if game.rexUnlocked {
                dockButton("💬", tint: .blue, badge: !game.state.rexMet) { showingRex = true }
                    .help("Rex has a proposition")
            }

            dockButton("🔄", tint: Theme.cloutPurple, badge: false) { showingRebrand = true }
                .help("Rebrand — burn the label, keep the Clout")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .luxCard(radius: 22)
        .padding(.horizontal, 14)
        .padding(.bottom, 12)
    }

    private var buyModeSwitch: some View {
        HStack(spacing: 2) {
            ForEach(BuyMode.allCases) { mode in
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) { game.buyMode = mode }
                } label: {
                    Text(mode.rawValue)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background {
                            if game.buyMode == mode {
                                Capsule().fill(game.theme.gradient)
                            }
                        }
                        .foregroundStyle(game.buyMode == mode ? Theme.bg : .secondary)
                }
                .buttonStyle(PressableButtonStyle(tint: game.theme.accent))
            }
        }
        .padding(3)
        .background(Capsule().fill(Color.white.opacity(0.06)))
    }

    private func dockButton(_ label: String, tint: Color, badge: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 16))
                .frame(width: 38, height: 38)
                .background(Circle().fill(tint.opacity(0.16)))
                .overlay(Circle().strokeBorder(tint.opacity(0.4), lineWidth: 1))
        }
        .buttonStyle(PressableButtonStyle(tint: tint))
        .overlay(alignment: .topTrailing) {
            if badge {
                Circle().fill(.red).frame(width: 9, height: 9)
                    .glow(.red, radius: 4)
                    .offset(x: 1, y: -1)
            }
        }
    }
}
