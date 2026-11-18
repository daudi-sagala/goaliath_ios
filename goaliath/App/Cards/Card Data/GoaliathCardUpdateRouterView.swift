import SwiftUI

/// Route the six newly redesigned types without replacing your existing
/// Request/Tip/Comment/Message or Form views.
struct GoaliathCardUpdateRouterView: View {
    let card: CardData
    let currentUserId: String

    var statusEngagement: GoaliathStatusEngagement? = nil
    var onAction: ((GoaliathCardUpdateAction) -> Void)? = nil
    var onOpenStatusChat: ((String) -> Void)? = nil
    var onLoadMemberConversation: ((String) async throws -> GoaliathMemberConversationData)? = nil
    var onMessageAction: ((GoaliathConversationAction) -> Void)? = nil

    @ViewBuilder
    var body: some View {
        switch card.cardDataTypeId {
        case "gift":
            if let gift = card.cardDataType.gift {
                GoaliathGiftCardView(gift: gift, onAction: onAction)
            } else { missing("Gift") }
        case "userStatus":
            if let status = card.cardDataType.userStatus {
                GoaliathMemberStatusCardView(
                    status: status,
                    currentUserId: currentUserId,
                    engagement: statusEngagement,
                    onAction: onAction,
                    onOpenChat: onOpenStatusChat,
                    onLoadMemberConversation: onLoadMemberConversation,
                    onMessageAction: onMessageAction
                )
            } else { missing("Member Status") }
        case "suggestedMeal":
            if let meal = card.cardDataType.suggestedMeal {
                GoaliathSuggestedMealCardView(meal: meal, onAction: onAction)
            } else { missing("Meal") }
        case "workout":
            if let workout = card.cardDataType.workout {
                GoaliathSuggestedWorkoutCardView(workout: workout, onAction: onAction)
            } else { missing("Workout") }
        case "task":
            if let task = card.cardDataType.task {
                GoaliathSuggestedTaskCardView(task: task, onAction: onAction)
            } else { missing("Task") }
        case "activity":
            if let activity = card.cardDataType.activity {
                GoaliathScheduledActivityCardView(activity: activity, onAction: onAction)
            } else { missing("Activity") }
        default:
            missing("Card")
        }
    }

    private func missing(_ name: String) -> some View {
        ContentUnavailableView(
            "\(name) unavailable",
            systemImage: "square.stack.3d.up.slash",
            description: Text("This card has no matching \(name.lowercased()) data.")
        )
    }
}
