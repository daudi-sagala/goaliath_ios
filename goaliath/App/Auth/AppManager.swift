import Foundation
import Combine

/// Single Better Auth session authority for the iOS client.
/// Source of identity is always the server-validated Better Auth session.
@MainActor
final class AppManager: ObservableObject {
    static let shared = AppManager()
    @Published private(set) var isAuthenticated = false
    @Published private(set) var authenticatedUserId = ""
    @Published private(set) var isRestoringSession = true
    @Published private(set) var emailCodeRequested = false

    private let auth = GoaliathBetterAuthClient.shared
    private var currentToken: String?

    private init() {
        _Concurrency.Task { await restoreSession() }
    }

    func bearerToken() async throws -> String? {
        currentToken
    }

    /// On app launch we verify any stored session before unlocking protected screens.
    func restoreSession() async {
        defer { isRestoringSession=false }
        guard let token=GoaliathAuthKeychain.load() else { return }
        do {
            if let session=try await auth.getSession(token:token) {
                currentToken=token
                authenticatedUserId=session.user.id
                isAuthenticated=true
            } else { GoaliathAuthKeychain.clear() }
        } catch let error as GoaliathAPIError where error.status==401 || error.status==403 {
            GoaliathAuthKeychain.clear()
        } catch {
            // On temporary network failure, don't erase the stored session.
            // User remains signed out until they explicitly retry restoration.
        }
    }

    func requestEmailCode(_ email: String) async throws {
        try await auth.sendCode(email:email)
        emailCodeRequested=true
    }

    func signInWithEmailCode(email:String,code:String) async throws {
        let reply=try await auth.signInWithCode(email:email,code:code)
        try await establishSession(reply)
        emailCodeRequested=false
    }

    func signInWithApple(idToken:String,rawNonce:String) async throws {
        let reply=try await auth.signInWithApple(identityToken:idToken,rawNonce:rawNonce)
        try await establishSession(reply)
    }

    private func establishSession(_ response:GoaliathBetterAuthClient.Response) async throws {
        guard let token=response.token,!token.isEmpty else {
            throw GoaliathAPIError(status:0,message:"Authentication succeeded but no bearer session was returned. Confirm the Better Auth bearer plugin is enabled.")
        }
        guard let session=try await auth.getSession(token:token) else {
            throw GoaliathAPIError(status:401,message:"Unable to validate the new sign-in session")
        }
        try GoaliathAuthKeychain.save(token)
        currentToken=token
        authenticatedUserId=session.user.id
        isAuthenticated=true
        isRestoringSession=false
    }

    func signOut() async {
        if let token=currentToken { try? await auth.signOut(token:token) }
        // Local credentials are always cleared even if offline.
        GoaliathAuthKeychain.clear()
        currentToken=nil
        authenticatedUserId=""
        isAuthenticated=false
        emailCodeRequested=false
    }
}
