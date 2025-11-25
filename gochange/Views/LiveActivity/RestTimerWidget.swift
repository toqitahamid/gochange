import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Rest Timer Widget

struct RestTimerWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RestTimerAttributes.self) { context in
            RestTimerLockScreenView(context: context)
        } dynamicIsland: { context in
            let safeEndTime = max(context.state.endTime, Date().addingTimeInterval(1))
            
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.cyan.opacity(0.2))
                                .frame(width: 44, height: 44)
                            Image(systemName: "pause.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.cyan)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("REST")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.cyan)
                            Text("Timer")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.leading, 4)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: Date()...safeEndTime, countsDown: true)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.white)
                        .padding(.trailing, 4)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(
                        timerInterval: Date()...safeEndTime,
                        countsDown: true
                    )
                    .progressViewStyle(.linear)
                    .tint(.cyan)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 4)
                }
            } compactLeading: {
                ZStack {
                    Circle()
                        .fill(Color.cyan.opacity(0.3))
                        .frame(width: 24, height: 24)
                    Image(systemName: "pause.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.cyan)
                }
            } compactTrailing: {
                Text(timerInterval: Date()...safeEndTime, countsDown: true)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.cyan)
                    .frame(minWidth: 44)
            } minimal: {
                ZStack {
                    Circle()
                        .strokeBorder(Color.cyan, lineWidth: 2)
                    Image(systemName: "pause.fill")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.cyan)
                }
            }
        }
    }
}

// MARK: - Rest Timer Lock Screen View

struct RestTimerLockScreenView: View {
    let context: ActivityViewContext<RestTimerAttributes>
    
    private var safeEndTime: Date {
        max(context.state.endTime, Date().addingTimeInterval(1))
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.cyan, Color.cyan.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Image(systemName: "pause.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Timer Info
            VStack(alignment: .leading, spacing: 4) {
                Text("REST TIMER")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.cyan)
                    .tracking(1)

                Text(timerInterval: Date()...safeEndTime, countsDown: true)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Progress Ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 4)
                    .frame(width: 44, height: 44)
                
                ProgressView(
                    timerInterval: Date()...safeEndTime,
                    countsDown: true
                ) {
                    EmptyView()
                }
                .progressViewStyle(.circular)
                .tint(.cyan)
                .scaleEffect(1.2)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .activityBackgroundTint(Color.black.opacity(0.85))
    }
}

// MARK: - Workout Activity Widget

struct WorkoutActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            WorkoutLockScreenView(context: context)
        } dynamicIsland: { context in
            let color = Color(hex: context.attributes.workoutColor) ?? .orange
            
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(color.opacity(0.2))
                                .frame(width: 44, height: 44)
                            Image(systemName: "dumbbell.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(color)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(context.attributes.workoutName.uppercased())
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(color)
                                .lineLimit(1)
                            Text("\(context.state.exerciseCount) exercises")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.leading, 4)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(context.state.startTime, style: .timer)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(.white)
                        
                        Text("\(context.state.completedSets)/\(context.state.totalSets) sets")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.trailing, 4)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 6)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(color)
                                .frame(
                                    width: context.state.totalSets > 0
                                        ? geometry.size.width * CGFloat(context.state.completedSets) / CGFloat(context.state.totalSets)
                                        : 0,
                                    height: 6
                                )
                        }
                    }
                    .frame(height: 6)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 4)
                }
            } compactLeading: {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.3))
                        .frame(width: 24, height: 24)
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(color)
                }
            } compactTrailing: {
                Text(context.state.startTime, style: .timer)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(color)
                    .frame(minWidth: 44)
            } minimal: {
                ZStack {
                    Circle()
                        .strokeBorder(color, lineWidth: 2)
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(color)
                }
            }
        }
    }
}

// MARK: - Workout Lock Screen View

struct WorkoutLockScreenView: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>
    
    private var workoutColor: Color {
        Color(hex: context.attributes.workoutColor) ?? .orange
    }
    
    private var progressPercent: Double {
        guard context.state.totalSets > 0 else { return 0 }
        return Double(context.state.completedSets) / Double(context.state.totalSets)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon with progress ring
            ZStack {
                // Background circle
                Circle()
                    .stroke(workoutColor.opacity(0.3), lineWidth: 4)
                    .frame(width: 50, height: 50)
                
                // Progress arc
                Circle()
                    .trim(from: 0, to: progressPercent)
                    .stroke(workoutColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
                
                // Center icon
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(workoutColor)
            }
            
            // Workout Info
            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.workoutName.uppercased())
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(workoutColor)
                    .tracking(1)
                    .lineLimit(1)
                
                Text(context.state.startTime, style: .timer)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Stats
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Text("\(context.state.completedSets)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(workoutColor)
                    Text("/\(context.state.totalSets)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Text("sets done")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .activityBackgroundTint(Color.black.opacity(0.85))
    }
}

// MARK: - Color Extension for Hex

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}
