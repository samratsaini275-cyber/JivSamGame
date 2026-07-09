import Foundation

// MARK: - DM threads & messages (Rex shop reskin)

struct RexDMThread: Identifiable {
    let id: String
    let title: String
    let preview: String
    /// Minimum milestone tier on any hustle (see `Formulas.milestoneTier`).
    let unlockMoneyTier: Int
    /// Additional lifetime-cash gate so threads appear as you scale.
    let unlockLifetimeCash: Double
    let slot: ItemSlot?

    static let all: [RexDMThread] = [
        RexDMThread(
            id: "intro",
            title: "Rex Calloway",
            preview: "Yo. Been watching the brand…",
            unlockMoneyTier: 0,
            unlockLifetimeCash: 0,
            slot: nil
        ),
        RexDMThread(
            id: "wrist",
            title: "Rex · Wrist Game",
            preview: "The watch is the whole argument.",
            unlockMoneyTier: Rex.unlockMoneyTier,
            unlockLifetimeCash: 500,
            slot: .wrist
        ),
        RexDMThread(
            id: "garage",
            title: "Rex · Garage Era",
            preview: "You don't drive it. You park it where people eat.",
            unlockMoneyTier: Rex.unlockMoneyTier,
            unlockLifetimeCash: 1_200,
            slot: .garage
        ),
    ]

    static func unlocked(for game: Game) -> [RexDMThread] {
        guard game.rexUnlocked else { return [] }
        return all.filter { thread in
            game.maxMoneyTier >= thread.unlockMoneyTier
                && game.state.lifetimeCash >= thread.unlockLifetimeCash
        }
    }
}

struct RexChatMessage: Identifiable {
    enum Sender { case rex, player }

    let id: String
    let sender: Sender
    let text: String
    let itemID: String?
    let pitchID: String?

    var isPitch: Bool { pitchID != nil && sender == .rex }
}

struct RexReply: Identifiable {
    enum Action {
        case buy(RexItem)
        case equip(RexItem)
        case dismiss(pitchID: String)
        case introAck
        case introCurious
    }

    let id: String
    let label: String
    let action: Action
}

enum RexChatBuilder {
    static func messages(for thread: RexDMThread, game: Game) -> [RexChatMessage] {
        switch thread.id {
        case "intro": return introMessages(game: game)
        case "wrist": return slotMessages(slot: .wrist, game: game)
        case "garage": return slotMessages(slot: .garage, game: game)
        default: return []
        }
    }

    static func pendingPitch(in messages: [RexChatMessage], game: Game) -> String? {
        for msg in messages.reversed() where msg.isPitch {
            guard let pitchID = msg.pitchID else { continue }
            if playerResponded(to: pitchID, game: game) { continue }
            return pitchID
        }
        return nil
    }

    static func replies(for pitchID: String, thread: RexDMThread, game: Game) -> [RexReply] {
        if pitchID == "intro" {
            if game.state.rexIntroAcknowledged { return [] }
            return [
                RexReply(id: "intro_yes", label: "Put me on the map", action: .introAck),
                RexReply(id: "intro_huh", label: "Who is this?", action: .introCurious),
            ]
        }
        guard let item = item(forPitchID: pitchID) else { return [] }

        if game.isEquipped(item) {
            return []
        }
        if game.owns(item) {
            return [
                RexReply(id: "eq_\(item.id)", label: "Put it on", action: .equip(item)),
                RexReply(id: "later_\(item.id)", label: "Not right now", action: .dismiss(pitchID: pitchID)),
            ]
        }
        let afford = game.state.cash >= item.cost
        return [
            RexReply(
                id: "buy_\(item.id)",
                label: afford ? "Send it · \(money(item.cost))" : "Need \(money(item.cost)) — broke",
                action: .buy(item)
            ),
            RexReply(id: "pass_\(item.id)", label: "Hard pass for now", action: .dismiss(pitchID: pitchID)),
        ]
    }

    // MARK: - Private

    private static func introMessages(game: Game) -> [RexChatMessage] {
        var msgs = [
            RexChatMessage(
                id: "intro_pitch",
                sender: .rex,
                text: Rex.greeting,
                itemID: nil,
                pitchID: "intro"
            ),
        ]
        if game.state.rexIntroAcknowledged {
            msgs.append(RexChatMessage(
                id: "intro_player",
                sender: .player,
                text: game.state.rexIntroReply ?? "Put me on the map",
                itemID: nil,
                pitchID: nil
            ))
            msgs.append(RexChatMessage(
                id: "intro_followup",
                sender: .rex,
                text: game.state.rexIntroReply == "Who is this?"
                    ? "I'm Rex. I make brands look expensive. Stick around."
                    : "That's the energy. Check the other threads — wrist and garage — when you're ready to level up the flex.",
                itemID: nil,
                pitchID: nil
            ))
        }
        return msgs
    }

    private static func slotMessages(slot: ItemSlot, game: Game) -> [RexChatMessage] {
        var msgs: [RexChatMessage] = []
        let opener = slot == .wrist
            ? "Alright. Wrist game separates tourists from founders. Pick your lane."
            : "Garage talk. The car doesn't matter — the photo angle does."

        msgs.append(RexChatMessage(
            id: "\(slot.rawValue)_opener",
            sender: .rex,
            text: opener,
            itemID: nil,
            pitchID: nil
        ))

        for item in RexItem.forSlot(slot) {
            let pitchID = "pitch_\(item.id)"
            guard pitchVisible(item: item, game: game) else { continue }

            msgs.append(RexChatMessage(
                id: pitchID,
                sender: .rex,
                text: pitchText(for: item),
                itemID: item.id,
                pitchID: pitchID
            ))

            if let player = playerMessage(for: pitchID, item: item, game: game) {
                msgs.append(player)
            }
            if let followUp = rexFollowUp(for: item, pitchID: pitchID, game: game) {
                msgs.append(followUp)
            }
        }
        return msgs
    }

    static func pitchVisible(item: RexItem, game: Game) -> Bool {
        if game.owns(item) || game.state.rexDismissedPitches.contains("pitch_\(item.id)") {
            return true
        }
        return game.state.lifetimeCash >= item.cost * 0.35
    }

    private static func pitchText(for item: RexItem) -> String {
        "\(item.name) — \(item.blurb)\n\n\(item.boostText). \(item.tierName) tier."
    }

    private static func playerMessage(for pitchID: String, item: RexItem, game: Game) -> RexChatMessage? {
        guard playerResponded(to: pitchID, game: game) else { return nil }
        let text: String
        if game.isEquipped(item) || game.owns(item) {
            text = game.state.rexPitchReplies[pitchID] ?? "Send it."
        } else if game.state.rexDismissedPitches.contains(pitchID) {
            text = game.state.rexPitchReplies[pitchID] ?? "Hard pass for now"
        } else {
            return nil
        }
        return RexChatMessage(
            id: "player_\(pitchID)",
            sender: .player,
            text: text,
            itemID: item.id,
            pitchID: nil
        )
    }

    private static func rexFollowUp(for item: RexItem, pitchID: String, game: Game) -> RexChatMessage? {
        guard playerResponded(to: pitchID, game: game) else { return nil }
        let text: String
        if let stored = game.state.rexPitchFollowUp[pitchID] {
            text = stored
        } else if game.isEquipped(item) {
            text = Rex.idleBark(wrist: game.equippedWristItem, garage: game.equippedGarageItem)
        } else if game.owns(item) {
            text = "It's in the stash. Equip when you're ready to be seen."
        } else if game.state.rexDismissedPitches.contains(pitchID) {
            text = "Fair. The flex will still be there when the bag catches up."
        } else {
            return nil
        }
        return RexChatMessage(
            id: "rex_follow_\(pitchID)",
            sender: .rex,
            text: text,
            itemID: item.id,
            pitchID: nil
        )
    }

    private static func playerResponded(to pitchID: String, game: Game) -> Bool {
        if pitchID == "intro" { return game.state.rexIntroAcknowledged }
        guard let item = item(forPitchID: pitchID) else { return false }
        return game.owns(item)
            || game.isEquipped(item)
            || game.state.rexDismissedPitches.contains(pitchID)
            || game.state.rexPitchReplies[pitchID] != nil
    }

    private static func item(forPitchID pitchID: String) -> RexItem? {
        guard pitchID.hasPrefix("pitch_") else { return nil }
        return RexItem.byID(String(pitchID.dropFirst(6)))
    }
}
