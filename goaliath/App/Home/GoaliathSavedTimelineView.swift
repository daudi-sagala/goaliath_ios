import SwiftUI

// MARK: - Daily schedule display model

/// Use this model to pass the app's real, backend-authoritative schedule into
/// GoaliathSavedTimelineView. Local timeline drafts are adapted automatically
/// when `activities` is omitted.
struct GoaliathScheduleActivity: Identifiable {
    let id: String
    let title: String
    let details: String
    let kind: TimelineCreationKind
    let startsAt: Date
    let endsAt: Date?
    let status: TimelineScheduleStatus
    let actualStartedAt: Date?
    let location: String?
    let localDraftID: UUID?

    init(
        id: String,
        title: String,
        details: String = "",
        kind: TimelineCreationKind = .activity,
        startsAt: Date,
        endsAt: Date? = nil,
        status: TimelineScheduleStatus,
        actualStartedAt: Date? = nil,
        location: String? = nil,
        localDraftID: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.details = details
        self.kind = kind
        self.startsAt = startsAt
        self.endsAt = endsAt
        self.status = status
        self.actualStartedAt = actualStartedAt
        self.location = location
        self.localDraftID = localDraftID
    }

    init?(localDraft: TimelineCreationDraft) {
        guard let status = localDraft.effectiveScheduleStatus else { return nil }
        self.init(
            id: localDraft.id.uuidString,
            title: localDraft.title,
            details: localDraft.description,
            kind: localDraft.kind,
            startsAt: localDraft.startsAt,
            endsAt: localDraft.expiresAt,
            status: status,
            actualStartedAt: localDraft.actualStartedAt,
            localDraftID: localDraft.id
        )
    }
}

private enum DailyScheduleFilter: String, CaseIterable, Identifiable {
    case all, scheduled, confirmed, inProgress, completed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All"
        case .scheduled: return "Scheduled"
        case .confirmed: return "Confirmed"
        case .inProgress: return "Started"
        case .completed: return "Completed"
        }
    }

    func includes(_ status: TimelineScheduleStatus) -> Bool {
        switch self {
        case .all: return status.isShownOnDailySchedule
        case .scheduled: return status == .scheduled
        case .confirmed: return status == .confirmed
        case .inProgress: return status == .inProgress
        case .completed: return status == .completed
        }
    }
}

// MARK: - Today's schedule

/// A daily overview only. Requests, goals, tips and other feed entries do not
/// appear merely because they have a date: they need an explicit schedule status.
struct GoaliathSavedTimelineView: View {
    /// Pass the server-authoritative schedule here when available. If omitted,
    /// the view loads saved timeline drafts from device storage.
    var activities: [GoaliathScheduleActivity]? = nil

    /// Optional navigation into your own activity detail view.
    var onOpenActivity: ((GoaliathScheduleActivity) -> Void)? = nil

    /// Optional backend status mutation for server-supplied activities.
    /// The parent is responsible for updating `activities` after it succeeds.
    var onSetStatus: ((GoaliathScheduleActivity, TimelineScheduleStatus) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var localDrafts: [TimelineCreationDraft] = []
    @State private var selectedDate = Date()
    @State private var selectedFilter: DailyScheduleFilter = .all
    @State private var loadError: String?

    private let canvas = Color(red: 0.929, green: 0.965, blue: 0.976)
    private let navy = Color(red: 0.149, green: 0.231, blue: 0.333)
    private let muted = Color(red: 0.388, green: 0.490, blue: 0.569)
    private let green = Color(red: 0.08, green: 0.61, blue: 0.42)

    private var schedule: [GoaliathScheduleActivity] {
        activities ?? localDrafts.compactMap { GoaliathScheduleActivity(localDraft: $0) }
    }

    private var dayActivities: [GoaliathScheduleActivity] {
        schedule.filter {
            $0.status.isShownOnDailySchedule &&
            Calendar.current.isDate($0.startsAt, inSameDayAs: selectedDate)
        }
        .sorted {
            if $0.startsAt != $1.startsAt { return $0.startsAt < $1.startsAt }
            return $0.id < $1.id
        }
    }

    private var filteredActivities: [GoaliathScheduleActivity] {
        dayActivities.filter { selectedFilter.includes($0.status) }
    }

    private var completedCount: Int {
        dayActivities.filter { $0.status == .completed }.count
    }

    private var completionFraction: Double {
        guard !dayActivities.isEmpty else { return 0 }
        return Double(completedCount) / Double(dayActivities.count)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    dateSelector
                    progressPanel
                    statusPicker

                    if let loadError {
                        errorPanel(loadError)
                    } else if filteredActivities.isEmpty {
                        emptyPanel
                    } else {
                        LazyVStack(alignment: .leading, spacing: 13) {
                            ForEach(filteredActivities) { activity in
                                scheduleRow(activity)
                            }
                        }
                    }

                    if activities == nil {
                        Text("Showing activities saved on this device. Connect your Goaliath schedule to include activities from other devices.")
                            .font(.caption)
                            .foregroundStyle(muted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
            .background(canvas.ignoresSafeArea())
            .navigationTitle("My Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(navy)
                }
            }
            .onAppear(perform: reloadLocalDrafts)
        }
        .presentationDragIndicator(.visible)
    }

    // MARK: Date navigation

    private var dateSelector: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(Calendar.current.isDateInToday(selectedDate) ? "YOUR DAY" : "YOUR SCHEDULE")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(green)
                    Text(selectedDate.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                        .font(.system(size: 27, weight: .bold, design: .rounded))
                        .foregroundStyle(navy)
                }
                Spacer(minLength: 0)
                DatePicker("Choose a day", selection: $selectedDate, displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .tint(green)
                    .accessibilityLabel("Choose schedule date")
            }

            HStack(spacing: 10) {
                navButton(title: "Previous day", symbol: "chevron.left", direction: -1)
                Button {
                    selectedDate = Date()
                } label: {
                    Text("Today")
                        .font(.subheadline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 39)
                        .background(.white, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .foregroundStyle(navy)
                navButton(title: "Next day", symbol: "chevron.right", direction: 1)
            }
        }
    }

    private func navButton(title: String, symbol: String, direction: Int) -> some View {
        Button {
            if let day = Calendar.current.date(byAdding: .day, value: direction, to: selectedDate) {
                selectedDate = day
            }
        } label: {
            Image(systemName: symbol)
                .font(.subheadline.weight(.bold))
                .frame(width: 44, height: 39)
                .background(.white, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .foregroundStyle(navy)
        .accessibilityLabel(title)
    }

    // MARK: Summary & filters

    private var progressPanel: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily progress")
                        .font(.headline)
                        .foregroundStyle(navy)
                    Text("\(completedCount) of \(dayActivities.count) activities completed")
                        .font(.subheadline)
                        .foregroundStyle(muted)
                }
                Spacer(minLength: 8)
                Text("\(Int((completionFraction * 100).rounded()))%")
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundStyle(green)
                    .monospacedDigit()
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(red: 0.88, green: 0.92, blue: 0.94))
                    Capsule().fill(green)
                        .frame(width: geometry.size.width * completionFraction)
                }
            }
            .frame(height: 9)
            .accessibilityLabel("Daily progress")
            .accessibilityValue("\(completedCount) of \(dayActivities.count) completed")

            HStack(spacing: 8) {
                summaryChip("Scheduled", count: count(for: .scheduled), color: Color(red: 0.28, green: 0.45, blue: 0.70))
                summaryChip("Confirmed", count: count(for: .confirmed), color: green)
                summaryChip("Started", count: count(for: .inProgress), color: Color.orange)
                summaryChip("Completed", count: completedCount, color: Color(red: 0.45, green: 0.55, blue: 0.60))
            }
        }
        .padding(18)
        .background(.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func count(for status: TimelineScheduleStatus) -> Int {
        dayActivities.filter { $0.status == status }.count
    }

    private func summaryChip(_ label: String, count: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("\(count)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .monospacedDigit()
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(muted)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(canvas, in: RoundedRectangle(cornerRadius: 12))
    }

    private var statusPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Activities")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(navy)
            Picker("Activity status", selection: $selectedFilter) {
                ForEach(DailyScheduleFilter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.menu)
        }
    }

    // MARK: Activity cards

    private func scheduleRow(_ activity: GoaliathScheduleActivity) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .trailing, spacing: 4) {
                Text(activity.startsAt.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(navy)
                    .fixedSize(horizontal: true, vertical: false)
                if let end = activity.endsAt, end > activity.startsAt {
                    Text(end.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(muted)
                        .monospacedDigit()
                        .fixedSize(horizontal: true, vertical: false)
                }
            }
            .frame(width: 82, alignment: .trailing)
            .padding(.top, 18)

            VStack(spacing: 4) {
                Circle()
                    .fill(statusTint(activity.status))
                    .frame(width: 11, height: 11)
                Rectangle().fill(statusTint(activity.status).opacity(0.20))
                    .frame(width: 2, height: 95)
            }
            .padding(.top, 23)

            VStack(alignment: .leading, spacing: 9) {
                HStack(alignment: .top, spacing: 9) {
                    Image(systemName: icon(for: activity.kind))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(statusTint(activity.status))
                        .frame(width: 30, height: 30)
                        .background(statusTint(activity.status).opacity(0.12), in: RoundedRectangle(cornerRadius: 9))
                    Text(activity.title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(navy)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }

                Text(activity.kind.title.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(muted)

                if !activity.details.isEmpty {
                    Text(activity.details)
                        .font(.subheadline)
                        .foregroundStyle(muted)
                        .lineLimit(3)
                }

                if let location = activity.location, !location.isEmpty {
                    Label(location, systemImage: "mappin")
                        .font(.caption)
                        .foregroundStyle(muted)
                }

                HStack {
                    Label(activity.status.title, systemImage: statusSymbol(activity.status))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(statusTint(activity.status))
                    Spacer(minLength: 0)
                    if canChangeStatus(for: activity) {
                        statusMenu(activity)
                    } else if onOpenActivity != nil {
                        Button("Open") { onOpenActivity?(activity) }
                            .font(.caption.weight(.semibold))
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(statusTint(activity.status).opacity(0.12), lineWidth: 1)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func canChangeStatus(for activity: GoaliathScheduleActivity) -> Bool {
        (activities == nil && activity.localDraftID != nil) || onSetStatus != nil
    }

    private func statusMenu(_ activity: GoaliathScheduleActivity) -> some View {
        Menu {
            ForEach(allowedTransitions(from: activity.status), id: \.self) { newStatus in
                Button {
                    setStatus(activity, to: newStatus)
                } label: {
                    Label(newStatus.title, systemImage: statusSymbol(newStatus))
                }
                .disabled(newStatus == activity.status)
            }
            if let onOpenActivity {
                Divider()
                Button("Open details") { onOpenActivity(activity) }
            }
        } label: {
            Label("Update", systemImage: "chevron.down")
                .font(.caption.weight(.semibold))
                .foregroundStyle(navy)
        }
        .accessibilityLabel("Update \(activity.title) status")
    }

    private func allowedTransitions(from status: TimelineScheduleStatus) -> [TimelineScheduleStatus] {
        switch status {
        case .scheduled: return [.confirmed, .inProgress, .skipped]
        case .confirmed: return [.inProgress, .skipped]
        case .inProgress: return [.completed, .cancelled]
        case .completed, .skipped, .cancelled: return []
        }
    }

    private func setStatus(_ item: GoaliathScheduleActivity, to status: TimelineScheduleStatus) {
        if activities != nil {
            onSetStatus?(item, status)
            return
        }
        guard let draftID = item.localDraftID else { return }
        do {
            try GoaliathTimelineStore.updateScheduleStatus(id: draftID, to: status)
            reloadLocalDrafts()
        } catch {
            loadError = "Couldn't update the activity: \(error.localizedDescription)"
        }
    }

    private func icon(for kind: TimelineCreationKind) -> String {
        switch kind {
        case .meal: return "fork.knife"
        case .workout: return "figure.run"
        case .task: return "checkmark.square"
        case .activity: return "calendar"
        case .connection: return "person.2"
        case .place: return "mappin"
        case .shopping: return "bag"
        case .learning: return "book"
        default: return "calendar.badge.clock"
        }
    }

    private func statusSymbol(_ status: TimelineScheduleStatus) -> String {
        switch status {
        case .scheduled: return "clock"
        case .confirmed: return "checkmark.seal.fill"
        case .inProgress: return "play.circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .skipped: return "forward.end"
        case .cancelled: return "xmark.circle"
        }
    }

    private func statusTint(_ status: TimelineScheduleStatus) -> Color {
        switch status {
        case .scheduled: return Color(red: 0.28, green: 0.45, blue: 0.70)
        case .confirmed: return green
        case .inProgress: return .orange
        case .completed: return Color(red: 0.35, green: 0.58, blue: 0.48)
        case .skipped, .cancelled: return muted
        }
    }

    // MARK: Empty/error & loading local data

    private var emptyPanel: some View {
        VStack(spacing: 13) {
            Image(systemName: selectedFilter == .all ? "calendar.badge.clock" : "line.3.horizontal.decrease.circle")
                .font(.system(size: 42))
                .foregroundStyle(green)
            Text(selectedFilter == .all ? "Nothing scheduled for this day" : "No \(selectedFilter.title.lowercased()) activities")
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundStyle(navy)
            Text(selectedFilter == .all
                 ? "Scheduled meals, workouts, tasks and activities will appear here."
                 : "Try another status filter or choose a different day.")
                .font(.subheadline)
                .foregroundStyle(muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 28)
        .padding(.vertical, 44)
        .background(.white, in: RoundedRectangle(cornerRadius: 20))
    }

    private func errorPanel(_ message: String) -> some View {
        VStack(spacing: 12) {
            Label("Couldn't load your schedule", systemImage: "exclamationmark.triangle")
                .font(.headline)
            Text(message).font(.caption)
            Button("Try Again", action: reloadLocalDrafts)
                .buttonStyle(.borderedProminent)
                .tint(green)
        }
        .foregroundStyle(navy)
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(.white, in: RoundedRectangle(cornerRadius: 20))
    }

    private func reloadLocalDrafts() {
        guard activities == nil else { return }
        do {
            localDrafts = try GoaliathTimelineStore.loadDrafts()
            loadError = nil
        } catch {
            loadError = error.localizedDescription
        }
    }
}
