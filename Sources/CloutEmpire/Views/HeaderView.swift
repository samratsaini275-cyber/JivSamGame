import SwiftUI

struct HeaderView: View {
    @EnvironmentObject var game: Game
    var onProfileTap: () -> Void = {}
    @State private var buffBounce = false
    @State private var devCashInput = ""

    var body: some View {
        VStack(spacing: 12) {
            devCashBar
            topBar
            commandPanel

            HStack(spacing: 10) {
                StatBadge(
                    imageName: "icon_clout",
                    title: "\(Int(game.state.availableClout)) CLOUT",
                    value: "+\(Int(game.state.availableClout * 2))% income · \(Int(game.state.spentClout)) invested",
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

            if game.milleBuffActive || game.viralBuffActive || game.cloutSurgeActive
                || game.equippedWristItem != nil || game.equippedGarageItem != nil
                || !game.state.equippedPerks.isEmpty { buffRow }
            if game.offlineEarnings > 0 { offlineBanner }
        }
        .padding(.horizontal, Theme.screenPadding)
        .padding(.top, 12)
        .padding(.bottom, 6)
    }

    private var devCashBar: some View {
        HStack(spacing: 8) {
            Text("DEV")
                .font(Theme.cartoonFont(9, weight: .black))
                .foregroundStyle(.orange)

            TextField("Amount", text: $devCashInput)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 140)
                .onSubmit { applyDevCash() }

            Button("Add $", action: applyDevCash)
                .font(Theme.cartoonFont(10, weight: .bold))
                .buttonStyle(PressableButtonStyle())

            ForEach([1_000.0, 10_000, 100_000, 1_000_000], id: \.self) { amount in
                Button(devCashLabel(amount)) { game.devAddCash(amount) }
                    .font(Theme.cartoonFont(9, weight: .bold))
                    .foregroundStyle(Theme.coinGreen)
                    .buttonStyle(PressableButtonStyle(bounce: false))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Theme.surfaceRaised.opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(.orange.opacity(0.45), lineWidth: 1)
        )
    }

    private func devCashLabel(_ amount: Double) -> String {
        switch amount {
        case 1_000_000: return "+1M"
        case 100_000: return "+100K"
        case 10_000: return "+10K"
        default: return "+1K"
        }
    }

    private func applyDevCash() {
        let cleaned = devCashInput
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "$", with: "")
            .trimmingCharacters(in: .whitespaces)
        guard let amount = Double(cleaned), amount > 0 else { return }
        game.devAddCash(amount)
        devCashInput = ""
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
            Text("CLOUT EMPIRE")
                .font(Theme.cartoonFont(18, weight: .black))
                .foregroundStyle(
                    LinearGradient(colors: [.white, Theme.champagne, Theme.cloutPink], startPoint: .top, endPoint: .bottom)
                )
                .shadow(color: Theme.cloutPink.opacity(0.50), radius: 8, y: 2)
        }
    }

    private var commandPanel: some View {
        VStack(spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("CASH STACK")
                        .font(Theme.cartoonFont(9, weight: .black))
                        .foregroundStyle(Theme.champagne.opacity(0.88))
                AnimatedMoney(value: game.state.cash)
                        .font(Theme.cartoonFont(42, weight: .black))
                        .foregroundStyle(
                            LinearGradient(colors: [.white, Theme.champagne, Theme.luxeGold], startPoint: .top, endPoint: .bottom)
                        )
                        .glow(Theme.luxeGold, radius: 8)
                        .minimumScaleFactor(0.50)
                        .lineLimit(1)
                        .rolls(with: game.state.cash)
                }
                Spacer(minLength: 0)
                VStack(spacing: 4) {
                    Text("AUTO")
                        .font(Theme.cartoonFont(8, weight: .black))
                        .foregroundStyle(.white.opacity(0.70))
                    Text("+\(money(game.incomePerSecond))/s")
                        .font(Theme.cartoonFont(13, weight: .black))
                        .monospacedDigit()
                        .minimumScaleFactor(0.55)
                        .lineLimit(1)
                }
                .foregroundStyle(Theme.coinGreen)
                .padding(.horizontal, 10)
                .padding(.vertical, 9)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.coinGreen.opacity(0.16)))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Theme.coinGreen.opacity(0.70), lineWidth: 2))
            }
            HStack {
                Text("\(money(game.state.lifetimeCash)) ALL-TIME FLEX")
                Spacer()
                Text("GET RICH QUICK")
            }
            .font(Theme.cartoonFont(9, weight: .black))
            .foregroundStyle(.white.opacity(0.58))
        }
        .padding(15)
        .background(alignment: .trailing) {
            Image(systemName: "sparkles")
                .font(.system(size: 92, weight: .black))
                .foregroundStyle(Theme.luxeGold.opacity(0.10))
                .rotationEffect(.degrees(-12))
                .offset(x: 16, y: -2)
        }
        .gameCard(highlighted: true, accent: Theme.luxeGold)
    }

    private var buffRow: some View {
        HStack(spacing: 8) {
            if let watch = game.equippedWristItem {
                buffPill("⌚ \(watch.boostText.uppercased())")
            }
            if let garage = game.equippedGarageItem {
                buffPill("🚗 \(garage.boostText.uppercased())")
            }
            ForEach(Array(game.activePerkBoostLabels.prefix(3)), id: \.self) { label in
                buffPill("✨ \(label.uppercased())")
            }
            if game.milleBuffActive { buffPill("MILLE ×2") }
            if game.viralBuffActive { buffPill("EARLY HYPE ×2") }
            if game.cloutSurgeActive {
                buffPill("SURGE ×2 · \(Int(game.cloutSurgeRemaining))s")
            }
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
