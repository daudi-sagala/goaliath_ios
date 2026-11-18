//
//  PickGoalsView.swift
//  goaliath
//
//  Created by Daudi Sagala on 11/9/26.
//


import SwiftUI

struct PickGoalsView: View {

    var geometry: GeometryProxy
    @Binding var showGoals: Bool
    private let background = Color(hex: "EDF6F9")
    private let primary = Color(hex: "263B55")
    private let secondary = Color(hex: "637D91")
    private let accent = Color(hex: "526FA5")

    @State private var draft = ""
    @State private var goalsList = "everyone"
    @State private var myGoals: [SharedGoal] = []

    var body: some View {

        VStack(spacing: 0) {

            // MARK: - Discovery Header

            VStack(alignment: .leading, spacing: 5) {

                HStack {
                    Text("Browse Goals")
                        .font(.custom("Fredoka-SemiBold", size: 27))
                        .foregroundStyle(primary)
                    
                    Spacer()
                    
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showGoals = false
                        }
                    } label: {
                        ZStack {
                            Circle().fill(.white)
                                .frame(width: 30, height: 30)
                            Image(systemName: "xmark")
                                .font(.system(size: 18))
                                .foregroundStyle(accent)
                                .padding(10)
                        }
                        
                    }
                    
                }

                Text("Discover goals added by Goaliath members")
                    .font(.custom("Nunito-Medium", size: 14))
                    .foregroundStyle(secondary)

            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 17)


            // MARK: - Explore / My Goals Selector

            HStack(spacing: 5) {

                goalTab(
                    title: "Explore",
                    icon: "person.3.fill",
                    selected: goalsList == "everyone"
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        goalsList = "everyone"
                    }
                }

                goalTab(
                    title: "My Goals",
                    icon: "person.circle.fill",
                    selected: goalsList == "me",
                    count: myGoals.count
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        goalsList = "me"
                    }
                }
            }
            .padding(5)
            .background(.white.opacity(0.85))
            .clipShape(Capsule())
            .padding(.horizontal, 20)
            .padding(.bottom, 17)


            // MARK: - Goals Feed

            ScrollView(showsIndicators: false) {

                LazyVStack(spacing: 13) {

                    if goalsList == "everyone" {

                        HStack {
                            Text("Goals people are chasing")
                                .font(.custom("Fredoka-Medium", size: 18))
                                .foregroundStyle(primary)

                            Spacer()

                            Text("\(sharedGoals.count) goals")
                                .font(.custom("Nunito-SemiBold", size: 12))
                                .foregroundStyle(secondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 2)

                        ForEach(sharedGoals) { goal in

                            SharedGoalItemView(
                                geometry: geometry,
                                userImageUrl: goal.userImageUrl,
                                userName: goal.userName,
                                dateAdded: goal.dateAdded,
                                goalDescription: goal.goalDescription,
                                category: goal.category,
                                peopleCount: goal.peopleCount,
                                onAdd: {
                                    if !myGoals.contains(where: {
                                        $0.goalDescription == goal.goalDescription
                                    }) {
                                        myGoals.append(goal)
                                    }
                                }
                            )
                            .padding(.horizontal, 16)
                        }

                    } else {

                        HStack {
                            Text("Goals I am chasing")
                                .font(.custom("Fredoka-Medium", size: 18))
                                .foregroundStyle(primary)

                            Spacer()

                            Text("\(myGoals.count) added")
                                .font(.custom("Nunito-SemiBold", size: 12))
                                .foregroundStyle(secondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 2)

                        if myGoals.isEmpty {

                            VStack(spacing: 12) {

                                Image(systemName: "flag.2.crossed.fill")
                                    .font(.system(size: 35))
                                    .foregroundStyle(accent)

                                Text("No goals added yet")
                                    .font(.custom("Fredoka-SemiBold", size: 19))
                                    .foregroundStyle(primary)

                                Text("Add a goal below or explore what others are working toward.")
                                    .font(.custom("Nunito-Regular", size: 14))
                                    .foregroundStyle(secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(30)
                            .frame(maxWidth: .infinity)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .padding(.horizontal, 16)

                        } else {

                            ForEach(myGoals) { goal in
                                SharedGoalItemView(
                                    geometry: geometry,
                                    userImageUrl: goal.userImageUrl,
                                    userName: goal.userName,
                                    dateAdded: goal.dateAdded,
                                    goalDescription: goal.goalDescription,
                                    category: goal.category,
                                    peopleCount: goal.peopleCount
                                )
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                }
                .padding(.top, 3)
                .padding(.bottom, 15)
            }

            Spacer(minLength: 0)


            // MARK: - Add Goal Composer

            HStack(spacing: 10) {

                Image(systemName: "person.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(accent)
                    .padding(.leading, 5)

                TextField("What's your next goal?", text: $draft, axis: .vertical)
                    .font(.custom("Nunito-SemiBold", size: 15))
                    .foregroundStyle(primary)
                    .lineLimit(1...3)
                    .submitLabel(.done)

                Button {
                    addNewGoal()
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(
                            draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? secondary.opacity(0.4)
                            : accent
                        )
                        .clipShape(Circle())
                }
                .disabled(
                    draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                )
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 9)
            .background(.white)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(Color(hex: "DCE9EF"), lineWidth: 1)
            }
            .shadow(color: primary.opacity(0.08), radius: 9, x: 0, y: 3)
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 8)
            .background(background)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(background.ignoresSafeArea())
        .navigationTitle("Add Goals")
        .navigationBarTitleDisplayMode(.inline)
    }


    // MARK: - Tab Component

    private func goalTab(
        title: String,
        icon: String,
        selected: Bool,
        count: Int = 0,
        action: @escaping () -> Void
    ) -> some View {

        Button(action: action) {

            HStack(spacing: 7) {

                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))

                Text(title)
                    .font(.custom("Fredoka-Medium", size: 16))

                if count > 0 {
                    Text("\(count)")
                        .font(.custom("Nunito-Bold", size: 11))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            selected ? .white.opacity(0.2) : accent.opacity(0.1)
                        )
                        .clipShape(Capsule())
                }
            }
            .foregroundStyle(selected ? .white : primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background {
                if selected {
                    Capsule().fill(accent)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }


    // MARK: - Add New Goal

    private func addNewGoal() {

        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.isEmpty else { return }

        let newGoal = SharedGoal(
            userImageUrl: "",
            userName: "You",
            dateAdded: "Just now",
            goalDescription: text,
            category: "Personal Growth",
            peopleCount: 1
        )

        myGoals.insert(newGoal, at: 0)
        draft = ""

        withAnimation(.spring(response: 0.35)) {
            goalsList = "me"
        }
    }
}



