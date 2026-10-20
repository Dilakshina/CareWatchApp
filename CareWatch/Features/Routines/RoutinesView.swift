import SwiftUI
import CoreData

struct RoutinesView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(sortDescriptors: [SortDescriptor(\.timeOfDay)])
    private var routines: FetchedResults<Routine>

    @State private var showingAdd = false
    @State private var editing: Routine?
    @State private var detail: Routine?

    // Routines planned for today, in time order
    private var todays: [Routine] {
        routines
            .filter { $0.isScheduled(on: .now) }
            .sorted { $0.scheduledTime(on: .now) < $1.scheduledTime(on: .now) }
    }

    // Saved routines that are not planned for today
    private var otherDays: [Routine] {
        routines
            .filter { !$0.isScheduled(on: .now) }
            .sorted { $0.scheduledTime(on: .now) < $1.scheduledTime(on: .now) }
    }

    private var doneCount: Int { todays.filter { $0.isDone(on: .now) }.count }

    var body: some View {
        NavigationStack {
            List {
                progressCard
                    .cardRow()

                Section {
                    ForEach(todays, id: \.objectID) { routine in
                        RoutineRow(routine: routine,
                                   onToggle: { withAnimation { routine.toggleDone(in: context) } },
                                   onEdit: { detail = routine })
                            .cardRow()
                    }
                    .onDelete { delete(todays, at: $0) }
                } header: {
                    sectionTitle("Your checklist")
                }

                if !otherDays.isEmpty {
                    Section {
                        ForEach(otherDays, id: \.objectID) { routine in
                            Button { detail = routine } label: {
                                ListRow(systemImage: "calendar",
                                        title: routine.title ?? "Routine",
                                        subtitle: "\(routine.timeText) · \(routine.daysText)")
                            }
                            .buttonStyle(.plain)
                            .cardRow()
                        }
                        .onDelete { delete(otherDays, at: $0) }
                    } header: {
                        sectionTitle("Other days")
                    }
                }

                PrimaryButton(title: "+  Add reminder") { showingAdd = true }
                    .cardRow()
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(AppColors.background)
            .overlay {
                if routines.isEmpty {
                    ContentUnavailableView("No routines yet",
                                           systemImage: "checklist",
                                           description: Text("Tap + Add reminder to create one."))
                }
            }
            .navigationTitle("Daily routines")
            .navigationDestination(item: $detail) { routine in
                MedicationDetailView(routine: routine)
            }
            .sheet(isPresented: $showingAdd) {
                RoutineFormView(routine: nil)
                    .environment(\.managedObjectContext, context)
            }
            .sheet(isPresented: Binding(get: { editing != nil },
                                        set: { if !$0 { editing = nil } })) {
                if let editing {
                    RoutineFormView(routine: editing)
                        .environment(\.managedObjectContext, context)
                }
            }
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.title3.bold())
            .foregroundStyle(AppColors.ink)
            .textCase(nil)
    }

    private var progressCard: some View {
        let left = todays.count - doneCount
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Today's progress").font(.headline)
                Spacer()
                Text("\(doneCount) / \(todays.count)").font(.title3.bold())
            }
            ProgressView(value: todays.isEmpty ? 0 : Double(doneCount) / Double(todays.count))
                .tint(.white)
            Text(left == 0 ? "All routines done for today"
                           : "\(left) routine\(left == 1 ? "" : "s") left to finish")
                .font(.subheadline)
        }
        .foregroundStyle(.white)
        .padding(18)
        .background(AppColors.primaryGradient)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .combine)
    }

    private func delete(_ items: [Routine], at offsets: IndexSet) {
        for index in offsets {
            ReminderService.cancel(items[index])
            context.delete(items[index])
        }
        do {
            try context.save()
        } catch {
            print("Delete failed: \(error)")
        }
    }
}

// One routine in the checklist: circle = done/undo, the rest = edit
struct RoutineRow: View {
    @ObservedObject var routine: Routine
    let onToggle: () -> Void
    let onEdit: () -> Void

    var body: some View {
        let done = routine.isDone(on: .now)
        CardView {
            HStack(spacing: 14) {
                Button(action: onToggle) {
                    Image(systemName: done ? "checkmark" : "circle")
                        .font(.headline)
                        .foregroundStyle(done ? AppColors.brandTeal : AppColors.warning)
                        .frame(width: 44, height: 44)
                        .background(done ? AppColors.mint : AppColors.warningSoft, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(done ? "Mark \(routine.title ?? "routine") as not done"
                                         : "Mark \(routine.title ?? "routine") as done")

                Button(action: onEdit) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(routine.title ?? "Routine")
                                .font(.headline)
                                .foregroundStyle(AppColors.ink)
                            Text("\(routine.timeText) · \(done ? "Completed" : "Upcoming")")
                                .font(.subheadline)
                                .foregroundStyle(AppColors.secondaryText)
                        }
                        Spacer()
                        Text(done ? "Done" : "Due")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(done ? AppColors.brandTeal : AppColors.warning)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(done ? AppColors.mint : AppColors.warningSoft, in: Capsule())
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint("Opens the reminder to edit")
            }
        }
    }
}

private extension View {
    // Makes a List row look like a floating card (no grey lines or background)
    func cardRow() -> some View {
        self
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
    }
}

#Preview {
    RoutinesView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
