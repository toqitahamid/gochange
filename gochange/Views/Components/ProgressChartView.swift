import SwiftUI
import Charts

/// A chart view showing exercise progress over time
struct ProgressChartView: View {
    let exerciseName: String
    let dataPoints: [ProgressDataPoint]
    
    @State private var selectedMetric: ProgressMetric = .weight
    
    enum ProgressMetric: String, CaseIterable {
        case weight = "Weight"
        case volume = "Volume"
        case reps = "Reps"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Progress")
                    .font(.headline)
                
                Spacer()
                
                Picker("Metric", selection: $selectedMetric) {
                    ForEach(ProgressMetric.allCases, id: \.self) { metric in
                        Text(metric.rawValue).tag(metric)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            
            // Chart
            if dataPoints.isEmpty {
                emptyChartView
            } else {
                Chart(dataPoints) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value(selectedMetric.rawValue, value(for: point))
                    )
                    .foregroundStyle(AppTheme.accent)
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value(selectedMetric.rawValue, value(for: point))
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppTheme.accent.opacity(0.3), AppTheme.accent.opacity(0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value(selectedMetric.rawValue, value(for: point))
                    )
                    .foregroundStyle(AppTheme.accent)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { value in
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            }
            
            // Stats Summary
            if !dataPoints.isEmpty {
                statsSummary
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
    
    private var emptyChartView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("No data yet")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }
    
    private var statsSummary: some View {
        HStack(spacing: 16) {
            StatSummaryItem(
                title: "Average",
                value: String(format: "%.1f", average)
            )
            
            StatSummaryItem(
                title: "Peak",
                value: String(format: "%.1f", peak)
            )
            
            StatSummaryItem(
                title: "Change",
                value: changeString,
                color: changeColor
            )
        }
    }
    
    // MARK: - Computed Properties
    
    private func value(for point: ProgressDataPoint) -> Double {
        switch selectedMetric {
        case .weight: return point.maxWeight
        case .volume: return point.totalVolume
        case .reps: return Double(point.totalReps)
        }
    }
    
    private var average: Double {
        guard !dataPoints.isEmpty else { return 0 }
        return dataPoints.map { value(for: $0) }.reduce(0, +) / Double(dataPoints.count)
    }
    
    private var peak: Double {
        dataPoints.map { value(for: $0) }.max() ?? 0
    }
    
    private var change: Double {
        guard dataPoints.count >= 2 else { return 0 }
        let first = value(for: dataPoints.first!)
        let last = value(for: dataPoints.last!)
        guard first > 0 else { return 0 }
        return ((last - first) / first) * 100
    }
    
    private var changeString: String {
        let symbol = change >= 0 ? "+" : ""
        return "\(symbol)\(String(format: "%.1f", change))%"
    }
    
    private var changeColor: Color {
        change >= 0 ? .green : .red
    }
}

// MARK: - Data Point
struct ProgressDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let maxWeight: Double
    let totalVolume: Double
    let totalReps: Int
}

// MARK: - Stat Summary Item
struct StatSummaryItem: View {
    let title: String
    let value: String
    var color: Color = .primary
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    let sampleData = [
        ProgressDataPoint(date: Date().daysAgo(30), maxWeight: 135, totalVolume: 4050, totalReps: 30),
        ProgressDataPoint(date: Date().daysAgo(23), maxWeight: 140, totalVolume: 4200, totalReps: 30),
        ProgressDataPoint(date: Date().daysAgo(16), maxWeight: 145, totalVolume: 4350, totalReps: 30),
        ProgressDataPoint(date: Date().daysAgo(9), maxWeight: 145, totalVolume: 4640, totalReps: 32),
        ProgressDataPoint(date: Date().daysAgo(2), maxWeight: 150, totalVolume: 5100, totalReps: 34)
    ]
    
    return ProgressChartView(exerciseName: "Bench Press", dataPoints: sampleData)
        .padding()
}

