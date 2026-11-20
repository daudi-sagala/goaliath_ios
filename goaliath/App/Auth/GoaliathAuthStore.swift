import Foundation
import Combine

@MainActor
final class GoaliathAuthStore: ObservableObject {
    @Published private(set) var user: GoaliathAuthUser?
    @Published private(set) var restoring = true
    @Published private(set) var busy = false
    @Published var errorMessage: String?

    private let api = GoaliathAuthAPI()
    private let keychain = GoaliathKeychain()
    private var hasRestored = false

    func restoreIfNeeded() async {
        guard !hasRestored else { return }
        hasRestored = true
        restoring = true
        defer { restoring = false }

        do {
            keychain.clearLegacyToken()
            guard let token = try keychain.loadToken() else { return }
            do {
                if let verifiedUser = try await api.currentUser(token: token) {
                    user = verifiedUser
                } else {
                    try keychain.deleteToken()
                }
            } catch GoaliathAuthAPIError.server(let status, _) where status == 401 || status == 403 {
                try keychain.deleteToken()
            }
        } catch {
            // Keep the stored token on transient network failure; never trust it
            // without a successful session validation from Better Auth.
            errorMessage = error.localizedDescription
        }
    }

    func signIn(email: String, password: String) async {
        guard !busy else { return }
        busy = true
        errorMessage = nil
        defer { busy = false }

        do {
            let token = try await api.signIn(email: email, password: password)
            try await establishVerifiedSession(token: token)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signUp(name: String, email: String, password: String) async {
        guard !busy else { return }
        busy = true
        errorMessage = nil
        defer { busy = false }

        do {
            // Some Better Auth setups don't emit set-auth-token at signup.
            // A normal password sign-in is the safe fallback.
            let initialToken = try await api.signUp(name: name, email: email, password: password)
            let token: String
            if let initialToken, !initialToken.isEmpty {
                token = initialToken
            } else {
                token = try await api.signIn(email: email, password: password)
            }
            try await establishVerifiedSession(token: token)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Validate the server-side session before exposing any logged-in view.
    /// Do not persist a token that failed validation.
    private func establishVerifiedSession(token: String) async throws {
        guard let verifiedUser = try await api.currentUser(token: token) else {
            throw GoaliathAuthAPIError.invalidResponse
        }
        try keychain.saveToken(token)
        user = verifiedUser
    }

    func signOut() async {
        guard !busy else { return }
        busy = true

        // Clear local identity *before* waiting for a possibly unavailable
        // server. A remote sign-out error must not trap a user in HomeView.
        let token = try? keychain.loadToken()
        do {
            try keychain.deleteToken()
            user = nil
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            busy = false
            return
        }
        // The UI can immediately offer sign-in again, even if revocation is slow.
        busy = false
        if let token {
            // Server revocation is best effort. The keychain no longer holds
            // the bearer credential regardless of network availability.
            try? await api.signOut(token: token)
        }
    }

    func retryRestore() async {
        hasRestored = false
        errorMessage = nil
        await restoreIfNeeded()
    }
}
