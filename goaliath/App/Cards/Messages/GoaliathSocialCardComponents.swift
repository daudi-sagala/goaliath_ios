import SwiftUI
import AVKit
import WebKit

// MARK: - Shared *presentation* primitives only.
// Tip, Comment, and Message retain their own named card views and actions.

enum GoaliathSocialPalette {
    static let ink = Color(red: 0.15, green: 0.23, blue: 0.33)
    static let muted = Color(red: 0.40, green: 0.49, blue: 0.57)
    static let canvas = Color(red: 0.929, green: 0.965, blue: 0.976)
    static let tip = Color(red: 0.44, green: 0.31, blue: 0.78)
    static let comment = Color(red: 0.14, green: 0.43, blue: 0.83)
    static let green = Color(red: 0.07, green: 0.61, blue: 0.42)
    static let danger = Color(red: 0.77, green: 0.22, blue: 0.32)
    static let neutral = Color(red: 0.35, green: 0.40, blue: 0.65)
}

struct GoaliathSocialAvatar: View {
    let urlString: String
    let name: String
    var size: CGFloat = 50

    var body: some View {
        AsyncImage(url: GoaliathSocialMedia.validURL(urlString)) { phase in
            if case let .success(image) = phase {
                image.resizable().scaledToFill()
            } else {
                ZStack {
                    Color(red: 0.84, green: 0.92, blue: 0.97)
                    Text(String(name.prefix(1)).uppercased())
                        .font(.system(size: size * 0.40, weight: .bold, design: .rounded))
                        .foregroundStyle(GoaliathSocialPalette.comment)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityLabel("\(name.isEmpty ? "Member" : name) profile photo")
    }
}

enum GoaliathSocialDate {
    static func parse(_ text: String) -> Date? {
        let parser = ISO8601DateFormatter()
        parser.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let result = parser.date(from: text) { return result }
        parser.formatOptions = [.withInternetDateTime]
        if let result = parser.date(from: text) { return result }
        parser.formatOptions = [.withFullDate]
        return parser.date(from: text)
    }

    static func display(_ text: String) -> String {
        guard let date = parse(text) else { return text.isEmpty ? "Not specified" : text }
        return date.formatted(.dateTime.month(.abbreviated).day().year().hour().minute())
    }

    static func time(_ text: String) -> String {
        guard let date = parse(text) else { return text.isEmpty ? "" : text }
        return date.formatted(.dateTime.hour().minute())
    }

    static func day(_ text: String) -> String {
        guard let date = parse(text) else { return text.isEmpty ? "Undated" : text }
        return date.formatted(.dateTime.month(.abbreviated).day().year())
    }
}

struct GoaliathSocialDateCell: View {
    let caption: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(caption)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(0.5)
                .foregroundStyle(GoaliathSocialPalette.muted)
            Text(GoaliathSocialDate.display(text))
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(GoaliathSocialPalette.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(GoaliathSocialPalette.canvas.opacity(0.72),
                    in: RoundedRectangle(cornerRadius: 13, style: .continuous))
    }
}

struct GoaliathSocialActionButton: View {
    enum Style { case primary, secondary }

    let title: String
    let color: Color
    var style: Style = .primary
    var isDisabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .multilineTextAlignment(.center)
                .foregroundStyle(style == .primary ? Color.white : color)
                .frame(maxWidth: .infinity)
                .frame(minHeight: style == .primary ? 60 : 52)
                .padding(.horizontal, 7)
                .background {
                    RoundedRectangle(cornerRadius: 17, style: .continuous)
                        .fill(LinearGradient(
                            colors: style == .primary
                                ? [color, color.opacity(0.85)]
                                : [color.opacity(0.14), color.opacity(0.08)],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 17, style: .continuous)
                        .strokeBorder(color.opacity(style == .primary ? 0.10 : 0.20), lineWidth: 1)
                }
                .shadow(color: color.opacity(style == .primary ? 0.20 : 0.04),
                        radius: style == .primary ? 8 : 2, y: style == .primary ? 4 : 1)
                .opacity(isDisabled ? 0.45 : 1)
                .contentShape(RoundedRectangle(cornerRadius: 17))
        }
        .buttonStyle(GoaliathSocialPressStyle())
        .disabled(isDisabled)
        .accessibilityLabel(title)
    }
}

struct GoaliathSocialPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .opacity(configuration.isPressed ? 0.90 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct GoaliathSocialAuthorRow: View {
    let name: String
    let avatarURL: String
    let role: String
    let location: String

    var body: some View {
        HStack(spacing: 12) {
            GoaliathSocialAvatar(urlString: avatarURL, name: name)
            VStack(alignment: .leading, spacing: 4) {
                Text(name.isEmpty ? "Goaliath member" : name)
                    .font(.headline)
                    .foregroundStyle(GoaliathSocialPalette.ink)
                Text([role.isEmpty ? "Member" : role, location]
                    .filter { !$0.isEmpty }.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(GoaliathSocialPalette.muted)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
    }
}

struct GoaliathSocialReplySummary: View {
    let count: Int
    let avatarURLs: [String]
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(tint)
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(count) \(count == 1 ? "reply" : "replies")")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(GoaliathSocialPalette.ink)
                    Text("View the conversation")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(GoaliathSocialPalette.muted)
                }
                Spacer(minLength: 4)
                if !avatarURLs.isEmpty {
                    HStack(spacing: -9) {
                        ForEach(Array(avatarURLs.prefix(3).enumerated()), id: \.offset) { _, url in
                            GoaliathSocialAvatar(urlString: url, name: "Member", size: 28)
                                .overlay(Circle().stroke(.white, lineWidth: 2))
                        }
                    }
                    .accessibilityHidden(true)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(tint)
            }
            .padding(14)
            .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
            .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(GoaliathSocialPressStyle())
        .accessibilityHint("Opens all available replies")
    }
}

// MARK: - Reusable action sheets; never claim a network operation succeeded.

struct GoaliathSocialTextComposer: View {
    let title: String
    let prompt: String
    let placeholder: String
    let submitTitle: String
    let isPreview: Bool
    let onSubmit: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draft = ""
    private var trimmed: String { draft.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        Form {
            Section {
                Text(prompt).font(.subheadline)
                TextEditor(text: $draft)
                    .frame(minHeight: 145)
                    .accessibilityLabel(placeholder)
            } header: {
                Text(placeholder)
            }
            if isPreview {
                Section {
                    Label("Preview only — this message will not be sent.", systemImage: "info.circle")
                        .font(.caption)
                }
            }
            Section {
                Button(isPreview ? "Close Preview" : submitTitle) {
                    if !isPreview { onSubmit(trimmed) }
                    dismiss()
                }
                .disabled(!isPreview && trimmed.isEmpty)
                .frame(maxWidth: .infinity)
                .font(.headline)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Cancel") { dismiss() }
            }
        }
    }
}

struct GoaliathSocialConfirmSheet: View {
    let title: String
    let explanation: String
    let confirmTitle: String
    let color: Color
    let isPreview: Bool
    let onConfirm: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "arrow.right.circle.fill")
                .font(.system(size: 45))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
            Text(explanation)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if isPreview {
                Text("Preview only — nothing will change in your feed.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Button(isPreview ? "Close Preview" : confirmTitle) {
                if !isPreview { onConfirm() }
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(color)
            .controlSize(.large)
            Button("Keep Viewing") { dismiss() }
                .buttonStyle(.bordered)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(confirmTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct GoaliathSocialReportSheet: View {
    let contentKind: String
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
            Section("Why are you reporting this \(contentKind.lowercased())?") {
                Picker("Reason", selection: $reason) {
                    ForEach(reasons, id: \.self) { Text($0) }
                }
                TextField("Additional details (optional)", text: $notes, axis: .vertical)
                    .lineLimit(2...5)
            }
            Section {
                Text("Reports are private and should be reviewed by Goaliath moderators when reporting is connected.")
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
                .foregroundStyle(GoaliathSocialPalette.danger)
                .font(.headline)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Report Abuse")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Cancel") { dismiss() }
            }
        }
    }
}

// MARK: - Image / video / GIF gallery

private enum GoaliathSocialMedia: Hashable, Identifiable {
    case image(String), video(String), gif(String)

    var id: String {
        switch self {
        case .image(let url): return "image:" + url
        case .video(let url): return "video:" + url
        case .gif(let url): return "gif:" + url
        }
    }

    static func validURL(_ text: String) -> URL? {
        guard let url = URL(string: text),
              let scheme = url.scheme?.lowercased(),
              ["https", "http"].contains(scheme),
              url.host != nil else { return nil }
        return url
    }
}

struct GoaliathSocialMediaGallery: View {
    let post: Post

    private var media: [GoaliathSocialMedia] {
        var items: [GoaliathSocialMedia] = []
        var seen = Set<String>()
        func add(_ media: GoaliathSocialMedia, from url: String) {
            guard GoaliathSocialMedia.validURL(url) != nil,
                  seen.insert(url).inserted else { return }
            items.append(media)
        }

        switch post.postMainMediaType.lowercased() {
        case "image", "photo": add(.image(post.postMainMediaURL), from: post.postMainMediaURL)
        case "video": add(.video(post.postMainMediaURL), from: post.postMainMediaURL)
        case "gif": add(.gif(post.postMainMediaURL), from: post.postMainMediaURL)
        default: break
        }
        for url in post.postImageURLs { add(.image(url), from: url) }
        for url in post.postVideoURLs { add(.video(url), from: url) }
        for url in post.postGIFMedia.values.sorted() { add(.gif(url), from: url) }
        return items
    }

    var body: some View {
        if !media.isEmpty {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 10) {
                    ForEach(media) { item in
                        Group {
                            switch item {
                            case .image(let url):
                                AsyncImage(url: GoaliathSocialMedia.validURL(url)) { phase in
                                    if case let .success(image) = phase {
                                        image.resizable().scaledToFill()
                                    } else {
                                        SocialMediaFallback(symbol: "photo")
                                    }
                                }
                            case .video(let url):
                                GoaliathSocialVideo(urlString: url)
                            case .gif(let url):
                                GoaliathSocialGIF(urlString: url)
                            }
                        }
                        .frame(width: 258, height: 183)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }
}

private struct SocialMediaFallback: View {
    let symbol: String
    var body: some View {
        Rectangle()
            .fill(GoaliathSocialPalette.canvas)
            .overlay {
                Image(systemName: symbol)
                    .font(.system(size: 30))
                    .foregroundStyle(.secondary)
            }
    }
}

private struct GoaliathSocialVideo: View {
    let urlString: String
    @State private var player: AVPlayer?

    var body: some View {
        Group {
            if let player {
                VideoPlayer(player: player)
            } else {
                SocialMediaFallback(symbol: "play.rectangle.fill")
            }
        }
        .onAppear {
            if player == nil, let url = GoaliathSocialMedia.validURL(urlString) {
                player = AVPlayer(url: url)
            }
        }
        .onDisappear { player?.pause() }
    }
}

private struct GoaliathSocialGIF: UIViewRepresentable {
    let urlString: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero)
        webView.isOpaque = false
        webView.backgroundColor = UIColor.systemGray6
        webView.scrollView.isScrollEnabled = false
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let url = GoaliathSocialMedia.validURL(urlString) else { return }
        if webView.url != url { webView.load(URLRequest(url: url)) }
    }
}
