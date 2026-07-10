import SwiftUI

struct HeaderView: View {
    @EnvironmentObject var game: Game
    var onProfileTap: () -> Void = {}
    var onCloutTap: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var devCashInput = ""
    @State private var heroPop = false
    @State private var lastCash: Double = 0

    var body: some View {
        VStack(spacing: 10) {
            devCashBar
            topBar
            commandPanel

            HStack(spacing: 8) {
                cloutChip
                hypeChip
            }

            if game.milleBuffActive || game.viralBuffActive || game.cloutSurgeActive
                || game.equippedWristItem != nil || game.equippedGarageItem != nil
                || !game.state.equippedPerks.isEmpty { buffRow }
            if game.offlineEarnings > 0 { offlineBanner }
        }
        .padding(.horizontal, Theme.screenPadding)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }

    // MARK: Dev tools (quiet receipt strip)

    private var devCashBar: some View {
        HStack(spacing: 8) {
            Text("DEV")
                .font(Theme.mono(8, weight: .bold))
                .kerning(1)
                .foregroundStyle(Theme.textFaint)

            TextField("amount", text: $devCashInput)
                .textFieldStyle(.roundedBorder)
                .font(Theme.mono(9))
                .frame(maxWidth: 110)
                .onSubmit { applyDevCash() }

            Button("add", action: applyDevCash)
                .font(Theme.mono(9, weight: .bold))
                .buttonStyle(PressableButtonStyle(bounce: false))

            Spacer(minLength: 0)

            ForEach([1_000.0, 10_000, 100_000, 1_000_000], id: \.self) { amount in
                Button(devCashLabel(amount)) { game.devAddCash(amount) }
                    .font(Theme.mono(9, weight: .bold))
                    .foregroundStyle(Theme.textMuted)
                    .buttonStyle(PressableButtonStyle(bounce: false))
            }
        }
        .padding(.horizontal, 2)
        .padding(.bottom, 4)
        .overlay(alignment: .bottom) { Rectangle().fill(Theme.hairline).frame(height: 1) }
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

    // MARK: Identity row

    private var topBar: some View {
        HStack {
            if game.personaCreated {
                Button(action: onProfileTap) {
                    HStack(spacing: 8) {
                        GameImage(name: game.portraitImage, size: 32)
                            .clipShape(Circle())
                            .overlay(Circle().strokeBorder(game.theme.accent.opacity(0.8), lineWidth: 1.5))
                        VStack(alignment: .leading, spacing: 1) {
                            Text("@\(game.state.handle)")
                                .font(Theme.body(12, weight: .semibold))
                                .lineLimit(1)
                                .foregroundStyle(Theme.textPrimary)
                            Text("FOUNDER")
                                .font(Theme.mono(7.5, weight: .semibold))
                                .kerning(1)
                                .foregroundStyle(Theme.textFaint)
                        }
                    }
                }
                .buttonStyle(PressableButtonStyle())
            }
            Spacer()
            Text("DRIP EMPIRE")
                .font(Theme.display(19))
                .kerning(1.5)
                .foregroundStyle(Theme.textPrimary)
        }
    }

    // MARK: Hero — the Empire number owns the screen

    private var commandPanel: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline) {
                Text("EMPIRE VALUE").kicker()
                Spacer()
                Text("\(money(game.state.lifetimeCash)) ALL-TIME")
                    .font(Theme.mono(8.5))
                    .kerning(0.8)
                    .monospacedDigit()
                    .foregroundStyle(Theme.textFaint)
            }

            HStack(alignment: .lastTextBaseline, spacing: 12) {
                AnimatedMoney(value: game.state.cash)
                    .font(Theme.display(48))
                    .monospacedDigit()
                    .foregroundStyle(Theme.moneyGradient)
                    .shadow(color: Theme.moneyDeep.opacity(0.25), radius: 8, y: 2)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .rolls(with: game.state.cash)
                    .scaleEffect(heroPop ? 1.05 : 1, anchor: .bottomLeading)

                // Income docked tight to the number; green never lies about $0.
                Text(game.incomePerSecond > 0 ? "+\(money(game.incomePerSecond))/S" : "$0.00/S")
                    .font(Theme.mono(12, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(game.incomePerSecond > 0 ? Theme.go : Theme.textFaint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .gameCard()
        .onAppear { lastCash = game.state.cash }
        .onChange(of: game.state.cash) { newCash in
            // Big gains get a brief scale pop; the roll handles the rest.
            if !reduceMotion, newCash > lastCash * 1.06, newCash - lastCash > 1 {
                withAnimation(.spring(response: 0.22, dampingFraction: 0.5)) { heroPop = true }
                Task {
                    try? await Task.sleep(nanoseconds: 160_000_000)
                    await MainActor.run {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { heroPop = false }
                    }
                }
            }
            lastCash = newCash
        }
    }

    // MARK: Stat chips

    private var cloutChip: some View {
        let clout = Int(game.state.availableClout)
        return StatChip(
            imageName: "icon_clout",
            title: "\(clout) CLOUT",
            value: clout > 0
                ? "+\(clout * 2)% INCOME · \(Int(game.state.spentClout)) INVESTED"
                : "REBRAND TO EARN →",
            color: Theme.hype,
            action: onCloutTap
        )
        .help("Clout survives a Rebrand. Every point is +2% income, forever.")
    }

    private var hypeChip: some View {
        StatChip(
            imageName: "icon_hype",
            title: "HYPE ×\(Int(pow(2, Double(game.effectiveViralTier))))",
            value: "\(game.hustlesAtNextViralTier)/\(game.hustles.count) AT NEXT TIER",
            color: Theme.hypeSoft,
            progress: Double(game.hustlesAtNextViralTier) / Double(game.hustles.count)
        )
        .help("When every hustle reaches the next milestone tier, ALL income doubles.")
    }

    // MARK: Buffs & offline

    private var buffRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                if let watch = game.equippedWristItem {
                    buffPill(watch.boostText.uppercased())
                }
                if let garage = game.equippedGarageItem {
                    buffPill(garage.boostText.uppercased())
                }
                ForEach(Array(game.activePerkBoostLabels.prefix(3)), id: \.self) { label in
                    buffPill(label.uppercased())
                }
                if game.milleBuffActive { buffPill("MILLE ×2") }
                if game.viralBuffActive { buffPill("EARLY HYPE ×2") }
                if game.cloutSurgeActive {
                    buffPill("SURGE ×2 · \(Int(game.cloutSurgeRemaining))S")
                }
            }
        }
    }

    private func buffPill(_ text: String) -> some View {
        Text(text)
            .font(Theme.mono(8.5, weight: .bold))
            .kerning(0.5)
            .foregroundStyle(Theme.textMuted)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(Theme.surfaceRaised))
            .overlay(Capsule().strokeBorder(Theme.hairline, lineWidth: 1))
    }

    private var offlineBanner: some View {
        HStack {
            GameImage(name: "icon_sparkle", size: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text("Your plug kept working")
                    .font(Theme.body(11, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("+\(money(game.offlineEarnings)) while you were gone")
                    .font(Theme.mono(10, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(Theme.money)
            }
            Spacer()
            Button("Collect") { game.offlineEarnings = 0 }
                .font(Theme.body(11, weight: .bold))
                .foregroundStyle(Theme.go)
                .buttonStyle(.borderless)
        }
        .padding(12)
        .gameCard(highlighted: true, accent: Theme.money)
    }
}
