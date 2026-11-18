//
//  BottomOverLay.swift
//  goaliath
//
//  Created by Daudi Sagala on 11/11/26.
//

import SwiftUI

// MARK: - Bottom Overlay

struct BottomOverLay: View {

    var cardData: [CardData]

    @Binding var selectedCard: CardData

    let currentPage: Int
    let pageCount: Int
    let slideDirection: TileSlideDirection

    let onPrevious: () -> Void
    let onNext: () -> Void

    private let accent = Color(hex: "526FA5")
    private let background = Color(hex: "EDF6F9")

    private var groupID: String {
        cardData
            .map(\.cardDataId)
            .joined(separator: "-")
    }

    private var slideTransition: AnyTransition {

        let incomingEdge: Edge =
            slideDirection == .next ? .trailing : .leading

        let outgoingEdge: Edge =
            slideDirection == .next ? .leading : .trailing

        return .asymmetric(
            insertion: .move(edge: incomingEdge),
            removal: .move(edge: outgoingEdge)
        )
    }

    var body: some View {

        HStack(spacing: 6) {

            // MARK: Previous arrow

            navigationArrow(
                icon: "chevron.left",
                label: "Previous cards",
                action: onPrevious
            )

            // MARK: Five sliding card tiles

            ZStack {

                HStack(spacing: 6) {

                    ForEach(
                        Array(cardData.prefix(5)),
                        id: \.cardDataId
                    ) { card in

                        BottomTileItemView(
                            card: card,
                            isSelected:
                                selectedCard.cardDataId == card.cardDataId
                        ) {
                            withAnimation(
                                .spring(
                                    response: 0.35,
                                    dampingFraction: 0.8
                                )
                            ) {
                                selectedCard = card
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .id(groupID)
                .transition(slideTransition)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .clipped()

            // MARK: Next arrow

            navigationArrow(
                icon: "chevron.right",
                label: "Next cards",
                action: onNext
            )
        }
        .padding(.horizontal, 10)
        .padding(.top, 8)
        .background(background)
    }

    // MARK: - Compact Navigation Arrow

    private func navigationArrow(
        icon: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {

        Button(action: action) {

            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(accent)
                .frame(width: 30, height: 44)
                .background {
                    Capsule()
                        .fill(.white)
                }
                .overlay {
                    Capsule()
                        .strokeBorder(
                            accent.opacity(0.2),
                            lineWidth: 1
                        )
                }
                .shadow(
                    color: accent.opacity(0.1),
                    radius: 4,
                    y: 2
                )
        }
        .buttonStyle(.plain)
        .disabled(pageCount <= 1)
        .opacity(pageCount <= 1 ? 0.4 : 1)
        .accessibilityLabel(label)
    }
}


// MARK: - Bottom Tile Item


import SwiftUI

struct BottomTileItemView: View {

    let card: CardData
    let isSelected: Bool
    let onTap: () -> Void

    private let accent = Color(hex: "526FA5")
    private let background = Color(hex: "EDF6F9")

    private let cornerRadius: CGFloat = 12

    // MARK: - Image Type

    private enum TileImageType {
        case icon(String, Color)
        case profile(String?)
        case cardImage(String?, String)
    }

    // MARK: - Determine Tile Content

    private var tileImageType: TileImageType {

        switch card.cardDataTypeId {

        case "message":
            return .icon(
                "bubble.left.and.bubble.right.fill",
                .blue
            )

        case "gift":
            return .icon(
                "gift.fill",
                .pink
            )

        case "formData":
            return .icon(
                "list.clipboard.fill",
                .purple
            )

        case "userStatus":
            return .profile(
                card.cardDataType.userStatus?.userImageURL
            )

        case "post":

            let post = card.cardDataType.post

            let postType = (
                post?.postType ?? ""
            ).lowercased()

            // Tips and requests show the author's avatar
            if [
                "tip",
                "tips",
                "request",
                "requests"
            ].contains(postType) {

                return .profile(
                    post?.posterImageURL
                )
            }

            // Other posts show their content image
            return .cardImage(
                card.imageUrl,
                "rectangle.stack.fill"
            )

        case "activity":
            return .cardImage(
                card.imageUrl,
                "calendar"
            )

        case "suggestedMeal":
            return .cardImage(
                card.imageUrl,
                "fork.knife"
            )

        case "task":
            return .cardImage(
                card.imageUrl,
                "checkmark.circle.fill"
            )

        case "workout":
            return .cardImage(
                card.imageUrl,
                "figure.run"
            )

        default:
            return .cardImage(
                card.imageUrl,
                "square.grid.2x2.fill"
            )
        }
    }

    // MARK: - Main View

    var body: some View {

        Button(action: onTap) {

            GeometryReader { geometry in

                tileContent(size: geometry.size)
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height
                    )
            }
            .frame(height: 70)
            .background(.white)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: cornerRadius
                )
            )
            .overlay {

                RoundedRectangle(
                    cornerRadius: cornerRadius
                )
                .strokeBorder(
                    isSelected
                        ? accent
                        : accent.opacity(0.15),
                    lineWidth: isSelected ? 3 : 1
                )
            }
            .shadow(
                color: isSelected
                    ? accent.opacity(0.25)
                    : .black.opacity(0.04),
                radius: isSelected ? 6 : 3,
                y: 2
            )
            .scaleEffect(
                isSelected ? 1.04 : 1
            )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .accessibilityLabel(card.title)
        .accessibilityAddTraits(
            isSelected ? [.isSelected] : []
        )
    }

    // MARK: - Render Tile Content

    @ViewBuilder
    private func tileContent(
        size: CGSize
    ) -> some View {

        switch tileImageType {

        case .icon(let icon, let color):

            iconView(
                icon: icon,
                color: color,
                size: size
            )

        case .profile(let imageURL):

            profileImageView(
                url: imageURL,
                size: size
            )

        case .cardImage(let imageURL, let fallback):

            cardImageView(
                url: imageURL,
                fallbackIcon: fallback,
                size: size
            )
        }
    }

    // MARK: - Icon Tile

    private func iconView(
        icon: String,
        color: Color,
        size: CGSize
    ) -> some View {

        ZStack {

            color.opacity(0.08)

            Image(systemName: icon)
                .font(.system(
                    size: 29,
                    weight: .medium
                ))
                .foregroundStyle(color)
                .symbolRenderingMode(.hierarchical)
        }
        .frame(
            width: size.width,
            height: size.height
        )
    }

    // MARK: - User Profile Tile

    private func profileImageView(
        url: String?,
        size: CGSize
    ) -> some View {

        let diameter = max(
            1,
            min(size.width - 8, size.height - 10)
        )

        return ZStack {

            background

            remoteImage(
                url: url,
                fallbackIcon: "person.crop.circle.fill",
                width: diameter,
                height: diameter
            )
            .clipShape(Circle())
            .overlay {
                Circle()
                    .strokeBorder(
                        .white,
                        lineWidth: 2
                    )
            }
        }
        .frame(
            width: size.width,
            height: size.height
        )
    }

    // MARK: - Card Image Tile

    private func cardImageView(
        url: String?,
        fallbackIcon: String,
        size: CGSize
    ) -> some View {

        remoteImage(
            url: url,
            fallbackIcon: fallbackIcon,
            width: size.width,
            height: size.height
        )
        .clipped()
    }

    // MARK: - Remote Image With Fallback

    private func remoteImage(
        url: String?,
        fallbackIcon: String,
        width: CGFloat,
        height: CGFloat
    ) -> some View {

        let imageURL: URL? = {
            guard let url,
                  let parsed = URL(string: url),
                  ["http", "https"].contains(
                    parsed.scheme?.lowercased() ?? ""
                  )
            else {
                return nil
            }

            return parsed
        }()

        return AsyncImage(url: imageURL) { phase in

            switch phase {

            case .success(let image):

                image
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: width,
                        height: height
                    )
                    .clipped()

            case .failure, .empty:

                imagePlaceholder(
                    icon: fallbackIcon,
                    width: width,
                    height: height
                )

            @unknown default:

                imagePlaceholder(
                    icon: fallbackIcon,
                    width: width,
                    height: height
                )
            }
        }
        .frame(
            width: width,
            height: height
        )
    }

    // MARK: - Image Placeholder

    private func imagePlaceholder(
        icon: String,
        width: CGFloat,
        height: CGFloat
    ) -> some View {

        ZStack {

            background

            Image(systemName: icon)
                .font(.system(
                    size: 25,
                    weight: .medium
                ))
                .foregroundStyle(accent.opacity(0.65))
        }
        .frame(
            width: width,
            height: height
        )
    }
}
