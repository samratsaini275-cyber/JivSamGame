import SwiftUI

// MARK: - Colorway (player-picked identity accent — persisted IDs, do not rename)

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
                 accent: Color(red: 0.91, green: 0.78, blue: 0.49),
                 accentDeep: Color(red: 0.60, green: 0.44, blue: 0.18)),
        Colorway(id: "volt", name: "Emerald",
                 accent: Color(red: 0.42, green: 0.90, blue: 0.63),
                 accentDeep: Color(red: 0.08, green: 0.42, blue: 0.28)),
        Colorway(id: "ice", name: "Platinum",
                 accent: Color(red: 0.72, green: 0.86, blue: 0.95),
                 accentDeep: Color(red: 0.28, green: 0.46, blue: 0.62)),
        Colorway(id: "crimson", name: "Bordeaux",
                 accent: Color(red: 0.90, green: 0.36, blue: 0.42),
                 accentDeep: Color(red: 0.44, green: 0.08, blue: 0.14)),
        Colorway(id: "amethyst", name: "Violet",
                 accent: Color(red: 0.72, green: 0.55, blue: 0.96),
                 accentDeep: Color(red: 0.32, green: 0.18, blue: 0.55)),
    ]

    static func byID(_ id: String) -> Colorway {
        all.first { $0.id == id } ?? all[0]
    }
}

extension Game {
    var theme: Colorway { Colorway.byID(state.colorway) }
}

// MARK: - Tokens: "Midnight Atelier / Drop Night" (see DESIGN.md)

enum Theme {
    // Elevation — separation by fill + shadow, never glowing borders.
    static let bg = Color(red: 0.039, green: 0.039, blue: 0.059)          // #0A0A0F obsidian
    static let bgTop = Color(red: 0.071, green: 0.071, blue: 0.102)       // #12121A
    static let bgBottom = Color(red: 0.031, green: 0.031, blue: 0.047)    // #08080C
    static let surface = Color(red: 0.082, green: 0.082, blue: 0.110)     // #15151C card fill
    static let surfaceRaised = Color(red: 0.114, green: 0.114, blue: 0.149) // #1D1D26 wells/chips
    static let hairline = Color.white.opacity(0.07)

    static let textPrimary = Color(red: 0.949, green: 0.945, blue: 0.925) // #F2F1EC warm paper
    static let textMuted = Color.white.opacity(0.62)
    static let textFaint = Color.white.opacity(0.42)

    // money — champagne gold, reserved EXCLUSIVELY for money values/moments.
    static let money = Color(red: 0.910, green: 0.784, blue: 0.486)       // #E8C87C
    static let moneyHigh = Color(red: 0.957, green: 0.890, blue: 0.698)   // #F4E3B2
    static let moneyDeep = Color(red: 0.851, green: 0.663, blue: 0.306)   // #D9A94E
    static var moneyGradient: LinearGradient {
        LinearGradient(colors: [moneyHigh, money, moneyDeep], startPoint: .top, endPoint: .bottom)
    }

    // hype — the one hot accent (Hype, Clout, heat, celebration).
    static let hype = Color(red: 1.0, green: 0.302, blue: 0.616)          // #FF4D9D
    static let hypeSoft = Color(red: 1.0, green: 0.55, blue: 0.75)        // lighter tint of the same hue

    // go — the one confirm color (DROP, COP-when-affordable, positive income).
    static let go = Color(red: 0.243, green: 0.863, blue: 0.522)          // #3EDC85
    static let goDeep = Color(red: 0.075, green: 0.51, blue: 0.29)

    static let ink = Color(red: 0.020, green: 0.024, blue: 0.031)

    // Legacy aliases — untouched views inherit the new palette through these.
    static let coinGreen = go
    static let cloutPink = hype
    static let hypeBlue = hypeSoft
    static let arcadePurple = hype
    static let arcadeOrange = moneyDeep
    static let luxeGold = money
    static let champagne = moneyHigh
    static let panelTop = surfaceRaised
    static let panelBottom = surface
    static let comicBorder = hairline
    static let comicShadow = Color.black.opacity(0.55)
    static let comicStroke: CGFloat = 1

    static let screenPadding: CGFloat = 16
    static let cardRadius: CGFloat = 18
    static let chipRadius: CGFloat = 10

    /// Obsidian floor: vertical gradient, a faint overhead spotlight, static grain.
    static func backdrop(_ colorway: Colorway) -> some View {
        ZStack {
            LinearGradient(colors: [bgTop, bg, bgBottom], startPoint: .top, endPoint: .bottom)
            // Showroom spotlight — barely-there pool of warm light from above.
            RadialGradient(
                colors: [Color.white.opacity(0.045), .clear],
                center: .init(x: 0.5, y: -0.15),
                startRadius: 10, endRadius: 460
            )
            GrainOverlay()
        }
        .ignoresSafeArea()
    }

    /// Milestone tier accents, folded into the system: silver → hype tints → hype.
    static func tierColor(_ tier: Int) -> Color {
        switch tier {
        case ..<2: return Color(white: 0.78)
        case 2, 3: return hypeSoft
        default: return hype
        }
    }

    // MARK: Type — display (poster), receipt (mono spec print), body

    /// Fashion-poster face: SF compressed black. Headers and big moments only.
    static func display(_ size: CGFloat, weight: Font.Weight = .black) -> Font {
        .system(size: size, weight: weight).width(.compressed)
    }

    /// Receipt/spec-sheet print for labels, stats, and the flavor jokes.
    static func mono(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    /// Neutral body sans. (Legacy `cartoonFont` callers land here.)
    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }

    static func cartoonFont(_ size: CGFloat, weight: Font.Weight = .heavy) -> Font {
        body(size, weight: weight)
    }
}

/// Static film grain so large dark areas don't read as flat. Drawn once.
struct GrainOverlay: View {
    var body: some View {
        Canvas { ctx, size in
            var rng = SeededRandom(seed: 0x0DD1)
            let count = Int(size.width * size.height / 480)
            for _ in 0..<count {
                let x = rng.next() * size.width
                let y = rng.next() * size.height
                let alpha = 0.015 + rng.next() * 0.035
                ctx.fill(Path(CGRect(x: x, y: y, width: 1, height: 1)),
                         with: .color(.white.opacity(alpha)))
            }
        }
        .allowsHitTesting(false)
    }
}

/// Tiny deterministic PRNG so the grain never shimmers between renders.
struct SeededRandom {
    private var state: UInt64
    init(seed: UInt64) { state = seed &* 0x9E3779B97F4A7C15 | 1 }
    mutating func next() -> CGFloat {
        state ^= state << 13; state ^= state >> 7; state ^= state << 17
        return CGFloat(state % 10_000) / 10_000
    }
}

// MARK: - Cards: elevation, not outlines

struct GameCard: ViewModifier {
    var highlighted: Bool = false
    var accent: Color = .white

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    .fill(Theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                            .fill(
                                LinearGradient(colors: [.white.opacity(0.045), .clear],
                                               startPoint: .top, endPoint: .center)
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                            .fill(accent.opacity(highlighted ? 0.06 : 0))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                            .strokeBorder(highlighted ? accent.opacity(0.28) : Theme.hairline,
                                          lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.45), radius: 14, y: 8)
            )
    }
}

struct PressableButtonStyle: ButtonStyle {
    var bounce: Bool = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(bounce && configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.55), value: configuration.isPressed)
    }
}

// MARK: - Stat chips (Clout / Hype) — chip-like, never card-like

struct StatChip: View {
    let imageName: String
    let title: String
    let value: String
    var color: Color = Theme.hype
    var progress: Double? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        Button { action?() } label: {
            HStack(spacing: 8) {
                if let progress {
                    ZStack {
                        Circle().stroke(color.opacity(0.22), lineWidth: 2.5)
                        Circle()
                            .trim(from: 0, to: CGFloat(min(1, max(0, progress))))
                            .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        GameImage(name: imageName, size: 14)
                    }
                    .frame(width: 26, height: 26)
                } else {
                    GameImage(name: imageName, size: 20)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(Theme.mono(10, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                    Text(value)
                        .font(Theme.mono(8.5))
                        .foregroundStyle(Theme.textMuted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .background(
                Capsule().fill(Theme.surfaceRaised.opacity(0.85))
                    .overlay(Capsule().strokeBorder(color.opacity(0.25), lineWidth: 1))
            )
        }
        .buttonStyle(PressableButtonStyle(bounce: action != nil))
        .allowsHitTesting(action != nil)
    }
}

/// Legacy shim — old call sites render as the new chip.
struct StatBadge: View {
    let imageName: String
    let title: String
    let value: String
    let color: Color
    var progress: Double? = nil

    var body: some View {
        StatChip(imageName: imageName, title: title, value: value, color: color, progress: progress)
    }
}

// MARK: - Segmented control: quiet, ink track, white-on-raised selection

struct GameSegmentedControl<Option: Hashable & Identifiable>: View where Option: CustomStringConvertible {
    @Binding var selection: Option
    let options: [Option]
    var colorway: Colorway

    var body: some View {
        HStack(spacing: 3) {
            ForEach(options) { option in
                let selected = selection == option
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) { selection = option }
                } label: {
                    Text(option.description)
                        .font(Theme.mono(11, weight: selected ? .bold : .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background {
                            if selected {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color.white.opacity(0.14))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .strokeBorder(.white.opacity(0.16), lineWidth: 1)
                                    )
                            }
                        }
                        .foregroundStyle(selected ? Theme.textPrimary : Theme.textFaint)
                }
                .buttonStyle(PressableButtonStyle(bounce: false))
            }
        }
        .padding(3)
        .background(RoundedRectangle(cornerRadius: Theme.chipRadius, style: .continuous)
            .fill(Theme.ink.opacity(0.55)))
    }
}

// GameButton alias — views use CartoonButton from CartoonChrome.swift
typealias GameButton = CartoonButton

// MARK: - Tab bar: gold = active (the only non-money gold, it marks *your* place)

struct GameTabBar: View {
    @Binding var selection: MainTab
    var colorway: Colorway
    var rexBadge: Bool
    var rexUnlocked: Bool = true
    var rebrandBadge: Bool = false

    @State private var showDMsLockHint = false

    private static let dmsLockMessage = "Unlocks when Sneaker Resells is unlocked"

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MainTab.allCases) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background {
            Theme.ink.opacity(0.92)
            VStack { Rectangle().fill(Theme.hairline).frame(height: 1); Spacer() }
        }
        .overlay(alignment: .top) {
            if showDMsLockHint {
                Text(Self.dmsLockMessage)
                    .font(Theme.mono(10, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Theme.ink.opacity(0.97))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 20)
                    .offset(y: -44)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private func badgeVisible(_ tab: MainTab) -> Bool {
        (tab == .rex && rexBadge) || (tab == .rebrand && rebrandBadge)
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
            withAnimation(.easeOut(duration: 0.18)) { selection = tab }
        } label: {
            VStack(spacing: 3) {
                ZStack {
                    GameImage(name: tab.imageName, size: 23)
                        .saturation(selected ? 1 : 0)
                        .opacity(locked ? 0.3 : (selected ? 1 : 0.4))
                    if locked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white.opacity(0.85))
                            .shadow(color: .black.opacity(0.4), radius: 2, y: 1)
                    } else if badgeVisible(tab) {
                        Circle().fill(Theme.hype).frame(width: 7, height: 7)
                            .offset(x: 13, y: -10)
                    }
                }
                .frame(height: 26)
                Text(tab.label)
                    .font(Theme.mono(9, weight: selected ? .bold : .medium))
                    .foregroundStyle(
                        locked ? Color.white.opacity(0.28)
                        : (selected ? Theme.money : Theme.textFaint)
                    )
                Circle()
                    .fill(Theme.money)
                    .frame(width: 3, height: 3)
                    .opacity(selected ? 1 : 0)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 5)
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

    var index: Int { MainTab.allCases.firstIndex(of: self) ?? 0 }
}

extension BuyMode: CustomStringConvertible {
    var description: String { rawValue }
}

// MARK: - View helpers

extension View {
    func gameCard(highlighted: Bool = false, accent: Color = .white) -> some View {
        modifier(GameCard(highlighted: highlighted, accent: accent))
    }

    func luxCard(radius: CGFloat = Theme.cardRadius, highlighted: Bool = false, accent: Color = .white) -> some View {
        gameCard(highlighted: highlighted, accent: accent)
    }

    func glow(_ color: Color, radius: CGFloat = 8) -> some View {
        shadow(color: color.opacity(0.45), radius: radius)
    }

    /// Receipt-print section label: mono, tracked, uppercase, muted.
    func kicker() -> some View {
        font(Theme.mono(9, weight: .semibold))
            .kerning(1.2)
            .foregroundStyle(Theme.textFaint)
            .textCase(.uppercase)
    }

    func gameTitle(_ colorway: Colorway) -> some View {
        font(Theme.display(30))
            .kerning(0.5)
            .foregroundStyle(Theme.textPrimary)
    }
}
