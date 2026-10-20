import SwiftUI

struct CheckInView: View {
    var body: some View {
        NavigationStack {
            Text("CheckIn dashboard coming soon")
                .foregroundStyle(AppColors.secondaryText)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColors.background)
                .navigationTitle("CheckIn")
        }
    }
}

#Preview {
    CheckInView()
}
