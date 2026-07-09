import SwiftUI

struct RexChatView: View {
    @EnvironmentObject var game: Game
    @Environment(\.dismiss) private var dismiss
    var embedded: Bool = false

    @State private var selectedThread: RexDMThread?

    var body: some View {
        Group {
            if let thread = selectedThread {
                DMThreadView(thread: thread, onBack: { selectedThread = nil })
            } else {
                DMInboxView(onSelect: { selectedThread = $0 })
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { game.markRexMet() }
    }
}

// MARK: - Inbox

private struct DMInboxView: View {
    @EnvironmentObject var game: Game
    let onSelect: (RexDMThread) -> Void

    private var threads: [RexDMThread] { RexDMThread.unlocked(for: game) }

    var body: some View {
        VStack(spacing: 0) {
            inboxHeader
            if threads.isEmpty {
                lockedPlaceholder
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(threads) { thread in
                            inboxRow(thread)
                            Divider().overlay(Theme.comicBorder.opacity(0.35))
                        }
                    }
                }
            }
            footerNote
        }
    }

    private var inboxHeader: some View {
        HStack {
            Text("DMs").kicker()
            Spacer()
            if game.rexUnreadCount > 0 {
                Text("\(game.rexUnreadCount) new")
                    .font(Theme.cartoonFont(10, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(.red))
            }
        }
        .padding(.horizontal, Theme.screenPadding)
        .padding(.vertical, 12)
        .background(Theme.surface)
    }

    private func inboxRow(_ thread: RexDMThread) -> some View {
        let unread = threadHasUnread(thread)
        return Button { onSelect(thread) } label: {
            HStack(spacing: 12) {
                ZStack(alignment: .bottomTrailing) {
                    GameIconTile(name: "tab_rex", size: 52, tint: Theme.hypeBlue)
                    if unread {
                        Circle().fill(.red).frame(width: 10, height: 10).offset(x: 2, y: 2)
                    }
                }
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(thread.title)
                            .font(Theme.cartoonFont(13, weight: .heavy))
                            .foregroundStyle(.white)
                        Spacer()
                        Text("now")
                            .font(Theme.cartoonFont(9, weight: .medium))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                    Text(thread.preview)
                        .font(Theme.cartoonFont(11, weight: unread ? .bold : .medium))
                        .foregroundStyle(unread ? .white.opacity(0.85) : .white.opacity(0.45))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(.horizontal, Theme.screenPadding)
            .padding(.vertical, 12)
            .background(unread ? Theme.surfaceRaised.opacity(0.55) : Color.clear)
        }
        .buttonStyle(PressableButtonStyle(bounce: false))
    }

    private func threadHasUnread(_ thread: RexDMThread) -> Bool {
        let messages = RexChatBuilder.messages(for: thread, game: game)
        return RexChatBuilder.pendingPitch(in: messages, game: game) != nil
    }

    private var lockedPlaceholder: some View {
        VStack(spacing: 12) {
            Spacer()
            GameImage(name: "tab_rex", size: 64)
            Text("No new DMs yet")
                .font(Theme.cartoonFont(14, weight: .heavy))
            Text("Unlock Sneaker Resells to get on Rex's radar.")
                .font(Theme.cartoonFont(12, weight: .medium))
                .foregroundStyle(.white.opacity(0.45))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var footerNote: some View {
        VStack(spacing: 4) {
            if game.state.daytonaPurchases > 0 {
                Text("Daytona legacy: +\(Int(Double(game.state.daytonaPurchases) * Formulas.daytonaGainRatePerPurchase * 100))% Clout — forever.")
                    .font(Theme.cartoonFont(10, weight: .semibold))
                    .foregroundStyle(Theme.cloutPink)
            }
            Text("Gear wipes on Rebrand. Rex's DMs don't.")
                .font(Theme.cartoonFont(9, weight: .medium))
                .foregroundStyle(.white.opacity(0.35))
        }
        .multilineTextAlignment(.center)
        .padding(Theme.screenPadding)
        .background(Theme.surface)
    }
}

// MARK: - Thread

private struct DMThreadView: View {
    @EnvironmentObject var game: Game
    let thread: RexDMThread
    let onBack: () -> Void

    @State private var scrollToken = 0

    private var messages: [RexChatMessage] {
        RexChatBuilder.messages(for: thread, game: game)
    }

    private var pendingPitchID: String? {
        RexChatBuilder.pendingPitch(in: messages, game: game)
    }

    private var replies: [RexReply] {
        guard let pitchID = pendingPitchID else { return [] }
        return RexChatBuilder.replies(for: pitchID, thread: thread, game: game)
    }

    var body: some View {
        VStack(spacing: 0) {
            threadHeader
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 10) {
                        ForEach(messages) { msg in
                            chatBubble(msg)
                                .id(msg.id)
                        }
                    }
                    .padding(.horizontal, Theme.screenPadding)
                    .padding(.vertical, 12)
                }
                .onChange(of: game.state.rexPitchReplies.count) { _ in scrollToken += 1 }
                .onChange(of: scrollToken) { _ in scrollToBottom(proxy) }
                .onAppear { scrollToBottom(proxy) }
            }
            if !replies.isEmpty {
                replyBar
            }
        }
    }

    private var threadHeader: some View {
        HStack(spacing: 10) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .buttonStyle(PressableButtonStyle(bounce: false))

            GameIconTile(name: "tab_rex", size: 40, tint: Theme.hypeBlue)
            VStack(alignment: .leading, spacing: 2) {
                Text(thread.title)
                    .font(Theme.cartoonFont(13, weight: .heavy))
                Text("Active now")
                    .font(Theme.cartoonFont(9, weight: .semibold))
                    .foregroundStyle(Theme.coinGreen)
            }
            Spacer()
        }
        .padding(.horizontal, Theme.screenPadding)
        .padding(.vertical, 10)
        .background(Theme.surface)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.comicBorder.opacity(0.4)).frame(height: 1)
        }
    }

    @ViewBuilder
    private func chatBubble(_ msg: RexChatMessage) -> some View {
        HStack {
            if msg.sender == .player { Spacer(minLength: 48) }
            VStack(alignment: msg.sender == .rex ? .leading : .trailing, spacing: 4) {
                if msg.sender == .rex, let itemID = msg.itemID,
                   let item = RexItem.byID(itemID) {
                    HStack(spacing: 6) {
                        GameIconTile(name: item.imageName, size: 36, tint: Theme.tierColor(item.tier))
                        Text(item.name)
                            .font(Theme.cartoonFont(10, weight: .bold))
                            .foregroundStyle(Theme.tierColor(item.tier))
                    }
                }
                Text(msg.text)
                    .font(Theme.cartoonFont(12, weight: .medium))
                    .foregroundStyle(msg.sender == .rex ? .white : .black)
                    .multilineTextAlignment(msg.sender == .rex ? .leading : .trailing)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(bubbleFill(msg.sender))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(Theme.comicBorder.opacity(0.5), lineWidth: 2)
                    }
            }
            if msg.sender == .rex { Spacer(minLength: 48) }
        }
    }

    private func bubbleFill(_ sender: RexChatMessage.Sender) -> Color {
        switch sender {
        case .rex: return Theme.surfaceRaised
        case .player: return game.theme.accent
        }
    }

    private var replyBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Reply")
                .font(Theme.cartoonFont(9, weight: .bold))
                .foregroundStyle(.white.opacity(0.4))
                .padding(.horizontal, Theme.screenPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(replies) { reply in
                        Button(reply.label) { select(reply) }
                            .font(Theme.cartoonFont(11, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background {
                                Capsule().fill(game.theme.accentDeep.opacity(0.85))
                            }
                            .overlay(Capsule().strokeBorder(Theme.comicBorder, lineWidth: 2))
                            .buttonStyle(PressableButtonStyle())
                    }
                }
                .padding(.horizontal, Theme.screenPadding)
            }
        }
        .padding(.vertical, 10)
        .background(Theme.surface)
    }

    private func select(_ reply: RexReply) {
        guard let pitchID = pendingPitchID else { return }
        game.handleRexReply(reply, pitchID: pitchID)
        scrollToken += 1
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        if let last = messages.last?.id {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(last, anchor: .bottom)
            }
        }
    }
}

// Sheet wrapper for legacy presentation
typealias RexShopView = RexChatView
