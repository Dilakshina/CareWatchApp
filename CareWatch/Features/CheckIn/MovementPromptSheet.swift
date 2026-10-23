import SwiftUI
import CoreData

//Movement prompt: suggests a manual check-in
struct MovementPromptSheet: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(AppColors.warning)
                .frame(width: 70, height: 70)
                .background(AppColors.warningSoft, in: Circle())
                .padding(.top, 24)

            Text("Haven't seen you move in a while")
                .font(.title2.bold())
                .foregroundStyle(AppColors.ink)
                .multilineTextAlignment(.center)

            Text("Your iPhone hasn't recorded any walking recently. If you're okay, let your family know with a quick check-in.")
                .foregroundStyle(AppColors.secondaryText)
                .multilineTextAlignment(.center)

            Text("Phone movement alone doesn't confirm your activity.")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppColors.warning)

            Spacer(minLength: 8)

            PrimaryButton(title: "I'm okay · Check in") {
                CheckIn.record(source: "motionPrompt", in: context)
                dismiss()
            }

            Button {
                MotionService.remindToCheckIn()
                CareEvent.record("motionPrompt", summary: "Movement prompt · remind me later", in: context)
                try? context.save()
                dismiss()
            } label: {
                Text("Remind me in 30 minutes")
                    .font(.headline)
                    .foregroundStyle(AppColors.brandTeal)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(AppColors.mint, in: RoundedRectangle(cornerRadius: 18))
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .presentationDetents([.medium, .large])
    }
}
