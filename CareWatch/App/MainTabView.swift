import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            Tab("Today", systemImage: "house") {
                TodayView()
            }
            Tab("Routines", systemImage: "checklist") {
                RoutinesView()
            }
            Tab("Activity", systemImage: "figure.walk") {
                ActivityView()
            }
            Tab("Check-in", systemImage: "checkmark.circle") {
                CheckInView()
            }
            Tab("History", systemImage: "clock.arrow.circlepath") {
                HistoryView()
            }
        }
        .tint(AppColors.brandTeal)
    }
}

#Preview {
    MainTabView()
}
