import SwiftUI
import Combine

struct FloatingRestTimerBanner: View {
    let timerState: RestTimerState
    let onTap: () -> Void
    let onDismiss: () -> Void

    @State private var remainingTime: TimeInterval = 0
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var progress: Double {
        // Estimate total duration based on remaining time
        let totalDuration: TimeInterval = remainingTime > 120 ? 180 : 90
        return max(0, min(1, remainingTime / totalDuration))
    }

    private var timeString: String {
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Timer Icon with Progress Ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 3)
                        .frame(width: 36, height: 36)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 36, height: 36)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: progress)

                    Image(systemName: "timer")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }

                // Timer Info
                VStack(alignment: .leading, spacing: 2) {
                    Text("Rest Timer")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.9))

                    Text("\(timerState.exerciseName) - \(timerState.setContext)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }

                Spacer()

                // Countdown
                Text(timeString)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .monospacedDigit()

                // Dismiss Button
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 24, height: 24)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [Color(hex: "#5B7FFF"), Color(hex: "#7B92FF")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: Color(hex: "#5B7FFF").opacity(0.4), radius: 12, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .onReceive(timer) { _ in
            remainingTime = timerState.remainingTime
        }
        .onAppear {
            remainingTime = timerState.remainingTime
        }
    }
}
