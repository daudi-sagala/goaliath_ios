import SwiftUI

/// Replace ONLY the existing right-hand button inside your TopOverlay HStack
/// with this view. Do not add a second TopOverlay declaration.
struct GoaliathTokenHeaderButton: View {
    let wallet: UserToken
    var onBuyTokens: (() -> Void)? = nil
    var onSendGift: (() -> Void)? = nil

    @State private var showDetails = false

    private let ink = GoaliathMenuStyle.ink

    var body: some View {
        Button { showDetails = true } label: {
            HStack(spacing: 2) {
                Image(systemName: "circle.hexagongrid.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color(red: 0.92, green: 0.62, blue: 0.19))
                Text(wallet.balance.formatted())
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .contentTransition(.numericText())
                    .foregroundStyle(Color(red: 0.92, green: 0.62, blue: 0.19))
            }
            .padding(.horizontal, 13)
            .frame(minHeight: 40)
            .background(.white, in: Capsule())
            .overlay(Capsule().strokeBorder(GoaliathMenuStyle.accent.opacity(0.14), lineWidth: 1))
            .shadow(color: ink.opacity(0.06), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(wallet.balance.formatted()) Goaliath tokens. View wallet")
        .sheet(isPresented: $showDetails) {
            NavigationStack {
                UserTokensDetailView(
                    wallet: wallet,
                    onBuyTokens: onBuyTokens,
                    onSendGift: onSendGift
                )
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { showDetails = false }
                    }
                }
            }
            .presentationDragIndicator(.visible)
        }
    }
}
