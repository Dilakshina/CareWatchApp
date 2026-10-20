import SwiftUI

struct TodayView: View {
    let summary = TodaySummary.sample

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)) + " · Your daily overview")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.secondaryText)

                    statusCard

                    section("Next up") {
                        ListRow(systemImage: "pills.fill",
                                title: summary.nextMedication,
                                subtitle: summary.nextMedicationDetail)
                    }

                    section("Your day") {
                        ListRow(systemImage: "checkmark",
                                title: "Daily checklist",
                                subtitle: "\(summary.routinesCompleted) of \(summary.routinesTotal) completed")
                        ListRow(systemImage: "figure.walk",
                                title: "Walking activity",
                                subtitle: "\(summary.steps.formatted()) steps today")
                    }

                    ListRow(systemImage: "exclamationmark",
                            title: "Emergency contact",
                            subtitle: "Call your selected family member",
                            tint: AppColors.emergency,
                            iconBackground: .white,
                            cardBackground: AppColors.emergencySoft,
                            showsChevron: false)
                }
                .padding(20)
            }
            .background(AppColors.background)
            .navigationTitle("\(greeting), \(summary.userName)")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // Opens Settings in feature/settings-privacy
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .tint(AppColors.brandTeal)
                    .accessibilityLabel("Settings")
                }
            }
        }
    }

    // tabs on the screen pieces

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        default:      return "Good evening"
        }
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TODAY'S STATUS")
                .font(.caption.weight(.semibold))
                .opacity(0.85)
            Text("You're doing well")
                .font(.title2.bold())
            Text("\(summary.routinesCompleted) of \(summary.routinesTotal) routines completed")
                .font(.subheadline)
            ProgressView(value: summary.progress)
                .tint(.white)
                .padding(.top, 6)
        }
        .foregroundStyle(.white)
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.primaryGradient)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .combine)
    }

    private func section<Content: View>(_ title: String,
                                        @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.title3.bold())
                .foregroundStyle(AppColors.ink)
            content()
        }
    }
}

#Preview {
    TodayView()
}
