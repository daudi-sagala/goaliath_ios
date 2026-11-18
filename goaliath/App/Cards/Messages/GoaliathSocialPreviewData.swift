import Foundation

/// Explicitly optional, for local testing. These records are not real server data.
enum GoaliathSocialPreviewData {
    static let previewCurrentUserID = "preview-current-user"
    static let previewOtherUserID = "preview-community-member"

    static func conversation(conversationId: String, peerName: String = "Jon Doe") -> [GoaliathConversationEntry] {
        [
            GoaliathConversationEntry(
                messageId: "demo-message-01", conversationId: conversationId,
                senderId: previewOtherUserID, senderName: peerName,
                text: "Hey! I saw your goal and thought I could help.",
                createdAt: "2026-11-15T10:05:00-05:00"
            ),
            GoaliathConversationEntry(
                messageId: "demo-message-02", conversationId: conversationId,
                senderId: previewCurrentUserID, senderName: "You",
                text: "That would be amazing. What did you have in mind?",
                createdAt: "2026-11-15T10:07:00-05:00"
            ),
            GoaliathConversationEntry(
                messageId: "demo-message-03", conversationId: conversationId,
                senderId: previewOtherUserID, senderName: peerName,
                text: "A friend of mine is looking for someone with your experience. Would you like an introduction?",
                createdAt: "2026-11-15T10:12:00-05:00"
            ),
            GoaliathConversationEntry(
                messageId: "demo-message-04", conversationId: conversationId,
                senderId: previewCurrentUserID, senderName: "You",
                text: "Yes, please! I really appreciate it.",
                createdAt: "2026-11-15T10:18:00-05:00"
            )
        ]
    }

    static func postReplies(postId: String, peerName: String = "Jon Doe") -> [RequestPostReply] {
        [
            RequestPostReply(
                replyId: "demo-reply-1", postId: postId,
                responderId: "preview-user-a", responderName: "Lucy Chen",
                body: "This is a useful idea — I tried a similar approach last week.",
                createdAt: "2026-11-15T10:03:00-05:00"
            ),
            RequestPostReply(
                replyId: "demo-reply-2", postId: postId,
                responderId: previewOtherUserID, responderName: peerName,
                body: "Thanks, Lucy! Would love to hear how it worked for you.",
                createdAt: "2026-11-15T10:15:00-05:00",
                parentReplyId: "demo-reply-1"
            )
        ]
    }
}
