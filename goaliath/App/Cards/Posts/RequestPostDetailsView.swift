import SwiftUI
import AVKit
import WebKit

// MARK: - Reply data

/// Represents one response to a request post. Goaliath's existing `Post`
/// contains reply counts and avatar URLs, but not the actual reply bodies.
/// Keep replies in a separate collection rather than inventing them from counts.
struct RequestPostReply: Codable, Identifiable, Hashable {
    let replyId: String
    let postId: String
    let responderId: String
    let responderName: String
    let responderImageURL: String
    let responderRole: String
    let responderLocation: String
    let body: String
    let createdAt: String
    let parentReplyId: String?
    var image_urls: [String]? = nil
    var video_urls: [String]? = nil
    var gif_urls: [String]? = nil

    var id: String { replyId }

    init(
        replyId: String,
        postId: String,
        responderId: String,
        responderName: String,
        body: String,
        createdAt: String,
        responderImageURL: String = "",
        responderRole: String = "Member",
        responderLocation: String = "",
        parentReplyId: String? = nil
    ) {
        self.replyId = replyId
        self.postId = postId
        self.responderId = responderId
        self.responderName = responderName
        self.body = body
        self.createdAt = createdAt
        self.responderImageURL = responderImageURL
        self.responderRole = responderRole
        self.responderLocation = responderLocation
        self.parentReplyId = parentReplyId
    }
}

// MARK: - Post details: original request + every available reply

struct RequestPostDetailsView: View {
    let post: Post
    let description: String
    let initialReplies: [RequestPostReply]
    let onLoadReplies: ((String) async throws -> [RequestPostReply])?
    let onAction: ((RequestPostAction) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var loadedReplies: [RequestPostReply]
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var newestFirst = false
    @State private var showsRespondSheet = false

    private let ink = Color(red: 0.15, green: 0.23, blue: 0.33)
    private let muted = Color(red: 0.40, green: 0.49, blue: 0.57)
    private let accent = Color(red: 0.07, green: 0.61, blue: 0.42)
    private let pageBackground = Color(red: 0.929, green: 0.965, blue: 0.976)

    init(
        post: Post,
        description: String,
        initialReplies: [RequestPostReply] = [],
        onLoadReplies: ((String) async throws -> [RequestPostReply])? = nil,
        onAction: ((RequestPostAction) -> Void)? = nil
    ) {
        self.post = post
        self.description = description
        self.initialReplies = initialReplies
        self.onLoadReplies = onLoadReplies
        self.onAction = onAction
        _loadedReplies = State(initialValue: initialReplies.filter { $0.postId == post.postId })
    }

    private var sortedReplies: [RequestPostReply] {
        loadedReplies.sorted { lhs, rhs in
            let leftDate = RequestDetailsDate.date(from: lhs.createdAt) ?? .distantPast
            let rightDate = RequestDetailsDate.date(from: rhs.createdAt) ?? .distantPast
            if leftDate == rightDate {
                return lhs.replyId < rhs.replyId
            }
            return newestFirst ? leftDate > rightDate : leftDate < rightDate
        }
    }

    private var firstName: String {
        post.posterName.split(separator: " ").first.map(String.init) ?? "this member"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                originalRequest
                repliesSection
            }
            .frame(maxWidth: 670)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 30)
        }
        .background(pageBackground.ignoresSafeArea())
        .navigationTitle("Request Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
                    .fontWeight(.semibold)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            replyFooter
        }
        .task(id: post.postId) {
            if onLoadReplies != nil {
                await refreshReplies()
            } else {
                loadedReplies = initialReplies.filter { $0.postId == post.postId }
            }
        }
        .sheet(isPresented: $showsRespondSheet) {
            NavigationStack {
                RequestDetailsRespondSheet(
                    requesterName: firstName,
                    isPreview: onAction == nil
                ) { response, media in
                    onAction?(.respondMedia(postId: post.postId, text: response, media: media))
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: Original request

    private var originalRequest: some View {
        VStack(alignment: .leading, spacing: 15) {
            Label("COMMUNITY REQUEST", systemImage: "person.2.fill")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(0.7)
                .foregroundStyle(accent)

            Text(post.subject)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(ink)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 11) {
                RequestDetailsAvatar(
                    urlString: post.posterImageURL,
                    name: post.posterName,
                    size: 46
                )
                VStack(alignment: .leading, spacing: 3) {
                    Text(post.posterName.isEmpty ? "Goaliath member" : post.posterName)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(ink)
                    Text([post.posterRole.isEmpty ? "Member" : post.posterRole,
                          post.posterLocation].filter { !$0.isEmpty }.joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(muted)
                }
                Spacer(minLength: 0)
            }

            if !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(description)
                    .font(.system(size: 15))
                    .foregroundStyle(ink.opacity(0.88))
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 8) {
                RequestDetailsDateBlock(icon: "calendar.badge.plus", caption: "ADDED", dateText: post.createdAt)
                RequestDetailsDateBlock(icon: "hourglass", caption: "EXPIRES", dateText: post.expiresAt)
            }

            RequestDetailsMediaView(post: post)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 22))
    }

    // MARK: Community replies

    private var repliesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Community Replies")
                        .font(.system(size: 21, weight: .bold, design: .rounded))
                        .foregroundStyle(ink)

                    if isLoading {
                        Text("Loading replies…")
                            .font(.caption)
                            .foregroundStyle(muted)
                    } else {
                        let count = loadedReplies.count
                        let expected = max(post.postResponseCount, count)
                        Text(expected > count
                            ? "Showing \(count) of \(expected) replies"
                            : "\(count) \(count == 1 ? "reply" : "replies")")
                            .font(.caption)
                            .foregroundStyle(muted)
                    }
                }
                Spacer(minLength: 8)
                if !loadedReplies.isEmpty {
                    Menu {
                        Button("Oldest first", systemImage: "arrow.up") { newestFirst = false }
                        Button("Newest first", systemImage: "arrow.down") { newestFirst = true }
                    } label: {
                        Label(newestFirst ? "Newest" : "Oldest", systemImage: "arrow.up.arrow.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(accent)
                    }
                }
            }
            .padding(.horizontal, 3)

            if isLoading && loadedReplies.isEmpty {
                HStack(spacing: 12) {
                    ProgressView()
                    Text("Fetching the conversation…")
                        .font(.subheadline)
                        .foregroundStyle(muted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 42)
            }

            if let loadError {
                VStack(alignment: .leading, spacing: 11) {
                    Label("Couldn't load replies", systemImage: "wifi.exclamationmark")
                        .font(.headline)
                        .foregroundStyle(ink)
                    Text(loadError)
                        .font(.subheadline)
                        .foregroundStyle(muted)
                    Button("Try Again") {
                        _Concurrency.Task { await refreshReplies() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(accent)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white, in: RoundedRectangle(cornerRadius: 18))
            }

            if !loadedReplies.isEmpty {
                LazyVStack(spacing: 11) {
                    ForEach(sortedReplies) { reply in
                        RequestPostReplyRow(
                            reply: reply,
                            originalPosterId: post.posterId,
                            parentName: parentName(for: reply)
                        )
                    }
                }
            } else if !isLoading && loadError == nil {
                emptyReplies
            }

            // A count alone doesn't provide reply text, names, or timestamps.
            if onLoadReplies == nil && post.postResponseCount > loadedReplies.count {
                Label("Additional replies need to be loaded from the app's reply service.",
                      systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(muted)
                    .padding(.horizontal, 4)
            }
        }
    }

    private var emptyReplies: some View {
        VStack(spacing: 11) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(accent)
            Text(post.postResponseCount == 0 ? "Start the conversation" : "Replies aren't available yet")
                .font(.headline)
                .foregroundStyle(ink)
            Text(post.postResponseCount == 0
                 ? "Be the first to offer help or share a useful connection."
                 : "The post has replies, but their content hasn't been supplied to this view.")
                .font(.subheadline)
                .foregroundStyle(muted)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(.white, in: RoundedRectangle(cornerRadius: 18))
    }

    private var replyFooter: some View {
        Button {
            showsRespondSheet = true
        } label: {
            Text("Respond to \(firstName)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    LinearGradient(colors: [accent, accent.opacity(0.84)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(.regularMaterial)
    }

    private func parentName(for reply: RequestPostReply) -> String? {
        guard let parentId = reply.parentReplyId,
              let parent = loadedReplies.first(where: { $0.replyId == parentId }) else {
            return nil
        }
        return parent.responderName
    }

    @MainActor
    private func refreshReplies() async {
        guard let onLoadReplies else { return }
        isLoading = true
        loadError = nil
        defer { isLoading = false }

        do {
            let fetched = try await onLoadReplies(post.postId)
            guard !_Concurrency.Task<Never, Never>.isCancelled else { return }
            loadedReplies = fetched.filter { $0.postId == post.postId }
        } catch {
            guard !_Concurrency.Task<Never, Never>.isCancelled else { return }
            loadError = error.localizedDescription
        }
    }
}

// MARK: - One reply (separate from the request card)

private struct RequestPostReplyRow: View {
    let reply: RequestPostReply
    let originalPosterId: String
    let parentName: String?

    private let ink = Color(red: 0.15, green: 0.23, blue: 0.33)
    private let muted = Color(red: 0.40, green: 0.49, blue: 0.57)
    private let accent = Color(red: 0.07, green: 0.61, blue: 0.42)

    private var isOriginalPoster: Bool {
        !originalPosterId.isEmpty && reply.responderId == originalPosterId
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RequestDetailsAvatar(
                urlString: reply.responderImageURL,
                name: reply.responderName,
                size: 42
            )

            VStack(alignment: .leading, spacing: 9) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(reply.responderName.isEmpty ? "Goaliath member" : reply.responderName)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(ink)

                    if isOriginalPoster {
                        Text("AUTHOR")
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundStyle(accent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(accent.opacity(0.10), in: Capsule())
                    }
                    Spacer(minLength: 0)
                }

                Text([reply.responderRole.isEmpty ? "Member" : reply.responderRole,
                      reply.responderLocation].filter { !$0.isEmpty }.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(muted)

                if let parentName {
                    Text("Replying to \(parentName)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(accent)
                } else if reply.parentReplyId != nil {
                    Text("Reply to a previous response")
                        .font(.caption)
                        .foregroundStyle(accent)
                }

                if !reply.body.isEmpty {
                    Text(reply.body)
                        .font(.system(size: 14))
                        .foregroundStyle(ink.opacity(0.92))
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                }
                if !(reply.image_urls ?? []).isEmpty || !(reply.video_urls ?? []).isEmpty || !(reply.gif_urls ?? []).isEmpty {
                    ScrollView(.horizontal) {
                        HStack(spacing: 8) {
                            ForEach(reply.image_urls ?? [], id: \.self) { source in
                                AsyncImage(url: RequestDetailsMedia.validURL(source)) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: { RequestDetailsMediaPlaceholder(symbol: "photo") }
                                .frame(width: 180, height: 130).clipped().clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            ForEach(reply.video_urls ?? [], id: \.self) { source in
                                RequestDetailsVideoTile(urlString: source)
                                    .frame(width: 180, height: 130).clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            ForEach(reply.gif_urls ?? [], id: \.self) { source in
                                RequestDetailsGIFTile(urlString: source)
                                    .frame(width: 180, height: 130).clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }.scrollIndicators(.hidden)
                }

                Label(RequestDetailsDate.display(reply.createdAt), systemImage: "clock")
                    .font(.caption2)
                    .foregroundStyle(muted)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Color.black.opacity(0.035), lineWidth: 1)
        }
    }
}


// MARK: - Self-contained helpers (no access to card-private types required)

private struct RequestDetailsAvatar: View {
    let urlString: String
    let name: String
    var size: CGFloat = 50

    var body: some View {
        AsyncImage(url: RequestDetailsMedia.validURL(urlString)) { phase in
            if case let .success(image) = phase {
                image.resizable().scaledToFill()
            } else {
                ZStack {
                    Color(red: 0.84, green: 0.92, blue: 0.97)
                    Text(String(name.prefix(1)).uppercased())
                        .font(.system(size: size * 0.42, weight: .bold))
                        .foregroundStyle(.blue)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityLabel("\(name) profile picture")
    }
}

private struct RequestDetailsDateBlock: View {
    let icon: String
    let caption: String
    let dateText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Label(caption, systemImage: icon)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)
            Text(RequestDetailsDate.display(dateText))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(red: 0.15, green: 0.23, blue: 0.33))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(red: 0.95, green: 0.97, blue: 0.99), in: RoundedRectangle(cornerRadius: 12))
    }
}

private enum RequestDetailsDate {
    static func date(from value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: value) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }

    static func display(_ value: String) -> String {
        if let date = date(from: value) {
            return date.formatted(.dateTime.month(.abbreviated).day().year().hour().minute())
        }
        return value.isEmpty ? "Not specified" : value
    }
}



private enum RequestDetailsMedia: Hashable, Identifiable {
    case image(String)
    case video(String)
    case gif(String)

    var id: String {
        switch self {
        case .image(let url): return "image:" + url
        case .video(let url): return "video:" + url
        case .gif(let url): return "gif:" + url
        }
    }

    static func validURL(_ value: String) -> URL? {
        guard let url = URL(string: value),
              let scheme = url.scheme?.lowercased(),
              ["https", "http"].contains(scheme),
              url.host != nil else { return nil }
        return url
    }
}

private struct RequestDetailsMediaView: View {
    let post: Post

    private var media: [RequestDetailsMedia] {
        var result: [RequestDetailsMedia] = []
        var seen = Set<String>()

        func append(_ item: RequestDetailsMedia, urlString: String) {
            guard RequestDetailsMedia.validURL(urlString) != nil else { return }
            guard seen.insert(urlString).inserted else { return }
            result.append(item)
        }

        let mainURL = post.postMainMediaURL
        switch post.postMainMediaType.lowercased() {
        case "image", "photo": append(.image(mainURL), urlString: mainURL)
        case "video": append(.video(mainURL), urlString: mainURL)
        case "gif": append(.gif(mainURL), urlString: mainURL)
        default: break
        }

        for url in post.postImageURLs { append(.image(url), urlString: url) }
        for url in post.postVideoURLs { append(.video(url), urlString: url) }
        for url in post.postGIFMedia.values.sorted() { append(.gif(url), urlString: url) }
        return result
    }

    var body: some View {
        if !media.isEmpty {
            VStack(alignment: .leading, spacing: 9) {
                ScrollView(.horizontal) {
                    HStack(spacing: 10) {
                        ForEach(media) { item in
                            Group {
                                switch item {
                                case .image(let url):
                                    AsyncImage(url: RequestDetailsMedia.validURL(url)) { phase in
                                        if case let .success(image) = phase {
                                            image.resizable().scaledToFill()
                                        } else {
                                            RequestDetailsMediaPlaceholder(symbol: "photo")
                                        }
                                    }
                                case .video(let url):
                                    RequestDetailsVideoTile(urlString: url)
                                case .gif(let url):
                                    RequestDetailsGIFTile(urlString: url)
                                }
                            }
                            .frame(width: 260, height: 188)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
    }
}

private struct RequestDetailsMediaPlaceholder: View {
    let symbol: String
    var body: some View {
        Rectangle()
            .fill(Color(red: 0.93, green: 0.97, blue: 0.98))
            .overlay {
                Image(systemName: symbol)
                    .font(.system(size: 32))
                    .foregroundStyle(.secondary)
            }
    }
}

private struct RequestDetailsVideoTile: View {
    let urlString: String
    @State private var player: AVPlayer?

    var body: some View {
        Group {
            if let player {
                VideoPlayer(player: player)
            } else {
                RequestDetailsMediaPlaceholder(symbol: "play.rectangle.fill")
            }
        }
        .onAppear {
            if player == nil, let url = RequestDetailsMedia.validURL(urlString) {
                player = AVPlayer(url: url)
            }
        }
        .onDisappear { player?.pause() }
    }
}

private struct RequestDetailsGIFTile: UIViewRepresentable {
    let urlString: String

    func makeUIView(context: Context) -> WKWebView {
        let view = WKWebView(frame: .zero)
        view.isOpaque = false
        view.backgroundColor = UIColor.systemGray6
        view.scrollView.isScrollEnabled = false
        return view
    }

    func updateUIView(_ view: WKWebView, context: Context) {
        guard let url = RequestDetailsMedia.validURL(urlString) else { return }
        if view.url != url { view.load(URLRequest(url: url)) }
    }
}



private struct RequestDetailsComposerContent: View {
    let prompt: String
    let placeholder: String
    let submitTitle: String
    let isPreview: Bool
    let onSubmit: (String, GoaliathMediaLinks) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draft = ""
    @State private var images = ""
    @State private var videos = ""
    @State private var gifs = ""

    private var cleanedDraft: String {
        draft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func links(_ text: String) -> [String] {
        text.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    }

    var body: some View {
        Form {
            Section {
                Text(prompt)
                    .font(.subheadline)
                TextEditor(text: $draft)
                    .frame(minHeight: 125)
                    .accessibilityLabel(placeholder)
            } header: {
                Text(placeholder)
            }
            Section("Attachments") {
                TextField("Image HTTPS URLs (comma-separated)", text: $images)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
                TextField("Video HTTPS URLs (comma-separated)", text: $videos)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
                TextField("GIF HTTPS URLs (comma-separated)", text: $gifs)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
            }
            if isPreview {
                Section {
                    Label("Design preview only. No message will be sent.", systemImage: "info.circle")
                        .font(.caption)
                }
            }
            Section {
                Button(isPreview ? "Close Preview" : submitTitle) {
                    if !isPreview { onSubmit(cleanedDraft, GoaliathMediaLinks(image_urls: Self.links(images), video_urls: Self.links(videos), gif_urls: Self.links(gifs))) }
                    dismiss()
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .disabled(!isPreview && cleanedDraft.isEmpty && images.isEmpty && videos.isEmpty && gifs.isEmpty)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Cancel") { dismiss() }
            }
        }
    }
}

private struct RequestDetailsRespondSheet: View {
    let requesterName: String
    let isPreview: Bool
    let onSubmit: (String, GoaliathMediaLinks) -> Void

    var body: some View {
        RequestDetailsComposerContent(
            prompt: "Tell \(requesterName) how you can help. You can offer advice, an introduction, or a useful resource.",
            placeholder: "Your response",
            submitTitle: "Send Response",
            isPreview: isPreview,
            onSubmit: onSubmit
        )
        .navigationTitle("Respond to Request")
        .navigationBarTitleDisplayMode(.inline)
    }
}
