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
        VStack(alignment: .leading, spacing: 14) {
            Text("CLOUT STORE")
                .font(Theme.cartoonFont(11, weight: .black))
                .foregroundStyle(Theme.champagne)

            Text("Spend available Clout on permanent hustle upgrades or a short income burst. Every point you spend leaves your passive +2%/point income bonus — that's the trade.")
                .font(Theme.cartoonFont(10, weight: .medium))
                .foregroundStyle(Theme.textMuted)
                .fixedSize(horizontal: false, vertical: true)

            upgradeExplainer(
                title: "Publicist",
                icon: "megaphone.fill",
                body: "One per hustle, forever. Reframes that hustle's income as cash/sec on the main screen, and permanently cuts its next buy price by 10%. Survives Rebrand.",
                costNote: "5% of available Clout"
            )

            upgradeExplainer(
                title: "Cost-Cut Shard",
                icon: "scissors",
                body: "Slows how fast that hustle's unit price scales (1.14× → 1.12× per owned unit, per shard). Stack up to 2 shards per hustle. Survives Rebrand.",
                costNote: "10% of available Clout each"
            )

            Divider().overlay(.white.opacity(0.08))

            surgeRow

            Divider().overlay(.white.opacity(0.08))

            Text("Pick a hustle")
                .font(Theme.cartoonFont(10, weight: .bold))
                .foregroundStyle(Theme.champagne.opacity(0.85))

            ForEach(game.hustles.indices, id: \.self) { index in
                hustleCloutRow(index)
            }
        }
        .padding(14)
        .gameCard(accent: Theme.cloutPink)
    }

    private func upgradeExplainer(title: String, icon: String, body: String, costNote: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.cloutPink)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Theme.cloutPink.opacity(0.12)))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(Theme.cartoonFont(11, weight: .heavy))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(costNote)
                        .font(Theme.cartoonFont(8, weight: .bold))
                        .foregroundStyle(Theme.champagne.opacity(0.7))
                }
                Text(body)
                    .font(Theme.cartoonFont(9, weight: .medium))
                    .foregroundStyle(Theme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Theme.surface.opacity(0.45)))
    }

    private var surgeRow: some View {
        let cost = game.cloutPurchaseCost(type: .oneTimeSurge)
        let canBuy = game.canPurchaseClout(type: .oneTimeSurge)
        return HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("One-Time Surge")
                    .font(Theme.cartoonFont(12, weight: .heavy))
                Text("Temporary — 2× income on every hustle for 60 seconds. Does not survive Rebrand. Always costs 15% of whatever Clout you still have available right now.")
                    .font(Theme.cartoonFont(9, weight: .medium))
                    .foregroundStyle(Theme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Current price: \(cost) Clout")
                    .font(Theme.cartoonFont(9, weight: .bold))
                    .foregroundStyle(Theme.coinGreen.opacity(0.85))
            }
            Spacer(minLength: 8)
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
        let growth = game.costGrowth(for: index)
        let growthPct = Int((growth * 100).rounded())

        return VStack(alignment: .leading, spacing: 10) {
            Text(hustle.name)
                .font(Theme.cartoonFont(12, weight: .heavy))
                .foregroundStyle(.white)

            hustleUpgradeRow(
                title: "Publicist",
                detail: hasPub
                    ? "Hired — income shows as /sec, buys are 10% cheaper here."
                    : "Hire to show /sec income and shave 10% off future buys for this hustle only.",
                status: hasPub ? "OWNED" : "\(pubCost) Clout",
                enabled: !hasPub && game.canPurchaseClout(type: .publicist, hustleIndex: index)
            ) {
                attemptPurchase(type: .publicist, hustleIndex: index)
            }

            hustleUpgradeRow(
                title: "Cost-Cut Shard",
                detail: shards >= maxShards
                    ? "Maxed — cost curve is \(growthPct)% per unit (2 shards applied)."
                    : "Shard \(shards + 1)/\(maxShards): softens the 1.14× scaling to \(growthPct)% after purchase.",
                status: shards >= maxShards ? "MAX" : "\(shardCost) Clout",
                enabled: shards < maxShards && game.canPurchaseClout(type: .costCutShard, hustleIndex: index)
            ) {
                attemptPurchase(type: .costCutShard, hustleIndex: index)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Theme.surface.opacity(0.35)))
    }

    private func hustleUpgradeRow(
        title: String,
        detail: String,
        status: String,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(Theme.cartoonFont(10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
                Text(detail)
                    .font(Theme.cartoonFont(8, weight: .medium))
                    .foregroundStyle(Theme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 4)
            Button(status, action: action)
                .font(Theme.cartoonFont(9, weight: .bold))
                .foregroundStyle(enabled ? Theme.coinGreen : Theme.textMuted)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(enabled ? Theme.coinGreen.opacity(0.12) : Theme.surface.opacity(0.5)))
                .overlay(Capsule().strokeBorder(enabled ? Theme.coinGreen.opacity(0.35) : Theme.comicBorder.opacity(0.2), lineWidth: 1))
                .buttonStyle(PressableButtonStyle(bounce: false))
                .disabled(!enabled)
        }
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
