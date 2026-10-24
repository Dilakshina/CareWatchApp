import Testing
import CoreData
@testable import CareWatch

/// Unit tests for the routine-scheduling logic and the Today summary.
///
/// These exercise the pure helpers in `RoutineHelpers.swift` and the
/// `TodaySummary` builder. They use a throwaway in-memory Core Data store,
/// so nothing touches disk and no Firebase/network access is involved.
@MainActor
struct RoutineLogicTests {

    // MARK: - Helpers

    /// A fresh, empty in-memory Core Data context for each test.
    private func makeContext() -> NSManagedObjectContext {
        PersistenceController(inMemory: true).container.viewContext
    }

    /// A deterministic Monday (2024-01-01) so weekday-based tests don't depend on "today".
    private func monday() -> Date {
        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 1
        return Calendar.current.date(from: components)!
    }

    /// Builds a routine in the given context with sensible defaults.
    private func makeRoutine(in context: NSManagedObjectContext,
                             title: String = "Morning medication",
                             category: String = "medication",
                             days: RepeatDays = .everyDay,
                             hour: Int = 8,
                             isActive: Bool = true) -> Routine {
        let routine = Routine(context: context)
        routine.id = UUID()
        routine.title = title
        routine.category = category
        routine.days = days
        routine.isActive = isActive
        routine.createdAt = .now
        routine.timeOfDay = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: .now)
        return routine
    }

    // MARK: - RepeatDays

    @Test func fromWeekdayMapsCalendarNumbers() {
        #expect(RepeatDays.from(weekday: 1) == .sunday)   // Calendar: 1 == Sunday
        #expect(RepeatDays.from(weekday: 2) == .monday)
        #expect(RepeatDays.from(weekday: 6) == .friday)
        #expect(RepeatDays.from(weekday: 7) == .saturday)
    }

    @Test func repeatDaysTextForCommonPatterns() {
        #expect(RepeatDays.everyDay.text == "Every day")
        #expect(([.monday, .tuesday, .wednesday, .thursday, .friday] as RepeatDays).text == "Weekdays")
        #expect(([.saturday, .sunday] as RepeatDays).text == "Weekends")
        #expect(([.monday, .wednesday, .friday] as RepeatDays).text == "Mon, Wed, Fri")
        #expect((RepeatDays([]) ).text == "No days selected")
    }

    @Test func daysPropertyRoundTripsThroughRawValue() {
        let context = makeContext()
        let routine = makeRoutine(in: context)

        routine.days = [.monday, .friday]

        #expect(routine.days.contains(.monday))
        #expect(routine.days.contains(.friday))
        #expect(!routine.days.contains(.tuesday))
        // Underlying bitfield should match the OptionSet raw value
        #expect(routine.repeatDays == ((1 << 0) | (1 << 4)))
    }

    // MARK: - Scheduling

    @Test func isMedicationReflectsCategory() {
        let context = makeContext()
        #expect(makeRoutine(in: context, category: "medication").isMedication)
        #expect(!makeRoutine(in: context, category: "wellbeing").isMedication)
    }

    @Test func isScheduledMatchesWeekdayAndActiveFlag() {
        let context = makeContext()
        let mon = monday()
        let tue = Calendar.current.date(byAdding: .day, value: 1, to: mon)!

        let routine = makeRoutine(in: context, days: [.monday])

        #expect(routine.isScheduled(on: mon))      // Monday-only routine, on a Monday
        #expect(!routine.isScheduled(on: tue))     // ...not on Tuesday

        routine.isActive = false
        #expect(!routine.isScheduled(on: mon))     // inactive routines are never scheduled
    }

    @Test func scheduledTimeUsesRoutineHourOnGivenDay() {
        let context = makeContext()
        let routine = makeRoutine(in: context, hour: 18)

        let scheduled = routine.scheduledTime(on: monday())
        let hour = Calendar.current.component(.hour, from: scheduled)

        #expect(hour == 18)
    }

    // MARK: - Completion state

    @Test func markDoneThenNotDoneTogglesCompletion() {
        let context = makeContext()
        let mon = monday()
        let routine = makeRoutine(in: context, category: "medication")

        #expect(!routine.isDone(on: mon))          // nothing logged yet

        routine.markDone(on: mon, in: context)
        #expect(routine.isDone(on: mon))           // a "taken" log now exists
        #expect(routine.log(on: mon)?.status == "taken")

        routine.markNotDone(on: mon, in: context)
        #expect(!routine.isDone(on: mon))          // log removed again
    }

    @Test func toggleDoneFlipsBothWays() {
        let context = makeContext()
        let mon = monday()
        let routine = makeRoutine(in: context, category: "wellbeing")

        routine.toggleDone(on: mon, in: context)
        #expect(routine.isDone(on: mon))
        #expect(routine.log(on: mon)?.status == "done")   // non-medication uses "done"

        routine.toggleDone(on: mon, in: context)
        #expect(!routine.isDone(on: mon))
    }

    // MARK: - TodaySummary

    @Test func todaySummaryProgressIsCompletedOverTotal() {
        let full = TodaySummary(userName: "Maya", routinesCompleted: 3, routinesTotal: 4,
                                nextMedication: "", nextMedicationDetail: "", steps: 0)
        #expect(abs(full.progress - 0.75) < 0.0001)

        let empty = TodaySummary(userName: "Maya", routinesCompleted: 0, routinesTotal: 0,
                                 nextMedication: "", nextMedicationDetail: "", steps: 0)
        #expect(empty.progress == 0)   // guards against divide-by-zero
    }

    @Test func todaySummaryBuildsFromScheduledRoutines() {
        let context = makeContext()
        let mon = monday()

        let morning = makeRoutine(in: context, title: "Morning medication", days: [.monday], hour: 8)
        let evening = makeRoutine(in: context, title: "Evening medication", days: [.monday], hour: 20)
        let notToday = makeRoutine(in: context, title: "Weekend walk", days: [.saturday], hour: 10)

        // Complete the morning dose only.
        morning.markDone(on: mon, in: context)

        let summary = TodaySummary(routines: [morning, evening, notToday],
                                   userName: "Maya", steps: 1200, now: mon)

        #expect(summary.routinesTotal == 2)                 // only Monday routines count
        #expect(summary.routinesCompleted == 1)             // morning done
        #expect(summary.nextMedication == "Evening medication") // earliest not-done routine
        #expect(summary.steps == 1200)
    }

    @Test func todaySummaryReportsAllDoneWhenNothingPending() {
        let context = makeContext()
        let mon = monday()
        let routine = makeRoutine(in: context, title: "Morning medication", days: [.monday], hour: 8)
        routine.markDone(on: mon, in: context)

        let summary = TodaySummary(routines: [routine], userName: "Maya", steps: 0, now: mon)

        #expect(summary.nextMedication == "All done for today")
    }
}
