import SwiftUI
import SwiftData
import Charts

struct ExerciseMiniChart: View {
    let exerciseId: UUID
    let accentColor: Color
    @Environment(\.modelContext) private var modelContext

    @State private var historyData: [ExerciseHistoryPoint] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("MAX WEIGHT TREND")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1.5)
                        .foregroundColor(.secondary.opacity(0.8))
                    
                    if let latest = historyData.last {
                        Text("\(Int(latest.maxWeight)) lbs")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                }

                Spacer()

                if let latest = historyData.last, let previous = historyData.dropLast().last {
                    let change = latest.maxWeight - previous.maxWeight
                    if change != 0 {
                        HStack(spacing: 3) {
                            Image(systemName: change > 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.system(size: 10, weight: .bold))
                            Text("\(change > 0 ? "+" : "")\(Int(change))")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(change > 0 ? Color(hex: "#00D4AA").opacity(0.1) : Color(hex: "#FF6B6B").opacity(0.1))
                        )
                        .foregroundColor(change > 0 ? Color(hex: "#00D4AA") : Color(hex: "#FF6B6B"))
                    }
                }
            }

            if historyData.isEmpty {
                emptyStateView
            } else {
                chartView
            }
        }
        .padding(AppLayout.cardPadding)
        .subCardStyle()
        .onAppear {
            fetchHistory()
        }
    }

    private var emptyStateView: some View {
        HStack {
            Spacer()
            VStack(spacing: 6) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary.opacity(0.5))
                Text("No history yet")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .frame(height: 60)
            Spacer()
        }
    }

    private var chartView: some View {
        Chart(historyData) { point in
            LineMark(
                x: .value("Workout", point.workoutNumber),
                y: .value("Weight", point.maxWeight)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [accentColor, accentColor.opacity(0.7)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .interpolationMethod(.catmullRom)
            .lineStyle(StrokeStyle(lineWidth: 2))

            AreaMark(
                x: .value("Workout", point.workoutNumber),
                y: .value("Weight", point.maxWeight)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [accentColor.opacity(0.2), accentColor.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)

            PointMark(
                x: .value("Workout", point.workoutNumber),
                y: .value("Weight", point.maxWeight)
            )
            .foregroundStyle(accentColor)
            .symbolSize(30)
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(height: 60)
    }

    private func fetchHistory() {
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate<WorkoutSession> { session in
                session.isCompleted
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        guard let sessions = try? modelContext.fetch(descriptor) else { return }

        // Get last 5 sessions that contain this exercise
        let relevantSessions = sessions
            .filter { session in
                session.exerciseLogs.contains { $0.exerciseId == exerciseId }
            }
            .prefix(5)
            .reversed()

        historyData = relevantSessions.enumerated().compactMap { index, session in
            guard let exerciseLog = session.exerciseLogs.first(where: { $0.exerciseId == exerciseId }) else {
                return nil
            }

            // Find max weight from completed sets
            let maxWeight = exerciseLog.sets
                .filter { $0.isCompleted }
                .compactMap { $0.weight }
                .max() ?? 0

            guard maxWeight > 0 else { return nil }

            return ExerciseHistoryPoint(
                workoutNumber: index + 1,
                maxWeight: maxWeight,
                date: session.date
            )
        }
    }
}

// MARK: - Data Model
struct ExerciseHistoryPoint: Identifiable {
    let id = UUID()
    let workoutNumber: Int
    let maxWeight: Double
    let date: Date
}
