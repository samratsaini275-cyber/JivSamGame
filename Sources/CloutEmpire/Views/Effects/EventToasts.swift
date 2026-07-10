import SwiftUI

struct EventToast: View {
    let event: GameEvent
    let colorway: Colorway

    var body: some View {
        switch event.kind {
        case .milestone(let index, let tier):
            toast(image: "icon_fire", title: VerificationTier.name(for: tier).uppercased(),
                  subtitle: "\(Hustle.all[index].name) · income ×2 · speed ×2",
                  color: Theme.tierColor(min(tier, 4)))
        case .hypeWave(let tier):
            toast(image: "icon_hype", title: "HYPE WAVE!",
                  subtitle: "Every hustle · all income ×\(Int(pow(2, Double(tier))))",
                  color: Theme.hypeBlue)
        case .rebranded(let clout):
            toast(image: "icon_sparkle", title: "REBRANDED!",
                  subtitle: "+\(Int(clout)) Clout · long live the label",
                  color: Theme.cloutPink)
        case .newDM(let dealer):
            let color: Color = {
                switch dealer.accentName {
                case "cloutPink": return Theme.cloutPink
                case "coinGreen": return Theme.coinGreen
                case "luxeGold": return Theme.luxeGold
                case "champagne": return Theme.champagne
                default: return Theme.hypeBlue
                }
            }()
            toast(image: "tab_rex", title: "NEW DM",
                  subtitle: "\(dealer.badgeEmoji) \(dealer.title) · \(dealer.preview)",
                  color: color)
        case .flexHit(let hype):
            toast(image: "icon_fire", title: "FLEX LANDED",
                  subtitle: "Hype ×\(String(format: "%g", hype)) · flex again to stack it",
                  color: Theme.luxeGold)
        case .flexExposed(let line):
            toast(image: "tab_rex", title: "EXPOSED 💀",
                  subtitle: "\(line) Income halved — check your DMs.",
                  color: Theme.cloutPink)
        case .flexSaved:
            toast(image: "icon_sparkle", title: "POST DELETED",
                  subtitle: "Your Reputation Manager handled it. You owe them one.",
                  color: Theme.champagne)
        case .flexViral:
            toast(image: "icon_hype", title: "ACTUALLY WENT VIRAL",
                  subtitle: "The larp was too good · all income ×2 for 60s",
                  color: Theme.hypeBlue)
        case .payout:
            EmptyView()
        }
    }

    private func toast(image: String, title: String, subtitle: String, color: Color) -> some View {
        VStack(spacing: 6) {
            GameImage(name: image, size: 44)
            Text(title)
                .font(Theme.cartoonFont(17, weight: .black))
                .foregroundStyle(color)
            Text(subtitle)
                .font(Theme.cartoonFont(11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 16)
        .gameCard(highlighted: true, accent: color)
        .glow(color, radius: 10)
    }
}
