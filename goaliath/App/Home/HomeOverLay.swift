import SwiftUI

/// Restores your ORIGINAL BottomOverLay (the one in your existing project).
/// The activity is represented by a temporary CardData in slot zero; the
/// original BottomOverLay still owns EVERY tile's size, shape and layout.
/// No extra bar, "Discover" label, page counter or empty discovery tile is added.
struct HomeOverLay: View {
    var geometry: GeometryProxy
    @Binding var showMenu: Bool
    @Binding var showGoals: Bool
    var cardData: [CardData]
    @Binding var selectedCard: CardData

    // Retained for source compatibility with existing HomeView/BottomOverLay.
    let currentPage: Int
    let pageCount: Int
    let slideDirection: TileSlideDirection
    let onPrevious: () -> Void
    let onNext: () -> Void

    // Pinned activity support supplied by the current HomeView.
    var pinnedActivity: GoaliathScheduleActivity? = nil
    var now: Date = Date()
    var onPinnedTap: ((GoaliathScheduleActivity) -> Void)? = nil
    @EnvironmentObject private var live: GoaliathLiveStore
    @State private var showSchedule = false

    private var cardsForBottomRow: [CardData] {
        guard let pinnedActivity else { return Array(cardData.prefix(5)) }
        let pinned = GoaliathPinnedCardAdapter.makeCard(from: pinnedActivity, at: now)
        // HomeView already passes four rotating discovery cards when pinned.
        // De-duplicate by ID as a defensive precaution.
        let others = cardData.filter {
            $0.cardDataId != pinned.cardDataId &&
            $0.cardDataId != pinnedActivity.id &&
            $0.cardDataType.activity?.activityId != pinnedActivity.id
        }
        return [pinned] + Array(others.prefix(4))
    }

    /// Tapping the synthetic first card opens the real pinned-activity sheet,
    /// without changing selectedCard or showing the synthetic card in the feed.
    private var interceptedSelection: Binding<CardData> {
        Binding(
            get: { selectedCard },
            set: { incoming in
                if let pinnedActivity,
                   incoming.cardDataId == GoaliathPinnedCardAdapter.cardID(for: pinnedActivity) {
                    onPinnedTap?(pinnedActivity)
                } else {
                    selectedCard = incoming
                }
            }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            TopOverlay(
                geometry: geometry,
                showMenu: $showMenu,
            )
            Spacer(minLength: 0)
            VerticalRightOverlay(
                firstName: live.profile?.firstName,
                onOpenSchedule: { showSchedule=true },
                onPublishTimeline: { try await live.publish($0) }
            )

            // IMPORTANT: Reuse the original, compact five-tile component.
            // Do not add GoaliathPinnedBottomBar or wrap it in a taller card.
            BottomOverLay(
                cardData: cardsForBottomRow,
                selectedCard: interceptedSelection,
                currentPage: currentPage,
                pageCount: pageCount,
                slideDirection: slideDirection,
                onPrevious: onPrevious,
                onNext: onNext
            )
        }
        .sheet(isPresented: $showSchedule) {
            GoaliathSavedTimelineView(activities: live.schedule, onSetStatus: { item,status in
                _Concurrency.Task { @MainActor in
                    do { try await live.setActivityStatus(item, to: status) }
                    catch { live.errorMessage = error.localizedDescription }
                }
            })
        }
    }
}
