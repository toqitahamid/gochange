import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = DashboardViewModel()
    @StateObject private var userProfile = UserProfileService.shared
    @EnvironmentObject var workoutManager: WorkoutManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    header
                    
                    // Pills Row
                    HStack(spacing: 12) {
                        NextWorkoutPill()
                        Spacer()
                    }
                    .padding(.bottom, 4)

                    // Summary Rings
                    SummaryRingsView(
                        strain: viewModel.strainScore,
                        recovery: viewModel.recoveryScore,
                        sleep: viewModel.sleepScore
                    )

                    // Daily Insight
                    dailyInsight

                    // Health Monitor
                    HealthMonitorGrid(
                        rhr: viewModel.restingHR,
                        hrv: viewModel.hrv,
                        respiratoryRate: viewModel.respiratoryRate,
                        oxygenSaturation: viewModel.oxygenSaturation,
                        bodyTemperature: viewModel.bodyTemperature,
                        stepCount: viewModel.stepCount,
                        vo2Max: viewModel.vo2Max,
                        sleepDuration: viewModel.sleepData?.totalDuration
                    )

                    // Timeline
                    TimelineView(workouts: viewModel.recentWorkouts)

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(AppColors.background.ignoresSafeArea()) // Clinical light background from design system
            .preferredColorScheme(.light) // Force Light Mode for the requested "White/Light Gray" theme
            .onAppear {
                Task {
                    await viewModel.loadData(context: modelContext)
                }
            }
        }
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(Date().formatted(date: .long, time: .omitted))
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                
                Text(viewModel.greeting)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
            }
            
            Spacer()
            
            // Settings Button (User Initials)
            NavigationLink(destination: SettingsView()) {
                Circle()
                    .fill(AppColors.primary.opacity(0.08))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(userInitials)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppColors.primary)
                    )
            }
        }
        // Removed padding bottom to fit pills closer
    }
    
    private var userInitials: String {
        let firstInitial = userProfile.firstName.prefix(1).uppercased()
        let lastInitial = userProfile.lastName.prefix(1).uppercased()
        return "\(firstInitial)\(lastInitial)"
    }
    
    private var dailyInsight: some View {
        HStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 24))
                .foregroundColor(AppColors.primary)
                .frame(width: 50, height: 50)
                .background(AppColors.primary.opacity(0.08))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Daily Insight")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textSecondary)
                
                Text(insightText)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
            }
            
            Spacer()
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
        }
    }
    
    private var insightText: String {
        if viewModel.recoveryScore >= 66 {
            return "You are well recovered. Ready to train hard!"
        } else if viewModel.recoveryScore >= 33 {
            return "Moderate recovery. Maintain a steady pace."
        } else {
            return "Low recovery. Prioritize rest today."
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [WorkoutSession.self, WorkoutDay.self])
}

#Preview {
    HomeView()
        .modelContainer(for: [WorkoutSession.self, WorkoutDay.self])
}



// MARK: - Next Workout Pill
// MARK: - Next Workout Pill
struct NextWorkoutPill: View {
    @Query(sort: \WorkoutDay.dayNumber) private var workouts: [WorkoutDay]
    
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(AppColors.success) // Mint success color
                    .frame(width: 32, height: 32)
                
                Image(systemName: "figure.run")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 0) {
                Text("Next Workout")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(nextWorkoutText)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            Image(systemName: "chevron.down")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding(.leading, 6)
        .padding(.trailing, 16)
        .padding(.vertical, 6)
        .background(Color.white)
        .cornerRadius(22)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var nextWorkoutText: String {
        guard !workouts.isEmpty else { return "No Workouts" }
        
        // Find next workout based on current day
        // Assuming dayNumber 1 = Monday, 7 = Sunday to match typical schedule
        // Calendar.current.component(.weekday) returns 1 = Sunday, 2 = Monday
        let calendar = Calendar.current
        let todayWeekday = calendar.component(.weekday, from: Date())
        
        // Convert Sunday=1...Saturday=7 to Monday=1...Sunday=7
        let currentDayISO = todayWeekday == 1 ? 7 : todayWeekday - 1
        
        // Find first workout with dayNumber > currentDayISO
        if let next = workouts.first(where: { $0.dayNumber > currentDayISO }) {
            return "\(next.name) • \(dayName(for: next.dayNumber))"
        }
        
        // Wrap around to first workout of the week
        if let first = workouts.first {
            return "\(first.name) • \(dayName(for: first.dayNumber))"
        }
        
        return "No Plan"
    }
    
    private func dayName(for number: Int) -> String {
        switch number {
        case 1: return "Monday"
        case 2: return "Tuesday"
        case 3: return "Wednesday"
        case 4: return "Thursday"
        case 5: return "Friday"
        case 6: return "Saturday"
        case 7: return "Sunday"
        default: return "Day \(number)"
        }
    }
}

