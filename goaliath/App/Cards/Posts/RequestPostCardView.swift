import SwiftUI
import AVKit
import WebKit

// MARK: - Actions (a parent view or networking layer handles these)

enum RequestPostAction {
    case respond(postId: String, text: String)
    case askForDetails(postId: String, question: String)
    case skip(postId: String)
    case report(postId: String, reason: String, notes: String)
}

private enum RequestPostDestination: String, Identifiable {
    case respond, askForDetails, skip, report, replies
    var id: String { rawValue }
}

// MARK: - Request card (the only completed subtype in this iteration)

struct RequestPostCardView: View {
    let post: Post
    let description: String
    /// Optional reply records already held by the parent view.
    let replies: [RequestPostReply]

    /// Optional async provider which returns the full reply list for a post ID.
    /// Your networking layer owns fetching and authorization.
    let onLoadReplies: ((String) async throws -> [RequestPostReply])?
    var onAction: ((RequestPostAction) -> Void)?

    @State private var destination: RequestPostDestination?

    init(
        post: Post,
        description: String,
        replies: [RequestPostReply] = [],
        onLoadReplies: ((String) async throws -> [RequestPostReply])? = nil,
        onAction: ((RequestPostAction) -> Void)? = nil
    ) {
        self.post = post
        self.description = description
        self.replies = replies
        self.onLoadReplies = onLoadReplies
        self.onAction = onAction
    }

    private let ink = Color(red: 0.15, green: 0.23, blue: 0.33)
    private let muted = Color(red: 0.40, green: 0.49, blue: 0.57)
    private let green = Color(red: 0.07, green: 0.61, blue: 0.42)

    private var firstName: String {
        post.posterName.split(separator: " ").first.map(String.init) ?? "Someone"
    }

    private var isExpired: Bool {
        guard let expiry = RequestPostDate.date(from: post.expiresAt) else { return false }
        return expiry < Date()
    }

    private var hasDescription: Bool {
        !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 17) {
            header
            authorRow
            requestContent
            timeline
            RequestPostMediaView(post: post)
            replySummary
            actionButtons
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(Color.black.opacity(0.04), lineWidth: 1)
        }
        .sheet(item: $destination) { selected in
            NavigationStack {
                switch selected {
                case .respond:
                    RespondToRequestSheet(
                        requesterName: firstName,
                        isPreview: onAction == nil
                    ) { reply in
                        onAction?(.respond(postId: post.postId, text: reply))
                    }
                case .askForDetails:
                    AskRequestDetailsSheet(
                        requesterName: firstName,
                        isPreview: onAction == nil
                    ) { question in
                        onAction?(.askForDetails(postId: post.postId, question: question))
                    }
                case .skip:
                    SkipRequestSheet(isPreview: onAction == nil) {
                        onAction?(.skip(postId: post.postId))
                    }
                case .report:
                    ReportRequestSheet(isPreview: onAction == nil) { reason, notes in
                        onAction?(.report(postId: post.postId, reason: reason, notes: notes))
                    }
                case .replies:
                    RequestPostDetailsView(
                        post: post,
                        description: description,
                        initialReplies: replies,
                        onLoadReplies: onLoadReplies,
                        onAction: onAction
                    )
                }
            }
            .presentationDetents(selected == .replies ? [.large] : [.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("NEW REQUEST", systemImage: "person.2.fill")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(green)
                Spacer(minLength: 6)
                if isExpired {
                    Text("EXPIRED")
                        .font(.caption2.weight(.heavy))
                        .foregroundStyle(.red)
                }
            }

            Text("\(firstName) could use your help")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(ink)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "star.fill")
                    .foregroundStyle(.orange)
                    .padding(.top, 2)
                Text("Your knowledge or connections could make a difference. Helpful responses may earn Goaliath tokens.")
                    .font(.subheadline)
                    .foregroundStyle(ink.opacity(0.87))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.orange.opacity(0.2), in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private var authorRow: some View {
        HStack(spacing: 12) {
            RequestAuthorAvatar(urlString: post.posterImageURL, name: post.posterName)
            VStack(alignment: .leading, spacing: 4) {
                Text(post.posterName.isEmpty ? "Goaliath member" : post.posterName)
                    .font(.headline)
                    .foregroundStyle(ink)
                let role = post.posterRole.isEmpty ? "Member" : post.posterRole
                Text([role, post.posterLocation].filter { !$0.isEmpty }.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(muted)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
    }

    private var requestContent: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(post.subject)
                .font(.system(size: 21, weight: .bold, design: .rounded))
                .foregroundStyle(ink)
                .fixedSize(horizontal: false, vertical: true)
            if hasDescription {
                Text(description)
                    .font(.system(size: 15))
                    .foregroundStyle(ink.opacity(0.86))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var timeline: some View {
        HStack(alignment: .top, spacing: 8) {
            RequestDateBlock(icon: "calendar.badge.plus", caption: "ADDED", dateText: post.createdAt)
            RequestDateBlock(icon: "hourglass", caption: "EXPIRES", dateText: post.expiresAt)
        }
    }

    private var replySummary: some View {
        Button {
            destination = .replies
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(green)

                VStack(alignment: .leading, spacing: 3) {
                    Text("\(post.postResponseCount) \(post.postResponseCount == 1 ? "reply" : "replies")")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(ink)
                    Text("See the community conversation")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(muted)
                }

                Spacer(minLength: 4)

                if !post.responderImageUrls.isEmpty {
                    HStack(spacing: -9) {
                        ForEach(Array(post.responderImageUrls.prefix(3).enumerated()), id: \.offset) { _, url in
                            RequestAuthorAvatar(urlString: url, name: "Member", size: 28)
                                .overlay(Circle().stroke(.white, lineWidth: 2))
                        }
                    }
                    .accessibilityHidden(true)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(green)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(Color(red: 0.94, green: 0.98, blue: 0.96),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(green.opacity(0.13), lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(RequestPostPressStyle())
        .accessibilityLabel("View all replies to \(post.subject)")
        .accessibilityHint("Opens request details and the community reply list")
    }

    private var actionButtons: some View {
        VStack(spacing: 11) {
            HStack(spacing: 11) {
                RequestActionButton(
                    title: "Respond Now", color: green, emphasis: .solid
                ) { destination = .respond }

                RequestActionButton(
                    title: "Ask for Details", color: Color(red: 0.14, green: 0.43, blue: 0.86),
                    emphasis: .solid
                ) { destination = .askForDetails }
            }

            HStack(spacing: 11) {
                RequestActionButton(
                    title: "Skip Request", color: Color(red: 0.35, green: 0.40, blue: 0.65),
                    emphasis: .soft
                ) { destination = .skip }

                RequestActionButton(
                    title: "Report Abuse", color: Color(red: 0.77, green: 0.22, blue: 0.32),
                    emphasis: .soft
                ) { destination = .report }
            }
        }
    }

}

// MARK: - Reusable request-only UI components

struct RequestAuthorAvatar: View {
    let urlString: String
    let name: String
    var size: CGFloat = 50

    var body: some View {
        AsyncImage(url: RequestPostMedia.validURL(urlString)) { phase in
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

struct RequestDateBlock: View {
    let icon: String
    let caption: String
    let dateText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Label(caption, systemImage: icon)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)
            Text(RequestPostDate.display(dateText))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(red: 0.15, green: 0.23, blue: 0.33))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(red: 0.95, green: 0.97, blue: 0.99), in: RoundedRectangle(cornerRadius: 12))
    }
}

enum RequestPostDate {
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

private struct RequestActionButton: View {
    enum Emphasis { case solid, soft }

    let title: String
    let color: Color
    let emphasis: Emphasis
    let action: () -> Void

    private var cornerRadius: CGFloat { 17 }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .tracking(0.1)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .foregroundStyle(emphasis == .solid ? Color.white : color)
                .frame(maxWidth: .infinity)
                .frame(minHeight: emphasis == .solid ? 62 : 54)
                .padding(.horizontal, 8)
                .background {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            emphasis == .solid
                            ? LinearGradient(colors: [color, color.opacity(0.84)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [color.opacity(0.12), color.opacity(0.08)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                }
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(color.opacity(emphasis == .solid ? 0.08 : 0.18), lineWidth: 1)
                }
                .shadow(color: color.opacity(emphasis == .solid ? 0.23 : 0.05),
                        radius: emphasis == .solid ? 9 : 3,
                        x: 0, y: emphasis == .solid ? 5 : 2)
                .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
        .buttonStyle(RequestPostPressStyle())
        .accessibilityLabel(title)
    }
}

/// Minimal, tactile scale on touch-down without changing each button's layout.
private struct RequestPostPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .opacity(configuration.isPressed ? 0.93 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

// MARK: - Images, videos and GIFs

private enum RequestPostMedia: Hashable, Identifiable {
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

struct RequestPostMediaView: View {
    let post: Post

    private var media: [RequestPostMedia] {
        var result: [RequestPostMedia] = []
        var seen = Set<String>()

        func append(_ item: RequestPostMedia, urlString: String) {
            guard RequestPostMedia.validURL(urlString) != nil else { return }
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
                                    AsyncImage(url: RequestPostMedia.validURL(url)) { phase in
                                        if case let .success(image) = phase {
                                            image.resizable().scaledToFill()
                                        } else {
                                            RequestMediaPlaceholder(symbol: "photo")
                                        }
                                    }
                                case .video(let url):
                                    RequestVideoTile(urlString: url)
                                case .gif(let url):
                                    RequestGIFTile(urlString: url)
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

private struct RequestMediaPlaceholder: View {
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

private struct RequestVideoTile: View {
    let urlString: String
    @State private var player: AVPlayer?

    var body: some View {
        Group {
            if let player {
                VideoPlayer(player: player)
            } else {
                RequestMediaPlaceholder(symbol: "play.rectangle.fill")
            }
        }
        .onAppear {
            if player == nil, let url = RequestPostMedia.validURL(urlString) {
                player = AVPlayer(url: url)
            }
        }
        .onDisappear { player?.pause() }
    }
}

private struct RequestGIFTile: UIViewRepresentable {
    let urlString: String

    func makeUIView(context: Context) -> WKWebView {
        let view = WKWebView(frame: .zero)
        view.isOpaque = false
        view.backgroundColor = UIColor.systemGray6
        view.scrollView.isScrollEnabled = false
        return view
    }

    func updateUIView(_ view: WKWebView, context: Context) {
        guard let url = RequestPostMedia.validURL(urlString) else { return }
        if view.url != url { view.load(URLRequest(url: url)) }
    }
}

// MARK: - Action-specific sheets

private struct RequestComposerContent: View {
    let prompt: String
    let placeholder: String
    let submitTitle: String
    let isPreview: Bool
    let onSubmit: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draft = ""

    private var cleanedDraft: String {
        draft.trimmingCharacters(in: .whitespacesAndNewlines)
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
            if isPreview {
                Section {
                    Label("Design preview only. No message will be sent.", systemImage: "info.circle")
                        .font(.caption)
                }
            }
            Section {
                Button(isPreview ? "Close Preview" : submitTitle) {
                    if !isPreview { onSubmit(cleanedDraft) }
                    dismiss()
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .disabled(!isPreview && cleanedDraft.isEmpty)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Cancel") { dismiss() }
            }
        }
    }
}

struct RespondToRequestSheet: View {
    let requesterName: String
    let isPreview: Bool
    let onSubmit: (String) -> Void

    var body: some View {
        RequestComposerContent(
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

private struct AskRequestDetailsSheet: View {
    let requesterName: String
    let isPreview: Bool
    let onSubmit: (String) -> Void

    var body: some View {
        RequestComposerContent(
            prompt: "Need more context before offering help? Ask \(requesterName) one clear question.",
            placeholder: "Your question",
            submitTitle: "Ask Question",
            isPreview: isPreview,
            onSubmit: onSubmit
        )
        .navigationTitle("Ask for Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SkipRequestSheet: View {
    let isPreview: Bool
    let onConfirm: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "forward.end.circle.fill")
                .font(.system(size: 52))
                .foregroundStyle(.indigo)
            Text("Not the right request for you?")
                .font(.title3.bold())
            Text("Skip this request to move on to another opportunity to help.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            if isPreview {
                Text("Preview mode — your feed won't change.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Button(isPreview ? "Close Preview" : "Skip Request") {
                if !isPreview { onConfirm() }
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(.indigo)
            Button("Keep Request") { dismiss() }
                .buttonStyle(.bordered)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Skip Request")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ReportRequestSheet: View {
    let isPreview: Bool
    let onSubmit: (String, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var reason = "Spam or misleading"
    @State private var notes = ""

    private let reasons = [
        "Spam or misleading", "Harassment or abuse", "Scam or fraud",
        "Inappropriate content", "Other"
    ]

    var body: some View {
        Form {
            Section("Why are you reporting this request?") {
                Picker("Reason", selection: $reason) {
                    ForEach(reasons, id: \.self) { Text($0) }
                }
                TextField("Additional details (optional)", text: $notes, axis: .vertical)
                    .lineLimit(2...5)
            }
            Section {
                Text("Reports should be reviewed privately by the Goaliath moderation team once reporting is connected.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if isPreview {
                    Text("Preview only — no report will be submitted.")
                        .font(.caption)
                }
                Button(isPreview ? "Close Preview" : "Submit Report") {
                    if !isPreview {
                        onSubmit(reason, notes.trimmingCharacters(in: .whitespacesAndNewlines))
                    }
                    dismiss()
                }
                .font(.headline)
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Report Abuse")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Cancel") { dismiss() }
            }
        }
    }
}

