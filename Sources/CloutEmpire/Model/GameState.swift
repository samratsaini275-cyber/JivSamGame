import Foundation

/// Clout Store upgrades per hustle — survive Rebrand (hustle units reset, upgrades don't).
struct HustleCloutUpgrades: Codable, Equatable {
    var publicistHired: Bool = false
    var costCutShards: Int = 0
}

/// Per-hustle mutable state, persisted between launches.
struct HustleState: Codable {
    var unitsOwned: Int = 0
    var ghostwriterHired: Bool = false
    var cycleProgress: Double = 0
    var cycleRunning: Bool = false
}

/// Full Codable game snapshot.
struct GameState: Codable {
    var cash: Double = 0
    var lifetimeCash: Double = 0
    var availableClout: Double = 0
    var spentClout: Double = 0
    var hustles: [HustleState] = [HustleState](repeating: HustleState(), count: Hustle.all.count)
    var hustleCloutUpgrades: [String: HustleCloutUpgrades] = [:]
    var lastSaved: Date?

    var ownedItems: Set<String> = []
    var equippedWrist: String?
    var equippedGarage: String?
    var equippedPerks: Set<String> = []
    var dmThreads: [String: DMThreadState] = [:]
    var dealerRelationships: [String: DealerRelationship] = [:]
    var daytonaPurchases: Int = 0
    var rexMet: Bool = false

    var vaultThreadStarted: Bool = false
    var vaultThreadClosed: Bool = false
    var vaultIntroCompleted: Bool = false
    var vaultRespectsPlayer: Bool = false
    var vaultCurrentNode: String?
    var vaultLastClosedNode: String?
    var vaultTranscript: [VaultTranscriptEntry] = []

    var whipUnlocked: Bool = false
    var whipThreadStarted: Bool = false
    var whipThreadClosed: Bool = false
    var whipIntroCompleted: Bool = false
    var whipRespectsPlayer: Bool = false
    var whipCurrentNode: String?
    var whipLastClosedNode: String?
    var whipTranscript: [DMTranscriptEntry] = []

    var milleBuffUntil: Date?
    var viralBuffUntil: Date?
    var cloutSurgeUntil: Date?
    var cloutPurchaseLog: [CloutStorePurchase] = []

    var flexHeat: Double = 0
    var hypeMultiplier: Double = 1
    var hypeExpiresAt: Date?
    var exposedUntil: Date?
    var lastFlexAt: Date?
    var lifetimeFlexes: Int = 0
    var lifetimeExposures: Int = 0
    /// Reputation Manager charges (Clout Store) — eats the next exposure. Survives Rebrand.
    var repManagerCharges: Int = 0

    var handle: String = ""
    var baseLook: String = "hoodie"
    var colorway: String = "gold"
    var ownedCosmetics: Set<String> = []
    var equippedCosmetics: [String: String] = [:]

    var totalClout: Double { availableClout + spentClout }

    func cloutUpgrades(for hustleIndex: Int) -> HustleCloutUpgrades {
        hustleCloutUpgrades[String(hustleIndex)] ?? HustleCloutUpgrades()
    }

    mutating func updateCloutUpgrades(for hustleIndex: Int, _ mutate: (inout HustleCloutUpgrades) -> Void) {
        let key = String(hustleIndex)
        var upgrades = cloutUpgrades(for: hustleIndex)
        mutate(&upgrades)
        hustleCloutUpgrades[key] = upgrades
    }

    static func newGame() -> GameState {
        var state = GameState()
        state.hustles[0].unitsOwned = 1
        return state
    }

    mutating func normalizeHustleCount() {
        let target = Hustle.all.count
        if hustles.count < target {
            hustles.append(contentsOf: [HustleState](repeating: HustleState(), count: target - hustles.count))
        } else if hustles.count > target {
            hustles = Array(hustles.prefix(target))
        }
    }

    mutating func rebrand(gaining gained: Double) {
        availableClout += gained
        cash = 0
        var fresh = [HustleState](repeating: HustleState(), count: Hustle.all.count)
        fresh[0].unitsOwned = 1
        hustles = fresh
        milleBuffUntil = nil
        viralBuffUntil = nil
        cloutSurgeUntil = nil
        // New account, clean slate — Heat, Hype, and any active ratio all die
        // with the old persona. Lifetime counters and Rep Manager charges stay.
        flexHeat = 0
        hypeMultiplier = 1
        hypeExpiresAt = nil
        exposedUntil = nil
        lastFlexAt = nil
        resetDMThreadsForRebrand()
    }

    private enum CodingKeys: String, CodingKey {
        case cash, lifetimeCash, availableClout, spentClout, clout, hustles, hustleCloutUpgrades, lastSaved
        case ownedItems, equippedWrist, equippedGarage, equippedPerks, daytonaPurchases, rexMet
        case dmThreads, dealerRelationships
        case cloutSurgeUntil, cloutPurchaseLog
        case rexIntroAcknowledged, rexIntroReply, rexPitchReplies, rexPitchFollowUp, rexDismissedPitches
        case vaultThreadStarted, vaultThreadClosed, vaultIntroCompleted, vaultRespectsPlayer
        case vaultCurrentNode, vaultLastClosedNode, vaultTranscript
        case whipUnlocked, whipThreadStarted, whipThreadClosed, whipIntroCompleted, whipRespectsPlayer
        case whipCurrentNode, whipLastClosedNode, whipTranscript
        case milleBuffUntil, viralBuffUntil
        case flexHeat, hypeMultiplier, hypeExpiresAt, exposedUntil, lastFlexAt
        case lifetimeFlexes, lifetimeExposures, repManagerCharges
        case handle, baseLook, ownedCosmetics, equippedCosmetics, colorway
    }

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        cash = try c.decode(Double.self, forKey: .cash)
        lifetimeCash = try c.decode(Double.self, forKey: .lifetimeCash)
        if let available = try c.decodeIfPresent(Double.self, forKey: .availableClout) {
            availableClout = available
            spentClout = try c.decodeIfPresent(Double.self, forKey: .spentClout) ?? 0
        } else {
            availableClout = try c.decodeIfPresent(Double.self, forKey: .clout) ?? 0
            spentClout = 0
        }
        hustles = try c.decode([HustleState].self, forKey: .hustles)
        hustleCloutUpgrades = try c.decodeIfPresent([String: HustleCloutUpgrades].self, forKey: .hustleCloutUpgrades) ?? [:]
        lastSaved = try c.decodeIfPresent(Date.self, forKey: .lastSaved)
        ownedItems = try c.decodeIfPresent(Set<String>.self, forKey: .ownedItems) ?? []
        equippedWrist = try c.decodeIfPresent(String.self, forKey: .equippedWrist)
        equippedGarage = try c.decodeIfPresent(String.self, forKey: .equippedGarage)
        equippedPerks = try c.decodeIfPresent(Set<String>.self, forKey: .equippedPerks) ?? []
        daytonaPurchases = try c.decodeIfPresent(Int.self, forKey: .daytonaPurchases) ?? 0
        rexMet = try c.decodeIfPresent(Bool.self, forKey: .rexMet) ?? false
        let legacyIntro = try c.decodeIfPresent(Bool.self, forKey: .rexIntroAcknowledged) ?? false
        vaultThreadStarted = try c.decodeIfPresent(Bool.self, forKey: .vaultThreadStarted) ?? false
        vaultThreadClosed = try c.decodeIfPresent(Bool.self, forKey: .vaultThreadClosed) ?? false
        vaultIntroCompleted = try c.decodeIfPresent(Bool.self, forKey: .vaultIntroCompleted) ?? legacyIntro
        vaultRespectsPlayer = try c.decodeIfPresent(Bool.self, forKey: .vaultRespectsPlayer) ?? false
        vaultCurrentNode = try c.decodeIfPresent(String.self, forKey: .vaultCurrentNode)
        vaultLastClosedNode = try c.decodeIfPresent(String.self, forKey: .vaultLastClosedNode)
        vaultTranscript = try c.decodeIfPresent([VaultTranscriptEntry].self, forKey: .vaultTranscript) ?? []
        whipUnlocked = try c.decodeIfPresent(Bool.self, forKey: .whipUnlocked) ?? false
        whipThreadStarted = try c.decodeIfPresent(Bool.self, forKey: .whipThreadStarted) ?? false
        whipThreadClosed = try c.decodeIfPresent(Bool.self, forKey: .whipThreadClosed) ?? false
        whipIntroCompleted = try c.decodeIfPresent(Bool.self, forKey: .whipIntroCompleted) ?? false
        whipRespectsPlayer = try c.decodeIfPresent(Bool.self, forKey: .whipRespectsPlayer) ?? false
        whipCurrentNode = try c.decodeIfPresent(String.self, forKey: .whipCurrentNode)
        whipLastClosedNode = try c.decodeIfPresent(String.self, forKey: .whipLastClosedNode)
        whipTranscript = try c.decodeIfPresent([DMTranscriptEntry].self, forKey: .whipTranscript) ?? []
        dmThreads = try c.decodeIfPresent([String: DMThreadState].self, forKey: .dmThreads) ?? [:]
        migrateLegacyDMThreadsIfNeeded()
        dealerRelationships = try c.decodeIfPresent([String: DealerRelationship].self, forKey: .dealerRelationships) ?? [:]
        migrateDealerRelationshipsFromThreads()
        cloutSurgeUntil = try c.decodeIfPresent(Date.self, forKey: .cloutSurgeUntil)
        cloutPurchaseLog = try c.decodeIfPresent([CloutStorePurchase].self, forKey: .cloutPurchaseLog) ?? []
        milleBuffUntil = try c.decodeIfPresent(Date.self, forKey: .milleBuffUntil)
        viralBuffUntil = try c.decodeIfPresent(Date.self, forKey: .viralBuffUntil)
        flexHeat = try c.decodeIfPresent(Double.self, forKey: .flexHeat) ?? 0
        hypeMultiplier = try c.decodeIfPresent(Double.self, forKey: .hypeMultiplier) ?? 1
        hypeExpiresAt = try c.decodeIfPresent(Date.self, forKey: .hypeExpiresAt)
        exposedUntil = try c.decodeIfPresent(Date.self, forKey: .exposedUntil)
        lastFlexAt = try c.decodeIfPresent(Date.self, forKey: .lastFlexAt)
        lifetimeFlexes = try c.decodeIfPresent(Int.self, forKey: .lifetimeFlexes) ?? 0
        lifetimeExposures = try c.decodeIfPresent(Int.self, forKey: .lifetimeExposures) ?? 0
        repManagerCharges = try c.decodeIfPresent(Int.self, forKey: .repManagerCharges) ?? 0
        handle = try c.decodeIfPresent(String.self, forKey: .handle) ?? ""
        baseLook = try c.decodeIfPresent(String.self, forKey: .baseLook) ?? "hoodie"
        ownedCosmetics = try c.decodeIfPresent(Set<String>.self, forKey: .ownedCosmetics) ?? []
        equippedCosmetics = try c.decodeIfPresent([String: String].self, forKey: .equippedCosmetics) ?? [:]
        colorway = try c.decodeIfPresent(String.self, forKey: .colorway) ?? "gold"
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(cash, forKey: .cash)
        try c.encode(lifetimeCash, forKey: .lifetimeCash)
        try c.encode(availableClout, forKey: .availableClout)
        try c.encode(spentClout, forKey: .spentClout)
        try c.encode(hustles, forKey: .hustles)
        try c.encode(hustleCloutUpgrades, forKey: .hustleCloutUpgrades)
        try c.encodeIfPresent(lastSaved, forKey: .lastSaved)
        try c.encode(ownedItems, forKey: .ownedItems)
        try c.encodeIfPresent(equippedWrist, forKey: .equippedWrist)
        try c.encodeIfPresent(equippedGarage, forKey: .equippedGarage)
        try c.encode(equippedPerks, forKey: .equippedPerks)
        try c.encode(daytonaPurchases, forKey: .daytonaPurchases)
        try c.encode(rexMet, forKey: .rexMet)
        try c.encode(vaultThreadStarted, forKey: .vaultThreadStarted)
        try c.encode(vaultThreadClosed, forKey: .vaultThreadClosed)
        try c.encode(vaultIntroCompleted, forKey: .vaultIntroCompleted)
        try c.encode(vaultRespectsPlayer, forKey: .vaultRespectsPlayer)
        try c.encodeIfPresent(vaultCurrentNode, forKey: .vaultCurrentNode)
        try c.encodeIfPresent(vaultLastClosedNode, forKey: .vaultLastClosedNode)
        try c.encode(vaultTranscript, forKey: .vaultTranscript)
        try c.encode(whipUnlocked, forKey: .whipUnlocked)
        try c.encode(whipThreadStarted, forKey: .whipThreadStarted)
        try c.encode(whipThreadClosed, forKey: .whipThreadClosed)
        try c.encode(whipIntroCompleted, forKey: .whipIntroCompleted)
        try c.encode(whipRespectsPlayer, forKey: .whipRespectsPlayer)
        try c.encodeIfPresent(whipCurrentNode, forKey: .whipCurrentNode)
        try c.encodeIfPresent(whipLastClosedNode, forKey: .whipLastClosedNode)
        try c.encode(whipTranscript, forKey: .whipTranscript)
        try c.encode(dmThreads, forKey: .dmThreads)
        try c.encode(dealerRelationships, forKey: .dealerRelationships)
        try c.encodeIfPresent(cloutSurgeUntil, forKey: .cloutSurgeUntil)
        try c.encode(cloutPurchaseLog, forKey: .cloutPurchaseLog)
        try c.encodeIfPresent(milleBuffUntil, forKey: .milleBuffUntil)
        try c.encodeIfPresent(viralBuffUntil, forKey: .viralBuffUntil)
        try c.encode(flexHeat, forKey: .flexHeat)
        try c.encode(hypeMultiplier, forKey: .hypeMultiplier)
        try c.encodeIfPresent(hypeExpiresAt, forKey: .hypeExpiresAt)
        try c.encodeIfPresent(exposedUntil, forKey: .exposedUntil)
        try c.encodeIfPresent(lastFlexAt, forKey: .lastFlexAt)
        try c.encode(lifetimeFlexes, forKey: .lifetimeFlexes)
        try c.encode(lifetimeExposures, forKey: .lifetimeExposures)
        try c.encode(repManagerCharges, forKey: .repManagerCharges)
        try c.encode(handle, forKey: .handle)
        try c.encode(baseLook, forKey: .baseLook)
        try c.encode(ownedCosmetics, forKey: .ownedCosmetics)
        try c.encode(equippedCosmetics, forKey: .equippedCosmetics)
        try c.encode(colorway, forKey: .colorway)
    }
}
