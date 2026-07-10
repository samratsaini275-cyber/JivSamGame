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
            toast(image: "icon_hype", title: "HYPE WAVE",
                  subtitle: "Every hustle · all income ×\(Int(pow(2, Double(tier))))",
                  color: Theme.hype)
        case .rebranded(let clout):
            toast(image: "icon_sparkle", title: "REBRANDED",
                  subtitle: "+\(Int(clout)) Clout · long live the label",
                  color: Theme.hype)
        case .newDM(let dealer):
            toast(image: "tab_rex", title: "NEW DM",
                  subtitle: "\(dealer.badgeEmoji) \(dealer.title) · \(dealer.preview)",
                  color: Theme.hypeSoft)
        case .flexHit(let hype):
            toast(image: "icon_fire", title: "FLEX LANDED",
                  subtitle: "Hype ×\(String(format: "%g", hype)) · flex again to stack it",
                  color: Theme.hypeSoft)
        case .flexExposed(let line):
            toast(image: "tab_rex", title: "EXPOSED 💀",
                  subtitle: "\(line) Income halved — check your DMs.",
                  color: Theme.hype)
        case .flexSaved:
            toast(image: "icon_sparkle", title: "POST DELETED",
                  subtitle: "Your Reputation Manager handled it. You owe them one.",
                  color: Theme.textMuted)
        case .flexViral:
            toast(image: "icon_hype", title: "ACTUALLY WENT VIRAL",
                  subtitle: "The larp was too good · all income ×2 for 60s",
                  color: Theme.hype)
        case .payout:
            EmptyView()
        }
    }

    private func toast(image: String, title: String, subtitle: String, color: Color) -> some View {
        VStack(spacing: 6) {
            GameImage(name: image, size: 40)
            Text(title)
                .font(Theme.display(22))
                .kerning(1)
                .foregroundStyle(color)
            Text(subtitle)
                .font(Theme.mono(9.5))
                .foregroundStyle(Theme.textMuted)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 15)
        .gameCard(highlighted: true, accent: color)
        .glow(color, radius: 12)
    }
}

/// Screen-wide moment for Hype Waves and Rebrands: darken, spotlight, poster
/// callout with a scale pop. Never blocks input; lifetime managed by caller.
struct HypeTakeoverOverlay: View {
    let event: GameEvent
    @State private var landed = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
            RadialGradient(colors: [accent.opacity(0.20), .clear],
                           center: .center, startRadius: 20, endRadius: 320)

            VStack(spacing: 8) {
                Text(headline)
                    .font(Theme.display(40))
                    .kerning(2)
                    .foregroundStyle(Theme.textPrimary)
                    .shadow(color: accent.opacity(0.7), radius: 16)
                Text(payoffLine)
                    .font(Theme.display(26))
                    .kerning(1.5)
                    .monospacedDigit()
                    .foregroundStyle(accent)
                    .scaleEffect(landed ? 1 : 1.5)
                    .opacity(landed ? 1 : 0)
            }
            .scaleEffect(landed ? 1 : 0.92)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .transition(.opacity)
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.08)) {
                landed = true
            }
        }
    }

    private var accent: Color {
        Theme.hype
    }

    private var headline: String {
        switch event.kind {
        case .hypeWave: return "HYPE WAVE"
        case .rebranded: return "REBRANDED"
        default: return ""
        }
    }

    private var payoffLine: String {
        switch event.kind {
        case .hypeWave(let tier): return "ALL INCOME ×\(Int(pow(2, Double(tier))))"
        case .rebranded(let clout): return "+\(Int(clout)) CLOUT"
        default: return ""
        }
    }
}
