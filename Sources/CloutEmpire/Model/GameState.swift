import Foundation

/// Per-hustle mutable state, persisted between launches.
struct HustleState: Codable {
    var unitsOwned: Int = 0
    var ghostwriterHired: Bool = false
    var cycleProgress: Double = 0 // seconds elapsed in the current post cycle
    var cycleRunning: Bool = false // manual hustles need a tap to start a cycle
}

/// Full Codable game snapshot.
struct GameState: Codable {
    var cash: Double = 0
    /// All-time earnings; persists across Rebrands and drives the Clout formula.
    var lifetimeCash: Double = 0
    var clout: Double = 0
    var hustles: [HustleState] = [HustleState](repeating: HustleState(), count: Hustle.all.count)
    var lastSaved: Date?

    // MARK: Rex Calloway's flex economy

    /// Dealer flex items bought via DMs — survives Rebrand with the player.
    var ownedItems: Set<String> = []
    var equippedWrist: String?
    var equippedGarage: String?
    var equippedPerks: Set<String> = []
    /// Per-dealer DM thread state (key = DMDealer.rawValue).
    var dmThreads: [String: DMThreadState] = [:]
    /// Daytona purchases — each is a permanent +2% Clout gain rate. Survives Rebrand;
    /// re-buyable every run, which makes it the one flex that compounds.
    var daytonaPurchases: Int = 0
    /// Player has opened DMs at least once (clears the inbox badge).
    var rexMet: Bool = false

    // MARK: Vinnie "The Vault" DM script

    var vaultThreadStarted: Bool = false
    var vaultThreadClosed: Bool = false
    var vaultIntroCompleted: Bool = false
    var vaultRespectsPlayer: Bool = false
    var vaultCurrentNode: String?
    var vaultLastClosedNode: String?
    var vaultTranscript: [VaultTranscriptEntry] = []

    // MARK: Dre "Whip Game" DM script

    var whipUnlocked: Bool = false
    var whipThreadStarted: Bool = false
    var whipThreadClosed: Bool = false
    var whipIntroCompleted: Bool = false
    var whipRespectsPlayer: Bool = false
    var whipCurrentNode: String?
    var whipLastClosedNode: String?
    var whipTranscript: [DMTranscriptEntry] = []

    /// "Richard Mille" buff: ×2 income until this instant.
    var milleBuffUntil: Date?
    /// Borrowed Lambo proc: +1 Viral tier until this instant.
    var viralBuffUntil: Date?

    // MARK: The player's Persona (identity + leaderboard ID; all of it survives Rebrand)

    /// Brand handle, doubles as leaderboard ID. Empty = persona not created yet.
    var handle: String = ""
    var baseLook: String = "hoodie"
    /// Brand colorway id — tints the entire UI accent. "Your own aesthetic," literally.
    var colorway: String = "gold"
    var ownedCosmetics: Set<String> = []
    /// PersonaSlot rawValue → PersonaItem id.
    var equippedCosmetics: [String: String] = [:]

    static func newGame() -> GameState {
        var state = GameState()
        state.hustles[0].unitsOwned = 1 // start already posting fake P&Ls
        return state
    }

    /// Rebrand keeps clout, lifetime cash, fit/gear, persona, and Daytona legacy.
    /// Hustles, cash, staff, and DM thread progress reset — dealers remember the vibe.
    mutating func rebrand(gaining gained: Double) {
        clout += gained
        cash = 0
        var fresh = [HustleState](repeating: HustleState(), count: Hustle.all.count)
        fresh[0].unitsOwned = 1
        hustles = fresh
        milleBuffUntil = nil
        viralBuffUntil = nil
        resetDMThreadsForRebrand()
        // ownedItems, equippedWrist/Garage/Perks, persona, daytonaPurchases survive.
    }

    // MARK: Codable (custom decode so pre-Rex saves still load)

    private enum CodingKeys: String, CodingKey {
        case cash, lifetimeCash, clout, hustles, lastSaved
        case ownedItems, equippedWrist, equippedGarage, equippedPerks, daytonaPurchases, rexMet
        case dmThreads
        case rexIntroAcknowledged, rexIntroReply, rexPitchReplies, rexPitchFollowUp, rexDismissedPitches
        case vaultThreadStarted, vaultThreadClosed, vaultIntroCompleted, vaultRespectsPlayer
        case vaultCurrentNode, vaultLastClosedNode, vaultTranscript
        case whipUnlocked, whipThreadStarted, whipThreadClosed, whipIntroCompleted, whipRespectsPlayer
        case whipCurrentNode, whipLastClosedNode, whipTranscript
        case milleBuffUntil, viralBuffUntil
        case handle, baseLook, ownedCosmetics, equippedCosmetics, colorway
    }

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        cash = try c.decode(Double.self, forKey: .cash)
        lifetimeCash = try c.decode(Double.self, forKey: .lifetimeCash)
        clout = try c.decode(Double.self, forKey: .clout)
        hustles = try c.decode([HustleState].self, forKey: .hustles)
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
        milleBuffUntil = try c.decodeIfPresent(Date.self, forKey: .milleBuffUntil)
        viralBuffUntil = try c.decodeIfPresent(Date.self, forKey: .viralBuffUntil)
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
        try c.encode(clout, forKey: .clout)
        try c.encode(hustles, forKey: .hustles)
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
        try c.encodeIfPresent(milleBuffUntil, forKey: .milleBuffUntil)
        try c.encodeIfPresent(viralBuffUntil, forKey: .viralBuffUntil)
        try c.encode(handle, forKey: .handle)
        try c.encode(baseLook, forKey: .baseLook)
        try c.encode(ownedCosmetics, forKey: .ownedCosmetics)
        try c.encode(equippedCosmetics, forKey: .equippedCosmetics)
        try c.encode(colorway, forKey: .colorway)
    }
}
