import SwiftUI
import Charts
import SwiftData

struct FitnessView: View {
    @StateObject private var viewModel = FitnessViewModel()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Fitness")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            Text("Last 30 days")
                                .font(.system(size: 15, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    // .padding(.horizontal) removed

                    // Recovery Overview
                    RecoveryOverviewCard()

                    // Strain Card
                    StrainCard(viewModel: viewModel)
                    
                    // Heatmap Card
                    FitnessHeatmapCard()

                    // Activity Summary Card
                    ActivitySummaryCard()

                    // Cardio Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Cardio")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.horizontal)

                        CardioLoadCard()

                        HStack(spacing: 16) {
                            CardioFocusCard(viewModel: viewModel)
                            HRRCard(viewModel: viewModel)
                        }
                        .padding(.horizontal)
                    }

                    // Strength Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Strength")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.horizontal)

                        StrengthRadarCard(viewModel: viewModel)

                        StrengthProgressionCard(viewModel: viewModel)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical)
                .padding(.bottom, 80)
            }
            .background(Color(hex: "#F5F5F7").ignoresSafeArea())
        }
        .task {
            viewModel.setModelContext(modelContext)
            await viewModel.fetchData()
        }
    }
}

// MARK: - Heatmap Card
// MARK: - Heatmap Card
struct FitnessHeatmapCard: View {
    @StateObject private var healthKitService = HealthKitService.shared
    @State private var activityStats: [Date: Int] = [:]
    
    private let calendar = Calendar.current
    private let days = ["S", "M", "T", "W", "T", "F", "S"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 16) {
                // Previous Month Grid
                MonthGrid(
                    month: previousMonthDate,
                    activityStats: activityStats,
                    days: days
                )
                
                // Current Month Grid
                MonthGrid(
                    month: Date(),
                    activityStats: activityStats,
                    days: days
                )
            }
            
            // Legend
            HStack(spacing: 12) {
                FitnessLegendItem(color: Color.gray.opacity(0.2), label: "0")
                FitnessLegendItem(color: Color.green.opacity(0.4), label: "1")
                FitnessLegendItem(color: Color.green, label: "2")
                FitnessLegendItem(color: Color.blue, label: "3+")
            }
        }

        .fitnessCardStyle()
        .task {
            await fetchActivityData()
        }
    }
    
    private var previousMonthDate: Date {
        calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    }
    
    private func fetchActivityData() async {
        let endDate = Date()
        let startDate = calendar.date(byAdding: .month, value: -2, to: endDate) ?? endDate
        let stats = await healthKitService.getDailyActivityStats(from: startDate, to: endDate)
        await MainActor.run {
            self.activityStats = stats
        }
    }
}

struct MonthGrid: View {
    let month: Date
    let activityStats: [Date: Int]
    let days: [String]
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(monthFormatter.string(from: month))
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                // Day Labels
                HStack(spacing: 4) {
                    ForEach(days, id: \.self) { day in
                        Text(day)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.gray.opacity(0.5))
                            .frame(maxWidth: .infinity)
                    }
                }
                
                // Days Grid
                let daysInMonth = self.daysInMonth
                let firstWeekday = self.firstWeekday
                let totalSlots = 35 // 5 rows * 7 columns
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                    ForEach(0..<totalSlots, id: \.self) { index in
                        if index >= firstWeekday - 1 && index < daysInMonth + firstWeekday - 1 {
                            let day = index - (firstWeekday - 1) + 1
                            let date = date(for: day)
                            let count = activityCount(for: date)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(color(for: count))
                                .aspectRatio(1, contentMode: .fit)
                        } else {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.1))
                                .aspectRatio(1, contentMode: .fit)
                        }
                    }
                }
            }
        }
    }
    
    private var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter
    }
    
    private var daysInMonth: Int {
        calendar.range(of: .day, in: .month, for: month)?.count ?? 30
    }
    
    private var firstWeekday: Int {
        let components = calendar.dateComponents([.year, .month], from: month)
        guard let startOfMonth = calendar.date(from: components) else { return 1 }
        return calendar.component(.weekday, from: startOfMonth)
    }
    
    private func date(for day: Int) -> Date {
        var components = calendar.dateComponents([.year, .month], from: month)
        components.day = day
        return calendar.date(from: components) ?? month
    }
    
    private func activityCount(for date: Date) -> Int {
        let startOfDay = calendar.startOfDay(for: date)
        return activityStats[startOfDay] ?? 0
    }
    
    private func color(for count: Int) -> Color {
        if count == 0 { return Color.gray.opacity(0.2) }
        if count == 1 { return Color.green.opacity(0.4) }
        if count == 2 { return Color.green }
        return Color.blue
    }
}

struct FitnessLegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Activity Summary Card
struct ActivitySummaryCard: View {
    @StateObject private var healthKitService = HealthKitService.shared
    @State private var steps: Double = 0
    @State private var distance: Double = 0
    @State private var activeEnergy: Double = 0
    @State private var exerciseTime: Double = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "figure.walk")
                    .foregroundColor(.blue)
                Text("Activity Summary")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray.opacity(0.5))
            }
            
            VStack(alignment: .leading, spacing: 12) {
                // Steps
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(Int(steps))")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        Text("Steps")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    // Distance
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "%.1f km", distance / 1000))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        Text("Distance")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                // Calories & Time
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(Int(activeEnergy))")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        Text("Kcal")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(Int(exerciseTime)) min")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        Text("Exercise")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }

        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        )
        .task {
            await fetchData()
        }
    }
    
    private func fetchData() async {
        let today = Date()
        async let stepsCount = healthKitService.getSteps(for: today)
        async let dist = healthKitService.getWalkingRunningDistance(for: today)
        async let energy = healthKitService.getActiveEnergyBurned(for: today)
        async let time = healthKitService.getExerciseTime(for: today)
        
        let (s, d, e, t) = await (stepsCount, dist, energy, time)
        
        await MainActor.run {
            self.steps = s
            self.distance = d
            self.activeEnergy = e
            self.exerciseTime = t
        }
    }
}



// MARK: - Cardio Load Card
struct CardioLoadCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "figure.run")
                    .foregroundColor(.gray)
                Text("Cardio Load")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("3")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                    Text("Detraining")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                // Mini Chart
                Chart {
                    ForEach(0..<10, id: \.self) { index in
                        AreaMark(
                            x: .value("Day", index),
                            y: .value("Load", [2, 3, 1, 4, 2, 5, 3, 6, 2, 3][index])
                        )
                        .foregroundStyle(Color.purple.opacity(0.2))
                        
                        LineMark(
                            x: .value("Day", index),
                            y: .value("Load", [2, 3, 1, 4, 2, 5, 3, 6, 2, 3][index])
                        )
                        .foregroundStyle(Color.purple)
                        .interpolationMethod(.catmullRom)
                    }
                }
                .frame(width: 120, height: 60)
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
            }
        }

        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Cardio Focus Card
// MARK: - Cardio Focus Card
struct CardioFocusCard: View {
    @ObservedObject var viewModel: FitnessViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "square.stack.3d.up.fill")
                    .foregroundColor(.gray)
                Text("Cardio Focus")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Text(viewModel.cardioFocusStatus)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("\(Int(viewModel.cardioFocusPercentage * 100))%")
                .font(.subheadline)
                .foregroundColor(Color(hex: "#00D4AA")) // Teal color
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 6)
                    
                    Capsule()
                        .fill(Color(hex: "#00D4AA"))
                        .frame(width: geometry.size.width * viewModel.cardioFocusPercentage, height: 6)
                    
                    // Indicator dot
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                        .offset(x: geometry.size.width * 0.1) // Example position
                        .offset(y: 10) // Below the bar
                }
            }
            .frame(height: 20) // Increased height for dot
        }
        .fitnessCardStyle()
    }
}

// MARK: - HRR Card
// MARK: - HRR Card
struct HRRCard: View {
    @ObservedObject var viewModel: FitnessViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.fill") // Icon with plus
                    .foregroundColor(.gray)
                Text("HRR")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            if viewModel.restingHeartRate > 0 {
                Text("\(Int(viewModel.restingHeartRate)) bpm")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Good") // Placeholder logic
                    .font(.subheadline)
                    .foregroundColor(.orange)
            } else {
                Text("--")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Text("No Data")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Slider/Indicator
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.orange.opacity(0.3), .orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 4)
                        .frame(width: 60) // Short track
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    
                    // Knob
                    Circle()
                        .strokeBorder(Color.orange, lineWidth: 2)
                        .background(Circle().fill(Color.white))
                        .frame(width: 12, height: 12)
                        .position(x: geometry.size.width / 2 + 10, y: geometry.size.height / 2) // Example position
                }
            }
            .frame(height: 20)
        }
        .fitnessCardStyle()
    }
}

// MARK: - Strength Radar Card
struct StrengthRadarCard: View {
    @ObservedObject var viewModel: FitnessViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "scalemass.fill")
                    .foregroundColor(.gray)
                
                Text(viewModel.selectedStrengthMetric.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Menu {
                    ForEach(FitnessViewModel.StrengthMetric.allCases, id: \.self) { metric in
                        Button {
                            viewModel.selectedStrengthMetric = metric
                        } label: {
                            HStack {
                                Text(metric.rawValue)
                                if viewModel.selectedStrengthMetric == metric {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            // Radar Chart
            let data = currentData
            RadarChart(
                data: data,
                maxValue: maxValue,
                isPercentage: viewModel.selectedStrengthMetric == .muscularLoad
            )
            .frame(height: 250)
            .frame(maxWidth: .infinity)
        }
        .fitnessCardStyle()
    }
    
    private var currentData: [String: Double] {
        switch viewModel.selectedStrengthMetric {
        case .totalVolume: return viewModel.muscleGroupVolumes
        case .workoutFrequency: return viewModel.muscleGroupFrequency
        case .muscularLoad: return viewModel.muscleGroupLoad
        }
    }
    
    private var maxValue: Double {
        let values = currentData.values
        if values.isEmpty { return 1 }
        return values.max() ?? 1
    }
}

struct RadarChart: View {
    let data: [String: Double]
    let maxValue: Double
    let isPercentage: Bool
    
    private let categories = ["Chest", "Back", "Legs", "Shoulders", "Core", "Arms"]
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = min(geometry.size.width, geometry.size.height) / 2 - 40
            let step = radius / 4
            
            ZStack {
                // Grid (White/Clean style)
                ForEach(1...4, id: \.self) { i in
                    Circle()
                        .stroke(Color.white, lineWidth: 2) // White lines for "cutout" effect
                        .background(Circle().stroke(Color.gray.opacity(0.1), lineWidth: 1))
                        .frame(width: step * CGFloat(i) * 2, height: step * CGFloat(i) * 2)
                }
                
                // Axes
                ForEach(0..<categories.count, id: \.self) { i in
                    Path { path in
                        path.move(to: center)
                        let angle = Angle(degrees: Double(i) * 60 - 90)
                        let x = center.x + radius * cos(angle.radians)
                        let y = center.y + radius * sin(angle.radians)
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                }
                
                // Data Shape
                if !data.isEmpty {
                    let normalizedData = categories.map { category -> Double in
                        let value = data[category] ?? 0
                        return maxValue > 0 ? value / maxValue : 0
                    }
                    
                    Path { path in
                        for (i, value) in normalizedData.enumerated() {
                            let angle = Angle(degrees: Double(i) * 60 - 90)
                            let r = radius * value
                            let x = center.x + r * cos(angle.radians)
                            let y = center.y + r * sin(angle.radians)
                            
                            if i == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                        path.closeSubpath()
                    }
                    .fill(Color.gray.opacity(0.05))
                    
                    Path { path in
                        for (i, value) in normalizedData.enumerated() {
                            let angle = Angle(degrees: Double(i) * 60 - 90)
                            let r = radius * value
                            let x = center.x + r * cos(angle.radians)
                            let y = center.y + r * sin(angle.radians)
                            
                            if i == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                        path.closeSubpath()
                    }
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                }
                
                // Labels
                ForEach(0..<categories.count, id: \.self) { i in
                    let angle = Angle(degrees: Double(i) * 60 - 90)
                    let labelRadius = radius + 25
                    let x = center.x + labelRadius * cos(angle.radians)
                    let y = center.y + labelRadius * sin(angle.radians)
                    
                    VStack(spacing: 2) {
                        let value = data[categories[i]] ?? 0
                        Text(formatValue(value))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(categories[i])
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    .position(x: x, y: y)
                }
            }
        }
    }
    
    private func formatValue(_ value: Double) -> String {
        if isPercentage {
            return "\(Int(value * 100))%"
        } else {
            // Check if it's frequency (likely small integer) or volume (large number)
            if value < 100 && value.truncatingRemainder(dividingBy: 1) == 0 {
                 return "\(Int(value))"
            }
            return "\(Int(value)) lb"
        }
    }
}

// MARK: - Strength Progression Card
struct StrengthProgressionCard: View {
    @ObservedObject var viewModel: FitnessViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.xyaxis.line")
                    .foregroundColor(.gray)
                Text("Strength Progression")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // Placeholder Content
            VStack(spacing: 12) {
                // Mock lines
                HStack {
                    Capsule().fill(Color.gray.opacity(0.1)).frame(width: 40, height: 4)
                    Spacer()
                    Capsule().fill(Color.gray.opacity(0.1)).frame(width: 80, height: 4)
                }
                HStack {
                    Capsule().fill(Color.gray.opacity(0.1)).frame(width: 60, height: 4)
                    Spacer()
                }
                
                Spacer().frame(height: 10)
                
                Text("No progression data")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.gray)
                
                Text("No \(viewModel.selectedStrengthMetric.rawValue.lowercased()) recorded in the last 30 days.")
                    .font(.caption)
                    .foregroundColor(.gray.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer().frame(height: 10)
                
                HStack {
                    Spacer()
                    Button {
                        // Add workout action
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(width: 44, height: 44)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    }
                }
            }
            .frame(height: 150)
        }
        .fitnessCardStyle()
    }
}

#Preview {
    FitnessView()
}

// MARK: - Card Style Modifier
struct FitnessCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.vertical, 24)
            .padding(.horizontal, 16)
            .background(Color.white)
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 5)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.gray.opacity(0.15), lineWidth: 1)
            )
    }
}

extension View {
    func fitnessCardStyle() -> some View {
        modifier(FitnessCardStyle())
    }
}
