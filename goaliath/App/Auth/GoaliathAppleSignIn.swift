import Foundation
import AuthenticationServices
import CryptoKit
import Security
import Combine

/// Uses native Sign in with Apple and exchanges the Apple ID token with Better Auth.
@MainActor
final class GoaliathAppleSignIn: ObservableObject {
    @Published var errorMessage: String?
    @Published var signingIn = false
    private var currentNonce: String?

    func configure(_ request: ASAuthorizationAppleIDRequest) {
        let nonce=Self.randomNonce()
        currentNonce=nonce
        request.requestedScopes=[.email,.fullName]
        request.nonce=Self.sha256(nonce)
    }

    func handle(_ result:Result<ASAuthorization,Error>) {
        switch result {
        case .failure(let error):errorMessage=error.localizedDescription
        case .success(let authorization):
            guard let apple=authorization.credential as? ASAuthorizationAppleIDCredential,
                  let data=apple.identityToken,
                  let idToken=String(data:data,encoding:.utf8),
                  let rawNonce=currentNonce else {
                errorMessage="Apple sign-in returned no identity token";return
            }
            signingIn=true
            _Concurrency.Task { @MainActor in
                defer { self.signingIn=false;self.currentNonce=nil }
                do {
                    try await AppManager.shared.signInWithApple(idToken:idToken,rawNonce:rawNonce)
                    self.errorMessage=nil
                } catch { self.errorMessage=error.localizedDescription }
            }
        }
    }

    private static func sha256(_ text:String)->String {
        SHA256.hash(data:Data(text.utf8)).map{String(format:"%02x",$0)}.joined()
    }
    private static func randomNonce(length:Int=32)->String {
        let alphabet=Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var bytes=[UInt8](repeating:0,count:length)
        guard SecRandomCopyBytes(kSecRandomDefault,bytes.count,&bytes)==errSecSuccess else {
            fatalError("Secure random number generation unavailable")
        }
        return String(bytes.map{alphabet[Int($0)%alphabet.count]})
    }
}
