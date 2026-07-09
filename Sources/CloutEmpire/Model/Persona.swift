import Foundation

/// The player's own character — pure identity, no stats, no builds.
/// Unlike Rex's rented gear, the Persona's wardrobe survives Rebrand:
/// you burn the account, not the closet.
enum PersonaSlot: String, Codable, CaseIterable {
    case clothes = "Clothes"
    case jewelry = "Jewelry"
    case watch = "Watch"
}

struct PersonaItem: Identifiable {
    let id: String
    let slot: PersonaSlot
    let tier: Int // 1 Low, 2 Mid, 3 High, 4 Grail
    let name: String
    let emoji: String
    let cost: Double

    static let tierNames = ["", "Low", "Mid", "High", "Grail"]
    var tierName: String { PersonaItem.tierNames[tier] }
    var isGrail: Bool { tier == 4 }
}

extension PersonaItem {
    /// Watch tier reuses Rex's table on purpose — same visual tech, same pricing
    /// logic. The difference is purpose (cosmetic identity), not structure.
    static let all: [PersonaItem] = [
        // Clothes
        PersonaItem(id: "thrifted", slot: .clothes, tier: 1,
                    name: "Thrifted \"Aesthetic\" Fit", emoji: "🧥", cost: 250),
        PersonaItem(id: "streetdrop", slot: .clothes, tier: 2,
                    name: "Streetwear Drop", emoji: "👟", cost: 5_000),
        PersonaItem(id: "designer", slot: .clothes, tier: 3,
                    name: "Designer Fit", emoji: "🕴️", cost: 150_000),
        PersonaItem(id: "couture", slot: .clothes, tier: 4,
                    name: "Custom Couture, One-of-One", emoji: "🦚", cost: 8_000_000),

        // Jewelry
        PersonaItem(id: "fakechain", slot: .jewelry, tier: 1,
                    name: "Fake Gold Chain", emoji: "⛓️", cost: 350),
        PersonaItem(id: "realchain", slot: .jewelry, tier: 2,
                    name: "Real Gold Chain", emoji: "📿", cost: 8_000),
        PersonaItem(id: "grill", slot: .jewelry, tier: 3,
                    name: "Diamond Grill", emoji: "😁", cost: 250_000),
        PersonaItem(id: "iced", slot: .jewelry, tier: 4,
                    name: "Iced-Out Everything", emoji: "🧊", cost: 12_000_000),

        // Watches (Rex's table, cosmetic edition)
        PersonaItem(id: "p_fauxlex", slot: .watch, tier: 1,
                    name: "Fauxlex", emoji: "⌚", cost: 500),
        PersonaItem(id: "p_tagheuer", slot: .watch, tier: 2,
                    name: "Actual Tag Heuer", emoji: "⌚", cost: 12_000),
        PersonaItem(id: "p_daytona", slot: .watch, tier: 3,
                    name: "Vintage Daytona", emoji: "🕰️", cost: 400_000),
        PersonaItem(id: "p_mille", slot: .watch, tier: 4,
                    name: "Unconfirmed \"Richard Mille\"", emoji: "💠", cost: 18_000_000),
    ]

    static func byID(_ id: String?) -> PersonaItem? {
        guard let id else { return nil }
        return all.first { $0.id == id }
    }

    static func forSlot(_ slot: PersonaSlot) -> [PersonaItem] {
        all.filter { $0.slot == slot }.sorted { $0.tier < $1.tier }
    }
}

/// Free starter presets picked at persona creation. No stats — the character IS the player.
struct BaseLook: Identifiable {
    let id: String
    let name: String
    let emoji: String

    static let all: [BaseLook] = [
        BaseLook(id: "hoodie", name: "Hoodie & Hat", emoji: "🧢"),
        BaseLook(id: "bizcaz", name: "Business Casual", emoji: "👔"),
        BaseLook(id: "street", name: "Streetwear", emoji: "🥷"),
        BaseLook(id: "gym", name: "Gym Mirror", emoji: "💪"),
    ]

    static func byID(_ id: String) -> BaseLook {
        all.first { $0.id == id } ?? all[0]
    }
}

/// Leaderboard seam — the board itself is built later, but the ranking contract
/// is decided now: primary sort is lifetime Clout (stable prestige), with the
/// portrait + equipped gear rendered alongside the handle so the board is a
/// social flex surface, not a raw number list. Cosmetics never touch income.
struct LeaderboardEntry: Identifiable {
    let id: String // the handle
    let handle: String
    let portrait: String
    let clout: Double
    let lifetimeCash: Double

    static func rank(_ entries: [LeaderboardEntry]) -> [LeaderboardEntry] {
        entries.sorted {
            $0.clout != $1.clout ? $0.clout > $1.clout : $0.lifetimeCash > $1.lifetimeCash
        }
    }
}
