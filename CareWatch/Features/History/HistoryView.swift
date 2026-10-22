import SwiftUI
import CoreData

// One day of history
struct HistoryDay: Identifiable {
    let day: Date
    let events: [CareEvent]
    var id: Date { day }
}

//Care history
struct HistoryView: View {
    @FetchRequest(sortDescriptors: [SortDescriptor(\.timestamp, order: .reverse)])
    private var events: FetchedResults<CareEvent>

    //Events grouped by day, newest day first
    private var days: [HistoryDay] {
        let groups = Dictionary(grouping: events) {
            Calendar.current.startOfDay(for: $0.timestamp ?? .now)
        }
        return groups.keys.sorted(by: >).map { HistoryDay(day: $0, events: groups[$0] ?? []) }
    }

    // The last 7 days, oldest first, for the weekly dots
    private var lastSevenDays: [Date] {
        let today = Calendar.current.startOfDay(for: .now)
        return (0..<7).reversed().compactMap {
            Calendar.current.date(byAdding: .day, value: -$0, to: today)
        }
    }

    private var activeDays: Set<Date> { Set(days.map(\.day)) }

    var body: some View {
        NavigationStack {
            List {
                weekCard
                    .historyRow()

                ForEach(days) { group in
                    Section {
                        ForEach(group.events, id: \.objectID) { event in
                            ListRow(systemImage: icon(for: event.kind),
                                    title: event.summary ?? "Event",
                                    subtitle: (event.timestamp ?? .now).formatted(date: .omitted, time: .shortened),
                                    showsChevron: false)
                                .historyRow()
                        }
                    } header: {
                        Text(title(for: group.day))
                            .font(.headline)
                            .foregroundStyle(AppColors.ink)
                            .textCase(nil)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(AppColors.background)
            .overlay {
                if events.isEmpty {
                    ContentUnavailableView("No history yet",
                                           systemImage: "clock",
                                           description: Text("Check-ins and completed routines will appear here."))
                }
            }
            .navigationTitle("Care history")
        }
    }
    private var weekCard: some View {
        let count = lastSevenDays.filter { activeDays.contains($0) }.count
        return VStack(alignment: .leading, spacing: 10) {
            Text("THIS WEEK")
                .font(.caption.weight(.semibold))
                .opacity(0.85)
            Text("\(count) active day\(count == 1 ? "" : "s")")
                .font(.title2.bold())
            Text("Days with check-ins or completed routines")
                .font(.subheadline)
                .opacity(0.9)
            HStack(spacing: 14) {
                ForEach(lastSevenDays, id: \.self) { day in
                    VStack(spacing: 4) {
                        Circle()
                            .fill(activeDays.contains(day) ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 14, height: 14)
                        Text(day.formatted(.dateTime.weekday(.narrow)))
                            .font(.caption2)
                    }
                }
            }
        }
        .foregroundStyle(.white)
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.primaryGradient)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .combine)
    }

    private func title(for day: Date) -> String {
        if Calendar.current.isDateInToday(day) { return "Today" }
        if Calendar.current.isDateInYesterday(day) { return "Yesterday" }
        return day.formatted(.dateTime.weekday(.wide).day().month(.wide))
    }

    private func icon(for kind: String?) -> String {
        switch kind {
        case "checkIn":     return "checkmark.circle"
        case "doseTaken":   return "pills.fill"
        case "routineDone": return "checkmark"
        case "undone":      return "arrow.uturn.backward"
        case "onboarding":  return "person"
        default:            return "clock"
        }
    }
}

private extension View {
    // Card-style List row with no grey lines
    func historyRow() -> some View {
        self
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
    }
}

#Preview {
    HistoryView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
