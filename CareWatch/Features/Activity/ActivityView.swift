import SwiftUI

struct ActivityView: View {
    var body: some View {
        NavigationStack {
            Text("Activity dashboard coming soon")
                .foregroundStyle(AppColors.secondaryText)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColors.background)
                .navigationTitle("Activity")
        }
    }
}

#Preview {
    TodayView()
}
