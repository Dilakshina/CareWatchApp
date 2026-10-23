import WidgetKit
import SwiftUI

// The small summary the app saves for the widget (shared through the App Group)
struct CareWatchSnapshot: Codable {
    var routinesCompleted: Int
    var routinesTotal: Int
    var steps: Int
    var nextTitle: String
    var nextTime: String
    var updatedAt: Date

    static let groupID = "group.com.d.CareWatch"
    static let key = "careWatchSnapshot"

    static let sample = CareWatchSnapshot(routinesCompleted: 3, routinesTotal: 4, steps: 4260,
                                          nextTitle: "Evening medication", nextTime: "6:00 PM",
                                          updatedAt: .now)

    static func load() -> CareWatchSnapshot? {
        guard let data = UserDefaults(suiteName: groupID)?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(CareWatchSnapshot.self, from: data)
    }
}

struct CareWatchEntry: TimelineEntry {
    let date: Date
    let snapshot: CareWatchSnapshot
    let isSample: Bool
}

// Tells iOS what to show and when to refresh
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> CareWatchEntry {
        CareWatchEntry(date: .now, snapshot: .sample, isSample: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (CareWatchEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CareWatchEntry>) -> Void) {
        // Refresh at least every 30 minutes; the app also asks for a refresh when data changes
        let next = Date.now.addingTimeInterval(30 * 60)
        completion(Timeline(entries: [currentEntry()], policy: .after(next)))
    }

    private func currentEntry() -> CareWatchEntry {
        if let saved = CareWatchSnapshot.load() {
            return CareWatchEntry(date: .now, snapshot: saved, isSample: false)
        }
        return CareWatchEntry(date: .now, snapshot: .sample, isSample: true)
    }
}

// Home Screen widget design (small and medium)
struct CareWatchWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CareWatchEntry

    // The widget is a separate target, so it has its own copy of the brand colours
    private let teal = Color(red: 13 / 255, green: 127 / 255, blue: 133 / 255)
    private let ink = Color(red: 28 / 255, green: 48 / 255, blue: 71 / 255)
    private let muted = Color(red: 94 / 255, green: 109 / 255, blue: 128 / 255)

    var body: some View {
        let s = entry.snapshot
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("CareWatch", systemImage: "heart.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(teal)
                Spacer()
                Text("Today")
                    .font(.caption2)
                    .foregroundStyle(muted)
            }

            Text(s.routinesTotal > 0 && s.routinesCompleted == s.routinesTotal
                 ? "All done today" : "You're doing well")
                .font(.headline)
                .foregroundStyle(ink)

            if family == .systemMedium {
                Divider()
                HStack(alignment: .top) {
                    stat("\(s.routinesCompleted) / \(s.routinesTotal)", "routines")
                    Spacer()
                    stat(s.steps.formatted(), "steps")
                    Spacer()
                    stat(s.nextTime, s.nextTitle)
                }
            } else {
                Spacer(minLength: 0)
                stat("\(s.routinesCompleted) / \(s.routinesTotal)", "routines")
                stat(s.steps.formatted(), "steps")
            }

            if entry.isSample {
                Text("Open CareWatch to update")
                    .font(.caption2)
                    .foregroundStyle(muted)
            }
        }
        .containerBackground(.white, for: .widget)
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.caption2)
                .foregroundStyle(muted)
                .lineLimit(1)
        }
    }
}

struct CareWatchWidget: Widget {
    let kind = "CareWatchWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            CareWatchWidgetView(entry: entry)
        }
        .configurationDisplayName("CareWatch today")
        .description("Routine progress, steps and your next reminder.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemMedium) {
    CareWatchWidget()
} timeline: {
    CareWatchEntry(date: .now, snapshot: .sample, isSample: false)
}
