import SwiftUI

struct HistoryView: View {
    var body: some View {
        NavigationStack {
            Text("History dashboard coming soon")
                .foregroundStyle(AppColors.secondaryText)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColors.background)
                .navigationTitle("History")
        }
    }
}

#Preview {
    HistoryView()
}
