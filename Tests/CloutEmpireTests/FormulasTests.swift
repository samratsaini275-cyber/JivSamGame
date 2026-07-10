import XCTest
@testable import CloutEmpire

final class FormulasTests: XCTestCase {

    // MARK: Cost curve (README §3: baseCost × 1.14^owned)

    func testFirstUnitCostsBase() {
        XCTAssertEqual(Formulas.unitCost(base: 4, owned: 0), 4)
        XCTAssertEqual(Formulas.unitCost(base: 180_000_000, owned: 0), 180_000_000)
    }

    func testCostGrowsByFourteenPercent() {
        XCTAssertEqual(Formulas.unitCost(base: 4, owned: 1), 4.56, accuracy: 0.001)
        XCTAssertEqual(Formulas.unitCost(base: 60, owned: 10), 60 * pow(1.14, 10), accuracy: 0.001)
    }

    func testBulkCostMatchesSumOfUnitCosts() {
        let summed = (0..<10).reduce(0.0) { $0 + Formulas.unitCost(base: 720, owned: 5 + $1) }
        XCTAssertEqual(Formulas.bulkCost(base: 720, owned: 5, count: 10), summed, accuracy: 0.01)
    }

    func testMaxAffordableIsConsistentWithBulkCost() {
        for cash in [0.0, 3.99, 4.0, 100, 12_345, 9_876_543] {
            let n = Formulas.maxAffordable(base: 4, owned: 7, cash: cash)
            XCTAssertLessThanOrEqual(Formulas.bulkCost(base: 4, owned: 7, count: n), cash + 1e-9)
            XCTAssertGreaterThan(Formulas.bulkCost(base: 4, owned: 7, count: n + 1), cash)
        }
    }

    // MARK: Milestones (README §4: 25/50/100/200/300/400)

    func testMilestoneTiers() {
        XCTAssertEqual(Formulas.milestoneTier(units: 0), 0)
        XCTAssertEqual(Formulas.milestoneTier(units: 24), 0)
        XCTAssertEqual(Formulas.milestoneTier(units: 25), 1)
        XCTAssertEqual(Formulas.milestoneTier(units: 99), 2)
        XCTAssertEqual(Formulas.milestoneTier(units: 400), 6)
        XCTAssertEqual(Formulas.milestoneTier(units: 10_000), 6)
    }

    func testMilestonesDoubleIncomeAndHalveCycle() {
        XCTAssertEqual(Formulas.incomeMultiplier(tier: 3), 8)
        XCTAssertEqual(Formulas.cycleTime(base: 1, tier: 6), 1.0 / 64, accuracy: 1e-9)
    }

    func testNextThreshold() {
        XCTAssertEqual(Formulas.nextThreshold(units: 0), 25)
        XCTAssertEqual(Formulas.nextThreshold(units: 25), 50)
        XCTAssertNil(Formulas.nextThreshold(units: 400))
    }

    // MARK: Viral Moment (README §5: min tier across all hustles)

    func testViralTierIsMinAcrossAllHustles() {
        XCTAssertEqual(Formulas.viralTier(unitCounts: Array(repeating: 25, count: 8)), 1)
        XCTAssertEqual(Formulas.viralTier(unitCounts: [400, 25, 25, 25, 25, 25, 25, 25]), 1)
        XCTAssertEqual(Formulas.viralTier(unitCounts: [400, 0, 25, 25, 25, 25, 25, 25]), 0)
        XCTAssertEqual(Formulas.viralMultiplier(unitCounts: Array(repeating: 50, count: 8)), 4)
    }

    // MARK: Clout (README §7: sqrt(lifetime/divisor) − held, +2% each)

    func testCloutGainUsesSquareRootCurve() {
        let lifetime = Formulas.cloutDivisor * 100 // sqrt = 10
        XCTAssertEqual(Formulas.cloutGain(lifetimeCash: lifetime, currentClout: 0), 10)
        XCTAssertEqual(Formulas.cloutGain(lifetimeCash: lifetime, currentClout: 4), 6)
        XCTAssertEqual(Formulas.cloutGain(lifetimeCash: lifetime, currentClout: 50), 0, "never negative")
    }

    func testCloutMultiplier() {
        XCTAssertEqual(Formulas.cloutMultiplier(clout: 0), 1)
        XCTAssertEqual(Formulas.cloutMultiplier(clout: 50), 2, accuracy: 1e-9, "50 clout = 2x, per README")
    }

    // MARK: Rex's flex items

    func testWristIncomeMultipliers() {
        XCTAssertEqual(Formulas.wristIncomeMultiplier(itemID: "fauxlex", hustleTier: 0), 1.05)
        XCTAssertEqual(Formulas.wristIncomeMultiplier(itemID: "tagheuer", hustleTier: 0), 1,
                       "Tag Heuer only boosts verified (tier 1+) hustles")
        XCTAssertEqual(Formulas.wristIncomeMultiplier(itemID: "tagheuer", hustleTier: 2), 1.15)
        XCTAssertEqual(Formulas.wristIncomeMultiplier(itemID: nil, hustleTier: 3), 1)
        XCTAssertEqual(Formulas.wristIncomeMultiplier(itemID: "daytona", hustleTier: 3), 1,
                       "Daytona's boost is clout gain rate, not income")
    }

    func testGarageCycleMultipliers() {
        XCTAssertEqual(Formulas.garageCycleMultiplier(itemID: "civic", hustleTier: 0), 0.95)
        XCTAssertEqual(Formulas.garageCycleMultiplier(itemID: "charger", hustleTier: 0), 1)
        XCTAssertEqual(Formulas.garageCycleMultiplier(itemID: "charger", hustleTier: 1), 0.90)
        XCTAssertEqual(Formulas.garageCycleMultiplier(itemID: nil, hustleTier: 1), 1)
    }

    func testDaytonaBoostsCloutGainRate() {
        let lifetime = Formulas.cloutDivisor * 10_000 // sqrt = 100
        XCTAssertEqual(Formulas.cloutGain(lifetimeCash: lifetime, currentClout: 0), 100)
        XCTAssertEqual(Formulas.cloutGain(lifetimeCash: lifetime, currentClout: 0, gainRateBonus: 0.04), 104)
    }

    func testItemTableMatchesSpec() {
        XCTAssertEqual(RexItem.all.count, 8)
        XCTAssertEqual(RexItem.forSlot(.wrist).map(\.tier), [1, 2, 3, 4])
        XCTAssertEqual(RexItem.forSlot(.garage).map(\.tier), [1, 2, 3, 4])
        XCTAssertEqual(RexItem.byID("fauxlex")?.cost, 500)
        XCTAssertEqual(RexItem.byID("bugatti")?.cost, 40_000_000)
    }

    func testRebrandKeepsFitAndDaytonaLegacy() {
        var state = GameState.newGame()
        state.ownedItems = ["fauxlex", "daytona", "lambo"]
        state.equippedWrist = "daytona"
        state.equippedGarage = "lambo"
        state.equippedPerks = ["heatpress", "cartbot"]
        state.daytonaPurchases = 2

        state.rebrand(gaining: 10)

        XCTAssertEqual(state.ownedItems, ["fauxlex", "daytona", "lambo"])
        XCTAssertEqual(state.equippedWrist, "daytona")
        XCTAssertEqual(state.equippedGarage, "lambo")
        XCTAssertEqual(state.equippedPerks, ["heatpress", "cartbot"])
        XCTAssertEqual(state.daytonaPurchases, 2, "Daytona legacy survives Rebrand")
    }

    func testPreRexSaveStillDecodes() throws {
        let legacyJSON = """
        {"cash": 42.5, "lifetimeCash": 100, "clout": 3,
         "hustles": [{"unitsOwned": 5, "ghostwriterHired": true, "cycleProgress": 0, "cycleRunning": false}]}
        """
        let state = try JSONDecoder().decode(GameState.self, from: Data(legacyJSON.utf8))
        XCTAssertEqual(state.cash, 42.5)
        XCTAssertEqual(state.availableClout, 3)
        XCTAssertTrue(state.ownedItems.isEmpty)
        XCTAssertEqual(state.daytonaPurchases, 0)
    }

    // MARK: Persona (cosmetics — identity layer, survives Rebrand)

    func testPersonaItemTable() {
        XCTAssertEqual(PersonaItem.all.count, 12)
        for slot in PersonaSlot.allCases {
            XCTAssertEqual(PersonaItem.forSlot(slot).map(\.tier), [1, 2, 3, 4], "\(slot) has 4 tiers")
        }
        XCTAssertEqual(PersonaItem.all.filter(\.isGrail).count, 3)
    }

    func testPersonaSurvivesRebrand() {
        var state = GameState.newGame()
        state.handle = "hustlegod99"
        state.baseLook = "street"
        state.ownedCosmetics = ["couture", "p_fauxlex"]
        state.equippedCosmetics = [PersonaSlot.clothes.rawValue: "couture"]

        state.rebrand(gaining: 5)

        XCTAssertEqual(state.handle, "hustlegod99", "you delete the account, not yourself")
        XCTAssertEqual(state.ownedCosmetics, ["couture", "p_fauxlex"])
        XCTAssertEqual(state.equippedCosmetics[PersonaSlot.clothes.rawValue], "couture")
    }

    func testGrailRebrandBonusIsHalfPercentEach() {
        // 3 grails equipped = +1.5% on the clout curve, income untouched.
        let bonus = 3 * Formulas.grailRebrandBonusPerItem
        let lifetime = Formulas.cloutDivisor * 40_000 // sqrt = 200
        XCTAssertEqual(Formulas.cloutGain(lifetimeCash: lifetime, currentClout: 0, gainRateBonus: bonus), 203)
    }

    func testLeaderboardRanksByCloutThenLifetimeCash() {
        let entries = [
            LeaderboardEntry(id: "a", handle: "a", portraitImage: "look_hoodie", clout: 10, lifetimeCash: 1),
            LeaderboardEntry(id: "b", handle: "b", portraitImage: "look_bizcaz", clout: 50, lifetimeCash: 1),
            LeaderboardEntry(id: "c", handle: "c", portraitImage: "look_street", clout: 10, lifetimeCash: 99),
        ]
        XCTAssertEqual(LeaderboardEntry.rank(entries).map(\.id), ["b", "c", "a"])
    }

    func testMaxBuyAddsAllAffordableUnits() {
        var state = GameState.newGame()
        state.cash = 1_000
        state.hustles[0].unitsOwned = 1
        let game = Game(state: state)
        game.buyMode = .max

        let count = game.buyCount(for: 0)
        XCTAssertGreaterThan(count, 1, "fixture should afford multiple units on Max")

        game.buy(0)
        XCTAssertEqual(game.state.hustles[0].unitsOwned, 1 + count)
    }

    // MARK: Rebrand state transition

    func testRebrandResetsRunButKeepsCloutAndLifetime() {
        var state = GameState.newGame()
        state.cash = 5_000
        state.lifetimeCash = 1_000_000
        state.hustles[2].unitsOwned = 50
        state.hustles[2].ghostwriterHired = true

        state.rebrand(gaining: 6)

        XCTAssertEqual(state.availableClout, 6)
        XCTAssertEqual(state.cash, 0)
        XCTAssertEqual(state.lifetimeCash, 1_000_000)
        XCTAssertEqual(state.hustles[2].unitsOwned, 0)
        XCTAssertFalse(state.hustles[2].ghostwriterHired)
        XCTAssertEqual(state.hustles[0].unitsOwned, 1, "fresh persona starts with one hustle unit")
    }

    func testCloutSpendingReducesIncomeMultiplier() {
        var state = GameState.newGame()
        state.availableClout = 100
        let game = Game(state: state)
        XCTAssertEqual(Formulas.cloutMultiplier(clout: game.state.availableClout), 3, accuracy: 1e-9)
        _ = game.purchaseClout(type: .oneTimeSurge)
        XCTAssertEqual(game.state.availableClout, 85)
        XCTAssertEqual(Formulas.cloutMultiplier(clout: game.state.availableClout), 2.7, accuracy: 1e-9)
    }

    func testComebackDoesNotTriggerWithoutPremiumRespect() {
        var state = GameState.newGame()
        state.hustles[1].unitsOwned = 100
        state.cash = 1_000_000_000
        state.updateDealerRelationship(.vinnie) { rel in
            rel.respectLevel = 0
            rel.lastPurchaseHustleTier = 0
        }
        let game = Game(state: state)
        game.buy(1)
        XCTAssertFalse(game.state.dealerRelationship(for: .vinnie).comebackPending)
    }

    func testComebackTriggersAfterTwoTiersPastPurchase() {
        var state = GameState.newGame()
        state.hustles[1].unitsOwned = 49
        state.cash = 1_000_000_000
        state.updateDealerRelationship(.vinnie) { rel in
            rel.respectLevel = 1
            rel.lastPurchaseHustleTier = 0
            rel.premiumItemID = "tagheuer"
        }
        let game = Game(state: state)
        game.buy(1)
        XCTAssertTrue(game.state.dealerRelationship(for: .vinnie).comebackPending)
    }

    func testReferralDiscountAppliesToPremiumPrice() {
        var state = GameState.newGame()
        state.updateDealerRelationship(.sloane) { $0.referredOpeningDiscount = 0.15 }
        let game = Game(state: state)
        guard let item = RexItem.byID("daytona") else {
            XCTFail("missing daytona item")
            return
        }
        let expected = (item.cost * 0.85).rounded(.down)
        XCTAssertEqual(game.price(for: item), expected)
    }

    func testCloutUpgradesSurviveRebrand() {
        var state = GameState.newGame()
        state.updateCloutUpgrades(for: 2) { upgrades in
            upgrades.publicistHired = true
            upgrades.costCutShards = 2
        }
        state.rebrand(gaining: 5)
        let upgrades = state.cloutUpgrades(for: 2)
        XCTAssertTrue(upgrades.publicistHired)
        XCTAssertEqual(upgrades.costCutShards, 2)
    }

    func testCostCutShardsCapAtTwo() {
        var state = GameState.newGame()
        state.availableClout = 1_000
        let game = Game(state: state)
        XCTAssertTrue(game.purchaseClout(type: .costCutShard, hustleIndex: 0))
        XCTAssertTrue(game.purchaseClout(type: .costCutShard, hustleIndex: 0))
        XCTAssertFalse(game.canPurchaseClout(type: .costCutShard, hustleIndex: 0))
    }
}
