import SwiftUI

enum GoaliathMenuStyle {
    static let background = Color(red: 0.929, green: 0.965, blue: 0.976) // EDF6F9
    static let ink = Color(red: 0.149, green: 0.231, blue: 0.333)        // 263B55
    static let muted = Color(red: 0.388, green: 0.490, blue: 0.569)
    static let accent = Color(red: 0.322, green: 0.435, blue: 0.647)
    static let green = Color(red: 0.07, green: 0.61, blue: 0.42)
    static let purple = Color(red: 0.47, green: 0.31, blue: 0.75)
}

struct GoaliathMenuPanel<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        VStack(alignment: .leading, spacing: 14) { content }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

struct GoaliathMenuAvatar: View {
    let name: String
    var size: CGFloat = 52
    var tint: Color = GoaliathMenuStyle.accent
    var imageURL: String = ""
    var body: some View {
        ZStack {
            Text(initials)
            .font(.system(size: size * 0.30, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(LinearGradient(colors: [tint, tint.opacity(0.65)], startPoint: .topLeading, endPoint: .bottomTrailing), in: Circle())
            if let url = URL(string: imageURL), let scheme = url.scheme?.lowercased(), ["https", "http"].contains(scheme) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill().frame(width: size, height: size).clipShape(Circle())
                } placeholder: { Color.clear }
            }
        }
        .accessibilityLabel(name)
    }
    private var initials: String {
        let parts = name.split(separator: " ").prefix(2)
        return parts.map { String($0.prefix(1)) }.joined().uppercased()
    }
}

struct GoaliathMenuTag: View {
    let text: String
    let tint: Color
    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .padding(.horizontal, 10).padding(.vertical, 6)
            .foregroundStyle(tint)
            .background(tint.opacity(0.10), in: Capsule())
    }
}
