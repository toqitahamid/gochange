import SwiftUI
import SwiftData
import Charts

struct PerformanceAnalyticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    
    @StateObject private var viewModel = AnalyticsViewModel()
    @State private var selectedSection: PerformanceSection = .strength
    @State private var showingPersonalRecords = false
    
    enum PerformanceSection: String, CaseIterable {
        case strength = "Strength"
        case cardio = "Cardio"
        case recovery = "Recovery"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Segmented Control
                    Picker("Section", selection: $selectedSection) {
                        ForEach(PerformanceSection.allCases, id: \.self) { section in
                            Text(section.rawValue).tag(section)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    
                    // MARK: - Hero Stats
                    heroStatsSection
                        .padding(.horizontal, 20)
                    
                    // MARK: - Section Content
                    switch selectedSection {
                    case .strength:
                        strengthSection
                    case .cardio:
                        cardioSection
                    case .recovery:
                        recoverySection
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 100)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("Performance")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await viewModel.refreshAllAnalytics()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
            .sheet(isPresented: $showingPersonalRecords) {
                PersonalRecordsSheet(records: viewModel.personalRecords)
            }
            .onAppear {
                viewModel.loadAnalytics(sessions: sessions)
            }
            .onChange(of: sessions.count) { _, _ in
                viewModel.loadAnalytics(sessions: sessions)
            }
        }
    }
    
    // MARK: - Hero Stats
    private var heroStatsSection: some View {
        HStack(spacing: 12) {
            StatPill(
                icon: "calendar.badge.clock",
                value: "\(viewModel.activeDays)",
                label: "Active Days",
                color: AppColors.primary
            )
            
            StatPill(
                icon: "figure.strengthtraining.traditional",
                value: "\(viewModel.totalExercises)",
                label: "Exercises",
                color: AppColors.warning
            )
            
            StatPill(
                icon: "number",
                value: formatNumber(viewModel.totalReps),
                label: "Total Reps",
                color: AppColors.success
            )
        }
    }
    
    // MARK: - Strength Section
    private var strengthSection: some View {
        VStack(spacing: 16) {
            // 1RM Trend Chart
            OneRepMaxTrendChart(
                data: viewModel.oneRepMaxData,
                exerciseName: viewModel.selectedExerciseForTrend,
                availableExercises: viewModel.availableExercisesForTrend
            ) { exercise in
                viewModel.selectedExerciseForTrend = exercise
            }
            .padding(.horizontal, 20)
            
            // Volume Trends
            VolumeTrendsChart(
                data: viewModel.volumeData,
                selectedPeriod: $viewModel.selectedTimePeriod
            )
            .onChange(of: viewModel.selectedTimePeriod) { _, newPeriod in
                viewModel.updateTimePeriod(newPeriod)
            }
            .padding(.horizontal, 20)
            
            // Muscle Balance (Radar or Heatmap)
            AnatomicalMuscleHeatmap(muscleData: muscleLoadData)
                .padding(.horizontal, 20)
            
            // Personal Records Button
            personalRecordsButton
                .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Cardio Section
    private var cardioSection: some View {
        VStack(spacing: 16) {
            // Heart Rate Zones
            HeartRateZoneChart(
                zone1Minutes: 5,
                zone2Minutes: 25,
                zone3Minutes: 15,
                zone4Minutes: 8,
                zone5Minutes: 2
            )
            .padding(.horizontal, 20)
            
            // Training Density
            TrainingDensityChart(data: densityData)
                .padding(.horizontal, 20)
            
            // Work Capacity
            WorkCapacityChart(data: workCapacityData)
                .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Recovery Section
    private var recoverySection: some View {
        VStack(spacing: 16) {
            // RPE Trends
            RPETrendChart(data: rpeData)
                .padding(.horizontal, 20)
            
            // Rest Period Analysis
            RestPeriodHistogram(restPeriods: restPeriodData)
                .padding(.horizontal, 20)
            
            // Body Composition
            BodyCompositionChart(
                weightData: weightData,
                bodyFatData: bodyFatData
            )
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Personal Records Button
    private var personalRecordsButton: some View {
        Button {
            showingPersonalRecords = true
        } label: {
            HStack {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "#FFD700"))
                
                Text("View Personal Records")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gray)
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Data Conversions
    private var muscleLoadData: [String: Double] {
        var result: [String: Double] = [:]
        let total = viewModel.muscleGroupData.map(\.volume).reduce(0, +)
        for group in viewModel.muscleGroupData {
            result[group.muscleGroup] = total > 0 ? group.volume / total : 0
        }
        return result
    }
    
    private var densityData: [TrainingDensityChart.DensityDataPoint] {
        // Convert volume data to density (volume / assumed duration)
        viewModel.volumeData.map { point in
            TrainingDensityChart.DensityDataPoint(
                date: point.date,
                density: point.volume / 60.0 // Assuming 60 min workouts
            )
        }
    }
    
    private var workCapacityData: [WorkCapacityChart.WorkCapacityPoint] {
        viewModel.volumeData.map { point in
            WorkCapacityChart.WorkCapacityPoint(date: point.date, totalWork: point.volume)
        }
    }
    
    private var rpeData: [RPETrendChart.RPEDataPoint] {
        // Mock data - would need to extract from session logs
        []
    }
    
    private var restPeriodData: [TimeInterval] {
        // Mock data - would need to extract from session logs
        [45, 60, 75, 90, 120, 60, 45, 30, 90, 60]
    }
    
    private var weightData: [BodyCompositionChart.WeightDataPoint] {
        // Would fetch from HealthKit
        []
    }
    
    private var bodyFatData: [BodyCompositionChart.BodyFatDataPoint] {
        // Would fetch from HealthKit
        []
    }
    
    private func formatNumber(_ value: Int) -> String {
        if value >= 1_000_000 { return String(format: "%.1fM", Double(value) / 1_000_000) }
        if value >= 1_000 { return String(format: "%.1fK", Double(value) / 1_000) }
        return "\(value)"
    }
}

// MARK: - Stat Pill Component
struct StatPill: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.08), lineWidth: 1)
        )
    }
}

#Preview {
    PerformanceAnalyticsView()
        .modelContainer(for: [WorkoutSession.self, WorkoutDay.self])
}
