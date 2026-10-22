import SwiftUI
import CoreData

//Emergency contact: view, edit and call after the confirming
struct EmergencyContactView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.openURL) private var openURL
    @FetchRequest(sortDescriptors: [SortDescriptor(\.name)])
    private var contacts: FetchedResults<CareContact>

    @State private var name = ""
    @State private var relation = ""
    @State private var phone = ""
    @State private var confirmCall = false
    @State private var showToast = false
    @State private var alertMessage: String?

    private var primary: CareContact? { contacts.first(where: \.isPrimary) ?? contacts.first }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && phone.filter(\.isNumber).count >= 9
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                contactCard

                Button { confirmCall = true } label: {
                    Label("Call \(primary?.name ?? "contact")", systemImage: "phone.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 58)
                        .background(AppColors.emergency, in: RoundedRectangle(cornerRadius: 18))
                }
                .disabled(primary == nil)

                Label("The call button always asks you first. CareWatch never calls anyone automatically.",
                      systemImage: "info.circle")
                    .font(.footnote)
                    .foregroundStyle(AppColors.ink)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColors.mint, in: RoundedRectangle(cornerRadius: 16))

                Text("Edit contact")
                    .font(.title3.bold())
                    .foregroundStyle(AppColors.ink)
                    .padding(.top, 8)

                FormField(label: "Name", text: $name, placeholder: "e.g. Nimal Perera", contentType: .name)
                FormField(label: "Relationship", text: $relation, placeholder: "e.g. Son")
                FormField(label: "Phone number", text: $phone, placeholder: "+94 77 123 4567",
                          keyboard: .phonePad, contentType: .telephoneNumber)

                PrimaryButton(title: "Save contact", action: save)
                    .disabled(!canSave)
                    .opacity(canSave ? 1 : 0.5)

                Text("This contact is stored only on this iPhone.")
                    .font(.footnote)
                    .foregroundStyle(AppColors.secondaryText)
                    .frame(maxWidth: .infinity)
            }
            .padding(20)
        }
        .background(AppColors.background)
        .navigationTitle("Emergency contact")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: load)
        .confirmationDialog("Call \(primary?.name ?? "your contact")?",
                            isPresented: $confirmCall, titleVisibility: .visible) {
            Button("Call \(primary?.phone ?? "")") { call() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will start a phone call.")
        }
        .overlay(alignment: .top) {
            if showToast {
                ToastBanner(title: "Contact saved", message: "\(name) · \(phone)")
            }
        }
        .task(id: showToast) {
            guard showToast else { return }
            try? await Task.sleep(for: .seconds(2.5))
            withAnimation { showToast = false }
        }
        .alert("Can't start the call",
               isPresented: Binding(get: { alertMessage != nil }, set: { if !$0 { alertMessage = nil } })) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage ?? "")
        }
    }

    private var contactCard: some View {
        HStack(spacing: 14) {
            Text(String((primary?.name ?? "?").prefix(1)))
                .font(.title.bold())
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background(AppColors.primaryGradient, in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(primary?.name ?? "No contact yet")
                    .font(.title3.bold())
                    .foregroundStyle(AppColors.ink)
                Text("\(primary?.relation ?? "Family") · Primary contact")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.secondaryText)
                Text(primary?.phone ?? "")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.brandTeal)
            }
            Spacer()
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: AppColors.ink.opacity(0.08), radius: 12, y: 5)
        .accessibilityElement(children: .combine)
    }

    // Filling the form with the saved contact
    private func load() {
        name = primary?.name ?? ""
        relation = primary?.relation ?? ""
        phone = primary?.phone ?? ""
    }

    private func save() {
        let contact = primary ?? CareContact(context: context)
        if contact.id == nil { contact.id = UUID() }
        contact.name = name.trimmingCharacters(in: .whitespaces)
        contact.relation = relation.isEmpty ? "Family" : relation
        contact.phone = phone
        contact.isPrimary = true
        CareEvent.record("contactUpdated", summary: "Emergency contact updated", in: context)
        try? context.save()
        withAnimation { showToast = true }
    }

    
    private func call() {
        let number = (primary?.phone ?? "").filter { $0.isNumber || $0 == "+" }
        guard let url = URL(string: "tel://\(number)") else { return }
        openURL(url) { accepted in
            if accepted {
                CareEvent.record("emergencyCall",
                                 summary: "Called \(primary?.name ?? "emergency contact")", in: context)
                try? context.save()
            } else {
                alertMessage = "This device can't make phone calls (for example, the Simulator). On an iPhone, the call to \(primary?.phone ?? "") would start now."
            }
        }
    }
}
