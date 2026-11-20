import Foundation

struct GoaliathAuthUser: Decodable, Identifiable {
    let id: String
    let name: String
    let email: String
    let image: String?
}

private struct GoaliathSessionResponse: Decodable {
    let user: GoaliathAuthUser?
    let session: GoaliathSessionMarker?
}

private struct GoaliathSessionMarker: Decodable {
    let id: String
}

private struct GoaliathAPIErrorBody: Decodable {
    let message: String?
    let code: String?
    let error: NestedError?

    struct NestedError: Decodable {
        let message: String?
    }
}

private struct GoaliathAuthTokenBody: Decodable {
    let token: String?
}

enum GoaliathAuthAPIError: LocalizedError {
    case invalidResponse
    case server(status: Int, message: String)
    case missingToken

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Unexpected response from Goaliath. Please try again."
        case .missingToken:
            return "Login succeeded without a usable session. Please try again."
        case .server(let status, let message):
            if status == 502 || status == 503 || status == 504 {
                return "Goaliath's server is temporarily unavailable. Please try again."
            }
            if status == 429 {
                return "Too many attempts. Please try again later."
            }
            return message
        }
    }
}

struct GoaliathAuthAPI {
    private let session: URLSession

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpShouldSetCookies = false
        configuration.httpCookieStorage = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        session = URLSession(configuration: configuration)
    }

    func signUp(name: String, email: String, password: String) async throws -> String? {
        let data = try JSONEncoder().encode(SignUpBody(name: name, email: email, password: password))
        let (responseData, response) = try await perform(path: "/api/auth/sign-up/email", method: "POST", body: data)
        return bearerToken(from: response, body: responseData)
    }

    func signIn(email: String, password: String) async throws -> String {
        let data = try JSONEncoder().encode(SignInBody(email: email, password: password, rememberMe: true))
        let (responseData, response) = try await perform(path: "/api/auth/sign-in/email", method: "POST", body: data)
        guard let token = bearerToken(from: response, body: responseData) else {
            throw GoaliathAuthAPIError.missingToken
        }
        return token
    }

    func currentUser(token: String) async throws -> GoaliathAuthUser? {
        let (data, _) = try await perform(path: "/api/auth/get-session", method: "GET", token: token)
        if String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines) == "null" {
            return nil
        }
        do {
            let result = try JSONDecoder().decode(GoaliathSessionResponse.self, from: data)
            guard result.session != nil else { return nil }
            return result.user
        } catch {
            throw GoaliathAuthAPIError.invalidResponse
        }
    }

    func signOut(token: String) async throws {
        _ = try await perform(path: "/api/auth/sign-out", method: "POST", body: Data("{}".utf8), token: token)
    }

    private func bearerToken(from response: HTTPURLResponse, body: Data) -> String? {
        let header = response.value(forHTTPHeaderField: "set-auth-token")?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if let header, !header.isEmpty { return header }
        let jsonToken = (try? JSONDecoder().decode(GoaliathAuthTokenBody.self, from: body))?.token
        return jsonToken?.isEmpty == false ? jsonToken : nil
    }

    private func perform(
        path: String,
        method: String,
        body: Data? = nil,
        token: String? = nil
    ) async throws -> (Data, HTTPURLResponse) {
        guard let url = URL(string: String(path.dropFirst()), relativeTo: GoaliathAuthConfig.apiBaseURL)?.absoluteURL else {
            throw GoaliathAuthAPIError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 25
        request.httpShouldHandleCookies = false
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, urlResponse) = try await session.data(for: request)
        guard let response = urlResponse as? HTTPURLResponse else {
            throw GoaliathAuthAPIError.invalidResponse
        }
        guard (200...299).contains(response.statusCode) else {
            let error = try? JSONDecoder().decode(GoaliathAPIErrorBody.self, from: data)
            let fallback = response.statusCode == 401 ? "Invalid email or password, or your session has expired." : "Request failed (HTTP \(response.statusCode))."
            throw GoaliathAuthAPIError.server(
                status: response.statusCode,
                message: error?.message ?? error?.error?.message ?? fallback
            )
        }
        return (data, response)
    }
}

private struct SignUpBody: Encodable {
    let name: String
    let email: String
    let password: String
}

private struct SignInBody: Encodable {
    let email: String
    let password: String
    let rememberMe: Bool
}
