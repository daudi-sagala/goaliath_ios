import Foundation

/// Empty signed-in home state. Never show a fictitious member or post.
enum GoaliathLiveEmptyCard {
    static let placeholder = CardData(
        cardDataId: "", cardDataTypeId: "empty", cardDataTypeTitle: "",
        cardDataType: CardDataType(cardDataTypeId: "empty", activity: nil,
            formData: nil, gift: nil, suggestedMeal: nil, message: nil,
            post: nil, task: nil, userStatus: nil, workout: nil),
        title: "",description: "",imageUrl: "",startHour: "",endHour: ""
    )
}
