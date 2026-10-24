import SwiftUI

//Face ID / App unlock
struct AppLockView: View {
    @EnvironmentObject private var auth: AuthService
    let onUnlock: () -> Void

    @State private var failed = false

    // Builds the locked screen prompting the user to unlock with Face ID or sign out
    var body: some View {
        VStack(spacing: 18) {
            Spacer()

            Image(systemName: "heart")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(AppColors.brandTeal)
                .frame(width: 66, height: 66)
                .background(.white, in: RoundedRectangle(cornerRadius: 20))

            Text("CareWatch is locked")
                .font(.title.bold())
            Text("Unlock to see your reminders and care history")
                .multilineTextAlignment(.center)
                .opacity(0.9)

            Image(systemName: "faceid")
                .font(.system(size: 70, weight: .light))
                .padding(36)
                .background(.white.opacity(0.15), in: Circle())
                .padding(.top, 20)

            if failed {
                Text("Couldn't unlock. Please try again.")
                    .font(.subheadline.weight(.semibold))
            }

            Spacer()

            Button {
                Task { await unlock() }
            } label: {
                Label("Unlock with Face ID", systemImage: "faceid")
                    .font(.headline)
                    .foregroundStyle(AppColors.brandTeal)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(.white, in: RoundedRectangle(cornerRadius: 18))
            }

            Button("Use password instead") {
                try? auth.signOut()
            }
            .font(.headline)
            .foregroundStyle(.white)
        }
        .foregroundStyle(.white)
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.primaryGradient.ignoresSafeArea())
        .task { await unlock() }      // ask for Face ID as soon as the screen appears
    }

    // Runs biometric authentication and unlocks the app, or flags failure
    private func unlock() async {
        if await BiometricService.authenticate() {
            onUnlock()
        } else {
            failed = true
        }
    }
}
