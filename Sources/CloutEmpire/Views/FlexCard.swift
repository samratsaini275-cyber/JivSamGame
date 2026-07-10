import SwiftUI

/// The push-your-luck posting card: Sus Meter, Hype streak, and the flex button.
struct FlexCard: View {
    @EnvironmentObject var game: Game
    @State private var showingSheet = false

    var body: some View {
        if game.flexUnlocked {
            TimelineView(.periodic(from: .now, by: 0.25)) { _ in
                card
            }
            .sheet(isPresented: $showingSheet) {
                FlexSheet().environmentObject(game)
            }
        }
    }

    private var heatFraction: Double { game.state.flexHeat / Flex.maxHeat }

    private var heatColor: Color {
        switch heatFraction {
        case ..<0.34: return Theme.go
        case ..<0.67: return Theme.hypeSoft
        default: return Theme.hype
        }
    }

    private var card: some View {
        let mood = Flex.mood(heatFraction: heatFraction)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("THE FEED").kicker()
                Spacer()
                Text("SUS METER \(mood.emoji)")
                    .font(Theme.mono(8.5, weight: .bold))
                    .kerning(0.6)
                    .foregroundStyle(heatColor)
            }

            GlowBar(progress: heatFraction, color: heatColor, height: 5)

            statusLine

            HStack(spacing: 10) {
                // Quiet at rest; demands attention only while a streak is live.
                CartoonButton(
                    title: buttonTitle,
                    color: Theme.hype,
                    style: game.hypeActive ? .primary : .secondary,
                    disabled: !game.canFlexNow,
                    emphasized: game.hypeActive
                ) {
                    showingSheet = true
                }
                if game.state.repManagerCharges > 0 {
                    Text("🧯")
                        .help("Reputation Manager on retainer — your next exposure gets deleted.")
                }
            }
        }
        .padding(12)
        .gameCard(highlighted: game.hypeActive || game.isExposed, accent: Theme.hype)
    }

    @ViewBuilder
    private var statusLine: some View {
        if game.isExposed {
            Text("RATIO'D — INCOME ×\(String(format: "%g", Flex.exposureIncomeMultiplier)) FOR \(countdown(game.exposureRemaining))")
                .font(Theme.mono(9, weight: .bold))
                .kerning(0.4)
                .foregroundStyle(Theme.hype)
        } else if game.hypeActive {
            Text("HYPE ×\(String(format: "%g", game.currentHype)) — FLEX IN \(countdown(game.hypeRemaining)) OR LOSE THE STREAK")
                .font(Theme.mono(9, weight: .bold))
                .kerning(0.4)
                .foregroundStyle(Theme.hypeSoft)
        } else {
            Text(Flex.mood(heatFraction: heatFraction).line)
                .font(Theme.mono(9))
                .foregroundStyle(Theme.textMuted)
        }
    }

    private var buttonTitle: String {
        if game.isExposed { return "LAY LOW (\(countdown(game.exposureRemaining)))" }
        if game.flexCooldownRemaining > 0 { return "POSTING… (\(countdown(game.flexCooldownRemaining)))" }
        return "POST A FLEX"
    }

    private func countdown(_ t: TimeInterval) -> String {
        "\(max(1, Int(t.rounded(.up))))s"
    }
}

/// Pick your stake: three flex tiers with live odds and receipts breakdown.
struct FlexSheet: View {
    @EnvironmentObject var game: Game
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 14) {
            VStack(spacing: 4) {
                Text("POST A FLEX")
                    .font(Theme.display(22))
                    .kerning(1)
                    .foregroundStyle(Theme.textPrimary)
                Text("Bigger flex, bigger Hype — and a bigger target on your back.")
                    .font(Theme.mono(9))
                    .foregroundStyle(Theme.textMuted)
            }

            ForEach(FlexTier.allCases) { tier in
                tierRow(tier)
            }

            Button("Never mind") { dismiss() }
                .font(Theme.cartoonFont(10, weight: .bold))
                .foregroundStyle(Theme.textMuted)
                .buttonStyle(PressableButtonStyle(bounce: false))
        }
        .padding(18)
        .frame(width: 340)
        .background(Theme.surface)
    }

    private func tierRow(_ tier: FlexTier) -> some View {
        let chance = game.flexExposureChance(for: tier)
        let riskPct = Int((chance * 100).rounded())
        let factors = game.flexRiskFactors(for: tier)

        return Button {
            game.postFlex(tier)
            dismiss()
        } label: {
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline) {
                    Text(tier.name)
                        .font(Theme.cartoonFont(13, weight: .heavy))
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(riskPct)% risk")
                        .font(Theme.cartoonFont(11, weight: .black))
                        .foregroundStyle(riskColor(chance))
                }
                Text(tier.flavor)
                    .font(Theme.cartoonFont(9, weight: .medium))
                    .foregroundStyle(Theme.textMuted)
                Text("+\(String(format: "%g", tier.hypeGain))× Hype · +\(Int(tier.heat)) heat")
                    .font(Theme.cartoonFont(9, weight: .bold))
                    .foregroundStyle(Theme.luxeGold.opacity(0.85))
                ForEach(factors) { factor in
                    Text("\(factor.delta < 0 ? "▼" : "▲") \(factor.label) \(deltaLabel(factor.delta))")
                        .font(Theme.cartoonFont(8, weight: .semibold))
                        .foregroundStyle(factor.delta < 0 ? Theme.coinGreen : Theme.cloutPink)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [riskColor(chance).opacity(0.10), Theme.surfaceRaised],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!game.canFlexNow)
    }

    private func riskColor(_ chance: Double) -> Color {
        switch chance {
        case ..<0.15: return Theme.go
        case ..<0.35: return Theme.hypeSoft
        default: return Theme.hype
        }
    }

    private func deltaLabel(_ delta: Double) -> String {
        let pts = Int((abs(delta) * 100).rounded())
        return "\(delta < 0 ? "−" : "+")\(pts)%"
    }
}
