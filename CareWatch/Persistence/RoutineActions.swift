import Foundation
import CoreData

extension Routine {
    // Marks the routine done (or the dose taken) for that day and records it in history
    func markDone(on date: Date = .now, in context: NSManagedObjectContext) {
        guard !isDone(on: date) else { return }
        let entry = log(on: date) ?? RoutineLog(context: context)
        if entry.id == nil { entry.id = UUID() }
        entry.day = Calendar.current.startOfDay(for: date)
        entry.status = isMedication ? "taken" : "done"
        entry.completedAt = .now
        entry.routine = self

        let name = title ?? "Routine"
        CareEvent.record(isMedication ? "doseTaken" : "routineDone",
                         summary: isMedication ? "\(name) taken" : "\(name) completed",
                         in: context)
        try? context.save()
    }

    // Undo: removes that day's record
    func markNotDone(on date: Date = .now, in context: NSManagedObjectContext) {
        guard let entry = log(on: date) else { return }
        context.delete(entry)
        CareEvent.record("undone", summary: "\(title ?? "Routine") marked as not done", in: context)
        try? context.save()
    }

    func toggleDone(on date: Date = .now, in context: NSManagedObjectContext) {
        if isDone(on: date) {
            markNotDone(on: date, in: context)
        } else {
            markDone(on: date, in: context)
        }
    }
}

extension CareEvent {
    // Adds one line to the care history (never edited afterwards)
    static func record(_ kind: String, summary: String, at date: Date = .now,
                       in context: NSManagedObjectContext) {
        let event = CareEvent(context: context)
        event.id = UUID()
        event.timestamp = date
        event.kind = kind
        event.summary = summary
    }
}
