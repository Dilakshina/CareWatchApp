import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(AppColors.primaryGradient)
                .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        PrimaryButton(title: "Mark as taken") {
            print("Mark as taken tapped")
        }

        PrimaryButton(title: "Save reminder") { }
            .environment(\.dynamicTypeSize, .accessibility2)
    }
    .padding()
    .background(AppColors.background)
}
