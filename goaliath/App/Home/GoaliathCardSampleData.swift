import Foundation

/// 27 preview cards: three each for all nine CardDataType payloads.
/// Add this file to the same target as your existing models.
enum CardSampleData {
    static let cards: [CardData] = {
        var results: [CardData] = []
        // Cycle through all nine types before repeating any one type.
        // Consequently, every five consecutive cards have five distinct types.
        // The first five are Activity, Message, Workout, Meal, and User Status.
        let kinds = [
            "activity", "message", "workout", "suggestedMeal", "userStatus",
            "post", "gift", "task", "formData"
        ]
        for example in 0..<3 {
            for kind in kinds {
                let slot = results.count
                let start = 8 + (slot % 12)
                let end = start + 1
                let entry = content[kind]![example]
                let identifier = "sample-\(kind)-\(example + 1)"
                let type = makeType(kind: kind, index: example, id: identifier)
                results.append(CardData(
                    cardDataId: identifier,
                    cardDataTypeId: kind,
                    cardDataTypeTitle: displayNames[kind]!,
                    cardDataType: type,
                    title: entry.0,
                    description: entry.1,
                    imageUrl: kind == "gift" ? "" : photo(entry.2),
                    startHour: String(format: "%02d:00", start),
                    endHour: String(format: "%02d:00", end)
                ))
            }
        }
        return results
    }()

    /// Useful for SwiftUI previews: `CardSampleData.cards(for: "post")`.
    static func cards(for type: String) -> [CardData] {
        cards.filter { $0.cardDataTypeId == type }
    }

    private static let displayNames = [
        "activity": "Activity", "formData": "Form", "gift": "Gift",
        "suggestedMeal": "Suggested Meal", "message": "Message", "post": "Post",
        "task": "Task", "userStatus": "User Status", "workout": "Workout"
    ]

    private static let content: [String: [(String, String, String)]] = [
        "activity": [
            ("Neighborhood coffee meetup", "Meet people working toward similar career goals.", "photo-1521017432531-fbd92d768814"),
            ("Community volunteering", "Join a small team to make a local difference.", "photo-1559027615-cd4628902d4a"),
            ("Weekend hiking group", "Explore a trail with new friends.", "photo-1551632811-561732d1e306")
        ],
        "formData": [
            ("What are your goals?", "Tell the network what you want to achieve.", "photo-1454165804606-c3d57bc86b40"),
            ("Find your people", "Choose the communities you'd like to connect with.", "photo-1529156069898-49953e39b3ac"),
            ("Plan your week", "Share when you are available to participate.", "photo-1506784983877-45594efa4cbe")
        ],
        "gift": [
            ("Maya gifted you 15 tokens", "15 tokens from Maya to you, with an encouraging note.", "photo-1513201099705-a9746e1e201f"),
            ("Jordan gifted you 25 tokens", "25 tokens from Jordan to celebrate your milestone.", "photo-1549465220-1a8b9238cd48"),
            ("Alex gifted you 10 tokens", "10 tokens from Alex to thank you for an introduction.", "photo-1512909006721-3d6018887383")
        ],
        "suggestedMeal": [
            ("Avocado toast & eggs", "A quick breakfast with protein and healthy fats.", "photo-1525351484163-7529414344d8"),
            ("Chicken grain bowl", "A colorful, balanced lunch idea.", "photo-1512621776951-a57141f2eefd"),
            ("Salmon & roasted vegetables", "A simple dinner to cook with friends.", "photo-1467003909585-2f8a72700288")
        ],
        "message": [
            ("Coffee this week?", "Maya: Let's connect about the design community.", "photo-1529156069898-49953e39b3ac"),
            ("Your introduction", "Jordan: I know someone who may be able to help.", "photo-1521737711867-e3b97375f902"),
            ("Saturday plans", "Alex: Are you joining the group walk?", "photo-1551632811-561732d1e306")
        ],
        "post": [
            ("Looking for a finance mentor", "A neighbor is seeking guidance on a career transition.", "photo-1454165804606-c3d57bc86b40"),
            ("Finished my first 5K!", "Celebrate a community member's accomplishment.", "photo-1552674605-db6ffd4facb5"),
            ("Anyone learning Swift?", "Join a discussion and find an accountability partner.", "photo-1515879218367-8466d910aaa4")
        ],
        "task": [
            ("Update your resume", "Set aside some time to refresh your experience.", "photo-1486312338219-ce68d2c6f44d"),
            ("Reach out to a mentor", "Send a thoughtful introduction today.", "photo-1516321318423-f06f85e504b3"),
            ("Read for 20 minutes", "Make a small step toward your learning goal.", "photo-1497633762265-9d179a990aa6")
        ],
        "userStatus": [
            ("Maya is at a coffee shop", "Open to meeting fellow designers nearby.", "photo-1442512595331-e89e73853f31"),
            ("Jordan finished a workout", "A new personal best for the week.", "photo-1538805060514-97d9cc17730c"),
            ("Alex is studying", "Making progress on a coding project.", "photo-1516321318423-f06f85e504b3")
        ],
        "workout": [
            ("Morning yoga flow", "A gentle 30-minute session to start the day.", "photo-1544367567-0f2fcb009e0b"),
            ("Group strength training", "Build strength together at the gym.", "photo-1534438327276-14e5300c3a48"),
            ("Evening social run", "A friendly 5K at a conversational pace.", "photo-1552674605-db6ffd4facb5")
        ]
    ]

    private static func photo(_ id: String) -> String {
        "https://images.unsplash.com/\(id)?auto=format&fit=crop&w=900&q=80"
    }

    private static func avatar(_ number: Int) -> String {
        "https://i.pravatar.cc/300?img=\(number)"
    }

    private static func makeType(kind: String, index: Int, id: String) -> CardDataType {
        CardDataType(
            cardDataTypeId: kind,
            activity: kind == "activity" ? makeActivity(index, id) : nil,
            formData: kind == "formData" ? makeForm(index, id) : nil,
            gift: kind == "gift" ? makeGift(index, id) : nil,
            suggestedMeal: kind == "suggestedMeal" ? makeMeal(index, id) : nil,
            message: kind == "message" ? makeMessage(index, id) : nil,
            post: kind == "post" ? makePost(index, id) : nil,
            task: kind == "task" ? makeTask(index, id) : nil,
            userStatus: kind == "userStatus" ? makeStatus(index) : nil,
            workout: kind == "workout" ? makeWorkout(index, id) : nil
        )
    }

    private static func makeActivity(_ i: Int, _ id: String) -> Activity {
        let entry = content["activity"]![i]
        return Activity(
            activityId: id, title: entry.0, date: "2026-11-12",
            startTime: ["09:00", "13:00", "16:00"][i],
            endTime: ["10:00", "15:00", "18:00"][i],
            location: ["Community cafe", "Community center", "Local trailhead"][i],
            description: entry.1, mainImageUrl: photo(entry.2),
            activityType: ["social", "volunteering", "outdoors"][i],
            activityMeals: [], activityWorkout: [], activityTask: [],
            status: "upcoming", creatorId: "user-\(i + 10)", viewedByUser: i == 0
        )
    }

    private static func makeForm(_ i: Int, _ id: String) -> FormData {
        let entry = content["formData"]![i]
        let questions: [[FormItem]] = [
            [FormItem(itemId: "goal-text", type: .text, title: "Your main goal", subtitle: "Be as specific as you can", placeholder: "e.g. Find a job in finance", isRequired: true, validation: FormValidation(minLength: 3, maxLength: 140)),
             FormItem(itemId: "goal-date", type: .date, title: "Target date")],
            [FormItem(itemId: "interest-section", type: .section, title: "Your interests"),
             FormItem(itemId: "interests", type: .multiSelect, title: "Choose some communities", options: [
                 FormOption(optionId: "career", title: "Career", icon: "briefcase", value: "career"),
                 FormOption(optionId: "fitness", title: "Fitness", icon: "figure.run", value: "fitness"),
                 FormOption(optionId: "learning", title: "Learning", icon: "book", value: "learning")
             ])],
            [FormItem(itemId: "availability", type: .singleSelect, title: "When are you usually free?", isRequired: true, options: [
                FormOption(optionId: "morning", title: "Mornings", value: "morning"),
                FormOption(optionId: "afternoon", title: "Afternoons", value: "afternoon"),
                FormOption(optionId: "evening", title: "Evenings", value: "evening")
            ]),
             FormItem(itemId: "remote", type: .toggle, title: "I'm open to virtual meetups", defaultValue: "true")]
        ]
        return FormData(formDataId: id, title: entry.0, subtitle: "Help us tailor your experience", description: entry.1, imageURL: photo(entry.2), items: questions[i], submitTitle: "Save", allowSkip: i != 0)
    }

    private static func makeGift(_ i: Int, _ id: String) -> Gift {
        let giverNames = ["Maya", "Jordan", "Alex"]
        let giver = GiftGiver(userId: "sender-\(i)", username: giverNames[i].lowercased(), firstName: giverNames[i], lastName: "Friend", userImageURL: avatar(11 + i))
        let receiver = GiftReceiver(userId: "current-user", username: "you", firstName: "You", lastName: "", userImageURL: avatar(5))
        let tokenAmounts = [15, 25, 10]
        let messages = [
            "Keep going—you've got this!",
            "Congratulations on your milestone!",
            "Thanks for making that introduction!"
        ]
        return Gift(
            giftId: id,
            tokenCount: tokenAmounts[i],
            giftGiver: giver,
            giftReceiver: receiver,
            giftDate: "2026-11-12T10:00:00Z",
            status: ["sent"],
            giftMessage: messages[i],
            modifiedAt: ["2026-11-12T10:00:00Z"]
        )
    }

    private static func makeMessage(_ i: Int, _ id: String) -> Message {
        Message(messageId: id, subject: content["message"]![i].0, messageImageURLs: [], messageVideoURLs: [], messageGIFMedia: [:], conversationId: "conversation-\(i)", senderId: "sender-\(i)", senderName: ["Maya", "Jordan", "Alex"][i], senderImage: avatar(11 + i), createdAt: "2026-11-12T10:00:00Z", readStatus: i == 0 ? "unread" : "read")
    }

    private static func makePost(_ i: Int, _ id: String) -> Post {
        let entry = content["post"]![i]
        return Post(
            postId: id, postType: ["request", "achievement", "discussion"][i], subject: entry.0,
            postMainMediaURL: photo(entry.2), postMainMediaType: "image", postMediaCount: 1,
            postImageURLs: [photo(entry.2)], postVideoURLs: [], postGIFMedia: [:],
            posterId: "poster-\(i)", posterName: ["Taylor", "Sam", "Riley"][i],
            posterImageURL: avatar(20 + i), posterLocation: "Philadelphia, PA", posterRole: "Member",
            posterConversationId: "post-conversation-\(i)", createdAt: "2026-11-12T09:00:00Z",
            updatedAt: [], expiresAt: "2026-12-12T09:00:00Z", status: ["active"],
            tags: [["career", "mentorship"], ["running", "milestone"], ["swift", "learning"]][i],
            responderImageUrls: [avatar(30), avatar(31)], postResponseCount: [4, 12, 7][i],
            postSavedCount: [3, 8, 5][i], savedPostStatus: "notSaved",
            postSelectedMealIds: [], postWorkoutIds: [], postActivityIds: [], postTaskIds: []
        )
    }

    private static func makeTask(_ i: Int, _ id: String) -> Task {
        let entry = content["task"]![i]
        return Task(taskId: id, title: entry.0, description: entry.1, createdBy: "current-user", createdAt: "2026-11-12T08:00:00Z", taskImageUrls: [photo(entry.2)], taskVideoUrls: [], taskGIFMedia: [:])
    }

    private static func makeStatus(_ i: Int) -> UserStatus {
        let entry = content["userStatus"]![i]
        let name = ["Maya", "Jordan", "Alex"][i]
        return UserStatus(userId: "status-user-\(i)", username: name.lowercased(), firstName: name, lastName: "Friend", phone: "", joined: "2026-01-01", userImageURL: avatar(11 + i), statusType: ["social", "fitness", "learning"][i], userStatusImageURLs: [photo(entry.2)], userStatusVideoURLs: [], userStatusGIFMedia: [:], userStatusDate: "2026-11-12T15:00:00Z", userStatusTitle: entry.0, userStatusDescription: entry.1)
    }

    private static func makeWorkout(_ i: Int, _ id: String) -> Workout {
        let entry = content["workout"]![i]
        let trainer = Trainer(userId: "trainer-\(i)", name: ["Casey", "Morgan", "Jamie"][i], location: "Philadelphia, PA", userImageUrl: avatar(40 + i), userDescription: "Friendly community coach", conversationId: "trainer-conversation-\(i)", onlineStatus: "online", rating: "4.9")
        let member = WorkoutParticipant(userId: "participant-\(i)", name: "Community Member", userImage: avatar(25 + i), userLocation: "Philadelphia, PA", userRole: "Member", userBio: "Working toward fitness goals", userConversationId: "participant-conversation-\(i)", userStatus: "joined", statusDescription: "Ready to go", nearestActivityTime: "2026-11-12T18:00:00Z", nearestActivityId: id)
        let comment = WorkoutComment(commentId: "comment-\(i)", userId: member.userId, name: member.name, userImage: member.userImage, userLocation: member.userLocation, userRole: member.userRole, userBio: member.userBio, userConversationId: member.userConversationId, userStatus: member.userStatus, commentText: "Looking forward to this!", createdAt: "2026-11-12T09:00:00Z", workoutId: id)
        return Workout(workoutId: id, workoutImageUrls: [photo(entry.2)], workoutTitle: entry.0, workoutLocation: i == 1 ? "Community gym" : "Neighborhood park", workoutCategories: [["yoga", "mobility"], ["strength", "group"], ["running", "cardio"]][i], selectedWorkoutTime: "2026-11-12T18:00:00Z", workoutDurationInSeconds: [1800, 2700, 2100][i], workoutDurationText: ["30 min", "45 min", "35 min"][i], workoutDescription: entry.1, workoutDistance: i == 2 ? "5 km" : "0 km", workoutTrainer: trainer, workoutStatus: "scheduled", workoutCommentsCount: 1, lastComment: comment, participants: [member], workoutFormat: "group", rating: "4.9", createdAt: "2026-11-10T12:00:00Z", user: Workout.User(userId: "current-user", name: "You", location: "Philadelphia, PA", avatarURL: avatar(5)))
    }

    private static func makeMeal(_ i: Int, _ id: String) -> SuggestedMeal {
        let entry = content["suggestedMeal"]![i]
        let names = ["Maya", "Jordan", "Alex"]
        let ingredientNames = [["Avocado", "Eggs", "Whole-grain bread"], ["Chicken", "Quinoa", "Spinach"], ["Salmon", "Broccoli", "Sweet potato"]][i]
        let ingredients = ingredientNames.enumerated().map { position, name in
            SuggestedMeal.Meal.Ingredient(id: UUID(), ingredientId: "\(id)-ingredient-\(position)", name: name, quantity: 1, units: "portion", isEssential: true)
        }
        let creator = SuggestedMeal.Meal.RecipeCreator(userId: "meal-user-\(i)", name: names[i], location: "Philadelphia, PA", userImageUrl: avatar(11 + i), userDescription: "Home cook", conversationId: "meal-conversation-\(i)", onlineStatus: "online")
        let lastMade = SuggestedMeal.Meal.LastMade(userId: creator.userId, name: creator.name, location: creator.location, userImageUrl: creator.userImageUrl, userDescription: creator.userDescription, conversationId: creator.conversationId, onlineStatus: creator.onlineStatus, madeAt: "2026-11-10T18:00:00Z")
        let recipe = SuggestedMeal.Meal.Recipe(recipeId: "\(id)-recipe", name: entry.0, description: entry.1, ingredients: ingredients, instructions: ["Prepare all ingredients.", "Cook or assemble the ingredients.", "Serve and enjoy."], prepTime: 10, cookTime: [10, 25, 30][i], servings: 2, difficulty: "Easy", cuisine: "Everyday", tags: ["balanced", "homemade"], rating: "4.8", imageUrls: [photo(entry.2)], videoUrls: [], webUrl: "", recipeNutrition: SuggestedMeal.Meal.RecipeNutrition(calories: [380, 520, 560][i], protein: [18, 42, 40][i], carbs: [32, 48, 38][i], fat: [20, 16, 24][i], sugar: 5, sodium: 400, fiber: 7), createdAt: "2026-11-10T12:00:00Z", lastMade: lastMade, recipeCreator: creator)
        let meal = SuggestedMeal.Meal(mealId: "\(id)-meal", title: entry.0, imageURL: photo(entry.2), estimatedTime: [20, 35, 40][i], priceRange: "$$", recipes: [recipe], ingredients: ingredients, sources: [])
        return SuggestedMeal(id: UUID(), suggestedMealId: id, title: entry.0, imageUrl: photo(entry.2), estimatedTime: [20, 35, 40][i], user: SuggestedMeal.User(userId: creator.userId, name: creator.name, location: creator.location, avatarURL: creator.userImageUrl), meals: [meal], mealUserData: SuggestedMeal.MealUserData(copyCount: [12, 25, 8][i], userAvatars: [avatar(20), avatar(21)]), createdAt: "2026-11-10T12:00:00Z", copyStatus: SuggestedMeal.CopyStatus(status: "notCopied", timestamp: ""), priceRange: "$$")
    }
}
