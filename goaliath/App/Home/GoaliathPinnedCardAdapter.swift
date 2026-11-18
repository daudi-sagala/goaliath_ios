import Foundation

/// An adapter, NOT a second visual tile implementation.  Converts the selected
/// scheduled activity to the existing CardData type, so BottomOverLay renders
/// it using its original tile geometry, image/icon style and tap behavior.
/// The synthetic ID is intercepted by HomeOverLay and never opened as feed content.
enum GoaliathPinnedCardAdapter {
    static func cardID(for item: GoaliathScheduleActivity) -> String {
        "goaliath-pinned::\(item.id)"
    }

    static func makeCard(from item: GoaliathScheduleActivity, at now: Date) -> CardData {
        let label: String
        if item.status == .inProgress {
            label = "IN PROGRESS"
        } else if item.startsAt <= now {
            label = "READY"
        } else {
            label = "UP NEXT"
        }

        // Use the underlying schedule activity's kind, but present it through
        // the existing Activity card type. We intercept the tap so this
        // display-only card never becomes an editable Activity model.
        let day = DateFormatter()
        day.locale = Locale(identifier: "en_US_POSIX")
        day.dateFormat = "yyyy-MM-dd"

        let clock = DateFormatter()
        clock.locale = Locale(identifier: "en_US_POSIX")
        clock.dateFormat = "HH:mm"

        let startText = clock.string(from: item.startsAt)
        let endText = clock.string(from: item.endsAt ?? item.startsAt.addingTimeInterval(3600))
        let titleWithPin = "📌 \(item.title)"

        let activity = Activity(
            activityId: cardID(for: item),
            title: item.title,
            date: day.string(from: item.startsAt),
            startTime: startText,
            endTime: endText,
            location: item.location ?? "",
            description: item.details,
            mainImageUrl: "",
            activityType: item.kind.rawValue,
            activityMeals: [],
            activityWorkout: [],
            activityTask: [],
            status: item.status.rawValue,
            creatorId: "",
            viewedByUser: true
        )

        let payload = CardDataType(
            cardDataTypeId: "activity",
            activity: activity,
            formData: nil,
            gift: nil,
            suggestedMeal: nil,
            message: nil,
            post: nil,
            task: nil,
            userStatus: nil,
            workout: nil
        )

        return CardData(
            cardDataId: cardID(for: item),
            cardDataTypeId: "activity",
            cardDataTypeTitle: label,
            cardDataType: payload,
            title: titleWithPin,
            description: item.details,
            imageUrl: "",
            startHour: startText,
            endHour: endText
        )
    }
}
