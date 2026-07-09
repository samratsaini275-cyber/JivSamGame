import SwiftUI

struct HeaderView: View {
    @EnvironmentObject var game: Game
    var onProfileTap: () -> Void = {}
    @State private var buffBounce = false

    var body: some View {
        VStack(spacing: 14) {
            topBar
            commandPanel

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
        .padding(.top, 14)
        .padding(.bottom, 6)
    }

    private var topBar: some View {
        HStack {
            if game.personaCreated {
                Button(action: onProfileTap) {
                    HStack(spacing: 9) {
                        GameImage(name: game.portraitImage, size: 34)
                            .clipShape(Circle())
                            .overlay(Circle().strokeBorder(game.theme.accent.opacity(0.7), lineWidth: 1.5))
                        VStack(alignment: .leading, spacing: 1) {
                            Text("@\(game.state.handle)")
                                .font(Theme.cartoonFont(12, weight: .bold))
                                .lineLimit(1)
                                .foregroundStyle(.white)
                            Text("Founder")
                                .font(Theme.cartoonFont(9, weight: .medium))
                                .foregroundStyle(Theme.textMuted)
                        }
                    }
                }
                .buttonStyle(PressableButtonStyle())
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                Text("CLOUT EMPIRE")
                    .font(Theme.cartoonFont(14, weight: .black))
                    .foregroundStyle(
                        LinearGradient(colors: [Theme.champagne, Theme.luxeGold], startPoint: .top, endPoint: .bottom)
                    )
                Text("PRIVATE TYCOON SUITE")
                    .font(Theme.cartoonFont(8, weight: .bold))
                    .foregroundStyle(Theme.textMuted)
            }
        }
    }

    private var commandPanel: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("NET LIQUID CAPITAL")
                    .font(Theme.cartoonFont(9, weight: .bold))
                    .foregroundStyle(Theme.champagne.opacity(0.78))
                AnimatedMoney(value: game.state.cash)
                    .font(Theme.cartoonFont(40, weight: .black))
                    .foregroundStyle(
                        LinearGradient(colors: [.white, Theme.champagne], startPoint: .top, endPoint: .bottom)
                    )
                    .glow(Theme.luxeGold, radius: 5)
                    .minimumScaleFactor(0.55)
                    .lineLimit(1)
                    .rolls(with: game.state.cash)
                Text("\(money(game.state.lifetimeCash)) lifetime gross")
                    .font(Theme.cartoonFont(10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.46))
                    .monospacedDigit()
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 5) {
                HStack(spacing: 6) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 11, weight: .bold))
                    Text("+\(money(game.incomePerSecond))/sec")
                        .font(Theme.cartoonFont(14, weight: .black))
                        .monospacedDigit()
                }
                .foregroundStyle(Theme.coinGreen)
                Text("passive yield")
                    .font(Theme.cartoonFont(9, weight: .medium))
                    .foregroundStyle(Theme.textMuted)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Theme.ink.opacity(0.66)))
            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(Theme.coinGreen.opacity(0.28), lineWidth: 1))
        }
        .padding(16)
        .background(alignment: .trailing) {
            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: 96, weight: .black))
                .foregroundStyle(Theme.luxeGold.opacity(0.055))
                .offset(x: 12)
        }
        .gameCard(highlighted: true, accent: Theme.luxeGold)
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
            .font(Theme.cartoonFont(10, weight: .bold))
            .foregroundStyle(game.theme.accent)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(RoundedRectangle(cornerRadius: 7, style: .continuous).fill(game.theme.accent.opacity(0.14)))
            .overlay(RoundedRectangle(cornerRadius: 7, style: .continuous).strokeBorder(game.theme.accent.opacity(0.36), lineWidth: 1))
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
                .font(Theme.cartoonFont(11, weight: .bold))
                .foregroundStyle(Theme.coinGreen)
                .buttonStyle(.borderless)
        }
        .padding(12)
        .gameCard(highlighted: true, accent: Theme.coinGreen)
    }
}
