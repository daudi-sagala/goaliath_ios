import SwiftUI

/// Replaces only the bottom tile row, leaving TopOverlay and VerticalRightOverlay alone.
/// Uses the app's existing CardData for discovery slots.
struct GoaliathPinnedBottomBar: View {
    let cards: [CardData]
    @Binding var selectedCard: CardData
    let pinnedActivity: GoaliathScheduleActivity?
    let currentPage: Int
    let pageCount: Int
    let slideDirection: TileSlideDirection
    let now: Date
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onPinnedTap: (GoaliathScheduleActivity) -> Void

    private let navy = Color(red: 0.149, green: 0.231, blue: 0.333)
    private let green = Color(red: 0.08, green: 0.61, blue: 0.42)
    private let blue = Color(red: 0.322, green: 0.435, blue: 0.647)

    var body: some View {
        VStack(spacing: 9) {
            HStack(spacing: 8) {
                Label(pinnedActivity == nil ? "Discover" : "Now & discover", systemImage: "square.grid.2x2.fill")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(navy)
                Spacer()
                Button(action: onPrevious) {
                    Image(systemName: "chevron.left")
                        .frame(width: 30, height: 28)
                }
                .accessibilityLabel("Previous cards")
                .disabled(pageCount <= 1)
                Text("\(currentPage) / \(pageCount)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(navy.opacity(0.7))
                Button(action: onNext) {
                    Image(systemName: "chevron.right")
                        .frame(width: 30, height: 28)
                }
                .accessibilityLabel("Next cards")
                .disabled(pageCount <= 1)
            }
            .buttonStyle(.plain)

            HStack(alignment: .top, spacing: 6) {
                if let pinnedActivity {
                    pinnedTile(pinnedActivity)
                }
                ForEach(cards, id: \.cardDataId) { card in
                    discoveryTile(card)
                }
                // An empty discovery slot is deliberate; don't duplicate cards.
                ForEach(0..<max(0, 5 - cards.count - (pinnedActivity == nil ? 0 : 1)), id: \.self) { _ in
                    emptyTile
                }
            }
            .animation(.easeInOut(duration: 0.25), value: pinnedActivity?.id)
            .animation(.easeInOut(duration: 0.25), value: currentPage)
        }
        .padding(11)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 21))
        .overlay {
            RoundedRectangle(cornerRadius: 21)
                .strokeBorder(navy.opacity(0.06), lineWidth: 1)
        }
    }

    private func pinnedTile(_ activity: GoaliathScheduleActivity) -> some View {
        Button { onPinnedTap(activity) } label: {
            VStack(spacing: 5) {
                Image(systemName: activity.kind.pinnedSymbol)
                    .font(.system(size: 23, weight: .semibold))
                    .frame(height: 31)
                Text(activity.status == .inProgress ? "IN PROGRESS" :
                     activity.startsAt <= now ? "READY" : "UP NEXT")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(activity.title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(navy)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(height: 28)
                Text(activity.endsAt.map { "Until \($0.formatted(date: .omitted, time: .shortened))" }
                     ?? activity.startsAt.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 9, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle(green)
            .frame(maxWidth: .infinity)
            .frame(height: 124)
            .padding(.horizontal, 3)
            .background(Color(red: 0.85, green: 0.95, blue: 0.90),
                        in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(green, lineWidth: 1.7))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Pinned activity: \(activity.title), \(activity.status.title)")
        .accessibilityHint("Opens activity actions")
        .frame(maxWidth: .infinity)
    }

    private func discoveryTile(_ card: CardData) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { selectedCard = card }
        } label: {
            VStack(spacing: 6) {
                AsyncImage(url: URL(string: card.imageUrl)) { phase in
                    if case .success(let image) = phase {
                        image.resizable().scaledToFill()
                    } else {
                        Image(systemName: card.cardDataTypeId.pinnedCardSymbol)
                            .resizable().scaledToFit().padding(12)
                            .foregroundStyle(blue)
                    }
                }
                .frame(height: 60)
                .frame(maxWidth: .infinity)
                .background(Color(red: 0.88, green: 0.93, blue: 0.97))
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 11))
                Text(card.cardDataTypeTitle)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(navy)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(card.title)
                    .font(.system(size: 9))
                    .foregroundStyle(navy.opacity(0.75))
                    .lineLimit(2)
                    .frame(height: 24, alignment: .top)
                    .multilineTextAlignment(.center)
            }
            .padding(4)
            .frame(maxWidth: .infinity)
            .frame(height: 124)
            .background(selectedCard.cardDataId == card.cardDataId ? Color.white : Color.white.opacity(0.65),
                        in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(selectedCard.cardDataId == card.cardDataId ? blue : .clear, lineWidth: 1.6))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(card.cardDataTypeTitle): \(card.title)")
        .frame(maxWidth: .infinity)
    }

    private var emptyTile: some View {
        VStack {
            Image(systemName: "sparkles")
                .font(.title3)
            Text("Explore").font(.system(size: 10, weight: .medium))
        }
        .foregroundStyle(blue.opacity(0.45))
        .frame(maxWidth: .infinity)
        .frame(height: 124)
        .background(Color.white.opacity(0.4), in: RoundedRectangle(cornerRadius: 14))
    }
}

private extension TimelineCreationKind {
    var pinnedSymbol: String {
        switch self {
        case .meal: return "fork.knife"
        case .workout: return "figure.run"
        case .task: return "checkmark.circle.fill"
        default: return "calendar.badge.clock"
        }
    }
}

private extension String {
    var pinnedCardSymbol: String {
        switch self {
        case "message": return "bubble.left.fill"
        case "post": return "person.2.fill"
        case "gift": return "gift.fill"
        case "suggestedMeal": return "fork.knife"
        case "workout": return "figure.run"
        case "activity": return "calendar"
        case "task": return "checkmark.circle"
        case "userStatus": return "person.crop.circle"
        case "formData": return "text.book.closed"
        default: return "sparkles"
        }
    }
}
