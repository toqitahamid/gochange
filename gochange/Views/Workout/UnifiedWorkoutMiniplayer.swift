import SwiftUI
import Combine

// MARK: - Unified Workout Miniplayer
struct UnifiedWorkoutMiniplayer: View {
    let workoutDayName: String
    let exerciseName: String?
    let workoutStartTime: Date
    let workoutIsPaused: Bool
    let setTimerState: SetTimerState?
    let restTimerState: RestTimerState?
    let currentHeartRate: Double?
    let accentColor: Color
    
    let onExpand: () -> Void
    let onPauseSession: () -> Void
    let onResumeSession: () -> Void
    let onStopSet: () -> Void
    
    @State private var workoutElapsed: TimeInterval = 0
    @State private var setElapsed: TimeInterval = 0
    @State private var restRemaining: TimeInterval = 0
    
    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Content
            VStack(spacing: 12) {
                // Top Row: Workout Info
                HStack(spacing: 12) {
                    // Workout Day Badge
                    Text(workoutDayName.uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(accentColor)
                        )
                    
                    // Exercise Name
                    if let exercise = exerciseName {
                        Text(exercise)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Heart Rate
                    if let heartRate = currentHeartRate {
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 11))
                                .foregroundColor(Color(hex: "#FF3B30"))
                            
                            Text("\(Int(heartRate))")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color(hex: "#FF3B30").opacity(0.1))
                        )
                    }
                }
                
                // Timer Row
                HStack(spacing: 16) {
                    // Workout Time
                    VStack(alignment: .leading, spacing: 2) {
                        Text("WORKOUT")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(1)
                            .foregroundColor(.secondary)
                        
                        Text(workoutElapsed.formattedSetDuration)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(workoutIsPaused ? .secondary : .primary)
                            .monospacedDigit()
                    }
                    
                    // Set Time (if active)
                    if let setTimer = setTimerState {
                        Divider()
                            .frame(height: 30)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            // Show Set Type or Set Number
                            Text(setTimer.setType == .normal ? "SET \(setTimer.setNumber)" : setTimer.setType.rawValue.uppercased())
                                .font(.system(size: 9, weight: .bold))
                                .tracking(1)
                                .foregroundColor(.secondary)
                            
                            Text(setElapsed.formattedSetDuration)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(setTimer.isPaused ? .secondary : accentColor)
                                .monospacedDigit()
                        }
                    }
                    
                    // Rest Timer (if active)
                    if let restTimer = restTimerState, !restTimer.isExpired {
                        Divider()
                            .frame(height: 30)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("REST")
                                .font(.system(size: 9, weight: .bold))
                                .tracking(1)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 4) {
                                Image(systemName: "timer")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "#00D4AA"))
                                
                                Text(restRemaining.formattedSetDuration)
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(hex: "#00D4AA"))
                                    .monospacedDigit()
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Control Buttons
                    HStack(spacing: 10) {
                        // Play/Pause Button
                        Button {
                            if workoutIsPaused {
                                onResumeSession()
                            } else {
                                onPauseSession()
                            }
                        } label: {
                            Image(systemName: workoutIsPaused ? "play.fill" : "pause.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle()
                                        .fill(accentColor)
                                )
                                .shadow(color: accentColor.opacity(0.3), radius: 6, y: 3)
                        }
                        
                        // Stop Button (only when set is active)
                        if setTimerState != nil {
                            Button {
                                onStopSet()
                            } label: {
                                Image(systemName: "stop.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 40, height: 40)
                                    .background(
                                        Circle()
                                            .fill(Color(hex: "#FF3B30"))
                                    )
                                    .shadow(color: Color(hex: "#FF3B30").opacity(0.3), radius: 6, y: 3)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }

        .background(
            Rectangle()
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 0, x: 0, y: -0.5) // Top border effect via shadow
        )
        // Add top border
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color(uiColor: .separator))
                .frame(height: 0.5)
        }
        .onTapGesture {
            onExpand()
        }
        .onReceive(timer) { _ in
            if !workoutIsPaused {
                workoutElapsed = Date().timeIntervalSince(workoutStartTime)
            }
            
            if let setTimer = setTimerState, !setTimer.isPaused {
                setElapsed = setTimer.elapsedTime
            }
            
            if let restTimer = restTimerState {
                restRemaining = max(0, restTimer.remainingTime)
            }
        }
        .onAppear {
            workoutElapsed = Date().timeIntervalSince(workoutStartTime)
            if let setTimer = setTimerState {
                setElapsed = setTimer.elapsedTime
            }
            if let restTimer = restTimerState {
                restRemaining = max(0, restTimer.remainingTime)
            }
        }
    }
}

#Preview {
    VStack {
        Spacer()
        
        // Preview with set timer
        UnifiedWorkoutMiniplayer(
            workoutDayName: "Push",
            exerciseName: "Bench Press",
            workoutStartTime: Date().addingTimeInterval(-450),
            workoutIsPaused: false,
            setTimerState: SetTimerState(
                startTime: Date().addingTimeInterval(-45),
                exerciseName: "Bench Press",
                exerciseIndex: 0,
                setIndex: 2,
                setNumber: 3,
                setType: .normal
            ),
            restTimerState: nil,
            currentHeartRate: 142,
            accentColor: Color(hex: "#7CB9A8"),
            onExpand: {},
            onPauseSession: {},
            onResumeSession: {},
            onStopSet: {}
        )
        .padding(.horizontal, 20)
    }
    .background(Color.gray.opacity(0.1))
}

// MARK: - TimeInterval Extension for Set Duration Formatting
extension TimeInterval {
    var formattedSetDuration: String {
        let totalSeconds = Int(self)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
