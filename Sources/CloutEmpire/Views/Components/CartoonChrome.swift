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
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .foregroundStyle(foreground)
            .background { face }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(stroke, lineWidth: 2.5))
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.white.opacity(disabled ? 0.04 : 0.22))
                    .frame(height: 5)
                    .padding(.horizontal, 8)
                    .padding(.top, 3)
            }
            .background(alignment: .bottom) {
                if !disabled {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(stroke.opacity(0.55))
                        .offset(y: 5)
                }
            }
            .shadow(color: disabled ? .clear : color.opacity(style == .primary ? 0.42 : 0.22), radius: 16, y: 7)
        }
        .buttonStyle(CartoonPressStyle())
        .disabled(disabled)
    }

    @ViewBuilder private var face: some View {
        switch style {
        case .primary:
            if let colorway, !disabled {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Theme.champagne, colorway.accent, Theme.arcadeOrange],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            } else {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(disabled ? Theme.surfaceRaised : color)
            }
        case .secondary:
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(disabled ? Theme.surfaceRaised : color.opacity(0.32))
        case .outline:
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(LinearGradient(colors: [Theme.arcadePurple.opacity(0.28), Theme.ink.opacity(0.60)], startPoint: .top, endPoint: .bottom))
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
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .offset(y: configuration.isPressed ? 4 : 0)
            .brightness(configuration.isPressed ? -0.08 : 0.03)
            .animation(.spring(response: 0.16, dampingFraction: 0.58), value: configuration.isPressed)
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
                                Theme.panelTop.opacity(0.96),
                                fill,
                                Theme.arcadePurple.opacity(0.20),
                                Theme.panelBottom.opacity(0.98),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Theme.cloutPink.opacity(0.18), radius: 16, y: 7)
                    .shadow(color: .black.opacity(0.48), radius: 20, y: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Theme.luxeGold.opacity(0.44), lineWidth: 2)
            )
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(.white.opacity(0.12))
                    .frame(height: 6)
                    .padding(.horizontal, 10)
                    .padding(.top, 3)
            }
    }
}
