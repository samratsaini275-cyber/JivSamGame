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
                    Text("Launch your label").gameTitle(preview)

                    GameImage(name: BaseLook.byID(look).imageName, size: 88)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(Theme.comicBorder, lineWidth: Theme.comicStroke))

                    TextField("@yourbrand", text: $handle)
                        .multilineTextAlignment(.center)
                        .font(Theme.cartoonFont(14, weight: .semibold))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 14)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.surface))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Theme.comicBorder, lineWidth: Theme.comicStroke))

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
                ForEach(PersonaSlot.allCases, id: \.rawValue) { slot in
                    slotSection(slot)
                }
                Text("Your fit survives Rebrand — labels get burned, you don't.")
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
                .overlay(Circle().strokeBorder(game.theme.accent.opacity(0.6), lineWidth: 3))
            Text("@\(game.state.handle)")
                .font(Theme.cartoonFont(18, weight: .black))
                .foregroundStyle(game.theme.gradient)
            HStack(spacing: 6) {
                GameImage(name: "icon_clout", size: 22)
                Text("\(Int(game.state.clout)) lifetime Clout")
                    .font(Theme.cartoonFont(11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.5))
            }
            if game.equippedGrailCount > 0 {
                Text("Grail drip: +\(String(format: "%.1f", Double(game.equippedGrailCount) * Formulas.grailRebrandBonusPerItem * 100))% on Rebrand")
                    .font(Theme.cartoonFont(10, weight: .heavy))
                    .foregroundStyle(Theme.cloutPink)
            }
        }
        .padding(.vertical, 8)
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

    private func slotSection(_ slot: PersonaSlot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(slot.rawValue).kicker()
            ForEach(PersonaItem.forSlot(slot)) { item in
                itemRow(item)
            }
        }
    }

    private func itemRow(_ item: PersonaItem) -> some View {
        let owned = game.owns(item)
        let equipped = game.isEquipped(item)
        let color = Theme.tierColor(item.tier)

        return HStack(spacing: 10) {
            GameIconTile(name: item.imageName, size: 46, tint: color)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text(item.name).font(Theme.cartoonFont(12))
                    Text(item.tierName.uppercased())
                        .font(Theme.cartoonFont(8))
                        .foregroundStyle(color)
                }
                Text(item.isGrail ? "+0.5% Clout on Rebrand · pure flex" : "Pure flex · zero income")
                    .font(Theme.cartoonFont(9, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
            }
            Spacer(minLength: 0)
            personaAction(item, owned: owned, equipped: equipped, color: color)
        }
        .padding(12)
        .gameCard(highlighted: equipped, accent: color)
    }

    @ViewBuilder
    private func personaAction(_ item: PersonaItem, owned: Bool, equipped: Bool, color: Color) -> some View {
        if equipped {
            Text("WEARING").font(Theme.cartoonFont(9)).foregroundStyle(color).frame(width: 62)
        } else if owned {
            Button("WEAR") { game.equipCosmetic(item) }
                .font(Theme.cartoonFont(9))
                .foregroundStyle(color)
                .buttonStyle(PressableButtonStyle())
                .frame(width: 62)
        } else {
            CartoonButton(title: "COP IT", subtitle: money(item.cost), color: color,
                          disabled: game.state.cash < item.cost) {
                game.buyCosmetic(item)
            }
            .frame(width: 66)
        }
    }
}
