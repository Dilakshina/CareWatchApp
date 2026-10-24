import SwiftUI
import CoreData

struct MedicationDetailView: View {
    @Environment(\.managedObjectContext) private var context
    @ObservedObject var routine: Routine

    @State private var showingEdit = false
    @State private var showToast = false

    private var taken: Bool { routine.isDone(on: .now) }

    private var takenTime: String {
        (routine.log(on: .now)?.completedAt ?? .now).formatted(date: .omitted, time: .shortened)
    }

    // Shows a routine's details with actions to mark it taken, undo, or edit
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                summaryCard

                Text("Reminder details")
                    .font(.title3.bold())
                    .foregroundStyle(AppColors.ink)
                    .padding(.top, 6)

                detail("Time", routine.timeText)
                detail("Repeat", routine.daysText)
                detail("Notification", routine.notify ? "At reminder time" : "Off")
                if let note = routine.note, !note.isEmpty {
                    detail("Note", note)
                }

                if taken {
                    Label("Taken at \(takenTime)", systemImage: "checkmark")
                        .font(.headline)
                        .foregroundStyle(AppColors.brandTeal)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(AppColors.mint, in: RoundedRectangle(cornerRadius: 18))
                        .padding(.top, 8)

                    Button("Undo · Mark as not taken") {
                        withAnimation { routine.markNotDone(in: context) }
                    }
                    .font(.subheadline.weight(.semibold))
                    .tint(AppColors.brandTeal)
                    .frame(maxWidth: .infinity)
                } else {
                    PrimaryButton(title: routine.isMedication ? "Mark as taken" : "Mark as done") {
                        withAnimation {
                            routine.markDone(in: context)
                            showToast = true
                        }
                    }
                    .padding(.top, 8)
                }

                Button("Edit reminder") { showingEdit = true }
                    .font(.subheadline.weight(.semibold))
                    .tint(AppColors.brandTeal)
                    .frame(maxWidth: .infinity)
            }
            .padding(20)
        }
        .background(AppColors.background)
        .navigationTitle(routine.isMedication ? "Medication reminder" : "Routine")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .top) {
            if showToast {
                ToastBanner(title: routine.isMedication ? "Dose marked as taken" : "Routine completed",
                            message: "\(routine.title ?? "") · \(takenTime)")
            }
        }
        .task(id: showToast) {
            // Hide the banner automatically after 2.5 seconds
            guard showToast else { return }
            try? await Task.sleep(for: .seconds(2.5))
            withAnimation { showToast = false }
        }
        .sheet(isPresented: $showingEdit) {
            RoutineFormView(routine: routine)
                .environment(\.managedObjectContext, context)
        }
    }

    // Gradient header card showing the routine's title, dose and current status
    private var summaryCard: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: routine.isMedication ? "pills.fill" : "checklist")
                .font(.title2)
                .frame(width: 54, height: 54)
                .background(.white.opacity(0.2), in: Circle())
            VStack(alignment: .leading, spacing: 6) {
                Text(routine.title ?? "Reminder")
                    .font(.title3.bold())
                Text(routine.dosage ?? (routine.category ?? "").capitalized)
                    .font(.subheadline)
                    .opacity(0.9)
                Text(taken ? "Taken at \(takenTime)" : "Due at \(routine.timeText)")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.2), in: Capsule())
            }
            Spacer()
        }
        .foregroundStyle(.white)
        .padding(18)
        .background(AppColors.primaryGradient)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .combine)
    }

    // Builds a labelled card row showing a single detail field
    private func detail(_ label: String, _ value: String) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(AppColors.secondaryText)
                Text(value)
                    .font(.headline)
                    .foregroundStyle(AppColors.ink)
            }
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let request: NSFetchRequest<Routine> = Routine.fetchRequest()
    let routine = (try? context.fetch(request))?.first(where: \.isMedication) ?? Routine(context: context)
    NavigationStack {
        MedicationDetailView(routine: routine)
    }
    .environment(\.managedObjectContext, context)
}
