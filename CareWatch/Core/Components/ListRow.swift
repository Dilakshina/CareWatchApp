import SwiftUI

struct ListRow: View {
    let systemImage: String
    let title: String
    let subtitle: String
    var tint: Color = AppColors.brandTeal
    var iconBackground: Color = AppColors.mint
    var cardBackground: Color = .white
    var showsChevron = true

    var body: some View {
        CardView(background: cardBackground) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.headline)
                    .foregroundStyle(tint)
                    .frame(width: 44, height: 44)
                    .background(iconBackground, in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(tint == AppColors.brandTeal ? AppColors.ink : tint)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(AppColors.secondaryText)
                }

                Spacer()

                if showsChevron {
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(tint)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack(spacing: 12) {
        ListRow(systemImage: "checkmark", title: "Daily checklist", subtitle: "3 of 4 completed")
        ListRow(systemImage: "figure.walk", title: "Walking activity", subtitle: "4,260 steps today")
        ListRow(systemImage: "exclamationmark", title: "Emergency contact",
                subtitle: "Call your selected family member",
                tint: AppColors.emergency, iconBackground: .white,
                cardBackground: AppColors.emergencySoft, showsChevron: false)
    }
    .padding()
    .background(AppColors.background)
}
