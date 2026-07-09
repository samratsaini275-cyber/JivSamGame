import SwiftUI

/// Center-screen milestone popup + full-width Hype Wave banner.
/// ContentView feeds it the latest GameEvent; it springs in and auto-dismisses.
struct EventToast: View {
    let event: GameEvent
    let colorway: Colorway

    var body: some View {
        switch event.kind {
        case .milestone(let index, let tier):
            VStack(spacing: 4) {
                Text("🔥 \(VerificationTier.name(for: tier).uppercased())")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.tierColor(min(tier, 4)))
                    .glow(Theme.tierColor(min(tier, 4)), radius: 6)
                Text("\(Hustle.all[index].name) · income ×2 · speed ×2")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            .luxCard(highlighted: true, accent: Theme.tierColor(min(tier, 4)))

        case .hypeWave(let tier):
            HStack(spacing: 10) {
                Text("🌊")
                    .font(.title2)
                VStack(alignment: .leading, spacing: 1) {
                    Text("HYPE WAVE")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .metallic(colorway)
                    Text("Every line is moving — all income ×\(Int(pow(2, Double(tier))))")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .luxCard(highlighted: true, accent: Theme.hypeOrange)
            .glow(Theme.hypeOrange, radius: 10)

        case .rebranded(let clout):
            VStack(spacing: 4) {
                Text("✨ REBRANDED")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.cloutPurple)
                    .glow(Theme.cloutPurple, radius: 8)
                Text("+\(Int(clout)) Clout · the label is dead, long live the label")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .luxCard(highlighted: true, accent: Theme.cloutPurple)

        case .payout:
            EmptyView() // payouts are particles, not toasts
        }
    }
}
