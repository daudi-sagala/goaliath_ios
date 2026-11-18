import SwiftUI

import PhotosUI

import CoreTransferable

import UniformTypeIdentifiers

// MARK: - Models (kept separate from existing CardData / Activity / Task types)

enum TimelineCreationKind: String, CaseIterable, Codable, Sendable, Identifiable {

    case request, goal, meal, place, shopping, connection, learning

    case gift, workout, task, activity, tip

    var id: String { rawValue }

    var title: String {

        switch self {

        case .request: return "Request"

        case .goal: return "Goal"

        case .meal: return "Meal"

        case .place: return "Place to visit"

        case .shopping: return "Shopping"

        case .connection: return "Meet people"

        case .learning: return "Learning"

        case .gift: return "Gift"

        case .workout: return "Workout"

        case .task: return "Task"

        case .activity: return "Activity"

        case .tip: return "Tip"

        }

    }

    var usesExpiration: Bool { self == .request || self == .goal }

    var dateTitle: String {

        switch self {

        case .gift: return "When to send"

        case .request, .goal: return "Start looking"

        default: return "Scheduled For"

        }

    }

}

// Public sharing/audience choice, independent of the timeline item kind.
// No geolocation permission is requested. City/area names are entered manually.
enum TimelineVisibilityScope: String, CaseIterable, Codable, Sendable, Identifiable {
    case privateOnly = "private"
    case connections = "connections"
    case localArea = "local_area"
    case city = "city"
    case everyone = "everyone"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .privateOnly: return "Private"
        case .connections: return "My Network"
        case .localArea: return "Local Area"
        case .city: return "City"
        case .everyone: return "Everyone"
        }
    }

    var subtitle: String {
        switch self {
        case .privateOnly: return "Only you"
        case .connections: return "Your connections"
        case .localArea: return "One neighborhood or area"
        case .city: return "Members in a city"
        case .everyone: return "All Goaliath members"
        }
    }

    var icon: String {
        switch self {
        case .privateOnly: return "lock.shield.fill"
        case .connections: return "person.2.fill"
        case .localArea: return "mappin.circle.fill"
        case .city: return "building.2.fill"
        case .everyone: return "globe.americas.fill"
        }
    }

    var requiresArea: Bool { self == .localArea || self == .city }

    func audienceDescription(area: String?) -> String {
        let trimmed = area?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        switch self {
        case .privateOnly: return "Only you can see this entry."
        case .connections: return "Visible to your Goaliath connections once published."
        case .localArea:
            return trimmed.isEmpty
                ? "Visible to members in your selected local area once published."
                : "Visible to Goaliath members around \(trimmed) once published."
        case .city:
            return trimmed.isEmpty
                ? "Visible to members in your selected city once published."
                : "Visible to Goaliath members in \(trimmed) once published."
        case .everyone: return "Visible to all Goaliath members once published."
        }
    }

    func compactLabel(area: String?) -> String {
        let trimmed = area?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if requiresArea && !trimmed.isEmpty { return "\(title) · \(trimmed)" }
        return title
    }
}

/// Schedule lifecycle. Only the first three states appear in the daily schedule.
/// Skipped/cancelled entries are kept in storage but hidden from this screen.
enum TimelineScheduleStatus: String, Codable, CaseIterable, Sendable, Identifiable {
    case scheduled, confirmed, inProgress, completed, skipped, cancelled

    var id: String { rawValue }

    var title: String { self == .inProgress ? "In progress" : rawValue.capitalized }

    var isShownOnDailySchedule: Bool {
        self == .scheduled || self == .confirmed || self == .inProgress || self == .completed
    }
}

enum TimelineAttachmentKind: String, Codable, Sendable { case image, video }

struct TimelineDraftAttachment: Identifiable, Codable, Sendable {

    let id: UUID

    let kind: TimelineAttachmentKind

    /// File name relative to Application Support/GoaliathTimeline/Media/<draft-id>/.

    let fileName: String

}

struct TimelineCreationDraft: Codable, Identifiable, Sendable {

    let id: UUID

    var kind: TimelineCreationKind

    var title: String

    var description: String

    var startsAt: Date

    var expiresAt: Date?

    var createdAt: Date

    var attachments: [TimelineDraftAttachment]

    // Defaults preserve existing call sites that construct a draft without a scope.
    var visibilityScope: TimelineVisibilityScope = .privateOnly
    var visibilityArea: String? = nil

    /// Explicit lifecycle set by scheduling, confirmation or completion actions.
    /// Nil means this entry is not currently marked as scheduled.
    var scheduleStatus: TimelineScheduleStatus? = nil

    /// Recorded when Begin is tapped; needed for activities without a defined end.
    var actualStartedAt: Date? = nil

    /// Legacy locally saved activity/meal/workout/task entries had no status.
    /// Treat them as planned; other kinds remain off the daily schedule unless
    /// an explicit scheduleStatus is assigned by the owning feature.
    var effectiveScheduleStatus: TimelineScheduleStatus? {
        if let scheduleStatus { return scheduleStatus }
        switch kind {
        case .activity, .meal, .workout, .task:
            return .scheduled
        default:
            return nil
        }
    }

}

// Older entries.json files have no visibility fields. Decoding them defaults to
// Private, instead of failing or silently making historical entries public.
extension TimelineCreationDraft {
    private enum CodingKeys: String, CodingKey {
        case id, kind, title, description, startsAt, expiresAt, createdAt
        case attachments, visibilityScope, visibilityArea, scheduleStatus, actualStartedAt
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(UUID.self, forKey: .id)
        kind = try values.decode(TimelineCreationKind.self, forKey: .kind)
        title = try values.decode(String.self, forKey: .title)
        description = try values.decode(String.self, forKey: .description)
        startsAt = try values.decode(Date.self, forKey: .startsAt)
        expiresAt = try values.decodeIfPresent(Date.self, forKey: .expiresAt)
        createdAt = try values.decode(Date.self, forKey: .createdAt)
        attachments = try values.decode([TimelineDraftAttachment].self, forKey: .attachments)
        visibilityScope = try values.decodeIfPresent(TimelineVisibilityScope.self, forKey: .visibilityScope) ?? .privateOnly
        visibilityArea = try values.decodeIfPresent(String.self, forKey: .visibilityArea)
        scheduleStatus = try values.decodeIfPresent(TimelineScheduleStatus.self, forKey: .scheduleStatus)
        actualStartedAt = try values.decodeIfPresent(Date.self, forKey: .actualStartedAt)
    }
}

/// Optional callback for the backend: the local draft is saved first, then this is invoked.

/// Keeping the local copy means a transient backend error never discards the user's work.

typealias TimelineDraftPublisher = (TimelineCreationDraft) async throws -> Void

// MARK: - Local file-backed store

enum GoaliathTimelineStore {

    private static func folder() throws -> URL {

        let manager = FileManager.default

        let folder = manager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]

            .appendingPathComponent("GoaliathTimeline", isDirectory: true)

        try manager.createDirectory(at: folder, withIntermediateDirectories: true)

        return folder

    }

    static func loadDrafts() throws -> [TimelineCreationDraft] {

        let location = try folder().appendingPathComponent("entries.json")

        guard FileManager.default.fileExists(atPath: location.path) else { return [] }

        return try JSONDecoder().decode([TimelineCreationDraft].self, from: Data(contentsOf: location))

    }

    static func save(

        _ draft: TimelineCreationDraft,

        stagedMedia: [TimelineStagedMedia]

    ) throws -> TimelineCreationDraft {

        let root = try folder()

        let assetFolder = root.appendingPathComponent("Media", isDirectory: true)

            .appendingPathComponent(draft.id.uuidString, isDirectory: true)

        try FileManager.default.createDirectory(at: assetFolder, withIntermediateDirectories: true)

        var stored = draft

        stored.attachments = []

        for item in stagedMedia {

            let fileExt = item.url.pathExtension.isEmpty

                ? (item.kind == .image ? "jpg" : "mov") : item.url.pathExtension

            let name = "\(item.id.uuidString).\(fileExt)"

            let destination = assetFolder.appendingPathComponent(name)

            if FileManager.default.fileExists(atPath: destination.path) {

                try FileManager.default.removeItem(at: destination)

            }

            try FileManager.default.copyItem(at: item.url, to: destination)

            stored.attachments.append(

                TimelineDraftAttachment(id: item.id, kind: item.kind, fileName: name)

            )

        }

        var all = try loadDrafts()

        all.removeAll { $0.id == stored.id }

        all.insert(stored, at: 0)

        let encoded = try JSONEncoder().encode(all)

        try encoded.write(to: root.appendingPathComponent("entries.json"), options: .atomic)
        NotificationCenter.default.post(name: .goaliathTimelineDidChange, object: nil)

        return stored

    }

    /// Update status for an existing device-saved schedule entry. Does not
    /// claim to update a remote authoritative schedule.
    static func updateScheduleStatus(id: UUID, to status: TimelineScheduleStatus) throws {
        var drafts = try loadDrafts()
        guard let index = drafts.firstIndex(where: { $0.id == id }) else {
            throw CocoaError(.fileNoSuchFile)
        }
        drafts[index].scheduleStatus = status
        if status == .inProgress && drafts[index].actualStartedAt == nil {
            drafts[index].actualStartedAt = Date()
        }
        let encoded = try JSONEncoder().encode(drafts)
        try encoded.write(to: try folder().appendingPathComponent("entries.json"), options: .atomic)
        NotificationCenter.default.post(name: .goaliathTimelineDidChange, object: nil)
    }

    static func attachmentURL(_ item: TimelineDraftAttachment, draftID: UUID) throws -> URL {

        try folder().appendingPathComponent("Media", isDirectory: true)

            .appendingPathComponent(draftID.uuidString, isDirectory: true)

            .appendingPathComponent(item.fileName)

    }

}

struct TimelineStagedMedia: Identifiable, Sendable {

    let id: UUID

    let kind: TimelineAttachmentKind

    let url: URL

}

/// PhotosPicker uses FileRepresentation for large movies, avoiding loading video files into RAM.

private struct TimelineImportedMovie: Transferable {

    let fileURL: URL

    static var transferRepresentation: some TransferRepresentation {

        FileRepresentation(contentType: .movie) { movie in

            SentTransferredFile(movie.fileURL)

        } importing: { received in

            let source = received.file

            let ext = source.pathExtension.isEmpty ? "mov" : source.pathExtension

            let destination = FileManager.default.temporaryDirectory

                .appendingPathComponent(UUID().uuidString)

                .appendingPathExtension(ext)

            try FileManager.default.copyItem(at: source, to: destination)

            return TimelineImportedMovie(fileURL: destination)

        }

    }

}

// MARK: - Quick-start suggestion data

private struct TimelinePrompt: Identifiable {

    let id: String

    let title: String

    let icon: String

    let kind: TimelineCreationKind

    let tint: Color

    let pale: Color

    let radius: CGFloat

    let height: CGFloat

    // Optional cached count for a prompt. Live counts supplied by the sheet's
    // promptUsageCounts dictionary take precedence over this value.
    var memberUsageCount: Int? = nil

    static let all: [TimelinePrompt] = [

        .init(id: "request", title: "Make a Request", icon: "hand.raised.fill", kind: .request, tint: .init(red: 0.12, green: 0.55, blue: 0.42), pale: .init(red: 0.83, green: 0.95, blue: 0.89), radius: 34, height: 62),

        .init(id: "hungry", title: "I'm Hungry", icon: "fork.knife", kind: .meal, tint: .init(red: 0.83, green: 0.40, blue: 0.21), pale: .init(red: 1.0, green: 0.91, blue: 0.80), radius: 15, height: 58),

        .init(id: "bar", title: "Find a Bar", icon: "wineglass.fill", kind: .place, tint: .init(red: 0.42, green: 0.31, blue: 0.73), pale: .init(red: 0.92, green: 0.86, blue: 0.98), radius: 26, height: 72),

        .init(id: "furniture", title: "Buy Furniture", icon: "sofa.fill", kind: .shopping, tint: .init(red: 0.33, green: 0.42, blue: 0.65), pale: .init(red: 0.88, green: 0.92, blue: 0.99), radius: 18, height: 62),

        .init(id: "job", title: "Find a Job", icon: "briefcase.fill", kind: .goal, tint: .init(red: 0.10, green: 0.48, blue: 0.67), pale: .init(red: 0.84, green: 0.93, blue: 0.97), radius: 30, height: 66),

        .init(id: "people", title: "Meet New People", icon: "person.2.fill", kind: .connection, tint: .init(red: 0.67, green: 0.28, blue: 0.54), pale: .init(red: 0.98, green: 0.88, blue: 0.94), radius: 22, height: 60),

        .init(id: "language", title: "Learn a Language", icon: "character.book.closed.fill", kind: .learning, tint: .init(red: 0.30, green: 0.45, blue: 0.70), pale: .init(red: 0.86, green: 0.90, blue: 0.99), radius: 34, height: 66),

        .init(id: "gift", title: "Send a Gift", icon: "gift.fill", kind: .gift, tint: .init(red: 0.79, green: 0.36, blue: 0.38), pale: .init(red: 1.00, green: 0.87, blue: 0.86), radius: 16, height: 58),

        .init(id: "workout", title: "Get Moving", icon: "figure.run", kind: .workout, tint: .init(red: 0.16, green: 0.56, blue: 0.42), pale: .init(red: 0.85, green: 0.96, blue: 0.88), radius: 28, height: 72),

        .init(id: "mentor", title: "Find a Mentor", icon: "person.crop.circle.badge.questionmark", kind: .goal, tint: .init(red: 0.43, green: 0.34, blue: 0.68), pale: .init(red: 0.91, green: 0.87, blue: 0.99), radius: 16, height: 60),

        .init(id: "event", title: "Plan an Event", icon: "calendar.badge.plus", kind: .activity, tint: .init(red: 0.75, green: 0.40, blue: 0.24), pale: .init(red: 1.0, green: 0.93, blue: 0.84), radius: 32, height: 68),

        .init(id: "task", title: "Remember Something", icon: "checklist", kind: .task, tint: .init(red: 0.25, green: 0.46, blue: 0.65), pale: .init(red: 0.87, green: 0.93, blue: 0.98), radius: 18, height: 58),

        .init(id: "tip", title: "Share a Tip", icon: "lightbulb.fill", kind: .tip, tint: .init(red: 0.75, green: 0.47, blue: 0.13), pale: .init(red: 1.0, green: 0.95, blue: 0.78), radius: 28, height: 62),

        .init(id: "coffee", title: "Grab a Coffee", icon: "cup.and.saucer.fill", kind: .connection, tint: .init(red: 0.57, green: 0.37, blue: 0.29), pale: .init(red: 0.96, green: 0.89, blue: 0.83), radius: 32, height: 60),

        .init(id: "study", title: "Find a Study Buddy", icon: "books.vertical.fill", kind: .learning, tint: .init(red: 0.26, green: 0.54, blue: 0.62), pale: .init(red: 0.85, green: 0.95, blue: 0.97), radius: 18, height: 68),

        .init(id: "goal", title: "Set a Goal", icon: "target", kind: .goal, tint: .init(red: 0.70, green: 0.32, blue: 0.44), pale: .init(red: 0.99, green: 0.88, blue: 0.92), radius: 30, height: 64)

    ]

}

// A justified, adaptive flow: each row expands its tiles to exactly fill the
// available sheet width, keeping the gaps even and the varied corner shapes.
// The usage caption is part of the measured tile but OUTSIDE its button border.
private struct TimelineFlowLayout: Layout {
    var spacing: CGFloat = 10
    var rowSpacing: CGFloat = 8

    private func frames(
        width proposedWidth: CGFloat,
        subviews: Subviews
    ) -> (size: CGSize, rects: [CGRect]) {
        let available = proposedWidth.isFinite ? max(1, proposedWidth) : 350
        guard !subviews.isEmpty else {
            return (CGSize(width: available, height: 0), [])
        }

        // Measure natural tile widths first, so rows still have an organic mix.
        let widths = subviews.map {
            min(available, max(1, $0.sizeThatFits(.unspecified).width))
        }
        var rows: [[Int]] = []
        var current: [Int] = []
        var naturalRowWidth: CGFloat = 0

        for index in subviews.indices {
            let nextWidth = widths[index] + (current.isEmpty ? 0 : spacing)
            if !current.isEmpty && naturalRowWidth + nextWidth > available {
                rows.append(current)
                current = []
                naturalRowWidth = 0
            }
            current.append(index)
            naturalRowWidth += widths[index] + (current.count == 1 ? 0 : spacing)
        }
        if !current.isEmpty { rows.append(current) }

        // Avoid an isolated final tile when the prior row has three or more.
        if rows.count >= 2 && rows[rows.count - 1].count == 1
            && rows[rows.count - 2].count >= 3 {
            let candidate = rows[rows.count - 2].last!
            let final = rows[rows.count - 1][0]
            if widths[candidate] + widths[final] + spacing <= available {
                rows[rows.count - 2].removeLast()
                rows[rows.count - 1].insert(candidate, at: 0)
            }
        }

        var result = Array(repeating: CGRect.zero, count: subviews.count)
        var y: CGFloat = 0

        for row in rows {
            let gapWidth = CGFloat(max(0, row.count - 1)) * spacing
            let natural = row.reduce(CGFloat.zero) { $0 + widths[$1] }
            let bonus = max(0, available - gapWidth - natural) / CGFloat(row.count)
            var x: CGFloat = 0
            var rowHeight: CGFloat = 0

            for (position, index) in row.enumerated() {
                // Assign the final tile the exact remaining width, avoiding
                // visible one-pixel gaps from floating-point rounding.
                let tileWidth = position == row.count - 1
                    ? max(1, available - x)
                    : widths[index] + bonus
                let tileSize = subviews[index].sizeThatFits(
                    ProposedViewSize(width: tileWidth, height: nil)
                )
                result[index] = CGRect(x: x, y: y, width: tileWidth, height: tileSize.height)
                rowHeight = max(rowHeight, tileSize.height)
                x += tileWidth + spacing
            }
            y += rowHeight + rowSpacing
        }

        return (CGSize(width: available, height: max(0, y - rowSpacing)), result)
    }

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        frames(width: proposal.width ?? 350, subviews: subviews).size
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let positions = frames(width: bounds.width, subviews: subviews).rects
        for index in subviews.indices {
            let rect = positions[index]
            subviews[index].place(
                at: CGPoint(x: bounds.minX + rect.minX, y: bounds.minY + rect.minY),
                proposal: ProposedViewSize(width: rect.width, height: rect.height)
            )
        }
    }
}

// A single prompt consists of its button AND a small, right-aligned caption.
// The caption sits outside the rounded border and cannot trigger the button.
private struct TimelinePromptTile: View {
    let prompt: TimelinePrompt
    let isSelected: Bool
    let memberCount: Int?
    let navy: Color
    let muted: Color
    let green: Color
    let action: () -> Void

    var body: some View {
        VStack(alignment: .trailing, spacing: 5) {
            Button(action: action) {
                HStack(spacing: 7) {
                    Image(systemName: prompt.icon)
                        .font(.system(size: 15, weight: .semibold))
                    Text(prompt.title)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.73)
                }
                .foregroundStyle(isSelected ? Color.white : prompt.tint)
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity)
                .frame(height: prompt.height)
                .background(
                    isSelected ? navy : prompt.pale,
                    in: RoundedRectangle(cornerRadius: prompt.radius, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: prompt.radius, style: .continuous)
                        .strokeBorder(
                            isSelected ? green : prompt.tint.opacity(0.12),
                            lineWidth: isSelected ? 2 : 1
                        )
                }
                .scaleEffect(isSelected ? 1.02 : 1)
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(isSelected ? [.isSelected] : [])

            HStack(spacing: 4) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 10, weight: .semibold))
                Text(usageLabel)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .monospacedDigit()
            }
            .foregroundStyle(muted)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, 6)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibleUsageLabel)
        }
        .frame(minWidth: 112)
    }

    private var usageLabel: String {
        guard let memberCount, memberCount >= 0 else { return "— members" }
        return "\(memberCount.formatted(.number.notation(.compactName))) members"
    }

    private var accessibleUsageLabel: String {
        guard let memberCount, memberCount >= 0 else {
            return "Usage count unavailable for \(prompt.title)"
        }
        return "\(memberCount) members have used \(prompt.title)"
    }
}

// MARK: - Two-step add flow

struct AddToTimelineSheet: View {

    var firstName: String? = nil

    /// Unique members who have selected each idea; keyed by TimelinePrompt.id.
    /// Supply real counts from your backend. Missing values show “— members”
    /// rather than an invented popularity number.
    var promptUsageCounts: [String: Int] = [:]

    var onSaved: ((TimelineCreationDraft) -> Void)? = nil

    var onPublish: TimelineDraftPublisher? = nil

    @Environment(\.dismiss) private var dismiss

    @State private var step = 0

    @State private var promptOrder = TimelinePrompt.all.shuffled()

    @State private var selectedPromptID: String?

    @State private var kind: TimelineCreationKind = .request

    @State private var what = ""

    @State private var notes = ""

    @State private var startsAt = Date().addingTimeInterval(60 * 60)

    @State private var expiresAt = Date().addingTimeInterval(7 * 24 * 60 * 60)

    @State private var includeEndTime = false

    // Privacy first: new additions stay private until the user changes scope.
    @State private var visibilityScope: TimelineVisibilityScope = .privateOnly
    @State private var visibilityArea = ""

    @State private var selectedMedia: [PhotosPickerItem] = []

    @State private var attachments: [TimelineStagedMedia] = []

    @State private var isImporting = false

    @State private var isSaving = false

    @State private var savedDraft: TimelineCreationDraft?

    @State private var problem: String?

    @State private var syncWarning: String?
    @State private var didPublish = false

    private let navy = Color(red: 0.15, green: 0.23, blue: 0.33)

    private let muted = Color(red: 0.39, green: 0.49, blue: 0.57)

    private let canvas = Color(red: 0.929, green: 0.965, blue: 0.976)

    private let green = Color(red: 0.08, green: 0.61, blue: 0.42)

    private var cleanedWhat: String { what.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var effectiveExpiry: Date? { (kind.usesExpiration || includeEndTime) ? expiresAt : nil }

    private var cleanedVisibilityArea: String {
        visibilityArea.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var valid: Bool {

        !cleanedWhat.isEmpty && startsAt >= Date().addingTimeInterval(-60)

            && (effectiveExpiry == nil || expiresAt > startsAt)
            && (!visibilityScope.requiresArea || !cleanedVisibilityArea.isEmpty)

            && !isSaving && !isImporting

    }

    var body: some View {

        NavigationStack {

            Group {

                if let savedDraft {

                    savedView(savedDraft)

                } else {

                    ScrollView {

                        VStack(alignment: .leading, spacing: 22) {

                            if step == 0 { ideasPage } else { detailsPage }

                        }

                        .padding(.horizontal, 20)

                        .padding(.top, 22)

                        .padding(.bottom, 36)

                    }

                    .safeAreaInset(edge: .bottom, spacing: 0) { bottomActions }

                }

            }

            .background(canvas.ignoresSafeArea())

            .navigationTitle(step == 0 ? "Add to Timeline" : "Customize Timeline")

            .navigationBarTitleDisplayMode(.inline)

            .toolbar {

                ToolbarItem(placement: .navigationBarLeading) {

                    if savedDraft == nil && step == 1 {

                        Button { withAnimation(.easeInOut) { step = 0 } } label: {

                            Label("Back", systemImage: "chevron.left")

                        }

                    }

                }

                ToolbarItem(placement: .navigationBarTrailing) {

                    Button(savedDraft == nil ? "Cancel" : "Done") { dismiss() }

                        .foregroundStyle(navy)

                }

            }

            .onChange(of: selectedMedia) { newItems in

                guard !newItems.isEmpty else { return }

                _Concurrency.Task { await importSelectedMedia(newItems) }

            }

            .onChange(of: startsAt) { newStart in

                if expiresAt <= newStart { expiresAt = newStart.addingTimeInterval(24 * 60 * 60) }

            }

            .alert("Couldn't save", isPresented: Binding(

                get: { problem != nil },

                set: { if !$0 { problem = nil } }

            )) {

                Button("OK", role: .cancel) { problem = nil }

            } message: {

                Text(problem ?? "Please try again.")

            }

        }

        .presentationDragIndicator(.visible)

    }

    private var ideasPage: some View {

        VStack(alignment: .leading, spacing: 17) {

            VStack(alignment: .leading, spacing: 6) {

                HStack(spacing: 8) {

                    Circle().fill(green).frame(width: 8, height: 8)

                    Text("1 OF 2 · SEEK TO FIND ")

                        .font(.system(size: 11, weight: .heavy, design: .rounded))

                        .tracking(1.2).foregroundStyle(green)

                }

                Text(heading)

                    .font(.system(size: 31, weight: .bold, design: .rounded))

                    .tracking(-0.7).foregroundStyle(navy)

                    .fixedSize(horizontal: false, vertical: true)

                Text("Choose from below, or enter your own.")

                    .font(.subheadline).foregroundStyle(muted)

            }

            TimelineFlowLayout(spacing: 10, rowSpacing: 8) {

                ForEach(promptOrder) { prompt in
                    TimelinePromptTile(
                        prompt: prompt,
                        isSelected: selectedPromptID == prompt.id,
                        memberCount: promptUsageCounts[prompt.id] ?? prompt.memberUsageCount,
                        navy: navy,
                        muted: muted,
                        green: green
                    ) {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                            selectedPromptID = prompt.id
                            kind = prompt.kind
                            what = prompt.title
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {

                Label("Or write your own", systemImage: "square.and.pencil")

                    .font(.subheadline.weight(.bold)).foregroundStyle(navy)

                TextField("What would you like to do or find?", text: $what, axis: .vertical)

                    .lineLimit(2...4)

                    .font(.system(size: 16))

                    .padding(15)

                    .background(.white, in: RoundedRectangle(cornerRadius: 18))

                    .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(green.opacity(0.2)))

                    .onChange(of: what) { newValue in

                        if let selectedPromptID,

                           let match = TimelinePrompt.all.first(where: { $0.id == selectedPromptID }),

                           match.title != newValue {

                            self.selectedPromptID = nil

                        }

                    }

            }

        }

    }

    private var heading: String {

        guard let first = firstName?.trimmingCharacters(in: .whitespacesAndNewlines), !first.isEmpty else {

            return "What are you looking for?"

        }

        return "What are you looking for, \(first)?"

    }

    private var detailsPage: some View {

        VStack(alignment: .leading, spacing: 17) {

            VStack(alignment: .leading, spacing: 7) {

                Text("2 OF 2 · CONFIRM SELECTION")

                    .font(.system(size: 11, weight: .heavy, design: .rounded)).tracking(1.2)

                    .foregroundStyle(green)

                Text("Finishing up.")

                    .font(.system(size: 29, weight: .bold, design: .rounded))

                    .foregroundStyle(navy)

                Text("Choose who sees this, then confirm when it should happen.")

                    .font(.subheadline).foregroundStyle(muted)

            }

            scopeSelection

            sectionCard {

                HStack {

                    Label("Confirm your selection", systemImage: "clock.arrow.trianglehead.clockwise.rotate.90.path.dotted")

                        .font(.headline).foregroundStyle(navy)

                    Spacer()

                    Button("Change") { withAnimation { step = 0 } }

                        .font(.subheadline.weight(.bold))

                }

                TextField("Describe what you want", text: $what, axis: .vertical)

                    .lineLimit(2...4)

                    .padding(12)

                    .background(canvas, in: RoundedRectangle(cornerRadius: 12))

                Picker("Type", selection: $kind) {

                    ForEach(TimelineCreationKind.allCases) { type in

                        Text(type.title).tag(type)

                    }

                }

                .tint(navy)

            }

            sectionCard {

                Label("When?", systemImage: "calendar.badge.clock")

                    .font(.headline).foregroundStyle(navy)

                DatePicker(kind.dateTitle, selection: $startsAt,

                           in: Date()..., displayedComponents: [.date, .hourAndMinute])

                    .tint(green)

                if kind.usesExpiration {

                    Divider()

                    Label(kind == .goal ? "Goal deadline" : "Request expires", systemImage: "hourglass")

                        .font(.subheadline.weight(.bold)).foregroundStyle(navy)

                    DatePicker("Until", selection: $expiresAt,

                               in: startsAt.addingTimeInterval(60)...,

                               displayedComponents: [.date, .hourAndMinute])

                        .tint(green)

                    Text("After this time, Goaliath can stop showing this to other members.")

                        .font(.caption).foregroundStyle(muted)

                } else {

                    Toggle("Add an end time", isOn: $includeEndTime).tint(green)

                    if includeEndTime {

                        DatePicker("Ends", selection: $expiresAt,

                                   in: startsAt.addingTimeInterval(60)...,

                                   displayedComponents: [.date, .hourAndMinute])

                            .tint(green)

                    }

                }

            }

            sectionCard {

                Label("Additional Details?", systemImage: "text.alignleft")

                    .font(.headline).foregroundStyle(navy)

                Text("Add context, details, or anything others should know (optional).")

                    .font(.caption).foregroundStyle(muted)

                TextEditor(text: $notes)

                    .scrollContentBackground(.hidden)

                    .frame(height: 110)

                    .padding(8)

                    .background(canvas, in: RoundedRectangle(cornerRadius: 12))

            }

            sectionCard {

                Label("Photos & videos", systemImage: "photo.on.rectangle.angled")

                    .font(.headline).foregroundStyle(navy)

                PhotosPicker(selection: $selectedMedia, maxSelectionCount: 8,

                             matching: .any(of: [.images, .videos])) {

                    Label("Add media", systemImage: "plus.circle.fill")

                        .font(.subheadline.weight(.bold))

                        .foregroundStyle(green)

                        .padding(.vertical, 8)

                }

                .disabled(isImporting || attachments.count >= 8)

                if isImporting {

                    ProgressView("Importing attachments…").font(.caption)

                }

                if !attachments.isEmpty {

                    ScrollView(.horizontal) {

                        HStack(spacing: 10) {

                            ForEach(attachments) { attachment in

                                attachmentTile(attachment)

                            }

                        }.padding(.vertical, 4)

                    }.scrollIndicators(.hidden)

                } else {

                    Text("Optional · Up to 8 photos or videos")

                        .font(.caption).foregroundStyle(muted)

                }

            }

        }

    }

    // A distinct, prominent visibility choice on page 2.
    // This is audience metadata, not a location lookup or actual publication.
    private var scopeSelection: some View {
        sectionCard {
            VStack(alignment: .leading, spacing: 5) {
                Label("Who should see this?", systemImage: "eye.fill")
                    .font(.headline)
                    .foregroundStyle(navy)

                Text("Keep it to yourself, share with your network, or reach people in a chosen area.")
                    .font(.subheadline)
                    .foregroundStyle(muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 10) {
                scopeButton(.privateOnly)
                scopeButton(.connections)
            }
            HStack(spacing: 10) {
                scopeButton(.localArea)
                scopeButton(.city)
            }
            scopeButton(.everyone)

            if visibilityScope.requiresArea {
                VStack(alignment: .leading, spacing: 7) {
                    Text(visibilityScope == .city ? "Which city?" : "Which local area?")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(navy)

                    TextField(
                        visibilityScope == .city
                            ? "e.g., Philadelphia, PA"
                            : "e.g., Fishtown, Philadelphia",
                        text: $visibilityArea
                    )
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .font(.subheadline)
                    .padding(13)
                    .background(canvas, in: RoundedRectangle(cornerRadius: 13))
                    .overlay {
                        RoundedRectangle(cornerRadius: 13)
                            .strokeBorder(green.opacity(0.2), lineWidth: 1)
                    }

                    if cleanedVisibilityArea.isEmpty {
                        Text("Enter a \(visibilityScope == .city ? "city" : "neighborhood or area") to continue.")
                            .font(.caption)
                            .foregroundStyle(Color.orange)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Label(visibilityScope.audienceDescription(area: cleanedVisibilityArea),
                  systemImage: visibilityScope.icon)
                .font(.caption.weight(.medium))
                .foregroundStyle(navy)
                .fixedSize(horizontal: false, vertical: true)

            Text("City and local area use the name you enter, not your device location. Audience filtering must be enforced by the Goaliath service when published.")
                .font(.caption2)
                .foregroundStyle(muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func scopeButton(_ candidate: TimelineVisibilityScope) -> some View {
        let isSelected = visibilityScope == candidate

        return Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                visibilityScope = candidate
            }
        } label: {
            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Image(systemName: candidate.icon)
                        .font(.system(size: 18, weight: .semibold))
                    Spacer(minLength: 0)
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 17))
                    }
                }
                Text(candidate.title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                Text(candidate.subtitle)
                    .font(.caption)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(isSelected ? Color.white : navy)
            .frame(maxWidth: .infinity, minHeight: 83, alignment: .leading)
            .padding(14)
            .background(isSelected ? green : canvas,
                        in: RoundedRectangle(cornerRadius: 17, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 17)
                    .strokeBorder(isSelected ? green : navy.opacity(0.07),
                                  lineWidth: isSelected ? 2 : 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(candidate.title). \(candidate.subtitle)")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private func sectionCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {

        VStack(alignment: .leading, spacing: 12, content: content)

            .frame(maxWidth: .infinity, alignment: .leading)

            .padding(17)

            .background(.white, in: RoundedRectangle(cornerRadius: 20))

    }

    private func attachmentTile(_ item: TimelineStagedMedia) -> some View {

        ZStack(alignment: .topTrailing) {

            Group {

                if item.kind == .image, let photo = UIImage(contentsOfFile: item.url.path) {

                    Image(uiImage: photo).resizable().scaledToFill()

                } else {

                    ZStack {

                        Color(red: 0.86, green: 0.91, blue: 0.97)

                        VStack(spacing: 6) {

                            Image(systemName: "video.fill").font(.title2)

                            Text("Video").font(.caption2.weight(.semibold))

                        }.foregroundStyle(navy)

                    }

                }

            }

            .frame(width: 116, height: 100)

            .clipped()

            .clipShape(RoundedRectangle(cornerRadius: 13))

            Button {

                attachments.removeAll { $0.id == item.id }

                try? FileManager.default.removeItem(at: item.url)

            } label: {

                Image(systemName: "xmark.circle.fill")

                    .symbolRenderingMode(.palette)

                    .foregroundStyle(.white, navy)

                    .font(.title3)

            }

            .padding(5)

            .accessibilityLabel("Remove attachment")

        }

    }

    private var bottomActions: some View {

        VStack(spacing: 0) {

            Divider().opacity(0.3)

            Button {

                if step == 0 {

                    withAnimation(.easeInOut(duration: 0.24)) { step = 1 }

                } else {

                    saveDraft()

                }

            } label: {

                HStack(spacing: 9) {

                    if isSaving { ProgressView().tint(.white) }

                    Text(step == 0 ? "Continue" : (isSaving ? "Saving…" : "Save to my timeline"))

                    if !isSaving { Image(systemName: step == 0 ? "arrow.right" : "checkmark.circle.fill") }

                }

                .font(.system(size: 16, weight: .bold, design: .rounded))

                .foregroundStyle(.white)

                .frame(maxWidth: .infinity).frame(height: 54)

                .background(green, in: RoundedRectangle(cornerRadius: 18))

            }

            .buttonStyle(.plain)

            .disabled(step == 0 ? cleanedWhat.isEmpty : !valid)

            .opacity((step == 0 ? cleanedWhat.isEmpty : !valid) ? 0.5 : 1)

            .padding(.horizontal, 20)

            .padding(.vertical, 13)

        }

        .background(.regularMaterial)

    }

    private func savedView(_ draft: TimelineCreationDraft) -> some View {

        VStack(spacing: 15) {

            Spacer()

            Image(systemName: "checkmark.circle.fill")

                .font(.system(size: 66)).foregroundStyle(green)

            Text("Added to your timeline")

                .font(.system(size: 26, weight: .bold, design: .rounded)).foregroundStyle(navy)

            Text(draft.title).font(.headline).multilineTextAlignment(.center)

                .foregroundStyle(navy)

            VStack(spacing: 9) {
                Label("Scope: \(draft.visibilityScope.compactLabel(area: draft.visibilityArea))",
                      systemImage: draft.visibilityScope.icon)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(navy)

                Text(draft.visibilityScope.audienceDescription(area: draft.visibilityArea))
                    .font(.subheadline)
                    .foregroundStyle(navy)
                    .multilineTextAlignment(.center)

                Text(didPublish
                     ? "Saved on this device and synced to Goaliath."
                     : "Saved on this device. Your chosen sharing scope will apply when the entry is published.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(muted)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(.white, in: RoundedRectangle(cornerRadius: 18))

            if let syncWarning {

                Label(syncWarning, systemImage: "wifi.exclamationmark")

                    .font(.caption).foregroundStyle(.orange)

                    .multilineTextAlignment(.center)

            }

            Spacer()

            Button("Done") { dismiss() }

                .font(.headline).foregroundStyle(.white)

                .frame(maxWidth: .infinity).frame(height: 54)

                .background(green, in: RoundedRectangle(cornerRadius: 18))

        }

        .padding(28)

    }

    @MainActor

    private func importSelectedMedia(_ items: [PhotosPickerItem]) async {

        isImporting = true

        defer {

            isImporting = false

            selectedMedia = []

        }

        for item in items {

            guard attachments.count < 8 else {

                problem = "You can add up to 8 photos or videos."

                break

            }

            do {

                let isVideo = item.supportedContentTypes.contains { $0.conforms(to: .movie) }

                if isVideo {

                    guard let movie = try await item.loadTransferable(type: TimelineImportedMovie.self) else {

                        throw TimelineImportError.unavailable

                    }

                    attachments.append(TimelineStagedMedia(id: UUID(), kind: .video, url: movie.fileURL))

                } else {

                    guard let data = try await item.loadTransferable(type: Data.self) else {

                        throw TimelineImportError.unavailable

                    }

                    let ext = item.supportedContentTypes.first(where: { $0.conforms(to: .image) })?

                        .preferredFilenameExtension ?? "jpg"

                    let url = FileManager.default.temporaryDirectory

                        .appendingPathComponent(UUID().uuidString).appendingPathExtension(ext)

                    try data.write(to: url, options: .atomic)

                    attachments.append(TimelineStagedMedia(id: UUID(), kind: .image, url: url))

                }

            } catch {

                problem = "One attachment couldn't be added: \(error.localizedDescription)"

            }

        }

    }

    private func saveDraft() {

        guard valid else { return }

        let draft = TimelineCreationDraft(

            id: UUID(), kind: kind, title: cleanedWhat,

            description: notes.trimmingCharacters(in: .whitespacesAndNewlines),

            startsAt: startsAt, expiresAt: effectiveExpiry,

            createdAt: Date(), attachments: [],
            visibilityScope: visibilityScope,
            visibilityArea: visibilityScope.requiresArea ? cleanedVisibilityArea : nil,
            scheduleStatus: [.activity, .meal, .workout, .task].contains(kind) ? .scheduled : nil

        )

        isSaving = true

        let captured = attachments

        _Concurrency.Task {

            do {

                let saved = try await _Concurrency.Task.detached(priority: .userInitiated) {

                    try GoaliathTimelineStore.save(draft, stagedMedia: captured)

                }.value

                // UI is honest: the locally saved copy exists even if publish fails.

                do {

                    if let onPublish {
                        try await onPublish(saved)
                        didPublish = true
                    }

                } catch {

                    syncWarning = "Not synced yet: \(error.localizedDescription)"

                }

                onSaved?(saved)

                savedDraft = saved

                isSaving = false

            } catch {

                problem = "We couldn't save your entry: \(error.localizedDescription)"

                isSaving = false

            }

        }

    }

}

private enum TimelineImportError: LocalizedError {

    case unavailable

    var errorDescription: String? { "This item could not be loaded from Photos." }

}
