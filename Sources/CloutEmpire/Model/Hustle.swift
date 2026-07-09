import Foundation

/// Static definition of a business — costs grow ×1.14 per unit owned.
/// (Type is still named `Hustle` internally; indices, costs, incomes and cycles
/// are load-bearing for save compatibility and must not change.)
struct Hustle: Identifiable {
    let id: Int
    let name: String
    let flavor: String
    let emoji: String
    let baseCost: Double
    let baseIncome: Double
    let baseCycle: Double // seconds per production run at tier 0
    let ghostwriterName: String // the staff hire that automates this business
    let ghostwriterCost: Double
}

extension Hustle {
    static let all: [Hustle] = [
        Hustle(id: 0, name: "Bootleg Tees",
               flavor: "Heat-pressed in the garage. The logo is \"inspired by.\"",
               emoji: "👕", baseCost: 4, baseIncome: 1, baseCycle: 1,
               ghostwriterName: "Print Plug", ghostwriterCost: 1_000),
        Hustle(id: 1, name: "Sneaker Resells",
               flavor: "Buy retail, flip triple. Condolences to people with feet.",
               emoji: "👟", baseCost: 60, baseIncome: 15, baseCycle: 3,
               ghostwriterName: "Sniper Bot", ghostwriterCost: 15_000),
        Hustle(id: 2, name: "Custom Hoodies",
               flavor: "Cut-and-sew, \"limited\" runs. Limited by the sewing machine.",
               emoji: "🧥", baseCost: 720, baseIncome: 100, baseCycle: 4,
               ghostwriterName: "Production Manager", ghostwriterCost: 100_000),
        Hustle(id: 3, name: "Hyped Drops",
               flavor: "Artificial scarcity as a service. Timer says 00:59.",
               emoji: "⏱️", baseCost: 8_640, baseIncome: 520, baseCycle: 5,
               ghostwriterName: "Drop Coordinator", ghostwriterCost: 500_000),
        Hustle(id: 4, name: "Influencer Collabs",
               flavor: "Their audience, your logo, everyone's cut.",
               emoji: "🤳", baseCost: 103_680, baseIncome: 3_600, baseCycle: 6,
               ghostwriterName: "Talent Agent", ghostwriterCost: 1_200_000),
        Hustle(id: 5, name: "Pop-Up Shops",
               flavor: "The line around the block IS the product.",
               emoji: "🏪", baseCost: 1_240_000, baseIncome: 24_000, baseCycle: 8,
               ghostwriterName: "Store Manager", ghostwriterCost: 10_000_000),
        Hustle(id: 6, name: "Flagship Store",
               flavor: "Retail as theater. The concrete floor cost six figures.",
               emoji: "🏬", baseCost: 14_900_000, baseIncome: 180_000, baseCycle: 10,
               ghostwriterName: "Creative Director", ghostwriterCost: 120_000_000),
        Hustle(id: 7, name: "Fashion Week Line",
               flavor: "The bootleg goes couture. Critics call it \"a journey.\"",
               emoji: "🕊️", baseCost: 180_000_000, baseIncome: 1_400_000, baseCycle: 15,
               ghostwriterName: "Atelier Director", ghostwriterCost: 1_000_000_000),
    ]
}

/// Hype Tier names shown at each milestone (25/50/100/200/300/400 units).
enum VerificationTier {
    static let names = [
        "No Buzz",
        "Local Buzz",
        "Sold-Out Drop",
        "Cult Following",
        "Celebrity Co-sign",
        "Global Hype",
        "Icon Status",
    ]

    static func name(for tier: Int) -> String {
        names[min(tier, names.count - 1)]
    }
}
