import SwiftUI

// Settings (account section for now)
struct SettingsView: View {
    @EnvironmentObject private var auth: AuthService
    @State private var confirmSignOut = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section("Safety") {
                NavigationLink("Emergency contact") {
                    EmergencyContactView()
                }
            }
            Section("Your account") {
                NavigationLink("Profile & security") {
                    ProfileView()
                }
                LabeledContent("Signed in as", value: auth.email ?? "—")
                Button("Sign out", role: .destructive) { confirmSignOut = true }
            }
            if let errorMessage {
                Text(errorMessage).foregroundStyle(AppColors.emergency)
            }
        }
        .navigationTitle("Settings & privacy")
        .confirmationDialog("Sign out of CareWatch?", isPresented: $confirmSignOut, titleVisibility: .visible) {
            Button("Sign out", role: .destructive) {
                do { try auth.signOut() } catch { errorMessage = AuthService.message(for: error) }
            }
        } message: {
            Text("Your reminders and history stay on this iPhone.")
        }
    }
}
