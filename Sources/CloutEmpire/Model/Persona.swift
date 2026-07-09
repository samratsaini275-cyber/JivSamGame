import Foundation

enum PersonaSlot: String, Codable, CaseIterable {
    case clothes = "Clothes"
    case jewelry = "Jewelry"
    case watch = "Watch"
}

struct PersonaItem: Identifiable {
    let id: String
    let slot: PersonaSlot
    let tier: Int
    let name: String
    let cost: Double

    var imageName: String { "persona_\(id)" }

    static let tierNames = ["", "Low", "Mid", "High", "Grail"]
    var tierName: String { PersonaItem.tierNames[tier] }
    var isGrail: Bool { tier == 4 }
}

extension PersonaItem {
    static let all: [PersonaItem] = [
        PersonaItem(id: "thrifted", slot: .clothes, tier: 1,
                    name: "Thrifted \"Aesthetic\" Fit", cost: 250),
        PersonaItem(id: "streetdrop", slot: .clothes, tier: 2,
                    name: "Streetwear Drop", cost: 5_000),
        PersonaItem(id: "designer", slot: .clothes, tier: 3,
                    name: "Designer Fit", cost: 150_000),
        PersonaItem(id: "couture", slot: .clothes, tier: 4,
                    name: "Custom Couture, One-of-One", cost: 8_000_000),
        PersonaItem(id: "fakechain", slot: .jewelry, tier: 1,
                    name: "Fake Gold Chain", cost: 350),
        PersonaItem(id: "realchain", slot: .jewelry, tier: 2,
                    name: "Real Gold Chain", cost: 8_000),
        PersonaItem(id: "grill", slot: .jewelry, tier: 3,
                    name: "Diamond Grill", cost: 250_000),
        PersonaItem(id: "iced", slot: .jewelry, tier: 4,
                    name: "Iced-Out Everything", cost: 12_000_000),
        PersonaItem(id: "p_fauxlex", slot: .watch, tier: 1,
                    name: "Fauxlex", cost: 500),
        PersonaItem(id: "p_tagheuer", slot: .watch, tier: 2,
                    name: "Actual Tag Heuer", cost: 12_000),
        PersonaItem(id: "p_daytona", slot: .watch, tier: 3,
                    name: "Vintage Daytona", cost: 400_000),
        PersonaItem(id: "p_mille", slot: .watch, tier: 4,
                    name: "Unconfirmed \"Richard Mille\"", cost: 18_000_000),
    ]

    static func byID(_ id: String?) -> PersonaItem? {
        guard let id else { return nil }
        return all.first { $0.id == id }
    }

    static func forSlot(_ slot: PersonaSlot) -> [PersonaItem] {
        all.filter { $0.slot == slot }.sorted { $0.tier < $1.tier }
    }
}

struct BaseLook: Identifiable {
    let id: String
    let name: String

    var imageName: String { "look_\(id)" }

    static let all: [BaseLook] = [
        BaseLook(id: "hoodie", name: "Hoodie & Hat"),
        BaseLook(id: "bizcaz", name: "Business Casual"),
        BaseLook(id: "street", name: "Streetwear"),
        BaseLook(id: "gym", name: "Gym Mirror"),
    ]

    static func byID(_ id: String) -> BaseLook {
        all.first { $0.id == id } ?? all[0]
    }
}

struct LeaderboardEntry: Identifiable {
    let id: String
    let handle: String
    let portraitImage: String
    let clout: Double
    let lifetimeCash: Double

    static func rank(_ entries: [LeaderboardEntry]) -> [LeaderboardEntry] {
        entries.sorted {
            $0.clout != $1.clout ? $0.clout > $1.clout : $0.lifetimeCash > $1.lifetimeCash
        }
    }
}
