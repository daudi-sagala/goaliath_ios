import SwiftUI

// Shares the already established RequestPostReply transport shape.
// The visible Tip and Comment details remain independently named views.

struct TipPostDetailsView: View {
    let post: Post
    let description: String
    var initialReplies: [RequestPostReply] = []
    var onLoadReplies: ((String) async throws -> [RequestPostReply])? = nil
    var onRespond: ((String) -> Void)? = nil

    var body: some View {
        GoaliathPostConversationView(
            post: post,
            description: description,
            kind: "TIP",
            tint: GoaliathSocialPalette.tip,
            initialReplies: initialReplies,
            onLoadReplies: onLoadReplies,
            onRespond: onRespond
        )
        .navigationTitle("Tip Details")
    }
}

struct CommentPostDetailsView: View {
    let post: Post
    let description: String
    var initialReplies: [RequestPostReply] = []
    var onLoadReplies: ((String) async throws -> [RequestPostReply])? = nil
    var onRespond: ((String) -> Void)? = nil

    var body: some View {
        GoaliathPostConversationView(
            post: post,
            description: description,
            kind: "COMMENT",
            tint: GoaliathSocialPalette.comment,
            initialReplies: initialReplies,
            onLoadReplies: onLoadReplies,
            onRespond: onRespond
        )
        .navigationTitle("Comment Details")
    }
}

private struct GoaliathPostConversationView: View {
    let post: Post
    let description: String
    let kind: String
    let tint: Color
    let initialReplies: [RequestPostReply]
    let onLoadReplies: ((String) async throws -> [RequestPostReply])?
    let onRespond: ((String) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var replies: [RequestPostReply] = []
    @State private var loading = false
    @State private var failure: String?
    @State private var newestFirst = false
    @State private var showComposer = false

    private var sorted: [RequestPostReply] {
        replies.sorted { a, b in
            let lhs = GoaliathSocialDate.parse(a.createdAt) ?? .distantPast
            let rhs = GoaliathSocialDate.parse(b.createdAt) ?? .distantPast
            if lhs == rhs { return a.replyId < b.replyId }
            return newestFirst ? lhs > rhs : lhs < rhs
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("COMMUNITY \(kind)")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(tint)
                    Text(post.subject.isEmpty ? "Shared \(kind.lowercased())" : post.subject)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(GoaliathSocialPalette.ink)
                    GoaliathSocialAuthorRow(
                        name: post.posterName,
                        avatarURL: post.posterImageURL,
                        role: post.posterRole,
                        location: post.posterLocation
                    )
                    if !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(GoaliathSocialPalette.ink)
                            .textSelection(.enabled)
                    }
                    HStack(spacing: 8) {
                        GoaliathSocialDateCell(caption: "ADDED", text: post.createdAt)
                        if !post.expiresAt.isEmpty {
                            GoaliathSocialDateCell(caption: "EXPIRES", text: post.expiresAt)
                        }
                    }
                    GoaliathSocialMediaGallery(post: post)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white, in: RoundedRectangle(cornerRadius: 22))

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Community Replies")
                            .font(.system(size: 21, weight: .bold, design: .rounded))
                            .foregroundStyle(GoaliathSocialPalette.ink)
                        Text(loading ? "Loading…" :
                             (post.postResponseCount > replies.count
                              ? "Showing \(replies.count) of \(post.postResponseCount) replies"
                              : "\(replies.count) \(replies.count == 1 ? "reply" : "replies")"))
                            .font(.caption)
                            .foregroundStyle(GoaliathSocialPalette.muted)
                    }
                    Spacer()
                    if !replies.isEmpty {
                        Menu {
                            Button("Oldest first") { newestFirst = false }
                            Button("Newest first") { newestFirst = true }
                        } label: {
                            Label(newestFirst ? "Newest" : "Oldest", systemImage: "arrow.up.arrow.down")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(tint)
                        }
                    }
                }
                .padding(.horizontal, 4)

                if loading && replies.isEmpty {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text("Fetching replies…")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                }
                if let failure {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Couldn't load replies").font(.headline)
                        Text(failure).font(.caption).foregroundStyle(.secondary)
                        Button("Try Again") { _Concurrency.Task { await loadReplies() } }
                            .buttonStyle(.borderedProminent)
                            .tint(tint)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(.white, in: RoundedRectangle(cornerRadius: 18))
                }
                if !replies.isEmpty {
                    LazyVStack(spacing: 11) {
                        ForEach(sorted) { reply in
                            GoaliathPostReplyCard(
                                reply: reply,
                                parentName: replies.first(where: { $0.replyId == reply.parentReplyId })?.responderName,
                                originalAuthorId: post.posterId,
                                tint: tint
                            )
                        }
                    }
                } else if !loading && failure == nil {
                    VStack(spacing: 8) {
                        Image(systemName: "text.bubble")
                            .font(.system(size: 27))
                            .foregroundStyle(tint)
                        Text(post.postResponseCount == 0 ? "Start the conversation" : "Replies aren't available yet")
                            .font(.headline)
                        Text(post.postResponseCount == 0
                             ? "Share a helpful thought or question."
                             : "Reply details must be loaded from your app's service.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                    .background(.white, in: RoundedRectangle(cornerRadius: 18))
                }
            }
            .frame(maxWidth: 670)
            .frame(maxWidth: .infinity)
            .padding(16)
        }
        .background(GoaliathSocialPalette.canvas.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            GoaliathSocialActionButton(
                title: kind == "TIP" ? "Respond to Tip" : "Respond Now",
                color: tint
            ) { showComposer = true }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial)
        }
        .task(id: post.postId) {
            if onLoadReplies != nil {
                await loadReplies()
            } else {
                replies = initialReplies.filter { $0.postId == post.postId }
            }
        }
        .sheet(isPresented: $showComposer) {
            NavigationStack {
                GoaliathSocialTextComposer(
                    title: kind == "TIP" ? "Respond to Tip" : "Reply to Comment",
                    prompt: "Share a thoughtful response with \(post.posterName.isEmpty ? "this member" : post.posterName).",
                    placeholder: "Your response",
                    submitTitle: "Send Response",
                    isPreview: onRespond == nil,
                    onSubmit: { onRespond?($0) }
                )
            }
            .presentationDetents([.medium, .large])
        }
    }

    @MainActor
    private func loadReplies() async {
        guard let onLoadReplies else { return }
        loading = true
        failure = nil
        defer { loading = false }
        do {
            let result = try await onLoadReplies(post.postId)
            guard !_Concurrency.Task<Never, Never>.isCancelled else { return }
            replies = result.filter { $0.postId == post.postId }
        } catch {
            guard !_Concurrency.Task<Never, Never>.isCancelled else { return }
            failure = error.localizedDescription
        }
    }
}

private struct GoaliathPostReplyCard: View {
    let reply: RequestPostReply
    let parentName: String?
    let originalAuthorId: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            GoaliathSocialAvatar(urlString: reply.responderImageURL,
                                 name: reply.responderName, size: 42)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(reply.responderName.isEmpty ? "Goaliath member" : reply.responderName)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(GoaliathSocialPalette.ink)
                    if !originalAuthorId.isEmpty && reply.responderId == originalAuthorId {
                        Text("AUTHOR")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(tint)
                    }
                    Spacer(minLength: 0)
                }
                Text([reply.responderRole.isEmpty ? "Member" : reply.responderRole,
                      reply.responderLocation].filter { !$0.isEmpty }.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(GoaliathSocialPalette.muted)
                if let parentName {
                    Text("Replying to \(parentName)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(tint)
                }
                Text(reply.body)
                    .font(.subheadline)
                    .foregroundStyle(GoaliathSocialPalette.ink)
                    .textSelection(.enabled)
                Text(GoaliathSocialDate.display(reply.createdAt))
                    .font(.caption2)
                    .foregroundStyle(GoaliathSocialPalette.muted)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 18))
    }
}
