import SwiftUI
import Combine

struct MiniPlayerView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var elapsed: TimeInterval = 0
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 16) {
                // Workout Icon
                if let session = workoutManager.currentSession {
                    Circle()
                        .fill(AppConstants.WorkoutColors.color(for: session.workoutDayName).opacity(0.2))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text(session.workoutDayName.prefix(1))
                                .fontWeight(.bold)
                                .foregroundColor(AppConstants.WorkoutColors.color(for: session.workoutDayName))
                        )
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(workoutManager.currentSession?.workoutDayName ?? "Workout")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(elapsed.formattedDuration)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
                
                Spacer()
                
                // Resume Button (Chevron Up)
                Image(systemName: "chevron.up")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(8)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppTheme.cardBackground)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation {
                    workoutManager.resume()
                }
            }
        }
        .background(AppTheme.cardBackground)
        .onReceive(timer) { _ in
            if let startTime = workoutManager.startTime {
                elapsed = Date().timeIntervalSince(startTime)
            }
        }
    }
}

#Preview {
    MiniPlayerView()
        .environmentObject(WorkoutManager())
}
