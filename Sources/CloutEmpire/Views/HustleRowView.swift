import SwiftUI

/// One business card: icon tile, level badge, hype tier, income, glowing bars,
/// buy/staff buttons, and a glow flare whenever it pays out.
struct HustleRowView: View {
    @EnvironmentObject var game: Game
    let index: Int
    @State private var flare = false

    private var hustle: Hustle { game.hustles[index] }
    private var hState: HustleState { game.state.hustles[index] }
    private var owned: Bool { hState.unitsOwned > 0 }

    var body: some View {
        Group {
            if owned {
                ownedCard
            } else {
                lockedCard
            }
        }
        .onChange(of: game.lastEvent) { event in
            guard case .payout(let i, _) = event?.kind, i == index else { return }
            withAnimation(.easeOut(duration: 0.12)) { flare = true }
            Task {
                try? await Task.sleep(nanoseconds: 260_000_000)
                withAnimation(.easeOut(duration: 0.4)) { flare = false }
            }
        }
    }

    // MARK: Locked (silhouette)

    private var lockedCard: some View {
        let affordable = game.state.cash >= hustle.baseCost
        return HStack(spacing: 12) {
            iconTile(dimmed: true)
            VStack(alignment: .leading, spacing: 2) {
                Text(hustle.name)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(affordable ? .primary : .secondary)
                Text(hustle.flavor)
                    .font(.system(size: 9.5))
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
            }
            Spacer()
            Button {
                game.buy(index)
            } label: {
                VStack(spacing: 1) {
                    Text("UNLOCK").font(.system(size: 9, weight: .heavy, design: .rounded))
                    Text(money(hustle.baseCost)).font(.system(size: 9, weight: .semibold)).monospacedDigit()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Capsule().fill(affordable ? AnyShapeStyle(game.theme.gradient)
                                                      : AnyShapeStyle(Color.white.opacity(0.07))))
                .foregroundStyle(affordable ? Theme.bg : Color.secondary)
            }
            .buttonStyle(PressableButtonStyle(tint: game.theme.accent))
            .disabled(!affordable)
        }
        .padding(12)
        .luxCard(highlighted: affordable, accent: game.theme.accent)
        .opacity(affordable ? 1 : 0.65)
    }

    // MARK: Owned

    private var ownedCard: some View {
        let tier = game.tier(of: index)
        let cycle = game.cycleTime(of: index)
        let continuous = hState.ghostwriterHired && cycle < 0.25

        return VStack(spacing: 9) {
            HStack(alignment: .top, spacing: 10) {
                iconTile(dimmed: false)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(hustle.name)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                        Text("LV.\(hState.unitsOwned)")
                            .font(.system(size: 8, weight: .heavy, design: .rounded))
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(Capsule().fill(game.theme.accent.opacity(0.16)))
                            .foregroundStyle(game.theme.accent)
                    }
                    Text(VerificationTier.name(for: tier))
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(tier > 0 ? Theme.tierColor(min(tier, 4)) : Color.secondary.opacity(0.6))
                }

                Spacer(minLength: 4)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(continuous ? "\(money(game.incomePerCycle(of: index) / cycle))/s"
                                    : "\(money(game.incomePerCycle(of: index)))")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(Theme.moneyGreen)
                        .monospacedDigit()
                    Text(hState.ghostwriterHired ? "staffed" : "hands-on")
                        .font(.system(size: 8.5, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
            }

            if continuous {
                GlowBar(progress: 1, color: Theme.moneyGreen, height: 5)
                    .opacity(0.8)
            } else {
                GlowBar(progress: hState.cycleProgress / cycle, color: Theme.moneyGreen, height: 5)
            }

            milestoneBar

            HStack(spacing: 8) {
                if !hState.ghostwriterHired {
                    capsuleButton(hState.cycleRunning ? "DROPPING…" : "DROP",
                                  sub: nil, tint: Theme.moneyGreen,
                                  filled: false, disabled: hState.cycleRunning) {
                        game.post(index)
                    }
                }

                capsuleButton("BUY \(game.buyMode == .max ? "×\(game.buyCount(for: index))" : game.buyMode.rawValue)",
                              sub: money(game.buyCost(for: index)), tint: game.theme.accent,
                              filled: true, disabled: game.state.cash < game.buyCost(for: index)) {
                    game.buy(index)
                }

                if !hState.ghostwriterHired {
                    capsuleButton("HIRE \(hustle.ghostwriterName.uppercased())",
                                  sub: money(hustle.ghostwriterCost), tint: Theme.cloutPurple,
                                  filled: false, disabled: game.state.cash < hustle.ghostwriterCost) {
                        game.hireGhostwriter(index)
                    }
                }
            }
        }
        .padding(12)
        .luxCard(highlighted: flare, accent: Theme.moneyGreen)
        .scaleEffect(flare ? 1.012 : 1)
    }

    // MARK: Pieces

    private func iconTile(dimmed: Bool) -> some View {
        Text(hustle.emoji)
            .font(.system(size: 20))
            .grayscale(dimmed ? 1 : 0)
            .frame(width: 42, height: 42)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(dimmed ? AnyShapeStyle(Color.white.opacity(0.05))
                                 : AnyShapeStyle(game.theme.gradient.opacity(0.22)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(dimmed ? Color.white.opacity(0.08)
                                         : game.theme.accent.opacity(0.4), lineWidth: 1)
            )
    }

    private var milestoneBar: some View {
        let units = hState.unitsOwned
        let next = Formulas.nextThreshold(units: units)
        let prev = Formulas.milestoneThresholds.last { units >= $0 } ?? 0
        let fraction: Double = next.map { Double(units - prev) / Double($0 - prev) } ?? 1
        let tier = game.tier(of: index)

        return HStack(spacing: 8) {
            GlowBar(progress: fraction, color: Theme.tierColor(min(tier + 1, 4)), height: 4)
            Text(next.map { "\(units)/\($0)" } ?? "MAXED")
                .font(.system(size: 8.5, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.tertiary)
                .frame(width: 52, alignment: .trailing)
        }
    }

    private func capsuleButton(_ title: String, sub: String?, tint: Color,
                               filled: Bool, disabled: Bool,
                               action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 1) {
                Text(title)
                    .font(.system(size: 8.5, weight: .heavy, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if let sub {
                    Text(sub).font(.system(size: 8.5, weight: .semibold)).monospacedDigit()
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background {
                if filled {
                    Capsule().fill(tint.opacity(disabled ? 0.15 : 1))
                    if !disabled { Capsule().fill(LinearGradient(colors: [.white.opacity(0.25), .clear], startPoint: .top, endPoint: .bottom)) }
                } else {
                    Capsule().fill(tint.opacity(0.12))
                    Capsule().strokeBorder(tint.opacity(disabled ? 0.15 : 0.45), lineWidth: 1)
                }
            }
            .foregroundStyle(filled ? (disabled ? Color.secondary : Theme.bg)
                                    : (disabled ? Color.secondary : tint))
        }
        .buttonStyle(PressableButtonStyle(tint: tint))
        .disabled(disabled)
    }
}
