import SwiftUI
import CoreData
import UserNotifications

struct RoutineFormView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    // null = adding a new routine, otherwise editing this one
    let routine: Routine?
    
    @State private var title = ""
    @State private var category = "wellbeing"
    @State private var time = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: .now) ?? .now
    @State private var days: RepeatDays = .everyDay
    @State private var dosage = ""
    @State private var note = ""
    @State private var notify = true
    @State private var saveError: String?
    
    private let categories = [("wellbeing", "Daily wellbeing"),
                              ("medication", "Medication"),
                              ("activity", "Activity")]
    private let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    private let dayValues: [RepeatDays] = [.monday, .tuesday, .wednesday, .thursday,
                                           .friday, .saturday, .sunday]
    
    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && !days.isEmpty
    }
    
    // Form for adding or editing a routine's name, time, days and options
    var body: some View {
        NavigationStack {
            Form {
                Section("Routine") {
                    TextField("Routine name, e.g. Drink water", text: $title)
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.0) { item in
                            Text(item.1).tag(item.0)
                        }
                    }
                    if category == "medication" {
                        TextField("Dose, e.g. One tablet", text: $dosage)
                    }
                }
                
                Section("When") {
                    DatePicker("Reminder time", selection: $time, displayedComponents: .hourAndMinute)
                    dayPicker
                    Text("Repeats: \(days.text)  ·  tap a day to turn it on or off")
                        .font(.footnote)
                        .foregroundStyle(days.isEmpty ? AppColors.emergency : AppColors.secondaryText)
                }
                
                
                Section {
                    Toggle("Send a notification", isOn: $notify)
                        .tint(AppColors.brandTeal)
                    TextField("Note (optional)", text: $note, axis: .vertical)
                }
                
                Section {
                    PrimaryButton(title: routine == nil ? "Save reminder" : "Save changes", action: save)
                        .disabled(!canSave)
                        .opacity(canSave ? 1 : 0.5)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
            .scrollContentBackground(.hidden)
            .background(AppColors.background)
            .navigationTitle(routine == nil ? "Add reminder" : "Edit reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear(perform: load)
            .alert("Couldn't save", isPresented: Binding(get: { saveError != nil },
                                                         set: { if !$0 { saveError = nil } })) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(saveError ?? "")
            }
        }
    }
    
    // Mon to Sun chips: tap to turn a day on or off
    private var dayPicker: some View {
        HStack(spacing: 6) {
            ForEach(0..<7, id: \.self) { index in
                let day = dayValues[index]
                let isOn = days.contains(day)
                Button {
                    if isOn { days.remove(day) } else { days.insert(day) }
                } label: {
                    Text(dayNames[index])
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .foregroundStyle(isOn ? .white : AppColors.brandTeal)
                        .background(isOn ? AppColors.brandTeal : AppColors.mint, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(dayNames[index])
                .accessibilityAddTraits(isOn ? .isSelected : [])
            }
        }
    }
    
    // When editing, fill the form with the routine's current values
    private func load() {
        guard let routine else { return }
        title = routine.title ?? ""
        category = routine.category ?? "wellbeing"
        time = routine.timeOfDay ?? time
        days = routine.days
        dosage = routine.dosage ?? ""
        note = routine.note ?? ""
        notify = routine.notify
    }
    
    // Writes the form values to Core Data and schedules its reminder notification
    private func save() {
        let item = routine ?? Routine(context: context)
        if routine == nil {
            item.id = UUID()
            item.createdAt = .now
            item.isActive = true
        }
        item.title = title.trimmingCharacters(in: .whitespaces)
        item.category = category
        item.timeOfDay = time
        item.days = days
        item.notify = notify
        item.dosage = (category == "medication" && !dosage.isEmpty) ? dosage : nil
        item.note = note.isEmpty ? nil : note
        
        do {
            try context.save()
            Task {
                if item.notify { _ = await ReminderService.requestPermission() }
                ReminderService.schedule(item)
            }
            dismiss()
        } catch {
            saveError = error.localizedDescription
            print("Routine save failed: \(error)")
        }
    }
}

#Preview {
    RoutineFormView(routine: nil)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
