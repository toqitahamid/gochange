import SwiftUI
import Charts

/// View showing monthly and yearly progress summaries
struct ProgressSummariesView: View {
    let monthlyProgress: [MonthlyProgress]
    let yearlyProgress: [YearlyProgress]

    @State private var selectedView: SummaryView = .monthly

    enum SummaryView: String, CaseIterable {
        case monthly = "Monthly"
        case yearly = "Yearly"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Progress Summary")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                // View selector
                Picker("View", selection: $selectedView) {
                    ForEach(SummaryView.allCases, id: \.self) { view in
                        Text(view.rawValue).tag(view)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }

            // Content
            if selectedView == .monthly {
                monthlyView
            } else {
                yearlyView
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    // MARK: - Monthly View

    private var monthlyView: some View {
        VStack(spacing: 12) {
            if monthlyProgress.isEmpty {
                emptyStateView(message: "No monthly data yet")
            } else {
                // Chart
                monthlyChart

                Divider()
                    .background(Color.white.opacity(0.1))

                // List
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(monthlyProgress.prefix(6)) { progress in
                            MonthlyProgressRow(progress: progress)
                        }
                    }
                }
                .frame(maxHeight: 300)
            }
        }
    }

    private var monthlyChart: some View {
        Chart(monthlyProgress.prefix(12)) { progress in
            BarMark(
                x: .value("Month", String(progress.monthName.prefix(3))),
                y: .value("Workouts", progress.workoutCount)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [Color(hex: "#00D4AA"), Color(hex: "#00B894")],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(4)
        }
        .frame(height: 150)
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel()
                    .foregroundStyle(.gray)
                    .font(.caption2)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.white.opacity(0.1))
                AxisValueLabel()
                    .foregroundStyle(.gray)
                    .font(.caption2)
            }
        }
    }

    // MARK: - Yearly View

    private var yearlyView: some View {
        VStack(spacing: 12) {
            if yearlyProgress.isEmpty {
                emptyStateView(message: "No yearly data yet")
            } else {
                // Chart
                yearlyChart

                Divider()
                    .background(Color.white.opacity(0.1))

                // List
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(yearlyProgress.prefix(5)) { progress in
                            YearlyProgressRow(progress: progress)
                        }
                    }
                }
                .frame(maxHeight: 300)
            }
        }
    }

    private var yearlyChart: some View {
        Chart(yearlyProgress) { progress in
            BarMark(
                x: .value("Year", String(progress.year)),
                y: .value("Workouts", progress.workoutCount)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [Color(hex: "#FF6B35"), Color(hex: "#F7931E")],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(4)
        }
        .frame(height: 150)
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel()
                    .foregroundStyle(.gray)
                    .font(.caption2)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.white.opacity(0.1))
                AxisValueLabel()
                    .foregroundStyle(.gray)
                    .font(.caption2)
            }
        }
    }

    // MARK: - Empty State

    private func emptyStateView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar")
                .font(.system(size: 40))
                .foregroundColor(.gray)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Monthly Progress Row

struct MonthlyProgressRow: View {
    let progress: MonthlyProgress

    var body: some View {
        HStack(spacing: 12) {
            // Date
            VStack(alignment: .leading, spacing: 2) {
                Text(progress.monthName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text(String(progress.year))
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
            .frame(width: 80, alignment: .leading)

            Spacer()

            // Stats
            HStack(spacing: 16) {
                StatBadge(
                    icon: "dumbbell.fill",
                    value: "\(progress.workoutCount)",
                    color: Color(hex: "#00D4AA")
                )

                StatBadge(
                    icon: "chart.bar.fill",
                    value: formatVolume(progress.totalVolume),
                    color: Color(hex: "#FF6B35")
                )

                StatBadge(
                    icon: "clock.fill",
                    value: formatDuration(progress.averageDuration),
                    color: Color(hex: "#FFD700")
                )
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
        )
    }

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1_000_000 {
            return String(format: "%.1fM", volume / 1_000_000)
        } else if volume >= 1_000 {
            return String(format: "%.0fK", volume / 1_000)
        } else {
            return String(format: "%.0f", volume)
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        return "\(minutes)m"
    }
}

// MARK: - Yearly Progress Row

struct YearlyProgressRow: View {
    let progress: YearlyProgress

    var body: some View {
        HStack(spacing: 12) {
            // Year
            Text(String(progress.year))
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 60, alignment: .leading)

            Spacer()

            // Stats
            HStack(spacing: 16) {
                StatBadge(
                    icon: "dumbbell.fill",
                    value: "\(progress.workoutCount)",
                    color: Color(hex: "#00D4AA")
                )

                StatBadge(
                    icon: "chart.bar.fill",
                    value: formatVolume(progress.totalVolume),
                    color: Color(hex: "#FF6B35")
                )

                StatBadge(
                    icon: "clock.fill",
                    value: formatDuration(progress.averageDuration),
                    color: Color(hex: "#FFD700")
                )
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
        )
    }

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1_000_000 {
            return String(format: "%.1fM", volume / 1_000_000)
        } else if volume >= 1_000 {
            return String(format: "%.0fK", volume / 1_000)
        } else {
            return String(format: "%.0f", volume)
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        return "\(minutes)m"
    }
}

// MARK: - Stat Badge

struct StatBadge: View {
    let icon: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .cornerRadius(6)
    }
}

#Preview {
    let sampleMonthly = [
        MonthlyProgress(year: 2025, month: 11, workoutCount: 16, totalVolume: 245000, totalDuration: 28800, averageDuration: 1800),
        MonthlyProgress(year: 2025, month: 10, workoutCount: 14, totalVolume: 220000, totalDuration: 25200, averageDuration: 1800),
        MonthlyProgress(year: 2025, month: 9, workoutCount: 12, totalVolume: 198000, totalDuration: 21600, averageDuration: 1800)
    ]

    let sampleYearly = [
        YearlyProgress(year: 2025, workoutCount: 156, totalVolume: 2450000, totalDuration: 280800, averageDuration: 1800),
        YearlyProgress(year: 2024, workoutCount: 142, totalVolume: 2200000, totalDuration: 255600, averageDuration: 1800)
    ]

    return ProgressSummariesView(monthlyProgress: sampleMonthly, yearlyProgress: sampleYearly)
        .padding()
        .background(Color.black)
}
