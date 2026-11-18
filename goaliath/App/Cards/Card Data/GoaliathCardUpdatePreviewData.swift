import Foundation

// Optional design-only examples. Never assume these counts are production data.
enum GoaliathCardUpdatePreviewData {
    static func statusEngagement(for status: UserStatus) -> GoaliathStatusEngagement {
        GoaliathStatusEngagement(
            commentCount: 3,
            reactions: [
                GoaliathStatusReaction(emoji: "❤️", count: 12),
                GoaliathStatusReaction(emoji: "👏", count: 5),
                GoaliathStatusReaction(emoji: "🔥", count: 2)
            ],
            comments: [
                GoaliathStatusComment(
                    id: "preview-1", memberName: "Maya",
                    memberAvatarURL: "", text: "Love this update!",
                    createdAt: "2026-11-15T10:05:00-05:00"
                ),
                GoaliathStatusComment(
                    id: "preview-2", memberName: "Jordan",
                    memberAvatarURL: "", text: "Well done 👏",
                    createdAt: "2026-11-15T10:21:00-05:00"
                ),
                GoaliathStatusComment(
                    id: "preview-3", memberName: "Alex",
                    memberAvatarURL: "", text: "Keep it up!",
                    createdAt: "2026-11-15T11:03:00-05:00"
                )
            ]
        )
    }

    // Design preview only: fabricate a clearly isolated local chat transcript.
    // Do NOT feed it into a production conversation or messaging cache.
    static func conversation(for status: UserStatus,
                             currentUserId: String) -> GoaliathMemberConversationData {
        let conversationId = "preview-status-chat-\(status.userId)"
        let memberName = [status.firstName, status.lastName]
            .filter { !$0.isEmpty }.joined(separator: " ")
        let message = Message(
            messageId: "preview-latest-\(status.userId)",
            subject: "",
            messageImageURLs: [],
            messageVideoURLs: [],
            messageGIFMedia: [:],
            conversationId: conversationId,
            senderId: status.userId,
            senderName: memberName,
            senderImage: status.userImageURL,
            createdAt: "2026-11-15T13:40:00-05:00",
            readStatus: "read"
        )
        return GoaliathMemberConversationData(
            message: message,
            entries: [
                GoaliathConversationEntry(
                    messageId: "preview-chat-1", conversationId: conversationId,
                    senderId: status.userId, senderName: memberName,
                    text: "Thanks for checking out my status!",
                    createdAt: "2026-11-15T13:37:00-05:00",
                    senderImageURL: status.userImageURL
                ),
                GoaliathConversationEntry(
                    messageId: "preview-chat-2", conversationId: conversationId,
                    senderId: currentUserId, senderName: "You",
                    text: "Great update! How is it going?",
                    createdAt: "2026-11-15T13:40:00-05:00"
                )
            ]
        )
    }
}
