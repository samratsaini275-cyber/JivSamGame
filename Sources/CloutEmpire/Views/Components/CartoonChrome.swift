import SwiftUI

// MARK: - Comic button (chunky 3D press)

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
            VStack(spacing: 2) {
                Text(title)
                    .font(Theme.cartoonFont(10))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if let subtitle {
                    Text(subtitle)
                        .font(Theme.cartoonFont(9, weight: .bold))
                        .monospacedDigit()
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .foregroundStyle(foreground)
            .background { face }
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(Theme.comicBorder, lineWidth: Theme.comicStroke))
            .background(alignment: .bottom) {
                if !disabled && style == .primary {
                    Capsule()
                        .fill(color.opacity(0.45))
                        .offset(y: 4)
                }
            }
        }
        .buttonStyle(CartoonPressStyle())
        .disabled(disabled)
    }

    @ViewBuilder private var face: some View {
        switch style {
        case .primary:
            if let colorway, !disabled {
                Capsule().fill(colorway.gradient)
            } else {
                Capsule().fill(disabled ? Theme.surfaceRaised : color)
            }
        case .secondary:
            Capsule().fill(disabled ? Theme.surfaceRaised : color.opacity(0.28))
        case .outline:
            Capsule().fill(color.opacity(0.12))
        }
    }

    private var foreground: Color {
        if disabled { return .white.opacity(0.35) }
        switch style {
        case .primary: return Theme.comicBorder
        case .secondary, .outline: return color
        }
    }
}

struct CartoonPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .offset(y: configuration.isPressed ? 3 : 0)
            .animation(.spring(response: 0.18, dampingFraction: 0.55), value: configuration.isPressed)
    }
}

extension View {
    func comicShadow(radius: CGFloat = 0, y: CGFloat = 5) -> some View {
        shadow(color: Theme.comicShadow, radius: radius, y: y)
    }

    func comicCard(radius: CGFloat = Theme.cardRadius, fill: Color = Theme.surface) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(fill)
                    .comicShadow(y: 5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Theme.comicBorder, lineWidth: Theme.comicStroke)
            )
    }
}
