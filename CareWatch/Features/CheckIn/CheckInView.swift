import SwiftUI
import CoreData


struct CheckInView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(sortDescriptors: [SortDescriptor(\.timestamp, order: .reverse)])
    private var checkIns: FetchedResults<CheckIn>

    @State private var showToast = false
    @State private var showMovementPrompt = false
    @State private var movementStatus = "Checking movement…"

    // Most recent check-in made today, if any
    private var lastToday: CheckIn? {
        checkIns.first { Calendar.current.isDateInToday($0.timestamp ?? .distantPast) }
    }

    private func time(_ date: Date?) -> String {
        (date ?? .now).formatted(date: .omitted, time: .shortened)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Let your family know you're okay")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.secondaryText)

                    statusCard

                    if lastToday == nil {
                        PrimaryButton(title: "I'm okay · Check in now") { checkIn() }
                    } else {
                        Button { checkIn() } label: {
                            Label("Checked in today · Check in again", systemImage: "checkmark")
                                .font(.headline)
                                .foregroundStyle(AppColors.brandTeal)
                                .frame(maxWidth: .infinity, minHeight: 56)
                                .background(AppColors.mint, in: RoundedRectangle(cornerRadius: 18))
                        }
                        .buttonStyle(.plain)
                    }

                    Text("Safety signals")
                        .font(.title3.bold())
                        .foregroundStyle(AppColors.ink)
                        .padding(.top, 6)

                    Button { showMovementPrompt = true } label: {
                        ListRow(systemImage: "waveform.path.ecg",
                                title: "Inactivity check",
                                subtitle: movementStatus)
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        EmergencyContactView()
                    } label: {
                        ListRow(systemImage: "exclamationmark",
                                title: "Call emergency contact",
                                subtitle: "For immediate help",
                                tint: AppColors.emergency,
                                iconBackground: .white,
                                cardBackground: AppColors.emergencySoft,
                                showsChevron: false)
                    }
                    .buttonStyle(.plain)

                    Text("Recent check-ins")
                        .font(.title3.bold())
                        .foregroundStyle(AppColors.ink)
                        .padding(.top, 6)

                    if checkIns.isEmpty {
                        Text("No check-ins yet.")
                            .foregroundStyle(AppColors.secondaryText)
                    } else {
                        ForEach(checkIns.prefix(5), id: \.objectID) { item in
                            ListRow(systemImage: "checkmark.circle",
                                    title: "I'm okay",
                                    subtitle: (item.timestamp ?? .now).formatted(date: .abbreviated, time: .shortened),
                                    showsChevron: false)
                        }
                    }
                }
                .padding(20)
            }
            .background(AppColors.background)
            .navigationTitle("Check-in")
            .overlay(alignment: .top) {
                if showToast {
                    ToastBanner(title: "Check-in recorded",
                                message: "Saved to today's care history · \(time(lastToday?.timestamp))")
                }
            }
            .task(id: showToast) {
                guard showToast else { return }
                try? await Task.sleep(for: .seconds(2.5))
                withAnimation { showToast = false }
            }
            .task { await checkMovement() }
            .sheet(isPresented: $showMovementPrompt) {
                MovementPromptSheet()
                    .environment(\.managedObjectContext, context)
            }
        }
    }

    private var statusCard: some View {
        let done = lastToday != nil
        return VStack(spacing: 12) {
            Image(systemName: done ? "checkmark" : "hand.wave")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 84, height: 84)
                .background(done ? AppColors.brandTeal : AppColors.warning, in: Circle())
            Text(done ? "You're checked in" : "Not checked in yet today")
                .font(.title2.bold())
                .foregroundStyle(AppColors.ink)
            Text(done ? "Last check-in · \(time(lastToday?.timestamp))" : "Tap the button below when you're ready")
                .font(.subheadline)
                .foregroundStyle(AppColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .background(done ? AppColors.mint : Color.white, in: RoundedRectangle(cornerRadius: 22))
        .accessibilityElement(children: .combine)
    }

    private func checkIn() {
        withAnimation {
            CheckIn.record(in: context)
            showToast = true
        }
    }

    // Looks at recent phone movement. Only SUGGESTS a check-in, never decides anything.
    private func checkMovement() async {
        switch await MotionService.movedRecently() {
        case .some(true):
            movementStatus = "Regular movement detected"
        case .some(false):
            movementStatus = "No walking recorded in the last 3 hours"
            if lastToday == nil { showMovementPrompt = true }
        case .none:
            movementStatus = "Needs a real iPhone · tap to preview the prompt"
        }
    }
}

#Preview {
    CheckInView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
