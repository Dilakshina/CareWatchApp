import SwiftUI
import CoreData

// Signed out then Welcome , Signed in without a profile goes to Onboarding Otherwise , the app
struct RootView: View {
    @EnvironmentObject private var auth: AuthService
    @FetchRequest(sortDescriptors: []) private var profiles: FetchedResults<UserProfile>

    private var hasProfile: Bool {
        profiles.contains { $0.accountID == auth.uid }
    }

    var body: some View {
        Group {
            if !auth.isSignedIn {
                WelcomeView()
            } else if !hasProfile {
                OnboardingView()
            } else {
                MainTabView()
            }
        }
        .animation(.easeInOut, value: auth.isSignedIn)
        .animation(.easeInOut, value: hasProfile)
    }
}
