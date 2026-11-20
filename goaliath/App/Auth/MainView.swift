import SwiftUI

/// The only app-level navigation gate:
/// restoring -> WelcomeView (signed out) -> HomeView (verified session).
/// All protected API requests use the same Better Auth token as GoaliathAuthStore.
struct MainView: View {
    @StateObject private var auth = GoaliathAuthStore()
    @StateObject private var live = GoaliathLiveStore(api: GoaliathAPIClient(
        baseURL: GoaliathAuthConfig.apiBaseURL,
        bearerToken: { try GoaliathKeychain().loadToken() }
    ))

    var body: some View {
        GeometryReader { geometry in
            Group {
                if auth.restoring {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Checking your session…")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if auth.user != nil {
                    signedInContent(geometry: geometry)
                } else {
                    WelcomeView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .environmentObject(auth)
        .environmentObject(live)
        .task { await auth.restoreIfNeeded() }
        .task(id: auth.user?.id) {
            // Avoid showing a previous account's profile, cards, or schedule.
            live.clear()
            if auth.user != nil {
                await live.refresh()
            }
        }
    }

    @ViewBuilder
    private func signedInContent(geometry: GeometryProxy) -> some View {
        if live.profile != nil {
            ZStack(alignment: .top) {
                HomeView(
                    geometry: geometry,
                    cardData: live.cards,
                    scheduleActivities: live.isPreviewMode ? nil : live.schedule,
                    onSetScheduleStatus: { activity, status in
                        _Concurrency.Task { @MainActor in
                            do { try await live.setActivityStatus(activity, to: status) }
                            catch { live.errorMessage = error.localizedDescription }
                        }
                    },
                    onSignOut: { _Concurrency.Task { await auth.signOut() } }
                )
                if live.isPreviewMode {
                    VStack(spacing: 6) {
                        Text("UI PREVIEW · Sample data · No server writes")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                        Button("Try live Home") {
//                            _Concurrency.Task { await live.retryLive() }
                        }
                        .font(.caption.weight(.semibold))
                        .buttonStyle(.borderedProminent)
                        .tint(.white)
                        .foregroundStyle(.black)
                        .disabled(live.loading)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.78), in: RoundedRectangle(cornerRadius: 14))
                    .padding(.top, 8)
                }
            }
        } else if let error = live.errorMessage {
            VStack(spacing: 18) {
                ContentUnavailableView(
                    "Your account is signed in",
                    systemImage: "wifi.exclamationmark",
                    description: Text("We couldn't load your Goaliath data. \(error)")
                )
                Button("Retry loading Home") {
                    _Concurrency.Task { await live.refresh() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(live.loading)

                #if DEBUG
                Button("Preview Home with sample data") {
                    live.usePreviewData()
                }
                .buttonStyle(.bordered)
                .disabled(live.loading)
                Text("Development-only UI preview. It does not bypass sign-in or send changes to the server.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                #endif

                Button("Sign out") {
                    _Concurrency.Task { await auth.signOut() }
                }
                .foregroundStyle(.secondary)
            }
            .padding(28)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(spacing: 14) {
                ProgressView()
                Text("Loading your Goaliath home…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button("Sign out") { _Concurrency.Task { await auth.signOut() } }
                    .font(.subheadline)
            }
        }
    }
}
