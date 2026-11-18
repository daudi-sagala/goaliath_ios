import SwiftUI

// New presentation components for Goaliath. They have unique names and do not
// redefine your existing Activity, Gift, UserStatus, SuggestedMeal, Workout or Task models.

enum GoaliathCardUpdateAction {
    case thankGifter(giftId: String, message: String)
    case reactToStatus(memberId: String, statusDate: String, emoji: String)
    case commentOnStatus(memberId: String, statusDate: String, text: String)
    case addSuggestionToSchedule(kind: GoaliathSuggestionKind, id: String, at: Date)
    case ignoreSuggestion(kind: GoaliathSuggestionKind, id: String)
    case activity(activityId: String, operation: GoaliathScheduleOperation)
}

enum GoaliathSuggestionKind: String {
    case meal, workout, task

    var displayName: String { rawValue.capitalized }
}

enum GoaliathScheduleOperation {
    case begin, open, confirm, skip, complete
}

struct GoaliathStatusReaction: Identifiable {
    let emoji: String
    let count: Int
    var id: String { emoji }
}

struct GoaliathStatusComment: Identifiable {
    let id: String
    let memberName: String
    let memberAvatarURL: String
    let text: String
    let createdAt: String
}

/// Supply these from the social backend; UserStatus itself has no engagement fields.
struct GoaliathStatusEngagement {
    var commentCount: Int = 0
    var reactions: [GoaliathStatusReaction] = []
    var comments: [GoaliathStatusComment] = []
}

/// Result of looking up the existing conversation by member ID.
/// The conversation's real ID and chat entries must come from your messaging service.
struct GoaliathMemberConversationData {
    let message: Message
    let entries: [GoaliathConversationEntry]
    var role: String = "Member"
    var location: String = ""
}

enum GoaliathCardLook {
    static let ink = Color(red: 0.15, green: 0.23, blue: 0.33)
    static let muted = Color(red: 0.40, green: 0.49, blue: 0.57)
    static let canvas = Color(red: 0.929, green: 0.965, blue: 0.976)
    static let blue = Color(red: 0.16, green: 0.43, blue: 0.83)
    static let green = Color(red: 0.07, green: 0.61, blue: 0.42)
    static let violet = Color(red: 0.45, green: 0.32, blue: 0.79)
    static let orange = Color(red: 0.91, green: 0.52, blue: 0.18)
    static let red = Color(red: 0.78, green: 0.26, blue: 0.33)
}

struct GoaliathCardSurface<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) { content }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white, in: RoundedRectangle(cornerRadius: 23, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 23, style: .continuous)
                    .strokeBorder(GoaliathCardLook.ink.opacity(0.055), lineWidth: 1)
            }
    }
}

struct GoaliathCardTitle: View {
    let title: String
    let symbol: String
    let tint: Color

    var body: some View {
        Label(title, systemImage: symbol)
            .font(.system(size: 12, weight: .heavy, design: .rounded))
            .tracking(0.7)
            .foregroundStyle(tint)
            .textCase(.uppercase)
    }
}

struct GoaliathCardFieldRow: View {
    let label: String
    let value: String
    let symbol: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: symbol)
                .frame(width: 19)
                .foregroundStyle(GoaliathCardLook.blue)
            VStack(alignment: .leading, spacing: 3) {
                Text(label).font(.caption).foregroundStyle(GoaliathCardLook.muted)
                Text(value.isEmpty ? "Not specified" : value)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(GoaliathCardLook.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }
}

struct GoaliathCardAvatarView: View {
    let imageURL: String
    let name: String
    var size: CGFloat = 52

    var body: some View {
        AsyncImage(url: URL(string: imageURL)) { phase in
            if case let .success(image) = phase {
                image.resizable().scaledToFill()
            } else {
                ZStack {
                    GoaliathCardLook.canvas
                    Text(String(name.prefix(1)).uppercased())
                        .font(.system(size: size * 0.4, weight: .heavy, design: .rounded))
                        .foregroundStyle(GoaliathCardLook.blue)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityLabel("\(name) profile photo")
    }
}

struct GoaliathCardPhoto: View {
    let imageURL: String
    var height: CGFloat = 180

    var body: some View {
        GeometryReader { geometry in
            AsyncImage(url: URL(string: imageURL)) { phase in
                if case let .success(image) = phase {
                    image.resizable().scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                } else {
                    ZStack {
                        GoaliathCardLook.canvas
                        Image(systemName: "photo")
                            .font(.system(size: 28))
                            .foregroundStyle(GoaliathCardLook.muted)
                    }
                }
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct GoaliathCardPillButton: View {
    let title: String
    let tint: Color
    var outlined = false
    var disabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.82)
                .foregroundStyle(outlined ? tint : Color.white)
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity, minHeight: 54)
                .background {
                    RoundedRectangle(cornerRadius: 17, style: .continuous)
                        .fill(outlined ? tint.opacity(0.11) : tint)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 17, style: .continuous)
                        .strokeBorder(tint.opacity(0.23), lineWidth: 1)
                }
                .shadow(color: outlined ? .clear : tint.opacity(0.18), radius: 6, y: 3)
        }
        .buttonStyle(GoaliathCardPressStyle())
        .disabled(disabled)
        .opacity(disabled ? 0.52 : 1)
        .accessibilityLabel(title)
    }
}

struct GoaliathCardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

/// Handles ISO-8601 (+ fractional seconds / timezone), yyyy-MM-dd, clock strings,
/// and simple SQL timestamps. Never substitutes the current date for unparseable data.
enum GoaliathHumanDate {
    static func parse(_ source: String) -> Date? {
        let text = source.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: text) { return date }
        iso.formatOptions = [.withInternetDateTime]
        if let date = iso.date(from: text) { return date }
        // Parse calendar-only dates as local dates. Treating them as UTC midnight
        // would incorrectly display the previous day in western time zones.
        if text.count == 10 && text.contains("-") {
            let calendarDate = DateFormatter()
            calendarDate.locale = Locale(identifier: "en_US_POSIX")
            calendarDate.dateFormat = "yyyy-MM-dd"
            return calendarDate.date(from: text)
        }
        for format in ["yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd HH:mm", "yyyy-MM-dd'T'HH:mm:ss"] {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = format
            if let date = formatter.date(from: text) { return date }
        }
        return nil
    }

    static func display(_ source: String) -> String {
        guard let date = parse(source) else { return source.isEmpty ? "Not specified" : source }
        let text = source.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.count == 10 && text.contains("-") {
            return date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day().year())
        }
        return date.formatted(.dateTime.month(.abbreviated).day().year().hour().minute())
    }

    static func date(_ source: String) -> String {
        guard let value = parse(source) else { return source.isEmpty ? "Not specified" : source }
        return value.formatted(.dateTime.weekday(.wide).month(.abbreviated).day().year())
    }

    static func clock(_ source: String) -> String {
        let text = source.trimmingCharacters(in: .whitespacesAndNewlines)
        if let full = parse(text), (text.contains("T") || text.contains(" ")) {
            return full.formatted(.dateTime.hour().minute())
        }
        for format in ["HH:mm:ss", "HH:mm", "h:mm a", "h:mma"] {
            let parser = DateFormatter()
            parser.locale = Locale(identifier: "en_US_POSIX")
            parser.dateFormat = format
            parser.isLenient = false
            if let date = parser.date(from: text) {
                return date.formatted(.dateTime.hour().minute())
            }
        }
        return text.isEmpty ? "Not specified" : text
    }

    static func timeRange(start: String, end: String) -> String {
        "\(clock(start)) – \(clock(end))"
    }

    static func statusTime(_ source: String) -> String {
        guard let date = parse(source) else { return source.isEmpty ? "Time unavailable" : source }
        let time = date.formatted(.dateTime.hour().minute())
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today · \(time)" }
        if calendar.isDateInYesterday(date) { return "Yesterday · \(time)" }
        return date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute())
    }
}

struct GoaliathScheduleSuggestionSheet: View {
    let kind: GoaliathSuggestionKind
    let title: String
    let isPreview: Bool
    let onAdd: (Date) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var scheduledAt = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("\(kind.displayName) suggestion") {
                    Text(title).font(.headline)
                    Text("Choose when this should appear in your schedule.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Section("When") {
                    DatePicker("Date and time", selection: $scheduledAt,
                               in: Date()..., displayedComponents: [.date, .hourAndMinute])
                }
                if isPreview {
                    Section {
                        Text("Preview only — connect a scheduling action to save this item.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                Section {
                    GoaliathCardPillButton(title: isPreview ? "Close Preview" : "Add to Schedule",
                                           tint: GoaliathCardLook.green) {
                        if !isPreview { onAdd(scheduledAt) }
                        dismiss()
                    }
                }
            }
            .navigationTitle("Add to Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Cancel") { dismiss() } } }
        }
    }
}

struct GoaliathSuggestionActions: View {
    let kind: GoaliathSuggestionKind
    let id: String
    let title: String
    var onAction: ((GoaliathCardUpdateAction) -> Void)?

    @State private var showSchedule = false
    @State private var confirmIgnore = false
    @State private var showPreview = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                GoaliathCardPillButton(title: "Add to Schedule", tint: GoaliathCardLook.green) {
                    showSchedule = true
                }
                GoaliathCardPillButton(title: "Ignore \(kind.displayName)", tint: GoaliathCardLook.muted,
                                       outlined: true) {
                    confirmIgnore = true
                }
            }
        }
        .sheet(isPresented: $showSchedule) {
            GoaliathScheduleSuggestionSheet(kind: kind, title: title,
                                           isPreview: onAction == nil) { date in
                onAction?(.addSuggestionToSchedule(kind: kind, id: id, at: date))
            }
            .presentationDetents([.medium, .large])
        }
        .confirmationDialog("Ignore this \(kind.displayName.lowercased())?",
                            isPresented: $confirmIgnore, titleVisibility: .visible) {
            Button("Ignore \(kind.displayName)") {
                if let onAction {
                    onAction(.ignoreSuggestion(kind: kind, id: id))
                } else { showPreview = true }
            }
            Button("Keep Suggestion", role: .cancel) { }
        } message: {
            Text("It will be removed from your recommendations once your app saves this action.")
        }
        .alert("Preview only", isPresented: $showPreview) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Connect this action to your scheduling or recommendation service.")
        }
    }
}
