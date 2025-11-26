import SwiftUI
import Charts

/// View showing muscle group volume distribution and balance
struct MuscleGroupBalanceView: View {
    let data: [MuscleGroupVolume]

    @State private var selectedView: ChartView = .bar

    enum ChartView: String, CaseIterable {
        case bar = "Bar"
        case pie = "Pie"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Muscle Group Balance")
                        .font(.headline)
                        .foregroundColor(.white)

                    if !data.isEmpty {
                        Text("Volume distribution")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }

                Spacer()

                // View selector
                Picker("View", selection: $selectedView) {
                    ForEach(ChartView.allCases, id: \.self) { view in
                        Text(view.rawValue).tag(view)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 140)
            }

            // Chart
            if data.isEmpty {
                emptyStateView
            } else {
                if selectedView == .bar {
                    barChartView
                } else {
                    pieChartView
                }

                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.vertical, 4)

                // Stats
                balanceStats
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

    // MARK: - Bar Chart

    private var barChartView: some View {
        VStack(spacing: 12) {
            Chart(data) { item in
                BarMark(
                    x: .value("Volume", item.volume),
                    y: .value("Muscle Group", item.muscleGroup)
                )
                .foregroundStyle(colorForMuscleGroup(item.muscleGroup))
                .cornerRadius(4)
            }
            .frame(height: CGFloat(data.count * 35 + 40))
            .chartXAxis {
                AxisMarks(position: .bottom) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.white.opacity(0.1))
                    AxisValueLabel()
                        .foregroundStyle(.gray)
                        .font(.caption2)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel()
                        .foregroundStyle(.white)
                        .font(.caption)
                }
            }
        }
    }

    // MARK: - Pie Chart

    private var pieChartView: some View {
        VStack(spacing: 16) {
            Chart(data) { item in
                SectorMark(
                    angle: .value("Volume", item.volume),
                    innerRadius: .ratio(0.5),
                    angularInset: 1.5
                )
                .foregroundStyle(colorForMuscleGroup(item.muscleGroup))
            }
            .frame(height: 220)

            // Legend
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(data) { item in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(colorForMuscleGroup(item.muscleGroup))
                            .frame(width: 8, height: 8)

                        Text(item.muscleGroup)
                            .font(.system(size: 11))
                            .foregroundColor(.white)

                        Spacer()

                        Text(String(format: "%.1f%%", item.percentage))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 40))
                .foregroundColor(.gray)

            Text("No muscle group data")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(height: 220)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Balance Stats

    private var balanceStats: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Balance Analysis")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Spacer()
            }

            if let mostTrained = data.first, let leastTrained = data.last {
                VStack(spacing: 8) {
                    BalanceStatRow(
                        label: "Most Trained",
                        muscleGroup: mostTrained.muscleGroup,
                        percentage: mostTrained.percentage,
                        color: Color(hex: "#00D4AA")
                    )

                    BalanceStatRow(
                        label: "Least Trained",
                        muscleGroup: leastTrained.muscleGroup,
                        percentage: leastTrained.percentage,
                        color: Color(hex: "#FF6B35")
                    )

                    // Balance indicator
                    balanceIndicator
                }
            }
        }
    }

    private var balanceIndicator: some View {
        HStack(spacing: 8) {
            Image(systemName: balanceIconName)
                .font(.system(size: 12))
                .foregroundColor(balanceColor)

            Text(balanceText)
                .font(.system(size: 12))
                .foregroundColor(.gray)

            Spacer()
        }
        .padding(10)
        .background(balanceColor.opacity(0.1))
        .cornerRadius(8)
    }

    // MARK: - Computed Properties

    private var balanceScore: Double {
        guard data.count >= 2 else { return 1.0 }
        let percentages = data.map { $0.percentage }
        let highest = percentages.max() ?? 0
        let lowest = percentages.min() ?? 0
        guard highest > 0 else { return 1.0 }
        return lowest / highest
    }

    private var balanceIconName: String {
        if balanceScore >= 0.7 {
            return "checkmark.circle.fill"
        } else if balanceScore >= 0.4 {
            return "exclamationmark.triangle.fill"
        } else {
            return "xmark.circle.fill"
        }
    }

    private var balanceColor: Color {
        if balanceScore >= 0.7 {
            return Color(hex: "#00D4AA")
        } else if balanceScore >= 0.4 {
            return Color(hex: "#FFD700")
        } else {
            return Color(hex: "#FF6B35")
        }
    }

    private var balanceText: String {
        if balanceScore >= 0.7 {
            return "Well balanced muscle group training"
        } else if balanceScore >= 0.4 {
            return "Moderate imbalance - consider balancing workouts"
        } else {
            return "Significant imbalance detected - focus on weaker groups"
        }
    }

    // MARK: - Helper Methods

    private func colorForMuscleGroup(_ muscleGroup: String) -> Color {
        switch muscleGroup {
        case "Chest": return Color(hex: "#FF6B35")
        case "Back": return Color(hex: "#00D4AA")
        case "Shoulders": return Color(hex: "#FFD700")
        case "Biceps": return Color(hex: "#4ECDC4")
        case "Triceps": return Color(hex: "#95E1D3")
        case "Quadriceps": return Color(hex: "#F38181")
        case "Hamstrings": return Color(hex: "#AA96DA")
        case "Calves": return Color(hex: "#FCBAD3")
        case "Glutes": return Color(hex: "#FFFFD2")
        case "Core": return Color(hex: "#A8E6CF")
        default: return Color.gray
        }
    }
}

// MARK: - Balance Stat Row

struct BalanceStatRow: View {
    let label: String
    let muscleGroup: String
    let percentage: Double
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(.gray)

                Text(muscleGroup)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
            }

            Spacer()

            Text(String(format: "%.1f%%", percentage))
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(color.opacity(0.15))
                .cornerRadius(6)
        }
        .padding(10)
        .background(Color.white.opacity(0.03))
        .cornerRadius(10)
    }
}

#Preview {
    let sampleData = [
        MuscleGroupVolume(muscleGroup: "Chest", volume: 45000),
        MuscleGroupVolume(muscleGroup: "Back", volume: 42000),
        MuscleGroupVolume(muscleGroup: "Quadriceps", volume: 38000),
        MuscleGroupVolume(muscleGroup: "Shoulders", volume: 35000),
        MuscleGroupVolume(muscleGroup: "Hamstrings", volume: 28000),
        MuscleGroupVolume(muscleGroup: "Triceps", volume: 25000),
        MuscleGroupVolume(muscleGroup: "Biceps", volume: 22000),
        MuscleGroupVolume(muscleGroup: "Core", volume: 18000)
    ].map { group in
        var updated = group
        updated.percentage = (group.volume / 253000) * 100
        return updated
    }

    return MuscleGroupBalanceView(data: sampleData)
        .padding()
        .background(Color.black)
}
