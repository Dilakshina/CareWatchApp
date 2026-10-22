import SwiftUI

//  Sign in / Create account page
struct SignInView: View {
    @EnvironmentObject private var auth: AuthService

    @State var mode: AuthMode
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var infoMessage: String?
    @State private var isWorking = false

    private var isCreate: Bool { mode == .createAccount }
    private var cleanEmail: String { email.trimmingCharacters(in: .whitespaces) }
    private var canSubmit: Bool { cleanEmail.contains("@") && password.count >= 6 && !isWorking }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(isCreate ? "Create your account" : "Welcome back")
                    .font(.largeTitle.bold())
                    .foregroundStyle(AppColors.ink)
                Text(isCreate ? "It only takes a minute." : "Sign in to see your day")
                    .foregroundStyle(AppColors.secondaryText)

                Picker("Mode", selection: $mode) {
                    Text("Sign in").tag(AuthMode.signIn)
                    Text("Create account").tag(AuthMode.createAccount)
                }
                .pickerStyle(.segmented)

                FormField(label: "Email", text: $email, placeholder: "name@example.com",
                          keyboard: .emailAddress, contentType: .emailAddress)
                FormField(label: "Password", text: $password,
                          placeholder: isCreate ? "At least 6 characters" : "Your password",
                          isSecure: true, contentType: isCreate ? .newPassword : .password)

                if !isCreate {
                    Button("Forgot password?") { Task { await resetPassword() } }
                        .font(.subheadline.weight(.semibold))
                        .tint(AppColors.brandTeal)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }

                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.circle")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.emergency)
                }
                if let infoMessage {
                    Label(infoMessage, systemImage: "envelope")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.brandTeal)
                }

                PrimaryButton(title: isWorking ? "Please wait…" : (isCreate ? "Create account" : "Sign in")) {
                    Task { await submit() }
                }
                .disabled(!canSubmit)
                .opacity(canSubmit ? 1 : 0.5)

                Label("Sign-in is secured by Firebase Authentication. Your care records stay on this iPhone.",
                      systemImage: "lock")
                    .font(.footnote)
                    .foregroundStyle(AppColors.ink)
                    .padding(14)
                    .background(AppColors.mint, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(20)
        }
        .background(AppColors.background)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: mode) {
            errorMessage = nil
            infoMessage = nil
        }
    }

    private func submit() async {
        isWorking = true
        errorMessage = nil
        do {
            if isCreate {
                try await auth.createAccount(email: cleanEmail, password: password)
            } else {
                try await auth.signIn(email: cleanEmail, password: password)
            }
        } catch {
            errorMessage = AuthService.message(for: error)
        }
        isWorking = false
    }

    private func resetPassword() async {
        guard cleanEmail.contains("@") else {
            errorMessage = "Type your email above first."
            return
        }
        do {
            try await auth.resetPassword(email: cleanEmail)
            errorMessage = nil
            infoMessage = "Password reset email sent to \(cleanEmail)."
        } catch {
            errorMessage = AuthService.message(for: error)
        }
    }
}
