import SwiftUI
import CoreData


struct RootView: View {
    @EnvironmentObject private var auth: AuthService
    @Environment(\.scenePhase) private var scenePhase
    @FetchRequest(sortDescriptors: []) private var profiles: FetchedResults<UserProfile>

    @AppStorage("faceIDEnabled") private var faceIDEnabled = false
    @State private var isLocked = true

    private var hasProfile: Bool {
        profiles.contains { $0.accountID == auth.uid }
    }

    var body: some View {
        Group {
            if !auth.isSignedIn {
                WelcomeView()
            } else if !hasProfile {
                OnboardingView()
            } else if faceIDEnabled && isLocked {
                AppLockView { isLocked = false }
            } else {
                MainTabView()
            }
        }
        .animation(.easeInOut, value: auth.isSignedIn)
        .animation(.easeInOut, value: hasProfile)
        .animation(.easeInOut, value: isLocked)
        // Lock again whenever the app goes to the background
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { isLocked = true }
        }
        // Just signed in with the password, so no need to unlock again
        .onChange(of: auth.isSignedIn) { _, signedIn in
            if signedIn { isLocked = false }
        }
        // Turning Face ID on from Settings shouldn't lock you out straight away
        .onChange(of: faceIDEnabled) {
            isLocked = false
        }
    }
}
