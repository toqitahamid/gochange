import SwiftUI
import Charts

/// Chart displaying reps trends over time
struct RepsTrendsChart: View {
    let data: [RepsDataPoint]
    @Binding var selectedPeriod: TimePeriod

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reps Trends")
                        .font(.headline)
                        .foregroundColor(.white)

                    if let average = averageReps {
                        Text("Avg: \(formatReps(average))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }

                Spacer()
            }

            // Chart
            if data.isEmpty {
                emptyStateView
            } else {
                Chart(data) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Reps", point.reps)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "#FF6B35"), Color(hex: "#FF8E53")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Reps", point.reps)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(hex: "#FF6B35").opacity(0.3),
                                Color(hex: "#FF6B35").opacity(0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
                .frame(height: 220)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.white.opacity(0.1))
                        AxisValueLabel()
                            .foregroundStyle(.gray)
                            .font(.caption2)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.white.opacity(0.1))
                        AxisValueLabel {
                            if let reps = value.as(Int.self) {
                                Text("\(reps)")
                                    .foregroundStyle(.gray)
                                    .font(.caption2)
                            }
                        }
                    }
                }

                // Stats
                statsRow
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

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundColor(.gray)

            Text("No reps data yet")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(height: 220)
        .frame(maxWidth: .infinity)
    }

    private var statsRow: some View {
        HStack(spacing: 16) {
            StatItem(label: "Peak", value: formatReps(Double(peakReps ?? 0)), color: Color(hex: "#FF6B35"))
            StatItem(label: "Average", value: formatReps(averageReps ?? 0), color: Color(hex: "#00D4AA"))
            StatItem(label: "Total", value: formatReps(Double(totalReps)), color: Color(hex: "#FFD700"))
        }
        .padding(.top, 8)
    }

    // MARK: - Computed Properties

    private var totalReps: Int {
        data.reduce(0) { $0 + $1.reps }
    }

    private var averageReps: Double? {
        guard !data.isEmpty else { return nil }
        return Double(totalReps) / Double(data.count)
    }

    private var peakReps: Int? {
        data.map { $0.reps }.max()
    }

    // MARK: - Formatters

    private func formatReps(_ reps: Double) -> String {
        if reps >= 1_000 {
            return String(format: "%.1fK", reps / 1_000)
        } else {
            return String(format: "%.0f", reps)
        }
    }
}

#Preview {
    let sampleData = [
        RepsDataPoint(date: Date().addingTimeInterval(-6 * 24 * 3600), reps: 120),
        RepsDataPoint(date: Date().addingTimeInterval(-5 * 24 * 3600), reps: 140),
        RepsDataPoint(date: Date().addingTimeInterval(-4 * 24 * 3600), reps: 130),
        RepsDataPoint(date: Date().addingTimeInterval(-3 * 24 * 3600), reps: 150),
        RepsDataPoint(date: Date().addingTimeInterval(-2 * 24 * 3600), reps: 145),
        RepsDataPoint(date: Date().addingTimeInterval(-1 * 24 * 3600), reps: 160),
        RepsDataPoint(date: Date(), reps: 155)
    ]

    return RepsTrendsChart(data: sampleData, selectedPeriod: .constant(.week))
        .padding()
        .background(Color.black)
}
