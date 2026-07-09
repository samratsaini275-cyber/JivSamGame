import SwiftUI

/// First-launch persona creation: handle, free base look, and your brand colorway.
/// No stats, no builds — the character IS the player.
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
            VStack(spacing: 16) {
                Text("Launch your label").kicker()

                Text(BaseLook.byID(look).emoji)
                    .font(.system(size: 52))
                    .glow(preview.accent.opacity(0.6), radius: 14)

                TextField("@yourbrand", text: $handle)
                    .textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .frame(width: 210)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Base look — free, the last free thing here").kicker()
                    HStack(spacing: 8) {
                        ForEach(BaseLook.all) { preset in
                            Button {
                                look = preset.id
                            } label: {
                                VStack(spacing: 2) {
                                    Text(preset.emoji).font(.system(size: 19))
                                    Text(preset.name).font(.system(size: 7.5, weight: .semibold))
                                }
                                .padding(7)
                                .luxCard(radius: 10, highlighted: look == preset.id, accent: preview.accent)
                            }
                            .buttonStyle(PressableButtonStyle(tint: preview.accent))
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Colorway — your whole aesthetic").kicker()
                    HStack(spacing: 10) {
                        ForEach(Colorway.all) { c in
                            Button {
                                withAnimation(.easeOut(duration: 0.3)) { colorway = c.id }
                            } label: {
                                VStack(spacing: 3) {
                                    Circle()
                                        .fill(c.gradient)
                                        .frame(width: 26, height: 26)
                                        .overlay(Circle().strokeBorder(.white.opacity(colorway == c.id ? 0.9 : 0.15),
                                                                       lineWidth: 2))
                                        .glow(colorway == c.id ? c.accent : .clear, radius: 6)
                                    Text(c.name).font(.system(size: 7.5, weight: .semibold))
                                        .foregroundStyle(colorway == c.id ? .primary : .secondary)
                                }
                            }
                            .buttonStyle(PressableButtonStyle(tint: c.accent))
                        }
                    }
                }

                Button {
                    game.createPersona(handle: handle, look: look, colorway: colorway)
                    dismiss()
                } label: {
                    Text("DROP THE BRAND")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .tracking(1.5)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(preview.gradient))
                        .foregroundStyle(Theme.bg)
                }
                .buttonStyle(PressableButtonStyle(tint: preview.accent))
                .disabled(handle.trimmingCharacters(in: .whitespaces).isEmpty)
                .glow(preview.accent.opacity(0.5), radius: 8)
            }
            .padding(24)
        }
        .frame(width: 350, height: 480)
        .preferredColorScheme(.dark)
        .interactiveDismissDisabled(!game.personaCreated)
    }
}

/// The profile screen: live portrait, handle, colorway switcher, and the closet.
/// Cosmetics survive Rebrand and (grail tier aside) never touch income.
struct PersonaView: View {
    @EnvironmentObject var game: Game
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Theme.backdrop(game.theme)
            VStack(spacing: 0) {
                profileHeader
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        colorwayRow
                        ForEach(PersonaSlot.allCases, id: \.rawValue) { slot in
                            slotSection(slot)
                        }
                        Text("Your fit survives Rebrand — labels get burned, you don't. This portrait is what the leaderboard will show next to your name.")
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(14)
                }
                Button("Done") { dismiss() }
                    .buttonStyle(.borderless)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(10)
            }
        }
        .frame(width: 370, height: 640)
        .preferredColorScheme(.dark)
    }

    private var profileHeader: some View {
        VStack(spacing: 5) {
            Text(game.portrait)
                .font(.system(size: 40))
                .glow(game.theme.accent.opacity(0.5), radius: 12)
            Text("@\(game.state.handle)")
                .font(.system(size: 15, weight: .black, design: .rounded))
                .metallic(game.theme)
            Text("✨ \(Int(game.state.clout)) lifetime Clout — your future leaderboard rank")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.secondary)
            if game.equippedGrailCount > 0 {
                Text("Grail drip: +\(String(format: "%.1f", Double(game.equippedGrailCount) * Formulas.grailRebrandBonusPerItem * 100))% Clout on Rebrand")
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundStyle(Theme.cloutPurple)
                    .glow(Theme.cloutPurple, radius: 4)
            }
        }
        .padding(.vertical, 14)
    }

    private var colorwayRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Brand colorway").kicker()
            HStack(spacing: 10) {
                ForEach(Colorway.all) { c in
                    Button {
                        withAnimation(.easeOut(duration: 0.3)) { game.setColorway(c.id) }
                    } label: {
                        Circle()
                            .fill(c.gradient)
                            .frame(width: 24, height: 24)
                            .overlay(Circle().strokeBorder(.white.opacity(game.state.colorway == c.id ? 0.9 : 0.15),
                                                           lineWidth: 2))
                            .glow(game.state.colorway == c.id ? c.accent : .clear, radius: 5)
                    }
                    .buttonStyle(PressableButtonStyle(tint: c.accent))
                    .help(c.name)
                }
                Spacer()
            }
        }
        .padding(11)
        .luxCard(radius: 13)
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
            Text(item.emoji)
                .font(.system(size: 18))
                .frame(width: 34, height: 34)
                .background(RoundedRectangle(cornerRadius: 10).fill(color.opacity(0.12)))
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(item.name).font(.system(size: 11, weight: .bold, design: .rounded))
                    Text(item.tierName.uppercased())
                        .font(.system(size: 7.5, weight: .heavy))
                        .padding(.horizontal, 5).padding(.vertical, 1.5)
                        .background(Capsule().fill(color.opacity(0.16)))
                        .foregroundStyle(color)
                        .glow(item.isGrail ? color : .clear, radius: 4)
                }
                Text(item.isGrail ? "+0.5% Clout on Rebrand · pure flex otherwise"
                                  : "Pure flex. Zero income effect.")
                    .font(.system(size: 9)).foregroundStyle(.tertiary)
            }
            Spacer(minLength: 4)
            actionButton(item, owned: owned, equipped: equipped, color: color)
        }
        .padding(11)
        .luxCard(radius: 13, highlighted: equipped, accent: color)
    }

    @ViewBuilder
    private func actionButton(_ item: PersonaItem, owned: Bool, equipped: Bool, color: Color) -> some View {
        if equipped {
            Text("WEARING")
                .font(.system(size: 8.5, weight: .heavy, design: .rounded))
                .foregroundStyle(color)
                .frame(width: 62)
        } else if owned {
            Button("WEAR") { game.equipCosmetic(item) }
                .font(.system(size: 8.5, weight: .heavy, design: .rounded))
                .buttonStyle(PressableButtonStyle(tint: color))
                .padding(.vertical, 6)
                .frame(width: 62)
                .background(Capsule().strokeBorder(color.opacity(0.4), lineWidth: 1))
                .foregroundStyle(color)
        } else {
            Button {
                game.buyCosmetic(item)
            } label: {
                VStack(spacing: 1) {
                    Text("COP IT").font(.system(size: 7.5, weight: .heavy))
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
