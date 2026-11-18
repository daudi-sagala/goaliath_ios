import Foundation

/// Foundation-only selector. Can be unit-tested without SwiftUI.
/// Status values correspond to TimelineScheduleStatus.rawValue.
struct GoaliathPinCandidate: Equatable {
    let id: String
    let startsAt: Date
    let endsAt: Date?
    let actualStartedAt: Date?
    let status: String

    func effectiveEnd(defaultDuration: TimeInterval = 3600) -> Date {
        if let endsAt, endsAt > startsAt { return endsAt }
        return (actualStartedAt ?? startsAt).addingTimeInterval(defaultDuration)
    }
}

enum GoaliathPinSelector {
    /// One pinned activity at a time. Ongoing started items outrank upcoming items;
    /// otherwise hold the previously pinned item until it stops being eligible.
    static func selectID(
        from candidates: [GoaliathPinCandidate],
        at now: Date,
        holding previousID: String?,
        calendar: Calendar = .current
    ) -> String? {
        let hourStart = calendar.dateInterval(of: .hour, for: now)?.start ?? now
        let nextHour = calendar.date(byAdding: .hour, value: 1, to: hourStart) ?? now.addingTimeInterval(3600)

        func eligible(_ item: GoaliathPinCandidate) -> Bool {
            guard item.effectiveEnd() > now else { return false }
            switch item.status {
            case "inProgress":
                return (item.actualStartedAt ?? item.startsAt) <= now
            case "scheduled", "confirmed":
                // Scheduled before this hour and not yet pinned must not suddenly
                // appear. A previous pinned item may stay until its end time.
                return item.startsAt >= hourStart && item.startsAt < nextHour
                    || item.id == previousID && item.startsAt <= now
            default:
                return false
            }
        }

        let usable = candidates.filter(eligible)
        let started = usable.filter { $0.status == "inProgress" }
        if !started.isEmpty {
            if let previous = started.first(where: { $0.id == previousID }) { return previous.id }
            return started.sorted {
                let l = $0.actualStartedAt ?? $0.startsAt
                let r = $1.actualStartedAt ?? $1.startsAt
                return l == r ? $0.id < $1.id : l < r
            }.first?.id
        }
        if let previous = usable.first(where: { $0.id == previousID }) { return previous.id }

        return usable.sorted {
            let a = $0.status == "confirmed" ? 0 : 1
            let b = $1.status == "confirmed" ? 0 : 1
            if a != b { return a < b }
            if $0.startsAt != $1.startsAt { return $0.startsAt < $1.startsAt }
            return $0.id < $1.id
        }.first?.id
    }
}

extension Notification.Name {
    /// Local drafts or lifecycle status changed. The home pin should re-evaluate.
    static let goaliathTimelineDidChange = Notification.Name("GoaliathTimelineDidChange")
}
