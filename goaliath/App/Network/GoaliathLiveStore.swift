import SwiftUI
import Foundation
import Combine

/// Backend-authoritative data source. Nothing is synthesized from demo data.
@MainActor
final class GoaliathLiveStore: ObservableObject {
    @Published private(set) var profile: UserProfile?
    @Published private(set) var cards: [CardData] = []
    @Published private(set) var schedule: [GoaliathScheduleActivity] = []
    @Published private(set) var contributions: [GoaliathContribution] = []
    @Published private(set) var conversations: [GoaliathChatConversation] = []
    @Published private(set) var loading = false
    @Published var errorMessage: String?
    /// True only after explicit selection of the DEBUG sample-data preview.
    @Published private(set) var isPreviewMode = false

    let api: GoaliathAPIClient
    init(api: GoaliathAPIClient) { self.api = api }

    /// Remove prior account content before a new member signs in.
    func clear() {
        profile=nil; cards=[]; schedule=[]; contributions=[]; conversations=[]
        errorMessage=nil
        isPreviewMode = false
    }

    #if DEBUG
    /// Signed-in, UI-only escape hatch when /v1/bootstrap is unavailable.
    /// These are conspicuously fake records, never mixed into real accounts.
    func usePreviewData() {
        isPreviewMode = true
        profile = GoaliathMenuDemoData.profile
        cards = CardSampleData.cards
        schedule = []
        contributions = GoaliathMenuDemoData.contributions
        conversations = GoaliathMenuDemoData.conversations()
        errorMessage = nil
    }
    #endif

    private func requireLiveData() throws {
        guard !isPreviewMode else {
            throw GoaliathAPIError(status: 0,
                message: "This is a sample-data UI preview. Changes are not saved. Retry the live backend to make changes.")
        }
    }

    func refresh() async {
        guard !isPreviewMode else { return }
        loading = true; defer { loading = false }
        do {
            let snapshot: GoaliathBootstrap = try await api.request("v1/bootstrap")
            profile = snapshot.profile
            cards = snapshot.feed
            schedule = snapshot.schedule.map(\.activity)
            contributions = snapshot.contributions
            conversations = snapshot.conversations
            errorMessage = nil
        } catch { errorMessage = error.localizedDescription }
    }

    func refreshSchedule() async throws {
        try requireLiveData()
        let result: LiveActivitiesEnvelope = try await api.request("v1/timeline")
        schedule = result.activities.map(\.activity)
    }
    func setActivityStatus(_ item: GoaliathScheduleActivity, to status: TimelineScheduleStatus) async throws {
        try requireLiveData()
        let body = ["status": status.rawValue]
        let _: LiveActivityEnvelope = try await api.request("v1/timeline/\(item.id)/status", method: "PATCH", body: body)
        try await refreshSchedule()
    }
    func refreshFeed() async throws {
        try requireLiveData()
        let result: LiveFeedEnvelope = try await api.request("v1/feed")
        cards = result.cards
    }

    /// Send SwiftUI FormResponse as [itemId: String] to its assigned questionnaire.
    /// The server checks assignment, field validation, and duplicate submissions.
    func submitQuestionnaire(_ response: FormResponse) async throws {
        try requireLiveData()
        guard UUID(uuidString: response.formDataId) != nil else {
            throw GoaliathAPIError(status: 400, message: "Invalid questionnaire identifier")
        }
        let _: QuestionnaireSubmitEnvelope = try await api.request(
            "v1/questionnaires/\(response.formDataId)/responses",
            method: "POST",
            body: QuestionnaireAnswersEnvelope(answers: response.answers)
        )
        try await refreshFeed()
    }
    func refreshProfile() async throws {
        try requireLiveData()
        let result: LiveProfileEnvelope = try await api.request("v1/profile")
        profile = result.profile
    }

    /// Routes an existing AddToTimelineSheet draft to the correct server API.
    /// Never turns a gift label into a token transfer: gifting needs a recipient/amount.
    func publish(_ draft: TimelineCreationDraft) async throws {
        try requireLiveData()
        var media = GoaliathMediaLinks(image_urls: draft.image_urls, video_urls: draft.video_urls, gif_urls: draft.gif_urls)
        if !draft.attachments.isEmpty {
            guard [.activity, .meal, .workout, .task, .request, .tip, .connection, .learning, .shopping, .place].contains(draft.kind) else {
                throw GoaliathAPIError(status: 400, message: "Uploads are not supported for this item type")
            }
            guard draft.visibilityScope == .everyone else {
                throw GoaliathAPIError(status: 400, message: "Device uploads create public media URLs. Choose Everyone or use links with appropriate access restrictions.")
            }
            for attachment in draft.attachments {
                let file = try GoaliathTimelineStore.attachmentURL(attachment, draftID: draft.id)
                let uploaded = try await api.uploadMedia(fileURL: file)
                switch uploaded.kind {
                case "image": media.image_urls.append(uploaded.url)
                case "gif": media.gif_urls.append(uploaded.url)
                case "video": media.video_urls.append(uploaded.url)
                default: throw GoaliathAPIError(status: 500, message: "Unsupported upload response")
                }
            }
        }
        guard media.total <= 12, media.image_urls.count <= 8, media.video_urls.count <= 8, media.gif_urls.count <= 8 else {
            throw GoaliathAPIError(status: 400, message: "Maximum 12 media attachments (8 per type)")
        }
        let visibility = Self.scope(draft.visibilityScope)
        let title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        switch draft.kind {
        case .activity, .meal, .workout, .task:
            var body = CreateLiveSchedule(kind: draft.kind.rawValue, title: title,
                details: draft.description, startsAt: draft.startsAt,
                endsAt: draft.expiresAt, scope: visibility, areaName: draft.visibilityArea)
            body.image_urls = media.image_urls; body.video_urls = media.video_urls; body.gif_urls = media.gif_urls
            let _: LiveCreatedActivity = try await api.request("v1/timeline", method: "POST", body: body)
            try await refreshSchedule()
        case .request, .tip:
            var body = CreateLivePost(type: draft.kind.rawValue, subject: title, body: draft.description,
                scope: visibility, areaName: draft.visibilityArea, expiresAt: draft.expiresAt)
            body.image_urls = media.image_urls; body.video_urls = media.video_urls; body.gif_urls = media.gif_urls
            let _: LivePostResult = try await api.request("v1/posts", method: "POST", body: body)
            try await refreshFeed()
            let c: LiveContributionsEnvelope = try await api.request("v1/contributions")
            contributions = c.contributions
        case .goal:
            // V1 goals support only owner-private or public. Reject narrower
            // audiences rather than silently publishing a city/network goal globally.
            guard visibility == "private" || visibility == "everyone" else {
                throw GoaliathAPIError(status: 0,
                    message: "Goal sharing currently supports Private or Everyone. Choose one of those audiences before publishing.")
            }
            let body = CreateLiveGoal(title: title, description: draft.description,
                category: "personal", targetDate: draft.expiresAt, isPublic: visibility == "everyone")
            let _: LiveGoalResult = try await api.request("v1/goals", method: "POST", body: body)
            try await refreshProfile()
        case .connection, .learning, .shopping, .place:
            // An intent/search is not a scheduled activity. This publishes it as a request.
            var body = CreateLivePost(type: "request", subject: title, body: draft.description,
                scope: visibility, areaName: draft.visibilityArea, expiresAt: draft.expiresAt)
            body.image_urls = media.image_urls; body.video_urls = media.video_urls; body.gif_urls = media.gif_urls
            let _: LivePostResult = try await api.request("v1/posts", method: "POST", body: body)
            try await refreshFeed()
        case .gift:
            throw GoaliathAPIError(status: 0, message: "Choose a recipient and a token amount in the Send Gift flow before transferring tokens.")
        }
    }
    static func scope(_ s: TimelineVisibilityScope) -> String {
        switch s {
        case .privateOnly: return "private"
        case .connections: return "myNetwork"
        case .localArea: return "localArea"
        case .city: return "city"
        case .everyone: return "everyone"
        }
    }
    func sendGift(to receiver: String, count: Int, note: String) async throws {
        try requireLiveData()
        let body = CreateLiveGift(receiverId: receiver, tokenCount: count, message: note)
        let _: LiveGiftResult = try await api.request("v1/tokens/gifts", method: "POST", body: body,
                                                  idempotencyKey: UUID().uuidString)
        try await refreshProfile()
    }
    func postReply(_ body: String, postId: String, media: GoaliathMediaLinks = GoaliathMediaLinks()) async throws {
        try requireLiveData()
        let _: LiveReplyResult = try await api.request("v1/posts/\(postId)/replies", method: "POST", body: GoaliathMessageWithMedia(body:body,media:media))
    }
    func replies(postId: String) async throws -> [RequestPostReply] {
        if isPreviewMode { return [] }
        let result: LiveRepliesEnvelope = try await api.request("v1/posts/\(postId)/replies")
        return result.replies
    }
    func loadMatches(for intentID: String) async throws -> [LiveMatch] {
        if isPreviewMode { return [] }
        let result: LiveMatchesEnvelope = try await api.request("v1/intents/\(intentID)/matches")
        return result.matches
    }
}

struct LiveReplyResult: Decodable { let reply: RequestPostReply }
private struct CreateLiveSchedule: Encodable {
    let kind, title, details: String
    let startsAt: Date
    let endsAt: Date?
    let scope: String
    let areaName: String?
    var image_urls: [String] = []
    var video_urls: [String] = []
    var gif_urls: [String] = []
}
private struct CreateLivePost: Encodable {
    let type, subject, body, scope: String
    let areaName: String?
    let expiresAt: Date?
    var image_urls: [String] = []
    var video_urls: [String] = []
    var gif_urls: [String] = []
}
private struct GoaliathMessageWithMedia: Encodable {
    let body: String
    let image_urls: [String]
    let video_urls: [String]
    let gif_urls: [String]
    init(body: String, media: GoaliathMediaLinks) { self.body=body; image_urls=media.image_urls; video_urls=media.video_urls; gif_urls=media.gif_urls }
}
private struct CreateLiveGoal: Encodable {
    let title, description, category: String
    let targetDate: Date?
    let isPublic: Bool
}
private struct CreateLiveGift: Encodable {
    let receiverId: String
    let tokenCount: Int
    let message: String
}

private struct LiveActionAcknowledgement: Decodable {
    let dismissed: Bool?
    let reported: Bool?
    let saved: Bool?
}
extension GoaliathLiveStore {
    func dismissPost(_ postId: String) async throws {
        try requireLiveData()
        let _: LiveActionAcknowledgement = try await api.request("v1/posts/\(postId)/dismiss", method: "POST", body: [String:String]())
        try await refreshFeed()
    }
    func reportPost(_ postId: String, reason: String, notes: String) async throws {
        try requireLiveData()
        let _: LiveActionAcknowledgement = try await api.request("v1/posts/\(postId)/report",method:"POST",body:["reason":reason,"notes":notes])
        try await refreshFeed()
    }
    func savePost(_ postId: String) async throws {
        try requireLiveData()
        let _: LiveActionAcknowledgement = try await api.request("v1/posts/\(postId)/save",method:"POST",body:[String:String]())
        try await refreshFeed()
    }
    func scheduleTip(_ postId: String, title: String, at date: Date) async throws {
        try requireLiveData()
        // Tip reminder is a private task with link in details. It does not duplicate
        // a meal/workout automatically: those require their typed scheduling views.
        let body = CreateLiveSchedule(kind:"task",title:title,details:"Follow up on tip \(postId)",
                                      startsAt:date,endsAt:nil,scope:"private",areaName:nil)
        let _: LiveCreatedActivity = try await api.request("v1/timeline",method:"POST",body:body)
        try await refreshSchedule()
    }
}

private struct LiveThanksResult: Decodable { let thanked: Bool; let replayed: Bool }
private struct LiveSuggestionIgnored: Decodable { let ignored: Bool }
private struct LiveCommentAdded: Decodable { let commentId: String }
private struct LiveReactionAdded: Decodable { let reacted: Bool }
extension GoaliathLiveStore {
    func thankGifter(_ giftId: String, text: String) async throws {
        try requireLiveData()
        let _: LiveThanksResult = try await api.request("v1/gifts/\(giftId)/thank", method:"POST", body:["message":text])
    }
    func reactToStatus(memberId: String, statusDate: String, emoji: String) async throws {
        try requireLiveData()
        let _: LiveReactionAdded = try await api.request("v1/statuses/member/\(memberId)/react", method:"POST",body:["statusDate":statusDate,"emoji":emoji])
    }
    func commentOnStatus(memberId: String, statusDate: String, text: String) async throws {
        try requireLiveData()
        let _: LiveCommentAdded = try await api.request("v1/statuses/member/\(memberId)/comments",method:"POST",body:["statusDate":statusDate,"body":text])
    }
    func addSuggestionToSchedule(_ kind: GoaliathSuggestionKind, sourceId: String, at: Date) async throws {
        try requireLiveData()
        let body = CreateSuggestionSchedule(kind:kind.rawValue,sourceId:sourceId,startsAt:at)
        let _: LiveCreatedActivity = try await api.request("v1/suggestions/schedule",method:"POST",body:body)
        try await refreshSchedule()
    }
    func ignoreSuggestion(_ kind: GoaliathSuggestionKind, sourceId: String) async throws {
        try requireLiveData()
        let _: LiveSuggestionIgnored = try await api.request("v1/suggestions/ignore",method:"POST",
            body:["kind":kind.rawValue,"sourceId":sourceId])
        try await refreshFeed()
    }
}
private struct CreateSuggestionSchedule: Encodable {
    let kind: String
    let sourceId: String
    let startsAt: Date
}

// Dedicated Codable envelopes so no global [String: Any] encoding is required.
private struct QuestionnaireAnswersEnvelope: Encodable { let answers: [String: String] }
private struct QuestionnaireSubmitEnvelope: Decodable { let responseId: String }
