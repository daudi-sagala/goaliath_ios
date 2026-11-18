import SwiftUI



/// Dedicated wallet screen. The server-provided UserToken.balance is the spendable

/// balance; recentTransactions may be only a partial history.

struct UserTokensDetailView: View {

    let wallet: UserToken

    var onBuyTokens: (() -> Void)? = nil

    var onSendGift: (() -> Void)? = nil



    @State private var selectedFilter: TokenHistoryFilter = .all



    private let ink = GoaliathMenuStyle.ink

    private let muted = GoaliathMenuStyle.muted

    private let accent = GoaliathMenuStyle.accent

    private let green = GoaliathMenuStyle.green

    private let gold = Color(red: 0.97, green: 0.70, blue: 0.26)



    private var filteredTransactions: [UserTokenTransaction] {

        wallet.recentTransactions

            .filter { selectedFilter.includes($0.type) }

            .sorted { $0.occurredAt > $1.occurredAt }

    }



    // Pre-group the wallet history as identifiable values instead of
    // constructing nested array/index ForEach values inside the ViewBuilder.
    private var transactionGroups: [TokenTransactionDayGroup] {
        let grouped = Dictionary(grouping: filteredTransactions) { transaction in
            Calendar.current.startOfDay(for: transaction.occurredAt)
        }
        return grouped.map { day, transactions in
            TokenTransactionDayGroup(day: day, transactions: transactions)
        }
        .sorted { $0.day > $1.day }
    }



    var body: some View {

        ScrollView(showsIndicators: false) {

            VStack(alignment: .leading, spacing: 22) {

                reachAndInfluenceIntro

                walletHero

                sourceBreakdown

                outflowBreakdown

                historySection

                explainer

            }

            .frame(maxWidth: 680)

            .frame(maxWidth: .infinity)

            .padding(.horizontal, 18)

            .padding(.top, 18)

            .padding(.bottom, 34)

        }

        .background(GoaliathMenuStyle.background.ignoresSafeArea())

        .navigationTitle("My Tokens")

        .navigationBarTitleDisplayMode(.inline)

    }



    // MARK: - The value of tokens (appears above My Wallet)

    private var reachAndInfluenceIntro: some View {
        VStack(alignment: .leading, spacing: 17) {
            HStack(spacing: 7) {
                Image(systemName: "circle.hexagongrid.fill")
                    .foregroundStyle(gold)
                Text("THE POWER OF GOALIATH TOKENS")
                    .foregroundStyle(green)
            }
            .font(.system(size: 11, weight: .heavy, design: .rounded))
            .tracking(1.15)

            Text("Tokens give you reach and influence.")
                .font(.custom("Fredoka-SemiBold", size: 34))
                .tracking(-0.8)
                .foregroundStyle(ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            Text("Your next opportunity could be outside your circle. Use tokens to bring your goals, requests and ideas to people who might be able to help — even if you've never met them.")
                .font(.custom("Nunito-Regular", size: 16))
                .foregroundStyle(muted)
                .fixedSize(horizontal: false, vertical: true)

            // A photographic community image gives the concept a human face.
            // Uses a remote photo and an offline-friendly native fallback.
            TokenReachCommunityImage()
                .frame(height: 182)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("100")
                        .font(.system(size: 31, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                    Text("TOKENS")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .tracking(1)
                }
                .foregroundStyle(ink)

                Spacer(minLength: 0)
                Image(systemName: "arrow.right")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(green)
                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 2) {
                    Text("1,000+")
                        .font(.system(size: 31, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                    Text("FOLLOWERS")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .tracking(0.6)
                }
                .foregroundStyle(green)
            }
            .padding(15)
            .frame(maxWidth: .infinity)
            .background(
                Color(red: 0.91, green: 0.965, blue: 0.94),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Example: 100 tokens can expand your potential audience to more than 1,000 people")

            VStack(alignment: .leading, spacing: 10) {
                Text("Choose who you reach.")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(ink)

                Text("Focus your reach on the networks, communities and locations that matter to your goal.")
                    .font(.subheadline)
                    .foregroundStyle(muted)
                    .fixedSize(horizontal: false, vertical: true)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 7) {
                        tokenReachAudienceChip("My networks", icon: "person.2.fill")
                        tokenReachAudienceChip("My city", icon: "building.2.fill")
                        tokenReachAudienceChip("Local area", icon: "location.fill")
                    }
                    VStack(alignment: .leading, spacing: 7) {
                        tokenReachAudienceChip("My networks", icon: "person.2.fill")
                        HStack(spacing: 7) {
                            tokenReachAudienceChip("My city", icon: "building.2.fill")
                            tokenReachAudienceChip("Local area", icon: "location.fill")
                        }
                    }
                }
            }

            HStack(alignment: .top, spacing: 9) {
                Image(systemName: "person.3.sequence.fill")
                    .font(.system(size: 17))
                    .foregroundStyle(accent)
                    .padding(.top, 1)
                Text("The more tokens you use, the more people you can potentially reach — and the more opportunities you have to be seen, heard and helped.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(ink)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text("Reach illustration, not a guaranteed number of views or responses. Your actual audience depends on available members and your selected networks or areas.")
                .font(.caption2)
                .foregroundStyle(muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(19)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 23, style: .continuous))
    }

    private func tokenReachAudienceChip(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(accent)
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .background(accent.opacity(0.09), in: Capsule())
            .fixedSize(horizontal: true, vertical: false)
    }

    private var walletHero: some View {

        VStack(alignment: .leading, spacing: 15) {

            HStack(spacing: 8) {

                Image(systemName: "circle.hexagongrid.fill")

                    .font(.system(size: 18, weight: .bold))

                    .foregroundStyle(gold)

                Text("MY GOALIATH WALLET")

                    .font(.system(size: 12, weight: .heavy, design: .rounded))

                    .tracking(1.2)

                    .foregroundStyle(.white.opacity(0.8))

                Spacer()

            }



            VStack(alignment: .leading, spacing: 2) {

                Text("Available tokens")

                    .font(.subheadline.weight(.semibold))

                    .foregroundStyle(.white.opacity(0.83))

                HStack(alignment: .firstTextBaseline, spacing: 9) {

                    Text(wallet.balance.formatted())

                        .font(.system(size: 52, weight: .heavy, design: .rounded))

                        .monospacedDigit()

                        .contentTransition(.numericText())

                    Text("tokens")

                        .font(.headline)

                        .foregroundStyle(.white.opacity(0.8))

                }

                .foregroundStyle(.white)

                .accessibilityElement(children: .combine)

            }



            Text("Use tokens to reward helpful members and support your goals.")

                .font(.subheadline)

                .foregroundStyle(.white.opacity(0.83))

                .fixedSize(horizontal: false, vertical: true)



            if onBuyTokens != nil || onSendGift != nil {

                HStack(spacing: 10) {

                    if let onBuyTokens {

                        walletAction("Buy tokens", icon: "plus.circle.fill", filled: true, action: onBuyTokens)

                    }

                    if let onSendGift {

                        walletAction("Send a gift", icon: "gift.fill", filled: false, action: onSendGift)

                    }

                }

                .padding(.top, 4)

            }

        }

        .padding(22)

        .frame(maxWidth: .infinity, alignment: .leading)

        .background(LinearGradient(colors: [GoaliathMenuStyle.accent, GoaliathMenuStyle.purple], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 23))

        .shadow(color: accent.opacity(0.18), radius: 16, y: 8)

    }



    private func walletAction(_ title: String, icon: String, filled: Bool, action: @escaping () -> Void) -> some View {

        Button(action: action) {

            Label(title, systemImage: icon)

                .font(.system(size: 13, weight: .bold, design: .rounded))

                .lineLimit(1)

                .minimumScaleFactor(0.8)

                .frame(maxWidth: .infinity)

                .frame(height: 45)

                .foregroundStyle(filled ? accent : .white)

                .background(filled ? Color.white : Color.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))

        }

        .buttonStyle(.plain)

    }



    private var sourceBreakdown: some View {

        VStack(alignment: .leading, spacing: 12) {

            sectionHeading("Source of my tokens", symbol: "circle.hexagongrid.fill")

            HStack(spacing: 9) {

                sourceTile("Earned", amount: wallet.earnedTotal, icon: "star.fill", tint: green)

                sourceTile("Bought", amount: wallet.purchasedTotal, icon: "bag.fill", tint: accent)

                sourceTile("Gifted to you", amount: wallet.giftsReceivedTotal, icon: "gift.fill", tint: GoaliathMenuStyle.purple)

            }

        }

    }



    private func sourceTile(_ title: String, amount: Int, icon: String, tint: Color) -> some View {

        VStack(alignment: .leading, spacing: 10) {

            Image(systemName: icon)

                .font(.system(size: 15, weight: .semibold))

                .foregroundStyle(tint)

                .frame(width: 31, height: 31)

                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))

            Text(amount.formatted())

                .font(.system(size: 21, weight: .heavy, design: .rounded))

                .monospacedDigit()

                .foregroundStyle(ink)

                .minimumScaleFactor(0.7)

                .lineLimit(1)

            Text(title)

                .font(.system(size: 11, weight: .semibold, design: .rounded))

                .foregroundStyle(muted)

                .fixedSize(horizontal: false, vertical: true)

        }

        .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)

        .padding(12)

        .background(.white, in: RoundedRectangle(cornerRadius: 19, style: .continuous))

    }



    private var outflowBreakdown: some View {

        HStack(spacing: 10) {

            outflowTile(title: "Gifts sent", value: wallet.giftsSentTotal, symbol: "gift")

            outflowTile(title: "Tokens used", value: wallet.spentTotal, symbol: "arrow.up.right")

        }

    }



    private func outflowTile(title: String, value: Int, symbol: String) -> some View {

        HStack(spacing: 10) {

            Image(systemName: symbol)

                .foregroundStyle(accent)

                .frame(width: 30, height: 30)

                .background(accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 9))

            VStack(alignment: .leading, spacing: 3) {

                Text(title).font(.caption).foregroundStyle(muted)

                Text(value.formatted()).font(.system(size: 18, weight: .bold, design: .rounded)).foregroundStyle(ink)

            }

            Spacer(minLength: 0)

        }

        .padding(12)

        .frame(maxWidth: .infinity)

        .background(.white, in: RoundedRectangle(cornerRadius: 17))

    }



    private var historySection: some View {

        VStack(alignment: .leading, spacing: 14) {

            sectionHeading("Token activity", symbol: "clock.arrow.circlepath")

            ScrollView(.horizontal, showsIndicators: false) {

                HStack(spacing: 8) {

                    ForEach(TokenHistoryFilter.allCases) { filter in

                        Button { withAnimation(.easeInOut(duration: 0.2)) { selectedFilter = filter } } label: {

                            Text(filter.title)

                                .font(.system(size: 13, weight: .bold, design: .rounded))

                                .foregroundStyle(selectedFilter == filter ? .white : ink)

                                .padding(.horizontal, 14)

                                .padding(.vertical, 10)

                                .background(selectedFilter == filter ? accent : Color.white, in: Capsule())

                        }

                        .buttonStyle(.plain)

                    }

                }

            }



            if filteredTransactions.isEmpty {

                VStack(spacing: 8) {

                    Image(systemName: "tray")

                        .font(.system(size: 29))

                        .foregroundStyle(muted)

                    Text("No transactions in this category")

                        .font(.subheadline.weight(.semibold))

                        .foregroundStyle(ink)

                    Text("Your recent token activity will appear here.")

                        .font(.caption)

                        .foregroundStyle(muted)

                }

                .frame(maxWidth: .infinity)

                .padding(.vertical, 30)

                .background(.white, in: RoundedRectangle(cornerRadius: 18))

            } else {
                VStack(alignment: .leading, spacing: 13) {
                    ForEach(transactionGroups) { group in
                        transactionDaySection(group)
                    }
                }
            }

            Text("Recent transactions shown. Your available balance may include activity not listed here.")

                .font(.caption2)

                .foregroundStyle(muted)

        }

    }



    // Splitting each day's history into its own View avoids the type-inference
    // error that Xcode reported on the old nested ForEach expression.
    private func transactionDaySection(_ group: TokenTransactionDayGroup) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(group.day.formatted(.dateTime.month(.abbreviated).day().year()))
                .font(.caption.weight(.bold))
                .foregroundStyle(muted)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(group.transactions) { transaction in
                    transactionRow(transaction)
                    if transaction.id != group.transactions.last?.id {
                        Divider().padding(.leading, 50)
                    }
                }
            }
            .padding(.horizontal, 14)
            .background(.white, in: RoundedRectangle(cornerRadius: 18))
        }
    }

    private func transactionRow(_ item: UserTokenTransaction) -> some View {

        HStack(spacing: 12) {

            Image(systemName: item.type.symbol)

                .font(.system(size: 15, weight: .bold))

                .foregroundStyle(item.amount >= 0 ? green : accent)

                .frame(width: 38, height: 38)

                .background((item.amount >= 0 ? green : accent).opacity(0.10), in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 3) {

                Text(item.type.title)

                    .font(.system(size: 14, weight: .bold, design: .rounded))

                    .foregroundStyle(ink)

                Text(item.note)

                    .font(.caption)

                    .foregroundStyle(muted)

                    .fixedSize(horizontal: false, vertical: true)

                Text(item.occurredAt.formatted(date: .omitted, time: .shortened))

                    .font(.caption2)

                    .foregroundStyle(muted)

            }

            Spacer(minLength: 4)

            Text("\(item.amount > 0 ? "+" : "")\(item.amount.formatted())")

                .font(.system(size: 17, weight: .heavy, design: .rounded))

                .monospacedDigit()

                .foregroundStyle(item.amount >= 0 ? green : ink)

        }

        .padding(.vertical, 13)

    }



    private var explainer: some View {

        VStack(alignment: .leading, spacing: 9) {

            Label("How tokens work", systemImage: "info.circle")

                .font(.headline)

                .foregroundStyle(ink)

            Text("Earn tokens for eligible contributions, purchase more when available, or receive them as gifts from members. When you gift tokens, they transfer from your balance to the recipient. Gifts never create extra tokens.")

                .font(.subheadline)

                .foregroundStyle(muted)

                .fixedSize(horizontal: false, vertical: true)

        }

        .padding(18)

        .frame(maxWidth: .infinity, alignment: .leading)

        .background(.white, in: RoundedRectangle(cornerRadius: 20))

    }



    private func sectionHeading(_ title: String, symbol: String) -> some View {

        Label(title, systemImage: symbol)

            .font(.system(size: 18, weight: .bold, design: .rounded))

            .foregroundStyle(ink)

    }

}



// Internal helper only for the wallet screen. No changes to your user models.
private struct TokenTransactionDayGroup: Identifiable {
    let day: Date
    let transactions: [UserTokenTransaction]
    var id: Date { day }
}

private enum TokenHistoryFilter: String, CaseIterable, Identifiable {

    case all, earned, bought, gifts, used, other

    var id: String { rawValue }

    var title: String {

        switch self {

        case .all: return "All"

        case .earned: return "Earned"

        case .bought: return "Bought"

        case .gifts: return "Gifts"

        case .used: return "Used"

        case .other: return "Other"

        }

    }

    func includes(_ type: UserTokenTransactionType) -> Bool {

        switch self {

        case .all: return true

        case .earned: return type == .earned

        case .bought: return type == .purchased

        case .gifts: return type == .giftReceived || type == .giftSent

        case .used: return type == .spent

        case .other: return type == .expired || type == .refunded

        }

    }

}



private extension UserTokenTransactionType {

    var symbol: String {

        switch self {

        case .earned: return "star.fill"

        case .purchased: return "bag.fill"

        case .giftReceived: return "gift.fill"

        case .giftSent: return "paperplane.fill"

        case .spent: return "arrow.up.right"

        case .expired: return "clock.fill"

        case .refunded: return "arrow.uturn.backward"

        }

    }

}

// MARK: - Community photo used by the reach introduction

private struct TokenReachCommunityImage: View {
    // Remote image: replace with your own licensed asset if you prefer to ship offline.
    // This view never blocks the wallet when the member is offline.
    private let photoURL = URL(string:
        "https://images.unsplash.com/photo-1529156069898-49953e39b3ac?auto=format&fit=crop&w=1200&q=85"
    )

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottomLeading) {
                AsyncImage(url: photoURL) { phase in
                    if case let .success(image) = phase {
                        image.resizable().scaledToFill()
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            .clipped()
                    } else {
                        ZStack {
                            LinearGradient(
                                colors: [
                                    Color(red: 0.23, green: 0.45, blue: 0.62),
                                    Color(red: 0.15, green: 0.25, blue: 0.43)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 70, weight: .light))
                                .foregroundStyle(.white.opacity(0.35))
                        }
                        .frame(width: proxy.size.width, height: proxy.size.height)
                    }
                }

                LinearGradient(
                    colors: [.clear, .black.opacity(0.72)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Your next connection is out there.")
                        .font(.system(size: 19, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Expand beyond the people you already know.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.94))
                }
                .padding(17)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
        .accessibilityLabel("A community of people representing new connections on Goaliath")
    }
}
