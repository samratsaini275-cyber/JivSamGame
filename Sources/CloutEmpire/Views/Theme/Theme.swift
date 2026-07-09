import SwiftUI

// MARK: - Brand colorways ("your own aesthetic")

/// Picked at persona creation; tints every accent in the app.
struct Colorway: Identifiable {
    let id: String
    let name: String
    let accent: Color
    let accentDeep: Color

    var gradient: LinearGradient {
        LinearGradient(colors: [accent, accentDeep], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static let all: [Colorway] = [
        Colorway(id: "gold", name: "24K", accent: Color(red: 0.94, green: 0.76, blue: 0.32),
                 accentDeep: Color(red: 0.72, green: 0.53, blue: 0.15)),
        Colorway(id: "volt", name: "Volt", accent: Color(red: 0.78, green: 1.0, blue: 0.20),
                 accentDeep: Color(red: 0.45, green: 0.75, blue: 0.10)),
        Colorway(id: "ice", name: "Ice", accent: Color(red: 0.55, green: 0.85, blue: 1.0),
                 accentDeep: Color(red: 0.22, green: 0.56, blue: 0.90)),
        Colorway(id: "crimson", name: "Crimson", accent: Color(red: 1.0, green: 0.32, blue: 0.38),
                 accentDeep: Color(red: 0.72, green: 0.10, blue: 0.20)),
        Colorway(id: "amethyst", name: "Amethyst", accent: Color(red: 0.70, green: 0.50, blue: 1.0),
                 accentDeep: Color(red: 0.45, green: 0.23, blue: 0.85)),
    ]

    static func byID(_ id: String) -> Colorway {
        all.first { $0.id == id } ?? all[0]
    }
}

extension Game {
    var theme: Colorway { Colorway.byID(state.colorway) }
}

// MARK: - Design tokens

enum Theme {
    static let bg = Color(red: 0.043, green: 0.043, blue: 0.059)      // #0B0B0F
    static let bgRaised = Color(red: 0.078, green: 0.078, blue: 0.106) // #14141B
    static let moneyGreen = Color(red: 0.29, green: 0.87, blue: 0.50)
    static let cloutPurple = Color(red: 0.65, green: 0.55, blue: 0.98)
    static let hypeOrange = Color(red: 1.0, green: 0.58, blue: 0.20)

    static let cardRadius: CGFloat = 16

    /// Full-window backdrop: layered radial glows on near-black.
    static func backdrop(_ colorway: Colorway) -> some View {
        ZStack {
            bg
            RadialGradient(colors: [colorway.accent.opacity(0.10), .clear],
                           center: .top, startRadius: 0, endRadius: 420)
            RadialGradient(colors: [cloutPurple.opacity(0.06), .clear],
                           center: .bottomTrailing, startRadius: 0, endRadius: 380)
        }
        .ignoresSafeArea()
    }

    static func tierColor(_ tier: Int) -> Color {
        switch tier {
        case 1: return Color(white: 0.65)
        case 2: return Color(red: 0.40, green: 0.70, blue: 1.0)
        case 3: return cloutPurple
        default: return Color(red: 0.94, green: 0.76, blue: 0.32)
        }
    }
}

// MARK: - Modifiers

/// Glassmorphism card: material blur, subtle inner gradient, 1px gradient stroke, drop shadow.
struct LuxCard: ViewModifier {
    var radius: CGFloat = Theme.cardRadius
    var highlighted: Bool = false
    var accent: Color = .white

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(LinearGradient(colors: [.white.opacity(0.05), .white.opacity(0.015)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
            }
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(colors: [
                            highlighted ? accent.opacity(0.55) : .white.opacity(0.16),
                            .white.opacity(0.03),
                        ], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1)
            }
            .shadow(color: highlighted ? accent.opacity(0.25) : .black.opacity(0.45),
                    radius: highlighted ? 14 : 10, y: 5)
    }
}

/// Two-layer shadow bloom.
struct Glow: ViewModifier {
    var color: Color
    var radius: CGFloat = 8

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.55), radius: radius)
            .shadow(color: color.opacity(0.25), radius: radius * 2.2)
    }
}

/// Press-down scale + accent flash; hover brighten on macOS.
struct PressableButtonStyle: ButtonStyle {
    var tint: Color = .white

    func makeBody(configuration: Configuration) -> some View {
        HoverBody(configuration: configuration, tint: tint)
    }

    private struct HoverBody: View {
        let configuration: Configuration
        let tint: Color
        @State private var hovering = false

        var body: some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.955 : 1)
                .brightness(hovering ? 0.06 : 0)
                .shadow(color: configuration.isPressed ? tint.opacity(0.5) : .clear, radius: 8)
                .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
                .onHover { hovering = $0 }
        }
    }
}

extension View {
    func luxCard(radius: CGFloat = Theme.cardRadius, highlighted: Bool = false, accent: Color = .white) -> some View {
        modifier(LuxCard(radius: radius, highlighted: highlighted, accent: accent))
    }

    func glow(_ color: Color, radius: CGFloat = 8) -> some View {
        modifier(Glow(color: color, radius: radius))
    }

    /// Caps-and-tracking section label.
    func kicker() -> some View {
        font(.system(size: 10, weight: .heavy, design: .rounded))
            .tracking(2.2)
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
    }

    /// Metallic gradient fill for display text.
    func metallic(_ colorway: Colorway) -> some View {
        foregroundStyle(
            LinearGradient(colors: [.white, colorway.accent, colorway.accentDeep],
                           startPoint: .top, endPoint: .bottom)
        )
    }
}
