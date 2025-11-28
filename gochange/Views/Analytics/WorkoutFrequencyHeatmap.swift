import SwiftUI
import SwiftData

struct WorkoutFrequencyHeatmap: View {
    let data: [WorkoutFrequencyPoint]
    
    private let calendar = Calendar.current
    private let days = ["S", "M", "T", "W", "T", "F", "S"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Activity Heatmap")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Last 90 days")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Legend
                HStack(spacing: 12) {
                    LegendItem(color: Color.gray.opacity(0.2), label: "0")
                    LegendItem(color: Color.green.opacity(0.4), label: "1")
                    LegendItem(color: Color.green, label: "2")
                    LegendItem(color: Color.blue, label: "3+")
                }
            }
            
            // 3 Months Grid
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 16) {
                    ForEach(0..<3) { i in
                        let monthDate = calendar.date(byAdding: .month, value: -i, to: Date()) ?? Date()
                        HeatmapMonthGrid(
                            month: monthDate,
                            data: data,
                            days: days
                        )
                    }
                }
                .padding(.vertical, 4) // Add some padding for shadows if needed
            }
            .defaultScrollAnchor(.trailing) // Start from the right (latest month)
            
            // Stats
            HStack(spacing: 24) {
                HeatmapStatBadge(
                    icon: "flame.fill",
                    value: "\(currentStreak)",
                    label: "Day Streak",
                    color: .orange
                )
                
                HeatmapStatBadge(
                    icon: "calendar.badge.clock",
                    value: "\(activeDays)",
                    label: "Active Days",
                    color: .blue
                )
                
                Spacer()
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        )
    }
    
    // MARK: - Computed Properties
    
    private var activeDays: Int {
        data.filter { $0.workoutCount > 0 }.count
    }
    
    private var currentStreak: Int {
        var streak = 0
        let sortedData = data.sorted { $0.date > $1.date }
        let today = calendar.startOfDay(for: Date())
        
        // Check if we worked out today
        let workedOutToday = sortedData.first { calendar.isDate($0.date, inSameDayAs: today) }?.workoutCount ?? 0 > 0
        
        if workedOutToday {
            streak = 1
        }
        
        // Check previous days
        var checkDate = calendar.date(byAdding: .day, value: -1, to: today)!
        
        while true {
            let hasWorkout = sortedData.contains { point in
                calendar.isDate(point.date, inSameDayAs: checkDate) && point.workoutCount > 0
            }
            
            if hasWorkout {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }
        
        return streak
    }
}

struct HeatmapMonthGrid: View {
    let month: Date
    let data: [WorkoutFrequencyPoint]
    let days: [String]
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(monthFormatter.string(from: month))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 6) {
                // Day Labels
                HStack(spacing: 4) {
                    ForEach(days, id: \.self) { day in
                        Text(day)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.gray.opacity(0.5))
                            .frame(maxWidth: .infinity)
                    }
                }
                
                // Days Grid
                let daysInMonth = self.daysInMonth
                let firstWeekday = self.firstWeekday
                let totalSlots = 35 // 5 rows * 7 columns (approx) or 42 for 6 rows
                
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(20), spacing: 4), count: 7), spacing: 4) {
                    ForEach(0..<42, id: \.self) { index in
                        if index >= firstWeekday - 1 && index < daysInMonth + firstWeekday - 1 {
                            let day = index - (firstWeekday - 1) + 1
                            let date = date(for: day)
                            let count = workoutCount(for: date)
                            
                            RoundedRectangle(cornerRadius: 3)
                                .fill(color(for: count))
                                .frame(height: 20)
                        } else if index < daysInMonth + firstWeekday - 1 {
                             // Empty slots before start of month
                            Color.clear.frame(height: 20)
                        }
                    }
                }
            }
        }
        .frame(width: 170) // Fixed width for consistent scrolling
    }
    
    private var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
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
    
    private func workoutCount(for date: Date) -> Int {
        let startOfDay = calendar.startOfDay(for: date)
        return data.first { calendar.isDate($0.date, inSameDayAs: startOfDay) }?.workoutCount ?? 0
    }
    
    private func color(for count: Int) -> Color {
        if count == 0 { return Color.gray.opacity(0.15) }
        if count == 1 { return Color.green.opacity(0.4) }
        if count == 2 { return Color.green }
        return Color.blue
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct HeatmapStatBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    let calendar = Calendar.current
    let today = Date()
    var sampleData: [WorkoutFrequencyPoint] = []
    
    // Generate 90 days of sample data
    for i in 0..<90 {
        let date = calendar.date(byAdding: .day, value: -i, to: today)!
        let count = Int.random(in: 0...3)
        let intensity = count > 0 ? Double(count) / 2.0 : 0
        sampleData.append(WorkoutFrequencyPoint(date: date, workoutCount: count, intensity: intensity))
    }
    
    return ZStack {
        Color(hex: "#F5F5F7").ignoresSafeArea()
        WorkoutFrequencyHeatmap(data: sampleData)
            .padding()
    }
}
