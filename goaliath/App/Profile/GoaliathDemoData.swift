import Foundation

// All names, amounts, chats, and contributions below are DESIGN PREVIEW DATA.
enum GoaliathMenuDemoData {
    private static func ago(_ seconds: TimeInterval) -> Date { Date().addingTimeInterval(-seconds) }
    private static func later(_ seconds: TimeInterval) -> Date { Date().addingTimeInterval(seconds) }

    static let profile = UserProfile(
        userId: "demo-current-user", username: "alexm", firstName: "Alex", lastName: "Morgan",
        userImageURL: "", bio: "Building meaningful connections, one goal at a time.",
        location: "Philadelphia, PA", joinedAt: ago(180 * 86400), lastActiveAt: Date(),
        followersCount: 184, followingCount: 96, isVerified: false,
        interests: ["Career", "Fitness", "Learning", "Community"],
        tokens: UserToken(
            balance: 145, earnedTotal: 75, purchasedTotal: 100,
            giftsReceivedTotal: 20, giftsSentTotal: 15, spentTotal: 30,
            recentTransactions: [
                .init(id: "tok-1", type: .earned, amount: 25, note: "Helped a member find a referral", occurredAt: ago(3600 * 4), relatedUserId: nil),
                .init(id: "tok-2", type: .giftReceived, amount: 20, note: "Gift from Jordan", occurredAt: ago(86400), relatedUserId: "jordan"),
                .init(id: "tok-3", type: .giftSent, amount: -15, note: "Gift to Maya", occurredAt: ago(86400 * 2), relatedUserId: "maya"),
                .init(id: "tok-4", type: .purchased, amount: 100, note: "Token purchase", occurredAt: ago(86400 * 4), relatedUserId: nil),
                .init(id: "tok-5", type: .spent, amount: -30, note: "Expanded request reach", occurredAt: ago(86400 * 5), relatedUserId: nil),
                .init(id: "tok-6", type: .earned, amount: 50, note: "Helpful tips and contributions", occurredAt: ago(86400 * 8), relatedUserId: nil),
                .init(id: "tok-7", type: .expired, amount: -5, note: "Expired earned tokens", occurredAt: ago(86400 * 11), relatedUserId: nil)
            ]
        ),
        goals: [
            .init(id: "goal-1", title: "Find a finance role", description: "Build my network and land interviews.", category: .career, status: .active, currentValue: 7, targetValue: 10, unit: "steps", startedAt: ago(86400 * 24), targetDate: later(86400 * 45), isPublic: true),
            .init(id: "goal-2", title: "Run a 5K", description: "Train consistently with friends.", category: .health, status: .active, currentValue: 3.5, targetValue: 5, unit: "km", startedAt: ago(86400 * 18), targetDate: later(86400 * 35), isPublic: true),
            .init(id: "goal-3", title: "Learn Spanish", description: "Have a basic conversation confidently.", category: .learning, status: .active, currentValue: 18, targetValue: 30, unit: "lessons", startedAt: ago(86400 * 40), targetDate: later(86400 * 65), isPublic: false)
        ]
    )

    static func conversations() -> [GoaliathChatConversation] {
        let me = profile.userId
        func msg(_ id: String, _ from: String, _ body: String, _ before: TimeInterval, _ read: Bool = true) -> GoaliathChatMessage {
            .init(id: id, senderId: from, body: body, sentAt: ago(before), isRead: read)
        }
        return [
            .init(id: "chat-jon", participantId: "jon", participantName: "Jon Doe", participantInitials: "JD", participantRole: "Member", participantLocation: "Philadelphia, PA", isSupport: false, messages: [
                msg("j1", "jon", "Hi Alex! I saw your finance goal and wanted to reach out.", 7200),
                msg("j2", me, "Thanks Jon! I'd really appreciate any advice.", 6900),
                msg("j3", "jon", "My team may have an opening. Would you like an introduction?", 3600, false)
            ]),
            .init(id: "chat-maya", participantId: "maya", participantName: "Maya Chen", participantInitials: "MC", participantRole: "Member", participantLocation: "Philadelphia, PA", isSupport: false, messages: [
                msg("m1", me, "Did you have any tips for preparing the presentation?", 103000),
                msg("m2", "maya", "I put together a quick list of suggestions for you.", 91000),
                msg("m3", "maya", "Happy to review it together this weekend!", 85000, false)
            ]),
            .init(id: "chat-jordan", participantId: "jordan", participantName: "Jordan Lee", participantInitials: "JL", participantRole: "Member", participantLocation: "Camden, NJ", isSupport: false, messages: [
                msg("k1", "jordan", "Thanks for sharing the workout idea!", 180000),
                msg("k2", me, "You're welcome! Let me know how it goes.", 170000)
            ]),
            .init(id: supportConversationID, participantId: "goaliath-support", participantName: "Goaliath Support", participantInitials: "GS", participantRole: "Support team", participantLocation: "Goaliath", isSupport: true, messages: [
                msg("s1", "goaliath-support", "Welcome to Goaliath Support! How can we help you today?", 260000),
                msg("s2", me, "How can I see which tokens were gifted to me?", 258000),
                msg("s3", "goaliath-support", "Open My Profile and tap Token history to see gifts, purchases, and earned tokens.", 250000)
            ])
        ]
    }
    static let supportConversationID = "chat-support"

    static let contributions: [GoaliathContribution] = [
        .init(id:"c1", type:.request, title:"Looking for finance interview connections", detail:"I'm hoping to connect with hiring managers or people working in financial analysis.", sharedAt:ago(3600*3), audience:.city, areaName:"Philadelphia, PA", replyCount:8, appreciationCount:21),
        .init(id:"c2", type:.tip, title:"Three ways to prepare for a networking call", detail:"Research the person, bring two thoughtful questions, and send a personal follow-up.", sharedAt:ago(86400), audience:.everyone, areaName:nil, replyCount:13, appreciationCount:42),
        .init(id:"c3", type:.comment, title:"My advice on learning a language", detail:"Find someone to practice with for just ten minutes every day.", sharedAt:ago(86400*2), audience:.network, areaName:nil, replyCount:3, appreciationCount:11),
        .init(id:"c4", type:.meal, title:"Quick vegetable power bowl", detail:"A simple homemade lunch idea with a flexible ingredient list.", sharedAt:ago(86400*4), audience:.localArea, areaName:"Fishtown", replyCount:6, appreciationCount:19),
        .init(id:"c5", type:.workout, title:"30-minute community walk", detail:"A beginner-friendly lunchtime walk with optional walking partners.", sharedAt:ago(86400*5), audience:.city, areaName:"Philadelphia, PA", replyCount:5, appreciationCount:15),
        .init(id:"c6", type:.task, title:"Reach out to an old colleague", detail:"One helpful step to reconnect with your professional network.", sharedAt:ago(86400*6), audience:.everyone, areaName:nil, replyCount:4, appreciationCount:8),
        .init(id:"c7", type:.activity, title:"Saturday coffee meetup", detail:"Meeting fellow Goaliath members to swap ideas and encouragement.", sharedAt:ago(86400*8), audience:.network, areaName:nil, replyCount:10, appreciationCount:26),
        .init(id:"c8", type:.request, title:"Seeking someone to practice Spanish with", detail:"Looking for a friendly language-exchange partner for weekly chats.", sharedAt:ago(86400*11), audience:.everyone, areaName:nil, replyCount:16, appreciationCount:33),
        .init(id:"c9", type:.tip, title:"How I keep a consistent morning routine", detail:"Make the first task easy, repeat it at the same time, and track small wins.", sharedAt:ago(86400*13), audience:.everyone, areaName:nil, replyCount:9, appreciationCount:28)
    ]
}
