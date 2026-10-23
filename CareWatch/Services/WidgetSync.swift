import Foundation
import WidgetKit

//Saves a small summary for the Home Screen widget
// Only counts and times are shared: no names of contacts, no health records.
enum WidgetSync {
    private static let groupID = "group.com.d.CareWatch"
    private static let key = "careWatchSnapshot"

    // Same shape as CareWatchSnapshot in the widget, so the widget can decode it
    private struct Snapshot: Codable {
        var routinesCompleted: Int
        var routinesTotal: Int
        var steps: Int
        var nextTitle: String
        var nextTime: String
        var updatedAt: Date
    }

    static func update(completed: Int, total: Int, steps: Int, nextTitle: String, nextTime: String) {
        let snapshot = Snapshot(routinesCompleted: completed, routinesTotal: total, steps: steps,
                                nextTitle: nextTitle, nextTime: nextTime, updatedAt: .now)
        guard let defaults = UserDefaults(suiteName: groupID),
              let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: key)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
