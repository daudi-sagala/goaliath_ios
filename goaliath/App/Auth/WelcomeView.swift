import SwiftUI
import AuthenticationServices

/// Native Apple + email verification code onboarding
struct WelcomeView: View {
    var geometry:GeometryProxy
    @StateObject private var apple=GoaliathAppleSignIn()
    @State private var email=""
    @State private var code=""
    @State private var showEmail=false
    @State private var awaitingCode=false
    @State private var busy=false
    @State private var errorMessage:String?

    private let navy=Color(hex:"263B55")
    private let blue=Color(hex:"526FA5")
    var body:some View {
        VStack(spacing:28) {
            Spacer(minLength:20)
            VStack(spacing:3) {
                Text("Goaliath").font(.custom("Fredoka-SemiBold",size:54)).foregroundStyle(navy)
              
                Text("ORGANIZE  ·  CONNECT  ·  ACHIEVE")
                    .font(.custom("Nunito-Bold", size: 14))
                    .tracking(1.2)
                    .foregroundStyle(blue)
            }
            Spacer()
            VStack(spacing:8) {
                Text("Discover the hidden networks around you.")
                    .font(.custom("Fredoka-SemiBold",size:34)).multilineTextAlignment(.center)
                Text("Find people and opportunities connected to what you want to achieve.")
                    .font(.custom("Nunito-Regular",size:18))
                    .multilineTextAlignment(.center).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(spacing:15) {
                SignInWithAppleButton(.continue,onRequest:apple.configure,onCompletion:apple.handle)
                    .signInWithAppleButtonStyle(.black)
                    .frame(height:54).clipShape(RoundedRectangle(cornerRadius:15))
                    .disabled(apple.signingIn)
                Button {showEmail=true} label: {
                    Label("Continue with Email",systemImage:"envelope")
                        .font(.headline).frame(maxWidth:.infinity).frame(height:54)
                        .background(.white,in:RoundedRectangle(cornerRadius:15))
                }.buttonStyle(.plain)
                Text("By continuing, you agree to our Terms and Privacy Policy.")
                    .font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center)
                if let message=apple.errorMessage {Text(message).foregroundStyle(.red).font(.caption)}
            }
            Spacer(minLength:12)
        }
        .padding(.horizontal,26)
        .frame(maxWidth:.infinity,maxHeight:.infinity)
        .background(Color(hex:"EDF6F9").ignoresSafeArea())
        .sheet(isPresented:$showEmail) {emailSheet.presentationDetents([.medium,.large])}
    }

    private var emailSheet:some View {
        NavigationStack {
            VStack(alignment:.leading,spacing:17) {
                Text(awaitingCode ? "Check your email" : "Continue with email")
                    .font(.system(size:26,weight:.bold,design:.rounded)).foregroundStyle(navy)
                Text(awaitingCode ? "Enter the 6-digit code sent to \(email)." : "We'll email you a one-time code. No password required.")
                    .font(.subheadline).foregroundStyle(.secondary)
                if !awaitingCode {
                    TextField("Email address",text:$email)
                        .keyboardType(.emailAddress).textInputAutocapitalization(.never)
                        .textContentType(.emailAddress).autocorrectionDisabled()
                        .padding(14).background(.white,in:RoundedRectangle(cornerRadius:12))
                } else {
                    TextField("6-digit code",text:$code)
                        .keyboardType(.numberPad).textContentType(.oneTimeCode)
                        .padding(14).background(.white,in:RoundedRectangle(cornerRadius:12))
                }
                if let errorMessage {Text(errorMessage).foregroundStyle(.red).font(.caption)}
                Button(busy ? "Please wait…" : (awaitingCode ? "Sign in" : "Send code")) {authenticate()}
                    .font(.headline).foregroundStyle(.white)
                    .frame(maxWidth:.infinity).frame(height:52)
                    .background(blue,in:RoundedRectangle(cornerRadius:14))
                    .disabled(busy || (awaitingCode ? code.count != 6 : !email.contains("@")))
                if awaitingCode {
                    Button("Use a different email") {awaitingCode=false;code="";errorMessage=nil}
                        .foregroundStyle(blue)
                    Button("Resend code") {sendCode()}.disabled(busy)
                        .font(.subheadline).foregroundStyle(blue)
                }
                Spacer(minLength:0)
            }.padding(22)
                .toolbar {ToolbarItem(placement:.topBarTrailing) {Button("Close") {showEmail=false}}}
        }
    }
    private func sendCode() {
        busy=true;errorMessage=nil
        _Concurrency.Task { @MainActor in
            defer{busy=false}
            do {try await AppManager.shared.requestEmailCode(email);awaitingCode=true}
            catch{errorMessage=error.localizedDescription}
        }
    }
    private func authenticate() {
        if !awaitingCode {sendCode();return}
        busy=true;errorMessage=nil
        _Concurrency.Task { @MainActor in
            defer{busy=false}
            do {
                try await AppManager.shared.signInWithEmailCode(email:email,code:code)
                showEmail=false;awaitingCode=false;code=""
            }catch{errorMessage=error.localizedDescription}
        }
    }
}

extension Color {
    init(hex: String) {
        let value = UInt64(hex, radix: 16) ?? 0

        self.init(
            .sRGB,
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255,
            opacity: 1
        )
    }
}
