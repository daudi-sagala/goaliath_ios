import SwiftUI

enum GoaliathMenuDestination: String, Identifiable {
    case profile
    case chats
    case contributions
    case support

    var id: String { rawValue }
}

struct SideMenuView: View {
    let primary: Color
    let secondary: Color
    let accent: Color
    let onSelect: (GoaliathMenuDestination) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Goaliath")
                .font(.system(size: 27, weight: .bold, design: .rounded))
                .foregroundStyle(primary)
                .padding(.top, 50)
                .padding(.bottom, 24)

            Divider()
                .padding(.bottom, 18)

            menuButton("My Profile", icon: "person.crop.circle", destination: .profile)
            menuButton("My Chats", icon: "bubble.left.and.bubble.right", destination: .chats)
            menuButton("My Contributions", icon: "square.stack.3d.up", destination: .contributions)
            menuButton("Chat with Support", icon: "questionmark.bubble", destination: .support)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 22,
                topTrailingRadius: 22
            )
            .fill(.white)
            .ignoresSafeArea(edges: .vertical)
        )
    }

    private func menuButton(
        _ title: String,
        icon: String,
        destination: GoaliathMenuDestination
    ) -> some View {
        Button {
            onSelect(destination)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 21, weight: .medium))
                    .foregroundStyle(accent)
                    .frame(width: 28)

                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(primary)

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(secondary.opacity(0.65))
            }
            .padding(.horizontal, 12)
            .frame(height: 58)
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}
