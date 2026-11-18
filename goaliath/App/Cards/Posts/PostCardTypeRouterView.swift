import SwiftUI

// MARK: - Post subtype router
// Only one post subtype renders at a time.

struct PostCardTypeRouterView: View {
    let post: Post
    let description: String
    var replies: [RequestPostReply] = []
    var onLoadReplies: ((String) async throws -> [RequestPostReply])? = nil
    var onRequestAction: ((RequestPostAction) -> Void)? = nil
    var onTipAction: ((TipPostAction) -> Void)? = nil
    var onCommentAction: ((CommentPostAction) -> Void)? = nil

    private var kind: String {
        post.postType.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    @ViewBuilder
    var body: some View {
        switch kind {
        case "request", "requests":
            RequestPostCardView(
                post: post,
                description: description,
                replies: replies,
                onLoadReplies: onLoadReplies,
                onAction: onRequestAction
            )
        case "tip", "tips":
            TipPostCardView(
                post: post,
                description: description,
                replies: replies,
                onLoadReplies: onLoadReplies,
                onAction: onTipAction
            )
        case "comment", "comments":
            CommentPostCardView(
                post: post,
                description: description,
                replies: replies,
                onLoadReplies: onLoadReplies,
                onAction: onCommentAction
            )
        default:
            ContentUnavailableView(
                "Unsupported post type",
                systemImage: "square.stack.3d.up",
                description: Text("This post subtype isn't supported: \(post.postType)")
            )
        }
    }
}

// MARK: - Main type router for Post and Message cards
// In your existing CardContentLayer, use this for "post" and "message"
// and preserve the other data type cases unchanged.

struct GoaliathPostMessageCardRouterView: View {
    let card: CardData
    let currentUserId: String

    var messageMemberRole: String = "Member"
    var messageMemberLocation: String = ""
    var postReplies: [RequestPostReply] = []
    var chatMessages: [GoaliathConversationEntry] = []
    var onLoadReplies: ((String) async throws -> [RequestPostReply])? = nil
    var onLoadMessages: ((String) async throws -> [GoaliathConversationEntry])? = nil
    var onRequestAction: ((RequestPostAction) -> Void)? = nil
    var onTipAction: ((TipPostAction) -> Void)? = nil
    var onCommentAction: ((CommentPostAction) -> Void)? = nil
    var onMessageAction: ((GoaliathConversationAction) -> Void)? = nil

    @ViewBuilder
    var body: some View {
        switch card.cardDataTypeId {
        case "post":
            if let post = card.cardDataType.post {
                PostCardTypeRouterView(
                    post: post,
                    description: card.description,
                    replies: postReplies,
                    onLoadReplies: onLoadReplies,
                    onRequestAction: onRequestAction,
                    onTipAction: onTipAction,
                    onCommentAction: onCommentAction
                )
            } else {
                missingPayload("Post")
            }
        case "message":
            if let message = card.cardDataType.message {
                MessageConversationCardView(
                    message: message,
                    currentUserId: currentUserId,
                    memberRole: messageMemberRole,
                    memberLocation: messageMemberLocation,
                    initialMessages: chatMessages,
                    onLoadMessages: onLoadMessages,
                    onAction: onMessageAction
                )
            } else {
                missingPayload("Message")
            }
        default:
            missingPayload("Social card")
        }
    }

    private func missingPayload(_ name: String) -> some View {
        ContentUnavailableView(
            "\(name) unavailable",
            systemImage: "exclamationmark.bubble",
            description: Text("This card has no matching data payload.")
        )
    }
}
