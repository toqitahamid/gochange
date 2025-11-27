import SwiftUI
import Charts

/// Chart displaying volume trends over time
struct VolumeTrendsChart: View {
    let data: [VolumeDataPoint]
    @Binding var selectedPeriod: TimePeriod

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Volume Trends")
                        .font(.headline)
                        .foregroundColor(.primary)

                    if let average = averageVolume {
                        Text("Avg: \(formatVolume(average))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Period selector
                Menu {
                    ForEach([TimePeriod.week, .month, .threeMonths, .sixMonths, .year, .allTime], id: \.displayName) { period in
                        Button(period.displayName) {
                            selectedPeriod = period
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedPeriod.displayName)
                            .font(.caption)
                            .foregroundColor(Color(hex: "#00D4AA"))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: "#00D4AA"))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: "#00D4AA").opacity(0.15))
                    .cornerRadius(8)
                }
            }

            // Chart
            if data.isEmpty {
                emptyStateView
            } else {
                Chart(data) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Volume", point.volume)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "#00D4AA"), Color(hex: "#00B894")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Volume", point.volume)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(hex: "#00D4AA").opacity(0.3),
                                Color(hex: "#00D4AA").opacity(0)
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
                            .foregroundStyle(Color.gray.opacity(0.2))
                        AxisValueLabel()
                            .foregroundStyle(.gray)
                            .font(.caption2)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.gray.opacity(0.2))
                        AxisValueLabel {
                            if let volume = value.as(Double.self) {
                                Text(formatVolumeShort(volume))
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
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundColor(.gray)

            Text("No volume data yet")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(height: 220)
        .frame(maxWidth: .infinity)
    }

    private var statsRow: some View {
        HStack(spacing: 16) {
            StatItem(label: "Peak", value: formatVolume(peakVolume ?? 0), color: Color(hex: "#FF6B35"))
            StatItem(label: "Average", value: formatVolume(averageVolume ?? 0), color: Color(hex: "#00D4AA"))
            StatItem(label: "Total", value: formatVolume(totalVolume), color: Color(hex: "#FFD700"))
        }
        .padding(.top, 8)
    }

    // MARK: - Computed Properties

    private var totalVolume: Double {
        data.reduce(0) { $0 + $1.volume }
    }

    private var averageVolume: Double? {
        guard !data.isEmpty else { return nil }
        return totalVolume / Double(data.count)
    }

    private var peakVolume: Double? {
        data.map { $0.volume }.max()
    }

    // MARK: - Formatters

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1_000_000 {
            return String(format: "%.1fM lbs", volume / 1_000_000)
        } else if volume >= 1_000 {
            return String(format: "%.1fK lbs", volume / 1_000)
        } else {
            return String(format: "%.0f lbs", volume)
        }
    }

    private func formatVolumeShort(_ volume: Double) -> String {
        if volume >= 1_000_000 {
            return String(format: "%.1fM", volume / 1_000_000)
        } else if volume >= 1_000 {
            return String(format: "%.0fK", volume / 1_000)
        } else {
            return String(format: "%.0f", volume)
        }
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(color)

            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    let sampleData = [
        VolumeDataPoint(date: Date().addingTimeInterval(-6 * 24 * 3600), volume: 12500),
        VolumeDataPoint(date: Date().addingTimeInterval(-5 * 24 * 3600), volume: 14200),
        VolumeDataPoint(date: Date().addingTimeInterval(-4 * 24 * 3600), volume: 13800),
        VolumeDataPoint(date: Date().addingTimeInterval(-3 * 24 * 3600), volume: 15100),
        VolumeDataPoint(date: Date().addingTimeInterval(-2 * 24 * 3600), volume: 14500),
        VolumeDataPoint(date: Date().addingTimeInterval(-1 * 24 * 3600), volume: 16000),
        VolumeDataPoint(date: Date(), volume: 15500)
    ]

    return VolumeTrendsChart(data: sampleData, selectedPeriod: .constant(.week))
        .padding()
        .background(Color.black)
}
