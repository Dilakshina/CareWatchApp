import SwiftUI

extension Color {
    // creating colors from a hexadecimal numbers
    
    init(hex: UInt) {
        self.init(
            red:   Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8)  & 0xFF) / 255,
            blue:  Double(hex         & 0xFF) / 255
        )
    }
}

enum AppColors {
    static let brandTeal       = Color(hex: 0x0D7F85)
    static let mint            = Color(hex: 0xE2F6F3)
    static let background      = Color(hex: 0xF3FAFB)
    static let ink             = Color(hex: 0x1C3047)
    static let secondaryText   = Color(hex: 0x5E6D80)
    static let emergency       = Color(hex: 0xB93F59)
    static let emergencySoft   = Color(hex: 0xFFF0F2)
    static let warning         = Color(hex: 0xB86B25)

    static let primaryGradient = LinearGradient(
        colors: [Color(hex: 0x008D85), Color(hex: 0x38B7A6)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

#Preview("Colours") {
    VStack(spacing: 12) {
        RoundedRectangle(cornerRadius: 16)
            .fill(AppColors.primaryGradient)
            .frame(height: 70)
        HStack {
            ForEach([AppColors.brandTeal, AppColors.mint, AppColors.ink,
                     AppColors.secondaryText, AppColors.emergency], id: \.self) { colour in
                Circle().fill(colour).frame(width: 44, height: 44)
            }
        }
    }
    .padding()
    .background(AppColors.background)
}
