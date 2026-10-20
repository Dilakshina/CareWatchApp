import Foundation
import CoreData

//days of the weeks stored as numbers
struct RepeatDays: OptionSet {
    let rawValue: Int16

    static let monday    = RepeatDays(rawValue: 1 << 0)
    static let tuesday   = RepeatDays(rawValue: 1 << 1)
    static let wednesday = RepeatDays(rawValue: 1 << 2)
    static let thursday  = RepeatDays(rawValue: 1 << 3)
    static let friday    = RepeatDays(rawValue: 1 << 4)
    static let saturday  = RepeatDays(rawValue: 1 << 5)
    static let sunday    = RepeatDays(rawValue: 1 << 6)
    static let everyDay: RepeatDays = [.monday, .tuesday, .wednesday, .thursday,
                                       .friday, .saturday, .sunday]

    // put calender weekday numbers
    static func from(weekday: Int) -> RepeatDays {
        switch weekday {
        case 1:  return .sunday
        case 2:  return .monday
        case 3:  return .tuesday
        case 4:  return .wednesday
        case 5:  return .thursday
        case 6:  return .friday
        default: return .saturday
        }
    }
}

extension Routine {
    var days: RepeatDays {
        get { RepeatDays(rawValue: repeatDays) }
        set { repeatDays = newValue.rawValue }
    }

    var isMedication: Bool { category == "medication" }

    var timeText: String {
        (timeOfDay ?? .now).formatted(date: .omitted, time: .shortened)
    }
    
    
   // checking is this routin planned for the given day?
    func isScheduled(on date: Date, calendar: Calendar = .current) -> Bool {
        isActive && days.contains(.from(weekday: calendar.component(.weekday, from: date)))
    }
// the records for that day is there is one
    func log(on date: Date, calendar: Calendar = .current) -> RoutineLog? {
        let all = (logs as? Set<RoutineLog>) ?? []
        return all.first { log in
            guard let day = log.day else { return false }
            return calendar.isDate(day, inSameDayAs: date)
        }
    }

    func isDone(on date: Date) -> Bool {
        guard let log = log(on: date) else { return false }
        return log.status != "notTaken"
    }
 // routines time , place on the given day ex- today at 6.00 pm
    func scheduledTime(on date: Date, calendar: Calendar = .current) -> Date {
        let parts = calendar.dateComponents([.hour, .minute], from: timeOfDay ?? date)
        return calendar.date(bySettingHour: parts.hour ?? 0, minute: parts.minute ?? 0,
                             second: 0, of: date) ?? date
    }
}
