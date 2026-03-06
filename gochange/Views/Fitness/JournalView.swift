import SwiftUI
import SwiftData

struct JournalView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject var workoutManager: WorkoutManager
    
    @State private var selectedMetricInfo: MetricExplanationSheet.MetricType?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Header
                    header
                    
                    // MARK: - Top Metrics Row (Recovery, Sleep, Strain)
                    HStack(spacing: 12) {
                        // Recovery
                        RecoveryRingCard(
                            score: Double(viewModel.recoveryScore),
                            status: recoveryStatus
                        ) {
                            selectedMetricInfo = .readiness
                        }
                        
                        // Sleep
                        SleepScoreCard(
                            score: Double(viewModel.sleepScore),
                            duration: viewModel.sleepData?.totalDuration ?? 0,
                            deepPercent: viewModel.sleepData?.deepPercentage ?? 0.20,
                            remPercent: viewModel.sleepData?.remPercentage ?? 0.25
                        ) {
                            // Detail logic
                        }
                        
                        // Strain
                        StrainProgressCard(
                            current: Double(viewModel.strainScore) / 5.0,
                            targetLow: 10,
                            targetHigh: 14,
                            status: strainStatus
                        ) {
                            selectedMetricInfo = .systemicLoad
                        }
                    }
                    .frame(height: 140) // Fixed height for alignment
                    
                    // MARK: - Activity Rings
                    ActivityRingsCard(
                        moveCurrent: viewModel.moveCalories,
                        moveTarget: viewModel.moveTarget,
                        exerciseCurrent: viewModel.exerciseMinutes,
                        exerciseTarget: viewModel.exerciseTarget,
                        standCurrent: Double(viewModel.standHours),
                        standTarget: Double(viewModel.standTarget)
                    )
                    
                    // MARK: - Daily Insight
                    dailyInsight
                    
                    // MARK: - Vitals Grid
                    VitalsGridView(
                        hrv: viewModel.hrv > 0 ? viewModel.hrv : nil,
                        rhr: viewModel.restingHR > 0 ? viewModel.restingHR : nil,
                        respiratoryRate: viewModel.respiratoryRate,
                        spo2: viewModel.oxygenSaturation,
                        vo2Max: viewModel.vo2Max
                    )
                    
                    // MARK: - Recent Activity Timeline
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Activity Timeline")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 4)
                        
                        TimelineView(workouts: viewModel.recentWorkouts)
                    }
                    
                    Spacer(minLength: 120) // Space for floating tab bar
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
            Text("Journal")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
            
            // Profile Button
            NavigationLink(destination: SettingsView()) {
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.primary)
                    )
            }
        }
    }
    
    // MARK: - Daily Insight
    private var dailyInsight: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Insights")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 24))
                    .foregroundColor(AppColors.primary)
                    .frame(width: 40, height: 40)
                    .background(AppColors.primary.opacity(0.1))
                    .clipShape(Circle())
                
                Text(viewModel.insightText)
                    .font(.subheadline)
                    .foregroundColor(AppColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 5)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.gray.opacity(0.15), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Computed Properties
    private var recoveryStatus: String {
        let score = viewModel.recoveryScore
        if score >= 85 { return "Optimal" }
        if score >= 70 { return "Ready" }
        if score >= 50 { return "Steady" }
        if score >= 30 { return "Recovering" }
        return "Low"
    }
    
    private var strainStatus: String {
        let score = Double(viewModel.strainScore) / 5.0
        if score < 10 { return "Restoring" }
        if score > 14 { return "High" }
        return "Optimal"
    }
}

#Preview {
    JournalView()
        .modelContainer(for: [WorkoutSession.self, WorkoutDay.self])
}
