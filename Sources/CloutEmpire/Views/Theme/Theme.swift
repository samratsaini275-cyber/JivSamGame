import SwiftUI

struct Colorway: Identifiable {
    let id: String
    let name: String
    let accent: Color
    let accentDeep: Color

    var gradient: LinearGradient {
        LinearGradient(colors: [accent, accentDeep], startPoint: .top, endPoint: .bottom)
    }

    static let all: [Colorway] = [
        Colorway(id: "gold", name: "24K",
                 accent: Color(red: 1.0, green: 0.85, blue: 0.25),
                 accentDeep: Color(red: 0.9, green: 0.55, blue: 0.05)),
        Colorway(id: "volt", name: "Volt",
                 accent: Color(red: 0.75, green: 1.0, blue: 0.2),
                 accentDeep: Color(red: 0.35, green: 0.78, blue: 0.05)),
        Colorway(id: "ice", name: "Ice",
                 accent: Color(red: 0.45, green: 0.88, blue: 1.0),
                 accentDeep: Color(red: 0.12, green: 0.55, blue: 0.95)),
        Colorway(id: "crimson", name: "Crimson",
                 accent: Color(red: 1.0, green: 0.38, blue: 0.45),
                 accentDeep: Color(red: 0.82, green: 0.12, blue: 0.22)),
        Colorway(id: "amethyst", name: "Amethyst",
                 accent: Color(red: 0.75, green: 0.48, blue: 1.0),
                 accentDeep: Color(red: 0.45, green: 0.18, blue: 0.88)),
    ]

    static func byID(_ id: String) -> Colorway {
        all.first { $0.id == id } ?? all[0]
    }
}

extension Game {
    var theme: Colorway { Colorway.byID(state.colorway) }
}

enum Theme {
    static let bg = Color(red: 0.14, green: 0.10, blue: 0.28)
    static let surface = Color(red: 0.22, green: 0.18, blue: 0.38)
    static let surfaceRaised = Color(red: 0.28, green: 0.24, blue: 0.46)
    static let comicBorder = Color(red: 0.12, green: 0.08, blue: 0.22)
    static let comicShadow = Color.black.opacity(0.45)
    static let comicStroke: CGFloat = 3

    static let coinGreen = Color(red: 0.3, green: 0.95, blue: 0.55)
    static let cloutPink = Color(red: 0.92, green: 0.5, blue: 1.0)
    static let hypeBlue = Color(red: 0.4, green: 0.78, blue: 1.0)

    static let screenPadding: CGFloat = 14
    static let cardRadius: CGFloat = 18

    static func backdrop(_ colorway: Colorway) -> some View {
        ZStack {
            bg
            RadialGradient(
                colors: [colorway.accent.opacity(0.22), .clear],
                center: .top, startRadius: 0, endRadius: 360
            )
            RadialGradient(
                colors: [cloutPink.opacity(0.12), .clear],
                center: .bottomTrailing, startRadius: 0, endRadius: 300
            )
        }
        .ignoresSafeArea()
    }

    static func tierColor(_ tier: Int) -> Color {
        switch tier {
        case 1: return Color(white: 0.8)
        case 2: return hypeBlue
        case 3: return cloutPink
        default: return Color(red: 1.0, green: 0.82, blue: 0.28)
        }
    }

    static func cartoonFont(_ size: CGFloat, weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

struct GameCard: ViewModifier {
    var highlighted: Bool = false
    var accent: Color = Theme.comicBorder

    func body(content: Content) -> some View {
        content
            .comicCard(radius: Theme.cardRadius, fill: Theme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    .strokeBorder(highlighted ? accent : Theme.comicBorder, lineWidth: Theme.comicStroke)
            )
    }
}

struct PressableButtonStyle: ButtonStyle {
    var bounce: Bool = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(bounce && configuration.isPressed ? 0.93 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.55), value: configuration.isPressed)
    }
}

struct StatBadge: View {
    let imageName: String
    let title: String
    let value: String
    let color: Color
    var progress: Double? = nil

    var body: some View {
        HStack(spacing: 8) {
            if let progress {
                ZStack {
                    Circle().stroke(color.opacity(0.25), lineWidth: 3)
                    Circle()
                        .trim(from: 0, to: CGFloat(min(1, max(0, progress))))
                        .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    GameImage(name: imageName, size: 18)
                }
                .frame(width: 32, height: 32)
            } else {
                GameImage(name: imageName, size: 28)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.cartoonFont(11))
                    .foregroundStyle(color)
                Text(value)
                    .font(Theme.cartoonFont(9, weight: .bold))
                    .foregroundStyle(.white.opacity(0.55))
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .gameCard(highlighted: (progress ?? 0) > 0, accent: color)
    }
}

struct GameSegmentedControl<Option: Hashable & Identifiable>: View where Option: CustomStringConvertible {
    @Binding var selection: Option
    let options: [Option]
    var colorway: Colorway

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options) { option in
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.7)) { selection = option }
                } label: {
                    Text(option.description)
                        .font(Theme.cartoonFont(12))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background {
                            if selection == option { Capsule().fill(colorway.gradient) }
                        }
                        .foregroundStyle(selection == option ? Theme.comicBorder : .white.opacity(0.45))
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
        .padding(4)
        .background(Capsule().fill(Theme.surfaceRaised))
        .overlay(Capsule().strokeBorder(Theme.comicBorder, lineWidth: Theme.comicStroke))
        .comicShadow(y: 4)
    }
}

// GameButton alias — views use CartoonButton from CartoonChrome.swift
typealias GameButton = CartoonButton

struct GameTabBar: View {
    @Binding var selection: MainTab
    var colorway: Colorway
    var rexBadge: Bool
    var rexUnlocked: Bool = true

    private var tabs: [MainTab] {
        rexUnlocked ? MainTab.allCases : MainTab.allCases.filter { $0 != .rex }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, 6)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background {
            Theme.surface
            VStack { Rectangle().fill(Theme.comicBorder).frame(height: Theme.comicStroke); Spacer() }
        }
    }

    private func tabButton(_ tab: MainTab) -> some View {
        let selected = selection == tab
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) { selection = tab }
        } label: {
            VStack(spacing: 3) {
                ZStack(alignment: .topTrailing) {
                    GameImage(name: tab.imageName, size: selected ? 30 : 26)
                        .scaleEffect(selected ? 1.08 : 1)
                    if tab == .rex, rexBadge {
                        Circle().fill(.red).frame(width: 8, height: 8).offset(x: 4, y: -3)
                    }
                }
                Text(tab.label)
                    .font(Theme.cartoonFont(9, weight: selected ? .heavy : .semibold))
                    .foregroundStyle(selected ? colorway.accent : .white.opacity(0.45))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PressableButtonStyle(bounce: false))
    }
}

enum MainTab: String, CaseIterable, Identifiable {
    case empire, rex, rebrand, profile
    var id: String { rawValue }

    var imageName: String {
        switch self {
        case .empire: return "tab_empire"
        case .rex: return "tab_rex"
        case .rebrand: return "tab_rebrand"
        case .profile: return "tab_profile"
        }
    }

    var label: String {
        switch self {
        case .empire: return "Empire"
        case .rex: return "Rex"
        case .rebrand: return "Rebrand"
        case .profile: return "Fit"
        }
    }
}

extension BuyMode: CustomStringConvertible {
    var description: String { rawValue }
}

extension View {
    func gameCard(highlighted: Bool = false, accent: Color = Theme.comicBorder) -> some View {
        modifier(GameCard(highlighted: highlighted, accent: accent))
    }

    func luxCard(radius: CGFloat = Theme.cardRadius, highlighted: Bool = false, accent: Color = .white) -> some View {
        gameCard(highlighted: highlighted, accent: accent)
    }

    func glow(_ color: Color, radius: CGFloat = 8) -> some View {
        shadow(color: color.opacity(0.55), radius: radius)
    }

    func kicker() -> some View {
        font(Theme.cartoonFont(10))
            .foregroundStyle(.white.opacity(0.45))
            .textCase(.uppercase)
    }

    func gameTitle(_ colorway: Colorway) -> some View {
        font(Theme.cartoonFont(26, weight: .black))
        .foregroundStyle(colorway.gradient)
    }
}
