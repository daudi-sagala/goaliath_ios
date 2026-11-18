import SwiftUI

// MARK: - Tip-specific actions (the app/service processes them)

enum TipPostAction {
    case respond(postId: String, text: String)
    case addToSchedule(postId: String, at: Date, target: TipScheduleTarget)
    case ignore(postId: String)
    case report(postId: String, reason: String, notes: String)
}

/// The selected item to schedule. An entire tip can be scheduled as a reminder;
/// linked items, where present, can be chosen instead. No backend assumptions.
struct TipScheduleTarget: Identifiable, Hashable, Codable {
    enum Kind: String, Codable { case tip, meal, workout, activity, task }
    let kind: Kind
    let contentId: String
    let title: String

    var id: String { "\(kind.rawValue):\(contentId)" }
}

private enum TipPostDestination: String, Identifiable {
    case respond, schedule, ignore, report, replies
    var id: String { rawValue }
}

// MARK: - Dedicated tip card

struct TipPostCardView: View {
    let post: Post
    let description: String
    var replies: [RequestPostReply] = []
    var onLoadReplies: ((String) async throws -> [RequestPostReply])? = nil
    var onAction: ((TipPostAction) -> Void)? = nil

    @State private var destination: TipPostDestination?

    private let ink = GoaliathSocialPalette.ink
    private let muted = GoaliathSocialPalette.muted
    private let accent = GoaliathSocialPalette.tip

    private var firstName: String {
        post.posterName.split(separator: " ").first.map(String.init) ?? "A member"
    }

    private var isExpired: Bool {
        guard let date = GoaliathSocialDate.parse(post.expiresAt) else { return false }
        return date < Date()
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
                Text(post.subject.isEmpty ? "A useful idea" : post.subject)
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
            HStack(alignment: .top, spacing: 8) {
                GoaliathSocialDateCell(caption: "SHARED", text: post.createdAt)
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
                        title: "Respond to Tip",
                        prompt: "Tell \(firstName) what you found helpful, share a follow-up, or ask a thoughtful question.",
                        placeholder: "Your response",
                        submitTitle: "Send Response",
                        isPreview: onAction == nil
                    ) { text in
                        onAction?(.respond(postId: post.postId, text: text))
                    }
                case .schedule:
                    TipAddToScheduleSheet(post: post, isPreview: onAction == nil) { date, target in
                        onAction?(.addToSchedule(postId: post.postId, at: date, target: target))
                    }
                case .ignore:
                    GoaliathSocialConfirmSheet(
                        title: "Not useful right now?",
                        explanation: "Move past this tip. You can keep exploring other ideas from the community.",
                        confirmTitle: "Ignore Tip",
                        color: GoaliathSocialPalette.neutral,
                        isPreview: onAction == nil
                    ) {
                        onAction?(.ignore(postId: post.postId))
                    }
                case .report:
                    GoaliathSocialReportSheet(contentKind: "Tip", isPreview: onAction == nil) { reason, notes in
                        onAction?(.report(postId: post.postId, reason: reason, notes: notes))
                    }
                case .replies:
                    TipPostDetailsView(
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
            HStack {
                Text("COMMUNITY TIP")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(accent)
                Spacer()
                if isExpired {
                    Text("EXPIRED")
                        .font(.caption2.weight(.heavy))
                        .foregroundStyle(GoaliathSocialPalette.danger)
                }
            }
            Text("\(firstName) has an idea for you")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(ink)
                .fixedSize(horizontal: false, vertical: true)
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.orange)
                    .padding(.top, 2)
                Text("Great ideas are better when put into action. Explore this tip, make it part of your day, or join the discussion.")
                    .font(.subheadline)
                    .foregroundStyle(ink.opacity(0.87))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.orange.opacity(0.16), in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private var buttons: some View {
        VStack(spacing: 11) {
            HStack(spacing: 11) {
                GoaliathSocialActionButton(title: "Respond to Tip", color: accent) {
                    destination = .respond
                }
                GoaliathSocialActionButton(title: "Add to Schedule", color: GoaliathSocialPalette.green) {
                    destination = .schedule
                }
            }
            HStack(spacing: 11) {
                GoaliathSocialActionButton(title: "Ignore Tip", color: GoaliathSocialPalette.neutral, style: .secondary) {
                    destination = .ignore
                }
                GoaliathSocialActionButton(title: "Report Abuse", color: GoaliathSocialPalette.danger, style: .secondary) {
                    destination = .report
                }
            }
        }
    }
}

// MARK: - Tip scheduling is intentionally not a server mutation.

private struct TipAddToScheduleSheet: View {
    let post: Post
    let isPreview: Bool
    let onSchedule: (Date, TipScheduleTarget) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var date = Date().addingTimeInterval(3600)
    @State private var selectedTargetID: String = ""

    private var availableTargets: [TipScheduleTarget] {
        var result = [TipScheduleTarget(kind: .tip, contentId: post.postId, title: "Tip reminder")]
        result += post.postSelectedMealIds.enumerated().map {
            TipScheduleTarget(kind: .meal, contentId: $0.element, title: "Meal idea \($0.offset + 1)")
        }
        result += post.postWorkoutIds.enumerated().map {
            TipScheduleTarget(kind: .workout, contentId: $0.element, title: "Workout \($0.offset + 1)")
        }
        result += post.postActivityIds.enumerated().map {
            TipScheduleTarget(kind: .activity, contentId: $0.element, title: "Activity \($0.offset + 1)")
        }
        result += post.postTaskIds.enumerated().map {
            TipScheduleTarget(kind: .task, contentId: $0.element, title: "Task \($0.offset + 1)")
        }
        return result
    }

    var body: some View {
        Form {
            Section {
                Text(post.subject.isEmpty ? "Plan this tip" : post.subject)
                    .font(.headline)
                Text("Choose when to revisit this tip or an item linked to it.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Section("Add") {
                Picker("Item", selection: $selectedTargetID) {
                    ForEach(availableTargets) { target in
                        Text(target.title).tag(target.id)
                    }
                }
            }
            Section("When") {
                DatePicker("Date & time", selection: $date, in: Date()...,
                           displayedComponents: [.date, .hourAndMinute])
            }
            if isPreview {
                Section {
                    Label("Preview only — your schedule will not change.", systemImage: "info.circle")
                        .font(.caption)
                }
            }
            Section {
                Button(isPreview ? "Close Preview" : "Add to Schedule") {
                    if !isPreview, let chosen = availableTargets.first(where: { $0.id == selectedTargetID }) {
                        onSchedule(date, chosen)
                    }
                    dismiss()
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            if selectedTargetID.isEmpty {
                selectedTargetID = availableTargets[0].id
            }
        }
        .navigationTitle("Add to Schedule")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Cancel") { dismiss() }
            }
        }
    }
}
