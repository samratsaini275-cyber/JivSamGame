import SwiftUI

struct RebrandView: View {
    @EnvironmentObject var game: Game
    @Environment(\.dismiss) private var dismiss
    var embedded: Bool = false

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
                    statRow("Current Clout", "\(Int(game.state.clout))")
                    if game.cloutGainRateBonus > 0 {
                        statRow("Flex bonus", "+\(String(format: "%.1f", game.cloutGainRateBonus * 100))%")
                    }
                    Divider().overlay(.white.opacity(0.10))
                    statRow("New income bonus", "+\(Int((game.state.clout + game.cloutOnRebrand) * 2))%", bold: true)
                }
                .padding(14)
                .gameCard()

                Text("Every hustle, cash, staff, and Rex's gear — gone. Your fit, handle, and Clout stay.")
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
