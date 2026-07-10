import SwiftUI

// MARK: - DROP WIRE — the hype ticker under the header.
// A stock-wire strip that scrolls fake streetwear headlines and real game
// events, so the world feels alive even while the player idles.

struct TickerItem: Identifiable, Equatable {
    enum Kind { case satire, event, money }
    let id = UUID()
    let text: String
    let kind: Kind
}

/// A fixed bed of canned satire with the most recent game events spliced in
/// every few headlines. UI-layer only — reads game state, never mutates it.
final class TickerFeed: ObservableObject {
    @Published private(set) var items: [TickerItem] = []

    private static let satire: [String] = [
        "THE NEXT DROP IS ALWAYS CLOSE",
        "FW LOOKBOOK LEAK: IT'S THE OLD LOOKBOOK AGAIN",
        "'90s VINTAGE TEE TRACED TO LAST YEAR'S BLANK",
        "RESELLER APOLOGIZES, RAISES PRICES",
        "CEASE-AND-DESIST FRAMED, HUNG IN FLAGSHIP",
        "COLLAB RUMOR DENIED BY BOTH BURNER ACCOUNTS",
        "DROP TIMER STILL SAYS 00:59",
        "EVERYTHING IS LIMITED IF YOU NEVER RESTOCK",
        "LINE FORMS OUTSIDE STORE THAT SELLS LINES",
        "GRAIL SPOTTED AT RETAIL, NOBODY BELIEVES IT",
    ]

    private var events: [TickerItem] = []

    init() { rebuild() }

    func push(_ text: String, kind: TickerItem.Kind = .event) {
        events.append(TickerItem(text: text.uppercased(), kind: kind))
        if events.count > 4 { events.removeFirst(events.count - 4) }
        rebuild()
    }

    /// Splice an event in after every second satire headline.
    private func rebuild() {
        var merged: [TickerItem] = []
        var eventQueue = events
        for (i, line) in Self.satire.enumerated() {
            merged.append(TickerItem(text: line, kind: .satire))
            if i % 2 == 1, !eventQueue.isEmpty {
                merged.append(eventQueue.removeFirst())
            }
        }
        merged.append(contentsOf: eventQueue)
        items = merged
    }

    /// Translate a celebration event into wire copy. Payouts are skipped —
    /// the cash particles already cover them and the wire would spam.
    func report(_ event: GameEvent, game: Game) {
        let handle = "@\(game.state.handle)"
        switch event.kind {
        case .payout:
            break
        case .milestone(let index, let tier):
            push("\(Hustle.all[index].name) HITS \(VerificationTier.name(for: tier))")
        case .hypeWave(let tier):
            push("HYPE WAVE — ALL INCOME ×\(Int(pow(2, Double(tier))))", kind: .money)
        case .rebranded(let clout):
            push("\(handle) REBRANDS · +\(Int(clout)) CLOUT — LONG LIVE THE LABEL", kind: .money)
        case .newDM(let dealer):
            push("NEW DM: \(dealer.title) SLID IN")
        case .flexHit(let hype):
            push("\(handle) FLEX LANDED · HYPE ×\(String(format: "%g", hype))")
        case .flexExposed:
            push("EXPOSED: \(handle) GOT RATIO'D")
        case .flexSaved:
            push("POST DELETED BEFORE IT SPREAD · NO WITNESSES")
        case .flexViral:
            push("\(handle) ACTUALLY WENT VIRAL · THE LARP WAS TOO GOOD", kind: .money)
        }
    }
}

struct TickerTape: View {
    @ObservedObject var feed: TickerFeed
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var stripWidth: CGFloat = 0

    private let speed: Double = 42 // pt/s

    var body: some View {
        Group {
            if reduceMotion {
                crossfadeTape
            } else {
                scrollingTape
            }
        }
        .frame(height: 24)
        .background(Theme.ink.opacity(0.6))
        .overlay(VStack {
            Rectangle().fill(Theme.hairline).frame(height: 1)
            Spacer()
            Rectangle().fill(Theme.hairline).frame(height: 1)
        })
        .clipped()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Hype wire")
    }

    // Seamless loop: two copies of the strip; offset wraps at one strip width.
    // The strip lives in an overlay so its huge ideal width never drives layout.
    private var scrollingTape: some View {
        Color.clear
            .overlay(alignment: .leading) {
                TimelineView(.animation(minimumInterval: 1.0 / 30)) { timeline in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    let offset = stripWidth > 1
                        ? (t * speed).truncatingRemainder(dividingBy: stripWidth) : 0
                    HStack(spacing: 0) {
                        TickerStrip(items: feed.items)
                            .background(
                                GeometryReader { geo in
                                    Color.clear.preference(key: StripWidthKey.self,
                                                           value: geo.size.width)
                                }
                            )
                        TickerStrip(items: feed.items)
                    }
                    .fixedSize()
                    .offset(x: -offset)
                }
            }
            .onPreferenceChange(StripWidthKey.self) { stripWidth = $0 }
    }

    // Reduced motion: one headline at a time, opacity crossfade.
    private var crossfadeTape: some View {
        TimelineView(.periodic(from: .now, by: 6)) { timeline in
            let idx = Int(timeline.date.timeIntervalSinceReferenceDate / 6)
            if !feed.items.isEmpty {
                let item = feed.items[idx % feed.items.count]
                TickerText(item: item)
                    .id(item.id)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: idx)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

private struct StripWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct TickerStrip: View {
    let items: [TickerItem]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                TickerText(item: item)
                Text("  ///  ")
                    .font(Theme.mono(9, weight: .bold))
                    .foregroundStyle(Theme.textFaint.opacity(0.6))
            }
        }
        .padding(.horizontal, 4)
        .frame(height: 24)
        .lineLimit(1)
    }
}

private struct TickerText: View {
    let item: TickerItem

    var body: some View {
        Text(item.text)
            .font(Theme.mono(9, weight: item.kind == .satire ? .medium : .bold))
            .kerning(0.8)
            .foregroundStyle(color)
            .lineLimit(1)
    }

    private var color: Color {
        switch item.kind {
        case .satire: return Theme.textMuted
        case .event: return Theme.textPrimary
        case .money: return Theme.money
        }
    }
}
