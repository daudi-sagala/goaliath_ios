import Foundation

enum GoaliathAuthConfig {
    /// Keep one backend URL for both Better Auth and /v1 requests.
    /// Change GoaliathAPIBaseURL in Info.plist if the Render service moves.
    static var apiBaseURL: URL {
        let value = Bundle.main.object(forInfoDictionaryKey: "GoaliathAPIBaseURL") as? String
        let fallback = "https://goaliath-backend.onrender.com/"
        let candidate = URL(string: value ?? fallback)
        guard let url = candidate, let scheme = url.scheme?.lowercased(),
              scheme == "https" || (scheme == "http" && ["localhost", "127.0.0.1"].contains(url.host ?? ""))
        else { return URL(string: fallback)! }
        return url
    }

    // Reserved for a later launch, when provider configuration is complete.
    static let appleSignInEnabled = false
    static let googleSignInEnabled = false
}
