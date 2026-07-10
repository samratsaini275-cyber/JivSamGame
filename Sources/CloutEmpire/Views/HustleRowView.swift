import SwiftUI

struct HustleRowView: View {
    @EnvironmentObject var game: Game
    let index: Int
    @State private var pop = false

    private var hustle: Hustle { game.hustles[index] }
    private var hState: HustleState { game.state.hustles[index] }
    private var owned: Bool { hState.unitsOwned > 0 }

    var body: some View {
        Group {
            if owned { ownedRow } else { lockedRow }
        }
        .scaleEffect(pop ? 1.04 : 1)
        .onChange(of: game.lastEvent) { event in
            guard case .payout(let i, _) = event?.kind, i == index else { return }
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { pop = true }
            Task {
                try? await Task.sleep(nanoseconds: 200_000_000)
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { pop = false }
            }
        }
    }

    private var lockedRow: some View {
        let affordable = game.state.cash >= hustle.baseCost
        return HStack(spacing: 14) {
            GameIconTile(name: hustle.imageName, size: 58, dimmed: true, tint: Theme.luxeGold)
            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 8) {
                    Text(hustle.name)
                        .font(Theme.cartoonFont(15, weight: .black))
                        .foregroundStyle(affordable ? .white : .white.opacity(0.50))
                        .lineLimit(1)
                    if affordable {
                        statusChip("OPENING", color: Theme.luxeGold)
                    }
                }
                Text(hustle.flavor)
                    .font(Theme.cartoonFont(10, weight: .medium))
                    .foregroundStyle(Theme.textMuted)
                    .lineLimit(2)
                Text("Initial launch cost \(money(hustle.baseCost))")
                    .font(Theme.cartoonFont(9, weight: .bold))
                    .foregroundStyle(affordable ? Theme.champagne : .white.opacity(0.35))
            }
            Spacer(minLength: 0)
            CartoonButton(
                title: "LAUNCH",
                subtitle: money(hustle.baseCost),
                color: Theme.luxeGold,
                colorway: affordable ? game.theme : nil,
                disabled: !affordable
            ) { game.buy(index) }
            .frame(width: 92)
        }
        .padding(14)
        .gameCard(highlighted: affordable, accent: Theme.luxeGold)
        .opacity(affordable ? 1 : 0.6)
    }

    private var ownedRow: some View {
        let tier = game.tier(of: index)
        let cycle = game.cycleTime(of: index)
        let units = hState.unitsOwned
        let next = Formulas.nextThreshold(units: units)
        let prev = Formulas.milestoneThresholds.last { units >= $0 } ?? 0
        let milestoneFrac = next.map { Double(units - prev) / Double($0 - prev) } ?? 1
        let barProgress: Double = {
            if hState.ghostwriterHired && cycle < 0.25 { return 1 }
            if hState.cycleRunning || (hState.ghostwriterHired && cycle >= 0.25) {
                return hState.cycleProgress / cycle
            }
            return milestoneFrac
        }()

        return VStack(spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                GameIconTile(name: hustle.imageName, size: 60, tint: Theme.luxeGold)
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 7) {
                        Text(hustle.name)
                            .font(Theme.cartoonFont(15, weight: .black))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        statusChip("HOLDING \(units)", color: Theme.luxeGold)
                    }
                    Text("\(followerCount(units)) · \(VerificationTier.name(for: tier))")
                        .font(Theme.cartoonFont(10, weight: .medium))
                        .foregroundStyle(Theme.textMuted)
                }
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: 3) {
                    Text(incomeText(cycle: cycle))
                        .font(Theme.cartoonFont(14, weight: .black))
                        .foregroundStyle(Theme.coinGreen)
                        .monospacedDigit()
                    Text(hState.ghostwriterHired ? "AUTO YIELD" : "MANUAL DROP")
                        .font(Theme.cartoonFont(8, weight: .bold))
                        .foregroundStyle(hState.ghostwriterHired ? Theme.coinGreen.opacity(0.75) : Theme.textMuted)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 7, style: .continuous).fill(Theme.ink.opacity(0.46)))
                .overlay(RoundedRectangle(cornerRadius: 7, style: .continuous).strokeBorder(Theme.coinGreen.opacity(0.18), lineWidth: 1))
            }

            revenueLane(progress: barProgress, units: units, next: next, active: hState.cycleRunning || hState.ghostwriterHired)

            actionRow
        }
        .padding(14)
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(LinearGradient(colors: [Theme.champagne, Theme.luxeGold], startPoint: .top, endPoint: .bottom))
                .frame(width: 3)
                .padding(.vertical, 12)
        }
        .gameCard(highlighted: pop, accent: pop ? Theme.coinGreen : Theme.luxeGold)
    }

    private func incomeText(cycle: Double) -> String {
        let upgrades = game.state.cloutUpgrades(for: index)
        if upgrades.publicistHired || hState.ghostwriterHired {
            return "\(money(game.incomePerCycle(of: index) / cycle))/s"
        }
        return money(game.incomePerCycle(of: index))
    }

    private var actionRow: some View {
        HStack(spacing: 8) {
            CartoonButton(
                title: buyLabel,
                subtitle: money(game.buyCost(for: index)),
                color: Theme.luxeGold,
                colorway: game.theme,
                disabled: game.state.cash < game.buyCost(for: index)
            ) { game.buy(index) }

            if !hState.ghostwriterHired {
                CartoonButton(
                    title: hState.cycleRunning ? "DROPPING…" : "DROP",
                    color: Theme.coinGreen,
                    style: .secondary,
                    disabled: hState.cycleRunning
                ) { game.post(index) }

                CartoonButton(
                    title: "HIRE",
                    subtitle: money(hustle.ghostwriterCost),
                    color: Theme.cloutPink,
                    style: .outline,
                    disabled: game.state.cash < hustle.ghostwriterCost
                ) { game.hireGhostwriter(index) }
            }
        }
    }

    private var buyLabel: String {
        switch game.buyMode {
        case .max: return "BUY ×\(game.buyCount(for: index))"
        default: return "BUY \(game.buyMode.rawValue)"
        }
    }

    private func statusChip(_ text: String, color: Color) -> some View {
        Text(text)
            .font(Theme.cartoonFont(8, weight: .black))
            .foregroundStyle(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(RoundedRectangle(cornerRadius: 5, style: .continuous).fill(color.opacity(0.12)))
            .overlay(RoundedRectangle(cornerRadius: 5, style: .continuous).strokeBorder(color.opacity(0.32), lineWidth: 1))
    }

    private func revenueLane(progress: Double, units: Int, next: Int?, active: Bool) -> some View {
        VStack(spacing: 7) {
            HStack {
                Text(active ? "PAYOUT CYCLE" : "NEXT PORTFOLIO TIER")
                    .font(Theme.cartoonFont(8, weight: .black))
                    .foregroundStyle(Theme.champagne.opacity(0.70))
                Spacer()
                Text(next.map { "\(units)/\($0)" } ?? "MAX")
                    .font(Theme.cartoonFont(9, weight: .bold))
                    .foregroundStyle(.white.opacity(0.62))
                    .monospacedDigit()
            }
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Theme.ink.opacity(0.72))
                    .frame(height: 26)
                    .overlay(RoundedRectangle(cornerRadius: 7, style: .continuous).strokeBorder(Theme.luxeGold.opacity(0.18), lineWidth: 1))
                GlowBar(progress: progress, color: active ? Theme.coinGreen : Theme.luxeGold, height: 20)
                    .padding(.horizontal, 3)
                HStack {
                    Text(active ? "CASHFLOW ONLINE" : "BUILDING MARKET HYPE")
                        .font(Theme.cartoonFont(10, weight: .black))
                        .foregroundStyle(active ? Theme.ink.opacity(0.86) : .white.opacity(0.78))
                    Spacer()
                }
                .padding(.horizontal, 12)
            }
        }
    }
}
