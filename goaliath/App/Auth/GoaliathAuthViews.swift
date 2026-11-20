import SwiftUI

private enum GoaliathAuthPalette {
    static let background = Color(red: 237/255, green: 246/255, blue: 249/255)
    static let ink = Color(red: 23/255, green: 54/255, blue: 77/255)
    static let accent = Color(red: 42/255, green: 110/255, blue: 148/255)
}

struct GoaliathSignInView: View {
    @EnvironmentObject private var auth: GoaliathAuthStore
    @State private var isSignUp: Bool

    init(startInSignUpMode: Bool = false) {
        _isSignUp = State(initialValue: startInSignUpMode)
    }
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var validationError: String?

    private var cleanEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Goaliath")
                        .font(.system(size: 46, weight: .bold, design: .rounded))
                        .foregroundStyle(GoaliathAuthPalette.ink)
                    Text("Find your network. Reach your goals.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 38)
                .padding(.bottom, 10)

                VStack(alignment: .leading, spacing: 5) {
                    Text(isSignUp ? "Join Goaliath" : "Welcome back")
                        .font(.title2.bold())
                        .foregroundStyle(GoaliathAuthPalette.ink)
                    Text(isSignUp ? "Create an account to explore your network." : "Sign in to continue exploring your network.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 12) {
                    if isSignUp {
                        TextField("Your name", text: $name)
                            .textContentType(.name)
                            .textInputAutocapitalization(.words)
                            .goaliathInputStyle()
                    }

                    TextField("Email address", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .goaliathInputStyle()

                    HStack {
                        Group {
                            if showPassword {
                                TextField("Password", text: $password)
                            } else {
                                SecureField("Password", text: $password)
                            }
                        }
                        .textContentType(isSignUp ? .newPassword : .password)
                        Button {
                            showPassword.toggle()
                        } label: {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityLabel(showPassword ? "Hide password" : "Show password")
                    }
                    .goaliathInputStyle()
                }

                if isSignUp {
                    Text("Use at least 8 characters.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let error = validationError ?? auth.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button(action: {
                    _Concurrency.Task { await submit() }
                }, label: {
                    HStack(spacing: 10) {
                        if auth.busy { ProgressView().tint(.white) }
                        Text(auth.busy ? "Please wait…" : isSignUp ? "Create account" : "Sign in")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                })
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .background(GoaliathAuthPalette.accent, in: RoundedRectangle(cornerRadius: 15))
                .disabled(auth.busy)

                HStack {
                    Rectangle().frame(height: 1).foregroundStyle(.quaternary)
                    Text("or continue with")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize()
                    Rectangle().frame(height: 1).foregroundStyle(.quaternary)
                }

                VStack(spacing: 10) {
                    disabledSocialButton(label: "Apple", icon: "apple.logo")
                    disabledSocialButton(label: "Google", icon: "g.circle.fill")
                }

                Button {
                    isSignUp.toggle()
                    password = ""
                    validationError = nil
                    auth.errorMessage = nil
                } label: {
                    Text(isSignUp ? "Already have an account? Sign in" : "New to Goaliath? Create an account")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(GoaliathAuthPalette.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .disabled(auth.busy)

                Text("Apple and Google sign-in are coming later. Email and password are enabled for testing.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: 440)
            .padding(.horizontal, 26)
            .padding(.bottom, 38)
            .frame(maxWidth: .infinity)
        }
        .background(GoaliathAuthPalette.background.ignoresSafeArea())
    }

    private func disabledSocialButton(label: String, icon: String) -> some View {
        // Even if UI flags change, these controls stay disabled until proper
        // Apple/Google authentication is implemented on client AND server.
        Button {} label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                Text("Continue with \(label)")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("Soon")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 16)
            .frame(height: 50)
            .background(.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.gray.opacity(0.2)))
        }
        .disabled(true)
        .accessibilityHint("Sign in with \(label) is currently unavailable.")
    }

    private func submit() async {
        validationError = nil
        let hasValidEmail = cleanEmail.contains("@") && cleanEmail.split(separator: "@").count == 2
        guard hasValidEmail else {
            validationError = "Enter a valid email address."
            return
        }
        guard !password.isEmpty else {
            validationError = "Enter your password."
            return
        }
        if isSignUp {
            let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !cleanName.isEmpty else {
                validationError = "Enter your name."
                return
            }
            guard password.count >= 8, password.count <= 128 else {
                validationError = "Your password must be between 8 and 128 characters."
                return
            }
            await auth.signUp(name: cleanName, email: cleanEmail, password: password)
        } else {
            await auth.signIn(email: cleanEmail, password: password)
        }
        if auth.user != nil { password = "" }
    }
}

private struct GoaliathInputStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.body)
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(.white, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.gray.opacity(0.18)))
    }
}

private extension View {
    func goaliathInputStyle() -> some View {
        modifier(GoaliathInputStyle())
    }
}
