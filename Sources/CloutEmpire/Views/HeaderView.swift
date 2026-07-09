import SwiftUI

struct HeaderView: View {
    @EnvironmentObject var game: Game
    var onProfileTap: () -> Void = {}
    @State private var buffPulse = false

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Text("DRIP EMPIRE")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .tracking(6)
                    .metallic(game.theme)
                    .glow(game.theme.accent, radius: 5)
                if game.personaCreated {
                    HStack {
                        profileChip
                        Spacer()
                    }
                }
            }

            VStack(spacing: 2) {
                AnimatedMoney(value: game.state.cash)
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .glow(Theme.moneyGreen.opacity(0.6), radius: 10)
                    .rolls(with: game.state.cash)

                Text("+\(money(game.incomePerSecond))/sec · \(money(game.state.lifetimeCash)) lifetime")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            HStack(spacing: 10) {
                cloutPill
                hypeWavePill
            }

            if game.milleBuffActive || game.viralBuffActive {
                buffBadges
            }

            if game.offlineEarnings > 0 {
                offlineBanner
            }
        }
        .padding(.top, 14)
        .padding(.horizontal, 14)
    }

    // MARK: Pieces

    private var profileChip: some View {
        Button(action: onProfileTap) {
            HStack(spacing: 4) {
                Text(game.portrait).font(.system(size: 11))
                Text("@\(game.state.handle)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(Capsule().fill(.ultraThinMaterial))
            .overlay(Capsule().strokeBorder(game.theme.accent.opacity(0.35), lineWidth: 1))
        }
        .buttonStyle(PressableButtonStyle(tint: game.theme.accent))
    }

    private var cloutPill: some View {
        HStack(spacing: 6) {
            Text("✨").font(.system(size: 12))
            VStack(alignment: .leading, spacing: 0) {
                Text("\(Int(game.state.clout)) CLOUT")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.cloutPurple)
                Text("+\(Int(game.state.clout * 2))% forever")
                    .font(.system(size: 8.5, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 6)
        .luxCard(radius: 14, highlighted: game.state.clout > 0, accent: Theme.cloutPurple)
    }

    private var hypeWavePill: some View {
        let total = game.hustles.count
        let ready = game.hustlesAtNextViralTier
        let tier = game.viralTier
        return HStack(spacing: 7) {
            ZStack {
                Circle().stroke(Theme.hypeOrange.opacity(0.18), lineWidth: 3.5)
                Circle()
                    .trim(from: 0, to: CGFloat(ready) / CGFloat(total))
                    .stroke(Theme.hypeOrange, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .glow(Theme.hypeOrange, radius: 3)
                Text("🌊").font(.system(size: 9))
            }
            .frame(width: 26, height: 26)
            .animation(.spring(response: 0.5), value: ready)

            VStack(alignment: .leading, spacing: 0) {
                Text("HYPE ×\(Int(pow(2, Double(game.effectiveViralTier))))")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.hypeOrange)
                Text("\(ready)/\(total) at \(VerificationTier.name(for: tier + 1))")
                    .font(.system(size: 8.5, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 6)
        .luxCard(radius: 14, highlighted: tier > 0 || game.viralBuffActive, accent: Theme.hypeOrange)
    }

    private var buffBadges: some View {
        HStack(spacing: 8) {
            if game.milleBuffActive {
                buffBadge("💠 MILLE FLEX ×2", color: game.theme.accent)
            }
            if game.viralBuffActive {
                buffBadge("🟡 EARLY HYPE WAVE ×2", color: Theme.hypeOrange)
            }
        }
        .scaleEffect(buffPulse ? 1.04 : 1)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                buffPulse = true
            }
        }
    }

    private func buffBadge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .heavy, design: .rounded))
            .foregroundStyle(color)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(Capsule().fill(color.opacity(0.14)))
            .overlay(Capsule().strokeBorder(color.opacity(0.45), lineWidth: 1))
            .glow(color, radius: 5)
    }

    private var offlineBanner: some View {
        HStack {
            Text("💤 The plug kept working: \(money(game.offlineEarnings)) while you were gone.")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
            Spacer()
            Button("OK") { game.offlineEarnings = 0 }
                .font(.system(size: 10, weight: .bold))
                .buttonStyle(.borderless)
                .foregroundStyle(Theme.moneyGreen)
        }
        .padding(10)
        .luxCard(radius: 12, highlighted: true, accent: Theme.moneyGreen)
    }
}
