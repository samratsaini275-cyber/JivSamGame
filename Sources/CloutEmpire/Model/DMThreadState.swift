import Foundation

struct DMThreadState: Codable, Equatable {
    var threadStarted: Bool = false
    var threadClosed: Bool = false
    var introCompleted: Bool = false
    var respectsPlayer: Bool = false
    var currentNode: String?
    var lastClosedNode: String?
    var transcript: [DMTranscriptEntry] = []

    var comebackThreadStarted: Bool = false
    var comebackThreadClosed: Bool = false
    var comebackCurrentNode: String?
    var comebackLastClosedNode: String?
    var comebackTranscript: [DMTranscriptEntry] = []
}

extension GameState {
    func dmThread(for dealer: DMDealer) -> DMThreadState {
        dmThreads[dealer.rawValue] ?? DMThreadState()
    }

    mutating func updateDMThread(_ dealer: DMDealer, _ mutate: (inout DMThreadState) -> Void) {
        var thread = dmThread(for: dealer)
        mutate(&thread)
        dmThreads[dealer.rawValue] = thread
    }

    mutating func migrateLegacyDMThreadsIfNeeded() {
        guard dmThreads["vinnie"] == nil else { return }
        if vaultThreadStarted || !vaultTranscript.isEmpty {
            dmThreads["vinnie"] = DMThreadState(
                threadStarted: vaultThreadStarted,
                threadClosed: vaultThreadClosed,
                introCompleted: vaultIntroCompleted,
                respectsPlayer: vaultRespectsPlayer,
                currentNode: vaultCurrentNode,
                lastClosedNode: vaultLastClosedNode,
                transcript: vaultTranscript
            )
        }
        if whipThreadStarted || !whipTranscript.isEmpty {
            dmThreads["dre"] = DMThreadState(
                threadStarted: whipThreadStarted,
                threadClosed: whipThreadClosed,
                introCompleted: whipIntroCompleted,
                respectsPlayer: whipRespectsPlayer,
                currentNode: whipCurrentNode,
                lastClosedNode: whipLastClosedNode,
                transcript: whipTranscript
            )
        }
    }

    mutating func resetDMThreadsForRebrand() {
        for dealer in DMDealer.allCases {
            let thread = dmThread(for: dealer)
            let intro = thread.introCompleted
            let respect = thread.respectsPlayer
            let comebackStarted = thread.comebackThreadStarted
            let rel = dealerRelationship(for: dealer)
            var fresh = DMThreadState()
            fresh.introCompleted = intro
            fresh.respectsPlayer = respect
            fresh.comebackThreadStarted = comebackStarted
            dmThreads[dealer.rawValue] = fresh
            updateDealerRelationship(dealer) { r in
                r.hasSeenComebackIntro = rel.hasSeenComebackIntro
                r.comebackThreadCompleted = rel.comebackThreadCompleted
                r.comebackPending = rel.comebackPending
            }
        }
    }
}
