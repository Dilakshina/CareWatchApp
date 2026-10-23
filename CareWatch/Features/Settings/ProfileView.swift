import SwiftUI
import CoreData

//Profile & security
struct ProfileView: View {
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject private var auth: AuthService
    @FetchRequest(sortDescriptors: []) private var profiles: FetchedResults<UserProfile>
    @AppStorage("faceIDEnabled") private var faceIDEnabled = false

    @State private var fullName = ""
    @State private var phone = ""
    @State private var dateOfBirth = Date.now
    @State private var showToast = false
    @State private var faceIDMessage: String?

    private var profile: UserProfile? {
        profiles.first { $0.accountID == auth.uid }
    }

    private var canSave: Bool {
        !fullName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerCard

                Text("Personal details")
                    .font(.title3.bold())
                    .foregroundStyle(AppColors.ink)
                    .padding(.top, 6)

                FormField(label: "Full name", text: $fullName, contentType: .name)
                FormField(label: "Phone number", text: $phone,
                          keyboard: .phonePad, contentType: .telephoneNumber)
                CardView {
                    DatePicker("Date of birth", selection: $dateOfBirth, in: ...Date.now,
                               displayedComponents: .date)
                        .font(.headline)
                        .foregroundStyle(AppColors.ink)
                }

                PrimaryButton(title: "Save changes", action: save)
                    .disabled(!canSave)
                    .opacity(canSave ? 1 : 0.5)

                Text("App unlock")
                    .font(.title3.bold())
                    .foregroundStyle(AppColors.ink)
                    .padding(.top, 10)

                CardView {
                    Toggle(isOn: faceIDBinding) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Face ID unlock")
                                .font(.headline)
                                .foregroundStyle(AppColors.ink)
                            Text(BiometricService.isAvailable
                                 ? "Password sign-in is always available"
                                 : "Face ID isn't set up on this device")
                                .font(.subheadline)
                                .foregroundStyle(AppColors.secondaryText)
                        }
                    }
                    .tint(AppColors.brandTeal)
                }
                .disabled(!BiometricService.isAvailable && !faceIDEnabled)

                if let faceIDMessage {
                    Text(faceIDMessage)
                        .font(.subheadline)
                        .foregroundStyle(AppColors.emergency)
                }
            }
            .padding(20)
        }
        .background(AppColors.background)
        .navigationTitle("Profile & security")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: load)
        .overlay(alignment: .top) {
            if showToast {
                ToastBanner(title: "Profile saved", message: fullName)
            }
        }
        .task(id: showToast) {
            guard showToast else { return }
            try? await Task.sleep(for: .seconds(2.5))
            withAnimation { showToast = false }
        }
    }

    private var headerCard: some View {
        HStack(spacing: 14) {
            Text(String(fullName.prefix(1)).uppercased())
                .font(.title.bold())
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background(AppColors.primaryGradient, in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(fullName.isEmpty ? "Your profile" : fullName)
                    .font(.title3.bold())
                    .foregroundStyle(AppColors.ink)
                Text(auth.email ?? "")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.secondaryText)
            }
            Spacer()
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: AppColors.ink.opacity(0.08), radius: 12, y: 5)
    }

    // Turning Face ID on asks for Face ID first, so you can't lock yourself out
    private var faceIDBinding: Binding<Bool> {
        Binding(
            get: { faceIDEnabled },
            set: { newValue in
                if newValue {
                    Task {
                        if await BiometricService.authenticate(reason: "Turn on Face ID for CareWatch") {
                            faceIDEnabled = true
                            faceIDMessage = nil
                        } else {
                            faceIDMessage = "Face ID couldn't be confirmed, so it stays off."
                        }
                    }
                } else {
                    faceIDEnabled = false
                }
            }
        )
    }

    private func load() {
        fullName = profile?.fullName ?? ""
        phone = profile?.phone ?? ""
        dateOfBirth = profile?.dateOfBirth ?? dateOfBirth
    }

    private func save() {
        guard let profile else { return }
        profile.fullName = fullName.trimmingCharacters(in: .whitespaces)
        profile.phone = phone.isEmpty ? nil : phone
        profile.dateOfBirth = dateOfBirth
        try? context.save()
        withAnimation { showToast = true }
    }
}
