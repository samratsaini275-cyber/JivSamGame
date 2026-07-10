import Foundation

enum ItemSlot: String, Codable, CaseIterable {
    case wrist = "Wrist"
    case garage = "Garage"
    case perk = "Perk"

    var fitLabel: String {
        switch self {
        case .wrist: return "Wrist"
        case .garage: return "Garage"
        case .perk: return "Bag"
        }
    }

    var emptyHint: String {
        switch self {
        case .wrist: return "Watches land here when a dealer puts you on"
        case .garage: return "Whips land here when you pull up different"
        case .perk: return "Perks and plug-ins show up from your DMs — 2 active max"
        }
    }
}

struct RexItem: Identifiable {
    let id: String
    let slot: ItemSlot
    let tier: Int
    let name: String
    let blurb: String
    let cost: Double
    let boostText: String
    let dealer: DMDealer?

    var imageName: String { "rex_\(id)" }
}

extension RexItem {
    static let maxEquippedPerks = 2

    static let all: [RexItem] = [
        RexItem(id: "heatpress", slot: .perk, tier: 1,
                name: "Garage Heat Press",
                blurb: "Louder than a factory. Half the permits.",
                cost: 25, boostText: "+4% income, all Hustles", dealer: .mica),
        RexItem(id: "subletter", slot: .perk, tier: 1,
                name: "Industrial Subletter",
                blurb: "Smells like a warehouse. Productivity included.",
                cost: 800, boostText: "+10% income, starter Hustles (no milestone)", dealer: .mica),
        RexItem(id: "fauxlex", slot: .wrist, tier: 1,
                name: "Fauxlex Datejust",
                blurb: "Ticks audibly. Real ones sweep.",
                cost: 500, boostText: "+5% income, all Hustles", dealer: .vinnie),
        RexItem(id: "tagheuer", slot: .wrist, tier: 2,
                name: "Actual Tag Heuer",
                blurb: "Genuine. The receipt is the fake part.",
                cost: 12_000, boostText: "+15% income, verified Hustles (Tier 1+)", dealer: .vinnie),
        RexItem(id: "civic", slot: .garage, tier: 1,
                name: "Leased Civic (wrapped)",
                blurb: "The wrap costs more per month than the lease.",
                cost: 1_200, boostText: "−5% cycle time, all Hustles", dealer: .dre),
        RexItem(id: "charger", slot: .garage, tier: 2,
                name: "Rented Charger",
                blurb: "Returned every Sunday night, photographed daily.",
                cost: 30_000, boostText: "−10% cycle time, verified Hustles (Tier 1+)", dealer: .dre),
        RexItem(id: "cartbot", slot: .perk, tier: 2,
                name: "Cart Bot License",
                blurb: "Refreshes faster than customer shame.",
                cost: 8_000, boostText: "−4% cycle time, all Hustles", dealer: .zay),
        RexItem(id: "queueskip", slot: .perk, tier: 2,
                name: "Queue Skip Pass",
                blurb: "Checkout like you own the backend.",
                cost: 250_000, boostText: "−8% cycle time, verified Hustles (Tier 1+)", dealer: .zay),
        RexItem(id: "micro_roster", slot: .perk, tier: 3,
                name: "Micro-Influencer Roster",
                blurb: "400K reach. Zero chemistry.",
                cost: 100_000, boostText: "+5% income, all Hustles", dealer: .lena),
        RexItem(id: "talent_pkg", slot: .perk, tier: 3,
                name: "Verified Talent Package",
                blurb: "Blue checks and soft launches.",
                cost: 2_500_000, boostText: "+12% income, verified Hustles (Tier 2+)", dealer: .lena),
        RexItem(id: "rack_kit", slot: .perk, tier: 3,
                name: "Foldable Rack Kit",
                blurb: "Sets up in 20 minutes. Looks permitted.",
                cost: 1_500_000, boostText: "−5% cycle time, all Hustles", dealer: .marco),
        RexItem(id: "lambo", slot: .garage, tier: 3,
                name: "Borrowed Lambo",
                blurb: "1-day rental, re-rented daily. The math is not mathing.",
                cost: 900_000, boostText: "25% chance a milestone triggers an early Viral Moment (×2, 60s)", dealer: .marco),
        RexItem(id: "foam_marble", slot: .perk, tier: 4,
                name: "Foam Marble Panels",
                blurb: "Weighs less than your lease.",
                cost: 20_000_000, boostText: "+8% income, verified Hustles (Tier 3+)", dealer: .sloane),
        RexItem(id: "daytona", slot: .wrist, tier: 3,
                name: "Vintage Daytona",
                blurb: "The flex is now load-bearing.",
                cost: 400_000, boostText: "+2% Clout gain rate — permanent, survives Rebrand", dealer: .sloane),
        RexItem(id: "standing_pass", slot: .perk, tier: 4,
                name: "Standing Room Pass",
                blurb: "You won't sit. You'll be photographed.",
                cost: 250_000_000, boostText: "+6% income, all Hustles", dealer: .viktor),
        RexItem(id: "mille", slot: .wrist, tier: 4,
                name: "\"Richard Mille\"",
                blurb: "Customs won't confirm it's real. Neither will Richard.",
                cost: 18_000_000, boostText: "×2 income for 10s whenever you buy a Hustle unit", dealer: .viktor),
        RexItem(id: "bugatti", slot: .garage, tier: 4,
                name: "Actual Bugatti",
                blurb: "Owned outright. The one real asset. Do not ask about the financing.",
                cost: 40_000_000, boostText: "Your lowest-owned Hustle cycles at your best milestone tier", dealer: nil),
    ]

    static func byID(_ id: String?) -> RexItem? {
        guard let id else { return nil }
        return all.first { $0.id == id }
    }

    static func forSlot(_ slot: ItemSlot) -> [RexItem] {
        all.filter { $0.slot == slot }.sorted { $0.tier < $1.tier }
    }

    static func forDealer(_ dealer: DMDealer) -> [RexItem] {
        all.filter { $0.dealer == dealer }
    }

    static let tierNames = ["", "Replica", "Genuine", "Grail", "Unreal"]
    var tierName: String { RexItem.tierNames[tier] }
}

enum Rex {
    /// DMs unlock once any hustle hits milestone tier 2 (50+ units — "Sold-Out Drop").
    static let unlockMoneyTier = 2
    static let unlockLifetimeCash: Double = 2_500

    static let greeting = "Yo. Been watching the brand. Put me on and I put YOU on. That's just math."
    static let purchaseBarks = [
        "This isn't a purchase. This is a statement.",
        "Receipts are for people who plan on being asked.",
        "We don't buy things. We acquire narratives.",
        "Grail secured. The fit is now historically significant.",
    ]
    static let downgradeBark = "The market didn't understand my vision."
    static let brokeBark = "Manifest harder."
    static let idleCarBarks = [
        "I don't drive to work. I drive to be seen not working.",
        "Mileage cap? Kings don't read contracts.",
    ]
    static let idleWatchBarks = [
        "Time is money. That's why I wear it.",
        "It loses four minutes a day. So do I.",
    ]
    static let idleBarks = [
        "Rise and grind. Mostly rise.",
        "My morning routine is 45 minutes of photos of my morning routine.",
    ]
    static let tier4Bark = "The hangar is rented. The altitude is real."

    static func scene(forBestTier tier: Int) -> (imageName: String, caption: String) {
        let t = min(max(tier, 0), 4)
        let captions = [
            "Rex is typing…",
            "Hotel bathroom he doesn't have a room in",
            "Top floor of a parking structure, golden hour",
            "Standing near a jet that is not his",
            "Private hangar (rented hourly)",
        ]
        return ("rex_scene_\(t)", captions[t])
    }

    static func idleBark(wrist: RexItem?, garage: RexItem?) -> String {
        let bestTier = max(wrist?.tier ?? 0, garage?.tier ?? 0)
        if bestTier >= 4 { return tier4Bark }
        if garage != nil { return idleCarBarks.randomElement()! }
        if wrist != nil { return idleWatchBarks.randomElement()! }
        return idleBarks.randomElement()!
    }
}
