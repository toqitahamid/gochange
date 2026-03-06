import SwiftUI
import SwiftData

struct WorkoutAnalyticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    
    @StateObject private var viewModel = AnalyticsViewModel()
    @State private var showingPersonalRecords = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#F5F5F7").ignoresSafeArea()
                
                if viewModel.loadState == .loading {
                    loadingView
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // 1. Heatmap (Top)
                            WorkoutFrequencyHeatmap(data: viewModel.frequencyData)
                                .padding(.horizontal, 20)
                            
                            // 2. Hero Stats
                            heroStatsSection
                                .padding(.horizontal, 20)
                            
                            // 3. Advanced Analytics (New Charts)
                            AdvancedAnalyticsView(viewModel: viewModel)
                                .padding(.horizontal, 20)
                            
                            // 4. Volume & Reps Trends (Existing)
                            VStack(spacing: 20) {
                                VolumeTrendsChart(
                                    data: viewModel.volumeData,
                                    selectedPeriod: $viewModel.selectedTimePeriod
                                )
                                .onChange(of: viewModel.selectedTimePeriod) { _, newPeriod in
                                    viewModel.updateTimePeriod(newPeriod)
                                }
                                
                                RepsTrendsChart(
                                    data: viewModel.repsData,
                                    selectedPeriod: $viewModel.selectedTimePeriod
                                )
                            }
                            .padding(.horizontal, 20)
                            
                            // 5. Top Exercises
                            TopExercisesView(exercises: viewModel.topExercises)
                                .padding(.horizontal, 20)
                            
                            // 6. Muscle Group Balance
                            MuscleGroupBalanceView(data: viewModel.muscleGroupData)
                                .padding(.horizontal, 20)
                            
                            // 7. Personal Records Button
                            personalRecordsButton
                                .padding(.horizontal, 20)
                        }
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
    
    // MARK: - Components
    
    private var heroStatsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                AnalyticsStatCard(
                    icon: "calendar.badge.clock",
                    value: "\(viewModel.activeDays)",
                    label: "Active Days",
                    color: Color(hex: "#00D4AA")
                )
                
                AnalyticsStatCard(
                    icon: "figure.strengthtraining.traditional",
                    value: "\(viewModel.totalExercises)",
                    label: "Exercises",
                    color: Color(hex: "#FF6B35")
                )
            }
            
            HStack(spacing: 12) {
                AnalyticsStatCard(
                    icon: "number",
                    value: formatReps(Double(viewModel.totalReps)),
                    label: "Total Reps",
                    color: Color(hex: "#FFD700")
                )
                
                AnalyticsStatCard(
                    icon: "flame.fill",
                    value: formatVolume(viewModel.volumeData.reduce(0) { $0 + $1.volume }),
                    label: "Volume",
                    color: Color(hex: "#4ECDC4")
                )
            }
        }
    }
    
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
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    colors: [Color(hex: "#FFD700").opacity(0.3), Color(hex: "#FFD700").opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(Color(hex: "#00D4AA"))
            
            Text("Analyzing your workouts...")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
    
    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1_000_000 {
            return String(format: "%.1fM", volume / 1_000_000)
        } else if volume >= 1_000 {
            return String(format: "%.1fK", volume / 1_000)
        } else {
            return String(format: "%.0f", volume)
        }
    }
    
    private func formatReps(_ reps: Double) -> String {
        if reps >= 1_000_000 {
            return String(format: "%.1fM", reps / 1_000_000)
        } else if reps >= 1_000 {
            return String(format: "%.1fK", reps / 1_000)
        } else {
            return String(format: "%.0f", reps)
        }
    }
}

// Helper Components (kept in same file for simplicity if not shared)

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
                    .foregroundColor(.primary)

                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct PersonalRecordsSheet: View {
    @Environment(\.dismiss) var dismiss
    let records: [PersonalRecord]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#F5F5F7").ignoresSafeArea()

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

struct PersonalRecordRow: View {
    let record: PersonalRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Exercise name
            Text(record.exerciseName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)

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
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

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
                    .foregroundColor(.primary)
            }

            Spacer()

            Text(date.formatted(as: "MMM d, yyyy"))
                .font(.system(size: 11))
                .foregroundColor(.gray)
        }
        .padding(10)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
}

#Preview {
    WorkoutAnalyticsView()
        .modelContainer(for: [WorkoutSession.self, WorkoutDay.self])
}
