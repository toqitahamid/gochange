import SwiftUI

/// Heatmap showing workout frequency over time
struct WorkoutFrequencyHeatmap: View {
    let data: [WorkoutFrequencyPoint]

    private let columns = 7 // Days of week
    private let cellSize: CGFloat = 12
    private let spacing: CGFloat = 4

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Activity Heatmap")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("Last 90 days")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                // Legend
                heatmapLegend
            }

            // Heatmap grid
            if data.isEmpty {
                emptyStateView
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    // Day labels
                    dayLabels

                    // Grid
                    heatmapGrid
                }
            }

            // Stats
            statsRow
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

    private var dayLabels: some View {
        HStack(spacing: spacing) {
            Text("")
                .frame(width: 20)

            ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                Text(day)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gray)
                    .frame(width: cellSize)
            }
        }
    }

    private var heatmapGrid: some View {
        let rows = calculateRows()

        return VStack(alignment: .leading, spacing: spacing) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: spacing) {
                    // Week number or month label
                    if row == 0 || shouldShowMonthLabel(row: row) {
                        Text(getMonthLabel(row: row))
                            .font(.system(size: 9))
                            .foregroundColor(.gray)
                            .frame(width: 20, alignment: .trailing)
                    } else {
                        Text("")
                            .frame(width: 20)
                    }

                    ForEach(0..<columns, id: \.self) { col in
                        let index = row * columns + col
                        if index < data.count {
                            heatmapCell(for: data[index])
                        } else {
                            Color.clear
                                .frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
        }
    }

    private func heatmapCell(for point: WorkoutFrequencyPoint) -> some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(cellColor(for: point))
            .frame(width: cellSize, height: cellSize)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            )
    }

    private func cellColor(for point: WorkoutFrequencyPoint) -> Color {
        let baseColor = Color(hex: "#00D4AA")
        switch point.workoutCount {
        case 0:
            return Color.white.opacity(0.05)
        case 1:
            return baseColor.opacity(0.3)
        case 2:
            return baseColor.opacity(0.6)
        default:
            return baseColor
        }
    }

    private var heatmapLegend: some View {
        HStack(spacing: 4) {
            Text("Less")
                .font(.system(size: 9))
                .foregroundColor(.gray)

            ForEach(0..<4, id: \.self) { level in
                RoundedRectangle(cornerRadius: 2)
                    .fill(legendColor(level: level))
                    .frame(width: 10, height: 10)
            }

            Text("More")
                .font(.system(size: 9))
                .foregroundColor(.gray)
        }
    }

    private func legendColor(level: Int) -> Color {
        let baseColor = Color(hex: "#00D4AA")
        switch level {
        case 0: return Color.white.opacity(0.05)
        case 1: return baseColor.opacity(0.3)
        case 2: return baseColor.opacity(0.6)
        default: return baseColor
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar")
                .font(.system(size: 40))
                .foregroundColor(.gray)

            Text("No activity data")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(height: 150)
        .frame(maxWidth: .infinity)
    }

    private var statsRow: some View {
        HStack(spacing: 16) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color(hex: "#00D4AA"))
                    .frame(width: 8, height: 8)
                Text("\(activeDays) active days")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            HStack(spacing: 8) {
                Circle()
                    .fill(Color(hex: "#FF6B35"))
                    .frame(width: 8, height: 8)
                Text("\(currentStreak) day streak")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding(.top, 8)
    }

    // MARK: - Computed Properties

    private var activeDays: Int {
        data.filter { $0.workoutCount > 0 }.count
    }

    private var currentStreak: Int {
        var streak = 0
        let sortedData = data.sorted { $0.date > $1.date }

        for point in sortedData {
            if point.workoutCount > 0 {
                streak += 1
            } else if point.date < Date() {
                // Only break streak for past days with 0 workouts
                break
            }
        }

        return streak
    }

    private func calculateRows() -> Int {
        let totalCells = data.count
        return (totalCells + columns - 1) / columns
    }

    private func shouldShowMonthLabel(row: Int) -> Bool {
        guard row > 0, row * columns < data.count else { return false }
        let currentDate = data[row * columns].date
        let previousDate = data[(row - 1) * columns].date

        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: currentDate)
        let previousMonth = calendar.component(.month, from: previousDate)

        return currentMonth != previousMonth
    }

    private func getMonthLabel(row: Int) -> String {
        guard row * columns < data.count else { return "" }
        let date = data[row * columns].date
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }
}

#Preview {
    let calendar = Calendar.current
    let today = Date()
    var sampleData: [WorkoutFrequencyPoint] = []

    // Generate 90 days of sample data
    for i in 0..<90 {
        let date = calendar.date(byAdding: .day, value: -i, to: today)!
        let count = Int.random(in: 0...2)
        let intensity = count > 0 ? Double(count) / 2.0 : 0
        sampleData.append(WorkoutFrequencyPoint(date: date, workoutCount: count, intensity: intensity))
    }

    return WorkoutFrequencyHeatmap(data: sampleData.reversed())
        .padding()
        .background(Color.black)
}
