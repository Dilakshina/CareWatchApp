import SwiftUI
import Charts

//Activity & health and Walking activity
struct ActivityView: View {
    @EnvironmentObject private var health: HealthService
    private let goal = 6000

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Your movement at a glance")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.secondaryText)

                    if !health.isAvailable {
                        infoCard(icon: "heart.slash",
                                 title: "Apple Health isn't available",
                                 text: "This device doesn't support Apple Health. Reminders and check-ins still work.")
                    } else if !health.isConnected {
                        connectCard
                    }
                    else {
                        stepsCard
                        HStack(spacing: 12) {
                            tile(value: String(format: "%.1f km", health.distanceKm),
                                 label: "Walking distance", icon: "figure.walk")
                            tile(value: "\(health.activeMinutes) min",
                                 label: "Active time", icon: "clock")
                        }
                        chartCard
                        if health.steps == 0 {
                            infoCard(icon: "info.circle",
                                     title: "No steps yet today",
                                     text: "Steps appear here once Apple Health records them. Pull down to refresh.")
                        }
                    }

                    Label("Only data you allow in Apple Health is shown here. It stays on this iPhone.",
                          systemImage: "lock")
                        .font(.footnote)
                        .foregroundStyle(AppColors.ink)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppColors.mint, in: RoundedRectangle(cornerRadius: 16))
                }
                .padding(20)
            }
            .background(AppColors.background)
            .navigationTitle("Activity & health")
            .refreshable { await health.refresh() }
            .task { await health.refresh() }
        }
    }
    private var connectCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Label("Connect Apple Health", systemImage: "heart.fill")
                    .font(.headline)
                    .foregroundStyle(AppColors.ink)
                Text("CareWatch can show your steps, walking distance and active time. It only reads this data and never changes it.")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.secondaryText)
                PrimaryButton(title: "Connect Apple Health") {
                    Task { await health.connect() }
                }
            }
        }
    }

    private var stepsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("STEPS TODAY")
                .font(.caption.weight(.semibold))
                .opacity(0.85)
            Text(health.steps.formatted())
                .font(.system(size: 46, weight: .bold))
            Text("of \(goal.formatted()) daily goal")
                .font(.subheadline)
            ProgressView(value: min(Double(health.steps) / Double(goal), 1))
                .tint(.white)
                .padding(.top, 4)
        }
        .foregroundStyle(.white)
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.primaryGradient)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .combine)
    }

    private func tile(value: String, label: String, icon: String) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(AppColors.brandTeal)
                Text(value)
                    .font(.title2.bold())
                    .foregroundStyle(AppColors.ink)
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.secondaryText)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var chartCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Daily movement")
                    .font(.headline)
                    .foregroundStyle(AppColors.ink)
                Chart(0..<24, id: \.self) { hour in
                    BarMark(x: .value("Hour", hour),
                            y: .value("Steps", health.hourlySteps[hour]))
                        .foregroundStyle(AppColors.brandTeal)
                }
                .chartXAxis { AxisMarks(values: [0, 6, 12, 18]) }
                .chartXAxisLabel("Hour of day")
                .frame(height: 150)
                .accessibilityLabel("Steps per hour today")
            }
        }
    }

    private func infoCard(icon: String, title: String, text: String) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 6) {
                Label(title, systemImage: icon)
                    .font(.headline)
                    .foregroundStyle(AppColors.ink)
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.secondaryText)
            }
        }
    }
}
