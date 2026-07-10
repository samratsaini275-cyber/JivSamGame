import SwiftUI

struct PersonaCreationView: View {
    @EnvironmentObject var game: Game
    @Environment(\.dismiss) private var dismiss
    @State private var handle = ""
    @State private var look = BaseLook.all[0].id
    @State private var colorway = Colorway.all[0].id

    private var preview: Colorway { Colorway.byID(colorway) }

    var body: some View {
        ZStack {
            Theme.backdrop(preview)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    Text("Launch Your Label").gameTitle(preview)

                    GameImage(name: BaseLook.byID(look).imageName, size: 88)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(preview.accent.opacity(0.7), lineWidth: 2))

                    TextField("@yourbrand", text: $handle)
                        .multilineTextAlignment(.center)
                        .font(Theme.cartoonFont(14, weight: .bold))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 14)
                        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Theme.ink.opacity(0.52)))
                        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(preview.accent.opacity(0.35), lineWidth: 1))

                    lookPicker
                    colorwayPicker

                    CartoonButton(
                        title: "DROP THE BRAND",
                        color: preview.accent,
                        colorway: preview,
                        disabled: handle.trimmingCharacters(in: .whitespaces).isEmpty
                    ) {
                        game.createPersona(handle: handle, look: look, colorway: colorway)
                        dismiss()
                    }
                }
                .padding(22)
            }
        }
        .frame(width: 390, height: 620)
        .preferredColorScheme(.dark)
        .interactiveDismissDisabled(!game.personaCreated)
    }

    private var lookPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pick your vibe").kicker()
            HStack(spacing: 8) {
                ForEach(BaseLook.all) { preset in
                    Button { look = preset.id } label: {
                        VStack(spacing: 4) {
                            GameImage(name: preset.imageName, size: 40)
                            Text(preset.name)
                                .font(Theme.cartoonFont(8, weight: .semibold))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .gameCard(highlighted: look == preset.id, accent: preview.accent)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
        }
    }

    private var colorwayPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your aesthetic").kicker()
            HStack(spacing: 10) {
                ForEach(Colorway.all) { c in
                    Button { colorway = c.id } label: {
                        Circle()
                            .fill(c.gradient)
                            .frame(width: 30, height: 30)
                            .overlay(Circle().strokeBorder(.white.opacity(colorway == c.id ? 0.9 : 0.2), lineWidth: 2))
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
        }
    }
}

struct PersonaView: View {
    @EnvironmentObject var game: Game
    var embedded: Bool = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                profileHero
                colorwayRow
                if !game.hasFitItems {
                    emptyFitCard
                }
                ForEach(ItemSlot.allCases, id: \.self) { slot in
                    fitSection(slot)
                }
                Text("Dealer gear stays on Rebrand. DM threads reset — dealers remember the vibe.")
                    .font(Theme.cartoonFont(9, weight: .medium))
                    .foregroundStyle(.white.opacity(0.35))
                    .multilineTextAlignment(.center)
            }
            .padding(Theme.screenPadding)
            .padding(.top, embedded ? 8 : 0)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var profileHero: some View {
        VStack(spacing: 8) {
            GameImage(name: game.portraitImage, size: 80)
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(game.theme.accent.opacity(0.75), lineWidth: 2))
            Text("@\(game.state.handle)")
                .font(Theme.cartoonFont(18, weight: .black))
                .foregroundStyle(game.theme.gradient)
            HStack(spacing: 6) {
                GameImage(name: "icon_clout", size: 22)
                Text("\(Int(game.state.clout)) lifetime Clout")
                    .font(Theme.cartoonFont(11, weight: .semibold))
                    .foregroundStyle(Theme.textMuted)
            }
            if let watch = game.equippedWristItem {
                Text("On wrist: \(watch.name)")
                    .font(Theme.cartoonFont(10, weight: .heavy))
                    .foregroundStyle(Theme.tierColor(watch.tier))
            }
            if let garage = game.equippedGarageItem {
                Text("In garage: \(garage.name)")
                    .font(Theme.cartoonFont(10, weight: .heavy))
                    .foregroundStyle(Theme.tierColor(garage.tier))
            }
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .gameCard(highlighted: true, accent: game.theme.accent)
    }

    private var emptyFitCard: some View {
        VStack(spacing: 10) {
            GameImage(name: "tab_rex", size: 52)
            Text("No flex yet")
                .font(Theme.cartoonFont(15, weight: .black))
            Text("Your dealers don't hand out free samples. Unlock hustles, open DMs, and buy in.")
                .font(Theme.cartoonFont(11, weight: .medium))
                .foregroundStyle(Theme.textMuted)
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .gameCard()
    }

    private var colorwayRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Brand colorway").kicker()
            HStack(spacing: 10) {
                ForEach(Colorway.all) { c in
                    Button { game.setColorway(c.id) } label: {
                        Circle()
                            .fill(c.gradient)
                            .frame(width: 28, height: 28)
                            .overlay(Circle().strokeBorder(.white.opacity(game.state.colorway == c.id ? 0.9 : 0.2), lineWidth: 2))
                    }
                    .buttonStyle(PressableButtonStyle())
                }
                Spacer()
            }
        }
        .padding(12)
        .gameCard()
    }

    private func fitSection(_ slot: ItemSlot) -> some View {
        let items = game.ownedRexItems(for: slot)
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(slot.fitLabel).kicker()
                if slot == .perk {
                    Text("\(game.state.equippedPerks.count)/\(RexItem.maxEquippedPerks) active")
                        .font(Theme.cartoonFont(9, weight: .bold))
                        .foregroundStyle(Theme.textMuted)
                }
                Spacer()
            }
            if items.isEmpty {
                Text(slot.emptyHint)
                    .font(Theme.cartoonFont(10, weight: .medium))
                    .foregroundStyle(Theme.textMuted)
                    .padding(.horizontal, 4)
            } else {
                ForEach(items) { item in
                    fitItemRow(item)
                }
            }
        }
    }

    private func fitItemRow(_ item: RexItem) -> some View {
        let equipped = game.isEquipped(item)
        let color = Theme.tierColor(item.tier)

        return HStack(spacing: 12) {
            GameIconTile(name: item.imageName, size: 50, tint: color)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 5) {
                    Text(item.name).font(Theme.cartoonFont(13, weight: .black))
                    Text(item.tierName.uppercased())
                        .font(Theme.cartoonFont(8, weight: .bold))
                        .foregroundStyle(color)
                }
                Text(item.boostText)
                    .font(Theme.cartoonFont(9, weight: .medium))
                    .foregroundStyle(Theme.textMuted)
                if let dealer = item.dealer {
                    Text("via \(dealer.title)")
                        .font(Theme.cartoonFont(8, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.35))
                }
            }
            Spacer(minLength: 0)
            fitAction(item, equipped: equipped, color: color)
        }
        .padding(12)
        .gameCard(highlighted: equipped, accent: color)
    }

    @ViewBuilder
    private func fitAction(_ item: RexItem, equipped: Bool, color: Color) -> some View {
        switch item.slot {
        case .perk:
            if equipped {
                Button("STASH") { game.unequip(item) }
                    .font(Theme.cartoonFont(9, weight: .bold))
                    .foregroundStyle(Theme.textMuted)
                    .buttonStyle(PressableButtonStyle())
                    .frame(width: 62)
            } else if game.canEquipPerk(item) {
                Button("WEAR") { game.equip(item) }
                    .font(Theme.cartoonFont(9, weight: .bold))
                    .foregroundStyle(color)
                    .buttonStyle(PressableButtonStyle())
                    .frame(width: 62)
            } else {
                Text("FULL")
                    .font(Theme.cartoonFont(9, weight: .black))
                    .foregroundStyle(.white.opacity(0.35))
                    .frame(width: 62)
                    .help("Only \(RexItem.maxEquippedPerks) bag perks can be active at once")
            }
        default:
            if equipped {
                Text("ACTIVE")
                    .font(Theme.cartoonFont(9, weight: .black))
                    .foregroundStyle(color)
                    .frame(width: 62)
            } else {
                Button("WEAR") { game.equip(item) }
                    .font(Theme.cartoonFont(9, weight: .bold))
                    .foregroundStyle(color)
                    .buttonStyle(PressableButtonStyle())
                    .frame(width: 62)
            }
        }
    }
}
