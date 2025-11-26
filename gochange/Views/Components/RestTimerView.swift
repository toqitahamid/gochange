import SwiftUI
import AVFoundation
import ActivityKit

/// A rest timer overlay that can be shown during workouts
struct RestTimerView: View {
    @Binding var isPresented: Bool
    
    @AppStorage("restTimerDuration") private var defaultDuration: Double = 90
    @AppStorage("hapticFeedback") private var hapticFeedbackEnabled: Bool = true
    
    @State private var remainingTime: TimeInterval = 0
    @State private var isRunning = false
    @State private var timer: Timer?
    
    private let timerAccentColor = Color(hex: "#00D4AA")
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            HStack {
                Text("REST TIMER")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button {
                    stopTimer()
                    isPresented = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gray)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            
            // Timer Display
            ZStack {
                // Background Circle
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 10)
                    .frame(width: 220, height: 220)
                
                // Progress Circle
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [progressColor, progressColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 220, height: 220)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: remainingTime)
                    .shadow(color: progressColor.opacity(0.4), radius: 10)
                
                // Time Text
                VStack(spacing: 8) {
                    Text(timeString)
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(isRunning ? "RESTING" : "READY")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.5)
                        .foregroundColor(isRunning ? progressColor : .gray)
                }
            }
            
            // Duration Presets
            HStack(spacing: 12) {
                ForEach([60, 90, 120, 180], id: \.self) { seconds in
                    Button {
                        setDuration(TimeInterval(seconds))
                    } label: {
                        Text("\(seconds)s")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(remainingTime == TimeInterval(seconds) ? .white : .gray)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(remainingTime == TimeInterval(seconds) ? timerAccentColor : Color.white.opacity(0.08))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(remainingTime == TimeInterval(seconds) ? timerAccentColor.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
                            )
                    }
                }
            }
            
            // Control Buttons
            HStack(spacing: 32) {
                // Reset Button
                Button {
                    resetTimer()
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                        
                        Text("Reset")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }
                
                // Start/Pause Button
                Button {
                    toggleTimer()
                } label: {
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: isRunning ? [Color(hex: "#FF6B35"), Color(hex: "#F7931E")] : [timerAccentColor, timerAccentColor.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 72, height: 72)
                                .shadow(color: (isRunning ? Color(hex: "#FF6B35") : timerAccentColor).opacity(0.5), radius: 12, y: 4)
                            
                            Image(systemName: isRunning ? "pause.fill" : "play.fill")
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundColor(.white)
                                .offset(x: isRunning ? 0 : 2)
                        }
                        
                        Text(isRunning ? "Pause" : "Start")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }
                
                // Skip Button
                Button {
                    timerComplete()
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                        
                        Text("Skip")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#1a1a2e"), Color(hex: "#16213e")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .onAppear {
            // Check for active Live Activity first
            // Check for active Live Activity first
            if let activity = RestTimerActivityManager.shared.activity,
               case .active = activity.activityState {
                
                let endTime = activity.content.state.endTime
                let remaining = endTime.timeIntervalSinceNow
                if remaining > 0 {
                    remainingTime = remaining
                    startTimer() // This will resume the timer UI
                } else {
                    remainingTime = defaultDuration
                }
            } else {
                remainingTime = defaultDuration
            }
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    // MARK: - Computed Properties
    
    private var progress: Double {
        guard defaultDuration > 0 else { return 0 }
        return remainingTime / defaultDuration
    }
    
    private var progressColor: Color {
        if remainingTime <= 10 {
            return .red
        } else if remainingTime <= 30 {
            return .orange
        }
        return AppTheme.accent
    }
    
    private var timeString: String {
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Timer Methods
    
    private func toggleTimer() {
        if isRunning {
            pauseTimer()
        } else {
            startTimer()
        }
    }
    
    private func startTimer() {
        isRunning = true
        let endTime = Date().addingTimeInterval(remainingTime)
        
        // Start Live Activity
        RestTimerActivityManager.shared.start(endTime: endTime)
        
        // Schedule background notification
        NotificationService.shared.scheduleRestTimerNotification(endTime: endTime)
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remainingTime > 0 {
                remainingTime -= 1
            } else {
                timerComplete()
            }
        }
    }
    
    private func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        // End Live Activity
        RestTimerActivityManager.shared.end()
        // Cancel background notification
        NotificationService.shared.cancelRestTimerNotification()
    }
    
    private func stopTimer() {
        pauseTimer()
        remainingTime = defaultDuration
    }
    
    private func resetTimer() {
        pauseTimer()
        remainingTime = defaultDuration
    }
    
    private func setDuration(_ duration: TimeInterval) {
        pauseTimer()
        remainingTime = duration
    }
    
    private func timerComplete() {
        pauseTimer()
        playCompletionSound()
        if hapticFeedbackEnabled {
            triggerHaptic()
        }
        remainingTime = defaultDuration
    }
    
    private func playCompletionSound() {
        AudioServicesPlaySystemSound(SystemSoundID(1005))
    }
    
    private func triggerHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

// MARK: - Rest Timer Button (for use in workout view)
struct RestTimerButton: View {
    @State private var showingTimer = false
    
    var body: some View {
        Button {
            showingTimer = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "timer")
                Text("Rest")
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(AppTheme.accent)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(AppTheme.accent.opacity(0.1))
            .cornerRadius(20)
        }
        .sheet(isPresented: $showingTimer) {
            RestTimerView(isPresented: $showingTimer)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    RestTimerView(isPresented: .constant(true))
}

