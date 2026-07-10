import Foundation

/// Long-term dealer relationship — respect, comeback progress, referral discounts.
struct DealerRelationship: Codable, Equatable {
    var respectLevel: Int = 0
    var hasSeenComebackIntro: Bool = false
    var comebackThreadCompleted: Bool = false
    var lastPurchaseHustleTier: Int = 0
    var premiumItemID: String?
    /// Shaves this dealer's premium opening-offer cost (referrals from other dealers).
    var referredOpeningDiscount: Double = 0
    /// Milestone trigger fired; player has an unread comeback thread.
    var comebackPending: Bool = false

    var isInnerCircle: Bool { respectLevel >= 2 }
}

extension GameState {
    func dealerRelationship(for dealer: DMDealer) -> DealerRelationship {
        dealerRelationships[dealer.rawValue] ?? DealerRelationship()
    }

    mutating func updateDealerRelationship(_ dealer: DMDealer, _ mutate: (inout DealerRelationship) -> Void) {
        var rel = dealerRelationship(for: dealer)
        mutate(&rel)
        dealerRelationships[dealer.rawValue] = rel
    }

    mutating func migrateDealerRelationshipsFromThreads() {
        for dealer in DMDealer.allCases {
            guard dealerRelationships[dealer.rawValue] == nil else { continue }
            let thread = dmThread(for: dealer)
            guard thread.respectsPlayer else { continue }
            dealerRelationships[dealer.rawValue] = DealerRelationship(
                respectLevel: 1,
                premiumItemID: dealer.premiumItemID
            )
        }
    }
}

extension DMDealer {
    /// Premium-tier item id for this dealer's opening offer.
    var premiumItemID: String {
        RexItem.forDealer(self).sorted { $0.tier < $1.tier }.last?.id ?? ""
    }

    var premiumItemName: String {
        RexItem.byID(premiumItemID)?.name ?? "the piece"
    }
}
