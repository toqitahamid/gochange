import SwiftUI
import AVFoundation

/// A rest timer overlay that can be shown during workouts
struct RestTimerView: View {
    @Binding var isPresented: Bool
    
    @AppStorage("restTimerDuration") private var defaultDuration: Double = 90
    @AppStorage("hapticFeedback") private var hapticFeedbackEnabled: Bool = true
    
    @State private var remainingTime: TimeInterval = 0
    @State private var isRunning = false
    @State private var timer: Timer?
    
    var body: some View {
        VStack(spacing: 24) {
            // Timer Display
            ZStack {
                // Background Circle
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                    .frame(width: 200, height: 200)
                
                // Progress Circle
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(progressColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: remainingTime)
                
                // Time Text
                VStack(spacing: 4) {
                    Text(timeString)
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                    
                    Text(isRunning ? "REST" : "READY")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Duration Presets
            HStack(spacing: 16) {
                ForEach([60, 90, 120, 180], id: \.self) { seconds in
                    Button {
                        setDuration(TimeInterval(seconds))
                    } label: {
                        Text("\(seconds)s")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(remainingTime == TimeInterval(seconds) ? .white : .primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(remainingTime == TimeInterval(seconds) ? AppTheme.accent : Color.gray.opacity(0.1))
                            .cornerRadius(20)
                    }
                }
            }
            
            // Control Buttons
            HStack(spacing: 24) {
                // Reset Button
                Button {
                    resetTimer()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .frame(width: 60, height: 60)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
                
                // Start/Pause Button
                Button {
                    toggleTimer()
                } label: {
                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                        .font(.title)
                        .foregroundColor(.white)
                        .frame(width: 80, height: 80)
                        .background(isRunning ? Color.orange : AppTheme.accent)
                        .clipShape(Circle())
                }
                
                // Close Button
                Button {
                    stopTimer()
                    isPresented = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .frame(width: 60, height: 60)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
            }
        }
        .padding(32)
        .background(AppTheme.cardBackground)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
        .onAppear {
            remainingTime = defaultDuration
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
        // Start Live Activity
        RestTimerActivityManager.shared.start(endTime: Date().addingTimeInterval(remainingTime))
        
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

