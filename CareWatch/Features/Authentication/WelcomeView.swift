import SwiftUI

enum AuthMode: Hashable {
    case signIn, createAccount
}

// Welcome page
struct WelcomeView: View {
    @State private var mode: AuthMode?

    // Builds the welcome screen , feature highlights and get-started actions
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    hero
                    VStack(spacing: 12) {
                        ListRow(systemImage: "bell", title: "Gentle reminders",
                                subtitle: "Medication and routines on time", showsChevron: false)
                        ListRow(systemImage: "checkmark", title: "Daily check-ins",
                                subtitle: "Let family know you're okay", showsChevron: false)
                        ListRow(systemImage: "phone", title: "One-tap family call",
                                subtitle: "Help is always one tap away", showsChevron: false)
                    }
                    .padding(20)
                }
            }
            .ignoresSafeArea(edges: .top)
            .background(AppColors.background)
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 14) {
                    PrimaryButton(title: "Get started") { mode = .createAccount }
                    Button("I already have an account") { mode = .signIn }
                        .font(.headline)
                        .tint(AppColors.brandTeal)
                }
                .padding(20)
                .background(AppColors.background)
            }
            .navigationDestination(item: $mode) { mode in
                SignInView(mode: mode)
            }
        }
    }

    // The gradient header showing the app icon, name and tagline
    private var hero: some View {
        VStack(spacing: 14) {
            Image(systemName: "heart")
                .font(.system(size: 38, weight: .semibold))
                .foregroundStyle(AppColors.brandTeal)
                .frame(width: 84, height: 84)
                .background(.white, in: RoundedRectangle(cornerRadius: 26))
            Text("CareWatch")
                .font(.system(size: 40, weight: .bold))
            Text("Everyday support for living well at home: reminders, check-ins and family help in one place.")
                .font(.body)
                .multilineTextAlignment(.center)
                .opacity(0.9)
                .padding(.horizontal, 30)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
        .padding(.bottom, 44)
        .background(AppColors.primaryGradient)
        .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 40, bottomTrailingRadius: 40))
    }
}
