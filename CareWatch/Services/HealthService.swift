import Foundation
import Combine
import HealthKit

// Reads today's steps, walking distance and active minutes from Apple Health
@MainActor
final class HealthService: ObservableObject {
    @Published private(set) var steps = 0
    @Published private(set) var distanceKm = 0.0
    @Published private(set) var activeMinutes = 0
    @Published private(set) var hourlySteps = Array(repeating: 0, count: 24)
    @Published private(set) var isConnected = UserDefaults.standard.bool(forKey: "healthConnected")

    private let store = HKHealthStore()
    private let stepType = HKQuantityType(.stepCount)
    private let distanceType = HKQuantityType(.distanceWalkingRunning)
    private let exerciseType = HKQuantityType(.appleExerciseTime)

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    // Shows Apple's permission sheet, then loads today's numbers
    func connect() async {
        guard isAvailable else { return }
        do {
            try await store.requestAuthorization(toShare: [],
                                                 read: [stepType, distanceType, exerciseType])
            isConnected = true
            UserDefaults.standard.set(true, forKey: "healthConnected")
            await refresh()
        } catch {
            print("HealthKit permission failed: \(error)")
        }
    }

    // Reloads today's numbers (only if the user connected Apple Health)
    func refresh() async {
        guard isConnected, isAvailable else { return }
        steps = Int(await todaySum(stepType, unit: .count()))
        distanceKm = await todaySum(distanceType, unit: .meterUnit(with: .kilo))
        activeMinutes = Int(await todaySum(exerciseType, unit: .minute()))
        hourlySteps = await stepsPerHour()
    }

    // queries

    private func todaySum(_ type: HKQuantityType, unit: HKUnit) async -> Double {
        let start = Calendar.current.startOfDay(for: .now)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: .now)
        let query = HKStatisticsQueryDescriptor(
            predicate: .quantitySample(type: type, predicate: predicate),
            options: .cumulativeSum)
        let result = try? await query.result(for: store)
        return result?.sumQuantity()?.doubleValue(for: unit) ?? 0
    }

    private func stepsPerHour() async -> [Int] {
        let start = Calendar.current.startOfDay(for: .now)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: .now)
        let query = HKStatisticsCollectionQueryDescriptor(
            predicate: .quantitySample(type: stepType, predicate: predicate),
            options: .cumulativeSum,
            anchorDate: start,
            intervalComponents: DateComponents(hour: 1))

        var values = Array(repeating: 0, count: 24)
        guard let collection = try? await query.result(for: store) else { return values }
        for stats in collection.statistics() {
            let hour = Calendar.current.component(.hour, from: stats.startDate)
            values[hour] = Int(stats.sumQuantity()?.doubleValue(for: .count()) ?? 0)
        }
        return values
    }
}
