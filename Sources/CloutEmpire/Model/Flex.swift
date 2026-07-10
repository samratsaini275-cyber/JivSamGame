import Foundation

/// A fake flex the player can post — push-your-luck risk/reward between purchases.
enum FlexTier: String, CaseIterable, Identifiable, Codable {
    case humbleBrag
    case photoshoot
    case fullLarp

    var id: String { rawValue }

    var name: String {
        switch self {
        case .humbleBrag: return "Humble Brag"
        case .photoshoot: return "Photoshoot"
        case .fullLarp: return "Full Larp"
        }
    }

    var flavor: String {
        switch self {
        case .humbleBrag: return "\"grateful 🙏\" + blurry sales screenshot"
        case .photoshoot: return "rented whip, 40 min left on the meter"
        case .fullLarp: return "fake Forbes feature, jet-doorway pose"
        }
    }

    /// Heat added to the Sus Meter when this flex is posted.
    var heat: Double {
        switch self {
        case .humbleBrag: return 10
        case .photoshoot: return 20
        case .fullLarp: return 35
        }
    }

    /// Exposure chance at zero Heat, before receipts modifiers.
    var baseRisk: Double {
        switch self {
        case .humbleBrag: return 0.05
        case .photoshoot: return 0.12
        case .fullLarp: return 0.20
        }
    }

    /// How much a success adds to the Hype income multiplier.
    var hypeGain: Double {
        switch self {
        case .humbleBrag: return 0.25
        case .photoshoot: return 0.5
        case .fullLarp: return 1.0
        }
    }
}

/// One line of the risk breakdown shown on a flex button — receipts cut risk,
/// zoomable fakes add it.
struct FlexRiskFactor: Identifiable {
    let label: String
    /// Risk delta as a fraction (−0.08 = 8 points safer).
    let delta: Double
    var id: String { label }
}

enum Flex {
    static let maxHeat: Double = 100
    static let heatDecayPerSecond: Double = 1.0
    /// Extra exposure chance per point of Heat (0.4%/point → +40% at max Heat).
    static let riskPerHeat: Double = 0.004
    static let minRisk: Double = 0.02
    static let maxRisk: Double = 0.90

    static let hypeCap: Double = 4.0
    /// Flex again within this window or the Hype streak dies.
    static let hypeWindow: TimeInterval = 45
    static let exposureDuration: TimeInterval = 60
    static let exposureIncomeMultiplier: Double = 0.5
    static let cooldown: TimeInterval = 10

    /// A Full Larp landing at this Heat or above actually goes viral (60s ×2).
    static let jackpotHeatThreshold: Double = 70
    static let jackpotViralDuration: TimeInterval = 60

    /// Rex items that are actually real — flexing them is receipts, not risk.
    static let realRexItemIDs: Set<String> = ["tagheuer", "daytona", "bugatti"]

    // MARK: Copy

    /// Sus Meter mood by heat fraction (0–1).
    static func mood(heatFraction: Double) -> (emoji: String, line: String) {
        switch heatFraction {
        case ..<0.34: return ("🙏", "comments are worshipping")
        case ..<0.67: return ("🤨", "reply guys are circling")
        default: return ("🚨", "one zoom from disaster")
        }
    }

    /// Toast copy when an exposure lands, escalating with lifetime exposures.
    static func exposureLine(exposureCount: Int) -> String {
        let lines = [
            "A reply guy zoomed in on the reflection. Delete it.",
            "The screenshot is in three group chats already.",
            "There's a side-by-side callout thread. It has numbers.",
            "The rental company tagged itself. Brutal.",
            "You're a cautionary quote-tweet now.",
        ]
        return lines[min(max(exposureCount - 1, 0), lines.count - 1)]
    }

    /// Dealer DM lines clowning the player after an exposure, by flex tier.
    static func clowningLines(tier: FlexTier, exposureCount: Int) -> [String] {
        let pools: [FlexTier: [[String]]] = [
            .humbleBrag: [
                ["my guy posted a spreadsheet with the formula bar still showing 💀",
                 "delete it before the accountants find you"],
                ["the 'sold out' banner is a sticker. i can see the edge",
                 "this is why we don't post before coffee"],
                ["bro the revenue graph is the default excel demo data",
                 "i can't keep defending you in the group chat"],
            ],
            .photoshoot: [
                ["bro the parking meter is IN THE SHOT 💀",
                 "40 minutes left on it too. they zoomed"],
                ["crown's on the wrong side of the watch. zoom happened. it's over",
                 "next time flex something with receipts"],
                ["the whip has the rental barcode in the window my guy",
                 "i know the rental guy. he's posting about you rn"],
            ],
            .fullLarp: [
                ["forbes doesn't use comic sans 💀💀",
                 "the font police got you before the fact-checkers did"],
                ["that jet is a museum exhibit. there's a rope in frame",
                 "the rope, my guy. the ROPE"],
                ["you tagged the location. it's a furniture showroom",
                 "living room set number 4 is famous now"],
            ],
        ]
        let pool = pools[tier] ?? []
        guard !pool.isEmpty else { return [] }
        return pool[min(max(exposureCount - 1, 0), pool.count - 1)]
    }

    /// Dealer DM lines when a Reputation Manager eats the exposure.
    static let repManagerSaveLines = [
        "i know a guy. the post is gone, the reply guy's account is gone.",
        "you owe me one.",
    ]
}
