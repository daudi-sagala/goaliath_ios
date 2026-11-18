import SwiftUI

struct MainView: View {
    @StateObject private var appManager = AppManager.shared
    @StateObject private var live = GoaliathLiveStore(api: GoaliathAPIClient(
        baseURL: URL(string: (Bundle.main.object(forInfoDictionaryKey: "GoaliathAPIBaseURL") as? String) ?? "http://127.0.0.1:8080/")!,
        bearerToken: { try await AppManager.shared.bearerToken() }
    ))

    var body: some View {
        GeometryReader { geometry in
            NavigationStack {
                if appManager.isRestoringSession {
                    ProgressView("Restoring session…")
                } else if appManager.isAuthenticated {
                    if let error = live.errorMessage, live.profile == nil {
                        VStack(spacing: 14) {
                            ContentUnavailableView("Could not load Goaliath",systemImage:"wifi.exclamationmark",description:Text(error))
                            Button("Retry") { _Concurrency.Task { await live.refresh() } }
                            Button("Sign out") { _Concurrency.Task { await appManager.signOut() } }
                        }
                    } else if live.profile == nil {
                        ProgressView("Connecting to Goaliath…")
                    } else {
                        HomeView(geometry: geometry,cardData:live.cards,scheduleActivities:live.schedule,
                            onSetScheduleStatus:{ activity,status in
                                _Concurrency.Task { @MainActor in
                                    do {try await live.setActivityStatus(activity,to:status)}
                                    catch {live.errorMessage = error.localizedDescription}
                                }
                            })
                        .environmentObject(live)
                    }
                } else { WelcomeView(geometry: geometry) }
            }
        }
        .task(id: appManager.authenticatedUserId) {
            live.clear()
            if appManager.isAuthenticated { await live.refresh() }
        }
    }
}
