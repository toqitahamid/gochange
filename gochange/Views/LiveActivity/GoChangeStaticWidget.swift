import WidgetKit
import SwiftUI

// MARK: - Color Extension for Widget
// Note: Widget extensions compile separately and need their own Color init
private extension Color {
    init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Widget Data Model
struct WidgetWorkoutData: Codable {
    let workoutsThisWeek: Int
    let totalWorkoutDays: Int
    let currentStreak: Int
    let nextWorkoutName: String?
    let lastUpdated: Date
    
    static let placeholder = WidgetWorkoutData(
        workoutsThisWeek: 2,
        totalWorkoutDays: 4,
        currentStreak: 3,
        nextWorkoutName: "Push",
        lastUpdated: Date()
    )
}

// MARK: - Shared Data Manager
class WidgetDataManager {
    static let shared = WidgetDataManager()
    
    private let userDefaults = UserDefaults(suiteName: "group.com.toqitahamid.gochange") ?? UserDefaults.standard
    private let dataKey = "widgetWorkoutData"
    
    func saveData(_ data: WidgetWorkoutData) {
        if let encoded = try? JSONEncoder().encode(data) {
            userDefaults.set(encoded, forKey: dataKey)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    func loadData() -> WidgetWorkoutData {
        guard let data = userDefaults.data(forKey: dataKey),
              let decoded = try? JSONDecoder().decode(WidgetWorkoutData.self, from: data) else {
            return WidgetWorkoutData.placeholder
        }
        return decoded
    }
}

// MARK: - Timeline Provider
struct GoChangeWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> GoChangeWidgetEntry {
        GoChangeWidgetEntry(date: Date(), data: .placeholder)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (GoChangeWidgetEntry) -> Void) {
        let entry = GoChangeWidgetEntry(date: Date(), data: WidgetDataManager.shared.loadData())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<GoChangeWidgetEntry>) -> Void) {
        let entry = GoChangeWidgetEntry(date: Date(), data: WidgetDataManager.shared.loadData())
        
        // Update every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Timeline Entry
struct GoChangeWidgetEntry: TimelineEntry {
    let date: Date
    let data: WidgetWorkoutData
}

// MARK: - Small Widget View
struct GoChangeSmallWidgetView: View {
    let entry: GoChangeWidgetEntry
    
    private var progressPercent: Double {
        guard entry.data.totalWorkoutDays > 0 else { return 0 }
        return Double(entry.data.workoutsThisWeek) / Double(entry.data.totalWorkoutDays)
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(hexString: "#1a1a2e") ?? .black, Color(hexString: "#16213e") ?? .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 12) {
                // Progress Ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 6)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: progressPercent)
                        .stroke(
                            LinearGradient(
                                colors: [Color(hexString: "#00D4AA"), Color(hexString: "#00B894")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 0) {
                        Text("\(entry.data.workoutsThisWeek)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("/\(entry.data.totalWorkoutDays)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }
                
                // Label
                Text("THIS WEEK")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1)
                    .foregroundColor(.gray)
                
                // Streak
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hexString: "#FF6B35"))
                    Text("\(entry.data.currentStreak)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            .padding()
        }
        .containerBackground(for: .widget) {
            Color(hexString: "#16213e") ?? .black
        }
    }
}

// MARK: - Medium Widget View
struct GoChangeMediumWidgetView: View {
    let entry: GoChangeWidgetEntry
    
    private var progressPercent: Double {
        guard entry.data.totalWorkoutDays > 0 else { return 0 }
        return Double(entry.data.workoutsThisWeek) / Double(entry.data.totalWorkoutDays)
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(hexString: "#1a1a2e") ?? .black, Color(hexString: "#16213e") ?? .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            HStack(spacing: 20) {
                // Left: Progress Circle
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 8)
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .trim(from: 0, to: progressPercent)
                            .stroke(
                                LinearGradient(
                                    colors: [Color(hexString: "#00D4AA"), Color(hexString: "#00B894")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))
                        
                        VStack(spacing: 0) {
                            Text("\(entry.data.workoutsThisWeek)")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("/\(entry.data.totalWorkoutDays)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Text("THIS WEEK")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1)
                        .foregroundColor(.gray)
                }
                
                // Right: Stats and Next Workout
                VStack(alignment: .leading, spacing: 12) {
                    // Streak
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color(hexString: "#FF6B35").opacity(0.2).opacity(0.2))
                                .frame(width: 36, height: 36)
                            Image(systemName: "flame.fill")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hexString: "#FF6B35"))
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(entry.data.currentStreak) weeks")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("Streak")
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Next Workout
                    if let nextWorkout = entry.data.nextWorkoutName {
                        HStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color(hexString: "#00D4AA").opacity(0.2).opacity(0.2))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color(hexString: "#00D4AA"))
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(nextWorkout)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                Text("Up Next")
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .containerBackground(for: .widget) {
            Color(hexString: "#16213e") ?? .black
        }
    }
}

// MARK: - Static Widget Definition
struct GoChangeStaticWidget: Widget {
    let kind: String = "GoChangeStaticWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GoChangeWidgetProvider()) { entry in
            GoChangeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("GoChange Progress")
        .description("Track your weekly workout progress and streak.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget Entry View
struct GoChangeWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: GoChangeWidgetEntry
    
    var body: some View {
        switch family {
        case .systemSmall:
            GoChangeSmallWidgetView(entry: entry)
        case .systemMedium:
            GoChangeMediumWidgetView(entry: entry)
        default:
            GoChangeSmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Previews
#Preview("Small", as: .systemSmall) {
    GoChangeStaticWidget()
} timeline: {
    GoChangeWidgetEntry(date: Date(), data: .placeholder)
}

#Preview("Medium", as: .systemMedium) {
    GoChangeStaticWidget()
} timeline: {
    GoChangeWidgetEntry(date: Date(), data: .placeholder)
}
