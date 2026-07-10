import Foundation

enum DMComebackPayload {
    case referral(target: DMDealer, discount: Double, cardCaption: String, acceptLines: [String])
    case favor(itemID: String, discount: Double, cardCaption: String, choiceLabel: String, acceptLines: [String])
}

struct DMComebackSpec {
    let prefix: String
    /// Lines after `{itemName}` substitution from the dealer's premium purchase.
    let introLines: [String]
    let declineLine: String
    let offerCloser: String
    let payload: DMComebackPayload
}

enum DMComebackScripts {
    static let specs: [DMDealer: DMComebackSpec] = [
        .mica: DMComebackSpec(
            prefix: "mica",
            introLines: [
                "ok real talk — those prints hitting different now",
                "the {itemName} was the right call. i saw the numbers",
                "got a connect for you if you wanna keep climbing",
            ],
            declineLine: "bet. presses stay hot whenever",
            offerCloser: "don't sleep on it",
            payload: .referral(
                target: .zay,
                discount: 0.15,
                cardCaption: "Referral: Zay — 15% off his opening premium if you mention me",
                acceptLines: ["sent. tell him the press queen put you on"]
            )
        ),
        .vinnie: DMComebackSpec(
            prefix: "vault",
            introLines: [
                "yo. the {itemName} treating you right?",
                "ngl i wasn't sure you'd actually go real on that first buy",
                "i got somethin i don't send to just anybody",
            ],
            declineLine: "no rush. door's open when it's open",
            offerCloser: "she doesn't talk to just anybody either. you're good for it now",
            payload: .referral(
                target: .sloane,
                discount: 0.15,
                cardCaption: "Referral: Sloane — 15% off her opening offer if you mention me",
                acceptLines: ["done. don't waste it"]
            )
        ),
        .dre: DMComebackSpec(
            prefix: "whip",
            introLines: [
                "aye you still pullin up clean?",
                "that {itemName} changed how people look at you. facts",
                "i know a guy who knows a guy — retail side",
            ],
            declineLine: "aight. lot's open whenever",
            offerCloser: "he respects the whip game. you're cleared",
            payload: .referral(
                target: .marco,
                discount: 0.15,
                cardCaption: "Referral: Marco — 15% off his opening premium if you mention me",
                acceptLines: ["bet. go build something they line up for"]
            )
        ),
        .zay: DMComebackSpec(
            prefix: "zay",
            introLines: [
                "timer's still running on your brand huh",
                "the {itemName} purchase? that was a statement",
                "lemme do you a favor back — not on the main menu",
            ],
            declineLine: "cool. ping me before the next drop",
            offerCloser: "one-time hookup. my treat on the markup",
            payload: .favor(
                itemID: "cartbot",
                discount: 0.20,
                cardCaption: "Cart Bot License — 20% insider price. refreshes faster than shame",
                choiceLabel: "Buy Cart Bot (insider 20% off)",
                acceptLines: ["there you go. don't get banned", "worth it if you know you know"]
            )
        ),
        .lena: DMComebackSpec(
            prefix: "lena",
            introLines: [
                "your roster's actually moving now",
                "that {itemName} buy told me you're not playing",
                "i can put you in a room with someone serious",
            ],
            declineLine: "noted. my book stays open",
            offerCloser: "couture access. one intro",
            payload: .referral(
                target: .viktor,
                discount: 0.15,
                cardCaption: "Referral: Viktor — 15% off his opening premium if you mention me",
                acceptLines: ["intro sent. dress like you mean it"]
            )
        ),
        .marco: DMComebackSpec(
            prefix: "marco",
            introLines: [
                "saw the line pics. respect",
                "that {itemName} was the right kind of loud",
                "i'll slide you rack pricing nobody gets cold",
            ],
            declineLine: "no stress. block's still for rent",
            offerCloser: "weekend infrastructure. insider rate",
            payload: .favor(
                itemID: "rack_kit",
                discount: 0.25,
                cardCaption: "Foldable Rack Kit — 25% insider price. sets up like you planned it",
                choiceLabel: "Buy Rack Kit (insider 25% off)",
                acceptLines: ["smart. teardown's still on you tho", "pop-up season just got easier"]
            )
        ),
        .sloane: DMComebackSpec(
            prefix: "sloane",
            introLines: [
                "your flagship reads different in person",
                "the {itemName} — tasteful. i don't say that often",
                "i have a favor. not for tourists",
            ],
            declineLine: "very well. the file remains open",
            offerCloser: "marble that photographs. quietly",
            payload: .favor(
                itemID: "foam_marble",
                discount: 0.20,
                cardCaption: "Foam Marble Panels — 20% insider price. weighs less than the lease",
                choiceLabel: "Buy Foam Marble (insider 20% off)",
                acceptLines: ["excellent. critics will say 'considered'", "appearance is infrastructure"]
            )
        ),
        .viktor: DMComebackSpec(
            prefix: "viktor",
            introLines: [
                "front row still talks about your line",
                "that {itemName} — you understand theater",
                "one more door. standing room but the cameras find you",
            ],
            declineLine: "as you wish. the tent has other names",
            offerCloser: "not seated. still photographed",
            payload: .favor(
                itemID: "standing_pass",
                discount: 0.15,
                cardCaption: "Standing Room Pass — 15% insider price. you won't sit but you'll be seen",
                choiceLabel: "Buy Standing Pass (insider 15% off)",
                acceptLines: ["done. stand where they can see you", "history favors the visible"]
            )
        ),
    ]

    static func nodes(for dealer: DMDealer) -> [String: DMNode] {
        guard let spec = specs[dealer] else { return [:] }
        return build(spec)
    }

    static func node(_ dealer: DMDealer, id: String) -> DMNode? {
        nodes(for: dealer)[id]
    }

    static func startingNodeID(for dealer: DMDealer) -> String {
        "\(specs[dealer]?.prefix ?? dealer.scriptPrefix)_return_1"
    }

    static func reopenableNodes(for dealer: DMDealer) -> Set<String> {
        guard let p = specs[dealer]?.prefix else { return [] }
        return ["\(p)_return_decline", "\(p)_return_offer"]
    }

    private static func build(_ spec: DMComebackSpec) -> [String: DMNode] {
        let p = spec.prefix
        let introID = "\(p)_return_1"
        let declineID = "\(p)_return_decline"
        let offerID = "\(p)_return_offer"

        let (offerBubbles, offerChoices, acceptID, acceptEffects): ([DMBubble], [DMChoice], String, [DMEffect]) = {
            switch spec.payload {
            case .referral(let target, let discount, let caption, _):
                let accept = "\(p)_return_referral_accept"
                return (
                    [.itemCard(rexItemID: target.premiumItemID, caption: caption), .text(spec.offerCloser)],
                    [
                        DMChoice(id: "a", label: "Send it", nextNodeID: accept),
                        DMChoice(id: "b", label: "Maybe later", nextNodeID: declineID),
                    ],
                    accept,
                    [.setReferralDiscount(target: target, fraction: discount), .completeComeback]
                )
            case .favor(let itemID, let discount, let caption, let label, _):
                let accept = "\(p)_return_favor_accept"
                return (
                    [.text("doing you a favor back"), .text(caption), .text(spec.offerCloser)],
                    [
                        DMChoice(id: "a", label: label, nextNodeID: accept, buyItemID: itemID, favorDiscount: discount),
                        DMChoice(id: "b", label: "Maybe later", nextNodeID: declineID),
                    ],
                    accept,
                    [.buyAndEquipDiscounted(rexItemID: itemID, discount: discount), .completeComeback]
                )
            }
        }()

        let acceptLines: [String] = {
            switch spec.payload {
            case .referral(_, _, _, let lines): return lines
            case .favor(_, _, _, _, let lines): return lines
            }
        }()

        let declineEffects: [DMEffect] = [.markComebackIntroSeen]

        return [
            introID: DMNode(
                id: introID,
                bubbles: spec.introLines.map { .text($0) },
                choices: [
                    DMChoice(id: "a", label: "What is it?", nextNodeID: offerID),
                    DMChoice(id: "b", label: "Not right now", nextNodeID: declineID),
                ],
                effects: [],
                closesThread: false,
                isComeback: true
            ),
            declineID: DMNode(
                id: declineID,
                bubbles: [.text(spec.declineLine)],
                choices: [],
                effects: declineEffects,
                closesThread: true,
                isComeback: true
            ),
            offerID: DMNode(
                id: offerID,
                bubbles: offerBubbles,
                choices: offerChoices,
                effects: [],
                closesThread: false,
                isComeback: true
            ),
            acceptID: DMNode(
                id: acceptID,
                bubbles: acceptLines.map { .text($0) },
                choices: [],
                effects: acceptEffects,
                closesThread: true,
                isComeback: true
            ),
        ]
    }

    static func interpolate(_ text: String, itemName: String) -> String {
        text.replacingOccurrences(of: "{itemName}", with: itemName)
    }
}
