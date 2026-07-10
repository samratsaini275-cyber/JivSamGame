import SwiftUI

struct RexChatView: View {
    @EnvironmentObject var game: Game
    var embedded: Bool = false

    @State private var activeDealer: DMDealer?
    @State private var affordTooltip: String?
    @State private var scrollToken = 0

    var body: some View {
        Group {
            if let dealer = activeDealer {
                dmThreadView(dealer)
            } else {
                inboxView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            game.markRexMet()
            game.prepareDMInbox()
        }
    }

    // MARK: - Inbox

    private var inboxView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("DMs").kicker()
                Spacer()
                if game.rexUnreadCount > 0 {
                    Text("new")
                        .font(Theme.mono(9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Theme.hype))
                }
            }
            .padding(.horizontal, Theme.screenPadding)
            .padding(.vertical, 12)
            .background(Theme.surface)

            if game.rexUnlocked {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(game.visibleDMThreads()) { dealer in
                            Button { activeDealer = dealer } label: {
                                inboxRow(dealer)
                            }
                            .buttonStyle(PressableButtonStyle(bounce: false))
                        }
                    }
                }
                Spacer(minLength: 0)
            } else {
                emptyInbox
            }

            footerNote
        }
    }

    private func inboxRow(_ dealer: DMDealer) -> some View {
        let unread = DMDialogueEngine.hasUnreadChoices(dealer: dealer, game: game)
        let innerCircle = DMDialogueEngine.isInnerCircle(dealer: dealer, state: game.state)
        return HStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                GameIconTile(name: dealer.iconName, size: 52, tint: dealerAccent(dealer))
                if innerCircle {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.luxeGold)
                        .offset(x: 4, y: 4)
                } else if dealer.verified {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.hypeBlue)
                        .offset(x: 4, y: 4)
                }
                if unread {
                    Circle().fill(Theme.hype).frame(width: 10, height: 10).offset(x: 2, y: -2)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(dealer.title)
                        .font(Theme.cartoonFont(13, weight: .heavy))
                        .foregroundStyle(.white)
                    if innerCircle {
                        Text("INNER")
                            .font(Theme.cartoonFont(8, weight: .black))
                            .foregroundStyle(Theme.luxeGold)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Theme.luxeGold.opacity(0.15)))
                    } else if dealer.verified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.hypeBlue)
                    } else {
                        Text(dealer.badgeEmoji)
                            .font(Theme.cartoonFont(10))
                    }
                    Spacer()
                    Text(game.state.dmThread(for: dealer).threadStarted ? "now" : "new")
                        .font(Theme.cartoonFont(9, weight: .medium))
                        .foregroundStyle(.white.opacity(0.35))
                }
                Text(DMDialogueEngine.inboxPreview(dealer: dealer, state: game.state))
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

    private var emptyInbox: some View {
        VStack(spacing: 12) {
            Spacer()
            GameImage(name: "tab_rex", size: 64)
            Text("No DMs yet")
                .font(Theme.cartoonFont(14, weight: .heavy))
            Text("Unlock Sneaker Resells to hear from Vinnie.")
                .font(Theme.cartoonFont(12, weight: .medium))
                .foregroundStyle(.white.opacity(0.45))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    private var footerNote: some View {
        Text("DM threads reset on Rebrand. Dealer respect, comeback arcs, and your fit stay.")
            .font(Theme.cartoonFont(9, weight: .medium))
            .foregroundStyle(.white.opacity(0.35))
            .multilineTextAlignment(.center)
            .padding(Theme.screenPadding)
            .background(Theme.surface)
    }

    // MARK: - Thread

    private func dmThreadView(_ dealer: DMDealer) -> some View {
        VStack(spacing: 0) {
            threadHeader(dealer)
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 10) {
                        ForEach(game.dmTranscript(for: dealer)) { entry in
                            transcriptBubble(entry)
                                .id(entry.id)
                        }
                    }
                    .padding(.horizontal, Theme.screenPadding)
                    .padding(.vertical, 12)
                }
                .onChange(of: game.dmTranscript(for: dealer).count) { _ in scrollToken += 1 }
                .onChange(of: scrollToken) { _ in scrollToBottom(proxy, dealer: dealer) }
                .onAppear { scrollToBottom(proxy, dealer: dealer) }
            }
            if let tooltip = affordTooltip {
                Text(tooltip)
                    .font(Theme.cartoonFont(10, weight: .semibold))
                    .foregroundStyle(Theme.cloutPink)
                    .padding(.horizontal, Theme.screenPadding)
                    .padding(.bottom, 4)
            }
            if !currentChoices(dealer).isEmpty {
                replyBar(dealer)
            }
        }
        .onAppear { game.onDMThreadOpened(dealer) }
    }

    private func threadHeader(_ dealer: DMDealer) -> some View {
        HStack(spacing: 10) {
            Button { activeDealer = nil } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .buttonStyle(PressableButtonStyle(bounce: false))

            GameIconTile(name: dealer.iconName, size: 40, tint: dealerAccent(dealer))
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(dealer.title)
                        .font(Theme.cartoonFont(13, weight: .heavy))
                    if dealer.verified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.hypeBlue)
                    }
                }
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

    private func currentChoices(_ dealer: DMDealer) -> [DMChoice] {
        guard let nodeID = game.dmCurrentNode(for: dealer) else { return [] }
        return DMScripts.choices(for: dealer, nodeID: nodeID, game: game)
    }

    @ViewBuilder
    private func transcriptBubble(_ entry: DMTranscriptEntry) -> some View {
        switch entry.kind {
        case .contactText, .vinnieText:
            contactBubble(text: entry.text, itemID: nil)
        case .contactItem, .vinnieItem:
            contactBubble(text: entry.text, itemID: entry.itemID)
        case .playerText:
            playerBubble(entry.text)
        }
    }

    private func contactBubble(text: String, itemID: String?) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                if let itemID, let item = RexItem.byID(itemID) {
                    HStack(spacing: 8) {
                        GameIconTile(name: item.imageName, size: 44, tint: Theme.tierColor(item.tier))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(Theme.cartoonFont(11, weight: .heavy))
                                .foregroundStyle(Theme.tierColor(item.tier))
                            Text(item.boostText)
                                .font(Theme.cartoonFont(9, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Theme.surface.opacity(0.6))
                    )
                }
                Text(text)
                    .font(Theme.cartoonFont(12, weight: .medium))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Theme.surfaceRaised)
                    }
            }
            Spacer(minLength: 48)
        }
    }

    private func playerBubble(_ text: String) -> some View {
        HStack {
            Spacer(minLength: 48)
            Text(text)
                .font(Theme.cartoonFont(12, weight: .medium))
                .foregroundStyle(.black)
                .multilineTextAlignment(.trailing)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(game.theme.accent)
                }
            Spacer(minLength: 0)
        }
    }

    private func replyBar(_ dealer: DMDealer) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Reply")
                .font(Theme.cartoonFont(9, weight: .bold))
                .foregroundStyle(.white.opacity(0.4))
                .padding(.horizontal, Theme.screenPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(currentChoices(dealer)) { choice in
                        choiceButton(dealer, choice)
                    }
                }
                .padding(.horizontal, Theme.screenPadding)
            }
        }
        .padding(.vertical, 10)
        .background(Theme.surface)
    }

    private func choiceButton(_ dealer: DMDealer, _ choice: DMChoice) -> some View {
        let enabled = DMScripts.canSelect(choice, game: game)
        return Button {
            if enabled {
                affordTooltip = nil
                game.selectDMChoice(dealer, choice)
                scrollToken += 1
            } else {
                affordTooltip = DMScripts.affordTooltip(for: choice, game: game)
            }
        } label: {
            Text(choice.label)
                .font(Theme.cartoonFont(11, weight: .semibold))
                .foregroundStyle(enabled ? .white : .white.opacity(0.45))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background {
                    Capsule().fill(
                        enabled
                            ? game.theme.accentDeep.opacity(0.85)
                            : Theme.surfaceRaised.opacity(0.8)
                    )
                }
                .shadow(color: enabled ? game.theme.accent.opacity(0.20) : .clear, radius: 8, y: 4)
        }
        .buttonStyle(PressableButtonStyle())
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy, dealer: DMDealer) {
        if let last = game.dmTranscript(for: dealer).last?.id {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(last, anchor: .bottom)
            }
        }
    }
    private func dealerAccent(_ dealer: DMDealer) -> Color {
        switch dealer.accentName {
        case "cloutPink": return Theme.cloutPink
        case "coinGreen": return Theme.coinGreen
        case "luxeGold": return Theme.luxeGold
        case "champagne": return Theme.champagne
        default: return Theme.hypeBlue
        }
    }
}

typealias RexShopView = RexChatView
