import Foundation
import Combine

/// Same type name and public methods as your original ChatStore, but server-backed.
@MainActor
final class GoaliathChatStore: ObservableObject {
    @Published private(set) var conversations: [GoaliathChatConversation] = []
    @Published private(set) var errorMessage: String?
    private(set) var currentUserId: String = ""
    private var api: GoaliathAPIClient?

    init(currentUserId: String = "", conversations: [GoaliathChatConversation] = []) {
        self.currentUserId = currentUserId
        self.conversations = conversations
    }
    func configure(api: GoaliathAPIClient, currentUserId: String) {
        self.api = api; self.currentUserId = currentUserId
    }
    func refresh() async {
        guard let api else { return }
        do {
            let result: LiveConversationsEnvelope = try await api.request("v1/conversations")
            conversations = result.conversations
            errorMessage = nil
        } catch { errorMessage = error.localizedDescription }
    }
    func conversation(_ id: String) -> GoaliathChatConversation? {
        conversations.first(where: { $0.id == id })
    }
    func send(_ body: String, in conversationId: String) {
        let message = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty, let api else { return }
        _Concurrency.Task { @MainActor in
            do {
                let _: LiveCreatedMessage = try await api.request(
                    "v1/conversations/\(conversationId)/messages",method:"POST",body:["body": message])
                await refresh()
            } catch { errorMessage = error.localizedDescription }
        }
    }
    func markRead(_ conversationId: String) {
        guard let api else { return }
        _Concurrency.Task { @MainActor in
            do {
                let _: LiveReadResult = try await api.request("v1/conversations/\(conversationId)/read",method:"POST",body: [String:String]())
                await refresh()
            } catch { errorMessage = error.localizedDescription }
        }
    }
    func openSupportConversation() async throws -> String {
        guard let api else { throw GoaliathAPIError(status: 0, message:"Missing API client") }
        let result: LiveConversationCreated = try await api.request("v1/conversations/support",method:"POST",body:[String:String]())
        await refresh()
        return result.conversationId
    }
}
struct LiveReadResult: Decodable { let markedRead: Bool }
struct LiveConversationCreated: Decodable { let conversationId: String }
