import Foundation

struct DMOfferSpec {
    let itemID: String
    let cardCaption: String
    let choiceLabel: String
    let boughtLines: [String]
}

struct DMTreeSpec {
    let prefix: String
    let introLines: [String]
    let whoDisLines: [String]
    let declineLine: String
    let passLine: String
    let offerLeadIn: String
    let offerCloser: String
    let cheap: DMOfferSpec
    let expensive: DMOfferSpec
    let boughtCheapCloser: String?
    let boughtExpensiveCloser: String?
    let respectOnExpensive: Bool
}

enum DMScriptBuilder {
    static func build(_ spec: DMTreeSpec) -> [String: DMNode] {
        let p = spec.prefix
        let cheapBought = "\(p)_bought_cheap"
        let expensiveBought = "\(p)_bought_expensive"

        let cheapEffects: [DMEffect] = [.buyAndEquip(rexItemID: spec.cheap.itemID)]
        var expensiveEffects: [DMEffect] = [.buyAndEquip(rexItemID: spec.expensive.itemID)]
        if spec.respectOnExpensive {
            expensiveEffects.append(.setRespectsPlayer)
        }

        var cheapBubbles = spec.cheap.boughtLines
        if let closer = spec.boughtCheapCloser { cheapBubbles.append(closer) }
        var expensiveBubbles = spec.expensive.boughtLines
        if let closer = spec.boughtExpensiveCloser { expensiveBubbles.append(closer) }

        return [
            "\(p)_intro_1": DMNode(
                id: "\(p)_intro_1",
                bubbles: spec.introLines.map { .text($0) },
                choices: [
                    DMChoice(id: "a", label: "What you got?", nextNodeID: "\(p)_offer_1"),
                    DMChoice(id: "b", label: "Who is this?", nextNodeID: "\(p)_intro_2"),
                    DMChoice(id: "c", label: "Not interested", nextNodeID: "\(p)_decline_1"),
                ],
                effects: [],
                closesThread: false
            ),
            "\(p)_intro_2": DMNode(
                id: "\(p)_intro_2",
                bubbles: spec.whoDisLines.map { .text($0) },
                choices: [
                    DMChoice(id: "a", label: "Okay, what you got?", nextNodeID: "\(p)_offer_1"),
                    DMChoice(id: "c", label: "Still not interested", nextNodeID: "\(p)_decline_1"),
                ],
                effects: [],
                closesThread: false
            ),
            "\(p)_decline_1": DMNode(
                id: "\(p)_decline_1",
                bubbles: [.text(spec.declineLine)],
                choices: [],
                effects: [],
                closesThread: true
            ),
            "\(p)_offer_1": DMNode(
                id: "\(p)_offer_1",
                bubbles: [
                    .text(spec.offerLeadIn),
                    .itemCard(rexItemID: spec.cheap.itemID, caption: spec.cheap.cardCaption),
                    .itemCard(rexItemID: spec.expensive.itemID, caption: spec.expensive.cardCaption),
                    .text(spec.offerCloser),
                ],
                choices: [
                    DMChoice(id: "a", label: spec.cheap.choiceLabel, nextNodeID: cheapBought, buyItemID: spec.cheap.itemID),
                    DMChoice(id: "b", label: spec.expensive.choiceLabel, nextNodeID: expensiveBought, buyItemID: spec.expensive.itemID),
                    DMChoice(id: "c", label: "I'll pass for now", nextNodeID: "\(p)_pass_1"),
                ],
                effects: [],
                closesThread: false
            ),
            cheapBought: DMNode(
                id: cheapBought,
                bubbles: cheapBubbles.map { .text($0) },
                choices: [],
                effects: cheapEffects,
                closesThread: true
            ),
            expensiveBought: DMNode(
                id: expensiveBought,
                bubbles: expensiveBubbles.map { .text($0) },
                choices: [],
                effects: expensiveEffects,
                closesThread: true
            ),
            "\(p)_pass_1": DMNode(
                id: "\(p)_pass_1",
                bubbles: [.text(spec.passLine)],
                choices: [],
                effects: [],
                closesThread: true
            ),
        ]
    }

    static func introCompletedNodes(prefix: String) -> Set<String> {
        [
            "\(prefix)_intro_1", "\(prefix)_intro_2", "\(prefix)_decline_1", "\(prefix)_pass_1",
            "\(prefix)_bought_cheap", "\(prefix)_bought_expensive",
        ]
    }

    static func reopenableNodes(prefix: String) -> Set<String> {
        [
            "\(prefix)_pass_1", "\(prefix)_decline_1",
            "\(prefix)_bought_cheap", "\(prefix)_bought_expensive",
        ]
    }
}
