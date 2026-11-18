import Foundation

// iOS client for the integrated Goaliath backend.
// Add once to the app target. Better Auth owns sessions; auth API calls live in GoaliathBetterAuthClient.
struct GoaliathAPIError: LocalizedError {
    let status: Int
    let message: String
    var errorDescription: String? { message }
}

struct GoaliathAPIClient {
    let baseURL: URL
    /// Returns the current Better Auth opaque bearer session from iOS Keychain.
    let bearerToken: () async throws -> String?
    /// Only for localhost development with server AUTH_MODE=dev; NEVER use in production.
    var localDevUserID: String? = nil

    init(baseURL: URL, bearerToken: @escaping () async throws -> String?, localDevUserID: String? = nil) {
        self.baseURL = baseURL
        self.bearerToken = bearerToken
        self.localDevUserID = localDevUserID
    }

    func request<Result: Decodable>(
        _ path: String,
        method: String = "GET",
        body: (any Encodable)? = nil,
        idempotencyKey: String? = nil
    ) async throws -> Result {
        guard let url = URL(string: path, relativeTo: baseURL)?.absoluteURL else {
            throw GoaliathAPIError(status: 0, message: "Invalid API URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try GoaliathJSON.encoder.encode(AnyEncodable(body))
        }
        if let idempotencyKey { request.setValue(idempotencyKey, forHTTPHeaderField: "Idempotency-Key") }
        if let token = try await bearerToken(), !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else if let id = localDevUserID, ["127.0.0.1", "localhost"].contains(url.host ?? "") {
            request.setValue(id, forHTTPHeaderField: "x-dev-user-id")
        } else {
            throw GoaliathAPIError(status: 401, message: "Please sign in to Goaliath")
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw GoaliathAPIError(status: 0, message: "No HTTP response") }
        guard (200..<300).contains(http.statusCode) else {
            let envelope = try? GoaliathJSON.decoder.decode(ServerErrorEnvelope.self, from: data)
            throw GoaliathAPIError(status: http.statusCode, message: envelope?.error.message ?? "Server error \(http.statusCode)")
        }
        return try GoaliathJSON.decoder.decode(Result.self, from: data)
    }
}

private struct ServerErrorEnvelope: Decodable {
    let error: ServerError
    struct ServerError: Decodable { let code: String; let message: String }
}

private struct AnyEncodable: Encodable {
    let encodeValue: (Encoder) throws -> Void
    init(_ value: any Encodable) { encodeValue = value.encode(to:) }
    func encode(to encoder: Encoder) throws { try encodeValue(encoder) }
}

enum GoaliathJSON {
    static let encoder: JSONEncoder = {
        let e = JSONEncoder(); e.dateEncodingStrategy = .iso8601; return e
    }()
    static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let standard = ISO8601DateFormatter()
        standard.formatOptions = [.withInternetDateTime]
        d.dateDecodingStrategy = .custom { decoder in
            let text = try decoder.singleValueContainer().decode(String.self)
            if let date = fractional.date(from: text) ?? standard.date(from: text) { return date }
            throw DecodingError.dataCorruptedError(in: try decoder.singleValueContainer(), debugDescription: "Invalid ISO timestamp: \(text)")
        }
        return d
    }()
}

struct GoaliathBootstrap: Decodable {
    let profile: UserProfile
    let schedule: [LiveScheduleDTO]
    let feed: [CardData]
    let conversations: [GoaliathChatConversation]
    let contributions: [GoaliathContribution]
}

struct LiveScheduleDTO: Decodable, Identifiable {
    let id: String
    let title: String
    let details: String
    let kind: TimelineCreationKind
    let startsAt: Date
    let endsAt: Date?
    let status: TimelineScheduleStatus
    let actualStartedAt: Date?
    let location: String?

    var activity: GoaliathScheduleActivity {
        GoaliathScheduleActivity(id: id, title: title, details: details, kind: kind,
                                 startsAt: startsAt, endsAt: endsAt, status: status,
                                 actualStartedAt: actualStartedAt, location: location,
                                 localDraftID: nil)
    }
}

struct LiveActivitiesEnvelope: Decodable { let activities: [LiveScheduleDTO] }
struct LiveProfileEnvelope: Decodable { let profile: UserProfile }
struct LiveFeedEnvelope: Decodable { let cards: [CardData] }
struct LiveContributionsEnvelope: Decodable { let contributions: [GoaliathContribution] }
struct LiveConversationsEnvelope: Decodable { let conversations: [GoaliathChatConversation] }
struct LiveWalletEnvelope: Decodable { let wallet: UserToken }
struct LiveActivityEnvelope: Decodable { let activity: LiveScheduleDTO }
struct LivePostResult: Decodable { let post: PostCreated }
struct PostCreated: Decodable { let id: String; let subject: String; let type: String }
struct LiveGoalResult: Decodable { let goal: UserGoal }
struct LiveCreatedActivity: Decodable { let activity: LiveScheduleDTO }
struct LiveGiftResult: Decodable { let giftId: String; let tokenCount: Int; let replayed: Bool }
struct LiveRepliesEnvelope: Decodable { let replies: [RequestPostReply] }
struct LiveCreatedMessage: Decodable { let message: GoaliathChatMessage }
struct LiveMessagesEnvelope: Decodable { let messages: [GoaliathChatMessage] }
struct LiveMatchesEnvelope: Decodable {
    let intentId: String
    let matchCount: Int
    let matches: [LiveMatch]
}
struct LiveMatch: Decodable, Identifiable {
    let candidateId: String
    let title: String
    let description: String
    let score: Int
    let reasons: [String]
    var id: String { candidateId }
}
