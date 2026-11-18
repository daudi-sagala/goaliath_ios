import SwiftUI

struct UserProfileView: View {
    var profile: UserProfile = GoaliathMenuDemoData.profile
    @State private var showHistory = false

    private var money: UserToken { profile.tokens }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                hero
                tokenWallet
                goalsSection
            }
            .padding(18)
            .padding(.bottom, 30)
        }
        .background(GoaliathMenuStyle.background.ignoresSafeArea())
        .navigationTitle("My Profile")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showHistory) {
            NavigationStack {
                UserTokensDetailView(wallet: money)
                    .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { showHistory = false } } }
            }
            .presentationDragIndicator(.visible)
        }
    }

    private var hero: some View {
        GoaliathMenuPanel {
            HStack(alignment: .top, spacing: 16) {
                GoaliathMenuAvatar(name: profile.fullName, size: 80, tint: GoaliathMenuStyle.accent, imageURL: profile.userImageURL)
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        Text(profile.fullName)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                        if profile.isVerified { Image(systemName: "checkmark.seal.fill").foregroundStyle(.blue) }
                    }
                    Text("@\(profile.username)").font(.subheadline).foregroundStyle(GoaliathMenuStyle.muted)
                    Label(profile.location, systemImage: "mappin.and.ellipse")
                        .font(.caption).foregroundStyle(GoaliathMenuStyle.muted)
                    Text("Member since \(profile.joinedAt.formatted(.dateTime.month(.abbreviated).year()))")
                        .font(.caption).foregroundStyle(GoaliathMenuStyle.muted)
                }
                Spacer(minLength: 0)
            }
            Text(profile.bio).font(.subheadline).foregroundStyle(GoaliathMenuStyle.ink)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 12) {
                metric(title: "Followers", value: profile.followersCount)
                metric(title: "Following", value: profile.followingCount)
                metric(title: "Active goals", value: profile.activeGoals.count)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
                    ForEach(profile.interests, id: \.self) { interest in
                        GoaliathMenuTag(text: interest, tint: GoaliathMenuStyle.accent)
                    }
                }
            }
        }
    }

    private func metric(title: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value.formatted()).font(.system(size: 19, weight: .heavy, design: .rounded)).foregroundStyle(GoaliathMenuStyle.ink)
            Text(title).font(.caption2).foregroundStyle(GoaliathMenuStyle.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
        .padding(.leading, 11)
        .background(GoaliathMenuStyle.background, in: RoundedRectangle(cornerRadius: 13))
    }

    private var tokenWallet: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Label("MY TOKENS", systemImage: "circle.hexagongrid.fill")
                    .font(.system(size: 12, weight: .heavy, design: .rounded)).tracking(1.1)
                    .foregroundStyle(Color(red: 0.92, green: 0.62, blue: 0.19))
                Spacer()
                Text("Demo balance").font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.85))
            }
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(money.balance.formatted())
                    .font(.system(size: 48, weight: .heavy, design: .rounded))
                    .contentTransition(.numericText())
                Text("available tokens").font(.subheadline.weight(.medium)).foregroundStyle(.white.opacity(0.8))
            }
            HStack(spacing: 7) {
                balanceSource(title: "Earned", value: money.earnedTotal, icon: "star.fill")
                balanceSource(title: "Bought", value: money.purchasedTotal, icon: "bag.fill")
                balanceSource(title: "Gifted to you", value: money.giftsReceivedTotal, icon: "gift.fill")
            }
            Button { showHistory = true } label: {
                HStack {
                    Text("View wallet details")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .font(.subheadline.weight(.bold))
                .foregroundStyle(GoaliathMenuStyle.ink)
                .padding(13)
                .background(.white, in: RoundedRectangle(cornerRadius: 13))
            }
            .buttonStyle(.plain)
        }
        .padding(19)
        .foregroundStyle(.white)
        .background(LinearGradient(colors: [GoaliathMenuStyle.accent, GoaliathMenuStyle.purple], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 23))
    }

    private func balanceSource(title: String, value: Int, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .lineLimit(1).minimumScaleFactor(0.8)
            Text(value.formatted()).font(.system(size: 20, weight: .bold, design: .rounded))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.white.opacity(0.13), in: RoundedRectangle(cornerRadius: 12))
    }

    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("My Goals")
                    .font(.system(size: 23, weight: .bold, design: .rounded))
                    .foregroundStyle(GoaliathMenuStyle.ink)
                Spacer()
                GoaliathMenuTag(text: "\(profile.activeGoals.count) active", tint: GoaliathMenuStyle.green)
            }
            if profile.goals.isEmpty {
                GoaliathMenuPanel { Text("No goals yet. Add your first goal from the timeline.").foregroundStyle(GoaliathMenuStyle.muted) }
            } else {
                ForEach(profile.goals) { goal in
                    GoaliathGoalRowView(goal: goal)
                }
            }
        }
    }
}

private struct GoaliathGoalRowView: View {
    let goal: UserGoal

    var body: some View {
        GoaliathMenuPanel {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: goal.category.symbol)
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(GoaliathMenuStyle.green)
                    .frame(width: 45, height: 45)
                    .background(GoaliathMenuStyle.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 13))
                VStack(alignment: .leading, spacing: 5) {
                    Text(goal.title).font(.headline).foregroundStyle(GoaliathMenuStyle.ink)
                    Text(goal.description).font(.caption).foregroundStyle(GoaliathMenuStyle.muted)
                }
                Spacer(minLength: 0)
                Text("\(Int((goal.progress * 100).rounded()))%")
                    .font(.system(size: 17, weight: .heavy, design: .rounded)).foregroundStyle(GoaliathMenuStyle.green)
            }
            ProgressView(value: goal.progress)
                .tint(GoaliathMenuStyle.green)
            HStack {
                Text("\(goal.currentValue.formatted()) / \(goal.targetValue.formatted()) \(goal.unit)")
                Spacer()
                if let deadline = goal.targetDate {
                    Text("Target: \(deadline.formatted(date: .abbreviated, time: .omitted))")
                }
            }
            .font(.caption).foregroundStyle(GoaliathMenuStyle.muted)
            HStack(spacing: 6) {
                GoaliathMenuTag(text: goal.status.rawValue.capitalized, tint: GoaliathMenuStyle.green)
                GoaliathMenuTag(text: goal.isPublic ? "Shared" : "Private", tint: GoaliathMenuStyle.accent)
            }
        }
    }
}
