import SwiftUI

// Drop-in replacement: the two buttons stay in their original right-side rail.
// The lower (+) opens the new two-step Add to Timeline sheet.
struct VerticalRightOverlay: View {
    var firstName: String? = nil
    var promptUsageCounts: [String: Int] = [:]
    var onOpenSchedule: (() -> Void)? = nil
    var onTimelineSaved: ((TimelineCreationDraft) -> Void)? = nil
    var onPublishTimeline: TimelineDraftPublisher? = nil

    @State private var showAddSheet = false
    @State private var showLocalTimeline = false

    private let accent = Color(red: 0.08, green: 0.61, blue: 0.42)

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack(spacing: 0) {
                    Button {
                        if let onOpenSchedule { onOpenSchedule() }
                        else { showLocalTimeline = true }
                    } label: {
                        Image(systemName: "clock.arrow.trianglehead.clockwise.rotate.90.path.dotted")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(.blue)
                            .frame(width: 62, height: 58)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Open my timeline")

                    Rectangle().fill(.white.opacity(0.45))
                        .frame(width: 36, height: 1)

                    Button { showAddSheet = true } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 31, weight: .medium))
                            .foregroundStyle(.green)
                            .frame(width: 62, height: 58)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Add to timeline")
                }
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 25, style: .continuous))
            }
        }
        .padding()
        .background(.clear)
        .sheet(isPresented: $showAddSheet) {
            AddToTimelineSheet(
                firstName: firstName,
                promptUsageCounts: promptUsageCounts,
                onSaved: onTimelineSaved,
                onPublish: onPublishTimeline
            )
        }
        .sheet(isPresented: $showLocalTimeline) { GoaliathSavedTimelineView() }
    }
}
