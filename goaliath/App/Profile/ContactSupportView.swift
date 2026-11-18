import SwiftUI

struct ContactSupportView: View {
    @ObservedObject var store: GoaliathChatStore
    @State private var supportID: String?
    @State private var errorMessage: String?
    init(store: GoaliathChatStore) { self.store = store }
    var body: some View {
        Group {
            if let supportID {
                GoaliathChatThreadView(store: store,conversationId: supportID)
            } else if let errorMessage {
                ContentUnavailableView("Support unavailable",systemImage:"exclamationmark.bubble",description:Text(errorMessage))
            } else { ProgressView("Opening Support…") }
        }
        .task {
            guard supportID == nil else { return }
            do { supportID = try await store.openSupportConversation() }
            catch { errorMessage = error.localizedDescription }
        }
    }
}
