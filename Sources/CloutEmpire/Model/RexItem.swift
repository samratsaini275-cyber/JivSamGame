import Foundation

enum ItemSlot: String, Codable, CaseIterable {
    case wrist = "Wrist"
    case garage = "Garage"
}

struct RexItem: Identifiable {
    let id: String
    let slot: ItemSlot
    let tier: Int
    let name: String
    let blurb: String
    let cost: Double
    let boostText: String

    var imageName: String { "rex_\(id)" }
}

extension RexItem {
    static let all: [RexItem] = [
        RexItem(id: "fauxlex", slot: .wrist, tier: 1,
                name: "Fauxlex Datejust",
                blurb: "Ticks audibly. Real ones sweep.",
                cost: 500, boostText: "+5% income, all Hustles"),
        RexItem(id: "tagheuer", slot: .wrist, tier: 2,
                name: "Actual Tag Heuer",
                blurb: "Genuine. The receipt is the fake part.",
                cost: 12_000, boostText: "+15% income, verified Hustles (Tier 1+)"),
        RexItem(id: "daytona", slot: .wrist, tier: 3,
                name: "Vintage Daytona",
                blurb: "The flex is now load-bearing.",
                cost: 400_000, boostText: "+2% Clout gain rate — permanent, survives Rebrand"),
        RexItem(id: "mille", slot: .wrist, tier: 4,
                name: "\"Richard Mille\"",
                blurb: "Customs won't confirm it's real. Neither will Richard.",
                cost: 18_000_000, boostText: "×2 income for 10s whenever you buy a Hustle unit"),
        RexItem(id: "civic", slot: .garage, tier: 1,
                name: "Leased Civic (wrapped)",
                blurb: "The wrap costs more per month than the lease.",
                cost: 1_200, boostText: "−5% cycle time, all Hustles"),
        RexItem(id: "charger", slot: .garage, tier: 2,
                name: "Rented Charger",
                blurb: "Returned every Sunday night, photographed daily.",
                cost: 30_000, boostText: "−10% cycle time, verified Hustles (Tier 1+)"),
        RexItem(id: "lambo", slot: .garage, tier: 3,
                name: "Borrowed Lambo",
                blurb: "1-day rental, re-rented daily. The math is not mathing.",
                cost: 900_000, boostText: "25% chance a milestone triggers an early Viral Moment (×2, 60s)"),
        RexItem(id: "bugatti", slot: .garage, tier: 4,
                name: "Actual Bugatti",
                blurb: "Owned outright. The one real asset. Do not ask about the financing.",
                cost: 40_000_000, boostText: "Your lowest-owned Hustle cycles at your best milestone tier"),
    ]

    static func byID(_ id: String?) -> RexItem? {
        guard let id else { return nil }
        return all.first { $0.id == id }
    }

    static func forSlot(_ slot: ItemSlot) -> [RexItem] {
        all.filter { $0.slot == slot }.sorted { $0.tier < $1.tier }
    }

    static let tierNames = ["", "Replica", "Genuine", "Grail", "Unreal"]
    var tierName: String { RexItem.tierNames[tier] }
}

enum Rex {
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
