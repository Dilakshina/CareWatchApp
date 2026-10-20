import Foundation
import CoreData

struct TodaySummary {
    let userName: String
    let routinesCompleted: Int
    let routinesTotal: Int
    let nextMedication: String
    let nextMedicationDetail: String
    let steps: Int

    var progress: Double {
        routinesTotal == 0 ? 0 : Double(routinesCompleted) / Double(routinesTotal)
    }

  
    static let sample = TodaySummary(
        userName: "Maya",
        routinesCompleted: 3,
        routinesTotal: 4,
        nextMedication: "Evening medication",
        nextMedicationDetail: "6:00 PM · After dinner",
        steps: 4260
    )
}
extension TodaySummary {
    // Builds the summary from real routines in Core Data
    init(routines: [Routine], userName: String, steps: Int, now: Date = .now) {
        let todays = routines.filter { $0.isScheduled(on: now) }
        let next = todays
            .filter { !$0.isDone(on: now) }
            .sorted { $0.scheduledTime(on: now) < $1.scheduledTime(on: now) }
            .first

        self.init(
            userName: userName,
            routinesCompleted: todays.filter { $0.isDone(on: now) }.count,
            routinesTotal: todays.count,
            nextMedication: next?.title ?? "All done for today",
            nextMedicationDetail: next.map { "\($0.timeText) · \($0.dosage ?? "Routine")" }
                                  ?? "Nothing else scheduled",
            steps: steps
        )
    }
}
