import Foundation

// IMPORTANT: If your project already declares UserProfile, merge these fields into
// that declaration instead of adding a second struct named UserProfile.
struct UserProfile: Codable, Identifiable, Equatable {
    var userId: String
    var username: String
    var firstName: String
    var lastName: String
    var userImageURL: String
    var bio: String
    var location: String
    var joinedAt: Date
    var lastActiveAt: Date?
    var followersCount: Int
    var followingCount: Int
    var isVerified: Bool
    var interests: [String]
    var tokens: UserToken
    var goals: [UserGoal]

    var id: String { userId }
    var fullName: String {
        let text = [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
        return text.isEmpty ? username : text
    }
    var activeGoals: [UserGoal] { goals.filter { $0.status == .active } }
}

// Server balance is authoritative. Do not derive spendable balance from
// a partial/paginated transaction history, or mint tokens for accepted gifts.
struct UserToken: Codable, Equatable {
    var balance: Int
    var earnedTotal: Int
    var purchasedTotal: Int
    var giftsReceivedTotal: Int
    var giftsSentTotal: Int
    var spentTotal: Int
    var recentTransactions: [UserTokenTransaction]
}

enum UserTokenTransactionType: String, Codable, CaseIterable {
    case earned, purchased, giftReceived, giftSent, spent, expired, refunded

    var title: String {
        switch self {
        case .earned: return "Earned"
        case .purchased: return "Purchased"
        case .giftReceived: return "Gift received"
        case .giftSent: return "Gift sent"
        case .spent: return "Used"
        case .expired: return "Expired"
        case .refunded: return "Refunded"
        }
    }
}

struct UserTokenTransaction: Codable, Identifiable, Equatable {
    var id: String
    var type: UserTokenTransactionType
    // Signed delta: receiving/earning/buying positive; sending/spending negative.
    var amount: Int
    var note: String
    var occurredAt: Date
    var relatedUserId: String?
}

enum UserGoalStatus: String, Codable, CaseIterable {
    case active, achieved, paused, expired
}

enum UserGoalCategory: String, Codable, CaseIterable {
    case career, health, learning, social, financial, personal

    var title: String { rawValue.capitalized }
    var symbol: String {
        switch self {
        case .career: return "briefcase.fill"
        case .health: return "heart.fill"
        case .learning: return "book.fill"
        case .social: return "person.2.fill"
        case .financial: return "chart.line.uptrend.xyaxis"
        case .personal: return "star.fill"
        }
    }
}

struct UserGoal: Codable, Identifiable, Equatable {
    var id: String
    var title: String
    var description: String
    var category: UserGoalCategory
    var status: UserGoalStatus
    var currentValue: Double
    var targetValue: Double
    var unit: String
    var startedAt: Date
    var targetDate: Date?
    var isPublic: Bool

    var progress: Double {
        guard targetValue > 0 else { return 0 }
        return min(1, max(0, currentValue / targetValue))
    }
}

// Local-only conversation models so the existing Card Message model is unchanged.
struct GoaliathChatMessage: Identifiable, Codable, Equatable {
    var id: String
    var senderId: String
    var body: String
    var sentAt: Date
    var isRead: Bool
}

struct GoaliathChatConversation: Identifiable, Codable, Equatable {
    var id: String
    var participantId: String
    var participantName: String
    var participantInitials: String
    var participantRole: String
    var participantLocation: String
    var isSupport: Bool
    var messages: [GoaliathChatMessage]

    var latest: GoaliathChatMessage? { messages.max(by: { $0.sentAt < $1.sentAt }) }
    func unreadCount(currentUserId: String) -> Int {
        messages.filter { $0.senderId != currentUserId && !$0.isRead }.count
    }
}

enum GoaliathContributionType: String, CaseIterable, Codable, Identifiable {
    case request, tip, comment, meal, workout, task, activity
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var symbol: String {
        switch self {
        case .request: return "hand.raised.fill"
        case .tip: return "lightbulb.fill"
        case .comment: return "bubble.left.fill"
        case .meal: return "fork.knife"
        case .workout: return "figure.run"
        case .task: return "checklist"
        case .activity: return "calendar"
        }
    }
}

enum GoaliathContributionAudience: String, Codable {
    case everyone, city, localArea, network
    var label: String {
        switch self {
        case .everyone: return "Everyone"
        case .city: return "City"
        case .localArea: return "Local area"
        case .network: return "My network"
        }
    }
}

struct GoaliathContribution: Identifiable, Codable, Equatable {
    var id: String
    var type: GoaliathContributionType
    var title: String
    var detail: String
    var sharedAt: Date
    var audience: GoaliathContributionAudience
    var areaName: String?
    var replyCount: Int
    var appreciationCount: Int
}
