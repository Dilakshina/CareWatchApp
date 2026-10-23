import Foundation
import CoreMotion
import UserNotifications

// Uses the phone's motion data to SUGGEST a check-in. It never decides someone is unwell.
enum MotionService {

    // Motion activity is only available on a real iPhone (not the Simulator)
    static var isAvailable: Bool { CMMotionActivityManager.isActivityAvailable() }

    // true = walked or ran recently, false = no walking recorded, nil = can't tell (Simulator / no permission)
    static func movedRecently(hours: Double = 3) async -> Bool? {
        guard isAvailable else { return nil }
        let manager = CMMotionActivityManager()
        let start = Date.now.addingTimeInterval(-hours * 3600)
        return await withCheckedContinuation { continuation in
            manager.queryActivityStarting(from: start, to: .now, to: .main) { activities, error in
                _ = manager   // keep the manager alive until the answer arrives
                guard error == nil, let activities else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: activities.contains { $0.walking || $0.running })
            }
        }
    }

    // "Remind me later": a one-off local notification to check in
    static func remindToCheckIn(after seconds: TimeInterval = 30 * 60) {
        let content = UNMutableNotificationContent()
        content.title = "Daily check-in"
        content.body = "Tap \"I'm okay\" in CareWatch to let your family know."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(identifier: "movement-check-in", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
