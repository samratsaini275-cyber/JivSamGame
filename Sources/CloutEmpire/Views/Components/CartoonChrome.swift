import SwiftUI

// MARK: - Studio chrome

struct CartoonButton: View {
    let title: String
    var subtitle: String? = nil
    var color: Color
    var colorway: Colorway? = nil
    var style: Style = .primary
    var disabled: Bool = false
    let action: () -> Void

    enum Style { case primary, secondary, outline }

    var body: some View {
        Button(action: action) {
            VStack(spacing: subtitle == nil ? 0 : 2) {
                Text(title)
                    .font(Theme.cartoonFont(10, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if let subtitle {
                    Text(subtitle)
                        .font(Theme.cartoonFont(9, weight: .medium))
                        .monospacedDigit()
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 8)
            .foregroundStyle(foreground)
            .background { face }
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 7, style: .continuous).strokeBorder(stroke, lineWidth: 1))
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(.white.opacity(disabled ? 0.04 : 0.16), lineWidth: 1)
                    .frame(height: 1)
            }
            .shadow(color: disabled ? .clear : color.opacity(style == .primary ? 0.22 : 0.10), radius: 14, y: 6)
        }
        .buttonStyle(CartoonPressStyle())
        .disabled(disabled)
    }

    @ViewBuilder private var face: some View {
        switch style {
        case .primary:
            if let colorway, !disabled {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Theme.champagne, colorway.accent, colorway.accentDeep],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            } else {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(disabled ? Theme.surfaceRaised : color)
            }
        case .secondary:
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(disabled ? Theme.surfaceRaised : color.opacity(0.18))
        case .outline:
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Theme.ink.opacity(0.35))
        }
    }

    private var foreground: Color {
        if disabled { return .white.opacity(0.35) }
        switch style {
        case .primary: return Theme.ink
        case .secondary, .outline: return color
        }
    }

    private var stroke: Color {
        if disabled { return .white.opacity(0.06) }
        switch style {
        case .primary: return Theme.champagne.opacity(0.55)
        case .secondary, .outline: return color.opacity(0.45)
        }
    }
}

struct CartoonPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .brightness(configuration.isPressed ? -0.06 : 0)
            .animation(.spring(response: 0.16, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

extension View {
    func comicShadow(radius: CGFloat = 0, y: CGFloat = 5) -> some View {
        shadow(color: Theme.comicShadow, radius: radius, y: y)
    }

    func comicCard(radius: CGFloat = Theme.cardRadius, fill: Color = Theme.surface) -> some View {
        proPanel(radius: radius, fill: fill)
    }

    func proPanel(radius: CGFloat = Theme.cardRadius, fill: Color = Theme.surface) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.panelTop.opacity(0.90),
                                fill,
                                Theme.panelBottom.opacity(0.98),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .black.opacity(0.44), radius: 22, y: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Theme.luxeGold.opacity(0.16), lineWidth: 1)
            )
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Theme.champagne.opacity(0.16), lineWidth: 1)
                    .frame(height: 1)
            }
    }
}
