import SwiftUI

// MARK: - Message is your existing conversation metadata model.
// This separate model represents each real message in that conversation.

struct GoaliathConversationEntry: Codable, Identifiable, Hashable {
    let messageId: String
    let conversationId: String
    let senderId: String
    let senderName: String
    let senderImageURL: String
    let text: String
    let createdAt: String
    let imageURLs: [String]

    var id: String { messageId }

    init(
        messageId: String,
        conversationId: String,
        senderId: String,
        senderName: String,
        text: String,
        createdAt: String,
        senderImageURL: String = "",
        imageURLs: [String] = []
    ) {
        self.messageId = messageId
        self.conversationId = conversationId
        self.senderId = senderId
        self.senderName = senderName
        self.text = text
        self.createdAt = createdAt
        self.senderImageURL = senderImageURL
        self.imageURLs = imageURLs
    }
}

enum GoaliathConversationAction {
    case markRead(messageId: String, conversationId: String)
    case reply(conversationId: String, text: String)
}

// MARK: - Dedicated chat card

struct MessageConversationCardView: View {
    let message: Message
    /// Supply the actual signed-in ID to identify outgoing messages accurately.
    let currentUserId: String
    var memberRole: String = "Member"
    var memberLocation: String = ""
    var initialMessages: [GoaliathConversationEntry] = []
    var onLoadMessages: ((String) async throws -> [GoaliathConversationEntry])? = nil
    var onAction: ((GoaliathConversationAction) -> Void)? = nil

    @State private var entries: [GoaliathConversationEntry] = []
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var showReply = false
    @State private var showPreviewReadAlert = false

    private let ink = GoaliathSocialPalette.ink
    private let tint = GoaliathSocialPalette.comment

    private var peerName: String {
        message.senderName.isEmpty ? "this member" : message.senderName
    }

    private var sortedMessages: [GoaliathConversationEntry] {
        entries.filter { $0.conversationId == message.conversationId }
            .sorted { lhs, rhs in
                let a = GoaliathSocialDate.parse(lhs.createdAt) ?? .distantPast
                let b = GoaliathSocialDate.parse(rhs.createdAt) ?? .distantPast
                if a == b { return lhs.messageId < rhs.messageId }
                return a < b
            }
    }

    private var isAlreadyRead: Bool {
        ["read", "seen"].contains(message.readStatus.lowercased())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 17) {
            header
            peer
            thread
            actions
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.black.opacity(0.04), lineWidth: 1)
        }
        .task(id: message.conversationId) {
            if onLoadMessages != nil {
                await refreshMessages()
            } else {
                entries = initialMessages.filter { $0.conversationId == message.conversationId }
            }
        }
        .sheet(isPresented: $showReply) {
            NavigationStack {
                GoaliathSocialTextComposer(
                    title: "Reply to \(peerName)",
                    prompt: "Continue the conversation with \(peerName).",
                    placeholder: "Your message",
                    submitTitle: "Send Message",
                    isPreview: onAction == nil
                ) { text in
                    onAction?(.reply(conversationId: message.conversationId, text: text))
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .alert("Preview Only", isPresented: $showPreviewReadAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Connect the Mark Read action to your messaging service to update the read status.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("DIRECT MESSAGE")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(1)
                .foregroundStyle(tint)
            Text("Conversation with \(peerName)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var peer: some View {
        VStack(alignment: .leading, spacing: 9) {
            GoaliathSocialAuthorRow(
                name: peerName,
                avatarURL: message.senderImage,
                role: memberRole,
                location: memberLocation
            )
            if !message.subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(message.subject)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(GoaliathSocialPalette.muted)
            }
        }
    }

    private var thread: some View {
        ScrollViewReader { scrollProxy in
            ScrollView(.vertical) {
                LazyVStack(spacing: 12) {
                    if isLoading && sortedMessages.isEmpty {
                        ProgressView("Loading conversation…")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 110)
                    }
                    if let loadError {
                        VStack(spacing: 10) {
                            Text("Couldn't load this conversation")
                                .font(.headline)
                            Text(loadError)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Button("Try Again") {
                                _Concurrency.Task { await refreshMessages() }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(tint)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 36)
                    }
                    if sortedMessages.isEmpty && !isLoading && loadError == nil {
                        VStack(spacing: 12) {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.system(size: 32))
                                .foregroundStyle(tint)
                            Text("Conversation not loaded")
                                .font(.headline)
                                .foregroundStyle(ink)
                            Text("Provide the messages for this conversation or connect a loader to show the chat history.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(25)
                    }
                    ForEach(sortedMessages.indices, id: \.self) { index in
                        let item = sortedMessages[index]
                        if index == 0 || GoaliathSocialDate.day(sortedMessages[index - 1].createdAt) != GoaliathSocialDate.day(item.createdAt) {
                            Text(GoaliathSocialDate.day(item.createdAt))
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(GoaliathSocialPalette.muted)
                                .padding(.vertical, 6)
                                .frame(maxWidth: .infinity)
                        }
                        GoaliathChatBubble(
                            entry: item,
                            isOutgoing: !currentUserId.isEmpty && item.senderId == currentUserId,
                            peerAvatarURL: message.senderImage
                        )
                        .id(item.id)
                    }
                    Color.clear.frame(height: 1).id("chat-bottom")
                }
                .padding(14)
                .frame(maxWidth: .infinity)
            }
            .frame(height: 405)
            .background(GoaliathSocialPalette.canvas.opacity(0.75),
                        in: RoundedRectangle(cornerRadius: 19, style: .continuous))
            .onChange(of: sortedMessages.count) { _, _ in
                scrollProxy.scrollTo("chat-bottom", anchor: .bottom)
            }
            .onAppear {
                scrollProxy.scrollTo("chat-bottom", anchor: .bottom)
            }
        }
    }

    private var actions: some View {
        HStack(spacing: 11) {
            GoaliathSocialActionButton(
                title: isAlreadyRead ? "Already Read" : "Mark Read",
                color: tint,
                style: .secondary,
                isDisabled: isAlreadyRead
            ) {
                if let onAction {
                    onAction(.markRead(messageId: message.messageId,
                                       conversationId: message.conversationId))
                } else {
                    showPreviewReadAlert = true
                }
            }
            GoaliathSocialActionButton(title: "Reply Now", color: tint) {
                showReply = true
            }
        }
    }

    @MainActor
    private func refreshMessages() async {
        guard let onLoadMessages else { return }
        isLoading = true
        loadError = nil
        defer { isLoading = false }
        do {
            let result = try await onLoadMessages(message.conversationId)
            guard !_Concurrency.Task<Never, Never>.isCancelled else { return }
            entries = result.filter { $0.conversationId == message.conversationId }
        } catch {
            guard !_Concurrency.Task<Never, Never>.isCancelled else { return }
            loadError = error.localizedDescription
        }
    }
}

// MARK: - Individual chat bubble

private struct GoaliathChatBubble: View {
    let entry: GoaliathConversationEntry
    let isOutgoing: Bool
    let peerAvatarURL: String

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isOutgoing { Spacer(minLength: 55) }
            if !isOutgoing {
                GoaliathSocialAvatar(
                    urlString: entry.senderImageURL.isEmpty ? peerAvatarURL : entry.senderImageURL,
                    name: entry.senderName,
                    size: 27
                )
            }
            VStack(alignment: isOutgoing ? .trailing : .leading, spacing: 6) {
                VStack(alignment: .leading, spacing: 8) {
                    if !entry.text.isEmpty {
                        Text(entry.text)
                            .font(.system(size: 14))
                            .foregroundStyle(isOutgoing ? .white : GoaliathSocialPalette.ink)
                            .textSelection(.enabled)
                    }
                    ForEach(Array(entry.imageURLs.enumerated()), id: \.offset) { _, url in
                        if let remoteURL = URL(string: url),
                           ["https", "http"].contains(remoteURL.scheme?.lowercased() ?? "") {
                            AsyncImage(url: remoteURL) { phase in
                                if case let .success(image) = phase {
                                    image.resizable().scaledToFit()
                                } else {
                                    Image(systemName: "photo")
                                        .font(.title3)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(maxWidth: 200, maxHeight: 190)
                            .clipShape(RoundedRectangle(cornerRadius: 11))
                        }
                    }
                }
                .padding(.horizontal, 13)
                .padding(.vertical, 11)
                .background(isOutgoing ? GoaliathSocialPalette.comment : Color.white,
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                Text(GoaliathSocialDate.time(entry.createdAt))
                    .font(.system(size: 10))
                    .foregroundStyle(GoaliathSocialPalette.muted)
                    .padding(.horizontal, 3)
            }
            if !isOutgoing { Spacer(minLength: 55) }
        }
        .frame(maxWidth: .infinity)
    }
}
