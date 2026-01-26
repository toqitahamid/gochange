import SwiftUI
import Charts

// MARK: - Body Composition Chart
struct BodyCompositionChart: View {
    let weightData: [WeightDataPoint]
    let bodyFatData: [BodyFatDataPoint]
    
    struct WeightDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let weight: Double // lbs or kg
    }
    
    struct BodyFatDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let bodyFatPercent: Double
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "figure.stand")
                    .foregroundColor(AppColors.primary)
                
                Text("Body Composition")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            // Current Stats
            if let lastWeight = weightData.last, let lastBF = bodyFatData.last {
                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(Int(lastWeight.weight)) lbs")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                        Text("Weight")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(format: "%.1f%%", lastBF.bodyFatPercent))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                        Text("Body Fat")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
            
            // Dual Axis Chart
            if !weightData.isEmpty {
                Chart {
                    ForEach(weightData) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Weight", point.weight)
                        )
                        .foregroundStyle(AppColors.primary)
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
            } else {
                Text("No weight data")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
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
}

// MARK: - Rest Period Histogram
struct RestPeriodHistogram: View {
    let restPeriods: [TimeInterval] // Array of rest periods in seconds
    
    private var buckets: [(range: String, count: Int)] {
        var result: [(String, Int)] = [
            ("0-30s", 0),
            ("30-60s", 0),
            ("60-90s", 0),
            ("90-120s", 0),
            ("120s+", 0)
        ]
        
        for period in restPeriods {
            if period < 30 { result[0].1 += 1 }
            else if period < 60 { result[1].1 += 1 }
            else if period < 90 { result[2].1 += 1 }
            else if period < 120 { result[3].1 += 1 }
            else { result[4].1 += 1 }
        }
        
        return result
    }
    
    private var averageRest: TimeInterval {
        guard !restPeriods.isEmpty else { return 0 }
        return restPeriods.reduce(0, +) / Double(restPeriods.count)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "stopwatch")
                    .foregroundColor(AppColors.success)
                
                Text("Rest Periods")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Avg: \(Int(averageRest))s")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if restPeriods.isEmpty {
                Text("No rest data")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 100)
            } else {
                Chart {
                    ForEach(buckets, id: \.range) { bucket in
                        BarMark(
                            x: .value("Range", bucket.range),
                            y: .value("Count", bucket.count)
                        )
                        .foregroundStyle(AppColors.success.gradient)
                        .cornerRadius(4)
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
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
}

// MARK: - Work Capacity Chart (Area Chart)
struct WorkCapacityChart: View {
    let data: [WorkCapacityPoint]
    
    struct WorkCapacityPoint: Identifiable {
        let id = UUID()
        let date: Date
        let totalWork: Double // Total volume
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(AppColors.warning)
                
                Text("Work Capacity")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let trend = calculateTrend() {
                    HStack(spacing: 2) {
                        Image(systemName: trend >= 0 ? "arrow.up.right" : "arrow.down.right")
                        Text(String(format: "%.1f%%", abs(trend)))
                    }
                    .font(.caption)
                    .foregroundColor(trend >= 0 ? AppColors.success : AppColors.error)
                }
            }
            
            if data.isEmpty {
                Text("Complete workouts to track capacity")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 120)
            } else {
                Chart {
                    ForEach(data) { point in
                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("Work", point.totalWork)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppColors.warning.opacity(0.4), AppColors.warning.opacity(0.1)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                        
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Work", point.totalWork)
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
    
    private func calculateTrend() -> Double? {
        guard data.count >= 4 else { return nil }
        let recent = data.suffix(data.count / 2).map(\.totalWork).reduce(0, +) / Double(data.count / 2)
        let previous = data.prefix(data.count / 2).map(\.totalWork).reduce(0, +) / Double(data.count / 2)
        guard previous > 0 else { return nil }
        return ((recent - previous) / previous) * 100
    }
}

// MARK: - Anatomical Muscle Heatmap
struct AnatomicalMuscleHeatmap: View {
    let muscleData: [String: Double] // Muscle group -> Volume or Intensity (0-1 normalized)
    
    private let musclePositions: [(name: String, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat)] = [
        ("Chest", 0.5, 0.25, 0.35, 0.12),
        ("Shoulders", 0.5, 0.18, 0.45, 0.08),
        ("Back", 0.5, 0.35, 0.35, 0.15),
        ("Arms", 0.5, 0.35, 0.55, 0.08),
        ("Core", 0.5, 0.48, 0.25, 0.12),
        ("Legs", 0.5, 0.72, 0.30, 0.25)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "figure.stand")
                    .foregroundColor(AppColors.primary)
                
                Text("Muscle Load")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            // Body Outline with Heatmap
            GeometryReader { geometry in
                ZStack {
                    // Body silhouette background
                    Image(systemName: "figure.stand")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(.gray.opacity(0.1))
                    
                    // Muscle overlays
                    ForEach(musclePositions, id: \.name) { muscle in
                        let intensity = muscleData[muscle.name] ?? 0
                        
                        Capsule()
                            .fill(heatColor(intensity))
                            .frame(width: geometry.size.width * muscle.width, height: geometry.size.height * muscle.height)
                            .position(x: geometry.size.width * muscle.x, y: geometry.size.height * muscle.y)
                            .opacity(0.7)
                    }
                }
            }
            .frame(height: 200)
            
            // Legend
            HStack(spacing: 8) {
                ForEach(["Fresh", "Light", "Moderate", "Intense"], id: \.self) { label in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(legendColor(for: label))
                            .frame(width: 8, height: 8)
                        Text(label)
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                }
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
    
    private func heatColor(_ intensity: Double) -> Color {
        if intensity < 0.25 { return AppColors.success.opacity(0.3) }
        if intensity < 0.5 { return AppColors.success }
        if intensity < 0.75 { return AppColors.warning }
        return AppColors.error
    }
    
    private func legendColor(for label: String) -> Color {
        switch label {
        case "Fresh": return AppColors.success.opacity(0.3)
        case "Light": return AppColors.success
        case "Moderate": return AppColors.warning
        case "Intense": return AppColors.error
        default: return .gray
        }
    }
}

// MARK: - Previews
#Preview("Body Composition") {
    BodyCompositionChart(
        weightData: [
            .init(date: Date().addingTimeInterval(-86400 * 30), weight: 185),
            .init(date: Date().addingTimeInterval(-86400 * 20), weight: 183),
            .init(date: Date().addingTimeInterval(-86400 * 10), weight: 181),
            .init(date: Date(), weight: 180)
        ],
        bodyFatData: [
            .init(date: Date(), bodyFatPercent: 15.5)
        ]
    )
    .padding()
    .background(Color(hex: "#F5F5F7"))
}

#Preview("Rest Periods") {
    RestPeriodHistogram(restPeriods: [45, 60, 75, 90, 120, 60, 45, 30, 90, 60, 45, 120, 150])
        .padding()
        .background(Color(hex: "#F5F5F7"))
}

#Preview("Muscle Heatmap") {
    AnatomicalMuscleHeatmap(muscleData: [
        "Chest": 0.8,
        "Back": 0.6,
        "Legs": 0.3,
        "Shoulders": 0.5,
        "Arms": 0.7,
        "Core": 0.2
    ])
    .padding()
    .background(Color(hex: "#F5F5F7"))
}
