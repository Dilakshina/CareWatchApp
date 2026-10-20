import SwiftUI
import CoreData

struct RoutinesView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(sortDescriptors: [SortDescriptor(\.timeOfDay)])
    private var routines: FetchedResults<Routine>

    // Only today's routines, in time order
    private var todays: [Routine] {
        routines
            .filter { $0.isScheduled(on: .now) }
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
                        RoutineRow(routine: routine) {
                            withAnimation { routine.toggleDone(in: context) }
                        }
                        .cardRow()
                    }
                    .onDelete(perform: delete)
                } header: {
                    Text("Your checklist")
                        .font(.title3.bold())
                        .foregroundStyle(AppColors.ink)
                        .textCase(nil)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(AppColors.background)
            .overlay {
                if todays.isEmpty {
                    ContentUnavailableView("No routines today",
                                           systemImage: "checklist",
                                           description: Text("Tap + to add your first reminder."))
                }
            }
            .navigationTitle("Daily routines")
        }
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

    private func delete(at offsets: IndexSet) {
        let items = todays
        for index in offsets {
            context.delete(items[index])
        }
        try? context.save()
    }
}

// One routine in the checklist: tap the circle to mark it done
struct RoutineRow: View {
    @ObservedObject var routine: Routine
    let onToggle: () -> Void

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
