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
                 accent: Color(red: 1.0, green: 0.80, blue: 0.36),
                 accentDeep: Color(red: 0.66, green: 0.39, blue: 0.11)),
        Colorway(id: "volt", name: "Emerald",
                 accent: Color(red: 0.42, green: 0.95, blue: 0.65),
                 accentDeep: Color(red: 0.06, green: 0.44, blue: 0.28)),
        Colorway(id: "ice", name: "Platinum",
                 accent: Color(red: 0.68, green: 0.90, blue: 1.0),
                 accentDeep: Color(red: 0.20, green: 0.48, blue: 0.70)),
        Colorway(id: "crimson", name: "Bordeaux",
                 accent: Color(red: 0.94, green: 0.33, blue: 0.39),
                 accentDeep: Color(red: 0.42, green: 0.04, blue: 0.10)),
        Colorway(id: "amethyst", name: "Violet",
                 accent: Color(red: 0.73, green: 0.52, blue: 1.0),
                 accentDeep: Color(red: 0.31, green: 0.15, blue: 0.55)),
    ]

    static func byID(_ id: String) -> Colorway {
        all.first { $0.id == id } ?? all[0]
    }
}

extension Game {
    var theme: Colorway { Colorway.byID(state.colorway) }
}

enum Theme {
    static let bg = Color(red: 0.025, green: 0.012, blue: 0.038)
    static let surface = Color(red: 0.095, green: 0.052, blue: 0.122)
    static let surfaceRaised = Color(red: 0.145, green: 0.075, blue: 0.175)
    static let panelTop = Color(red: 0.235, green: 0.105, blue: 0.235)
    static let panelBottom = Color(red: 0.050, green: 0.024, blue: 0.080)
    static let comicBorder = Color(red: 1.0, green: 0.82, blue: 0.42).opacity(0.18)
    static let comicShadow = Color.black.opacity(0.55)
    static let comicStroke: CGFloat = 1

    static let coinGreen = Color(red: 0.34, green: 0.92, blue: 0.52)
    static let cloutPink = Color(red: 0.96, green: 0.42, blue: 0.58)
    static let hypeBlue = Color(red: 0.38, green: 0.72, blue: 1.0)
    static let arcadePurple = Color(red: 0.58, green: 0.32, blue: 1.0)
    static let arcadeOrange = Color(red: 1.0, green: 0.45, blue: 0.18)
    static let luxeGold = Color(red: 1.0, green: 0.78, blue: 0.34)
    static let champagne = Color(red: 1.0, green: 0.91, blue: 0.68)
    static let ink = Color(red: 0.010, green: 0.011, blue: 0.014)
    static let textMuted = Color.white.opacity(0.56)

    static let screenPadding: CGFloat = 18
    static let cardRadius: CGFloat = 8

    static func backdrop(_ colorway: Colorway) -> some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.13, green: 0.045, blue: 0.18),
                    Color(red: 0.025, green: 0.012, blue: 0.045),
                    Color(red: 0.12, green: 0.040, blue: 0.090),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            ArcadeBackdropPattern(colorway: colorway)
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.black.opacity(0.10), .clear, cloutPink.opacity(0.10)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
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
        .system(size: size, weight: weight, design: .default)
    }
}

struct ArcadeBackdropPattern: View {
    var colorway: Colorway
    @State private var drift: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<6, id: \.self) { index in
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    colorway.accent.opacity(index.isMultiple(of: 2) ? 0.28 : 0.08),
                                    Theme.cloutPink.opacity(index.isMultiple(of: 2) ? 0.16 : 0.06),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * 1.35, height: index.isMultiple(of: 2) ? 42 : 16)
                        .rotationEffect(.degrees(index.isMultiple(of: 2) ? -14 : 18))
                        .offset(
                            x: sin(drift + CGFloat(index)) * 22 - geo.size.width * 0.14,
                            y: CGFloat(index) * geo.size.height * 0.18 - 60
                        )
                }
                ForEach(0..<18, id: \.self) { index in
                    Image(systemName: index.isMultiple(of: 3) ? "sparkle" : "dollarsign")
                        .font(.system(size: CGFloat(12 + (index % 4) * 5), weight: .black))
                        .foregroundStyle(index.isMultiple(of: 2) ? Theme.luxeGold.opacity(0.18) : Theme.cloutPink.opacity(0.14))
                        .rotationEffect(.degrees(Double(index * 21)))
                        .offset(
                            x: CGFloat((index * 67) % 380) - 190 + sin(drift * 0.7 + CGFloat(index)) * 10,
                            y: CGFloat((index * 113) % 760) - 380 + cos(drift * 0.6 + CGFloat(index)) * 12
                        )
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .onAppear {
                withAnimation(.linear(duration: 9).repeatForever(autoreverses: true)) {
                    drift = .pi * 2
                }
            }
        }
        .blendMode(.screen)
        .opacity(0.95)
    }
}

struct GameCard: ViewModifier {
    var highlighted: Bool = false
    var accent: Color = Theme.comicBorder

    func body(content: Content) -> some View {
        content
            .proPanel(radius: Theme.cardRadius, fill: Theme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    .strokeBorder(highlighted ? accent.opacity(0.95) : Theme.luxeGold.opacity(0.35), lineWidth: highlighted ? 3 : 2)
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
        HStack(spacing: 10) {
            if let progress {
                ZStack {
                    Circle().stroke(color.opacity(0.22), lineWidth: 3)
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
                    .font(Theme.cartoonFont(10, weight: .black))
                    .foregroundStyle(.white)
                Text(value)
                    .font(Theme.cartoonFont(9, weight: .medium))
                    .foregroundStyle(Theme.textMuted)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(LinearGradient(colors: [color.opacity(0.28), Theme.surface.opacity(0.95)], startPoint: .topLeading, endPoint: .bottomTrailing))
        }
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(color.opacity(0.70), lineWidth: 2))
        .shadow(color: color.opacity(0.24), radius: 12, y: 6)
    }
}

struct GameSegmentedControl<Option: Hashable & Identifiable>: View where Option: CustomStringConvertible {
    @Binding var selection: Option
    let options: [Option]
    var colorway: Colorway

    var body: some View {
        HStack(spacing: 6) {
            ForEach(options) { option in
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.7)) { selection = option }
                } label: {
                    Text(option.description)
                        .font(Theme.cartoonFont(11, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background {
                            if selection == option {
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(colorway.gradient)
                                    .shadow(color: colorway.accent.opacity(0.28), radius: 10, y: 4)
                            }
                        }
                        .foregroundStyle(selection == option ? Theme.ink : Theme.textMuted)
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
        .padding(5)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.ink.opacity(0.72)))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.luxeGold.opacity(0.42), lineWidth: 2))
        .shadow(color: colorway.accent.opacity(0.22), radius: 14, y: 8)
    }
}

// GameButton alias — views use CartoonButton from CartoonChrome.swift
typealias GameButton = CartoonButton

struct GameTabBar: View {
    @Binding var selection: MainTab
    var colorway: Colorway
    var rexBadge: Bool
    var rexUnlocked: Bool = true

    @State private var showDMsLockHint = false

    private static let dmsLockMessage = "Unlocks when Sneaker Resells is unlocked"

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MainTab.allCases) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 9)
        .padding(.bottom, 11)
        .background {
            LinearGradient(colors: [Theme.arcadePurple.opacity(0.45), Theme.ink.opacity(0.94)], startPoint: .top, endPoint: .bottom)
            VStack { Rectangle().fill(Theme.luxeGold.opacity(0.45)).frame(height: 2); Spacer() }
        }
        .overlay(alignment: .top) {
            if showDMsLockHint {
                Text(Self.dmsLockMessage)
                    .font(Theme.cartoonFont(10, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Theme.ink.opacity(0.95))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(Theme.luxeGold.opacity(0.45), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 20)
                    .offset(y: -44)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private func tabButton(_ tab: MainTab) -> some View {
        let selected = selection == tab
        let locked = tab == .rex && !rexUnlocked
        return Button {
            if locked {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.72)) {
                    showDMsLockHint = true
                }
                Task {
                    try? await Task.sleep(nanoseconds: 2_500_000_000)
                    await MainActor.run {
                        withAnimation(.easeOut(duration: 0.2)) { showDMsLockHint = false }
                    }
                }
                return
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) { selection = tab }
        } label: {
            VStack(spacing: 3) {
                ZStack {
                    Circle()
                        .fill(selected ? colorway.accent.opacity(0.28) : Theme.ink.opacity(0.40))
                        .frame(width: 42, height: 34)
                        .overlay(Circle().strokeBorder(selected ? colorway.accent : .white.opacity(0.12), lineWidth: selected ? 2 : 1))
                    GameImage(name: tab.imageName, size: selected ? 29 : 23)
                        .scaleEffect(selected ? 1.08 : 1)
                        .opacity(locked ? 0.35 : 1)
                    if locked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white.opacity(0.9))
                            .shadow(color: .black.opacity(0.4), radius: 2, y: 1)
                    } else if tab == .rex, rexBadge {
                        Circle().fill(Theme.cloutPink).frame(width: 8, height: 8)
                            .offset(x: 14, y: -12)
                    }
                }
                Text(tab.label)
                    .font(Theme.cartoonFont(9, weight: selected ? .bold : .medium))
                    .foregroundStyle(
                        locked ? .white.opacity(0.25)
                        : (selected ? colorway.accent : Theme.textMuted)
                    )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 5)
            .background {
                if selected {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(LinearGradient(colors: [colorway.accent.opacity(0.30), Theme.cloutPink.opacity(0.14)], startPoint: .top, endPoint: .bottom))
                        .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous).strokeBorder(colorway.accent.opacity(0.45), lineWidth: 1.5))
                }
            }
        }
        .buttonStyle(PressableButtonStyle(bounce: !locked))
        .help(locked ? Self.dmsLockMessage : "")
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
        case .rex: return "DMs"
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
        font(Theme.cartoonFont(10, weight: .bold))
            .foregroundStyle(Theme.textMuted)
            .textCase(.uppercase)
    }

    func gameTitle(_ colorway: Colorway) -> some View {
        font(Theme.cartoonFont(28, weight: .black))
        .foregroundStyle(colorway.gradient)
    }
}
