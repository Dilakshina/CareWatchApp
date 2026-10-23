import SwiftUI
import UIKit

// A white rounded input box with a small label, matching the Figma form fields
struct FormField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var isSecure = false
    var keyboard: UIKeyboardType = .default
    var contentType: UITextContentType? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(AppColors.secondaryText)
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboard)
                        .textInputAutocapitalization(keyboard == .emailAddress ? .never : .words)
                        .autocorrectionDisabled(keyboard == .emailAddress)
                }
            }
            .font(.headline)
            .foregroundStyle(AppColors.ink)
            .textContentType(contentType)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: AppColors.ink.opacity(0.06), radius: 10, y: 4)
    }
}
