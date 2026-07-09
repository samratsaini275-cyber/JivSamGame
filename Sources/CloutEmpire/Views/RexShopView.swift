import SwiftUI

/// Rex Calloway's DMs — the upgrade shop. You fund his lifestyle; it boosts you back.
struct RexShopView: View {
    @EnvironmentObject var game: Game
    @Environment(\.dismiss) private var dismiss
    @State private var bark = Rex.greeting

    var body: some View {
        ZStack {
            Theme.backdrop(game.theme)
            VStack(spacing: 0) {
                rexHeader
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        slotSection(.wrist)
                        slotSection(.garage)
                        if game.state.daytonaPurchases > 0 {
                            Text("🕰️ Daytona legacy: +\(Int(Double(game.state.daytonaPurchases) * Formulas.daytonaGainRatePerPurchase * 100))% Clout gain rate, forever. Rex insists this was the plan.")
                                .font(.system(size: 9.5, weight: .semibold))
                                .foregroundStyle(Theme.cloutPurple)
                                .multilineTextAlignment(.center)
                        }
                        Text("All items are wiped on Rebrand. Rex will not discuss why the watches keep disappearing.")
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(14)
                }
                Button("Leave him on read") { dismiss() }
                    .buttonStyle(.borderless)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(10)
            }
        }
        .frame(width: 370, height: 640)
        .preferredColorScheme(.dark)
        .onAppear {
            game.markRexMet()
            if game.rexBestTier > 0 {
                bark = Rex.idleBark(wrist: game.equippedWristItem, garage: game.equippedGarageItem)
            }
        }
    }

    // MARK: Rex himself

    private var rexHeader: some View {
        let scene = Rex.scene(forBestTier: game.rexBestTier)
        return VStack(spacing: 8) {
            Text("REX CALLOWAY — \"THE WHALE\"")
                .kicker()
            Text(scene.emoji)
                .font(.system(size: 42))
                .glow(game.theme.accent.opacity(0.5), radius: 12)
            Text(scene.caption)
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
            Text("“\(bark)”")
                .font(.system(size: 12, weight: .medium, design: .rounded).italic())
                .multilineTextAlignment(.center)
                .padding(11)
                .frame(maxWidth: .infinity)
                .luxCard(radius: 14, highlighted: true, accent: .blue)
                .padding(.horizontal, 14)
        }
        .padding(.vertical, 14)
    }

    // MARK: Item slots

    private func slotSection(_ slot: ItemSlot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(slot == .wrist ? "⌚ Wrist" : "🚗 Garage").kicker()
            ForEach(RexItem.forSlot(slot)) { item in
                itemRow(item)
            }
        }
    }

    private func itemRow(_ item: RexItem) -> some View {
        let owned = game.owns(item)
        let equipped = game.isEquipped(item)
        let color = Theme.tierColor(item.tier)

        return HStack(alignment: .top, spacing: 10) {
            Text(item.emoji)
                .font(.system(size: 18))
                .frame(width: 34, height: 34)
                .background(RoundedRectangle(cornerRadius: 10).fill(color.opacity(0.12)))
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(item.name).font(.system(size: 11, weight: .bold, design: .rounded))
                    tierBadge(item.tierName, color: color, shimmer: item.tier == 4)
                }
                Text(item.blurb).font(.system(size: 9)).foregroundStyle(.tertiary)
                Text(item.boostText).font(.system(size: 9, weight: .semibold)).foregroundStyle(.secondary)
            }
            Spacer(minLength: 4)
            actionButton(item, owned: owned, equipped: equipped, color: color)
        }
        .padding(11)
        .luxCard(radius: 13, highlighted: equipped, accent: color)
    }

    private func tierBadge(_ name: String, color: Color, shimmer: Bool) -> some View {
        Text(name.uppercased())
            .font(.system(size: 7.5, weight: .heavy))
            .padding(.horizontal, 5).padding(.vertical, 1.5)
            .background(Capsule().fill(color.opacity(0.16)))
            .foregroundStyle(color)
            .glow(shimmer ? color : .clear, radius: 4)
    }

    @ViewBuilder
    private func actionButton(_ item: RexItem, owned: Bool, equipped: Bool, color: Color) -> some View {
        if equipped {
            Text("ON")
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .foregroundStyle(color)
                .frame(width: 62)
        } else if owned {
            Button("EQUIP") {
                let downgrade = item.tier < (item.slot == .wrist
                    ? game.equippedWristItem?.tier ?? 0
                    : game.equippedGarageItem?.tier ?? 0)
                game.equip(item)
                bark = downgrade ? Rex.downgradeBark : Rex.idleBark(wrist: game.equippedWristItem,
                                                                    garage: game.equippedGarageItem)
            }
            .font(.system(size: 8.5, weight: .heavy, design: .rounded))
            .buttonStyle(PressableButtonStyle(tint: color))
            .padding(.vertical, 6)
            .frame(width: 62)
            .background(Capsule().strokeBorder(color.opacity(0.4), lineWidth: 1))
            .foregroundStyle(color)
        } else {
            Button {
                bark = game.buyItem(item) ? Rex.purchaseBarks.randomElement()! : Rex.brokeBark
            } label: {
                VStack(spacing: 1) {
                    Text("PUT HIM ON").font(.system(size: 7.5, weight: .heavy))
                    Text(money(item.cost)).font(.system(size: 8.5, weight: .semibold)).monospacedDigit()
                }
                .frame(width: 62)
                .padding(.vertical, 5)
                .background(Capsule().fill(game.state.cash >= item.cost ? color.opacity(0.9) : Color.white.opacity(0.06)))
                .foregroundStyle(game.state.cash >= item.cost ? Theme.bg : Color.secondary)
            }
            .buttonStyle(PressableButtonStyle(tint: color))
            .disabled(game.state.cash < item.cost)
        }
    }
}
