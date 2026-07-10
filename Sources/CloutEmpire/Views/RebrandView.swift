import SwiftUI

struct RebrandView: View {
    @EnvironmentObject var game: Game
    @Environment(\.dismiss) private var dismiss
    var embedded: Bool = false

    @State private var pendingPurchase: PendingCloutPurchase?
    @State private var showConfirm = false

    private struct PendingCloutPurchase {
        let type: CloutPurchase
        let hustleIndex: Int?
    }

    private var rebrandColorway: Colorway {
        Colorway(id: "rebrand", name: "", accent: Theme.cloutPink,
                 accentDeep: Color(red: 0.75, green: 0.15, blue: 0.55))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                VStack(spacing: 7) {
                    Text("REBRAND").gameTitle(game.theme)
                    Text("Kill the label. Keep the Clout.")
                        .font(Theme.cartoonFont(12, weight: .semibold))
                        .foregroundStyle(Theme.textMuted)
                }
                .padding(.top, embedded ? 8 : 0)

                VStack(spacing: 6) {
                    GameImage(name: "icon_clout", size: 56)
                    Text("+\(Int(game.cloutOnRebrand))")
                        .font(Theme.cartoonFont(52, weight: .black))
                        .foregroundStyle(Theme.cloutPink)
                        .glow(Theme.cloutPink, radius: 12)
                        .monospacedDigit()
                    Text("CLOUT ON RELAUNCH").kicker()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .gameCard(highlighted: game.cloutOnRebrand > 0, accent: Theme.cloutPink)

                VStack(spacing: 10) {
                    statRow("Lifetime revenue", money(game.state.lifetimeCash))
                    statRow("Available Clout", "\(Int(game.state.availableClout))", bold: true)
                    statRow("Clout invested", "\(Int(game.state.spentClout))")
                    statRow("Income bonus", "+\(Int(game.state.availableClout * 2))%")
                    if game.cloutGainRateBonus > 0 {
                        statRow("Flex bonus", "+\(String(format: "%.1f", game.cloutGainRateBonus * 100))%")
                    }
                    Divider().overlay(.white.opacity(0.10))
                    statRow("After Rebrand bonus", "+\(Int((game.state.availableClout + game.cloutOnRebrand) * 2))%", bold: true)
                }
                .padding(14)
                .gameCard()

                cloutStoreSection

                Text("Every hustle, cash, and staff — gone. Your fit, handle, Clout upgrades, and dealer gear stay.")
                    .font(Theme.cartoonFont(10, weight: .medium))
                    .foregroundStyle(Theme.textMuted)
                    .multilineTextAlignment(.center)

                CartoonButton(
                    title: game.cloutOnRebrand > 0 ? "BURN IT ALL DOWN" : "NOT ENOUGH CLOUT YET",
                    color: Theme.cloutPink,
                    colorway: game.cloutOnRebrand > 0 ? rebrandColorway : nil,
                    disabled: game.cloutOnRebrand <= 0
                ) {
                    game.rebrand()
                    if !embedded { dismiss() }
                }
            }
            .padding(Theme.screenPadding)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert("Spend Clout?", isPresented: $showConfirm) {
            Button("Cancel", role: .cancel) { pendingPurchase = nil }
            Button("Spend anyway") {
                if let pending = pendingPurchase {
                    game.purchaseClout(type: pending.type, hustleIndex: pending.hustleIndex)
                }
                pendingPurchase = nil
            }
        } message: {
            if let pending = pendingPurchase {
                let cost = game.cloutPurchaseCost(type: pending.type, hustleIndex: pending.hustleIndex)
                let loss = game.permanentIncomeLossPercent(forCloutCost: cost)
                Text("This will cost you \(cost) Clout — permanently −\(loss)% income. Spend anyway?")
            }
        }
    }

    private var cloutStoreSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CLOUT STORE")
                .font(Theme.cartoonFont(11, weight: .black))
                .foregroundStyle(Theme.champagne)

            surgeRow

            Divider().overlay(.white.opacity(0.08))

            Text("Per hustle — spendable Clout only")
                .font(Theme.cartoonFont(9, weight: .medium))
                .foregroundStyle(Theme.textMuted)

            ForEach(game.hustles.indices, id: \.self) { index in
                hustleCloutRow(index)
            }
        }
        .padding(14)
        .gameCard(accent: Theme.cloutPink)
    }

    private var surgeRow: some View {
        let cost = game.cloutPurchaseCost(type: .oneTimeSurge)
        let canBuy = game.canPurchaseClout(type: .oneTimeSurge)
        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("One-Time Surge")
                    .font(Theme.cartoonFont(12, weight: .heavy))
                Text("2× income all hustles · 60s · \(cost) Clout (15%)")
                    .font(Theme.cartoonFont(9, weight: .medium))
                    .foregroundStyle(Theme.textMuted)
            }
            Spacer()
            Button(canBuy ? "BUY" : "—") {
                attemptPurchase(type: .oneTimeSurge)
            }
            .font(Theme.cartoonFont(10, weight: .bold))
            .foregroundStyle(canBuy ? Theme.coinGreen : Theme.textMuted)
            .disabled(!canBuy)
            .buttonStyle(PressableButtonStyle(bounce: false))
        }
    }

    private func hustleCloutRow(_ index: Int) -> some View {
        let hustle = game.hustles[index]
        let pubCost = game.cloutPurchaseCost(type: .publicist, hustleIndex: index)
        let shardCost = game.cloutPurchaseCost(type: .costCutShard, hustleIndex: index)
        let hasPub = game.hasPublicist(for: index)
        let shards = game.costCutShards(for: index)
        let maxShards = CloutStore.maxCostCutShardsPerHustle

        return VStack(alignment: .leading, spacing: 8) {
            Text(hustle.name)
                .font(Theme.cartoonFont(11, weight: .bold))
                .foregroundStyle(.white.opacity(0.85))

            HStack(spacing: 8) {
                cloutMiniButton(
                    title: hasPub ? "Publicist ✓" : "Publicist \(pubCost)",
                    enabled: !hasPub && game.canPurchaseClout(type: .publicist, hustleIndex: index)
                ) {
                    attemptPurchase(type: .publicist, hustleIndex: index)
                }

                cloutMiniButton(
                    title: shards >= maxShards ? "Shard ✓×\(maxShards)" : "Shard \(shardCost) (\(shards)/\(maxShards))",
                    enabled: shards < maxShards && game.canPurchaseClout(type: .costCutShard, hustleIndex: index)
                ) {
                    attemptPurchase(type: .costCutShard, hustleIndex: index)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func cloutMiniButton(title: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(Theme.cartoonFont(9, weight: .bold))
                .foregroundStyle(enabled ? .white : Theme.textMuted)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(enabled ? Theme.surfaceRaised : Theme.surface.opacity(0.5)))
                .overlay(Capsule().strokeBorder(Theme.comicBorder.opacity(enabled ? 0.6 : 0.25), lineWidth: 1))
        }
        .buttonStyle(PressableButtonStyle(bounce: false))
        .disabled(!enabled)
    }

    private func attemptPurchase(type: CloutPurchase, hustleIndex: Int? = nil) {
        guard game.canPurchaseClout(type: type, hustleIndex: hustleIndex) else { return }
        if game.cloutPurchaseNeedsConfirmation(type: type, hustleIndex: hustleIndex) {
            pendingPurchase = PendingCloutPurchase(type: type, hustleIndex: hustleIndex)
            showConfirm = true
        } else {
            game.purchaseClout(type: type, hustleIndex: hustleIndex)
        }
    }

    private func statRow(_ label: String, _ value: String, bold: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(Theme.cartoonFont(12, weight: .medium))
                .foregroundStyle(Theme.textMuted)
            Spacer()
            Text(value)
                .font(Theme.cartoonFont(12, weight: bold ? .heavy : .semibold))
                .monospacedDigit()
        }
    }
}
