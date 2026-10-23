import Foundation
import CoreData

extension CheckIn {
    // Saves an "I'm okay" checkin and adds it to the care history
    static func record(source: String = "manual", in context: NSManagedObjectContext) {
        let checkIn = CheckIn(context: context)
        checkIn.id = UUID()
        checkIn.timestamp = .now
        checkIn.source = source
        CareEvent.record("checkIn", summary: "Checked in · I'm okay", in: context)
        try? context.save()
    }
}
