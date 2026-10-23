import Foundation
import UserNotifications
import CoreData

// Schedules and cancels local reminder notifications for routines
enum ReminderService {

    // Asks once for permission. iOS only shows the popup the first time.
    static func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    // Removes this routine's old notifications and adds fresh ones
    static func schedule(_ routine: Routine) {
        cancel(routine)
        guard routine.notify, routine.isActive,
              let id = routine.id?.uuidString,
              let time = routine.timeOfDay else { return }

        let parts = Calendar.current.dateComponents([.hour, .minute], from: time)

        let content = UNMutableNotificationContent()
        content.title = routine.title ?? "CareWatch reminder"
        content.body = routine.isMedication
            ? "Time for your \(routine.dosage ?? "medication"). Open CareWatch to mark it as taken."
            : "It's time for this routine."
        content.sound = .default
        content.userInfo = ["routineID": id]

        if routine.days == .everyDay {
            // One notification that repeats every day
            add(id: "\(id)-daily", hour: parts.hour, minute: parts.minute, weekday: nil, content: content)
        } else {
            // One repeating notification per selected weekday
            for (weekday, day) in weekdays where routine.days.contains(day) {
                add(id: "\(id)-\(weekday)", hour: parts.hour, minute: parts.minute,
                    weekday: weekday, content: content)
            }
        }
    }

    // Removes every notification belonging to this routine
    static func cancel(_ routine: Routine) {
        guard let id = routine.id?.uuidString else { return }
        let ids = ["\(id)-daily"] + (1...7).map { "\(id)-\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }


    // Calendar weekday numbers: 1 = Sunday … 7 = Saturday
    private static let weekdays: [(Int, RepeatDays)] = [
        (1, .sunday), (2, .monday), (3, .tuesday), (4, .wednesday),
        (5, .thursday), (6, .friday), (7, .saturday)
    ]

    private static func add(id: String, hour: Int?, minute: Int?, weekday: Int?,
                            content: UNNotificationContent) {
        var when = DateComponents()
        when.hour = hour
        when.minute = minute
        when.weekday = weekday
        let trigger = UNCalendarNotificationTrigger(dateMatching: when, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
