import SwiftUI

// Success banner shown at the top after an action (dose taken, check-in, saved)
struct ToastBanner: View {
    let title: String
    let message: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(AppColors.brandTeal, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppColors.ink)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(AppColors.secondaryText)
            }
            Spacer()
        }
        .padding(14)
        .background(.white, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: AppColors.ink.opacity(0.15), radius: 16, y: 6)
        .padding(.horizontal, 16)
        .transition(.move(edge: .top).combined(with: .opacity))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ToastBanner(title: "Dose marked as taken", message: "Evening medication · 6:04 PM")
        .padding(.vertical)
        .background(AppColors.background)
}
