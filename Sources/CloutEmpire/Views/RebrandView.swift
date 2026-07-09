import SwiftUI

/// The prestige screen: a dark takeover. Burn the label, keep the Clout.
struct RebrandView: View {
    @EnvironmentObject var game: Game
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Theme.backdrop(game.theme)

            VStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("REBRAND")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .tracking(6)
                        .metallic(game.theme)
                    Text("Kill the label. Keep the Clout.")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 2) {
                    Text("+\(Int(game.cloutOnRebrand))")
                        .font(.system(size: 64, weight: .black, design: .rounded))
                        .foregroundStyle(Theme.cloutPurple)
                        .glow(Theme.cloutPurple, radius: 16)
                        .monospacedDigit()
                    Text("CLOUT ON RELAUNCH")
                        .kicker()
                }

                VStack(spacing: 8) {
                    statRow("Lifetime revenue", money(game.state.lifetimeCash))
                    statRow("Current Clout", "✨ \(Int(game.state.clout))")
                    if game.cloutGainRateBonus > 0 {
                        statRow("Flex bonus (Daytona + grail drip)",
                                "+\(String(format: "%.1f", game.cloutGainRateBonus * 100))%")
                    }
                    Divider().overlay(Color.white.opacity(0.1))
                    statRow("New permanent income bonus",
                            "+\(Int((game.state.clout + game.cloutOnRebrand) * 2))%")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                }
                .padding(14)
                .luxCard()

                Text("Every business, your Cash, staff, and Rex's rented gear — gone. Your wardrobe, handle, and Clout walk out untouched.")
                    .font(.system(size: 9.5))
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

                Button {
                    game.rebrand()
                    dismiss()
                } label: {
                    Text(game.cloutOnRebrand > 0
                         ? "BURN IT ALL DOWN"
                         : "NOT ENOUGH LIFETIME REVENUE YET")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .tracking(1.5)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(
                            Capsule().fill(
                                game.cloutOnRebrand > 0
                                ? AnyShapeStyle(LinearGradient(colors: [Theme.cloutPurple, Color(red: 0.85, green: 0.2, blue: 0.35)],
                                                               startPoint: .leading, endPoint: .trailing))
                                : AnyShapeStyle(Color.white.opacity(0.07))))
                        .foregroundStyle(game.cloutOnRebrand > 0 ? .white : .secondary)
                }
                .buttonStyle(PressableButtonStyle(tint: Theme.cloutPurple))
                .disabled(game.cloutOnRebrand <= 0)
                .glow(game.cloutOnRebrand > 0 ? Theme.cloutPurple : .clear, radius: 10)

                Button("Keep grinding") { dismiss() }
                    .buttonStyle(.borderless)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(26)
        }
        .frame(width: 350, height: 560)
        .preferredColorScheme(.dark)
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).monospacedDigit().foregroundStyle(.primary)
        }
        .font(.system(size: 11, weight: .semibold, design: .rounded))
    }
}
