import SwiftUI

struct HeaderView: View {
    @EnvironmentObject var game: Game
    var onProfileTap: () -> Void = {}
    @State private var buffBounce = false

    var body: some View {
        VStack(spacing: 12) {
            topBar

            VStack(spacing: 4) {
                AnimatedMoney(value: game.state.cash)
                    .font(Theme.cartoonFont(44, weight: .black))
                    .foregroundStyle(.white)
                    .glow(Theme.coinGreen, radius: 10)
                    .rolls(with: game.state.cash)

                HStack(spacing: 8) {
                    Text("+\(money(game.incomePerSecond))/sec")
                        .font(Theme.cartoonFont(12))
                        .foregroundStyle(Theme.coinGreen)
                    Text("·")
                        .foregroundStyle(.white.opacity(0.3))
                    Text("\(money(game.state.lifetimeCash)) all-time")
                        .font(Theme.cartoonFont(11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .monospacedDigit()
            }

            HStack(spacing: 10) {
                StatBadge(
                    imageName: "icon_clout",
                    title: "\(Int(game.state.clout)) CLOUT",
                    value: "+\(Int(game.state.clout * 2))% forever",
                    color: Theme.cloutPink
                )
                StatBadge(
                    imageName: "icon_hype",
                    title: "HYPE ×\(Int(pow(2, Double(game.effectiveViralTier))))",
                    value: "\(game.hustlesAtNextViralTier)/\(game.hustles.count) ready",
                    color: Theme.hypeBlue,
                    progress: Double(game.hustlesAtNextViralTier) / Double(game.hustles.count)
                )
            }

            if game.milleBuffActive || game.viralBuffActive { buffRow }
            if game.offlineEarnings > 0 { offlineBanner }
        }
        .padding(.horizontal, Theme.screenPadding)
        .padding(.top, 10)
        .padding(.bottom, 4)
    }

    private var topBar: some View {
        HStack {
            if game.personaCreated {
                Button(action: onProfileTap) {
                    HStack(spacing: 6) {
                        GameImage(name: game.portraitImage, size: 34)
                            .clipShape(Circle())
                            .overlay(Circle().strokeBorder(Theme.comicBorder, lineWidth: 2))
                        Text("@\(game.state.handle)")
                            .font(Theme.cartoonFont(11))
                            .lineLimit(1)
                    }
                }
                .buttonStyle(PressableButtonStyle())
            }
            Spacer()
            Text("DRIP EMPIRE")
                .font(Theme.cartoonFont(12, weight: .black))
                .tracking(2)
                .foregroundStyle(game.theme.gradient)
        }
    }

    private var buffRow: some View {
        HStack(spacing: 8) {
            if game.milleBuffActive { buffPill("MILLE ×2") }
            if game.viralBuffActive { buffPill("EARLY HYPE ×2") }
        }
        .scaleEffect(buffBounce ? 1.05 : 1)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) { buffBounce = true }
        }
    }

    private func buffPill(_ text: String) -> some View {
        Text(text)
            .font(Theme.cartoonFont(10))
            .foregroundStyle(game.theme.accent)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(game.theme.accent.opacity(0.2)))
            .overlay(Capsule().strokeBorder(Theme.comicBorder, lineWidth: 2))
    }

    private var offlineBanner: some View {
        HStack {
            GameImage(name: "icon_sparkle", size: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text("Your plug kept working!")
                    .font(Theme.cartoonFont(10))
                Text("+\(money(game.offlineEarnings)) while you were gone")
                    .font(Theme.cartoonFont(10, weight: .bold))
                    .foregroundStyle(Theme.coinGreen)
            }
            Spacer()
            Button("Collect") { game.offlineEarnings = 0 }
                .font(Theme.cartoonFont(11))
                .foregroundStyle(Theme.coinGreen)
                .buttonStyle(.borderless)
        }
        .padding(12)
        .gameCard(highlighted: true, accent: Theme.coinGreen)
    }
}
