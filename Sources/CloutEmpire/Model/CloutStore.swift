import Foundation

enum CloutPurchase: String, Codable {
    case publicist
    case costCutShard
    case oneTimeSurge
}

struct CloutStorePurchase: Codable, Equatable, Identifiable {
    var id: String { "\(type.rawValue)-\(targetHustleID ?? "all")-\(timestamp.timeIntervalSince1970)" }
    let type: CloutPurchase
    let targetHustleID: String?
    let cloutSpent: Int
    let timestamp: Date
}

enum CloutStore {
    static let publicistCostFraction = 0.05
    static let costCutShardFraction = 0.10
    static let surgeCostFraction = 0.15
    static let confirmationThreshold = 0.15
    static let maxCostCutShardsPerHustle = 2
    static let costGrowthReductionPerShard = 0.02
    static let publicistCostCut = 0.10
    static let surgeDuration: Double = 60
    static let surgeIncomeMultiplier = 2.0
}
