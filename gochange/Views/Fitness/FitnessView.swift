import SwiftUI
import Charts
import SwiftData

struct FitnessView: View {
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
                        
                        Button {
                            // Add action
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.primary)
                                .frame(width: 40, height: 40)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Heatmap Card
                    FitnessHeatmapCard()
                    
                    // Activity Summary Card
                    ActivitySummaryCard()
                    
                    // Strain Performance Card
                    StrainPerformanceCard()
                    
                    // Cardio Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Cardio")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        CardioLoadCard()
                        
                        HStack(spacing: 16) {
                            CardioFocusCard()
                            HRRCard()
                        }
                        .padding(.horizontal)
                    }
                    
                    // Strength Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Strength")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        TotalVolumeCard()
                    }
                }
                .padding(.vertical)
                .padding(.bottom, 80)
            }
            .background(Color(hex: "#F5F5F7").ignoresSafeArea())
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
            HStack(spacing: 16) {
                LegendItem(color: Color.green.opacity(0.4), label: "1 activity")
                LegendItem(color: Color.green, label: "2 activities")
                LegendItem(color: Color.blue, label: "3+ activities")
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        .padding(.horizontal)
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

struct LegendItem: View {
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
        .padding(20)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        .padding(.horizontal)
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

// MARK: - Strain Performance Card
struct StrainPerformanceCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .foregroundColor(.gray)
                Text("Strain Performance")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("-30%")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primary)
                Text("Below target")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
            
            // Mock Chart
            Chart {
                ForEach(0..<30, id: \.self) { index in
                    LineMark(
                        x: .value("Day", index),
                        y: .value("Strain", Double.random(in: 0...100))
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .green, .orange],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
            }
            .frame(height: 100)
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        .padding(.horizontal)
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
        .padding(20)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        .padding(.horizontal)
    }
}

// MARK: - Cardio Focus Card
struct CardioFocusCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "square.stack.3d.up")
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
            
            Text("Low Aerobic")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("94%")
                .font(.subheadline)
                .foregroundColor(Color(hex: "#00D4AA"))
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 6)
                    
                    Capsule()
                        .fill(Color(hex: "#00D4AA"))
                        .frame(width: geometry.size.width * 0.94, height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - HRR Card
struct HRRCard: View {
    @StateObject private var healthKitService = HealthKitService.shared
    @State private var restingHeartRate: Double = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                Text("RHR")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            if restingHeartRate > 0 {
                Text("\(Int(restingHeartRate)) bpm")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(restingHeartRate < 60 ? "Excellent" : restingHeartRate < 70 ? "Good" : "Average")
                    .font(.subheadline)
                    .foregroundColor(restingHeartRate < 60 ? .green : .orange)
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
                    Capsule()
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 4)
                    
                    if restingHeartRate > 0 {
                        // Map 40-100 bpm to 0-1 range
                        let normalized = min(max((restingHeartRate - 40) / 60, 0), 1)
                        
                        Circle()
                            .fill(restingHeartRate < 60 ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)
                            .offset(x: geometry.size.width * normalized)
                    }
                }
            }
            .frame(height: 8)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .task {
            if let rhr = await healthKitService.getRestingHeartRate(for: Date()) {
                await MainActor.run {
                    self.restingHeartRate = rhr
                }
            }
        }
    }
}

// MARK: - Total Volume Card (Radar Chart Placeholder)
struct TotalVolumeCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "scalemass.fill")
                    .foregroundColor(.gray)
                Text("Total Volume")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // Radar Chart Visualization
            ZStack {
                // Spider Web Grid
                ForEach(1...4, id: \.self) { i in
                    Circle()
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                        .frame(width: CGFloat(i) * 50, height: CGFloat(i) * 50)
                }
                
                // Lines
                ForEach(0..<6, id: \.self) { i in
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 1, height: 200)
                        .rotationEffect(.degrees(Double(i) * 60))
                }
                
                // Labels
                VStack {
                    Text("0 lb\nChest")
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                        .offset(y: -110)
                    Spacer()
                    Text("0 lb\nShoulders")
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                        .offset(y: 110)
                }
                .frame(height: 240)
                
                HStack {
                    Text("0 lb\nArms")
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                        .offset(x: -110)
                    Spacer()
                    Text("0 lb\nBack")
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                        .offset(x: 110)
                }
                .frame(width: 240)
                
                HStack {
                    Text("0 lb\nCore")
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                        .offset(x: -80, y: 80)
                    Spacer()
                    Text("0 lb\nLegs")
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                        .offset(x: 80, y: 80)
                }
                .frame(width: 240)
            }
            .frame(height: 250)
            .frame(maxWidth: .infinity)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        .padding(.horizontal)
    }
}

#Preview {
    FitnessView()
}
