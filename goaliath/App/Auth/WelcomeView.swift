import SwiftUI

/// Public landing screen. Sign-in and account creation both use the same
/// email/password form and single GoaliathAuthStore supplied by MainView.
struct WelcomeView: View {
    @EnvironmentObject private var auth: GoaliathAuthStore
    @State private var showAuthentication = false
    @State private var createAccount = false

    private let navy = Color(hex: "263B55")
    private let blue = Color(hex: "526FA5")

    var body: some View {
        VStack(spacing: 25) {
            Spacer(minLength: 24)
            VStack(spacing: 4) {
                Text("Goaliath")
                    .font(.custom("Fredoka-SemiBold", size: 54))
                    .foregroundStyle(navy)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                Text("ORGANIZE  ·  CONNECT  ·  ACHIEVE")
                    .font(.custom("Nunito-Bold", size: 13))
                    .tracking(1.1)
                    .foregroundStyle(blue)
            }
            Spacer()
            VStack(spacing: 12) {
                Text("Discover the hidden networks around you.")
                    .font(.custom("Fredoka-SemiBold", size: 32))
                    .foregroundStyle(navy)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Find the people, connections, and opportunities that can help you reach your goals.")
                    .font(.custom("Nunito-Regular", size: 17))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            VStack(spacing: 12) {
                Button {
                    presentAuthentication(signUp: false)
                } label: {
                    Label("Sign in with email", systemImage: "envelope.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                }
                .foregroundStyle(.white)
                .background(blue, in: RoundedRectangle(cornerRadius: 15))
                .buttonStyle(.plain)

                Button {
                    presentAuthentication(signUp: true)
                } label: {
                    Text("Create an account")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                }
                .foregroundStyle(navy)
                .background(.white, in: RoundedRectangle(cornerRadius: 15))
                .buttonStyle(.plain)

                Text("Apple and Google sign-in will be available later.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                if let error = auth.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                    Button("Retry session check") {
                        _Concurrency.Task { await auth.retryRestore() }
                    }
                    .font(.caption.weight(.semibold))
                }
            }
            Spacer(minLength: 14)
        }
        .padding(.horizontal, 26)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "EDF6F9").ignoresSafeArea())
        .sheet(isPresented: $showAuthentication) {
            NavigationStack {
                GoaliathSignInView(startInSignUpMode: createAccount)
                    .id(createAccount)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Close") { showAuthentication = false }
                        }
                    }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .onChange(of: auth.user?.id) { _, newID in
            if newID != nil { showAuthentication = false }
        }
    }

    private func presentAuthentication(signUp: Bool) {
        createAccount = signUp
        auth.errorMessage = nil
        showAuthentication = true
    }
}

extension Color {
    init(hex: String) {
        let value = UInt64(hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")), radix: 16) ?? 0
        self.init(
            .sRGB,
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255,
            opacity: 1
        )
    }
}
