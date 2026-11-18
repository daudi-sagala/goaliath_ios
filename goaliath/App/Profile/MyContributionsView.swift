import SwiftUI

struct MyContributionsView: View {
    var contributions: [GoaliathContribution] = GoaliathMenuDemoData.contributions
    @State private var selectedType: GoaliathContributionType?
    @State private var selectedContribution: GoaliathContribution?
    @State private var searchText = ""

    private var visible: [GoaliathContribution] {
        contributions
            .filter { selectedType == nil || $0.type == selectedType }
            .filter { searchText.isEmpty || $0.title.localizedCaseInsensitiveContains(searchText) || $0.detail.localizedCaseInsensitiveContains(searchText) }
            .sorted { $0.sharedAt > $1.sharedAt }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                intro
                summary
                categoryPicker
                HStack {
                    Text("Shared by you")
                        .font(.system(size: 21, weight: .bold, design: .rounded))
                        .foregroundStyle(GoaliathMenuStyle.ink)
                    Spacer()
                    Text("\(visible.count) items")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(GoaliathMenuStyle.muted)
                }
                LazyVStack(spacing: 10) {
                    ForEach(visible) { item in
                        Button { selectedContribution = item } label: { contributionRow(item) }
                            .buttonStyle(.plain)
                    }
                    if visible.isEmpty {
                        GoaliathMenuPanel {
                            Text("No contributions match these filters.")
                                .foregroundStyle(GoaliathMenuStyle.muted)
                        }
                    }
                }
            }.padding(18).padding(.bottom, 30)
        }
        .background(GoaliathMenuStyle.background.ignoresSafeArea())
        .navigationTitle("My Contributions")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search contributions")
        .sheet(item: $selectedContribution) { contribution in
            NavigationStack {
                GoaliathContributionDetailsView(contribution: contribution)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { selectedContribution = nil }
                        }
                    }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("The value you've shared")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(GoaliathMenuStyle.ink)
            Text("Requests, ideas, and activities you've contributed to the community.")
                .font(.subheadline).foregroundStyle(GoaliathMenuStyle.muted)
            Text("Sample contributions for design review")
                .font(.caption2.weight(.semibold)).foregroundStyle(GoaliathMenuStyle.green)
        }
    }

    private var summary: some View {
        GoaliathMenuPanel {
            HStack(spacing: 12) {
                stat("Shared", count: contributions.count, icon: "square.and.arrow.up.fill")
                stat("Replies", count: contributions.reduce(0) { $0 + $1.replyCount }, icon: "bubble.left.fill")
                stat("Appreciations", count: contributions.reduce(0) { $0 + $1.appreciationCount }, icon: "heart.fill")
            }
        }
    }

    private func stat(_ title: String, count: Int, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 17)).foregroundStyle(GoaliathMenuStyle.accent)
            Text(count.formatted()).font(.system(size: 22, weight: .bold, design: .rounded)).foregroundStyle(GoaliathMenuStyle.ink)
            Text(title).font(.caption2).foregroundStyle(GoaliathMenuStyle.muted)
                .lineLimit(1).minimumScaleFactor(0.75)
        }.frame(maxWidth: .infinity)
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                filterButton("All", selected: selectedType == nil) { selectedType = nil }
                ForEach(GoaliathContributionType.allCases) { type in
                    filterButton("\(type.label) (\(contributions.filter { $0.type == type }.count))", selected: selectedType == type) {
                        selectedType = type
                    }
                }
            }
        }
    }

    private func filterButton(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(selected ? .white : GoaliathMenuStyle.ink)
                .padding(.horizontal, 15).padding(.vertical, 11)
                .background(selected ? GoaliathMenuStyle.accent : Color.white, in: Capsule())
        }.buttonStyle(.plain)
    }

    private func contributionRow(_ item: GoaliathContribution) -> some View {
        GoaliathMenuPanel {
            HStack(alignment: .top, spacing: 11) {
                Image(systemName: item.type.symbol)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(GoaliathMenuStyle.accent)
                    .frame(width: 43, height: 43)
                    .background(GoaliathMenuStyle.background, in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(item.type.label.uppercased())
                            .font(.caption2.weight(.heavy)).foregroundStyle(GoaliathMenuStyle.accent)
                        Spacer()
                        Text(item.sharedAt.formatted(.dateTime.month(.abbreviated).day()))
                            .font(.caption2).foregroundStyle(GoaliathMenuStyle.muted)
                    }
                    Text(item.title)
                        .font(.headline).foregroundStyle(GoaliathMenuStyle.ink)
                        .multilineTextAlignment(.leading)
                    Text(item.detail).font(.subheadline).foregroundStyle(GoaliathMenuStyle.muted)
                        .lineLimit(2).multilineTextAlignment(.leading)
                }
            }
            HStack(spacing: 7) {
                GoaliathMenuTag(text: item.audience.label + (item.areaName.map { " · \($0)" } ?? ""), tint: GoaliathMenuStyle.green)
                Spacer(minLength: 0)
            }
            HStack(spacing: 16) {
                Label("\(item.replyCount)", systemImage: "bubble.left")
                Label("\(item.appreciationCount)", systemImage: "heart")
                Spacer()
                Label("View", systemImage: "chevron.right")
            }
            .font(.caption.weight(.medium)).foregroundStyle(GoaliathMenuStyle.muted)
        }
    }
}

private struct GoaliathContributionDetailsView: View {
    let contribution: GoaliathContribution
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                GoaliathMenuTag(text: contribution.type.label, tint: GoaliathMenuStyle.accent)
                Text(contribution.title)
                    .font(.system(size: 27, weight: .bold, design: .rounded))
                    .foregroundStyle(GoaliathMenuStyle.ink)
                Text(contribution.detail)
                    .font(.body).foregroundStyle(GoaliathMenuStyle.ink)
                Divider()
                Label("Shared \(contribution.sharedAt.formatted(date: .abbreviated, time: .shortened))", systemImage: "clock")
                Label("Audience: \(contribution.audience.label)\(contribution.areaName.map { " · \($0)" } ?? "")", systemImage: "person.2")
                Label("\(contribution.replyCount) replies", systemImage: "bubble.left")
                Label("\(contribution.appreciationCount) appreciations", systemImage: "heart")
                Text("This is a preview of your contribution. Publishing and editing actions will be connected to your Goaliath data service later.")
                    .font(.caption).foregroundStyle(GoaliathMenuStyle.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(22)
        }
        .background(GoaliathMenuStyle.background.ignoresSafeArea())
        .navigationTitle("Contribution Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}
