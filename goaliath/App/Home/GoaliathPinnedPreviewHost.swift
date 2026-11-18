import SwiftUI

/// Optional demo-only entry point. Do not add this as your app's main view.
/// Presents two sample activities, with an in-memory status callback.
struct GoaliathPinnedPreviewHost: View {
    @State private var exampleSchedule = GoaliathPinnedPreviewHost.makeSchedule()

    var body: some View {
        GeometryReader { geometry in
            HomeView(
                geometry: geometry,
                scheduleActivities: exampleSchedule,
                onSetScheduleStatus: { item, status in
                    guard let index = exampleSchedule.firstIndex(where: { $0.id == item.id }) else { return }
                    let old = exampleSchedule[index]
                    exampleSchedule[index] = GoaliathScheduleActivity(
                        id: old.id,
                        title: old.title,
                        details: old.details,
                        kind: old.kind,
                        startsAt: old.startsAt,
                        endsAt: old.endsAt,
                        status: status,
                        actualStartedAt: status == .inProgress ? Date() : old.actualStartedAt,
                        location: old.location
                    )
                }
            )
        }
    }

    private static func makeSchedule() -> [GoaliathScheduleActivity] {
        let hour = Calendar.current.dateInterval(of: .hour, for: Date())!.start
        return [
            GoaliathScheduleActivity(
                id: "preview-workout",
                title: "Strength workout",
                details: "30-minute strength session at the neighborhood gym.",
                kind: .workout,
                startsAt: hour.addingTimeInterval(5 * 60),
                endsAt: hour.addingTimeInterval(90 * 60),
                status: .confirmed,
                location: "Community gym"
            ),
            GoaliathScheduleActivity(
                id: "preview-meal",
                title: "Dinner with friends",
                kind: .meal,
                startsAt: hour.addingTimeInterval(65 * 60),
                endsAt: hour.addingTimeInterval(120 * 60),
                status: .scheduled
            )
        ]
    }
}
