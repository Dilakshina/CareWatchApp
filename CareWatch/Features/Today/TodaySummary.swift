import Foundation

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
