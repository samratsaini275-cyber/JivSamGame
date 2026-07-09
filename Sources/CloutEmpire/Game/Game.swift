import Foundation
import Combine

enum BuyMode: String, CaseIterable, Identifiable {
    case one = "×1", ten = "×10", hundred = "×100", max = "Max"
    var id: String { rawValue }

    var count: Int? {
        switch self {
        case .one: return 1
        case .ten: return 10
        case .hundred: return 100
        case .max: return nil
        }
    }
}

/// Something the UI should celebrate: identity is per-emission so equal payloads
/// still retrigger animations.
struct GameEvent: Equatable, Identifiable {
    enum Kind: Equatable {
        case milestone(hustleIndex: Int, tier: Int)
        case hypeWave(tier: Int)
        case payout(hustleIndex: Int, amount: Double)
        case rebranded(clout: Double)
    }

    let id = UUID()
    let kind: Kind
}

/// Owns the game state and the 10 Hz tick loop. All mutations go through here.
final class Game: ObservableObject {
    @Published private(set) var state: GameState
    @Published var buyMode: BuyMode = .one
    /// Cash earned by staff while the app was closed; shown as a banner.
    @Published var offlineEarnings: Double = 0
    /// Latest celebration-worthy event; views observe this for toasts/particles.
    @Published private(set) var lastEvent: GameEvent?

    let hustles = Hustle.all

    private var timer: Timer?
    private let tickInterval = 0.1
    private var ticksSinceSave = 0

    init(state: GameState) {
        self.state = state
        grantOfflineEarnings()
        start()
    }

    static func loadOrNew() -> Game {
        Game(state: Persistence.load() ?? .newGame())
    }

    // MARK: Derived values

    var viralTier: Int { Formulas.viralTier(unitCounts: state.hustles.map(\.unitsOwned)) }

    /// Viral tier including the Borrowed Lambo's temporary "early Viral Moment" proc.
    var effectiveViralTier: Int { viralTier + (viralBuffActive ? 1 : 0) }

    var viralBuffActive: Bool { (state.viralBuffUntil ?? .distantPast) > Date() }
    var milleBuffActive: Bool { (state.milleBuffUntil ?? .distantPast) > Date() }

    /// How many hustles have reached the next viral tier — drives the header ring.
    var hustlesAtNextViralTier: Int {
        state.hustles.filter { Formulas.milestoneTier(units: $0.unitsOwned) > viralTier }.count
    }

    func tier(of index: Int) -> Int {
        Formulas.milestoneTier(units: state.hustles[index].unitsOwned)
    }

    private var maxHustleTier: Int {
        state.hustles.map { Formulas.milestoneTier(units: $0.unitsOwned) }.max() ?? 0
    }

    /// Best milestone tier across all hustles (money tier for DM unlocks).
    var maxMoneyTier: Int { maxHustleTier }

    /// The owned hustle with the fewest units — the Bugatti's beneficiary.
    var lowestOwnedHustleIndex: Int? {
        state.hustles.indices
            .filter { state.hustles[$0].unitsOwned > 0 }
            .min { state.hustles[$0].unitsOwned < state.hustles[$1].unitsOwned }
    }

    func cycleTime(of index: Int) -> Double {
        var cycleTier = tier(of: index)
        // Bugatti: the lowest-owned hustle stops being cycle-penalized for lagging —
        // it runs at the account's best milestone tier.
        if state.equippedGarage == "bugatti", index == lowestOwnedHustleIndex {
            cycleTier = max(cycleTier, maxHustleTier)
        }
        return Formulas.cycleTime(base: hustles[index].baseCycle, tier: cycleTier)
            * Formulas.garageCycleMultiplier(itemID: state.equippedGarage, hustleTier: tier(of: index))
    }

    /// Full payout of one completed post cycle, all multipliers applied.
    func incomePerCycle(of index: Int) -> Double {
        let h = hustles[index]
        let s = state.hustles[index]
        return h.baseIncome * Double(s.unitsOwned)
            * Formulas.incomeMultiplier(tier: tier(of: index))
            * pow(2, Double(effectiveViralTier))
            * Formulas.cloutMultiplier(clout: state.clout)
            * Formulas.wristIncomeMultiplier(itemID: state.equippedWrist, hustleTier: tier(of: index))
            * (milleBuffActive ? 2 : 1)
    }

    /// Aggregate automated income — the header's "per second" subtitle.
    var incomePerSecond: Double {
        state.hustles.indices.reduce(0) { sum, i in
            guard state.hustles[i].unitsOwned > 0, state.hustles[i].ghostwriterHired else { return sum }
            return sum + incomePerCycle(of: i) / cycleTime(of: i)
        }
    }

    func buyCount(for index: Int) -> Int {
        let h = hustles[index]
        let owned = state.hustles[index].unitsOwned
        if let count = buyMode.count { return count }
        return max(1, Formulas.maxAffordable(base: h.baseCost, owned: owned, cash: state.cash))
    }

    func buyCost(for index: Int) -> Double {
        Formulas.bulkCost(base: hustles[index].baseCost,
                          owned: state.hustles[index].unitsOwned,
                          count: buyCount(for: index))
    }

    var cloutOnRebrand: Double {
        Formulas.cloutGain(lifetimeCash: state.lifetimeCash,
                           currentClout: state.clout,
                           gainRateBonus: cloutGainRateBonus)
    }

    var cloutGainRateBonus: Double {
        Double(state.daytonaPurchases) * Formulas.daytonaGainRatePerPurchase
            + Double(equippedGrailCount) * Formulas.grailRebrandBonusPerItem
    }

    // MARK: Persona (the player's own character — cosmetic, survives Rebrand)

    var personaCreated: Bool { !state.handle.isEmpty }

    func createPersona(handle: String, look: String, colorway: String) {
        let trimmed = handle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        state.handle = trimmed
        state.baseLook = look
        state.colorway = colorway
    }

    func setColorway(_ id: String) {
        state.colorway = id
    }

    var equippedGrailCount: Int {
        state.equippedCosmetics.values
            .compactMap(PersonaItem.byID)
            .filter(\.isGrail)
            .count
    }

    func owns(_ item: PersonaItem) -> Bool { state.ownedCosmetics.contains(item.id) }

    func isEquipped(_ item: PersonaItem) -> Bool {
        state.equippedCosmetics[item.slot.rawValue] == item.id
    }

    @discardableResult
    func buyCosmetic(_ item: PersonaItem) -> Bool {
        guard !owns(item), state.cash >= item.cost else { return false }
        state.cash -= item.cost
        state.ownedCosmetics.insert(item.id)
        equipCosmetic(item)
        return true
    }

    func equipCosmetic(_ item: PersonaItem) {
        guard owns(item) else { return }
        state.equippedCosmetics[item.slot.rawValue] = item.id
    }

    var portraitImage: String {
        BaseLook.byID(state.baseLook).imageName
    }

    /// Legacy emoji portrait for saves — UI uses `portraitImage`.
    var portrait: String {
        let base = BaseLook.byID(state.baseLook).imageName
        let gear = PersonaSlot.allCases
            .compactMap { PersonaItem.byID(state.equippedCosmetics[$0.rawValue])?.imageName }
            .joined(separator: ",")
        return gear.isEmpty ? base : "\(base)|\(gear)"
    }

    var leaderboardEntry: LeaderboardEntry {
        LeaderboardEntry(id: state.handle, handle: state.handle, portraitImage: portraitImage,
                         clout: state.clout, lifetimeCash: state.lifetimeCash)
    }

    // MARK: Rex

    var rexUnlocked: Bool {
        sneakerResellsUnlocked || state.clout > 0
    }

    /// DMs tab unlocks after the player buys into Sneaker Resells (hustle 1).
    var sneakerResellsUnlocked: Bool {
        state.hustles[1].unitsOwned >= 1
    }

    var rexUnreadCount: Int {
        guard rexUnlocked else { return 0 }
        return RexDMThread.unlocked(for: self).filter { thread in
            let msgs = RexChatBuilder.messages(for: thread, game: self)
            return RexChatBuilder.pendingPitch(in: msgs, game: self) != nil
        }.count
    }

    var equippedWristItem: RexItem? { RexItem.byID(state.equippedWrist) }
    var equippedGarageItem: RexItem? { RexItem.byID(state.equippedGarage) }

    var rexBestTier: Int {
        max(equippedWristItem?.tier ?? 0, equippedGarageItem?.tier ?? 0)
    }

    func owns(_ item: RexItem) -> Bool { state.ownedItems.contains(item.id) }

    func isEquipped(_ item: RexItem) -> Bool {
        switch item.slot {
        case .wrist: return state.equippedWrist == item.id
        case .garage: return state.equippedGarage == item.id
        }
    }

    /// Buying auto-equips. Returns false if unaffordable (Rex: "Manifest harder.")
    @discardableResult
    func buyItem(_ item: RexItem) -> Bool {
        guard !owns(item), state.cash >= item.cost else { return false }
        state.cash -= item.cost
        state.ownedItems.insert(item.id)
        if item.id == "daytona" {
            state.daytonaPurchases += 1 // permanent, survives Rebrand
        }
        equip(item)
        return true
    }

    func equip(_ item: RexItem) {
        guard owns(item) else { return }
        switch item.slot {
        case .wrist: state.equippedWrist = item.id
        case .garage: state.equippedGarage = item.id
        }
    }

    func markRexMet() {
        if !state.rexMet { state.rexMet = true }
    }

    func handleRexReply(_ reply: RexReply, pitchID: String) {
        switch reply.action {
        case .introAck:
            state.rexIntroAcknowledged = true
            state.rexIntroReply = reply.label
        case .introCurious:
            state.rexIntroAcknowledged = true
            state.rexIntroReply = reply.label
        case .buy(let item):
            state.rexPitchReplies[pitchID] = reply.label
            if buyItem(item) {
                state.rexPitchFollowUp[pitchID] = Rex.purchaseBarks.randomElement()!
            } else {
                state.rexPitchFollowUp[pitchID] = Rex.brokeBark
            }
        case .equip(let item):
            state.rexPitchReplies[pitchID] = reply.label
            let prev = item.slot == .wrist
                ? equippedWristItem?.tier ?? 0
                : equippedGarageItem?.tier ?? 0
            equip(item)
            state.rexPitchFollowUp[pitchID] = item.tier < prev
                ? Rex.downgradeBark
                : Rex.idleBark(wrist: equippedWristItem, garage: equippedGarageItem)
        case .dismiss(let id):
            state.rexDismissedPitches.insert(id)
            state.rexPitchReplies[id] = reply.label
            state.rexPitchFollowUp[id] = "Fair. The flex will still be there when the bag catches up."
        }
    }

    // MARK: Player actions

    func buy(_ index: Int) {
        let count = buyCount(for: index)
        let cost = Formulas.bulkCost(base: hustles[index].baseCost,
                                     owned: state.hustles[index].unitsOwned,
                                     count: count)
        guard count > 0, state.cash >= cost else { return }
        let tierBefore = tier(of: index)
        let viralBefore = viralTier
        state.cash -= cost
        state.hustles[index].unitsOwned += count

        // "Richard Mille": every unit purchase doubles income for 10 seconds.
        if state.equippedWrist == "mille" {
            state.milleBuffUntil = Date().addingTimeInterval(Formulas.milleBuffDuration)
        }
        // Borrowed Lambo: crossing a milestone has a 25% chance to go viral early.
        if state.equippedGarage == "lambo", tier(of: index) > tierBefore,
           Double.random(in: 0..<1) < Formulas.lamboViralChance {
            state.viralBuffUntil = Date().addingTimeInterval(Formulas.lamboViralDuration)
        }

        // Celebrations — Hype Wave outranks a single business's milestone.
        if viralTier > viralBefore {
            lastEvent = GameEvent(kind: .hypeWave(tier: viralTier))
        } else if tier(of: index) > tierBefore {
            lastEvent = GameEvent(kind: .milestone(hustleIndex: index, tier: tier(of: index)))
        }
    }

    func post(_ index: Int) {
        guard state.hustles[index].unitsOwned > 0,
              !state.hustles[index].ghostwriterHired,
              !state.hustles[index].cycleRunning else { return }
        state.hustles[index].cycleRunning = true
        state.hustles[index].cycleProgress = 0
    }

    func hireGhostwriter(_ index: Int) {
        guard !state.hustles[index].ghostwriterHired,
              state.cash >= hustles[index].ghostwriterCost else { return }
        state.cash -= hustles[index].ghostwriterCost
        state.hustles[index].ghostwriterHired = true
    }

    func rebrand() {
        let gained = cloutOnRebrand
        guard gained > 0 else { return }
        state.rebrand(gaining: gained)
        save()
        lastEvent = GameEvent(kind: .rebranded(clout: gained))
    }

    // MARK: Tick loop

    private func start() {
        let timer = Timer(timeInterval: tickInterval, repeats: true) { [weak self] _ in
            self?.tick(dt: self?.tickInterval ?? 0)
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func tick(dt: Double) {
        for i in state.hustles.indices {
            let s = state.hustles[i]
            guard s.unitsOwned > 0 else { continue }
            let cycle = cycleTime(of: i)

            if s.ghostwriterHired {
                // Automated: credit every whole cycle completed this tick; fast
                // businesses can clear several per tick, which is what makes
                // their income read as per-second.
                let progress = s.cycleProgress + dt
                let completed = Int(progress / cycle)
                if completed > 0 {
                    let amount = Double(completed) * incomePerCycle(of: i)
                    deposit(amount)
                    // Only slow (≥1s) cycles pop particles — sub-second lines would spam.
                    if cycle >= 1 { lastEvent = GameEvent(kind: .payout(hustleIndex: i, amount: amount)) }
                }
                state.hustles[i].cycleProgress = progress - Double(completed) * cycle
            } else if s.cycleRunning {
                let progress = s.cycleProgress + dt
                if progress >= cycle {
                    let amount = incomePerCycle(of: i)
                    deposit(amount)
                    state.hustles[i].cycleRunning = false
                    state.hustles[i].cycleProgress = 0
                    lastEvent = GameEvent(kind: .payout(hustleIndex: i, amount: amount))
                } else {
                    state.hustles[i].cycleProgress = progress
                }
            }
        }

        ticksSinceSave += 1
        if ticksSinceSave >= 50 { // autosave every 5s
            ticksSinceSave = 0
            save()
        }
    }

    private func deposit(_ amount: Double) {
        state.cash += amount
        state.lifetimeCash += amount
    }

    // MARK: Persistence & offline earnings

    private func grantOfflineEarnings() {
        guard let last = state.lastSaved else { return }
        let elapsed = min(Date().timeIntervalSince(last), 24 * 3600)
        guard elapsed > 1 else { return }
        var earned = 0.0
        for i in state.hustles.indices where state.hustles[i].ghostwriterHired {
            earned += elapsed / cycleTime(of: i) * incomePerCycle(of: i)
        }
        if earned > 0 {
            deposit(earned)
            offlineEarnings = earned
        }
    }

    private func save() {
        state.lastSaved = Date()
        Persistence.save(state)
    }
}
