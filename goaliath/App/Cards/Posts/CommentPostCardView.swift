import SwiftUI

// MARK: - Comment-specific actions

enum CommentPostAction {
    case respond(postId: String, text: String)
    case save(postId: String)
    case skip(postId: String)
    case report(postId: String, reason: String, notes: String)
}

private enum CommentPostDestination: String, Identifiable {
    case respond, save, skip, report, replies
    var id: String { rawValue }
}

// MARK: - Dedicated comment card

struct CommentPostCardView: View {
    let post: Post
    let description: String
    var replies: [RequestPostReply] = []
    var onLoadReplies: ((String) async throws -> [RequestPostReply])? = nil
    var onAction: ((CommentPostAction) -> Void)? = nil

    @State private var destination: CommentPostDestination?

    private let ink = GoaliathSocialPalette.ink
    private let accent = GoaliathSocialPalette.comment

    private var firstName: String {
        post.posterName.split(separator: " ").first.map(String.init) ?? "A member"
    }

    private var isSaved: Bool {
        ["saved", "true"].contains(post.savedPostStatus.lowercased())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 17) {
            header
            GoaliathSocialAuthorRow(
                name: post.posterName,
                avatarURL: post.posterImageURL,
                role: post.posterRole,
                location: post.posterLocation
            )
            VStack(alignment: .leading, spacing: 9) {
                Text(post.subject.isEmpty ? "A new thought from the community" : post.subject)
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                    .foregroundStyle(ink)
                    .fixedSize(horizontal: false, vertical: true)
                if !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(description)
                        .font(.system(size: 15))
                        .foregroundStyle(ink.opacity(0.86))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            HStack(spacing: 8) {
                GoaliathSocialDateCell(caption: "COMMENTED", text: post.createdAt)
                if !post.expiresAt.isEmpty {
                    GoaliathSocialDateCell(caption: "AVAILABLE UNTIL", text: post.expiresAt)
                }
            }
            GoaliathSocialMediaGallery(post: post)
            GoaliathSocialReplySummary(
                count: post.postResponseCount,
                avatarURLs: post.responderImageUrls,
                tint: accent
            ) { destination = .replies }
            buttons
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.black.opacity(0.04), lineWidth: 1)
        }
        .sheet(item: $destination) { selected in
            NavigationStack {
                switch selected {
                case .respond:
                    GoaliathSocialTextComposer(
                        title: "Respond to Comment",
                        prompt: "Join \(firstName)'s conversation with a thoughtful reply.",
                        placeholder: "Your reply",
                        submitTitle: "Send Reply",
                        isPreview: onAction == nil
                    ) { text in
                        onAction?(.respond(postId: post.postId, text: text))
                    }
                case .save:
                    GoaliathSocialConfirmSheet(
                        title: "Keep this comment handy?",
                        explanation: "Save this thought so you can find it again later.",
                        confirmTitle: "Save Comment",
                        color: accent,
                        isPreview: onAction == nil
                    ) {
                        onAction?(.save(postId: post.postId))
                    }
                case .skip:
                    GoaliathSocialConfirmSheet(
                        title: "Ready for the next conversation?",
                        explanation: "Move past this comment and explore more from the community.",
                        confirmTitle: "Skip Comment",
                        color: GoaliathSocialPalette.neutral,
                        isPreview: onAction == nil
                    ) {
                        onAction?(.skip(postId: post.postId))
                    }
                case .report:
                    GoaliathSocialReportSheet(contentKind: "Comment", isPreview: onAction == nil) { reason, notes in
                        onAction?(.report(postId: post.postId, reason: reason, notes: notes))
                    }
                case .replies:
                    CommentPostDetailsView(
                        post: post,
                        description: description,
                        initialReplies: replies,
                        onLoadReplies: onLoadReplies,
                        onRespond: onAction == nil ? nil : { text in
                            onAction?(.respond(postId: post.postId, text: text))
                        }
                    )
                }
            }
            .presentationDetents(selected == .replies ? [.large] : [.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("COMMUNITY COMMENT")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(1)
                .foregroundStyle(accent)
            Text("\(firstName) joined the conversation")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(ink)
                .fixedSize(horizontal: false, vertical: true)
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "bubble.left.fill")
                    .foregroundStyle(accent)
                    .padding(.top, 2)
                Text("A good conversation can lead to your next big idea. Reply with your perspective or save this insight for later.")
                    .font(.subheadline)
                    .foregroundStyle(ink.opacity(0.87))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private var buttons: some View {
        VStack(spacing: 11) {
            HStack(spacing: 11) {
                GoaliathSocialActionButton(title: "Respond Now", color: accent) {
                    destination = .respond
                }
                GoaliathSocialActionButton(title: isSaved ? "Saved Comment" : "Save Comment",
                                           color: GoaliathSocialPalette.green, isDisabled: isSaved) {
                    destination = .save
                }
            }
            HStack(spacing: 11) {
                GoaliathSocialActionButton(title: "Skip Comment", color: GoaliathSocialPalette.neutral, style: .secondary) {
                    destination = .skip
                }
                GoaliathSocialActionButton(title: "Report Abuse", color: GoaliathSocialPalette.danger, style: .secondary) {
                    destination = .report
                }
            }
        }
    }
}
