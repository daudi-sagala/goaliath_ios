//
//  SharedGoalItemView.swift
//  goaliath
//
//  Created by Daudi Sagala on 11/9/26.
//


import SwiftUI

struct SharedGoalItemView: View {
    var geometry: GeometryProxy

    private let primary = Color(hex: "263B55")
    private let secondary = Color(hex: "637D91")
    private let accent = Color(hex: "526FA5")

    var userImageUrl: String
    var userName: String
    var dateAdded: String
    var goalDescription: String
    var category: String = "Personal Growth"
    var peopleCount: Int = 1
    var onAdd: () -> Void = {}

    private var categoryColor: Color {
        switch category {
        case "Health & Fitness": return Color(hex: "E98B78")
        case "Career & Business": return Color(hex: "8A80C5")
        case "Learning": return Color(hex: "55A6A0")
        case "Financial": return Color(hex: "D6A34E")
        case "Relationships": return Color(hex: "D77F9E")
        default: return Color(hex: "7195C5")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            // Category and date
            HStack {
                HStack(spacing: 5) {
                    Circle()
                        .fill(categoryColor)
                        .frame(width: 7, height: 7)

                    Text(category)
                        .font(.custom("Nunito-Bold", size: 12))
                        .foregroundStyle(categoryColor)
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 6)
                .background(categoryColor.opacity(0.10))
                .clipShape(Capsule())

                Spacer()

                Text(dateAdded)
                    .font(.custom("Nunito-SemiBold", size: 12))
                    .foregroundStyle(secondary)
            }

            // Goal description
            Text(goalDescription)
                .font(.custom("Nunito-Bold", size: 17))
                .foregroundStyle(primary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(3)

            // User information and action
            HStack(spacing: 9) {

                if let url = URL(string: userImageUrl), !userImageUrl.isEmpty {
                    CustomAsyncImage(url: url)
                        .aspectRatio(1, contentMode: .fill)
                        .frame(width: 34, height: 34)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(accent.opacity(0.15))
                        .frame(width: 34, height: 34)
                        .overlay {
                            Image(systemName: "person.fill")
                                .foregroundStyle(accent)
                                .font(.system(size: 15))
                        }
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(userName)
                        .font(.custom("Nunito-Bold", size: 13))
                        .foregroundStyle(primary)

                    Text("\(peopleCount) \(peopleCount == 1 ? "person" : "people") pursuing this")
                        .font(.custom("Nunito-Regular", size: 11))
                        .foregroundStyle(secondary)
                }

                Spacer()

                Button(action: onAdd) {
                    HStack(spacing: 5) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))

                        Text("Add")
                            .font(.custom("Nunito-Bold", size: 13))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 17)
                    .padding(.vertical, 9)
                    .background(accent)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(15)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 19))
        .overlay {
            RoundedRectangle(cornerRadius: 19)
                .stroke(Color(hex: "DCE9EF").opacity(0.8), lineWidth: 1)
        }
        .shadow(color: Color(hex: "263B55").opacity(0.055),
                radius: 8, x: 0, y: 4)
    }
}



