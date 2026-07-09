import Foundation

/// Pure game math — README §§3–7. Everything here is deterministic and unit-tested.
enum Formulas {
    static let costGrowth = 1.14
    static let milestoneThresholds = [25, 50, 100, 200, 300, 400]
    /// Clout gained on Rebrand = floor(√(lifetimeCash / divisor)) − clout held.
    /// Tuned so the first Rebrand is worth taking after a few minutes of play.
    static let cloutDivisor: Double = 25_000
    static let cloutBonusPerPoint = 0.02

    // MARK: Costs (baseCost × 1.14^owned, geometric sums for bulk buys)

    static func unitCost(base: Double, owned: Int) -> Double {
        base * pow(costGrowth, Double(owned))
    }

    static func bulkCost(base: Double, owned: Int, count: Int) -> Double {
        guard count > 0 else { return 0 }
        let r = costGrowth
        return unitCost(base: base, owned: owned) * (pow(r, Double(count)) - 1) / (r - 1)
    }

    static func maxAffordable(base: Double, owned: Int, cash: Double) -> Int {
        let first = unitCost(base: base, owned: owned)
        guard cash >= first else { return 0 }
        let r = costGrowth
        let n = Int(floor(log(cash * (r - 1) / first + 1) / log(r)))
        // Guard against floating-point edge cases at the boundary.
        if bulkCost(base: base, owned: owned, count: n + 1) <= cash { return n + 1 }
        if n > 0, bulkCost(base: base, owned: owned, count: n) > cash { return n - 1 }
        return n
    }

    // MARK: Milestones (README §4: income ×2 and cycle ÷2 per threshold crossed)

    static func milestoneTier(units: Int) -> Int {
        milestoneThresholds.filter { units >= $0 }.count
    }

    static func nextThreshold(units: Int) -> Int? {
        milestoneThresholds.first { units < $0 }
    }

    static func incomeMultiplier(tier: Int) -> Double {
        pow(2, Double(tier))
    }

    static func cycleTime(base: Double, tier: Int) -> Double {
        base / pow(2, Double(tier))
    }

    // MARK: Viral Moment (README §5: min tier across ALL hustles, ×2 each)

    /// The account "goes viral" at the tier every hustle has reached — unowned
    /// hustles count as tier 0, matching AdCap's all-business Capitalist unlocks.
    static func viralTier(unitCounts: [Int]) -> Int {
        unitCounts.map(milestoneTier(units:)).min() ?? 0
    }

    static func viralMultiplier(unitCounts: [Int]) -> Double {
        pow(2, Double(viralTier(unitCounts: unitCounts)))
    }

    // MARK: Clout (README §7)

    static func cloutMultiplier(clout: Double) -> Double {
        1 + cloutBonusPerPoint * clout
    }

    /// `gainRateBonus` is Rex's Daytona effect: +2% per purchase, applied to the
    /// square-root curve before the held-clout subtraction.
    static func cloutGain(lifetimeCash: Double, currentClout: Double, gainRateBonus: Double = 0) -> Double {
        // Epsilon keeps binary rounding (200 × 1.015 → 202.999…) from eating a point.
        max(0, floor(sqrt(lifetimeCash / cloutDivisor) * (1 + gainRateBonus) + 1e-9) - currentClout)
    }

    // MARK: Rex's flex items

    /// "Tier-1 Hustles only" = hustles that have reached Verification Tier 1 (25+ units).
    static func wristIncomeMultiplier(itemID: String?, hustleTier: Int) -> Double {
        switch itemID {
        case "fauxlex": return 1.05
        case "tagheuer": return hustleTier >= 1 ? 1.15 : 1
        default: return 1
        }
    }

    static func garageCycleMultiplier(itemID: String?, hustleTier: Int) -> Double {
        switch itemID {
        case "civic": return 0.95
        case "charger": return hustleTier >= 1 ? 0.90 : 1
        default: return 1
        }
    }

    static let lamboViralChance = 0.25
    static let lamboViralDuration: Double = 60
    static let milleBuffDuration: Double = 10
    static let daytonaGainRatePerPurchase = 0.02

    // MARK: Persona cosmetics

    /// The one mechanical exception to "cosmetics are pure vanity": each equipped
    /// grail-tier item adds +0.5% to Clout gained on Rebrand — flex affects how
    /// seriously people take the rebrand, never Cash income.
    static let grailRebrandBonusPerItem = 0.005
}
