import SwiftUI

struct TodayView: View {
    var body: some View {
        NavigationStack {
            Text("Today dashboard coming soon")
                .foregroundStyle(AppColors.secondaryText)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColors.background)
                .navigationTitle("Today")
        }
    }
}

#Preview {
    TodayView()
}
