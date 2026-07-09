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

    /// Item ids bought for Rex this run — wiped on Rebrand (his DMs go with the account).
    var ownedItems: Set<String> = []
    var equippedWrist: String?
    var equippedGarage: String?
    /// Daytona purchases — each is a permanent +2% Clout gain rate. Survives Rebrand;
    /// re-buyable every run, which makes it the one flex that compounds.
    var daytonaPurchases: Int = 0
    /// Player has opened Rex's DMs at least once (clears the "new DM" badge).
    var rexMet: Bool = false
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

    /// Rebrand keeps clout + lifetime cash (and Daytona's permanent bonus),
    /// wipes everything else — README §7. Rex's gear was rented anyway.
    mutating func rebrand(gaining gained: Double) {
        clout += gained
        cash = 0
        var fresh = [HustleState](repeating: HustleState(), count: Hustle.all.count)
        fresh[0].unitsOwned = 1
        hustles = fresh
        ownedItems = []
        equippedWrist = nil
        equippedGarage = nil
        milleBuffUntil = nil
        viralBuffUntil = nil
        // Persona (handle, look, cosmetics) is deliberately untouched:
        // the account gets deleted, the player doesn't.
    }

    // MARK: Codable (custom decode so pre-Rex saves still load)

    private enum CodingKeys: String, CodingKey {
        case cash, lifetimeCash, clout, hustles, lastSaved
        case ownedItems, equippedWrist, equippedGarage, daytonaPurchases, rexMet
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
        daytonaPurchases = try c.decodeIfPresent(Int.self, forKey: .daytonaPurchases) ?? 0
        rexMet = try c.decodeIfPresent(Bool.self, forKey: .rexMet) ?? false
        milleBuffUntil = try c.decodeIfPresent(Date.self, forKey: .milleBuffUntil)
        viralBuffUntil = try c.decodeIfPresent(Date.self, forKey: .viralBuffUntil)
        handle = try c.decodeIfPresent(String.self, forKey: .handle) ?? ""
        baseLook = try c.decodeIfPresent(String.self, forKey: .baseLook) ?? "hoodie"
        ownedCosmetics = try c.decodeIfPresent(Set<String>.self, forKey: .ownedCosmetics) ?? []
        equippedCosmetics = try c.decodeIfPresent([String: String].self, forKey: .equippedCosmetics) ?? [:]
        colorway = try c.decodeIfPresent(String.self, forKey: .colorway) ?? "gold"
    }
}
