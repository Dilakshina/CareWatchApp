import SwiftUI

struct CardView<Content: View>: View {
    var background: Color = .white
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: AppColors.ink.opacity(0.08), radius: 12, x: 0, y: 5)
    }
}

#Preview {
    VStack(spacing: 16) {
        CardView {
            Text("Evening medication").font(.headline)
            Text("6:00 PM · After dinner").foregroundStyle(AppColors.secondaryText)
        }
        CardView(background: AppColors.emergencySoft) {
            Text("Emergency contact").font(.headline).foregroundStyle(AppColors.emergency)
        }
    }
    .padding()
    .background(AppColors.background)
}
