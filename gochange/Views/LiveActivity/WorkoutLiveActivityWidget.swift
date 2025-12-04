import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Premium Color Palette

private struct LiveActivityColors {
    // Premium gradient colors
    static let workoutGradientStart = Color(red: 1.0, green: 0.42, blue: 0.21)  // #FF6B35
    static let workoutGradientEnd = Color(red: 0.97, green: 0.58, blue: 0.12)   // #F7931E
    
    // Rest timer accent
    static let restAccent = Color(red: 0.0, green: 0.83, blue: 0.67)  // #00D4AA
    
    // Premium dark background
    static let darkBackground = Color(red: 0.06, green: 0.06, blue: 0.09)  // #0F0F17
    static let cardSurface = Color(red: 0.1, green: 0.1, blue: 0.14)       // #1A1A24
}

// MARK: - Unified Workout Widget (includes Rest Timer)

struct WorkoutActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            UnifiedLockScreenView(context: context)
        } dynamicIsland: { context in
            let workoutColor = Color(hex: context.attributes.workoutColor) ?? LiveActivityColors.workoutGradientStart
            let isResting = context.state.restEndTime != nil
            let restEndTime = context.state.restEndTime ?? Date()
            let safeRestEndTime = max(restEndTime, Date().addingTimeInterval(1))
            
            return DynamicIsland {
                // MARK: - Expanded Leading
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        // Icon with progress ring
                        ZStack {
                            // Glow
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [workoutColor.opacity(0.5), workoutColor.opacity(0.0)],
                                        center: .center,
                                        startRadius: 12,
                                        endRadius: 22
                                    )
                                )
                                .frame(width: 40, height: 40)
                            
                            // Progress ring
                            Circle()
                                .stroke(workoutColor.opacity(0.3), lineWidth: 2.5)
                                .frame(width: 32, height: 32)
                            
                            Circle()
                                .trim(from: 0, to: progressPercent(context: context))
                                .stroke(workoutColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                                .frame(width: 32, height: 32)
                                .rotationEffect(.degrees(-90))
                            
                            Image(systemName: isResting ? "timer" : "dumbbell.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(isResting ? LiveActivityColors.restAccent : workoutColor)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(context.attributes.workoutName.uppercased())
                                .font(.system(size: 10, weight: .heavy))
                                .tracking(0.8)
                                .foregroundColor(workoutColor)
                                .lineLimit(1)
                            
                            if isResting {
                                Text("REST • Set \(context.state.restAfterSetNumber ?? 1)")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(LiveActivityColors.restAccent)
                            } else if let exercise = context.state.currentExerciseName {
                                Text(exercise)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                
                // MARK: - Expanded Trailing
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 3) {
                        if isResting {
                            // Rest countdown (prominent)
                            Text(timerInterval: Date()...safeRestEndTime, countsDown: true)
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundColor(LiveActivityColors.restAccent)
                            
                            // Workout time (small)
                            Text(context.state.startTime, style: .timer)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .monospacedDigit()
                                .foregroundColor(.white.opacity(0.5))
                        } else {
                            // Workout time (prominent)
                            Text(context.state.startTime, style: .timer)
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundColor(context.state.isPaused ? .white.opacity(0.5) : .white)
                            
                            // Sets progress
                            HStack(spacing: 2) {
                                Text("\(context.state.completedSets)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(workoutColor)
                                Text("/\(context.state.totalSets)")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                    }
                }
                
                // MARK: - Expanded Bottom
                DynamicIslandExpandedRegion(.bottom) {
                    if isResting {
                        // Rest timer progress bar
                        ProgressView(
                            timerInterval: Date()...safeRestEndTime,
                            countsDown: true
                        ) { EmptyView() }
                        .progressViewStyle(.linear)
                        .tint(LiveActivityColors.restAccent)
                        .frame(height: 4)
                        .padding(.horizontal, 4)
                        .padding(.bottom, 4)
                    } else {
                        // Sets progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white.opacity(0.15))
                                    .frame(height: 4)
                                
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(
                                        LinearGradient(
                                            colors: [workoutColor, workoutColor.opacity(0.7)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(
                                        width: context.state.totalSets > 0
                                            ? geometry.size.width * CGFloat(context.state.completedSets) / CGFloat(context.state.totalSets)
                                            : 0,
                                        height: 4
                                    )
                            }
                        }
                        .frame(height: 4)
                        .padding(.horizontal, 4)
                        .padding(.bottom, 4)
                    }
                }
                
            } compactLeading: {
                // Simple icon with progress ring - constrained to fit Dynamic Island
                ZStack {
                    // Background ring
                    Circle()
                        .stroke(
                            (isResting ? LiveActivityColors.restAccent : workoutColor).opacity(0.3),
                            lineWidth: 2
                        )
                    
                    // Progress ring
                    Circle()
                        .trim(from: 0, to: isResting ? 1.0 : progressPercent(context: context))
                        .stroke(
                            isResting ? LiveActivityColors.restAccent : workoutColor,
                            style: StrokeStyle(lineWidth: 2, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                    
                    // Center icon
                    Image(systemName: isResting ? "pause.fill" : "dumbbell.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(isResting ? LiveActivityColors.restAccent : workoutColor)
                }
                .frame(width: 24, height: 24)
            } compactTrailing: {
                // Timer text only - minimal width
                if isResting {
                    Text(timerInterval: Date()...safeRestEndTime, countsDown: true)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(LiveActivityColors.restAccent)
                } else {
                    Text(context.state.startTime, style: .timer)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(context.state.isPaused ? workoutColor.opacity(0.5) : workoutColor)
                }
            } minimal: {
                // Minimal circular view
                ZStack {
                    Circle()
                        .fill(isResting ? LiveActivityColors.restAccent : workoutColor)
                    
                    Image(systemName: isResting ? "pause.fill" : "dumbbell.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    private func progressPercent(context: ActivityViewContext<WorkoutActivityAttributes>) -> Double {
        guard context.state.totalSets > 0 else { return 0 }
        return Double(context.state.completedSets) / Double(context.state.totalSets)
    }
}

// MARK: - Unified Lock Screen View

struct UnifiedLockScreenView: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>
    
    private var workoutColor: Color {
        Color(hex: context.attributes.workoutColor) ?? LiveActivityColors.workoutGradientStart
    }
    
    private var isResting: Bool {
        context.state.restEndTime != nil
    }
    
    private var safeRestEndTime: Date {
        max(context.state.restEndTime ?? Date(), Date().addingTimeInterval(1))
    }
    
    private var progressPercent: Double {
        guard context.state.totalSets > 0 else { return 0 }
        return Double(context.state.completedSets) / Double(context.state.totalSets)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // MARK: - Left: Progress Ring + Icon
            ZStack {
                // Background ring
                Circle()
                    .stroke(workoutColor.opacity(0.2), lineWidth: 4)
                    .frame(width: 48, height: 48)
                
                // Progress arc
                Circle()
                    .trim(from: 0, to: progressPercent)
                    .stroke(
                        LinearGradient(
                            colors: [workoutColor, workoutColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 48, height: 48)
                    .rotationEffect(.degrees(-90))
                
                // Center icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isResting
                                    ? [LiveActivityColors.restAccent, LiveActivityColors.restAccent.opacity(0.7)]
                                    : [workoutColor, workoutColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: isResting ? "timer" : "dumbbell.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            // MARK: - Center: Info
            VStack(alignment: .leading, spacing: 3) {
                // Workout name + status
                HStack(spacing: 6) {
                    Text(context.attributes.workoutName.uppercased())
                        .font(.system(size: 10, weight: .heavy))
                        .tracking(0.8)
                        .foregroundColor(workoutColor)
                    
                    if isResting {
                        Text("REST")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(LiveActivityColors.restAccent)
                            .cornerRadius(4)
                    } else if context.state.isPaused {
                        Text("PAUSED")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                
                // Main time display
                if isResting {
                    Text(timerInterval: Date()...safeRestEndTime, countsDown: true)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(LiveActivityColors.restAccent)
                } else {
                    Text(context.state.startTime, style: .timer)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(context.state.isPaused ? .white.opacity(0.5) : .white)
                }
                
                // Secondary info
                if let exercise = context.state.currentExerciseName {
                    Text(exercise)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // MARK: - Right: Stats
            VStack(alignment: .trailing, spacing: 4) {
                // Sets progress
                HStack(spacing: 2) {
                    Text("\(context.state.completedSets)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(workoutColor)
                    Text("/\(context.state.totalSets)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Text("sets")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                
                // Workout time when resting
                if isResting {
                    Text(context.state.startTime, style: .timer)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.white.opacity(0.4))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .activityBackgroundTint(LiveActivityColors.darkBackground)
    }
}

// MARK: - Color Extension

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
