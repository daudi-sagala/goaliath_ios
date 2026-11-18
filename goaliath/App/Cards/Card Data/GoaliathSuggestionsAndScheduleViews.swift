import SwiftUI

// MARK: - Meal suggestion

struct GoaliathSuggestedMealCardView: View {
    let meal: SuggestedMeal
    var onAction: ((GoaliathCardUpdateAction) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            GoaliathCardSurface {
                GoaliathCardTitle(title: "Meal Suggestion", symbol: "fork.knife",
                                  tint: GoaliathCardLook.green)
                Text(meal.title)
                    .font(.system(size: 25, weight: .bold, design: .rounded))
                    .foregroundStyle(GoaliathCardLook.ink)
                if ((meal.imageUrl?.isEmpty) == nil) {
                    GoaliathCardPhoto(imageURL: meal.imageUrl ?? "", height: 205)
                }
                HStack(spacing: 10) {
                    GoaliathCardAvatarView(imageURL: meal.user.avatarURL,
                                           name: meal.user.name, size: 46)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Suggested by \(meal.user.name)")
                            .font(.subheadline.weight(.bold))
                        if !meal.user.location.isEmpty {
                            Text(meal.user.location).font(.caption)
                                .foregroundStyle(GoaliathCardLook.muted)
                        }
                    }
                    Spacer(minLength: 0)
                }
                GoaliathCardFieldRow(label: "Estimated preparation",
                                      value: "\(meal.estimatedTime) minutes", symbol: "clock")
                GoaliathCardFieldRow(label: "Price range", value: meal.priceRange,
                                      symbol: "dollarsign.circle")
                GoaliathCardFieldRow(label: "Added by", value: "\(meal.mealUserData.copyCount) members",
                                      symbol: "person.2")
                GoaliathCardFieldRow(label: "Shared",
                                      value: GoaliathHumanDate.display(meal.createdAt),
                                      symbol: "calendar")
            }
            ForEach(meal.meals, id: \.mealId) { dish in
                GoaliathCardSurface {
                    Text(dish.title).font(.headline)
                        .foregroundStyle(GoaliathCardLook.ink)
                    if let url = dish.imageURL, !url.isEmpty {
                        GoaliathCardPhoto(imageURL: url, height: 170)
                    }
                    ForEach(dish.recipes ?? [], id: \.recipeId) { recipe in
                        GoaliathCardFieldRow(label: "Calories",
                                              value: "\(recipe.recipeNutrition.calories) kcal",
                                              symbol: "flame")
                        GoaliathCardFieldRow(label: "Protein",
                                              value: "\(recipe.recipeNutrition.protein) g",
                                              symbol: "bolt")
                        GoaliathCardFieldRow(label: "Prep + cook",
                                              value: "\(recipe.prepTime + recipe.cookTime) minutes",
                                              symbol: "clock")
                        Text("Ingredients").font(.headline)
                        ForEach(recipe.ingredients, id: \.ingredientId) { ingredient in
                            HStack {
                                Text(ingredient.name)
                                Spacer()
                                Text("\(ingredient.quantity.formatted()) \(ingredient.units)")
                                    .foregroundStyle(GoaliathCardLook.muted)
                            }
                            .font(.subheadline)
                        }
                        if !recipe.instructions.isEmpty {
                            Text("Instructions").font(.headline)
                            ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { step in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("\(step.offset + 1).")
                                        .fontWeight(.bold)
                                        .foregroundStyle(GoaliathCardLook.blue)
                                    Text(step.element).font(.subheadline)
                                }
                            }
                        }
                    }
                    if (dish.recipes ?? []).isEmpty,
                       let ingredients = dish.ingredients, !ingredients.isEmpty {
                        Text("Ingredients").font(.headline)
                        ForEach(ingredients, id: \.ingredientId) { item in
                            Text("• \(item.name)").font(.subheadline)
                        }
                    }
                }
            }
            GoaliathCardSurface {
                GoaliathSuggestionActions(kind: .meal, id: meal.suggestedMealId,
                                          title: meal.title, onAction: onAction)
            }
        }
    }
}

// MARK: - Workout suggestion

struct GoaliathSuggestedWorkoutCardView: View {
    let workout: Workout
    var onAction: ((GoaliathCardUpdateAction) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            GoaliathCardSurface {
                GoaliathCardTitle(title: "Workout Suggestion", symbol: "figure.run",
                                  tint: GoaliathCardLook.violet)
                Text(workout.workoutTitle)
                    .font(.system(size: 25, weight: .bold, design: .rounded))
                    .foregroundStyle(GoaliathCardLook.ink)
                if !workout.workoutDescription.isEmpty {
                    Text(workout.workoutDescription).font(.subheadline)
                        .foregroundStyle(GoaliathCardLook.ink)
                }
                if let image = workout.workoutImageUrls.first, !image.isEmpty {
                    GoaliathCardPhoto(imageURL: image, height: 205)
                }
                GoaliathCardFieldRow(label: "Suggested workout time",
                                      value: GoaliathHumanDate.display(workout.selectedWorkoutTime),
                                      symbol: "calendar")
                GoaliathCardFieldRow(label: "Duration",
                                      value: workout.workoutDurationText.isEmpty
                                      ? "\(workout.workoutDurationInSeconds / 60) minutes"
                                      : workout.workoutDurationText,
                                      symbol: "clock")
                GoaliathCardFieldRow(label: "Location", value: workout.workoutLocation,
                                      symbol: "mappin")
                GoaliathCardFieldRow(label: "Format", value: workout.workoutFormat.capitalized,
                                      symbol: "person.2")
                if workout.workoutDistance != "0 km" && !workout.workoutDistance.isEmpty {
                    GoaliathCardFieldRow(label: "Distance", value: workout.workoutDistance,
                                          symbol: "figure.walk")
                }
                if !workout.workoutCategories.isEmpty {
                    Text(workout.workoutCategories.map { $0.capitalized }.joined(separator: " · "))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(GoaliathCardLook.violet)
                }
                GoaliathCardFieldRow(label: "Shared",
                                      value: GoaliathHumanDate.display(workout.createdAt),
                                      symbol: "clock")
            }
            GoaliathCardSurface {
                Text("Coach / Trainer").font(.headline)
                    .foregroundStyle(GoaliathCardLook.ink)
                HStack(spacing: 10) {
                    GoaliathCardAvatarView(imageURL: workout.workoutTrainer.userImageUrl,
                                           name: workout.workoutTrainer.name, size: 50)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workout.workoutTrainer.name).font(.subheadline.weight(.bold))
                        Text(workout.workoutTrainer.userDescription)
                            .font(.caption).foregroundStyle(GoaliathCardLook.muted)
                    }
                }
                if !workout.participants.isEmpty {
                    Text("\(workout.participants.count) participant(s)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(GoaliathCardLook.muted)
                }
                if workout.workoutCommentsCount > 0 {
                    Text("\(workout.workoutCommentsCount) comment(s)")
                        .font(.caption).foregroundStyle(GoaliathCardLook.muted)
                }
            }
            GoaliathCardSurface {
                GoaliathSuggestionActions(kind: .workout, id: workout.workoutId,
                                          title: workout.workoutTitle, onAction: onAction)
            }
        }
    }
}

// MARK: - Task suggestion

struct GoaliathSuggestedTaskCardView: View {
    let task: Task
    var onAction: ((GoaliathCardUpdateAction) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            GoaliathCardSurface {
                GoaliathCardTitle(title: "Task Suggestion", symbol: "checklist",
                                  tint: GoaliathCardLook.blue)
                Text(task.title)
                    .font(.system(size: 25, weight: .bold, design: .rounded))
                    .foregroundStyle(GoaliathCardLook.ink)
                if !task.description.isEmpty {
                    Text(task.description)
                        .font(.subheadline).foregroundStyle(GoaliathCardLook.ink)
                }
                if let image = task.taskImageUrls.first, !image.isEmpty {
                    GoaliathCardPhoto(imageURL: image, height: 205)
                }
                GoaliathCardFieldRow(label: "Suggested by", value: task.createdBy,
                                      symbol: "person")
                GoaliathCardFieldRow(label: "Shared",
                                      value: GoaliathHumanDate.display(task.createdAt),
                                      symbol: "calendar")
                if !task.taskVideoUrls.isEmpty {
                    Label("\(task.taskVideoUrls.count) video attachment(s)", systemImage: "video.fill")
                        .font(.caption).foregroundStyle(GoaliathCardLook.muted)
                }
            }
            GoaliathCardSurface {
                GoaliathSuggestionActions(kind: .task, id: task.taskId,
                                          title: task.title, onAction: onAction)
            }
        }
    }
}

// MARK: - My Schedule / activity

struct GoaliathScheduledActivityCardView: View {
    let activity: Activity
    var onAction: ((GoaliathCardUpdateAction) -> Void)? = nil

    @State private var showPreview = false

    private var state: String {
        activity.status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
    private var completed: Bool { state.contains("complete") || state == "done" }
    private var skipped: Bool { state.contains("skip") }
    private var started: Bool {
        state == "active" || state == "in_progress" || state == "in progress" ||
        state == "started" || state == "begun" || state == "ongoing"
    }
    private var confirmed: Bool {
        state == "confirmed" || state == "accepted" || started || completed
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            GoaliathCardSurface {
                GoaliathCardTitle(title: "My Schedule", symbol: "calendar",
                                  tint: GoaliathCardLook.blue)
                Text(activity.title)
                    .font(.system(size: 25, weight: .bold, design: .rounded))
                    .foregroundStyle(GoaliathCardLook.ink)
                if !activity.description.isEmpty {
                    Text(activity.description).font(.subheadline)
                        .foregroundStyle(GoaliathCardLook.ink)
                }
                if !activity.mainImageUrl.isEmpty {
                    GoaliathCardPhoto(imageURL: activity.mainImageUrl, height: 205)
                }
                GoaliathCardFieldRow(label: "Date",
                                      value: GoaliathHumanDate.date(activity.date),
                                      symbol: "calendar")
                GoaliathCardFieldRow(label: "Time",
                                      value: GoaliathHumanDate.timeRange(start: activity.startTime,
                                                                         end: activity.endTime),
                                      symbol: "clock")
                GoaliathCardFieldRow(label: "Location", value: activity.location,
                                      symbol: "mappin")
                GoaliathCardFieldRow(label: "Category", value: activity.activityType.capitalized,
                                      symbol: "tag")
                GoaliathCardFieldRow(label: "Status", value: activity.status.capitalized,
                                      symbol: "checkmark.circle")
            }
            if !activity.activityMeals.isEmpty ||
                !activity.activityWorkout.isEmpty || !activity.activityTask.isEmpty {
                GoaliathCardSurface {
                    Text("Included in your plan").font(.headline)
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
            GoaliathCardSurface {
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        GoaliathCardPillButton(
                            title: (started || completed) ? "Open" : "Begin",
                            tint: GoaliathCardLook.blue,
                            disabled: skipped,
                            action: { fire(started || completed ? .open : .begin) }
                        )
                        GoaliathCardPillButton(
                            title: confirmed ? "Confirmed" : "Confirm",
                            tint: GoaliathCardLook.green,
                            outlined: confirmed,
                            disabled: confirmed || skipped,
                            action: { fire(.confirm) }
                        )
                    }
                    HStack(spacing: 10) {
                        GoaliathCardPillButton(
                            title: skipped ? "Skipped" : "Skip",
                            tint: GoaliathCardLook.muted,
                            outlined: true,
                            disabled: skipped || completed,
                            action: { fire(.skip) }
                        )
                        GoaliathCardPillButton(
                            title: completed ? "Completed" : "Complete",
                            tint: GoaliathCardLook.violet,
                            outlined: completed,
                            disabled: completed || skipped,
                            action: { fire(.complete) }
                        )
                    }
                }
                Text("Button states follow the saved activity status; changes appear after your app confirms them.")
                    .font(.caption).foregroundStyle(GoaliathCardLook.muted)
            }
        }
        .alert("Preview only", isPresented: $showPreview) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Connect this action to your schedule service to update the activity.")
        }
    }

    private func fire(_ operation: GoaliathScheduleOperation) {
        if let onAction {
            onAction(.activity(activityId: activity.activityId, operation: operation))
        } else {
            showPreview = true
        }
    }
}
