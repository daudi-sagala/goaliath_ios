import SwiftUI

struct ChatView: View {
    @ObservedObject var store: GoaliathChatStore
    @State private var search = ""

    init(store: GoaliathChatStore) {
        self.store = store
    }

    private var filtered: [GoaliathChatConversation] {
        store.conversations
            .filter { search.isEmpty || $0.participantName.localizedCaseInsensitiveContains(search) ||
                ($0.latest?.body.localizedCaseInsensitiveContains(search) ?? false) }
            .sorted { ($0.latest?.sentAt ?? .distantPast) > ($1.latest?.sentAt ?? .distantPast) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Stay connected")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(GoaliathMenuStyle.ink)
                    Text("Your conversations with the people helping you move forward.")
                        .font(.subheadline).foregroundStyle(GoaliathMenuStyle.muted)
                }
                if store.isUsingSampleConversations {
                    Label("Sample conversations · Messages are not sent to the server", systemImage: "info.circle")
                        .font(.caption).foregroundStyle(GoaliathMenuStyle.muted)
                }
                LazyVStack(spacing: 10) {
                    ForEach(filtered) { conversation in
                        NavigationLink {
                            GoaliathChatThreadView(store: store, conversationId: conversation.id)
                        } label: {
                            conversationRow(conversation)
                        }.buttonStyle(.plain)
                    }
                    if filtered.isEmpty {
                        GoaliathMenuPanel { Text("No matching conversations").foregroundStyle(GoaliathMenuStyle.muted) }
                    }
                }
            }
            .padding(18)
        }
        .searchable(text: $search, prompt: "Search conversations")
        .background(GoaliathMenuStyle.background.ignoresSafeArea())
        .navigationTitle("My Chats")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func conversationRow(_ item: GoaliathChatConversation) -> some View {
        let unread = item.unreadCount(currentUserId: store.currentUserId)
        return HStack(spacing: 13) {
            GoaliathMenuAvatar(name: item.participantName, size: 52,
                               tint: item.isSupport ? GoaliathMenuStyle.green : GoaliathMenuStyle.accent)
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(item.participantName)
                        .font(.headline).foregroundStyle(GoaliathMenuStyle.ink)
                    Spacer(minLength: 4)
                    if let last = item.latest {
                        Text(last.sentAt.formatted(.dateTime.hour().minute()))
                            .font(.caption2).foregroundStyle(GoaliathMenuStyle.muted)
                    }
                }
                HStack(spacing: 9) {
                    Text(item.latest?.body ?? "Start a conversation")
                        .font(.subheadline)
                        .foregroundStyle(unread > 0 ? GoaliathMenuStyle.ink : GoaliathMenuStyle.muted)
                        .fontWeight(unread > 0 ? .semibold : .regular)
                        .lineLimit(2)
                    Spacer(minLength: 0)
                    if unread > 0 {
                        Text("\(unread)")
                            .font(.caption2.bold()).foregroundStyle(.white)
                            .frame(minWidth: 22, minHeight: 22)
                            .background(GoaliathMenuStyle.green, in: Circle())
                    }
                }
            }
        }
        .padding(14)
        .background(.white, in: RoundedRectangle(cornerRadius: 19))
    }
}
