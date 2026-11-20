import SwiftUI

// MARK: - Main card content router
// Uses the CardData / CardDataType models already in your project.
// All interactions in this file are LOCAL PREVIEW STATE; no server calls occur.

struct CardContentLayer: View {
    var geometry: GeometryProxy
    @Binding var selectedCard: CardData

    // Optional integration inputs; supply authenticated ID and real backend handlers.
    var currentUserId: String = ""
    var statusEngagement: GoaliathStatusEngagement? = nil
    var onCardUpdateAction: ((GoaliathCardUpdateAction) -> Void)? = nil
    var onOpenStatusChat: ((String) -> Void)? = nil
    var onLoadMemberConversation: ((String) async throws -> GoaliathMemberConversationData)? = nil
    var onMessageAction: ((GoaliathConversationAction) -> Void)? = nil
    var onLoadPostReplies: ((String) async throws -> [RequestPostReply])? = nil
    var onRequestPostAction: ((RequestPostAction) -> Void)? = nil
    var onTipPostAction: ((TipPostAction) -> Void)? = nil
    var onCommentPostAction: ((CommentPostAction) -> Void)? = nil
    var onSubmitForm: ((FormResponse) async throws -> Void)? = nil

    private let customCardTypes: Set<String> = [
        "post", "message", "gift", "userStatus", "suggestedMeal",
        "workout", "task", "activity"
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if selectedCard.cardDataId.isEmpty {
                    ContentUnavailableCard()
                } else {
                    if !customCardTypes.contains(selectedCard.cardDataTypeId) {
                        CardHero(card: selectedCard)
                    }
                    detailView
                }
            }
            .id(selectedCard.cardDataId)
            .frame(maxWidth: 650)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.top, 76)
            .padding(.bottom, 116)
        }
        .frame(width: geometry.size.width, height: geometry.size.height)
        .background(CardPalette.background)
    }

    @ViewBuilder
    private var detailView: some View {
        switch selectedCard.cardDataTypeId {
        case "gift", "userStatus", "suggestedMeal", "workout", "task", "activity":
            GoaliathCardUpdateRouterView(
                card: selectedCard,
                currentUserId: currentUserId,
                statusEngagement: statusEngagement,
                onAction: onCardUpdateAction,
                onOpenStatusChat: onOpenStatusChat,
                onLoadMemberConversation: onLoadMemberConversation,
                onMessageAction: onMessageAction
            )
        case "post", "message":
            GoaliathPostMessageCardRouterView(
                card: selectedCard,
                currentUserId: currentUserId,
                onLoadReplies: onLoadPostReplies,
                onRequestAction: onRequestPostAction,
                onTipAction: onTipPostAction,
                onCommentAction: onCommentPostAction,
                onMessageAction: onMessageAction,
               
               
            )
        case "formData":
            if let data = selectedCard.cardDataType.formData {
                FormCardDetails(form: data, onSubmit: onSubmitForm)
            } else {
                MissingCardPayload()
            }
        default:
            MissingCardPayload()
        }
    }
}

// MARK: - Shared styling / building blocks

private enum CardPalette {
    static let background = Color(red: 0.929, green: 0.965, blue: 0.976) // #EDF6F9
    static let ink = Color(red: 0.149, green: 0.231, blue: 0.333)        // #263B55
    static let muted = Color(red: 0.388, green: 0.490, blue: 0.569)      // #637D91
    static let accent = Color(red: 0.322, green: 0.435, blue: 0.647)     // #526FA5
}

private struct CardPanel<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) { content }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white, in: RoundedRectangle(cornerRadius: 18))
    }
}

private struct RemoteCardImage: View {
    let urlString: String
    var height: CGFloat = 175
    var fallbackIcon: String = "photo"

    var body: some View {
        GeometryReader { proxy in
            AsyncImage(url: URL(string: urlString)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                case .empty, .failure:
                    ZStack {
                        CardPalette.background
                        Image(systemName: fallbackIcon)
                            .font(.system(size: 32))
                            .foregroundStyle(CardPalette.accent)
                    }
                @unknown default:
                    CardPalette.background
                }
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityHidden(true)
    }
}

private struct CardHero: View {
    let card: CardData

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RemoteCardImage(urlString: card.imageUrl, height: 205,
                            fallbackIcon: iconForCard(card.cardDataTypeId))
            Label(card.cardDataTypeTitle, systemImage: iconForCard(card.cardDataTypeId))
                .font(.subheadline.weight(.bold))
                .foregroundStyle(CardPalette.accent)
            Text(card.title)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(CardPalette.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(card.description)
                .font(.subheadline)
                .foregroundStyle(CardPalette.muted)
                .fixedSize(horizontal: false, vertical: true)
            Label("\(card.startHour) – \(card.endHour)", systemImage: "clock")
                .font(.caption)
                .foregroundStyle(CardPalette.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private func iconForCard(_ type: String) -> String {
    switch type {
    case "activity": return "calendar"
    case "formData": return "list.clipboard"
    case "gift": return "star.circle.fill"
    case "suggestedMeal": return "fork.knife"
    case "message": return "bubble.left.fill"
    case "post": return "person.2.fill"
    case "task": return "checkmark.circle"
    case "userStatus": return "person.crop.circle"
    case "workout": return "figure.run"
    default: return "square.grid.2x2"
    }
}

private struct CardField: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundStyle(CardPalette.accent)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.caption).foregroundStyle(CardPalette.muted)
                Text(value).font(.subheadline.weight(.medium))
                    .foregroundStyle(CardPalette.ink)
            }
            Spacer(minLength: 0)
        }
    }
}

private struct CardSectionTitle: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.headline)
            .foregroundStyle(CardPalette.ink)
    }
}

private struct CardAvatar: View {
    let imageURL: String
    let name: String
    var size: CGFloat = 46

    var body: some View {
        AsyncImage(url: URL(string: imageURL)) { phase in
            if case .success(let image) = phase {
                image.resizable().scaledToFill()
            } else {
                ZStack {
                    CardPalette.background
                    Text(String(name.prefix(1)).uppercased())
                        .font(.headline).foregroundStyle(CardPalette.accent)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityLabel(name)
    }
}

private struct CardChips: View {
    let values: [String]

    var body: some View {
        if !values.isEmpty {
            FlowingChips(values: values)
        }
    }
}

// Native wrapping without external flow-layout libraries (iOS 16+).
private struct FlowingChips: View {
    let values: [String]

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 6) { chips }
            VStack(alignment: .leading, spacing: 7) { chips }
        }
    }

    @ViewBuilder private var chips: some View {
        ForEach(Array(values.enumerated()), id: \.offset) { pair in
            Text(pair.element)
                .font(.caption.weight(.semibold))
                .foregroundStyle(CardPalette.accent)
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(CardPalette.background, in: Capsule())
        }
    }
}

private struct CardImageStrip: View {
    let urls: [String]

    var body: some View {
        if !urls.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 9) {
                    ForEach(Array(urls.enumerated()), id: \.offset) { pair in
                        RemoteCardImage(urlString: pair.element, height: 108)
                            .frame(width: 132)
                    }
                }
            }
        }
    }
}

private struct ContentUnavailableCard: View {
    var body: some View {
        CardPanel {
            Label("Select a card below", systemImage: "hand.tap")
                .font(.headline)
                .foregroundStyle(CardPalette.ink)
            Text("Choose one of the five tiles to see its details.")
                .foregroundStyle(CardPalette.muted)
        }
    }
}

private struct MissingCardPayload: View {
    var body: some View {
        CardPanel {
            Label("Card details unavailable", systemImage: "exclamationmark.circle")
                .foregroundStyle(CardPalette.muted)
            Text("This card has no matching content payload.")
                .font(.subheadline)
                .foregroundStyle(CardPalette.muted)
        }
    }
}

// MARK: - 1. Activity

private struct ActivityCardDetails: View {
    let activity: Activity
    @State private var interested = false

    var body: some View {
        CardPanel {
            CardSectionTitle(text: "Activity details")
            CardField(icon: "calendar", title: "Date", value: activity.date)
            CardField(icon: "clock", title: "Time",
                      value: "\(activity.startTime) – \(activity.endTime)")
            CardField(icon: "mappin.and.ellipse", title: "Location", value: activity.location)
            CardField(icon: "tag", title: "Type", value: activity.activityType.capitalized)
            CardField(icon: "person", title: "Organizer", value: activity.creatorId)
            CardChips(values: [activity.status.capitalized])
        }
        if !activity.activityMeals.isEmpty || !activity.activityWorkout.isEmpty || !activity.activityTask.isEmpty {
            CardPanel {
                CardSectionTitle(text: "Included in this activity")
                ForEach(activity.activityMeals, id: \.suggestedMealId) { meal in
                    Label(meal.title, systemImage: "fork.knife")
                }
                ForEach(activity.activityWorkout, id: \.workoutId) { workout in
                    Label(workout.workoutTitle, systemImage: "figure.run")
                }
                ForEach(activity.activityTask, id: \.taskId) { task in
                    Label(task.title, systemImage: "checkmark.circle")
                }
            }
        }
        Button {
            interested.toggle()
        } label: {
            Label(interested ? "Interested ✓" : "I'm interested",
                  systemImage: interested ? "checkmark.circle.fill" : "hand.thumbsup")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(CardPalette.accent)
        Text("Interest is shown in this preview only.")
            .font(.caption).foregroundStyle(CardPalette.muted)
    }
}

// MARK: - 2. FormData (dynamic form controls)

private struct FormCardDetails: View {
    let form: FormData
    var onSubmit: ((FormResponse) async throws -> Void)? = nil
    @State private var answers: [String: String] = [:]
    @State private var previewResponse: FormResponse?
    @State private var submitting = false
    @State private var submitted = false
    @State private var submissionError: String?

    private var missingRequired: Bool {
        form.items.contains { item in
            guard item.isRequired else { return false }
            let answer = answers[item.itemId] ?? item.defaultValue ?? ""
            return answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let subtitle = form.subtitle, !subtitle.isEmpty {
                Text(subtitle).font(.headline).foregroundStyle(CardPalette.ink)
            }
            if let description = form.description, !description.isEmpty {
                Text(description).font(.subheadline).foregroundStyle(CardPalette.muted)
            }
            ForEach(form.items, id: \.itemId) { item in
                DynamicFormItem(item: item, answers: $answers)
                    .disabled(!item.isEnabled)
                    .opacity(item.isEnabled ? 1 : 0.55)
            }
            Button {
                var filledAnswers = answers
                for item in form.items {
                    if filledAnswers[item.itemId] == nil,
                       let defaultValue = item.defaultValue {
                        filledAnswers[item.itemId] = defaultValue
                    }
                }
                let response = FormResponse(formDataId: form.formDataId, answers: filledAnswers)
                guard let onSubmit else { previewResponse = response; return }
                submissionError = nil
                submitting = true
                _Concurrency.Task {
                    do {
                        try await onSubmit(response)
                        submitted = true
                        previewResponse = nil
                    } catch {
                        submissionError = error.localizedDescription
                    }
                    submitting = false
                }
            } label: {
                Text(form.submitTitle)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(CardPalette.accent)
            .disabled(missingRequired || submitting || submitted)

            if submitted {
                Label("Submitted to Goaliath", systemImage: "checkmark.circle.fill")
                    .font(.subheadline).foregroundStyle(.green)
            }
            if submitting { ProgressView("Submitting response…") }
            if let submissionError {
                Text(submissionError).font(.caption).foregroundStyle(.red)
            }
            if form.allowSkip {
                Button("Skip for now") { previewResponse = nil; answers.removeAll() }
                    .font(.subheadline)
            }
            if missingRequired {
                Text("Complete required fields to continue.")
                    .font(.caption).foregroundStyle(CardPalette.muted)
            }
            if let response = previewResponse {
                Label("Response preview ready (\(response.answers.count) fields)",
                      systemImage: "checkmark.circle.fill")
                    .font(.subheadline).foregroundStyle(.green)
            }
            if onSubmit == nil {
                Text("Preview mode: answers are not sent or stored.")
                    .font(.caption).foregroundStyle(CardPalette.muted)
            }
        }
    }
}

private struct DynamicFormItem: View {
    let item: FormItem
    @Binding var answers: [String: String]

    private var textValue: Binding<String> {
        Binding(
            get: { answers[item.itemId] ?? item.defaultValue ?? "" },
            set: { answers[item.itemId] = $0 }
        )
    }

    private var dateValue: Binding<Date> {
        Binding(
            get: {
                guard let raw = answers[item.itemId],
                      let parsed = ISO8601DateFormatter().date(from: raw) else {
                    return Date()
                }
                return parsed
            },
            set: { answers[item.itemId] = ISO8601DateFormatter().string(from: $0) }
        )
    }

    private var numericValue: Binding<Double> {
        Binding(
            get: {
                Double(answers[item.itemId] ?? item.defaultValue ?? "")
                ?? item.validation?.minimum ?? 0
            },
            set: { answers[item.itemId] = String($0) }
        )
    }

    var body: some View {
        if item.type == .section {
            CardSectionTitle(text: item.title)
                .padding(.top, 6)
        } else if item.type == .info {
            CardPanel {
                Label(item.title, systemImage: "info.circle")
                    .font(.subheadline.weight(.semibold))
                if let info = item.subtitle { Text(info).font(.subheadline) }
                if let url = item.imageURL, !url.isEmpty {
                    RemoteCardImage(urlString: url, height: 145)
                }
            }
        } else {
            CardPanel {
                HStack(spacing: 4) {
                    Text(item.title).font(.subheadline.weight(.semibold))
                    if item.isRequired { Text("*").foregroundStyle(.red) }
                }
                .foregroundStyle(CardPalette.ink)
                if let subtitle = item.subtitle, !subtitle.isEmpty {
                    Text(subtitle).font(.caption).foregroundStyle(CardPalette.muted)
                }
                if let image = item.imageURL, !image.isEmpty {
                    RemoteCardImage(urlString: image, height: 120)
                }
                control
            }
        }
    }

    @ViewBuilder
    private var control: some View {
        switch item.type {
        case .text:
            TextField(item.placeholder ?? "Enter text", text: textValue)
                .textFieldStyle(.roundedBorder)
        case .email:
            TextField(item.placeholder ?? "Email address", text: textValue)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .textFieldStyle(.roundedBorder)
        case .phone:
            TextField(item.placeholder ?? "Phone number", text: textValue)
                .keyboardType(.phonePad)
                .textFieldStyle(.roundedBorder)
        case .number:
            TextField(item.placeholder ?? "0", text: textValue)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
        case .multiline:
            TextEditor(text: textValue)
                .frame(height: 104)
                .overlay(RoundedRectangle(cornerRadius: 9)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1))
        case .date:
            DatePicker("Choose a date", selection: dateValue, displayedComponents: .date)
                .datePickerStyle(.compact)
        case .time:
            DatePicker("Choose a time", selection: dateValue, displayedComponents: .hourAndMinute)
                .datePickerStyle(.compact)
        case .singleSelect, .imageSelect:
            optionButtons(multiSelect: false)
        case .multiSelect, .imageMultiSelect:
            optionButtons(multiSelect: true)
        case .dropdown:
            Picker("Choose an option", selection: textValue) {
                Text("Select...").tag("")
                ForEach(item.options ?? [], id: \.optionId) { option in
                    Text(option.title).tag(option.value)
                }
            }
            .pickerStyle(.menu)
        case .toggle:
            Toggle("Enabled", isOn: Binding(
                get: { textValue.wrappedValue == "true" },
                set: { textValue.wrappedValue = $0 ? "true" : "false" }
            ))
            .tint(CardPalette.accent)
        case .slider:
            let minValue = item.validation?.minimum ?? 0
            let maxValue = max(minValue + 1, item.validation?.maximum ?? 100)
            VStack(alignment: .leading) {
                Text(String(format: "%.0f", numericValue.wrappedValue))
                    .font(.title3.weight(.semibold))
                Slider(value: numericValue, in: minValue...maxValue)
                    .tint(CardPalette.accent)
            }
        case .section, .info:
            EmptyView()
        }
    }

    @ViewBuilder
    private func optionButtons(multiSelect: Bool) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            ForEach(item.options ?? [], id: \.optionId) { option in
                let isSelected = selected(option.value, multi: multiSelect)
                Button {
                    if multiSelect {
                        var values = Set(textValue.wrappedValue
                            .split(separator: ",").map(String.init))
                        if isSelected { values.remove(option.value) }
                        else { values.insert(option.value) }
                        textValue.wrappedValue = values.sorted().joined(separator: ",")
                    } else {
                        textValue.wrappedValue = option.value
                    }
                } label: {
                    HStack(spacing: 10) {
                        if let url = option.imageURL, !url.isEmpty {
                            RemoteCardImage(urlString: url, height: 58)
                                .frame(width: 76)
                        } else if let icon = option.icon {
                            Image(systemName: icon)
                                .frame(width: 23)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(option.title).font(.subheadline.weight(.medium))
                            if let subtitle = option.subtitle {
                                Text(subtitle).font(.caption).foregroundStyle(CardPalette.muted)
                            }
                        }
                        Spacer(minLength: 4)
                        Image(systemName: isSelected
                              ? "checkmark.circle.fill" : "circle")
                    }
                    .foregroundStyle(isSelected ? CardPalette.accent : CardPalette.ink)
                    .padding(10)
                    .background(isSelected ? CardPalette.background : .white,
                                in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? CardPalette.accent : Color.gray.opacity(0.17),
                                lineWidth: isSelected ? 2 : 1))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func selected(_ value: String, multi: Bool) -> Bool {
        if multi {
            return textValue.wrappedValue.split(separator: ",").contains(Substring(value))
        }
        return textValue.wrappedValue == value
    }
}

// MARK: - 3. Gift

private struct GiftCardDetails: View {
    let gift: Gift

    private let tokenGold = Color(red: 0.88, green: 0.62, blue: 0.16)

    private var giverName: String {
        displayName(
            first: gift.giftGiver.firstName,
            last: gift.giftGiver.lastName,
            username: gift.giftGiver.username
        )
    }

    private var receiverName: String {
        displayName(
            first: gift.giftReceiver.firstName,
            last: gift.giftReceiver.lastName,
            username: gift.giftReceiver.username
        )
    }

    private func displayName(
        first: String,
        last: String,
        username: String
    ) -> String {
        let name = "\(first) \(last)"
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? username : name
    }

    private var formattedDate: String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: gift.giftDate) else {
            return gift.giftDate
        }
        return date.formatted(date: .abbreviated, time: .shortened)
    }

    var body: some View {
        // A gift is *only* a transfer of tokens between two users.
        CardPanel {
            VStack(spacing: 12) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 54))
                    .foregroundStyle(tokenGold)
                    .accessibilityHidden(true)

                Text(gift.tokenCount.formatted())
                    .font(.system(size: 54, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(CardPalette.ink)

                Text(gift.tokenCount == 1 ? "TOKEN GIFTED" : "TOKENS GIFTED")
                    .font(.caption.weight(.bold))
                    .tracking(2)
                    .foregroundStyle(CardPalette.accent)

                Text("\(giverName) gifted \(receiverName) \(gift.tokenCount.formatted()) \(gift.tokenCount == 1 ? "token" : "tokens")")
                    .font(.headline)
                    .foregroundStyle(CardPalette.ink)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }

        CardPanel {
            CardSectionTitle(text: "From & to")

            HStack(alignment: .center, spacing: 12) {
                participant(
                    name: giverName,
                    username: gift.giftGiver.username,
                    avatarURL: gift.giftGiver.userImageURL
                )
                Spacer(minLength: 2)
                Image(systemName: "arrow.right")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CardPalette.accent)
                    .accessibilityHidden(true)
                Spacer(minLength: 2)
                participant(
                    name: receiverName,
                    username: gift.giftReceiver.username,
                    avatarURL: gift.giftReceiver.userImageURL
                )
            }
            .frame(maxWidth: .infinity)
        }

        CardPanel {
            if !gift.giftMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                CardSectionTitle(text: "Personal message")
                Text(gift.giftMessage)
                    .font(.body)
                    .foregroundStyle(CardPalette.ink)
            }

            CardField(icon: "calendar", title: "Gift date", value: formattedDate)
            if !gift.status.isEmpty {
                CardChips(values: gift.status.map { $0.capitalized })
            }
        }
    }

    private func participant(
        name: String,
        username: String,
        avatarURL: String
    ) -> some View {
        VStack(spacing: 5) {
            CardAvatar(imageURL: avatarURL, name: name, size: 58)
            Text(name)
                .font(.caption.weight(.semibold))
                .foregroundStyle(CardPalette.ink)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            Text("@\(username)")
                .font(.caption2)
                .foregroundStyle(CardPalette.muted)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 4. Suggested meal

private struct MealCardDetails: View {
    let meal: SuggestedMeal

    var body: some View {
        CardPanel {
            HStack(spacing: 10) {
                CardAvatar(imageURL: meal.user.avatarURL, name: meal.user.name)
                VStack(alignment: .leading) {
                    Text("Suggested by \(meal.user.name)").font(.subheadline.weight(.semibold))
                    Text(meal.user.location).font(.caption).foregroundStyle(CardPalette.muted)
                }
                Spacer()
            }
            CardField(icon: "clock", title: "Estimated time", value: "\(meal.estimatedTime) min")
            CardField(icon: "dollarsign.circle", title: "Price range", value: meal.priceRange)
            CardField(icon: "person.2", title: "Added by", value: "\(meal.mealUserData.copyCount) people")
        }
        ForEach(meal.meals, id: \.mealId) { dish in
            CardPanel {
                CardSectionTitle(text: dish.title)
                if let image = dish.imageURL, !image.isEmpty {
                    RemoteCardImage(urlString: image, height: 150)
                }
                ForEach(dish.recipes ?? [], id: \.recipeId) { recipe in
                    CardField(icon: "flame", title: "Calories",
                              value: "\(recipe.recipeNutrition.calories) kcal")
                    CardField(icon: "bolt", title: "Protein",
                              value: "\(recipe.recipeNutrition.protein) g")
                    CardField(icon: "clock", title: "Preparation",
                              value: "\(recipe.prepTime + recipe.cookTime) min")
                    CardChips(values: recipe.tags)
                    CardSectionTitle(text: "Ingredients")
                    ForEach(recipe.ingredients, id: \.ingredientId) { ingredient in
                        HStack {
                            Text(ingredient.name)
                            Spacer()
                            Text("\(ingredient.quantity.formatted()) \(ingredient.units)")
                                .foregroundStyle(CardPalette.muted)
                        }
                        .font(.subheadline)
                    }
                    CardSectionTitle(text: "Instructions")
                    ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { pair in
                        HStack(alignment: .top) {
                            Text("\(pair.offset + 1).")
                                .fontWeight(.bold).foregroundStyle(CardPalette.accent)
                            Text(pair.element).font(.subheadline)
                        }
                    }
                }
                if (dish.recipes ?? []).isEmpty, let ingredients = dish.ingredients {
                    CardSectionTitle(text: "Ingredients")
                    ForEach(ingredients, id: \.ingredientId) { ingredient in
                        Text("• \(ingredient.name)")
                    }
                }
            }
        }
    }
}

// MARK: - 5. Message

private struct MessageCardDetails: View {
    let message: Message
    let previewText: String
    @State private var replyDraft = ""
    @State private var showPreview = false

    var body: some View {
        CardPanel {
            HStack(spacing: 12) {
                CardAvatar(imageURL: message.senderImage, name: message.senderName, size: 54)
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.senderName).font(.headline)
                    Text(message.createdAt).font(.caption).foregroundStyle(CardPalette.muted)
                }
                Spacer()
                if message.readStatus == "unread" {
                    Circle().fill(CardPalette.accent).frame(width: 9, height: 9)
                }
            }
            CardSectionTitle(text: message.subject)
            Text(previewText).font(.subheadline)
            CardImageStrip(urls: message.messageImageURLs)
            if !message.messageVideoURLs.isEmpty {
                Label("\(message.messageVideoURLs.count) video attachment(s)", systemImage: "video")
                    .font(.caption).foregroundStyle(CardPalette.muted)
            }
        }
        CardPanel {
            CardSectionTitle(text: "Reply")
            TextField("Write a reply...", text: $replyDraft, axis: .vertical)
                .lineLimit(2...5).textFieldStyle(.roundedBorder)
            Button("Preview reply") { showPreview = true }
                .buttonStyle(.borderedProminent)
                .tint(CardPalette.accent)
                .disabled(replyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            if showPreview {
                Text(replyDraft).font(.subheadline)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(CardPalette.background, in: RoundedRectangle(cornerRadius: 10))
            }
            Text("Preview only — no reply is sent.")
                .font(.caption).foregroundStyle(CardPalette.muted)
        }
    }
}

// MARK: - 6. Post

private struct PostCardDetails: View {
    let post: Post
    let previewText: String
    @State private var saved: Bool
    @State private var responseDraft = ""
    @State private var showResponse = false

    init(post: Post, previewText: String) {
        self.post = post
        self.previewText = previewText
        _saved = State(initialValue: post.savedPostStatus.lowercased() == "saved")
    }

    var body: some View {
        CardPanel {
            HStack(spacing: 11) {
                CardAvatar(imageURL: post.posterImageURL, name: post.posterName)
                VStack(alignment: .leading, spacing: 3) {
                    Text(post.posterName).font(.headline)
                    Text("\(post.posterRole) • \(post.posterLocation)")
                        .font(.caption).foregroundStyle(CardPalette.muted)
                }
                Spacer(minLength: 0)
            }
            Text(post.subject).font(.title3.weight(.bold))
            Text(previewText).font(.subheadline)
            CardChips(values: post.tags)
            CardField(icon: "bubble.left", title: "Responses",
                      value: "\(post.postResponseCount)")
            CardField(icon: "bookmark", title: "Saves", value: "\(post.postSavedCount)")
            CardField(icon: "calendar", title: "Expires", value: post.expiresAt)
            CardImageStrip(urls: post.postImageURLs)
            if !post.postVideoURLs.isEmpty {
                Text("\(post.postVideoURLs.count) video(s) attached")
                    .font(.caption).foregroundStyle(CardPalette.muted)
            }
        }
        CardPanel {
            HStack {
                Button {
                    saved.toggle()
                } label: {
                    Label(saved ? "Saved locally" : "Save post",
                          systemImage: saved ? "bookmark.fill" : "bookmark")
                }
                .buttonStyle(.bordered)
                .tint(CardPalette.accent)
                Spacer()
                Button("Respond") { showResponse.toggle() }
                    .buttonStyle(.borderedProminent)
                    .tint(CardPalette.accent)
            }
            if showResponse {
                TextField("Draft a response...", text: $responseDraft, axis: .vertical)
                    .lineLimit(2...5).textFieldStyle(.roundedBorder)
                Text("Draft only — not published.")
                    .font(.caption).foregroundStyle(CardPalette.muted)
            }
        }
    }
}

// MARK: - 7. Task

private struct TaskCardDetails: View {
    let task: Task
    @State private var completed = false

    var body: some View {
        CardPanel {
            CardSectionTitle(text: "Task details")
            Text(task.description).font(.subheadline)
            CardField(icon: "person", title: "Created by", value: task.createdBy)
            CardField(icon: "calendar", title: "Created", value: task.createdAt)
            CardImageStrip(urls: task.taskImageUrls)
        }
        CardPanel {
            Toggle(isOn: $completed) {
                Label(completed ? "Completed (preview)" : "Mark as complete",
                      systemImage: completed ? "checkmark.circle.fill" : "circle")
            }
            .tint(CardPalette.accent)
            Text("Completion is local to this preview.")
                .font(.caption).foregroundStyle(CardPalette.muted)
        }
    }
}

// MARK: - 8. User status

private struct UserStatusCardDetails: View {
    let status: UserStatus
    @State private var showDraft = false
    @State private var messageDraft = ""

    var body: some View {
        CardPanel {
            HStack(spacing: 12) {
                CardAvatar(imageURL: status.userImageURL,
                           name: status.firstName, size: 60)
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(status.firstName) \(status.lastName)").font(.headline)
                    Text("@\(status.username)").font(.caption)
                        .foregroundStyle(CardPalette.muted)
                }
            }
            CardSectionTitle(text: status.userStatusTitle)
            Text(status.userStatusDescription).font(.subheadline)
            CardField(icon: "clock", title: "Posted", value: status.userStatusDate)
            CardField(icon: "tag", title: "Status", value: status.statusType.capitalized)
            CardImageStrip(urls: status.userStatusImageURLs)
            if !status.userStatusVideoURLs.isEmpty {
                Label("\(status.userStatusVideoURLs.count) video(s)", systemImage: "video")
                    .font(.caption).foregroundStyle(CardPalette.muted)
            }
        }
        CardPanel {
            Button(showDraft ? "Hide message draft" : "Say hello") {
                showDraft.toggle()
            }
            .buttonStyle(.borderedProminent)
            .tint(CardPalette.accent)
            if showDraft {
                TextField("Write a message to \(status.firstName)...",
                          text: $messageDraft, axis: .vertical)
                    .lineLimit(2...5).textFieldStyle(.roundedBorder)
                Text("Draft only — no message is sent.")
                    .font(.caption).foregroundStyle(CardPalette.muted)
            }
        }
    }
}

// MARK: - 9. Workout

private struct WorkoutCardDetails: View {
    let workout: Workout
    @State private var interested = false

    var body: some View {
        CardPanel {
            CardSectionTitle(text: "Workout details")
            CardChips(values: workout.workoutCategories)
            CardField(icon: "clock", title: "Duration", value: workout.workoutDurationText)
            CardField(icon: "calendar", title: "Scheduled", value: workout.selectedWorkoutTime)
            CardField(icon: "mappin", title: "Location", value: workout.workoutLocation)
            CardField(icon: "figure.walk", title: "Distance", value: workout.workoutDistance)
            CardField(icon: "person.2", title: "Format", value: workout.workoutFormat.capitalized)
            CardField(icon: "star", title: "Rating", value: workout.rating)
            CardImageStrip(urls: workout.workoutImageUrls)
        }
        CardPanel {
            CardSectionTitle(text: "Trainer")
            HStack(spacing: 12) {
                CardAvatar(imageURL: workout.workoutTrainer.userImageUrl,
                           name: workout.workoutTrainer.name, size: 56)
                VStack(alignment: .leading, spacing: 3) {
                    Text(workout.workoutTrainer.name).font(.headline)
                    Text(workout.workoutTrainer.userDescription)
                        .font(.caption).foregroundStyle(CardPalette.muted)
                    Text("★ \(workout.workoutTrainer.rating) • \(workout.workoutTrainer.onlineStatus)")
                        .font(.caption).foregroundStyle(CardPalette.accent)
                }
            }
        }
        if !workout.participants.isEmpty {
            CardPanel {
                CardSectionTitle(text: "Participants (\(workout.participants.count))")
                ForEach(workout.participants, id: \.userId) { participant in
                    HStack(spacing: 10) {
                        CardAvatar(imageURL: participant.userImage,
                                   name: participant.name, size: 40)
                        VStack(alignment: .leading) {
                            Text(participant.name).font(.subheadline.weight(.semibold))
                            Text(participant.statusDescription).font(.caption)
                                .foregroundStyle(CardPalette.muted)
                        }
                    }
                }
            }
        }
        CardPanel {
            CardSectionTitle(text: "Latest comment")
            Text("\(workout.lastComment.name): \(workout.lastComment.commentText)")
                .font(.subheadline)
            Text("\(workout.workoutCommentsCount) comment(s)")
                .font(.caption).foregroundStyle(CardPalette.muted)
        }
        Button {
            interested.toggle()
        } label: {
            Label(interested ? "Interested ✓" : "I'm interested",
                  systemImage: interested ? "checkmark.circle.fill" : "hand.thumbsup")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(CardPalette.accent)
        Text("Interest is local to this preview.")
            .font(.caption).foregroundStyle(CardPalette.muted)
    }
}

// MARK: - Preview

#Preview {
    GeometryReader { proxy in
        CardContentLayer(
            geometry: proxy,
            selectedCard: .constant(CardSampleData.cards[0])
        )
    }
}
