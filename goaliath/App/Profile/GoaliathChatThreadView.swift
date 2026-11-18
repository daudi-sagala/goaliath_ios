import SwiftUI

struct GoaliathChatThreadView: View {
    @ObservedObject var store: GoaliathChatStore
    let conversationId: String
    @State private var messageDraft = ""
    @FocusState private var isTyping: Bool

    private var thread: GoaliathChatConversation? { store.conversation(conversationId) }
    private var messages: [GoaliathChatMessage] { thread?.messages.sorted(by: { $0.sentAt < $1.sentAt }) ?? [] }

    var body: some View {
        VStack(spacing: 0) {
            if let thread {
                header(thread)
                Divider()
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(Array(messages.enumerated()), id: \.element.id) { index, msg in
                                if index == 0 || !Calendar.current.isDate(msg.sentAt, inSameDayAs: messages[index - 1].sentAt) {
                                    Text(msg.sentAt.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(GoaliathMenuStyle.muted)
                                        .padding(.top, 10)
                                }
                                bubble(msg)
                                    .id(msg.id)
                            }
                        }
                        .padding(15)
                    }
                    .onAppear {
                        if let last = messages.last { proxy.scrollTo(last.id, anchor: .bottom) }
                        store.markRead(conversationId)
                    }
                    .onChange(of: messages.count) { _ in
                        if let last = messages.last { withAnimation { proxy.scrollTo(last.id, anchor: .bottom) } }
                    }
                }
                composer
            } else {
                ContentUnavailableView("Conversation unavailable", systemImage: "bubble.left.and.bubble.right")
            }
        }
        .background(GoaliathMenuStyle.background.ignoresSafeArea())
        .navigationTitle(thread?.isSupport == true ? "Support" : "Conversation")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func header(_ thread: GoaliathChatConversation) -> some View {
        HStack(spacing: 11) {
            GoaliathMenuAvatar(name: thread.participantName, size: 42,
                               tint: thread.isSupport ? GoaliathMenuStyle.green : GoaliathMenuStyle.accent)
            VStack(alignment: .leading, spacing: 3) {
                Text(thread.participantName).font(.headline).foregroundStyle(GoaliathMenuStyle.ink)
                Text(thread.isSupport ? "Goaliath help team" : "\(thread.participantRole) · \(thread.participantLocation)")
                    .font(.caption).foregroundStyle(GoaliathMenuStyle.muted)
            }
            Spacer()
        }
        .padding(.horizontal, 15).padding(.vertical, 10)
        .background(.white)
    }

    private func bubble(_ message: GoaliathChatMessage) -> some View {
        let mine = message.senderId == store.currentUserId
        return HStack {
            if mine { Spacer(minLength: 55) }
            VStack(alignment: .trailing, spacing: 5) {
                Text(message.body)
                    .font(.system(size: 15))
                    .foregroundStyle(mine ? Color.white : GoaliathMenuStyle.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(message.sentAt.formatted(.dateTime.hour().minute()))
                    .font(.caption2)
                    .foregroundStyle(mine ? .white.opacity(0.8) : GoaliathMenuStyle.muted)
            }
            .padding(.horizontal, 14).padding(.vertical, 11)
            .fixedSize(horizontal: false, vertical: true)
            .background(mine ? GoaliathMenuStyle.accent : Color.white,
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .frame(maxWidth: 290)
            if !mine { Spacer(minLength: 55) }
        }
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Write a message…", text: $messageDraft, axis: .vertical)
                .lineLimit(1...4)
                .focused($isTyping)
                .padding(.horizontal, 14).padding(.vertical, 11)
                .background(.white, in: RoundedRectangle(cornerRadius: 18))
                .submitLabel(.send)
                .onSubmit(send)
            Button(action: send) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(GoaliathMenuStyle.green, in: Circle())
            }
            .disabled(messageDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(messageDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
            .accessibilityLabel("Send message")
        }
        .padding(12)
        .background(.regularMaterial)
    }

    private func send() {
        store.send(messageDraft, in: conversationId)
        messageDraft = ""
    }
}
