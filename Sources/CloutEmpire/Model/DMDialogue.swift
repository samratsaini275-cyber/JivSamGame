import Foundation

// MARK: - Dealers (one per hustle)

enum DMDealer: String, CaseIterable, Identifiable {
    case mica
    case vinnie
    case dre
    case zay
    case lena
    case marco
    case sloane
    case viktor

    var id: String { rawValue }

    var hustleIndex: Int {
        switch self {
        case .mica: return 0
        case .vinnie: return 1
        case .dre: return 2
        case .zay: return 3
        case .lena: return 4
        case .marco: return 5
        case .sloane: return 6
        case .viktor: return 7
        }
    }

    static func forHustle(_ index: Int) -> DMDealer? {
        allCases.first { $0.hustleIndex == index }
    }

    var scriptPrefix: String {
        switch self {
        case .mica: return "mica"
        case .vinnie: return "vault"
        case .dre: return "whip"
        case .zay: return "zay"
        case .lena: return "lena"
        case .marco: return "marco"
        case .sloane: return "sloane"
        case .viktor: return "viktor"
        }
    }

    var title: String {
        switch self {
        case .mica: return #"Mica "Press Queen" Santos"#
        case .vinnie: return #"Vinnie "The Vault""#
        case .dre: return #"Dre "Whip Game" Alvarez"#
        case .zay: return #"Zay "The Timer" Okonkwo"#
        case .lena: return #"Lena "Clout Casting" Reyes"#
        case .marco: return #"Marco "Line Outside" Velez"#
        case .sloane: return #"Sloane "White Glove" Hart"#
        case .viktor: return #"Viktor "Front Row" Novak"#
        }
    }

    var verified: Bool {
        switch self {
        case .mica, .vinnie, .lena, .sloane: return true
        case .dre, .zay, .marco, .viktor: return false
        }
    }

    var badgeEmoji: String {
        switch self {
        case .mica: return "🖨️"
        case .vinnie: return "⌚"
        case .dre: return "🔥"
        case .zay: return "⏱️"
        case .lena: return "📱"
        case .marco: return "🏪"
        case .sloane: return "👠"
        case .viktor: return "🎭"
        }
    }

    var preview: String {
        switch self {
        case .mica: return "ok the bootleg prints are actually kinda fire??"
        case .vinnie: return "yo i see you moving 👀"
        case .dre: return "bro the hoodie game going crazy rn"
        case .zay: return "that countdown on your drop?? chef's kiss"
        case .lena: return "your brand just crossed my desk"
        case .marco: return "saw the pop-up line on my feed"
        case .sloane: return "congratulations on the flagship. sincerely."
        case .viktor: return "fashion week called. i didn't pick up."
        }
    }

    var iconName: String { "tab_rex" }

    var accentName: String {
        switch self {
        case .mica: return "champagne"
        case .vinnie: return "hypeBlue"
        case .dre: return "cloutPink"
        case .zay: return "coinGreen"
        case .lena: return "cloutPink"
        case .marco: return "luxeGold"
        case .sloane: return "champagne"
        case .viktor: return "hypeBlue"
        }
    }

    var nodes: [String: DMNode] {
        DMScripts.nodes(for: self)
    }

    var comebackNodes: [String: DMNode] {
        DMComebackScripts.nodes(for: self)
    }

    func startingNodeID(for state: GameState) -> String {
        let p = scriptPrefix
        return state.dmThread(for: self).introCompleted ? "\(p)_offer_1" : "\(p)_intro_1"
    }

    func offerNodeID(for state: GameState) -> String { "\(scriptPrefix)_offer_1" }

    var offerItemIDs: [String] {
        RexItem.forDealer(self).map(\.id)
    }

    var reopenableClosedNodes: Set<String> {
        DMScriptBuilder.reopenableNodes(prefix: scriptPrefix)
    }

    var introCompletedNodeIDs: Set<String> {
        DMScriptBuilder.introCompletedNodes(prefix: scriptPrefix)
    }
}

enum DMBubble: Equatable {
    case text(String)
    case itemCard(rexItemID: String, caption: String)
}

struct DMChoice: Identifiable {
    let id: String
    let label: String
    let nextNodeID: String
    var buyItemID: String? = nil
    var favorDiscount: Double? = nil
}

struct DMNode {
    let id: String
    let bubbles: [DMBubble]
    let choices: [DMChoice]
    let effects: [DMEffect]
    let closesThread: Bool
    var isComeback: Bool = false
}

enum DMEffect: Equatable {
    case buyAndEquip(rexItemID: String)
    case buyAndEquipDiscounted(rexItemID: String, discount: Double)
    case setPremiumRespect(itemID: String, dealer: DMDealer)
    case setReferralDiscount(target: DMDealer, fraction: Double)
    case completeComeback
    case markComebackIntroSeen
}

struct DMTranscriptEntry: Identifiable, Codable, Equatable {
    enum Kind: String, Codable {
        case contactText
        case contactItem
        case playerText
        case vinnieText
        case vinnieItem
    }

    let id: String
    let kind: Kind
    let text: String
    let itemID: String?

    var isFromContact: Bool {
        switch kind {
        case .contactText, .contactItem, .vinnieText, .vinnieItem: return true
        case .playerText: return false
        }
    }

    static func contact(_ text: String) -> DMTranscriptEntry {
        DMTranscriptEntry(id: UUID().uuidString, kind: .contactText, text: text, itemID: nil)
    }

    static func contactItem(_ itemID: String, caption: String) -> DMTranscriptEntry {
        DMTranscriptEntry(id: UUID().uuidString, kind: .contactItem, text: caption, itemID: itemID)
    }

    static func player(_ text: String) -> DMTranscriptEntry {
        DMTranscriptEntry(id: UUID().uuidString, kind: .playerText, text: text, itemID: nil)
    }
}

enum DMScripts {
    static func nodes(for dealer: DMDealer) -> [String: DMNode] {
        var merged = allNodes[dealer] ?? [:]
        for (id, node) in DMComebackScripts.nodes(for: dealer) {
            merged[id] = node
        }
        return merged
    }

    static func node(_ dealer: DMDealer, id: String) -> DMNode? {
        nodes(for: dealer)[id]
    }

    static func isComebackNode(_ dealer: DMDealer, id: String) -> Bool {
        node(dealer, id: id)?.isComeback ?? false
    }

    private static let allNodes: [DMDealer: [String: DMNode]] = [
        .mica: DMScriptBuilder.build(DMTreeSpec(
            prefix: "mica",
            introLines: [
                "ok the bootleg prints are actually kinda fire??",
                "don't let the big brands know i said that",
                "i lease gear to people scaling out the garage. you scaling?",
            ],
            whoDisLines: [
                "mica. press queen. i sublet industrial equipment to founders who aren't industrial yet",
                "no credit check. just vibes and a deposit",
            ],
            declineLine: "copy. my presses stay warm whenever you ready",
            passLine: "bet. garage door's open when the tees start printing money",
            offerLeadIn: "two setups for your tier rn",
            offerCloser: "either way your prints stop looking homemade",
            cheap: DMOfferSpec(
                itemID: "heatpress",
                cardCaption: "Garage Heat Press — $25. louder than a real factory, half the liability",
                choiceLabel: "Buy Garage Heat Press ($25)",
                boughtLines: ["ok ok i see you", "don't burn the garage down. legally i'm not responsible"]
            ),
            expensive: DMOfferSpec(
                itemID: "subletter",
                cardCaption: "Industrial Subletter — $800. smells like a warehouse. productivity included",
                choiceLabel: "Buy Industrial Subletter ($800)",
                boughtLines: ["NOW we're talking", "your tees about to look offended on purpose"]
            ),
            boughtCheapCloser: nil,
            boughtExpensiveCloser: "i'll remember you moved serious",
            respectOnExpensive: true
        )),
        .vinnie: DMScriptBuilder.build(DMTreeSpec(
            prefix: "vault",
            introLines: [
                "yo i see you moving 👀",
                "sneaker flips already lookin clean. respect.",
                "i don't usually do this but i got somethin for people who actually got it",
            ],
            whoDisLines: [
                "relax, i'm not a scammer 💀 i just know a guy who knows a guy",
                "watches. that's the business.",
            ],
            declineLine: "your loss king. i'll be here when the flips slow down",
            passLine: "bet, i'll keep the tab open",
            offerLeadIn: "ok so real talk, i got two options for you rn",
            offerCloser: "your call. both do somethin for you",
            cheap: DMOfferSpec(
                itemID: "fauxlex",
                cardCaption: "Fauxlex Datejust — $500. looks real in every photo that matters",
                choiceLabel: "Buy Fauxlex Datejust ($500)",
                boughtLines: ["lmaooo respect the hustle. nobody's checking the movement anyway", "hit me up when you're ready to go real"]
            ),
            expensive: DMOfferSpec(
                itemID: "tagheuer",
                cardCaption: "Actual Tag Heuer — $12,000. this one's real real. papers and everything",
                choiceLabel: "Buy Actual Tag Heuer ($12,000)",
                boughtLines: ["okay okay. didn't expect that from you ngl", "you just moved different. i'll remember that"]
            ),
            boughtCheapCloser: nil,
            boughtExpensiveCloser: nil,
            respectOnExpensive: true
        )),
        .dre: DMScriptBuilder.build(DMTreeSpec(
            prefix: "whip",
            introLines: [
                "bro the hoodie game going crazy rn",
                "but you still walkin everywhere or...?",
                "i got somethin for you if you ready to actually pull up somewhere",
            ],
            whoDisLines: [
                "dre. i move whips for people on their way up 💯",
                "no pressure, just don't wanna see you late to your own come-up",
            ],
            declineLine: "aight no worries. lot's still open whenever",
            passLine: "say less. lot's open whenever you ready",
            offerLeadIn: "two ways to do this rn",
            offerCloser: "up to you. either way you're pulling up different",
            cheap: DMOfferSpec(
                itemID: "civic",
                cardCaption: "Leased Civic (wrapped) — $1,200. looks clean in every story, nobody's checking the title",
                choiceLabel: "Buy Leased Civic ($1,200)",
                boughtLines: ["see that's smart. don't overspend before you're really eating", "hit me up when the bag get heavier"]
            ),
            expensive: DMOfferSpec(
                itemID: "charger",
                cardCaption: "Rented Charger — $30,000. this one's got a little more weight behind it",
                choiceLabel: "Buy Rented Charger ($30,000)",
                boughtLines: ["okay THAT's what i'm talkin about", "you movin like you got somethin to prove. i respect it"]
            ),
            boughtCheapCloser: nil,
            boughtExpensiveCloser: nil,
            respectOnExpensive: true
        )),
        .zay: DMScriptBuilder.build(DMTreeSpec(
            prefix: "zay",
            introLines: [
                "that countdown on your last drop??",
                "artificial scarcity is a lifestyle and i respect the commitment",
                "i can make the queue move faster. literally.",
            ],
            whoDisLines: [
                "zay. the timer. i sell bots, buffers, and panic in 60-second intervals",
                "not illegal. just spiritually adjacent",
            ],
            declineLine: "cool cool. the cart stays open when hype dips",
            passLine: "aight. ping me before the next drop goes live",
            offerLeadIn: "pick your chaos level",
            offerCloser: "either way the timer hits different",
            cheap: DMOfferSpec(
                itemID: "cartbot",
                cardCaption: "Cart Bot License — $8,000. refreshes faster than your customers refresh shame",
                choiceLabel: "Buy Cart Bot License ($8,000)",
                boughtLines: ["respect. you're playing the meta now", "don't screenshot the settings. ever."]
            ),
            expensive: DMOfferSpec(
                itemID: "queueskip",
                cardCaption: "Queue Skip Pass — $250,000. verified hustles checkout like they own the site",
                choiceLabel: "Buy Queue Skip Pass ($250,000)",
                boughtLines: ["oh you SERIOUS serious", "sold out in 4 seconds is a personality. you got it now"]
            ),
            boughtCheapCloser: nil,
            boughtExpensiveCloser: "i'll cut you in on the next backend drop",
            respectOnExpensive: true
        )),
        .lena: DMScriptBuilder.build(DMTreeSpec(
            prefix: "lena",
            introLines: [
                "your brand just crossed my desk",
                "i place creators with labels that need an audience yesterday",
                "roster access is usually closed. yours isn't. yet.",
            ],
            whoDisLines: [
                "lena. clout casting. i don't do followers — i do reach",
                "every collab is a loan against your reputation. spend wisely",
            ],
            declineLine: "noted. my roster rotates every quarter anyway",
            passLine: "fine. dm me when you're ready to borrow someone's audience",
            offerLeadIn: "two packages. both come with contracts you'll pretend you read",
            offerCloser: "pick your co-sign energy",
            cheap: DMOfferSpec(
                itemID: "micro_roster",
                cardCaption: "Micro-Influencer Roster — $100,000. 12 creators, 400K combined reach, 0 chemistry",
                choiceLabel: "Buy Micro-Influencer Roster ($100,000)",
                boughtLines: ["smart. start mid before you go A-list", "first post drops when the invoice clears"]
            ),
            expensive: DMOfferSpec(
                itemID: "talent_pkg",
                cardCaption: "Verified Talent Package — $2,500,000. blue checks, soft launches, hard engagement",
                choiceLabel: "Buy Verified Talent Package ($2,500,000)",
                boughtLines: ["okay founder behavior", "your logo's about to be on someone's morning routine for 60 days"]
            ),
            boughtCheapCloser: nil,
            boughtExpensiveCloser: "you just became a preferred client",
            respectOnExpensive: true
        )),
        .marco: DMScriptBuilder.build(DMTreeSpec(
            prefix: "marco",
            introLines: [
                "saw the pop-up line on my feed",
                "people waited 3 hours to buy a tote. that's not retail that's religion",
                "i outfit temporary temples. you interested?",
            ],
            whoDisLines: [
                "marco. line outside. i build stores that expire on sunday",
                "permanent locations are for people who believe in tomorrow",
            ],
            declineLine: "no stress. the block is still for rent next weekend",
            passLine: "say less. i'll hold a rack with your name on it",
            offerLeadIn: "weekend retail, two price points",
            offerCloser: "the line doesn't care which one you pick",
            cheap: DMOfferSpec(
                itemID: "rack_kit",
                cardCaption: "Foldable Rack Kit — $1,500,000. sets up in 20 min, looks like it took 3 permits",
                choiceLabel: "Buy Foldable Rack Kit ($1,500,000)",
                boughtLines: ["efficient. i like founders who respect the teardown", "your next pop-up just got a backbone"]
            ),
            expensive: DMOfferSpec(
                itemID: "lambo",
                cardCaption: "Borrowed Lambo — $900,000. pull up to your own line in someone else's car",
                choiceLabel: "Buy Borrowed Lambo ($900,000)",
                boughtLines: ["YESSS that's the energy", "mileage cap is a suggestion. the photos are forever"]
            ),
            boughtCheapCloser: nil,
            boughtExpensiveCloser: "you understand spectacle. respect.",
            respectOnExpensive: true
        )),
        .sloane: DMScriptBuilder.build(DMTreeSpec(
            prefix: "sloane",
            introLines: [
                "congratulations on the flagship. sincerely.",
                "most founders hire contractors. i hire illusions.",
                "the floor doesn't have to be marble. it has to LOOK marble.",
            ],
            whoDisLines: [
                "sloane hart. white glove retail. i sell the feeling of having always been expensive",
                "your customers won't know what's real. neither will your accountant",
            ],
            declineLine: "understood. the veneer market remains... robust",
            passLine: "very well. my team keeps a file on ascending founders",
            offerLeadIn: "flagship polish, two tiers",
            offerCloser: "appearance is infrastructure at your level",
            cheap: DMOfferSpec(
                itemID: "foam_marble",
                cardCaption: "Foam Marble Panels — $20,000,000. weighs less than your lease. looks heavier than your debt",
                choiceLabel: "Buy Foam Marble Panels ($20,000,000)",
                boughtLines: ["tasteful restraint. rare at this stage", "critics will call it 'considered.' that's a win"]
            ),
            expensive: DMOfferSpec(
                itemID: "daytona",
                cardCaption: "Vintage Daytona — $400,000. the flex is now load-bearing. +2% Clout gain forever",
                choiceLabel: "Buy Vintage Daytona ($400,000)",
                boughtLines: ["there it is.", "you just bought time that appreciates. allegedly."]
            ),
            boughtCheapCloser: nil,
            boughtExpensiveCloser: "preferred pricing on anything else i touch",
            respectOnExpensive: true
        )),
        .viktor: DMScriptBuilder.build(DMTreeSpec(
            prefix: "viktor",
            introLines: [
                "fashion week called. i didn't pick up.",
                "they called again. i thought about your line.",
                "couture is just bootlegs with better lighting. want in?",
            ],
            whoDisLines: [
                "viktor novak. front row. i translate garage brands into runway dialect",
                "the critics will cry. the invoices will not",
            ],
            declineLine: "as you wish. the tent has other names on the list",
            passLine: "noted. the runway keeps a seat warm for the bold",
            offerLeadIn: "couture access. pick your altitude",
            offerCloser: "history is written by whoever shows up best dressed",
            cheap: DMOfferSpec(
                itemID: "standing_pass",
                cardCaption: "Standing Room Pass — $250,000,000. you won't sit but you'll be photographed not sitting",
                choiceLabel: "Buy Standing Room Pass ($250,000,000)",
                boughtLines: ["bold. standing is honest.", "your line just entered the chat. literally."]
            ),
            expensive: DMOfferSpec(
                itemID: "mille",
                cardCaption: "\"Richard Mille\" — $18,000,000. ×2 income for 10s whenever you buy a Hustle unit",
                choiceLabel: "Buy \"Richard Mille\" ($18,000,000)",
                boughtLines: ["unreal.", "customs won't confirm it's real. neither will richard. you don't care."]
            ),
            boughtCheapCloser: nil,
            boughtExpensiveCloser: "you are now on the short list for everything",
            respectOnExpensive: true
        )),
    ]

    static func choices(for dealer: DMDealer, nodeID: String, game: Game) -> [DMChoice] {
        guard let node = node(dealer, id: nodeID) else { return [] }
        return node.choices
            .filter { choice in
                guard let itemID = choice.buyItemID,
                      let item = RexItem.byID(itemID) else { return true }
                return !game.owns(item)
            }
            .map { choice in
                guard let itemID = choice.buyItemID,
                      let item = RexItem.byID(itemID) else { return choice }
                let cost = game.price(for: item, favorDiscount: choice.favorDiscount)
                guard game.state.cash < cost else { return choice }
                return DMChoice(
                    id: choice.id,
                    label: "\(choice.label) — need \(money(cost))",
                    nextNodeID: choice.nextNodeID,
                    buyItemID: choice.buyItemID,
                    favorDiscount: choice.favorDiscount
                )
            }
    }

    static func canSelect(_ choice: DMChoice, game: Game) -> Bool {
        guard let itemID = choice.buyItemID,
              let item = RexItem.byID(itemID) else { return true }
        return game.state.cash >= game.price(for: item, favorDiscount: choice.favorDiscount)
    }

    static func affordTooltip(for choice: DMChoice, game: Game) -> String? {
        guard let itemID = choice.buyItemID,
              let item = RexItem.byID(itemID) else { return nil }
        let cost = game.price(for: item, favorDiscount: choice.favorDiscount)
        guard game.state.cash < cost else { return nil }
        return "Need \(money(cost)) cash — you have \(money(game.state.cash))"
    }
}

enum DMDialogueEngine {
    static func inboxPreview(dealer: DMDealer, state: GameState) -> String {
        let thread = state.dmThread(for: dealer)
        let transcript = thread.comebackThreadStarted ? thread.comebackTranscript : thread.transcript
        if let last = transcript.last {
            if last.isFromContact { return last.text }
            return "You: \(last.text)"
        }
        if state.dealerRelationship(for: dealer).comebackPending { return "new message" }
        return dealer.preview
    }

    static func hasUnreadChoices(dealer: DMDealer, game: Game) -> Bool {
        guard game.isDMInboxVisible(dealer) else { return false }
        if game.hasUnreadComeback(dealer) { return true }
        let thread = game.state.dmThread(for: dealer)
        if !thread.threadStarted { return true }
        if thread.threadClosed { return game.shouldReopenDMOffer(dealer) }
        guard let nodeID = thread.currentNode else { return false }
        return !DMScripts.choices(for: dealer, nodeID: nodeID, game: game).isEmpty
    }

    static func isInnerCircle(dealer: DMDealer, state: GameState) -> Bool {
        state.dealerRelationship(for: dealer).isInnerCircle
    }
}

typealias VaultTranscriptEntry = DMTranscriptEntry

extension DMTranscriptEntry {
    static func vinnie(_ text: String) -> DMTranscriptEntry { .contact(text) }
    static func vinnieItem(_ itemID: String, caption: String) -> DMTranscriptEntry { .contactItem(itemID, caption: caption) }
}
