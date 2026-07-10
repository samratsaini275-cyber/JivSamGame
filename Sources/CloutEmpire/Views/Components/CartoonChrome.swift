import SwiftUI

// MARK: - Button system
// One primary (go fill, ink text), one secondary (tinted), one disabled (quiet
// well that shows progress toward affordability). The screen tells you "you can
// buy something" without reading a number: ≥80% shimmer, affordable pulse.

struct CartoonButton: View {
    let title: String
    var subtitle: String? = nil
    var color: Color
    var colorway: Colorway? = nil // legacy param; identity accents no longer paint buttons
    var style: Style = .primary
    var disabled: Bool = false
    /// 0…1 progress toward affording this action; drives the disabled-state
    /// inner fill and the ≥80% "almost affordable" shimmer.
    var progress: Double? = nil
    /// Gentle pulse when enabled — for buy/unlock moments, not every button.
    var emphasized: Bool = false
    let action: () -> Void

    enum Style { case primary, secondary, outline }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulsing = false

    private var nearlyAffordable: Bool {
        disabled && (progress ?? 0) >= 0.8
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: subtitle == nil ? 0 : 1) {
                Text(title)
                    .font(Theme.body(12, weight: .heavy))
                    .kerning(0.3)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if let subtitle {
                    Text(subtitle)
                        .font(Theme.mono(9, weight: .semibold))
                        .monospacedDigit()
                        .opacity(0.85)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .frame(maxWidth: .infinity, minHeight: subtitle == nil ? 20 : 30)
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .foregroundStyle(foreground)
            .background { face }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                if nearlyAffordable, !reduceMotion {
                    ShimmerSweep(period: 2.8)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: 1)
            )
            .shadow(color: shadowColor, radius: 10, y: 5)
        }
        .buttonStyle(CartoonPressStyle())
        .disabled(disabled)
        .onAppear { startPulseIfNeeded() }
        .onChange(of: disabled) { _ in startPulseIfNeeded() }
    }

    private func startPulseIfNeeded() {
        guard emphasized, !disabled, !reduceMotion else { pulsing = false; return }
        pulsing = false
        withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
            pulsing = true
        }
    }

    @ViewBuilder private var face: some View {
        switch style {
        case .primary:
            if disabled {
                ZStack(alignment: .leading) {
                    Theme.ink.opacity(0.45)
                    // Quiet progress toward affording it.
                    if let progress, progress > 0.02 {
                        GeometryReader { geo in
                            Rectangle()
                                .fill((nearlyAffordable ? Theme.money : Color.white)
                                    .opacity(nearlyAffordable ? 0.14 : 0.07))
                                .frame(width: geo.size.width * min(1, progress))
                        }
                    }
                }
            } else {
                // Confirm fill: the passed color (go by default, hype for the
                // flex moment) deepened toward the bottom.
                ZStack {
                    color
                    LinearGradient(colors: [.white.opacity(0.12), .clear, .black.opacity(0.30)],
                                   startPoint: .top, endPoint: .bottom)
                }
            }
        case .secondary:
            (disabled ? Theme.ink.opacity(0.4) : color.opacity(0.16))
        case .outline:
            (disabled ? Theme.ink.opacity(0.35) : Theme.ink.opacity(0.5))
        }
    }

    private var foreground: Color {
        if disabled {
            return nearlyAffordable ? Theme.textPrimary.opacity(0.8) : .white.opacity(0.45)
        }
        switch style {
        case .primary: return Theme.ink
        case .secondary, .outline: return color
        }
    }

    private var borderColor: Color {
        if disabled {
            return nearlyAffordable ? Theme.money.opacity(0.3) : Theme.hairline
        }
        switch style {
        case .primary: return .white.opacity(pulsing ? 0.5 : 0.18)
        case .secondary: return color.opacity(0.3)
        case .outline: return color.opacity(0.4)
        }
    }

    private var shadowColor: Color {
        guard !disabled else { return .clear }
        switch style {
        case .primary: return color.opacity(emphasized ? (pulsing ? 0.5 : 0.22) : 0.28)
        case .secondary, .outline: return .black.opacity(0.2)
        }
    }
}

struct CartoonPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .brightness(configuration.isPressed ? -0.06 : 0)
            .animation(.spring(response: 0.18, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Shimmer sweep ("almost affordable" — warm light passes over)

struct ShimmerSweep: View {
    /// Seconds per full traversal.
    var period: Double = 2.8
    var tint: Color = Theme.moneyHigh

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: 1.0 / 30)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                    .truncatingRemainder(dividingBy: period) / period
                let w = geo.size.width
                LinearGradient(
                    colors: [.clear, tint.opacity(0.16), .clear],
                    startPoint: .leading, endPoint: .trailing
                )
                .frame(width: w * 0.6)
                .offset(x: -w * 0.6 + t * (w + w * 0.6))
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Legacy panel helpers

extension View {
    func comicShadow(radius: CGFloat = 0, y: CGFloat = 5) -> some View {
        shadow(color: Theme.comicShadow, radius: radius, y: y)
    }

    func comicCard(radius: CGFloat = Theme.cardRadius, fill: Color = Theme.surface) -> some View {
        proPanel(radius: radius, fill: fill)
    }

    /// Soft elevated panel — depth from fill and shadow, never glow strokes.
    func proPanel(radius: CGFloat = Theme.cardRadius, fill: Color = Theme.surface) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(fill)
                    .overlay(
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .fill(
                                LinearGradient(colors: [.white.opacity(0.045), .clear],
                                               startPoint: .top, endPoint: .center)
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .strokeBorder(Theme.hairline, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.4), radius: 14, y: 8)
            )
    }
}
