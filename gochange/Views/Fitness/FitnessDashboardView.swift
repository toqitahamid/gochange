import SwiftUI
import Charts
import SwiftData

struct FitnessDashboardView: View {
    @StateObject private var viewModel = FitnessViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var selectedMetricInfo: MetricExplanationSheet.MetricType?
    @State private var selectedTimeRange: TimeRange = .month

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Fitness")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        TimeRangePicker(selection: $selectedTimeRange)
                    }

                    // Daily Readiness
                    DailyReadinessCard(viewModel: viewModel) {
                        selectedMetricInfo = .readiness
                    }
                    
                    HStack(spacing: 16) {
                        // Sleep Debt
                        SleepDebtCard(viewModel: viewModel) {
                            selectedMetricInfo = .sleepDebt
                        }
                        
                        // ACWR
                        ACWRCard(viewModel: viewModel) {
                            selectedMetricInfo = .acwr
                        }
                    }
                    
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

                        CardioLoadCard(viewModel: viewModel)

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
                    
                    // Strain vs Recovery Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Strain Performance")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        StrainRecoveryCorrelationCard(viewModel: viewModel)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical)
                .padding(.bottom, 80)
            }
            .background(AppColors.background.ignoresSafeArea())
        }
        .sheet(item: $selectedMetricInfo) { metric in
            let value: Double? = {
                switch metric {
                case .readiness: return viewModel.dailyReadinessScore
                case .sleepDebt: return viewModel.sleepDebt
                case .acwr: return viewModel.acwr
                case .systemicLoad: return viewModel.systemicLoad
                default: return nil
                }
            }()
            
            MetricExplanationSheet(metric: metric, currentValue: value)
                .presentationDetents([.large])
        }
        .task(id: selectedTimeRange) {
            viewModel.setModelContext(modelContext)
            await viewModel.fetchData(for: selectedTimeRange)
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
                FitnessLegendItem(color: AppColors.success.opacity(0.4), label: "1")
                FitnessLegendItem(color: AppColors.success, label: "2")
                FitnessLegendItem(color: AppColors.primary, label: "3+")
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
        if count == 1 { return AppColors.success.opacity(0.4) }
        if count == 2 { return AppColors.success }
        return AppColors.primary
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
                    .foregroundColor(AppColors.primary)
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
            self.distance = d ?? 0
            self.activeEnergy = e ?? 0
            self.exerciseTime = t ?? 0
        }
    }
}



// MARK: - Cardio Load Card
struct CardioLoadCard: View {
    @ObservedObject var viewModel: FitnessViewModel
    
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
                    // Show average of last 3 days or some aggregate
                    let avgLoad = viewModel.cardioLoadHistory.suffix(3).reduce(0, +) / 3.0
                    Text("\(Int(avgLoad))")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                        .contentTransition(.numericText())
                    
                    Text(status(for: avgLoad))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(statusColor(for: avgLoad))
                }
                
                Spacer()
                
                // Mini Chart
                if !viewModel.cardioLoadHistory.isEmpty {
                    Chart {
                        ForEach(Array(viewModel.cardioLoadHistory.enumerated()), id: \.offset) { index, value in
                            AreaMark(
                                x: .value("Day", index),
                                y: .value("Load", value)
                            )
                            .foregroundStyle(Color.purple.opacity(0.2))
                            
                            LineMark(
                                x: .value("Day", index),
                                y: .value("Load", value)
                            )
                            .foregroundStyle(Color.purple)
                            .interpolationMethod(.catmullRom)
                        }
                    }
                    .frame(width: 120, height: 60)
                    .chartXAxis(.hidden)
                    .chartYAxis(.hidden)
                } else {
                    Text("No Data")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(width: 120, height: 60)
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
    }
    
    private func status(for load: Double) -> String {
        if load > 500 { return "Productive" } // Mock threshold
        if load > 200 { return "Maintaining" }
        return "Detraining"
    }
    
    private func statusColor(for load: Double) -> Color {
        if load > 500 { return AppColors.success }
        if load > 200 { return AppColors.primary }
        return AppColors.warning
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
                    .foregroundColor(AppColors.success)
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 6)
                    
                    Capsule()
                        .fill(AppColors.success)
                        .frame(width: geometry.size.width * viewModel.cardioFocusPercentage, height: 6)
                    
                    // Indicator dot
                    Circle()
                        .fill(AppColors.primary)
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
                
                Text(viewModel.rhrStatus)
                    .font(.subheadline)
                    .foregroundColor(rhrColor)
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
    private var rhrColor: Color {
        switch viewModel.rhrStatus {
        case "Excellent", "Good": return AppColors.success
        case "Fair": return AppColors.warning
        default: return AppColors.error
        }
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
            let radius = min(geometry.size.width / 2, geometry.size.height / 2) - 40 // Safe margin for labels
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
    @State private var showAddWorkout = false
    
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
                        showAddWorkout = true
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
        .sheet(isPresented: $showAddWorkout) {
             AddWorkoutDayView()
        }
    }
}

#Preview {
    FitnessDashboardView()
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

// MARK: - Daily Readiness Card
struct DailyReadinessCard: View {
    @ObservedObject var viewModel: FitnessViewModel
    var onInfoTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "bolt.heart.fill")
                    .foregroundColor(AppColors.primary)
                Text("Daily Readiness")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: onInfoTap) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            HStack(alignment: .bottom, spacing: 4) {
                Text("\(Int(viewModel.dailyReadinessScore))")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(scoreColor)
                Text("%")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 6)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(governorMessage)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(scoreColor)
                        .multilineTextAlignment(.trailing)
                    
                    Text("Based on HRV, Sleep & RHR")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 8)
                    
                    Capsule()
                        .fill(scoreColor)
                        .frame(width: geometry.size.width * (viewModel.dailyReadinessScore / 100), height: 8)
                }
            }
            .frame(height: 8)
        }
        .fitnessCardStyle()
    }
    
    private var scoreColor: Color {
        if viewModel.dailyReadinessScore >= 80 { return AppColors.success }
        if viewModel.dailyReadinessScore >= 40 { return AppColors.warning }
        return AppColors.error
    }
    
    private var governorMessage: String {
        if viewModel.dailyReadinessScore >= 80 { return "Prime Time. Go for PRs." }
        if viewModel.dailyReadinessScore >= 40 { return "Train as planned." }
        return "CNS Fried. Reduce Volume."
    }
}

// MARK: - Sleep Debt Card
struct SleepDebtCard: View {
    @ObservedObject var viewModel: FitnessViewModel
    var onInfoTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bed.double.fill")
                    .foregroundColor(AppColors.primary)
                Text("Sleep Debt")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: onInfoTap) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            HStack(alignment: .firstTextBaseline) {
                Text(String(format: "%.1f", viewModel.sleepDebt))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(debtColor)
                Text("hours")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(realityCheckMessage)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(debtColor)
            }
        }
        .fitnessCardStyle()
    }
    
    private var debtColor: Color {
        if viewModel.sleepDebt < 2 { return AppColors.success }
        if viewModel.sleepDebt < 5 { return AppColors.warning }
        return AppColors.error
    }
    
    private var realityCheckMessage: String {
        if viewModel.sleepDebt < 2 { return "Well Rested" }
        if viewModel.sleepDebt < 5 { return "Minor Debt" }
        return "Recovery Compromised"
    }
}

// MARK: - ACWR Card
struct ACWRCard: View {
    @ObservedObject var viewModel: FitnessViewModel
    var onInfoTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "shield.fill")
                    .foregroundColor(AppColors.success)
                Text("ACWR (Injury Risk)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: onInfoTap) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            HStack(alignment: .firstTextBaseline) {
                Text(String(format: "%.2f", viewModel.acwr))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(ratioColor)
                
                Spacer()
                
                Text(shieldMessage)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(ratioColor)
            }
            
            // Range Indicator
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background Track
                    Capsule()
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 6)
                    
                    // Sweet Spot Zone (0.8 - 1.3)
                    // Map 0.0 - 2.0 range to width
                    let start = (0.8 / 2.0) * geometry.size.width
                    let width = ((1.3 - 0.8) / 2.0) * geometry.size.width
                    
                    Capsule()
                        .fill(Color.green.opacity(0.3))
                        .frame(width: width, height: 6)
                        .offset(x: start)
                    
                    // Current Value Indicator
                    let currentPos = min(max(viewModel.acwr / 2.0, 0), 1.0) * geometry.size.width
                    Circle()
                        .fill(ratioColor)
                        .frame(width: 10, height: 10)
                        .offset(x: currentPos - 5)
                }
            }
            .frame(height: 10)
        }
        .fitnessCardStyle()
    }
    
    private var ratioColor: Color {
        if viewModel.acwr >= 0.8 && viewModel.acwr <= 1.3 { return AppColors.success }
        if viewModel.acwr > 1.5 { return AppColors.error }
        return AppColors.warning
    }
    
    private var shieldMessage: String {
        if viewModel.acwr >= 0.8 && viewModel.acwr <= 1.3 { return "Sweet Spot" }
        if viewModel.acwr > 1.5 { return "High Risk" }
        return "Undertraining"
    }
}

// MARK: - Strain vs Recovery Correlation Card
struct StrainRecoveryCorrelationCard: View {
    @ObservedObject var viewModel: FitnessViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.gray)
                
                Text("Strain vs Recovery")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            // Chart
            if viewModel.isLoadingStrainRecoveryData {
                // Loading state
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading correlation data...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
            } else if !viewModel.strainRecoveryData.isEmpty {
                Chart {
                    // Recovery line (green)
                    ForEach(viewModel.strainRecoveryData) { point in
                        LineMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("Recovery", point.recoveryScore)
                        )
                        .foregroundStyle(Color(hex: "#00D4AA"))
                        .interpolationMethod(.catmullRom)
                        .symbol(Circle().strokeBorder(lineWidth: 2))
                        
                        // Recovery area
                        AreaMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("Recovery", point.recoveryScore)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "#00D4AA").opacity(0.2), Color(hex: "#00D4AA").opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                    }
                    
                    // Strain line (orange)
                    ForEach(viewModel.strainRecoveryData) { point in
                        LineMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("Strain", point.strainScore)
                        )
                        .foregroundStyle(Color(hex: "#FF6B35"))
                        .interpolationMethod(.catmullRom)
                        .symbol(Circle().strokeBorder(lineWidth: 2))
                    }
                }
                .frame(height: 200)
                .chartXAxis {
                    // Improved axis label spacing based on data count
                    let labelCount = viewModel.strainRecoveryData.count > 30 ? 7 : 
                                    viewModel.strainRecoveryData.count > 14 ? 5 : 
                                    viewModel.strainRecoveryData.count > 7 ? 3 : 1
                    
                    AxisMarks(values: .stride(by: .day, count: max(1, viewModel.strainRecoveryData.count / max(1, labelCount)))) { _ in
                        AxisValueLabel(format: .dateTime.month().day(), centered: false)
                            .font(.caption2)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .stride(by: 25)) { value in
                        AxisValueLabel {
                            if let intValue = value.as(Double.self) {
                                Text("\(Int(intValue))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        AxisGridLine()
                            .foregroundStyle(.gray.opacity(0.2))
                    }
                }
                .chartYScale(domain: 0...100)
                
                // Legend
                HStack(spacing: 20) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(hex: "#00D4AA"))
                            .frame(width: 8, height: 8)
                        Text("Recovery")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(hex: "#FF6B35"))
                            .frame(width: 8, height: 8)
                        Text("Strain")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                // Insight text
                if let insight = generateInsight() {
                    Text(insight)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            } else {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 32))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("No data available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Complete workouts and sync recovery data to see correlation")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
            }
        }
        .fitnessCardStyle()
    }
    
    private func generateInsight() -> String? {
        guard !viewModel.strainRecoveryData.isEmpty else { return nil }
        
        // Calculate average recovery and strain
        let avgRecovery = viewModel.strainRecoveryData.map { $0.recoveryScore }.reduce(0, +) / Double(viewModel.strainRecoveryData.count)
        let avgStrain = viewModel.strainRecoveryData.map { $0.strainScore }.reduce(0, +) / Double(viewModel.strainRecoveryData.count)
        
        // Generate insight based on correlation
        if avgRecovery > 70 && avgStrain > 50 {
            return "Good balance: High recovery supports your training intensity"
        } else if avgRecovery < 50 && avgStrain > 50 {
            return "Consider rest: High strain with low recovery may lead to overreaching"
        } else if avgRecovery > 70 && avgStrain < 30 {
            return "Ready to push: High recovery suggests you can increase intensity"
        } else if avgRecovery < 50 && avgStrain < 30 {
            return "Focus on recovery: Low strain and recovery suggests rest is needed"
        }
        
        return "Track your strain and recovery balance over time"
    }
}
