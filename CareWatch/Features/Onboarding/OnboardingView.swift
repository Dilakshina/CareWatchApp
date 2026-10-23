import SwiftUI
import CoreData

// Onboarding profile,emergency contact and the permissions
struct OnboardingView: View {
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject private var auth: AuthService

    @State private var step = 1

    // profile information
    @State private var fullName = ""
    @State private var dateOfBirth = Calendar.current.date(byAdding: .year, value: -70, to: .now) ?? .now
    @State private var phone = ""

    // emergency contact information
    @State private var contactName = ""
    @State private var relation = ""
    @State private var contactPhone = ""

    // permissions
    @State private var notificationsAllowed = false
    @State private var errorMessage: String?

    private var canContinue: Bool {
        switch step {
        case 1:  return !fullName.trimmingCharacters(in: .whitespaces).isEmpty
        case 2:  return !contactName.trimmingCharacters(in: .whitespaces).isEmpty
                     && contactPhone.filter(\.isNumber).count >= 9
        default: return true
        }
    }
    
    // user view

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            progress
                .padding(.horizontal, 20)
                .padding(.top, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch step {
                    case 1:  profileStep
                    case 2:  contactStep
                    default: permissionsStep
                    }
                    if let errorMessage {
                        Text(errorMessage).foregroundStyle(AppColors.emergency)
                    }
                }
                .padding(20)
            }
        }
        .background(AppColors.background)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                PrimaryButton(title: step < 3 ? "Continue" : "Finish setup") {
                    if step < 3 {
                        withAnimation { step += 1 }
                    } else {
                        finish()
                    }
                }
                .disabled(!canContinue)
                .opacity(canContinue ? 1 : 0.5)

                if step > 1 {
                    Button("Back") { withAnimation { step -= 1 } }
                        .font(.headline)
                        .tint(AppColors.secondaryText)
                }
            }
            .padding(20)
            .background(AppColors.background)
        }
    }

    
    private var progress: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Step \(step) of 3")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.brandTeal)
            HStack(spacing: 8) {
                ForEach(1...3, id: \.self) { index in
                    Capsule()
                        .fill(index <= step ? AppColors.brandTeal : AppColors.mint)
                        .frame(height: 6)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func header(_ title: String, _ subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.largeTitle.bold())
                .foregroundStyle(AppColors.ink)
            Text(subtitle)
                .foregroundStyle(AppColors.secondaryText)
        }
    }

    private var profileStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            header("Create your profile", "This helps CareWatch greet you and personalise your reminders.")
            FormField(label: "Full name", text: $fullName, placeholder: "e.g. Maya Fernando",
                      contentType: .name)
            CardView {
                DatePicker("Date of birth", selection: $dateOfBirth, in: ...Date.now,
                           displayedComponents: .date)
                    .font(.headline)
                    .foregroundStyle(AppColors.ink)
            }
            FormField(label: "Phone (optional)", text: $phone, placeholder: "+94 71 555 0182",
                      keyboard: .phonePad, contentType: .telephoneNumber)
        }
    }

    private var contactStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            header("Who should we call?", "Choose one trusted family member for one-tap emergency calls.")
            FormField(label: "Name", text: $contactName, placeholder: "e.g. Nimal Perera",
                      contentType: .name)
            FormField(label: "Relationship", text: $relation, placeholder: "e.g. Son")
            FormField(label: "Phone number", text: $contactPhone, placeholder: "+94 77 123 4567",
                      keyboard: .phonePad, contentType: .telephoneNumber)
            Label("Only used when you tap Emergency contact. CareWatch never calls anyone automatically.",
                  systemImage: "phone")
                .font(.footnote)
                .foregroundStyle(AppColors.ink)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.emergencySoft, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    private var permissionsStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            header("Choose what to allow", "Every permission is optional. You can change these any time in Settings.")
            CardView {
                HStack(spacing: 14) {
                    Image(systemName: "bell")
                        .font(.headline)
                        .foregroundStyle(AppColors.brandTeal)
                        .frame(width: 44, height: 44)
                        .background(AppColors.mint, in: Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Notifications").font(.headline).foregroundStyle(AppColors.ink)
                        Text("Medication and routine reminders")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.secondaryText)
                    }
                    Spacer()
                    Button(notificationsAllowed ? "Allowed" : "Allow") {
                        Task { notificationsAllowed = await ReminderService.requestPermission() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.brandTeal)
                    .disabled(notificationsAllowed)
                }
            }
            ListRow(systemImage: "heart", title: "Apple Health",
                    subtitle: "Asked when you open Activity", showsChevron: false)
            ListRow(systemImage: "location", title: "Location",
                    subtitle: "Asked when you set your home", showsChevron: false)
            ListRow(systemImage: "faceid", title: "Face ID",
                    subtitle: "Turn on later in Settings", showsChevron: false)
            Text("Health, motion and location data stay on this iPhone.")
                .font(.footnote)
                .foregroundStyle(AppColors.secondaryText)
        }
    }

    // save information part

    private func finish() {
        let profile = UserProfile(context: context)
        profile.id = UUID()
        profile.accountID = auth.uid
        profile.fullName = fullName.trimmingCharacters(in: .whitespaces)
        profile.dateOfBirth = dateOfBirth
        profile.phone = phone.isEmpty ? nil : phone
        profile.createdAt = .now

        // Keep one primary contact: update the existing one, or create it
        let request: NSFetchRequest<CareContact> = CareContact.fetchRequest()
        let existing = (try? context.fetch(request)) ?? []
        let contact = existing.first(where: \.isPrimary) ?? CareContact(context: context)
        if contact.id == nil { contact.id = UUID() }
        contact.name = contactName.trimmingCharacters(in: .whitespaces)
        contact.relation = relation.isEmpty ? "Family" : relation
        contact.phone = contactPhone
        contact.isPrimary = true

        CareEvent.record("onboarding", summary: "Profile created", in: context)

        do {
            try context.save()
        } catch {
            errorMessage = "Couldn't save: \(error.localizedDescription)"
        }
    }
}
