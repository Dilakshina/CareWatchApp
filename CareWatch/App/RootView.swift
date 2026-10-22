import SwiftUI

// Decides which part of the app to show
struct RootView: View {
    @EnvironmentObject private var auth: AuthService

    var body: some View {
        Group {
            if auth.isSignedIn {
                MainTabView()
            } else {
                WelcomeView()
            }
        }
        .animation(.easeInOut, value: auth.isSignedIn)
    }
}
