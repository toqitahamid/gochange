import SwiftUI
import SwiftData

struct JournalView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var userProfile = UserProfileService.shared
    @EnvironmentObject var workoutManager: WorkoutManager
    
    @State private var selectedMetricInfo: MetricExplanationSheet.MetricType?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Header
                    header
                    
                    // MARK: - Next Workout Pill
                    HStack {
                        NextWorkoutPill()
                        Spacer()
                    }
                    
                    // MARK: - Score Cards Grid (2x2)
                    scoreCardsGrid
                    
                    // MARK: - Vitals Section
                    VitalsGridView(
                        hrv: viewModel.hrv > 0 ? viewModel.hrv : nil,
                        rhr: viewModel.restingHR > 0 ? viewModel.restingHR : nil,
                        respiratoryRate: viewModel.respiratoryRate,
                        spo2: viewModel.oxygenSaturation,
                        vo2Max: viewModel.vo2Max
                    )
                    
                    // MARK: - Daily Insight
                    dailyInsight
                    
                    // MARK: - Recent Activity Timeline
                    TimelineView(workouts: viewModel.recentWorkouts)
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(AppColors.background.ignoresSafeArea())
            .refreshable {
                await viewModel.loadData(context: modelContext)
            }
            .task {
                await viewModel.loadData(context: modelContext)
            }
        }
        .sheet(item: $selectedMetricInfo) { metric in
            MetricExplanationSheet(metric: metric, currentValue: nil)
                .presentationDetents([.large])
        }
    }
    
    // MARK: - Header
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
            
            // Settings Button
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
    }
    
    private var userInitials: String {
        let firstInitial = userProfile.firstName.prefix(1).uppercased()
        let lastInitial = userProfile.lastName.prefix(1).uppercased()
        return "\(firstInitial)\(lastInitial)"
    }
    
    // MARK: - Score Cards Grid
    private var scoreCardsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            // Recovery
            RecoveryRingCard(
                score: Double(viewModel.recoveryScore),
                status: recoveryStatus
            ) {
                selectedMetricInfo = .readiness
            }
            
            // Energy Bank (calculated from recovery + sleep)
            EnergyBankCard(
                level: energyLevel
            ) {
                // Could navigate to energy detail
            }
            
            // Strain (Full Width - spans 2 columns? No, let's keep the grid consistent)
            // Actually, let's make Strain and Sleep full-width below
        }
        
        // Full Width Cards
        VStack(spacing: 12) {
            StrainProgressCard(
                current: Double(viewModel.strainScore) / 5.0, // Convert 0-100 to 0-21 scale approx
                targetLow: 10,
                targetHigh: 14,
                status: strainStatus
            ) {
                selectedMetricInfo = .systemicLoad
            }
            
            SleepScoreCard(
                score: Double(viewModel.sleepScore),
                duration: viewModel.sleepData?.totalDuration ?? 0,
                deepPercent: viewModel.sleepData?.deepPercentage ?? 0.20,
                remPercent: viewModel.sleepData?.remPercentage ?? 0.25
            ) {
                // Navigate to Sleep Detail
            }
        }
    }
    
    // MARK: - Daily Insight
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
    
    // MARK: - Computed Properties
    private var recoveryStatus: String {
        let score = viewModel.recoveryScore
        if score >= 85 { return "Prime" }
        if score >= 70 { return "Ready" }
        if score >= 50 { return "Steady" }
        if score >= 30 { return "Recovering" }
        return "Low"
    }
    
    private var strainStatus: String {
        let score = Double(viewModel.strainScore) / 5.0 // Convert to 0-21 scale
        if score < 10 { return "Restoring" }
        if score > 14 { return "Overreaching" }
        return "Optimal"
    }
    
    private var energyLevel: Double {
        // Energy = Recovery weighted average with Sleep
        return Double(viewModel.recoveryScore * 6 + viewModel.sleepScore * 4) / 10.0
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
    JournalView()
        .modelContainer(for: [WorkoutSession.self, WorkoutDay.self])
}
