import SwiftUI

/// Small activity action sheet shown when the leftmost bottom tile is tapped.
/// This view does not assume the server mutation succeeded: the parent owns persistence.
struct GoaliathPinnedActivityDetailView: View {
    let activity: GoaliathScheduleActivity
    let onChangeStatus: (TimelineScheduleStatus) -> Void
    var onOpenActivity: ((GoaliathScheduleActivity) -> Void)? = nil
    var canUpdateStatus: Bool = true

    @Environment(\.dismiss) private var dismiss
    private let navy = Color(red: 0.149, green: 0.231, blue: 0.333)
    private let green = Color(red: 0.08, green: 0.61, blue: 0.42)

    private var isDue: Bool { activity.startsAt <= Date() }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Label("PINNED ACTIVITY", systemImage: "pin.fill")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundStyle(green)
                        Spacer()
                        Text(activity.status.title)
                            .font(.caption.bold())
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .background(green.opacity(0.12), in: Capsule())
                    }
                    Text(activity.title)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(navy)
                    if !activity.details.isEmpty {
                        Text(activity.details).foregroundStyle(navy.opacity(0.78))
                    }
                    Label(activity.startsAt.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                    if let endsAt = activity.endsAt {
                        Label("Ends \(endsAt.formatted(date: .omitted, time: .shortened))", systemImage: "clock")
                    } else {
                        Label("No end time · pin lasts up to 60 minutes", systemImage: "clock")
                    }
                    if let location = activity.location, !location.isEmpty {
                        Label(location, systemImage: "mappin")
                    }
                    Divider()
                    if !canUpdateStatus {
                        Text("Connect schedule actions to enable status changes.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    if activity.status == .scheduled {
                        actionButton("Confirm", icon: "checkmark.seal.fill", prominent: false) {
                            onChangeStatus(.confirmed)
                        }
                    }
                    if activity.status == .scheduled || activity.status == .confirmed {
                        if isDue {
                            actionButton("Begin", icon: "play.fill", prominent: true) {
                                onChangeStatus(.inProgress)
                            }
                        } else if let onOpenActivity {
                            actionButton("Open activity", icon: "arrow.up.right.square.fill", prominent: true, requiresMutation: false) {
                                onOpenActivity(activity)
                            }
                        }
                        actionButton("Skip", icon: "forward.fill", prominent: false) {
                            onChangeStatus(.skipped)
                        }
                    } else if activity.status == .inProgress {
                        actionButton("Completed", icon: "checkmark.circle.fill", prominent: true) {
                            onChangeStatus(.completed)
                        }
                        actionButton("Cancel activity", icon: "xmark.circle", prominent: false) {
                            onChangeStatus(.cancelled)
                        }
                    } else {
                        Text("This activity is no longer pinned.")
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.subheadline)
                .padding(20)
            }
            .background(Color(red: 0.929, green: 0.965, blue: 0.976).ignoresSafeArea())
            .navigationTitle("Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func actionButton(_ title: String, icon: String, prominent: Bool, requiresMutation: Bool = true, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity).frame(height: 50)
                .foregroundStyle(prominent ? Color.white : navy)
                .background(prominent ? green : Color.white,
                            in: RoundedRectangle(cornerRadius: 15))
        }
        .buttonStyle(.plain)
        .disabled(requiresMutation && !canUpdateStatus)
    }
}
