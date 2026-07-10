import Foundation

/// Static definition of a business — costs grow ×1.14 per unit owned.
/// (Type is still named `Hustle` internally; indices, costs, incomes and cycles
/// are load-bearing for save compatibility and must not change.)
struct Hustle: Identifiable {
    let id: Int
    let name: String
    let flavor: String
    let imageName: String
    let baseCost: Double
    let baseIncome: Double
    let baseCycle: Double // seconds per production run at tier 0
    let ghostwriterName: String // the staff hire that automates this business
    let ghostwriterCost: Double
}

extension Hustle {
    static let customHoodiesIndex = 2

    static let all: [Hustle] = [
        Hustle(id: 0, name: "Bootleg Tees",
               flavor: "Heat-pressed in the garage. The logo is \"inspired by.\"",
               imageName: "hustle_0_luxury", baseCost: 4, baseIncome: 1, baseCycle: 1,
               ghostwriterName: "Print Plug", ghostwriterCost: 1_000),
        Hustle(id: 1, name: "Sneaker Resells",
               flavor: "Buy retail, flip triple. Condolences to people with feet.",
               imageName: "hustle_1_luxury", baseCost: 60, baseIncome: 15, baseCycle: 3,
               ghostwriterName: "Sniper Bot", ghostwriterCost: 15_000),
        Hustle(id: 2, name: "Custom Hoodies",
               flavor: "Cut-and-sew, \"limited\" runs. Limited by the sewing machine.",
               imageName: "hustle_2_luxury", baseCost: 720, baseIncome: 100, baseCycle: 4,
               ghostwriterName: "Production Manager", ghostwriterCost: 100_000),
        Hustle(id: 3, name: "Hyped Drops",
               flavor: "Artificial scarcity as a service. Timer says 00:59.",
               imageName: "hustle_3_luxury", baseCost: 8_640, baseIncome: 520, baseCycle: 5,
               ghostwriterName: "Drop Coordinator", ghostwriterCost: 500_000),
        Hustle(id: 4, name: "Influencer Collabs",
               flavor: "Their audience, your logo, everyone's cut.",
               imageName: "hustle_4_luxury", baseCost: 103_680, baseIncome: 3_600, baseCycle: 6,
               ghostwriterName: "Talent Agent", ghostwriterCost: 1_200_000),
        Hustle(id: 5, name: "Pop-Up Shops",
               flavor: "The line around the block IS the product.",
               imageName: "hustle_5_luxury", baseCost: 1_240_000, baseIncome: 24_000, baseCycle: 8,
               ghostwriterName: "Store Manager", ghostwriterCost: 10_000_000),
        Hustle(id: 6, name: "Flagship Store",
               flavor: "Retail as theater. The concrete floor cost six figures.",
               imageName: "hustle_6_luxury", baseCost: 14_900_000, baseIncome: 180_000, baseCycle: 10,
               ghostwriterName: "Creative Director", ghostwriterCost: 120_000_000),
        Hustle(id: 7, name: "Fashion Week Line",
               flavor: "The bootleg goes couture. Critics call it \"a journey.\"",
               imageName: "hustle_7_luxury", baseCost: 180_000_000, baseIncome: 1_400_000, baseCycle: 15,
               ghostwriterName: "Atelier Director", ghostwriterCost: 1_000_000_000),
        Hustle(id: 8, name: "Viral Lookbook Studio",
               flavor: "Every fit gets a cinematic trailer and a suspiciously perfect comment section.",
               imageName: "hustle_8_luxury", baseCost: 2_160_000_000, baseIncome: 10_800_000, baseCycle: 16,
               ghostwriterName: "Content Director", ghostwriterCost: 12_000_000_000),
        Hustle(id: 9, name: "Micro Factory",
               flavor: "Tiny batch, massive margins. The sewing machine has a waiting list.",
               imageName: "hustle_9_luxury", baseCost: 26_000_000_000, baseIncome: 82_000_000, baseCycle: 18,
               ghostwriterName: "Factory Lead", ghostwriterCost: 140_000_000_000),
        Hustle(id: 10, name: "Celebrity Capsule",
               flavor: "One famous person wears it once. The internet treats it like scripture.",
               imageName: "hustle_10_luxury", baseCost: 310_000_000_000, baseIncome: 640_000_000, baseCycle: 20,
               ghostwriterName: "Celebrity Wrangler", ghostwriterCost: 1_700_000_000_000),
        Hustle(id: 11, name: "Digital Skins",
               flavor: "Fabric is optional when the flex lives on every avatar.",
               imageName: "hustle_11_luxury", baseCost: 3_700_000_000_000, baseIncome: 5_200_000_000, baseCycle: 21,
               ghostwriterName: "Virtual Tailor", ghostwriterCost: 20_000_000_000_000),
        Hustle(id: 12, name: "Global Licensing Deal",
               flavor: "Your logo appears on objects you have never personally seen.",
               imageName: "hustle_12_luxury", baseCost: 44_000_000_000_000, baseIncome: 43_000_000_000, baseCycle: 23,
               ghostwriterName: "Licensing Counsel", ghostwriterCost: 240_000_000_000_000),
        Hustle(id: 13, name: "Signature Fragrance",
               flavor: "Smells like ambition, oud, and margin expansion.",
               imageName: "hustle_13_luxury", baseCost: 530_000_000_000_000, baseIncome: 360_000_000_000, baseCycle: 24,
               ghostwriterName: "Scent Director", ghostwriterCost: 2_900_000_000_000_000),
        Hustle(id: 14, name: "Streamed Runway",
               flavor: "The front row is global, the chat is feral, the sponsors are thrilled.",
               imageName: "hustle_14_luxury", baseCost: 6_400_000_000_000_000, baseIncome: 3_100_000_000_000, baseCycle: 26,
               ghostwriterName: "Broadcast Producer", ghostwriterCost: 34_000_000_000_000_000),
        Hustle(id: 15, name: "Private Members Club",
               flavor: "You can't buy taste, but you can charge monthly for proximity to it.",
               imageName: "hustle_15_luxury", baseCost: 77_000_000_000_000_000, baseIncome: 27_000_000_000_000, baseCycle: 28,
               ghostwriterName: "Club Concierge", ghostwriterCost: 410_000_000_000_000_000),
        Hustle(id: 16, name: "Brand Acquisition",
               flavor: "Why compete with old money when you can acquire its mailing list?",
               imageName: "hustle_16_luxury", baseCost: 920_000_000_000_000_000, baseIncome: 240_000_000_000_000, baseCycle: 30,
               ghostwriterName: "Deal Team", ghostwriterCost: 4_900_000_000_000_000_000),
        Hustle(id: 17, name: "Mega Mall Flagship",
               flavor: "A monument to buying things, shaped like a flex.",
               imageName: "hustle_17_luxury", baseCost: 11_000_000_000_000_000_000, baseIncome: 2_200_000_000_000_000, baseCycle: 32,
               ghostwriterName: "Mall Emperor", ghostwriterCost: 58_000_000_000_000_000_000),
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
