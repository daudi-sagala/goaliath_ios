import SwiftUI
import Combine

/// HomeView with one stable activity pin and four rotating discovery cards.
struct HomeView: View {
    var geometry: GeometryProxy
    var cardData: [CardData] = []

    /// Supply your authoritative schedule here when available; otherwise local
    /// drafts saved by AddToTimelineSheet are loaded automatically.
    var scheduleActivities: [GoaliathScheduleActivity]? = nil
    /// For server-supplied activities, mutate the backend and then refresh
    /// scheduleActivities; this view does not pretend the remote write succeeded.
    var onSetScheduleStatus: ((GoaliathScheduleActivity, TimelineScheduleStatus) -> Void)? = nil
    var onOpenScheduleActivity: ((GoaliathScheduleActivity) -> Void)? = nil
    /// Passed by MainView. Optional so standalone SwiftUI previews still compile.
    var onSignOut: (() -> Void)? = nil

    @Environment(\.scenePhase) private var scenePhase
    @State private var cardGroupIndex = 0
    @State private var slideDirection: TileSlideDirection = .next
    @State private var localDrafts: [TimelineCreationDraft] = []
    @State private var pinnedID: String?
    @State private var openedPinnedActivity: GoaliathScheduleActivity?
    @State private var now = Date()
    @State private var scheduleError: String?

    @State private var showMenu = false
    @State private var showSignOutConfirmation = false
    @State private var showGoals = false
    @State private var activeMenuDestination: GoaliathMenuDestination?
    @StateObject private var demoChats = GoaliathChatStore(currentUserId: "", conversations: [])
    @EnvironmentObject private var live: GoaliathLiveStore
    @State private var selectedCard: CardData = GoaliathLiveEmptyCard.placeholder

    private let background = Color(red: 0.929, green: 0.965, blue: 0.976)
    private let primary = Color(red: 0.149, green: 0.231, blue: 0.333)
    private let secondary = Color(red: 0.388, green: 0.490, blue: 0.569)
    private let accent = Color(red: 0.322, green: 0.435, blue: 0.647)

    private let cardRotationTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    private var schedule: [GoaliathScheduleActivity] {
        if let scheduleActivities { return scheduleActivities }
        return localDrafts.compactMap(GoaliathScheduleActivity.init(localDraft:))
    }

    private var pinnedActivity: GoaliathScheduleActivity? {
        guard let pinnedID else { return nil }
        return schedule.first(where: { $0.id == pinnedID })
    }

    private var rotatingPool: [CardData] {
        guard let pinnedActivity else { return cardData }
        return cardData.filter { card in
            card.cardDataId != pinnedActivity.id &&
            card.cardDataType.activity?.activityId != pinnedActivity.id
        }
    }

    private var discoverySlotCount: Int { pinnedActivity == nil ? 5 : 4 }
    private var groupCount: Int {
        max(1, (rotatingPool.count + discoverySlotCount - 1) / discoverySlotCount)
    }

    private var visibleCards: [CardData] {
        let pool = rotatingPool
        guard !pool.isEmpty else { return [] }
        let start = (cardGroupIndex % groupCount) * discoverySlotCount
        let count = min(discoverySlotCount, pool.count)
        return (0..<count).map { pool[(start + $0) % pool.count] }
    }

    /// Allows the pin to re-select when the hosting view receives a new server snapshot.
    private var scheduleSignature: String {
        schedule.map {
            "\($0.id)|\($0.status.rawValue)|\($0.startsAt.timeIntervalSince1970)|\($0.endsAt?.timeIntervalSince1970 ?? 0)|\($0.actualStartedAt?.timeIntervalSince1970 ?? 0)"
        }.joined(separator: ";")
    }

    private func reconcilePin(at time: Date) {
        let oldID = pinnedID
        let options = schedule.map {
            GoaliathPinCandidate(
                id: $0.id,
                startsAt: $0.startsAt,
                endsAt: $0.endsAt,
                actualStartedAt: $0.actualStartedAt,
                status: $0.status.rawValue
            )
        }
        pinnedID = GoaliathPinSelector.selectID(from: options, at: time, holding: oldID)
        if oldID != pinnedID {
            cardGroupIndex = 0
        }
    }

    private func reloadLocalSchedule() {
        guard scheduleActivities == nil else { return }
        do {
            localDrafts = try GoaliathTimelineStore.loadDrafts()
            scheduleError = nil
        } catch {
            scheduleError = "Couldn't load your schedule: \(error.localizedDescription)"
        }
        reconcilePin(at: Date())
    }

    private func changeCardGroup(_ direction: TileSlideDirection) {
        guard !rotatingPool.isEmpty, groupCount > 1 else { return }
        let step = direction == .next ? 1 : -1
        let next = (cardGroupIndex + step + groupCount) % groupCount
        withAnimation(.easeInOut(duration: 0.4)) {
            slideDirection = direction
            cardGroupIndex = next
            if let first = visibleCards.first { selectedCard = first }
        }
    }

    private func changeStatus(_ status: TimelineScheduleStatus, for item: GoaliathScheduleActivity) {
        if scheduleActivities != nil {
            // A backend-supplied schedule must stay authoritative.
            onSetScheduleStatus?(item, status)
            openedPinnedActivity = nil
            return
        }
        guard let id = item.localDraftID else { return }
        do {
            try GoaliathTimelineStore.updateScheduleStatus(id: id, to: status)
            reloadLocalSchedule()
            openedPinnedActivity = schedule.first(where: { $0.id == item.id })
            if status == .completed || status == .cancelled || status == .skipped {
                openedPinnedActivity = nil
            }
        } catch {
            scheduleError = "Couldn't update the activity: \(error.localizedDescription)"
        }
    }

    private func handleCardUpdateAction(_ action: GoaliathCardUpdateAction) async {
        do {
            switch action {
            case .thankGifter(let giftId,let message):
                try await live.thankGifter(giftId,text:message)
            case .reactToStatus(let memberId,let statusDate,let emoji):
                try await live.reactToStatus(memberId:memberId,statusDate:statusDate,emoji:emoji)
            case .commentOnStatus(let memberId,let statusDate,let text):
                try await live.commentOnStatus(memberId:memberId,statusDate:statusDate,text:text)
            case .addSuggestionToSchedule(let kind,let id,let at):
                try await live.addSuggestionToSchedule(kind,sourceId:id,at:at)
            case .ignoreSuggestion(let kind,let id):
                try await live.ignoreSuggestion(kind,sourceId:id)
            case .activity(let id,let operation):
                guard let item=live.schedule.first(where:{$0.id==id}) else {
                    throw GoaliathAPIError(status:404,message:"This activity is not on your schedule")
                }
                switch operation {
                case .open: break
                case .begin: try await live.setActivityStatus(item,to:.inProgress)
                case .confirm: try await live.setActivityStatus(item,to:.confirmed)
                case .skip: try await live.setActivityStatus(item,to:.skipped)
                case .complete: try await live.setActivityStatus(item,to:.completed)
                }
            }
        } catch { live.errorMessage=error.localizedDescription }
    }

    private func handleRequestAction(_ action: RequestPostAction) async {
        do {
            switch action {
            case .respond(let id,let text): try await live.postReply(text, postId: id)
            case .respondMedia(let id,let text,let media): try await live.postReply(text, postId: id, media: media)
            case .askForDetails(let id,let question): try await live.postReply(question, postId: id)
            case .skip(let id): try await live.dismissPost(id)
            case .report(let id,let reason,let notes): try await live.reportPost(id, reason: reason, notes: notes)
            }
        } catch { live.errorMessage = error.localizedDescription }
    }
    private func handleTipAction(_ action: TipPostAction) async {
        do {
            switch action {
            case .respond(let id,let text): try await live.postReply(text, postId: id)
            case .ignore(let id): try await live.dismissPost(id)
            case .report(let id,let reason,let notes): try await live.reportPost(id, reason: reason, notes: notes)
            case .addToSchedule(let id,let at,let target): try await live.scheduleTip(id, title: target.title, at: at)
            }
        } catch { live.errorMessage = error.localizedDescription }
    }
    private func handleCommentAction(_ action: CommentPostAction) async {
        do {
            switch action {
            case .respond(let id,let text): try await live.postReply(text, postId: id)
            case .save(let id): try await live.savePost(id)
            case .skip(let id): try await live.dismissPost(id)
            case .report(let id,let reason,let notes): try await live.reportPost(id, reason: reason, notes: notes)
            }
        } catch { live.errorMessage = error.localizedDescription }
    }

    var body: some View {
        ZStack(alignment: .leading) {
            ZStack {
                background.ignoresSafeArea()
                CardContentLayer(geometry: geometry, selectedCard: $selectedCard,
                    currentUserId: live.profile?.userId ?? "",
                    onCardUpdateAction: { action in
                        _Concurrency.Task { await handleCardUpdateAction(action) }
                    },
                    onLoadPostReplies: { try await live.replies(postId: $0) },
                    onRequestPostAction: { action in
                        _Concurrency.Task { await handleRequestAction(action) }
                    },
                    onTipPostAction: { action in
                        _Concurrency.Task { await handleTipAction(action) }
                    },
                    onCommentPostAction: { action in
                        _Concurrency.Task { await handleCommentAction(action) }
                    },
                    onSubmitForm: { response in try await live.submitQuestionnaire(response) })
                HomeOverLay(
                    geometry: geometry,
                    showMenu: $showMenu,
                    showGoals: $showGoals,
                    cardData: visibleCards,
                    selectedCard: $selectedCard,
                    currentPage: (cardGroupIndex % groupCount) + 1,
                    pageCount: groupCount,
                    slideDirection: slideDirection,
                    onPrevious: { changeCardGroup(.previous) },
                    onNext: { changeCardGroup(.next) },
                    pinnedActivity: pinnedActivity,
                    now: now,
                    onPinnedTap: { openedPinnedActivity = $0 }
                )
            }
            .disabled(showMenu)
            .blur(radius: showMenu ? 2 : 0)
            .fullScreenCover(isPresented: $showGoals) {
                PickGoalsView(geometry: geometry, showGoals: $showGoals)
            }

            if showMenu {
                Color.black.opacity(0.3).ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showMenu = false
                        }
                    }
                SideMenuView(
                    primary: primary,
                    secondary: secondary,
                    accent: accent,
                    onSelect: { destination in
                        showMenu = false
                        activeMenuDestination = destination
                    },
                    onSignOut: onSignOut == nil ? nil : {
                        showSignOutConfirmation = true
                    }
                )
                .frame(width: geometry.size.width * 0.72)
                .transition(.move(edge: .leading))
                .zIndex(1)
            }
        }
        .onAppear {
            if live.isPreviewMode {
                demoChats.configurePreview()
            } else {
                demoChats.configure(api: live.api, currentUserId: live.profile?.userId ?? "")
                _Concurrency.Task { await demoChats.refresh() }
            }
            now = Date()
            reloadLocalSchedule()
            reconcilePin(at: now)
        }
        .onChange(of: scheduleSignature) { _ in reconcilePin(at: Date()) }
        .onChange(of: cardData.map(\.cardDataId).joined(separator: ",")) { _ in
            if selectedCard.cardDataId.isEmpty, let first = cardData.first { selectedCard = first }
            if !cardData.contains(where: { $0.cardDataId == selectedCard.cardDataId }), let first=cardData.first { selectedCard = first }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                if !live.isPreviewMode {
                    _Concurrency.Task { await live.refresh(); await demoChats.refresh() }
                }
                now = Date()
                reloadLocalSchedule()
                reconcilePin(at: now)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .goaliathTimelineDidChange)
            .receive(on: RunLoop.main)) { _ in
                reloadLocalSchedule()
            }
        .onReceive(cardRotationTimer) { _ in
            let latest = Date()
            now = latest
            reconcilePin(at: latest)
            guard !showMenu, !showGoals, activeMenuDestination == nil,
                  openedPinnedActivity == nil else { return }
            changeCardGroup(.next)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showMenu)
        .confirmationDialog("Sign out of Goaliath?", isPresented: $showSignOutConfirmation, titleVisibility: .visible) {
            Button("Sign out", role: .destructive) {
                showMenu = false
                onSignOut?()
            }
        } message: {
            Text("You'll return to the welcome screen.")
        }
        .alert("Goaliath", isPresented: Binding(get:{ live.errorMessage != nil },set:{if !$0 {live.errorMessage=nil}})) {
            Button("OK",role:.cancel){live.errorMessage=nil}
        } message: { Text(live.errorMessage ?? "Something went wrong") }
        .sheet(item: $openedPinnedActivity) { captured in
            let current = schedule.first(where: { $0.id == captured.id }) ?? captured
            GoaliathPinnedActivityDetailView(
                activity: current,
                onChangeStatus: { changeStatus($0, for: current) },
                onOpenActivity: onOpenScheduleActivity,
                canUpdateStatus: current.localDraftID != nil || onSetScheduleStatus != nil
            )
        }
        .alert("Schedule update", isPresented: Binding(
            get: { scheduleError != nil },
            set: { if !$0 { scheduleError = nil } }
        )) {
            Button("OK", role: .cancel) { scheduleError = nil }
        } message: {
            Text(scheduleError ?? "Please try again.")
        }
        .fullScreenCover(item: $activeMenuDestination) { destination in
            NavigationStack {
                Group {
                    switch destination {
                    case .profile:
                        if let profile=live.profile { UserProfileView(profile: profile) }
                        else { ProgressView() }
                    case .chats: ChatView(store: demoChats)
                    case .contributions: MyContributionsView(contributions: live.contributions)
                    case .support: ContactSupportView(store: demoChats)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") { activeMenuDestination = nil }
                            .foregroundStyle(accent)
                    }
                }
            }
        }
    }
}

enum TileSlideDirection {
    case next
    case previous
}
