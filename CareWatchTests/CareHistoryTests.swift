import Testing
import CoreData
@testable import CareWatch

/// Unit tests for the care-history records written to Core Data:
/// `CheckIn.record`, `CareEvent.record`, and the history entries that
/// `Routine.markDone` / `markNotDone` add.
///
/// Each test uses a fresh in-memory store, so records never persist and
/// tests stay isolated from one another.
@MainActor
struct CareHistoryTests {

    // MARK: - Helpers

    /// A fresh, empty in-memory Core Data context for each test.
    private func makeContext() -> NSManagedObjectContext {
        PersistenceController(inMemory: true).container.viewContext
    }

    /// Fetches every `CareEvent` currently in the context.
    private func allEvents(in context: NSManagedObjectContext) -> [CareEvent] {
        (try? context.fetch(CareEvent.fetchRequest())) ?? []
    }

    /// Fetches every `CheckIn` currently in the context.
    private func allCheckIns(in context: NSManagedObjectContext) -> [CheckIn] {
        (try? context.fetch(CheckIn.fetchRequest())) ?? []
    }

    /// Builds a routine in the given context.
    private func makeRoutine(in context: NSManagedObjectContext,
                             title: String,
                             category: String) -> Routine {
        let routine = Routine(context: context)
        routine.id = UUID()
        routine.title = title
        routine.category = category
        routine.days = .everyDay
        routine.isActive = true
        routine.createdAt = .now
        routine.timeOfDay = .now
        return routine
    }

    // MARK: - CheckIn

    @Test func recordCheckInStoresCheckInAndHistoryEvent() {
        let context = makeContext()

        CheckIn.record(source: "manual", in: context)

        let checkIns = allCheckIns(in: context)
        #expect(checkIns.count == 1)
        #expect(checkIns.first?.source == "manual")
        #expect(checkIns.first?.id != nil)
        #expect(checkIns.first?.timestamp != nil)

        // A matching history line should be added alongside the check-in.
        let events = allEvents(in: context)
        #expect(events.contains { $0.kind == "checkIn" })
    }

    @Test func recordCheckInKeepsTheProvidedSource() {
        let context = makeContext()

        CheckIn.record(source: "motionPrompt", in: context)

        #expect(allCheckIns(in: context).first?.source == "motionPrompt")
    }

    // MARK: - CareEvent

    @Test func recordCareEventCapturesKindAndSummary() {
        let context = makeContext()
        let stamp = Date(timeIntervalSince1970: 1_700_000_000)

        CareEvent.record("onboarding", summary: "Welcome to CareWatch", at: stamp, in: context)

        let events = allEvents(in: context)
        #expect(events.count == 1)
        #expect(events.first?.kind == "onboarding")
        #expect(events.first?.summary == "Welcome to CareWatch")
        #expect(events.first?.timestamp == stamp)
    }

    // MARK: - Routine history

    @Test func markingMedicationDoneLogsDoseTakenEvent() {
        let context = makeContext()
        let routine = makeRoutine(in: context, title: "Evening medication", category: "medication")

        routine.markDone(in: context)

        let events = allEvents(in: context)
        #expect(events.contains { $0.kind == "doseTaken" })
        #expect(events.contains { $0.summary == "Evening medication taken" })
    }

    @Test func markingWellbeingRoutineDoneLogsRoutineDoneEvent() {
        let context = makeContext()
        let routine = makeRoutine(in: context, title: "Afternoon walk", category: "wellbeing")

        routine.markDone(in: context)

        let events = allEvents(in: context)
        #expect(events.contains { $0.kind == "routineDone" })
        #expect(events.contains { $0.summary == "Afternoon walk completed" })
    }

    @Test func undoingARoutineLogsUndoneEvent() {
        let context = makeContext()
        let routine = makeRoutine(in: context, title: "Breakfast", category: "wellbeing")

        routine.markDone(in: context)
        routine.markNotDone(in: context)

        let events = allEvents(in: context)
        #expect(events.contains { $0.kind == "undone" })
    }
}
