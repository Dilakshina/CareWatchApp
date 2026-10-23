import SwiftUI
import CoreData

struct TodayView: View {
    @FetchRequest(sortDescriptors: [SortDescriptor(\.timeOfDay)])
    private var routines: FetchedResults<Routine>

    @State private var selected: Routine?
    @State private var showingSettings = false
    
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var health: HealthService
    @FetchRequest(sortDescriptors: []) private var profiles: FetchedResults<UserProfile>

    // First name from the saved profile
    private var firstName: String {
        let profile = profiles.first { $0.accountID == auth.uid }
        return profile?.fullName?.components(separatedBy: " ").first ?? "there"
    }

    // The next routine today that isn't done yet
    private var nextRoutine: Routine? {
        routines
            .filter { $0.isScheduled(on: .now) && !$0.isDone(on: .now) }
            .min { $0.scheduledTime(on: .now) < $1.scheduledTime(on: .now) }
    }

    private var summary: TodaySummary {
        TodaySummary(routines: Array(routines), userName: firstName, steps: health.steps)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)) + " · Your daily overview")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.secondaryText)

                    statusCard

                    section("Next up") {
                        Button { selected = nextRoutine } label: {
                            ListRow(systemImage: "pills.fill",
                                    title: summary.nextMedication,
                                    subtitle: summary.nextMedicationDetail)
                        }
                        .buttonStyle(.plain)
                        .disabled(nextRoutine == nil)
                    }

                    section("Your day") {
                        ListRow(systemImage: "checkmark",
                                title: "Daily checklist",
                                subtitle: "\(summary.routinesCompleted) of \(summary.routinesTotal) completed")
                        ListRow(systemImage: "figure.walk",
                                title: "Walking activity",
                                subtitle: "\(summary.steps.formatted()) steps today")
                    }

                    NavigationLink {
                        EmergencyContactView()
                    } label: {
                        ListRow(systemImage: "exclamationmark",
                                title: "Emergency contact",
                                subtitle: "Call your selected family member",
                                tint: AppColors.emergency,
                                iconBackground: .white,
                                cardBackground: AppColors.emergencySoft,
                                showsChevron: false)
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
            }
            .background(AppColors.background)
            .navigationTitle("\(greeting), \(summary.userName)")
            .task { await health.refresh() }
            .navigationDestination(item: $selected) { routine in
                MedicationDetailView(routine: routine)
            }
            .navigationDestination(isPresented: $showingSettings) {
                SettingsView()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .tint(AppColors.brandTeal)
                    .accessibilityLabel("Settings")
                }
            }
        }
    }

    // pieces of the screen

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
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
