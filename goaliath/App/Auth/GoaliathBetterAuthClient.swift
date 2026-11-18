import Foundation

/// Native Swift REST adapter for Better Auth
/// Better Auth's bearer plugin returns `set-auth-token` on successful sign-in.
/// Requests to /v1 use that opaque token via Authorization: Bearer.
struct GoaliathBetterAuthClient {
    static var shared: GoaliathBetterAuthClient { GoaliathBetterAuthClient() }

    var baseURL: URL {
        let configured = Bundle.main.object(forInfoDictionaryKey: "GoaliathAPIBaseURL") as? String
        // Development fallback for simulator only. Configure HTTPS for physical devices/production.
        return URL(string: configured ?? "http://127.0.0.1:8080/")!
    }

    struct SessionEnvelope: Decodable {
        let user: AuthUser
        let session: SessionInfo?
        struct AuthUser: Decodable { let id: String; let email: String?; let name: String? }
        struct SessionInfo: Decodable { let id: String }
    }

    struct Response {
        let data: Data
        let token: String?
    }

    func sendCode(email: String) async throws {
        let _: Response = try await post("email-otp/send-verification-otp", body: [
            "email": email.trimmingCharacters(in: .whitespacesAndNewlines),
            "type": "sign-in"
        ])
    }

    func signInWithCode(email: String, code: String) async throws -> Response {
        try await post("sign-in/email-otp", body: [
            "email":email.trimmingCharacters(in: .whitespacesAndNewlines),
            "otp":code.trimmingCharacters(in: .whitespacesAndNewlines)
        ])
    }

    func signInWithApple(identityToken: String, rawNonce: String) async throws -> Response {
        try await post("sign-in/social", body: [
            "provider":"apple",
            "idToken":["token":identityToken,"nonce":rawNonce]
        ])
    }

    func getSession(token: String) async throws -> SessionEnvelope? {
        let response = try await send("get-session", method:"GET", bearer:token)
        // Better Auth may return JSON `null` when no valid session exists.
        if response.data.isEmpty || String(data: response.data, encoding:.utf8)?.trimmingCharacters(in:.whitespacesAndNewlines)=="null" { return nil }
        return try JSONDecoder().decode(SessionEnvelope.self, from: response.data)
    }

    func signOut(token: String) async throws {
        let _: Response = try await post("sign-out", body: [String:String](), bearer:token)
    }

    private func post(_ path: String, body: [String:Any], bearer: String? = nil) async throws -> Response {
        try await send(path,method:"POST",body:body,bearer:bearer)
    }

    private func send(_ path: String, method: String, body: [String:Any]? = nil, bearer: String? = nil) async throws -> Response {
        guard let url = URL(string:"api/auth/\(path)",relativeTo:baseURL)?.absoluteURL else {
            throw GoaliathAPIError(status:0,message:"Invalid sign-in URL")
        }
        var req=URLRequest(url:url)
        req.httpMethod=method
        req.setValue("application/json",forHTTPHeaderField:"Accept")
        if let body {
            req.setValue("application/json",forHTTPHeaderField:"Content-Type")
            req.httpBody=try JSONSerialization.data(withJSONObject:body)
        }
        if let bearer {req.setValue("Bearer \(bearer)",forHTTPHeaderField:"Authorization")}
        let (data,response)=try await URLSession.shared.data(for:req)
        guard let http=response as? HTTPURLResponse else {throw GoaliathAPIError(status:0,message:"Authentication server did not respond")}
        guard (200..<300).contains(http.statusCode) else {
            // Avoid printing credentials or session tokens in messages/logs.
            let details=(try? JSONSerialization.jsonObject(with:data)) as? [String:Any]
            let message=(details?["message"] as? String)
                ?? ((details?["error"] as? [String:Any])?["message"] as? String)
                ?? "Unable to sign in (HTTP \(http.statusCode))"
            throw GoaliathAPIError(status:http.statusCode,message:message)
        }
        let headerToken=http.value(forHTTPHeaderField:"set-auth-token")
        let result=(try? JSONSerialization.jsonObject(with:data)) as? [String:Any]
        let jsonToken=result?["token"] as? String
        return Response(data:data,token:headerToken ?? jsonToken)
    }
}
