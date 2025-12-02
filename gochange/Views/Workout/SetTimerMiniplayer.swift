import SwiftUI
import Combine

// MARK: - Set Timer Miniplayer
struct SetTimerMiniplayer: View {
    let timerState: SetTimerState
    let currentHeartRate: Double?
    let accentColor: Color
    let onPause: () -> Void
    let onResume: () -> Void
    let onStop: () -> Void
    
    @State private var elapsed: TimeInterval = 0
    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle/Drag Indicator
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 12)
            
            HStack(spacing: 16) {
                // Timer Display
                VStack(alignment: .leading, spacing: 4) {
                    Text(timerState.exerciseName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        Text("Set \(timerState.setNumber)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        
                        Text(elapsed.formattedSetDuration)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(accentColor)
                            .monospacedDigit()
                    }
                }
                
                Spacer()
                
                // Heart Rate Display
                if let heartRate = currentHeartRate {
                    VStack(spacing: 2) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#FF3B30"))
                        
                        Text("\(Int(heartRate))")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    .frame(width: 50)
                }
                
                // Control Buttons
                HStack(spacing: 12) {
                    // Play/Pause Button
                    Button {
                        if timerState.isPaused {
                            onResume()
                        } else {
                            onPause()
                        }
                    } label: {
                        Image(systemName: timerState.isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(accentColor)
                            )
                            .shadow(color: accentColor.opacity(0.3), radius: 8, y: 4)
                    }
                    
                    // Stop Button
                    Button {
                        onStop()
                    } label: {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(Color(hex: "#FF3B30"))
                            )
                            .shadow(color: Color(hex: "#FF3B30").opacity(0.3), radius: 8, y: 4)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.12), radius: 20, x: 0, y: -5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        )
        .onReceive(timer) { _ in
            if !timerState.isPaused {
                elapsed = timerState.elapsedTime
            }
        }
        .onAppear {
            elapsed = timerState.elapsedTime
        }
    }
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

#Preview {
    VStack {
        Spacer()
        SetTimerMiniplayer(
            timerState: SetTimerState(
                startTime: Date().addingTimeInterval(-45),
                exerciseName: "Bench Press",
                exerciseIndex: 0,
                setIndex: 0,
                setNumber: 1,
                isPaused: false
            ),
            currentHeartRate: 142,
            accentColor: Color(hex: "#7CB9A8"),
            onPause: {},
            onResume: {},
            onStop: {}
        )
    }
    .background(Color.gray.opacity(0.1))
}
