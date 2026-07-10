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
        case newDM(dealer: DMDealer)
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
        reconcileDMThreadStates()
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
    var cloutSurgeActive: Bool { (state.cloutSurgeUntil ?? .distantPast) > Date() }
    var cloutSurgeRemaining: TimeInterval {
        guard cloutSurgeActive, let until = state.cloutSurgeUntil else { return 0 }
        return until.timeIntervalSinceNow
    }

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
            * Formulas.perkCycleMultiplier(equippedPerks: state.equippedPerks, hustleTier: tier(of: index))
    }

    /// Full payout of one completed post cycle, all multipliers applied.
    func incomePerCycle(of index: Int) -> Double {
        let h = hustles[index]
        let s = state.hustles[index]
        return h.baseIncome * Double(s.unitsOwned)
            * Formulas.incomeMultiplier(tier: tier(of: index))
            * pow(2, Double(effectiveViralTier))
            * Formulas.cloutMultiplier(clout: state.availableClout)
            * Formulas.wristIncomeMultiplier(itemID: state.equippedWrist, hustleTier: tier(of: index))
            * Formulas.perkIncomeMultiplier(equippedPerks: state.equippedPerks, hustleTier: tier(of: index))
            * (milleBuffActive ? 2 : 1)
            * (cloutSurgeActive ? CloutStore.surgeIncomeMultiplier : 1)
    }

    /// Aggregate automated income — the header's "per second" subtitle.
    var incomePerSecond: Double {
        state.hustles.indices.reduce(0) { sum, i in
            guard state.hustles[i].unitsOwned > 0, state.hustles[i].ghostwriterHired else { return sum }
            return sum + incomePerCycle(of: i) / cycleTime(of: i)
        }
    }

    func costGrowth(for index: Int) -> Double {
        let shards = state.cloutUpgrades(for: index).costCutShards
        return Formulas.costGrowth(shards: shards)
    }

    func buyCount(for index: Int) -> Int {
        let h = hustles[index]
        let owned = state.hustles[index].unitsOwned
        if let count = buyMode.count { return count }
        return max(1, Formulas.maxAffordable(base: h.baseCost, owned: owned, cash: state.cash, growth: costGrowth(for: index)))
    }

    func buyCost(for index: Int) -> Double {
        var cost = Formulas.bulkCost(base: hustles[index].baseCost,
                                     owned: state.hustles[index].unitsOwned,
                                     count: buyCount(for: index),
                                     growth: costGrowth(for: index))
        if state.cloutUpgrades(for: index).publicistHired {
            cost *= (1 - CloutStore.publicistCostCut)
        }
        return cost
    }

    var cloutOnRebrand: Double {
        Formulas.cloutGain(lifetimeCash: state.lifetimeCash,
                           currentClout: state.totalClout,
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
                         clout: state.totalClout, lifetimeCash: state.lifetimeCash)
    }

    // MARK: Rex

    var rexUnlocked: Bool {
        sneakerResellsUnlocked || state.totalClout > 0
    }

    /// DMs tab unlocks after the player buys into Sneaker Resells (hustle 1).
    var sneakerResellsUnlocked: Bool {
        state.hustles[1].unitsOwned >= 1
    }

    /// Dre unlocks when the player launches Custom Hoodies (hustle 2).
    var customHoodiesUnlocked: Bool {
        hustleUnlockedForDM(Hustle.customHoodiesIndex)
    }

    func hustleUnlockedForDM(_ index: Int) -> Bool {
        state.hustles[index].unitsOwned >= 1
    }

    var rexUnreadCount: Int {
        visibleDMThreads().filter { DMDialogueEngine.hasUnreadChoices(dealer: $0, game: self) }.count
    }

    func visibleDMThreads() -> [DMDealer] {
        guard rexUnlocked else { return [] }
        return DMDealer.allCases.filter { hustleUnlockedForDM($0.hustleIndex) }
    }

    func isDMInboxVisible(_ dealer: DMDealer) -> Bool {
        rexUnlocked && hustleUnlockedForDM(dealer.hustleIndex)
    }

    func hasRemainingDMOffers(_ dealer: DMDealer) -> Bool {
        dealer.offerItemIDs.contains { id in
            guard let item = RexItem.byID(id) else { return false }
            return !owns(item)
        }
    }

    func shouldReopenDMOffer(_ dealer: DMDealer) -> Bool {
        let thread = state.dmThread(for: dealer)
        guard thread.threadClosed, hasRemainingDMOffers(dealer) else { return false }
        guard let lastClosed = thread.lastClosedNode,
              dealer.reopenableClosedNodes.contains(lastClosed) else { return false }
        return true
    }

    func dmTranscript(for dealer: DMDealer) -> [DMTranscriptEntry] {
        let thread = state.dmThread(for: dealer)
        if isViewingComeback(dealer) { return thread.comebackTranscript }
        return thread.transcript
    }

    func dmCurrentNode(for dealer: DMDealer) -> String? {
        let thread = state.dmThread(for: dealer)
        if isViewingComeback(dealer) { return thread.comebackCurrentNode }
        return thread.currentNode
    }

    private func isViewingComeback(_ dealer: DMDealer) -> Bool {
        let thread = state.dmThread(for: dealer)
        if thread.comebackCurrentNode != nil { return true }
        if thread.comebackThreadStarted && !thread.comebackTranscript.isEmpty { return true }
        if state.dealerRelationship(for: dealer).comebackPending && !thread.comebackThreadStarted { return true }
        return false
    }

    func hasUnreadComeback(_ dealer: DMDealer) -> Bool {
        let rel = state.dealerRelationship(for: dealer)
        let thread = state.dmThread(for: dealer)
        guard rel.respectLevel >= 1, !rel.comebackThreadCompleted else { return false }
        if rel.comebackPending && !thread.comebackThreadStarted { return true }
        if shouldReopenComeback(dealer) { return true }
        if let nodeID = thread.comebackCurrentNode, !thread.comebackThreadClosed {
            return !DMScripts.choices(for: dealer, nodeID: nodeID, game: self).isEmpty
        }
        return false
    }

    func shouldReopenComeback(_ dealer: DMDealer) -> Bool {
        let thread = state.dmThread(for: dealer)
        guard thread.comebackThreadClosed else { return false }
        guard !state.dealerRelationship(for: dealer).comebackThreadCompleted else { return false }
        guard let last = thread.comebackLastClosedNode,
              DMComebackScripts.reopenableNodes(for: dealer).contains(last) else { return false }
        return true
    }

    func ownedRexItems(for slot: ItemSlot) -> [RexItem] {
        RexItem.forSlot(slot).filter { owns($0) }
    }

    var hasFitItems: Bool { !state.ownedItems.isEmpty }
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
        case .perk: return state.equippedPerks.contains(item.id)
        }
    }

    /// Buying auto-equips. Returns false if unaffordable (Rex: "Manifest harder.")
    @discardableResult
    func buyItem(_ item: RexItem) -> Bool {
        let cost = price(for: item)
        guard !owns(item), state.cash >= cost else { return false }
        state.cash -= cost
        state.ownedItems.insert(item.id)
        if item.id == "daytona" {
            state.daytonaPurchases += 1 // permanent, survives Rebrand
        }
        equip(item)
        return true
    }

    /// Dealer respect + referral discounts on premium opening offers.
    func price(for item: RexItem, favorDiscount: Double? = nil) -> Double {
        var cost = item.cost
        if let dealer = item.dealer {
            let rel = state.dealerRelationship(for: dealer)
            if rel.respectLevel >= 1 || state.dmThread(for: dealer).respectsPlayer {
                cost *= 0.9
            }
            if item.id == dealer.premiumItemID, rel.referredOpeningDiscount > 0 {
                cost *= (1 - rel.referredOpeningDiscount)
            }
        }
        if let favorDiscount {
            cost *= (1 - favorDiscount)
        }
        return cost.rounded(.down)
    }

    /// Active perk boost labels for the HUD.
    var activePerkBoostLabels: [String] {
        state.equippedPerks.compactMap { RexItem.byID($0)?.boostText }
    }

    /// Short label for the active wrist boost shown in the HUD.
    var activeWatchBoostLabel: String? {
        guard let item = equippedWristItem else { return nil }
        return "\(item.name) · \(item.boostText)"
    }

    /// Short label for the active garage boost shown in the HUD.
    var activeGarageBoostLabel: String? {
        guard let item = equippedGarageItem else { return nil }
        return "\(item.name) · \(item.boostText)"
    }

    func canEquipPerk(_ item: RexItem) -> Bool {
        guard item.slot == .perk, owns(item) else { return false }
        return isEquipped(item) || state.equippedPerks.count < RexItem.maxEquippedPerks
    }

    func unequip(_ item: RexItem) {
        guard owns(item) else { return }
        switch item.slot {
        case .wrist:
            if state.equippedWrist == item.id { state.equippedWrist = nil }
        case .garage:
            if state.equippedGarage == item.id { state.equippedGarage = nil }
        case .perk:
            state.equippedPerks.remove(item.id)
        }
    }

    func equip(_ item: RexItem) {
        guard owns(item) else { return }
        switch item.slot {
        case .wrist: state.equippedWrist = item.id
        case .garage: state.equippedGarage = item.id
        case .perk:
            guard !state.equippedPerks.contains(item.id) else { return }
            guard state.equippedPerks.count < RexItem.maxEquippedPerks else { return }
            state.equippedPerks.insert(item.id)
        }
    }

    func markRexMet() {
        if !state.rexMet { state.rexMet = true }
    }

    func onDMThreadOpened(_ dealer: DMDealer) {
        if shouldStartComeback(dealer) {
            startComebackThread(dealer)
            return
        }
        if shouldReopenComeback(dealer) {
            reopenComebackThread(dealer)
            return
        }
        startDMThreadIfNeeded(dealer)
        guard shouldReopenDMOffer(dealer) else { return }
        state.updateDMThread(dealer) { thread in
            thread.threadClosed = false
            thread.currentNode = dealer.offerNodeID(for: state)
        }
    }

    private func shouldStartComeback(_ dealer: DMDealer) -> Bool {
        let rel = state.dealerRelationship(for: dealer)
        let thread = state.dmThread(for: dealer)
        guard rel.respectLevel >= 1, !rel.comebackThreadCompleted else { return false }
        return rel.comebackPending && !thread.comebackThreadStarted
    }

    private func startComebackThread(_ dealer: DMDealer) {
        state.updateDMThread(dealer) { thread in
            thread.comebackThreadStarted = true
            thread.comebackThreadClosed = false
        }
        state.updateDealerRelationship(dealer) { $0.comebackPending = false }
        enterComebackNode(dealer, DMComebackScripts.startingNodeID(for: dealer))
    }

    private func reopenComebackThread(_ dealer: DMDealer) {
        let thread = state.dmThread(for: dealer)
        let prefix = DMComebackScripts.specs[dealer]?.prefix ?? dealer.scriptPrefix
        let offerID = "\(prefix)_return_offer"
        let nodeID: String
        if let last = thread.comebackLastClosedNode,
           DMComebackScripts.reopenableNodes(for: dealer).contains(last) {
            nodeID = last.hasSuffix("_return_decline") ? offerID : last
        } else {
            nodeID = offerID
        }
        state.updateDMThread(dealer) { thread in
            thread.comebackThreadClosed = false
            thread.comebackCurrentNode = nodeID
        }
    }

    func startDMThreadIfNeeded(_ dealer: DMDealer) {
        guard isDMInboxVisible(dealer) else { return }
        let started = state.dmThread(for: dealer).threadStarted
        guard !started else { return }
        state.updateDMThread(dealer) { $0.threadStarted = true }
        enterDMNode(dealer, dealer.startingNodeID(for: state))
    }

    func startAllDMThreadsIfNeeded() {
        reconcileDMThreadStates()
        for dealer in visibleDMThreads() {
            startDMThreadIfNeeded(dealer)
        }
    }

    /// Clears DM threads that started before their hustle was unlocked.
    private func reconcileDMThreadStates() {
        for dealer in DMDealer.allCases {
            guard !hustleUnlockedForDM(dealer.hustleIndex) else { continue }
            let thread = state.dmThread(for: dealer)
            guard thread.threadStarted || !thread.transcript.isEmpty else { continue }
            state.updateDMThread(dealer) { t in
                t = DMThreadState()
            }
        }
    }

    func selectDMChoice(_ dealer: DMDealer, _ choice: DMChoice) {
        let comeback = isViewingComeback(dealer)
        let nodeID = dmCurrentNode(for: dealer)
        guard let nodeID,
              DMScripts.node(dealer, id: nodeID) != nil else { return }
        guard DMScripts.canSelect(choice, game: self) else { return }

        if comeback {
            appendComebackTranscript(dealer, .player(choice.label))
            enterComebackNode(dealer, choice.nextNodeID)
        } else {
            appendDMTranscript(dealer, .player(choice.label))
            enterDMNode(dealer, choice.nextNodeID)
        }
    }

    // Legacy wrappers
    func onVaultThreadOpened() { onDMThreadOpened(.vinnie) }
    func startVaultThreadIfNeeded() { startDMThreadIfNeeded(.vinnie) }
    func reopenVaultThread() { onVaultThreadOpened() }
    func selectVaultChoice(_ choice: DMChoice) { selectDMChoice(.vinnie, choice) }

    private func enterComebackNode(_ dealer: DMDealer, _ nodeID: String) {
        guard let node = DMScripts.node(dealer, id: nodeID), node.isComeback else { return }
        let itemName = state.dealerRelationship(for: dealer).premiumItemID
            .flatMap { RexItem.byID($0)?.name } ?? dealer.premiumItemName

        for effect in node.effects {
            applyDMEffect(effect, dealer: dealer, favorDiscount: nil)
        }

        for bubble in node.bubbles {
            switch bubble {
            case .text(let text):
                let line = DMComebackScripts.interpolate(text, itemName: itemName)
                appendComebackTranscript(dealer, .contact(line))
            case .itemCard(let itemID, let caption):
                appendComebackTranscript(dealer, .contactItem(itemID, caption: caption))
            }
        }

        if node.closesThread {
            state.updateDMThread(dealer) { thread in
                thread.comebackThreadClosed = true
                thread.comebackLastClosedNode = nodeID
                thread.comebackCurrentNode = nil
            }
        } else {
            state.updateDMThread(dealer) { $0.comebackCurrentNode = nodeID }
        }
    }

    private func appendComebackTranscript(_ dealer: DMDealer, _ entry: DMTranscriptEntry) {
        state.updateDMThread(dealer) { $0.comebackTranscript.append(entry) }
    }

    private func enterDMNode(_ dealer: DMDealer, _ nodeID: String) {
        guard let node = DMScripts.node(dealer, id: nodeID) else { return }

        for effect in node.effects {
            applyDMEffect(effect, dealer: dealer, favorDiscount: nil)
        }

        for bubble in node.bubbles {
            switch bubble {
            case .text(let text):
                appendDMTranscript(dealer, .contact(text))
            case .itemCard(let itemID, let caption):
                appendDMTranscript(dealer, .contactItem(itemID, caption: caption))
            }
        }

        if node.closesThread {
            state.updateDMThread(dealer) { thread in
                thread.threadClosed = true
                thread.lastClosedNode = nodeID
                thread.currentNode = nil
                if dealer.introCompletedNodeIDs.contains(nodeID) {
                    thread.introCompleted = true
                }
            }
        } else {
            state.updateDMThread(dealer) { $0.currentNode = nodeID }
        }
    }

    private func appendDMTranscript(_ dealer: DMDealer, _ entry: DMTranscriptEntry) {
        state.updateDMThread(dealer) { $0.transcript.append(entry) }
    }

    private func applyDMEffect(_ effect: DMEffect, dealer: DMDealer, favorDiscount: Double?) {
        switch effect {
        case .buyAndEquip(let itemID):
            guard let item = RexItem.byID(itemID) else { return }
            _ = buyItem(item)
        case .buyAndEquipDiscounted(let itemID, let discount):
            guard let item = RexItem.byID(itemID) else { return }
            let cost = price(for: item, favorDiscount: discount)
            guard !owns(item), state.cash >= cost else { return }
            state.cash -= cost
            state.ownedItems.insert(item.id)
            if item.id == "daytona" { state.daytonaPurchases += 1 }
            equip(item)
        case .setPremiumRespect(let itemID, let respectDealer):
            let hustleTier = tier(of: respectDealer.hustleIndex)
            state.updateDMThread(respectDealer) { $0.respectsPlayer = true }
            state.updateDealerRelationship(respectDealer) { rel in
                rel.respectLevel = max(rel.respectLevel, 1)
                rel.premiumItemID = itemID
                rel.lastPurchaseHustleTier = hustleTier
            }
        case .setReferralDiscount(let target, let fraction):
            state.updateDealerRelationship(target) { rel in
                rel.referredOpeningDiscount = max(rel.referredOpeningDiscount, fraction)
            }
        case .completeComeback:
            state.updateDealerRelationship(dealer) { rel in
                rel.respectLevel = 2
                rel.comebackThreadCompleted = true
                rel.hasSeenComebackIntro = true
                rel.comebackPending = false
            }
        case .markComebackIntroSeen:
            state.updateDealerRelationship(dealer) { rel in
                rel.hasSeenComebackIntro = true
                rel.comebackPending = false
            }
        }
    }

    private func checkComebackTriggers(hustleIndex: Int, newTier: Int) {
        guard let dealer = DMDealer.forHustle(hustleIndex) else { return }
        let rel = state.dealerRelationship(for: dealer)
        guard rel.respectLevel >= 1,
              !rel.hasSeenComebackIntro,
              !rel.comebackThreadCompleted,
              newTier >= rel.lastPurchaseHustleTier + 2 else { return }
        state.updateDealerRelationship(dealer) { $0.comebackPending = true }
        lastEvent = GameEvent(kind: .newDM(dealer: dealer))
    }

    private func notifyDMAvailableIfNeeded(hustleIndex: Int, hadUnitsBefore: Bool) {
        guard !hadUnitsBefore,
              hustleUnlockedForDM(hustleIndex),
              let dealer = DMDealer.forHustle(hustleIndex) else { return }
        lastEvent = GameEvent(kind: .newDM(dealer: dealer))
    }

    func prepareDMInbox() {
        reconcileDMThreadStates()
    }

    // MARK: Dev

    func devAddCash(_ amount: Double) {
        guard amount > 0 else { return }
        state.cash += amount
    }

    // MARK: Player actions

    func buy(_ index: Int) {
        let count = buyCount(for: index)
        let cost = Formulas.bulkCost(base: hustles[index].baseCost,
                                     owned: state.hustles[index].unitsOwned,
                                     count: count,
                                     growth: costGrowth(for: index))
        guard count > 0, state.cash >= cost else { return }
        let tierBefore = tier(of: index)
        let viralBefore = viralTier
        let hadUnits = state.hustles[index].unitsOwned >= 1
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

        notifyDMAvailableIfNeeded(hustleIndex: index, hadUnitsBefore: hadUnits)
        if tier(of: index) > tierBefore {
            checkComebackTriggers(hustleIndex: index, newTier: tier(of: index))
        }
    }

    // MARK: Clout Store

    func cloutPurchaseCost(type: CloutPurchase, hustleIndex: Int? = nil) -> Int {
        let fraction: Double = switch type {
        case .publicist: CloutStore.publicistCostFraction
        case .costCutShard: CloutStore.costCutShardFraction
        case .oneTimeSurge: CloutStore.surgeCostFraction
        }
        return max(1, Int(floor(state.availableClout * fraction)))
    }

    func cloutPurchaseNeedsConfirmation(type: CloutPurchase, hustleIndex: Int? = nil) -> Bool {
        let cost = cloutPurchaseCost(type: type, hustleIndex: hustleIndex)
        let fraction = Double(cost) / max(state.availableClout, 1)
        return fraction >= CloutStore.confirmationThreshold - 1e-9
    }

    func permanentIncomeLossPercent(forCloutCost cost: Int) -> Int {
        Int((Double(cost) * Formulas.cloutBonusPerPoint * 100).rounded())
    }

    func canPurchaseClout(type: CloutPurchase, hustleIndex: Int? = nil) -> Bool {
        let cost = cloutPurchaseCost(type: type, hustleIndex: hustleIndex)
        guard cost > 0, state.availableClout >= Double(cost) else { return false }
        switch type {
        case .publicist:
            guard let i = hustleIndex else { return false }
            return !state.cloutUpgrades(for: i).publicistHired
        case .costCutShard:
            guard let i = hustleIndex else { return false }
            return state.cloutUpgrades(for: i).costCutShards < CloutStore.maxCostCutShardsPerHustle
        case .oneTimeSurge:
            return true
        }
    }

    @discardableResult
    func purchaseClout(type: CloutPurchase, hustleIndex: Int? = nil) -> Bool {
        guard canPurchaseClout(type: type, hustleIndex: hustleIndex) else { return false }
        let cost = cloutPurchaseCost(type: type, hustleIndex: hustleIndex)
        guard state.availableClout >= Double(cost) else { return false }

        state.availableClout -= Double(cost)
        state.spentClout += Double(cost)
        state.cloutPurchaseLog.append(CloutStorePurchase(
            type: type,
            targetHustleID: hustleIndex.map { String($0) },
            cloutSpent: cost,
            timestamp: Date()
        ))

        switch type {
        case .publicist:
            guard let i = hustleIndex else { return false }
            state.updateCloutUpgrades(for: i) { $0.publicistHired = true }
        case .costCutShard:
            guard let i = hustleIndex else { return false }
            state.updateCloutUpgrades(for: i) { $0.costCutShards += 1 }
        case .oneTimeSurge:
            state.cloutSurgeUntil = Date().addingTimeInterval(CloutStore.surgeDuration)
        }
        return true
    }

    func hasPublicist(for index: Int) -> Bool {
        state.cloutUpgrades(for: index).publicistHired
    }

    func costCutShards(for index: Int) -> Int {
        state.cloutUpgrades(for: index).costCutShards
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
