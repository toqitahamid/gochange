import SwiftUI
import Charts

// MARK: - 1RM Trend Chart (Scrubbable Line Chart)
struct OneRepMaxTrendChart: View {
    let data: [OneRepMaxDataPoint]
    let exerciseName: String
    let availableExercises: [String]
    var onExerciseChange: ((String) -> Void)? = nil
    
    @State private var selectedPoint: OneRepMaxDataPoint?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with Exercise Picker
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(AppColors.primary)
                
                Text("Estimated 1RM")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Menu {
                    ForEach(availableExercises, id: \.self) { exercise in
                        Button {
                            onExerciseChange?(exercise)
                        } label: {
                            HStack {
                                Text(exercise)
                                if exercise == exerciseName {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(exerciseName)
                            .font(.caption)
                            .foregroundColor(.primary)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            if data.isEmpty {
                Text("No data available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 180)
            } else {
                // Selected Value Display
                if let selected = selectedPoint {
                    HStack {
                        Text("\(Int(selected.estimated1RM)) lbs")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                        
                        Spacer()
                        
                        Text(selected.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else if let last = data.last {
                    HStack {
                        Text("\(Int(last.estimated1RM)) lbs")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                        
                        // Trend indicator
                        if data.count > 1 {
                            let previous = data[data.count - 2].estimated1RM
                            let change = last.estimated1RM - previous
                            let percentage = previous > 0 ? (change / previous * 100) : 0
                            
                            HStack(spacing: 2) {
                                Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                                Text(String(format: "%.1f%%", abs(percentage)))
                            }
                            .font(.caption)
                            .foregroundColor(change >= 0 ? AppColors.success : AppColors.error)
                        }
                        
                        Spacer()
                    }
                }
                
                // Chart
                Chart {
                    ForEach(data, id: \.date) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("1RM", point.estimated1RM)
                        )
                        .foregroundStyle(AppColors.primary)
                        .interpolationMethod(.catmullRom)
                        
                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("1RM", point.estimated1RM)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppColors.primary.opacity(0.3), AppColors.primary.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                        
                        if let selected = selectedPoint, point.date == selected.date {
                            PointMark(
                                x: .value("Date", point.date),
                                y: .value("1RM", point.estimated1RM)
                            )
                            .foregroundStyle(AppColors.primary)
                            .symbolSize(100)
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        Rectangle()
                            .fill(.clear)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let x = value.location.x
                                        if let date: Date = proxy.value(atX: x) {
                                            selectedPoint = data.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })
                                        }
                                    }
                                    .onEnded { _ in
                                        selectedPoint = nil
                                    }
                            )
                    }
                }
                .frame(height: 180)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Heart Rate Zone Chart
struct HeartRateZoneChart: View {
    let zone1Minutes: Double // Recovery (50-60%)
    let zone2Minutes: Double // Aerobic (60-70%)
    let zone3Minutes: Double // Tempo (70-80%)
    let zone4Minutes: Double // Threshold (80-90%)
    let zone5Minutes: Double // Anaerobic (90-100%)
    
    private var totalMinutes: Double {
        zone1Minutes + zone2Minutes + zone3Minutes + zone4Minutes + zone5Minutes
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(Color(hex: "#FF6B6B"))
                
                Text("Heart Rate Zones")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(totalMinutes)) min total")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Stacked Horizontal Bar
            GeometryReader { geometry in
                HStack(spacing: 1) {
                    zoneSegment(width: geometry.size.width * (zone1Minutes / max(totalMinutes, 1)), color: Color.gray.opacity(0.3))
                    zoneSegment(width: geometry.size.width * (zone2Minutes / max(totalMinutes, 1)), color: AppColors.primary)
                    zoneSegment(width: geometry.size.width * (zone3Minutes / max(totalMinutes, 1)), color: AppColors.success)
                    zoneSegment(width: geometry.size.width * (zone4Minutes / max(totalMinutes, 1)), color: AppColors.warning)
                    zoneSegment(width: geometry.size.width * (zone5Minutes / max(totalMinutes, 1)), color: AppColors.error)
                }
                .cornerRadius(6)
            }
            .frame(height: 16)
            
            // Legend
            HStack(spacing: 16) {
                zoneLegend(label: "Z1", minutes: zone1Minutes, color: Color.gray.opacity(0.5))
                zoneLegend(label: "Z2", minutes: zone2Minutes, color: AppColors.primary)
                zoneLegend(label: "Z3", minutes: zone3Minutes, color: AppColors.success)
                zoneLegend(label: "Z4", minutes: zone4Minutes, color: AppColors.warning)
                zoneLegend(label: "Z5", minutes: zone5Minutes, color: AppColors.error)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
    
    private func zoneSegment(width: CGFloat, color: Color) -> some View {
        Rectangle()
            .fill(color)
            .frame(width: max(0, width))
    }
    
    private func zoneLegend(label: String, minutes: Double, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                Text("\(Int(minutes))m")
                    .font(.system(size: 10))
                    .foregroundColor(.primary)
            }
        }
    }
}

// MARK: - Training Density Chart
struct TrainingDensityChart: View {
    let data: [DensityDataPoint]
    
    struct DensityDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let density: Double // lbs per minute
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "timer")
                    .foregroundColor(AppColors.warning)
                
                Text("Training Density")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let avg = averageDensity {
                    Text("\(Int(avg)) lbs/min avg")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if data.isEmpty {
                Text("No data available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 120)
            } else {
                Chart {
                    ForEach(data) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Density", point.density)
                        )
                        .foregroundStyle(AppColors.warning)
                        .interpolationMethod(.catmullRom)
                    }
                }
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .frame(height: 120)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
    
    private var averageDensity: Double? {
        guard !data.isEmpty else { return nil }
        return data.map(\.density).reduce(0, +) / Double(data.count)
    }
}

// MARK: - RPE Trend Chart
struct RPETrendChart: View {
    let data: [RPEDataPoint]
    
    struct RPEDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let averageRPE: Double
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "gauge.medium")
                    .foregroundColor(Color(hex: "#7B68EE"))
                
                Text("RPE Trend")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let last = data.last {
                    Text("Last: \(String(format: "%.1f", last.averageRPE))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if data.isEmpty {
                Text("Log RPE to see trends")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 100)
            } else {
                Chart {
                    ForEach(data) { point in
                        BarMark(
                            x: .value("Date", point.date),
                            y: .value("RPE", point.averageRPE)
                        )
                        .foregroundStyle(rpeColor(point.averageRPE))
                    }
                }
                .chartYScale(domain: 0...10)
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks(values: [0, 5, 10]) { _ in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .frame(height: 100)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
    
    private func rpeColor(_ rpe: Double) -> Color {
        if rpe < 5 { return AppColors.success }
        if rpe < 7 { return AppColors.warning }
        return AppColors.error
    }
}

// MARK: - Data Models (if not already defined)
struct OneRepMaxDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let estimated1RM: Double
    let exerciseName: String
}

// MARK: - Previews
#Preview("1RM Trend") {
    OneRepMaxTrendChart(
        data: [
            OneRepMaxDataPoint(date: Date().addingTimeInterval(-86400 * 30), estimated1RM: 200, exerciseName: "Bench Press"),
            OneRepMaxDataPoint(date: Date().addingTimeInterval(-86400 * 20), estimated1RM: 210, exerciseName: "Bench Press"),
            OneRepMaxDataPoint(date: Date().addingTimeInterval(-86400 * 10), estimated1RM: 215, exerciseName: "Bench Press"),
            OneRepMaxDataPoint(date: Date(), estimated1RM: 225, exerciseName: "Bench Press")
        ],
        exerciseName: "Bench Press",
        availableExercises: ["Bench Press", "Squat", "Deadlift"]
    )
    .padding()
    .background(Color(hex: "#F5F5F7"))
}

#Preview("HR Zones") {
    HeartRateZoneChart(
        zone1Minutes: 5,
        zone2Minutes: 25,
        zone3Minutes: 15,
        zone4Minutes: 8,
        zone5Minutes: 2
    )
    .padding()
    .background(Color(hex: "#F5F5F7"))
}
