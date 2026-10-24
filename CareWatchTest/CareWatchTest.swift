import XCTest
import CoreData
@testable import CareWatch

// Unit tests for CareWatch's main logic.
// Each test uses a fresh, empty in-memory database, so real data is never touched.
@MainActor
final class CareWatchTests: XCTestCase {


    private func makeContainer() -> NSPersistentContainer {
        let model = PersistenceController.shared.container.managedObjectModel
        let container = NSPersistentContainer(name: "CareWatch", managedObjectModel: model)
        let store = NSPersistentStoreDescription()
        store.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [store]
        container.loadPersistentStores { _, error in XCTAssertNil(error) }
        return container
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 9, minute: Int = 0) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day,
                                                   hour: hour, minute: minute))!
    }

    private func makeRoutine(in context: NSManagedObjectContext,
                             title: String = "Morning walk",
                             category: String = "wellbeing",
                             days: RepeatDays? = nil,
                             active: Bool = true) -> Routine {
        let routine = Routine(context: context)
        routine.id = UUID()
        routine.title = title
        routine.category = category
        routine.timeOfDay = date(2026, 1, 1, hour: 18, minute: 30)
        // Default is applied here (on the main actor) rather than as a default
        // argument, because default arguments run outside the main actor and
        // `RepeatDays.everyDay` is main-actor isolated.
        routine.days = days ?? .everyDay
        routine.isActive = active
        routine.createdAt = .now
        return routine
    }

    private func events(in context: NSManagedObjectContext) throws -> [CareEvent] {
        let request: NSFetchRequest<CareEvent> = CareEvent.fetchRequest()
        return try context.fetch(request)
    }

    // Repeat days

    // UT01
    func testRepeatDaysText() {
        XCTAssertEqual(RepeatDays.everyDay.text, "Every day")
        XCTAssertEqual(RepeatDays([.monday, .tuesday, .wednesday, .thursday, .friday]).text, "Weekdays")
        XCTAssertEqual(RepeatDays([.saturday, .sunday]).text, "Weekends")
        XCTAssertEqual(RepeatDays([.monday, .wednesday, .friday]).text, "Mon, Wed, Fri")
        XCTAssertEqual(RepeatDays([]).text, "No days selected")
    }

    // UT02
    func testWeekdayNumberMapsToCorrectDay() {
        XCTAssertEqual(RepeatDays.from(weekday: 1), .sunday)
        XCTAssertEqual(RepeatDays.from(weekday: 2), .monday)
        XCTAssertEqual(RepeatDays.from(weekday: 7), .saturday)
    }

    //  Routine scheduling

    // UT03
    func testRoutineOnlyScheduledOnSelectedDays() {
        let container = makeContainer()
        let routine = makeRoutine(in: container.viewContext, days: [.monday])
        XCTAssertTrue(routine.isScheduled(on: date(2026, 10, 19)))   // Monday
        XCTAssertFalse(routine.isScheduled(on: date(2026, 10, 20)))  // Tuesday
    }

    // UT04
    func testPausedRoutineIsNotScheduled() {
        let container = makeContainer()
        let routine = makeRoutine(in: container.viewContext, active: false)
        XCTAssertFalse(routine.isScheduled(on: date(2026, 10, 19)))
    }

    // UT05
    func testScheduledTimeUsesRoutineTimeOnGivenDay() {
        let container = makeContainer()
        let routine = makeRoutine(in: container.viewContext)
        let result = routine.scheduledTime(on: date(2026, 10, 19))
        let parts = Calendar.current.dateComponents([.day, .hour, .minute], from: result)
        XCTAssertEqual(parts.day, 19)
        XCTAssertEqual(parts.hour, 18)
        XCTAssertEqual(parts.minute, 30)
    }

    //  Marking routines done

    // UT06
    func testMarkDoneSavesLogAndHistoryEvent() throws {
        let container = makeContainer()
        let context = container.viewContext
        let routine = makeRoutine(in: context)

        routine.markDone(on: .now, in: context)

        XCTAssertTrue(routine.isDone(on: .now))
        XCTAssertEqual(routine.log(on: .now)?.status, "done")
        let history = try events(in: context)
        XCTAssertEqual(history.count, 1)
        XCTAssertEqual(history.first?.kind, "routineDone")
    }

    // UT07
    func testMedicationIsMarkedAsTaken() throws {
        let container = makeContainer()
        let context = container.viewContext
        let medicine = makeRoutine(in: context, title: "Metformin", category: "medication")

        medicine.markDone(on: .now, in: context)

        XCTAssertEqual(medicine.log(on: .now)?.status, "taken")
        XCTAssertEqual(try events(in: context).first?.summary, "Metformin taken")
    }

    // UT08
    func testToggleTwiceUndoesDone() {
        let container = makeContainer()
        let context = container.viewContext
        let routine = makeRoutine(in: context)

        routine.toggleDone(on: .now, in: context)
        XCTAssertTrue(routine.isDone(on: .now))

        routine.toggleDone(on: .now, in: context)
        XCTAssertFalse(routine.isDone(on: .now))
    }

    // Check-in

    // UT09
    func testCheckInIsSavedAndAddedToHistory() throws {
        let container = makeContainer()
        let context = container.viewContext

        CheckIn.record(source: "manual", in: context)

        let request: NSFetchRequest<CheckIn> = CheckIn.fetchRequest()
        let checkIns = try context.fetch(request)
        XCTAssertEqual(checkIns.count, 1)
        XCTAssertEqual(checkIns.first?.source, "manual")
        XCTAssertEqual(try events(in: context).first?.kind, "checkIn")
    }

    // Login error messages

    // UT10
    func testFriendlyLoginErrorMessages() {
        func message(_ code: Int) -> String {
            AuthService.message(for: NSError(domain: "FIRAuthErrorDomain", code: code))
        }
        XCTAssertEqual(message(17009), "Email or password is incorrect.")
        XCTAssertEqual(message(17007), "An account with this email already exists. Try signing in.")
        XCTAssertEqual(message(17026), "Password must be at least 6 characters.")
        XCTAssertEqual(message(17020), "No internet connection. Please try again.")
    }

    // More repeat days

    // UT11
    func testEveryWeekdayNumberMapsToCorrectDay() {
        XCTAssertEqual(RepeatDays.from(weekday: 3), .tuesday)
        XCTAssertEqual(RepeatDays.from(weekday: 4), .wednesday)
        XCTAssertEqual(RepeatDays.from(weekday: 5), .thursday)
        XCTAssertEqual(RepeatDays.from(weekday: 6), .friday)
    }

    // UT12
    func testRepeatDaysTextIsInWeekOrder() {
        // Days chosen out of order should still be listed Monday before Friday.
        XCTAssertEqual(RepeatDays([.friday, .monday]).text, "Mon, Fri")
    }

    // More routine scheduling

    // UT13
    func testEveryDayRoutineIsScheduledAllWeek() {
        let container = makeContainer()
        let routine = makeRoutine(in: container.viewContext)
        for day in 19...25 {   // Mon 19 Oct to Sun 25 Oct 2026
            XCTAssertTrue(routine.isScheduled(on: date(2026, 10, day)), "Not scheduled on \(day) Oct")
        }
    }

    // UT14
    func testWeekdayRoutineIsNotScheduledAtWeekend() {
        let container = makeContainer()
        let routine = makeRoutine(in: container.viewContext,
                                  days: [.monday, .tuesday, .wednesday, .thursday, .friday])
        XCTAssertTrue(routine.isScheduled(on: date(2026, 10, 23)))   // Friday
        XCTAssertFalse(routine.isScheduled(on: date(2026, 10, 24)))  // Saturday
        XCTAssertFalse(routine.isScheduled(on: date(2026, 10, 25)))  // Sunday
    }

    // UT15
    func testRoutineWithNoDaysIsNeverScheduled() {
        let container = makeContainer()
        let routine = makeRoutine(in: container.viewContext, days: [])
        for day in 19...25 {
            XCTAssertFalse(routine.isScheduled(on: date(2026, 10, day)))
        }
    }

    // UT16
    func testScheduledTimeKeepsTheGivenDate() {
        let container = makeContainer()
        let routine = makeRoutine(in: container.viewContext)
        let result = routine.scheduledTime(on: date(2027, 3, 5))
        let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: result)
        XCTAssertEqual(parts.year, 2027)
        XCTAssertEqual(parts.month, 3)
        XCTAssertEqual(parts.day, 5)
        XCTAssertEqual(parts.hour, 18)
        XCTAssertEqual(parts.minute, 30)
    }

    // More marking routines done

    // UT17
    func testNewRoutineIsNotDoneAndHasNoLog() throws {
        let container = makeContainer()
        let context = container.viewContext
        let routine = makeRoutine(in: context)

        XCTAssertFalse(routine.isDone(on: .now))
        XCTAssertNil(routine.log(on: .now))
        XCTAssertTrue(try events(in: context).isEmpty)
    }

    // UT18
    func testDoneOnOneDayDoesNotCountForAnotherDay() {
        let container = makeContainer()
        let context = container.viewContext
        let routine = makeRoutine(in: context)

        routine.markDone(on: date(2026, 10, 19), in: context)

        XCTAssertTrue(routine.isDone(on: date(2026, 10, 19)))
        XCTAssertFalse(routine.isDone(on: date(2026, 10, 20)))
    }

    // UT19
    func testMarkingDoneOnTwoDaysAddsTwoHistoryEvents() throws {
        let container = makeContainer()
        let context = container.viewContext
        let routine = makeRoutine(in: context)

        routine.markDone(on: date(2026, 10, 19), in: context)
        routine.markDone(on: date(2026, 10, 20), in: context)

        XCTAssertTrue(routine.isDone(on: date(2026, 10, 19)))
        XCTAssertTrue(routine.isDone(on: date(2026, 10, 20)))
        XCTAssertEqual(try events(in: context).count, 2)
    }

    // UT20
    func testMarkingOneRoutineDoesNotAffectAnother() {
        let container = makeContainer()
        let context = container.viewContext
        let walk = makeRoutine(in: context, title: "Morning walk")
        let medicine = makeRoutine(in: context, title: "Metformin", category: "medication")

        walk.markDone(on: .now, in: context)

        XCTAssertTrue(walk.isDone(on: .now))
        XCTAssertFalse(medicine.isDone(on: .now))
    }

    // More check-in

    // UT21
    func testEachCheckInIsSavedSeparately() throws {
        let container = makeContainer()
        let context = container.viewContext

        CheckIn.record(source: "manual", in: context)
        CheckIn.record(source: "manual", in: context)

        let request: NSFetchRequest<CheckIn> = CheckIn.fetchRequest()
        XCTAssertEqual(try context.fetch(request).count, 2)
        XCTAssertEqual(try events(in: context).filter { $0.kind == "checkIn" }.count, 2)
    }

    // More login error messages

    // UT22
    func testUnknownLoginErrorStillGivesAMessage() {
        let text = AuthService.message(for: NSError(domain: "FIRAuthErrorDomain", code: 99999))
        XCTAssertFalse(text.isEmpty)
        XCTAssertNotEqual(text, "Email or password is incorrect.")
    }
}
