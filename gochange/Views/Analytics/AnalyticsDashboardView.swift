import SwiftUI
import SwiftData

/// Advanced analytics dashboard with comprehensive workout insights
struct AnalyticsDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]

    @StateObject private var viewModel = AnalyticsViewModel()
    @State private var showingPersonalRecords = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color.black, Color(hex: "#0A1628")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                if viewModel.isLoading {
                    loadingView
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Hero stats
                            heroStatsSection

                            // Volume trends
                            VolumeTrendsChart(
                                data: viewModel.volumeData,
                                selectedPeriod: $viewModel.selectedTimePeriod
                            )
                            .onChange(of: viewModel.selectedTimePeriod) { _, newPeriod in
                                viewModel.updateTimePeriod(newPeriod)
                            }

                            // Workout frequency heatmap
                            WorkoutFrequencyHeatmap(data: viewModel.frequencyData)

                            // Muscle group balance
                            MuscleGroupBalanceView(data: viewModel.muscleGroupData)

                            // Progress summaries
                            ProgressSummariesView(
                                monthlyProgress: viewModel.monthlyProgress,
                                yearlyProgress: viewModel.yearlyProgress
                            )

                            // Personal Records button
                            personalRecordsButton
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await viewModel.refreshAllAnalytics()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(Color(hex: "#00D4AA"))
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

    // MARK: - Hero Stats Section

    private var heroStatsSection: some View {
        VStack(spacing: 12) {
            // Top row
            HStack(spacing: 12) {
                AnalyticsStatCard(
                    icon: "chart.bar.fill",
                    value: "\(viewModel.totalWorkouts)",
                    label: "Total Workouts",
                    color: Color(hex: "#00D4AA")
                )

                AnalyticsStatCard(
                    icon: "flame.fill",
                    value: formatVolume(viewModel.totalVolume),
                    label: "Total Volume",
                    color: Color(hex: "#FF6B35")
                )
            }

            // Bottom row
            HStack(spacing: 12) {
                AnalyticsStatCard(
                    icon: "clock.fill",
                    value: formatDuration(viewModel.averageWorkoutDuration),
                    label: "Avg Duration",
                    color: Color(hex: "#FFD700")
                )

                AnalyticsStatCard(
                    icon: "calendar",
                    value: "\(viewModel.workoutsThisMonth)",
                    label: "This Month",
                    color: Color(hex: "#4ECDC4")
                )
            }
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
                    .foregroundColor(.white)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gray)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [Color(hex: "#FFD700").opacity(0.3), Color(hex: "#FFD700").opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(Color(hex: "#00D4AA"))

            Text("Analyzing your workouts...")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }

    // MARK: - Formatters

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1_000_000 {
            return String(format: "%.1fM", volume / 1_000_000)
        } else if volume >= 1_000 {
            return String(format: "%.1fK", volume / 1_000)
        } else {
            return String(format: "%.0f", volume)
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        return "\(minutes) min"
    }
}

// MARK: - Analytics Stat Card

struct AnalyticsStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
            }

            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Personal Records Sheet

struct PersonalRecordsSheet: View {
    @Environment(\.dismiss) var dismiss
    let records: [PersonalRecord]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if records.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "trophy")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)

                        Text("No personal records yet")
                            .font(.headline)
                            .foregroundColor(.gray)

                        Text("Complete workouts to set your first records")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(records) { record in
                                PersonalRecordRow(record: record)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Personal Records")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "#00D4AA"))
                }
            }
        }
    }
}

// MARK: - Personal Record Row

struct PersonalRecordRow: View {
    let record: PersonalRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Exercise name
            Text(record.exerciseName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)

            // Records
            VStack(spacing: 8) {
                RecordItem(
                    icon: "scalemass.fill",
                    label: "Max Weight",
                    value: "\(Int(record.maxWeight)) lbs",
                    date: record.maxWeightDate,
                    color: Color(hex: "#FF6B35")
                )

                RecordItem(
                    icon: "number",
                    label: "Max Reps",
                    value: "\(record.maxReps) reps",
                    date: record.maxRepsDate,
                    color: Color(hex: "#00D4AA")
                )

                RecordItem(
                    icon: "chart.bar.fill",
                    label: "Max Volume",
                    value: "\(Int(record.maxVolume)) lbs",
                    date: record.maxVolumeDate,
                    color: Color(hex: "#FFD700")
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Record Item

struct RecordItem: View {
    let icon: String
    let label: String
    let value: String
    let date: Date
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(color)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(.gray)

                Text(value)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }

            Spacer()

            Text(date.formatted(as: "MMM d, yyyy"))
                .font(.system(size: 11))
                .foregroundColor(.gray)
        }
        .padding(10)
        .background(Color.white.opacity(0.03))
        .cornerRadius(10)
    }
}

#Preview {
    AnalyticsDashboardView()
        .modelContainer(for: [WorkoutSession.self, WorkoutDay.self])
}
