import SwiftUI

struct HustleRowView: View {
    @EnvironmentObject var game: Game
    let index: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pop = false
    @State private var bobbing = false

    private var hustle: Hustle { game.hustles[index] }
    private var hState: HustleState { game.state.hustles[index] }
    private var owned: Bool { hState.unitsOwned > 0 }

    var body: some View {
        Group {
            if owned { ownedRow } else { lockedRow }
        }
        .scaleEffect(pop ? 1.03 : 1)
        .onChange(of: game.lastEvent) { event in
            guard case .payout(let i, _) = event?.kind, i == index else { return }
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { pop = true }
            Task {
                try? await Task.sleep(nanoseconds: 200_000_000)
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { pop = false }
            }
        }
    }

    // MARK: Locked — merch in the window you can't have yet. Create want.

    private var lockedRow: some View {
        let progress = min(1, game.state.cash / hustle.baseCost)
        let affordable = progress >= 1
        let near = !affordable && progress >= 0.8

        return HStack(spacing: 12) {
            DisplayCase(imageName: hustle.imageName, size: 58, locked: true, spotlight: Theme.money)
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Theme.ink)
                        .padding(4)
                        .background(Circle().fill(Color.white.opacity(0.85)))
                        .offset(x: 4, y: 4)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(hustle.name.uppercased())
                    .font(Theme.display(15))
                    .kerning(0.4)
                    .foregroundStyle(.white.opacity(affordable ? 1 : 0.62))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(hustle.flavor)
                    .font(Theme.mono(8.5))
                    .foregroundStyle(Theme.textMuted)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 6) {
                    GlowBar(progress: progress, color: near || affordable ? Theme.money : Color(white: 0.5), height: 3)
                        .frame(maxWidth: 72)
                    Text(affordable ? "IN REACH" : "\(Int((progress * 100).rounded()))% THERE")
                        .font(Theme.mono(8, weight: .bold))
                        .kerning(0.6)
                        .monospacedDigit()
                        .foregroundStyle(affordable ? Theme.money : Theme.textFaint)
                }
            }
            Spacer(minLength: 0)
            CartoonButton(
                title: "UNLOCK",
                subtitle: money(hustle.baseCost),
                color: Theme.go,
                disabled: !affordable,
                progress: progress,
                emphasized: true
            ) { game.buy(index) }
            .frame(width: 92)
        }
        .padding(13)
        .gameCard(highlighted: affordable, accent: Theme.go)
        .overlay {
            if near, !reduceMotion {
                ShimmerSweep(period: 2.8)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
            }
        }
    }

    // MARK: Owned — spotlit product card

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

        return VStack(spacing: 8) {
            HStack(alignment: .center, spacing: 12) {
                DisplayCase(imageName: hustle.imageName, size: 58, spotlight: tierTint)
                    .offset(y: bobbing ? -1.5 : 1.5)
                    .overlay(alignment: .topTrailing) {
                        Text("×\(units)")
                            .font(Theme.mono(8.5, weight: .bold))
                            .monospacedDigit()
                            .foregroundStyle(Theme.textPrimary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Theme.ink.opacity(0.9)))
                            .overlay(Capsule().strokeBorder(tierTint.opacity(0.5), lineWidth: 1))
                            .offset(x: 6, y: -5)
                    }
                    .onAppear { startBobbing(cycle: cycle) }

                VStack(alignment: .leading, spacing: 3) {
                    Text(hustle.name.uppercased())
                        .font(Theme.display(16))
                        .kerning(0.4)
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text("\(followerCount(units).uppercased()) · \(VerificationTier.name(for: tier).uppercased())")
                        .font(Theme.mono(8.5))
                        .kerning(0.4)
                        .foregroundStyle(tier >= 2 ? tierTint.opacity(0.9) : Theme.textFaint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(incomeText(cycle: cycle))
                        .font(Theme.mono(13, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(Theme.go)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(hState.ghostwriterHired ? "AUTO" : "PER DROP")
                        .font(Theme.mono(7.5, weight: .semibold))
                        .kerning(0.8)
                        .foregroundStyle(Theme.textFaint)
                }
            }

            revenueLane(progress: barProgress, units: units, next: next,
                        active: hState.cycleRunning || hState.ghostwriterHired)

            actionRow
        }
        .padding(13)
        .gameCard()
    }

    private func startBobbing(cycle: Double) {
        guard !reduceMotion else { return }
        let period = min(3.0, max(1.2, cycle))
        withAnimation(.easeInOut(duration: period).repeatForever(autoreverses: true)) {
            bobbing = true
        }
    }

    private func incomeText(cycle: Double) -> String {
        let upgrades = game.state.cloutUpgrades(for: index)
        if upgrades.publicistHired || hState.ghostwriterHired {
            return "+\(money(game.incomePerCycle(of: index) / cycle))/S"
        }
        return money(game.incomePerCycle(of: index))
    }

    // Right side of the card is the action zone: COP lives there; manual
    // controls (DROP/HIRE) sit to its left until automation takes over.
    private var actionRow: some View {
        let cost = game.buyCost(for: index)
        let affordable = game.state.cash >= cost
        return HStack(spacing: 8) {
            if !hState.ghostwriterHired {
                CartoonButton(
                    title: hState.cycleRunning ? "DROPPING…" : "DROP",
                    color: Theme.go,
                    style: .secondary,
                    disabled: hState.cycleRunning
                ) { game.post(index) }

                CartoonButton(
                    title: "HIRE",
                    subtitle: money(hustle.ghostwriterCost),
                    color: Theme.textMuted,
                    style: .outline,
                    disabled: game.state.cash < hustle.ghostwriterCost
                ) { game.hireGhostwriter(index) }
            } else {
                // Automated: the staff hire holds down the left of the zone.
                Text("\(hustle.ghostwriterName.uppercased()) ON DUTY")
                    .font(Theme.mono(8, weight: .semibold))
                    .kerning(0.8)
                    .foregroundStyle(Theme.textFaint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            CartoonButton(
                title: buyLabel,
                subtitle: money(cost),
                color: Theme.go,
                disabled: !affordable,
                progress: min(1, game.state.cash / max(cost, 0.01)),
                emphasized: true
            ) { game.buy(index) }
            .frame(width: hState.ghostwriterHired ? 140 : nil)
        }
    }

    private var buyLabel: String {
        switch game.buyMode {
        case .max: return "COP ×\(game.buyCount(for: index))"
        default: return "COP \(game.buyMode.rawValue)"
        }
    }

    private func revenueLane(progress: Double, units: Int, next: Int?, active: Bool) -> some View {
        HStack(spacing: 10) {
            GlowBar(progress: progress, color: active ? Theme.go : tierTint, height: 6)
            Text(next.map { "\(units)/\($0)" } ?? "MAX")
                .font(Theme.mono(8.5, weight: .bold))
                .foregroundStyle(Theme.textFaint)
                .monospacedDigit()
                .fixedSize()
        }
    }

    private var tierTint: Color {
        Theme.tierColor(game.tier(of: index))
    }
}

// MARK: - Display case: product art in a lit showroom well

struct DisplayCase: View {
    let imageName: String
    var size: CGFloat = 58
    var locked: Bool = false
    var spotlight: Color = .white

    var body: some View {
        GameImage(name: imageName, size: size * 0.76)
            .saturation(locked ? 0.5 : 1)
            .opacity(locked ? 0.7 : 1)
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(Theme.ink.opacity(0.55))
                    .overlay(
                        // Soft spotlight falling from above onto the product.
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .fill(
                                RadialGradient(
                                    colors: [spotlight.opacity(locked ? 0.10 : 0.22), .clear],
                                    center: .init(x: 0.5, y: 0.05),
                                    startRadius: 1, endRadius: size * 0.95
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .strokeBorder(Theme.hairline, lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.35), radius: 7, y: 4)
    }
}
