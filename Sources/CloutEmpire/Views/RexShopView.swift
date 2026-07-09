import SwiftUI

struct RexShopView: View {
    @EnvironmentObject var game: Game
    @Environment(\.dismiss) private var dismiss
    var embedded: Bool = false
    @State private var bark = Rex.greeting

    var body: some View {
        VStack(spacing: 0) {
            if !embedded { sheetHeader("Rex Calloway") }
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    rexHero
                    slotSection(.wrist)
                    slotSection(.garage)
                    if game.state.daytonaPurchases > 0 {
                        Text("Daytona legacy: +\(Int(Double(game.state.daytonaPurchases) * Formulas.daytonaGainRatePerPurchase * 100))% Clout — forever.")
                            .font(Theme.cartoonFont(10, weight: .semibold))
                            .foregroundStyle(Theme.cloutPink)
                            .multilineTextAlignment(.center)
                            .padding(12)
                            .gameCard(accent: Theme.cloutPink)
                    }
                    Text("All gear wipes on Rebrand.")
                        .font(Theme.cartoonFont(9, weight: .medium))
                        .foregroundStyle(.white.opacity(0.35))
                        .multilineTextAlignment(.center)
                }
                .padding(Theme.screenPadding)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { refreshBark() }
    }

    private var rexHero: some View {
        let scene = Rex.scene(forBestTier: game.rexBestTier)
        return VStack(spacing: 8) {
            Text("REX CALLOWAY").kicker()
            GameImage(name: scene.imageName, size: 80)
            Text(scene.caption)
                .font(Theme.cartoonFont(10, weight: .medium))
                .foregroundStyle(.white.opacity(0.45))
            Text("“\(bark)”")
                .font(Theme.cartoonFont(12, weight: .medium).italic())
                .multilineTextAlignment(.center)
                .padding(12)
                .frame(maxWidth: .infinity)
                .gameCard(highlighted: true, accent: Theme.hypeBlue)
        }
    }

    private func slotSection(_ slot: ItemSlot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(slot.rawValue).kicker()
            ForEach(RexItem.forSlot(slot)) { item in
                itemRow(item)
            }
        }
    }

    private func itemRow(_ item: RexItem) -> some View {
        let owned = game.owns(item)
        let equipped = game.isEquipped(item)
        let color = Theme.tierColor(item.tier)

        return HStack(spacing: 10) {
            GameIconTile(name: item.imageName, size: 48, tint: color)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text(item.name).font(Theme.cartoonFont(12))
                    Text(item.tierName.uppercased())
                        .font(Theme.cartoonFont(8))
                        .foregroundStyle(color)
                }
                Text(item.boostText)
                    .font(Theme.cartoonFont(10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.55))
            }
            Spacer(minLength: 0)
            itemAction(item, owned: owned, equipped: equipped, color: color)
        }
        .padding(12)
        .gameCard(highlighted: equipped, accent: color)
    }

    @ViewBuilder
    private func itemAction(_ item: RexItem, owned: Bool, equipped: Bool, color: Color) -> some View {
        if equipped {
            Text("ON").font(Theme.cartoonFont(10)).foregroundStyle(color).frame(width: 64)
        } else if owned {
            Button("EQUIP") {
                let prev = item.slot == .wrist ? game.equippedWristItem?.tier ?? 0 : game.equippedGarageItem?.tier ?? 0
                game.equip(item)
                bark = item.tier < prev ? Rex.downgradeBark
                    : Rex.idleBark(wrist: game.equippedWristItem, garage: game.equippedGarageItem)
            }
            .font(Theme.cartoonFont(9))
            .foregroundStyle(color)
            .buttonStyle(PressableButtonStyle())
            .frame(width: 64)
        } else {
            CartoonButton(title: "PUT ON", subtitle: money(item.cost), color: color,
                          disabled: game.state.cash < item.cost) {
                bark = game.buyItem(item) ? Rex.purchaseBarks.randomElement()! : Rex.brokeBark
            }
            .frame(width: 68)
        }
    }

    private func refreshBark() {
        game.markRexMet()
        if game.rexBestTier > 0 {
            bark = Rex.idleBark(wrist: game.equippedWristItem, garage: game.equippedGarageItem)
        }
    }

    private func sheetHeader(_ title: String) -> some View {
        HStack {
            Text(title).kicker()
            Spacer()
            Button("Done") { dismiss() }
                .font(Theme.cartoonFont(12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(.horizontal, Theme.screenPadding)
        .padding(.top, 12)
    }
}
