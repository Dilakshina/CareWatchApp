import SwiftUI

struct RoutinesView: View {
    var body: some View {
        NavigationStack {
            Text("Routine dashboard coming soon")
                .foregroundStyle(AppColors.secondaryText)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColors.background)
                .navigationTitle("routines")
        }
    }
}

#Preview {
    RoutinesView()
}
