import Foundation
import CoreData

// Demo data for development and the demo. Added only when the database is empty.
enum SampleData {
    static func seedIfNeeded(in context: NSManagedObjectContext) {
        let request: NSFetchRequest<Routine> = Routine.fetchRequest()
        request.fetchLimit = 1
        guard (try? context.count(for: request)) == 0 else { return }

        let today = Date.now
        let calendar = Calendar.current
        let samples: [(title: String, category: String, hour: Int, minute: Int, done: Bool)] = [
            ("Morning medication", "medication", 8, 0, true),
            ("Breakfast", "wellbeing", 9, 0, true),
            ("Afternoon walk", "activity", 15, 30, true),
            ("Evening medication", "medication", 18, 0, false),
        ]

        for sample in samples {
            let routine = Routine(context: context)
            routine.id = UUID()
            routine.title = sample.title
            routine.category = sample.category
            routine.timeOfDay = calendar.date(bySettingHour: sample.hour, minute: sample.minute,
                                              second: 0, of: today)
            routine.days = .everyDay
            routine.createdAt = today
            if sample.category == "medication" { routine.dosage = "One tablet" }

            if sample.done {
                let log = RoutineLog(context: context)
                log.id = UUID()
                log.day = calendar.startOfDay(for: today)
                log.status = "done"
                log.completedAt = routine.timeOfDay
                log.routine = routine
            }
        }

        let contact = CareContact(context: context)
        contact.id = UUID()
        contact.name = "Nimal Perera"
        contact.relation = "Son"
        contact.phone = "+94 77 123 4567"
        contact.isPrimary = true

        try? context.save()
    }
}
