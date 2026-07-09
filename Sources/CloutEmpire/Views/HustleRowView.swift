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
        return HStack(spacing: 12) {
            GameIconTile(name: hustle.imageName, size: 54, dimmed: true, tint: game.theme.accent)
            VStack(alignment: .leading, spacing: 3) {
                Text(hustle.name)
                    .font(Theme.cartoonFont(14))
                    .foregroundStyle(affordable ? .white : .white.opacity(0.45))
                Text(hustle.flavor)
                    .font(Theme.cartoonFont(10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.45))
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
            CartoonButton(
                title: "UNLOCK",
                subtitle: money(hustle.baseCost),
                color: game.theme.accent,
                colorway: affordable ? game.theme : nil,
                disabled: !affordable
            ) { game.buy(index) }
            .frame(width: 88)
        }
        .padding(12)
        .gameCard(highlighted: affordable, accent: game.theme.accent)
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

        return VStack(spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                GameIconTile(name: hustle.imageName, size: 54, tint: game.theme.accent)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 5) {
                        Text(hustle.name).font(Theme.cartoonFont(14))
                        Text("Lv.\(units)")
                            .font(Theme.cartoonFont(9))
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(Capsule().fill(game.theme.accent.opacity(0.25)))
                            .foregroundStyle(game.theme.accent)
                    }
                    Text("\(followerCount(units)) · \(VerificationTier.name(for: tier))")
                        .font(Theme.cartoonFont(10, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))
                }
                Spacer(minLength: 0)
                Text(incomeText(cycle: cycle))
                    .font(Theme.cartoonFont(14, weight: .black))
                    .foregroundStyle(Theme.coinGreen)
                    .monospacedDigit()
            }

            HStack(spacing: 8) {
                GlowBar(progress: barProgress, color: Theme.coinGreen)
                Text(next.map { "\(units)/\($0)" } ?? "MAX")
                    .font(Theme.cartoonFont(9, weight: .bold))
                    .foregroundStyle(.white.opacity(0.45))
                    .monospacedDigit()
                    .frame(width: 44, alignment: .trailing)
            }

            actionRow
        }
        .padding(12)
        .gameCard(highlighted: pop, accent: Theme.coinGreen)
    }

    private func incomeText(cycle: Double) -> String {
        if hState.ghostwriterHired {
            return "\(money(game.incomePerCycle(of: index) / cycle))/s"
        }
        return money(game.incomePerCycle(of: index))
    }

    private var actionRow: some View {
        HStack(spacing: 6) {
            CartoonButton(
                title: buyLabel,
                subtitle: money(game.buyCost(for: index)),
                color: game.theme.accent,
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
}
