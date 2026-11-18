import Foundation

// MARK: - Local examples for reviewing the UI in Xcode only
// This is not a source of production replies. Do not seed it in the live feed.

enum RequestPostRepliesPreviewData {
    static func samples(for postId: String) -> [RequestPostReply] {
        [
            RequestPostReply(
                replyId: "preview-1", postId: postId, responderId: "member-a",
                responderName: "Tim Carter",
                body: "The finance team at my company is hiring analysts. Happy to share the job description and make an introduction if it's a match.",
                createdAt: "2026-11-15T14:08:00Z",
                responderRole: "Finance Manager", responderLocation: "Philadelphia, PA"
            ),
            RequestPostReply(
                replyId: "preview-2", postId: postId, responderId: "member-b",
                responderName: "Lucy Green",
                body: "I can help review your resume before you apply. Send me the role you're targeting and I'll share a few suggestions.",
                createdAt: "2026-11-15T14:18:00Z",
                responderRole: "Member", responderLocation: "Camden, NJ"
            ),
            RequestPostReply(
                replyId: "preview-3", postId: postId, responderId: "member-c",
                responderName: "Maria Alvarez",
                body: "Are you open to hybrid positions? I know a team that needs someone with financial modeling experience.",
                createdAt: "2026-11-15T15:02:00Z",
                responderRole: "Recruiter", responderLocation: "Philadelphia, PA"
            ),
            RequestPostReply(
                replyId: "preview-4", postId: postId, responderId: "member-a",
                responderName: "Tim Carter",
                body: "Absolutely — I'll send the details through Goaliath once I confirm the hiring manager's contact.",
                createdAt: "2026-11-15T15:09:00Z",
                responderRole: "Finance Manager", responderLocation: "Philadelphia, PA",
                parentReplyId: "preview-3"
            )
        ]
    }
}
