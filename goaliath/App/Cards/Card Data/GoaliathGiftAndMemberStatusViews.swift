import SwiftUI

// MARK: - Token gift

struct GoaliathGiftCardView: View {
    let gift: Gift
    var onAction: ((GoaliathCardUpdateAction) -> Void)? = nil

    @State private var thankYouMessage = ""
    @State private var showPreview = false

    private var giverName: String {
        let name = [gift.giftGiver.firstName, gift.giftGiver.lastName]
            .filter { !$0.isEmpty }.joined(separator: " ")
        return name.isEmpty ? gift.giftGiver.username : name
    }

    private var receiverName: String {
        let name = [gift.giftReceiver.firstName, gift.giftReceiver.lastName]
            .filter { !$0.isEmpty }.joined(separator: " ")
        return name.isEmpty ? gift.giftReceiver.username : name
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            GoaliathCardSurface {
                VStack(spacing: 10) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(GoaliathCardLook.orange)
                    Text(gift.tokenCount.formatted())
                        .font(.system(size: 52, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(GoaliathCardLook.ink)
                    Text(gift.tokenCount == 1 ? "TOKEN GIFTED" : "TOKENS GIFTED")
                        .font(.caption.weight(.bold))
                        .tracking(1.6)
                        .foregroundStyle(GoaliathCardLook.orange)
                    Text("\(giverName) gifted \(receiverName) \(gift.tokenCount) \(gift.tokenCount == 1 ? "token" : "tokens")")
                        .font(.headline)
                        .foregroundStyle(GoaliathCardLook.ink)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                HStack(spacing: 8) {
                    GoaliathCardAvatarView(imageURL: gift.giftGiver.userImageURL,
                                           name: giverName, size: 48)
                    Text(giverName).font(.subheadline.weight(.semibold))
                    Spacer()
                    Image(systemName: "arrow.right").foregroundStyle(GoaliathCardLook.muted)
                    Spacer()
                    GoaliathCardAvatarView(imageURL: gift.giftReceiver.userImageURL,
                                           name: receiverName, size: 48)
                    Text(receiverName).font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(GoaliathCardLook.ink)
                if !gift.giftMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("A note from \(giverName)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(GoaliathCardLook.muted)
                        Text(gift.giftMessage).font(.subheadline)
                            .foregroundStyle(GoaliathCardLook.ink)
                    }
                }
                GoaliathCardFieldRow(label: "Gifted", value: GoaliathHumanDate.display(gift.giftDate),
                                      symbol: "calendar")
            }
            GoaliathCardSurface {
                Text("Send \(giverName) a thank-you")
                    .font(.headline).foregroundStyle(GoaliathCardLook.ink)
                TextField("Write a personal message (optional)", text: $thankYouMessage,
                          axis: .vertical)
                    .lineLimit(2...4)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Thank-you message to \(giverName)")
                GoaliathCardPillButton(title: "Thank You", tint: GoaliathCardLook.green) {
                    let text = thankYouMessage.trimmingCharacters(in: .whitespacesAndNewlines)
                    if let onAction {
                        onAction(.thankGifter(
                            giftId: gift.giftId,
                            message: text.isEmpty ? "Thank you for the tokens!" : text
                        ))
                    } else {
                        showPreview = true
                    }
                }
                Text("This sends a message only; it does not transfer or mint tokens.")
                    .font(.caption).foregroundStyle(GoaliathCardLook.muted)
            }
        }
        .alert("Preview only", isPresented: $showPreview) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Connect the Thank You action to your messaging service to send this message.")
        }
    }
}

// MARK: - Member status

struct GoaliathMemberStatusCardView: View {
    let status: UserStatus
    let currentUserId: String
    var engagement: GoaliathStatusEngagement? = nil
    var onAction: ((GoaliathCardUpdateAction) -> Void)? = nil
    var onOpenChat: ((String) -> Void)? = nil
    var onLoadMemberConversation: ((String) async throws -> GoaliathMemberConversationData)? = nil
    var onMessageAction: ((GoaliathConversationAction) -> Void)? = nil

    @State private var commentDraft = ""
    @State private var showChat = false
    @State private var showComments = false
    @State private var showPreview = false

    private let emojis = ["❤️", "👏", "🔥", "😊", "💡", "💪"]

    private var memberName: String {
        let name = [status.firstName, status.lastName].filter { !$0.isEmpty }
            .joined(separator: " ")
        return name.isEmpty ? status.username : name
    }

    private var totalReactions: Int? {
        engagement.map { $0.reactions.reduce(0) { $0 + $1.count } }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            GoaliathCardSurface {
                HStack(alignment: .firstTextBaseline) {
                    GoaliathCardTitle(title: "Member Status", symbol: "person.crop.circle",
                                      tint: GoaliathCardLook.violet)
                    Spacer()
                    Text(GoaliathHumanDate.statusTime(status.userStatusDate))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(GoaliathCardLook.muted)
                }
                HStack(spacing: 12) {
                    GoaliathCardAvatarView(imageURL: status.userImageURL,
                                           name: memberName, size: 56)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(memberName)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(GoaliathCardLook.ink)
                        Text(status.username.isEmpty ? "Member" : "Member · @\(status.username)")
                            .font(.caption).foregroundStyle(GoaliathCardLook.muted)
                    }
                    Spacer(minLength: 0)
                    Button {
                        if let onOpenChat {
                            onOpenChat(status.userId)
                        } else {
                            showChat = true
                        }
                    } label: {
                        Image(systemName: "message.fill")
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 46, height: 46)
                            .background(GoaliathCardLook.blue,
                                        in: RoundedRectangle(cornerRadius: 15))
                    }
                    .buttonStyle(GoaliathCardPressStyle())
                    .accessibilityLabel("Open conversation with \(memberName)")
                }
                Text(status.userStatusTitle)
                    .font(.system(size: 23, weight: .bold, design: .rounded))
                    .foregroundStyle(GoaliathCardLook.ink)
                if !status.userStatusDescription.isEmpty {
                    Text(status.userStatusDescription)
                        .font(.subheadline).foregroundStyle(GoaliathCardLook.ink)
                }
                ForEach(status.userStatusImageURLs, id: \.self) { url in
                    GoaliathCardPhoto(imageURL: url, height: 210)
                }
                if !status.userStatusVideoURLs.isEmpty {
                    Label("\(status.userStatusVideoURLs.count) video attachment(s)",
                          systemImage: "video.fill")
                        .font(.caption).foregroundStyle(GoaliathCardLook.muted)
                }
                if !status.userStatusGIFMedia.isEmpty {
                    Label("\(status.userStatusGIFMedia.count) GIF attachment(s)",
                          systemImage: "photo.on.rectangle.angled")
                        .font(.caption).foregroundStyle(GoaliathCardLook.muted)
                }
                GoaliathCardFieldRow(label: "Shared",
                                      value: GoaliathHumanDate.display(status.userStatusDate),
                                      symbol: "clock")
            }

            GoaliathCardSurface {
                HStack(spacing: 12) {
                    Label("\(engagement?.commentCount.formatted() ?? "—") comments",
                          systemImage: "bubble.left.fill")
                    Spacer()
                    Text("\(totalReactions.map(String.init) ?? "—") reactions")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(GoaliathCardLook.ink)

                if let engagement, !engagement.reactions.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(engagement.reactions.filter { $0.count > 0 }) { reaction in
                            Text("\(reaction.emoji) \(reaction.count)")
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(GoaliathCardLook.canvas,
                                            in: Capsule())
                        }
                    }
                }

                Text("React to this status")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(GoaliathCardLook.muted)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 7) {
                        ForEach(emojis, id: \.self) { emoji in
                        Button {
                            if let onAction {
                                onAction(.reactToStatus(memberId: status.userId,
                                                         statusDate: status.userStatusDate,
                                                         emoji: emoji))
                            } else { showPreview = true }
                        } label: {
                            Text(emoji)
                                .font(.system(size: 22))
                                .frame(maxWidth: .infinity)
                                .frame(height: 41)
                                .background(GoaliathCardLook.canvas,
                                            in: RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(GoaliathCardPressStyle())
                        .accessibilityLabel("React \(emoji)")
                        }
                    }
                }
                HStack(spacing: 9) {
                    TextField("Write a comment…", text: $commentDraft, axis: .vertical)
                        .lineLimit(1...3)
                        .textFieldStyle(.roundedBorder)
                    Button {
                        let text = commentDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !text.isEmpty else { return }
                        if let onAction {
                            onAction(.commentOnStatus(memberId: status.userId,
                                                      statusDate: status.userStatusDate, text: text))
                        } else { showPreview = true }
                    } label: {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 42, height: 42)
                            .background(GoaliathCardLook.blue,
                                        in: RoundedRectangle(cornerRadius: 13))
                    }
                    .disabled(commentDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityLabel("Send status comment")
                }
                if let engagement, !engagement.comments.isEmpty {
                    Button("View comments") { showComments = true }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(GoaliathCardLook.blue)
                }
            }
        }
        .sheet(isPresented: $showChat) {
            GoaliathMemberStatusChatSheet(
                memberId: status.userId, memberName: memberName,
                currentUserId: currentUserId,
                onLoadConversation: onLoadMemberConversation,
                onMessageAction: onMessageAction
            )
        }
        .sheet(isPresented: $showComments) {
            NavigationStack {
                List(engagement?.comments ?? []) { comment in
                    HStack(alignment: .top, spacing: 10) {
                        GoaliathCardAvatarView(imageURL: comment.memberAvatarURL,
                                               name: comment.memberName, size: 36)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(comment.memberName).font(.subheadline.weight(.bold))
                            Text(comment.text).font(.subheadline)
                            Text(GoaliathHumanDate.display(comment.createdAt))
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
                .navigationTitle("Status Comments")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showComments = false }
                }}
            }
        }
        .alert("Preview only", isPresented: $showPreview) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Connect status comments and reactions to your social service. Counts update only from actual data.")
        }
    }
}

// Real chat, using the previously added MessageConversationCardView.
// No fake conversation identifier or transcript is manufactured.
struct GoaliathMemberStatusChatSheet: View {
    let memberId: String
    let memberName: String
    let currentUserId: String
    var onLoadConversation: ((String) async throws -> GoaliathMemberConversationData)?
    var onMessageAction: ((GoaliathConversationAction) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var context: GoaliathMemberConversationData?
    @State private var loading = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let context {
                        MessageConversationCardView(
                            message: context.message,
                            currentUserId: currentUserId,
                            memberRole: context.role,
                            memberLocation: context.location,
                            initialMessages: context.entries,
                            onAction: onMessageAction
                        )
                    } else if loading {
                        ProgressView("Loading conversation…")
                            .padding(.top, 80)
                    } else {
                        ContentUnavailableView(
                            error == nil ? "Conversation unavailable" : "Couldn't open conversation",
                            systemImage: "bubble.left.and.bubble.right",
                            description: Text(error ?? "Connect your messaging service to open the conversation with \(memberName).")
                        )
                        Button("Try Again") {
                            _Concurrency.Task { await load() }
                        }
                        .disabled(onLoadConversation == nil)
                    }
                }
                .padding(16)
            }
            .background(GoaliathCardLook.canvas)
            .navigationTitle(memberName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }}
        }
        .task(id: memberId) { await load() }
    }

    private func load() async {
        guard let onLoadConversation else { return }
        loading = true
        error = nil
        do {
            context = try await onLoadConversation(memberId)
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }
}
