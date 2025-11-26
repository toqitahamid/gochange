import SwiftUI
import Combine

struct MiniPlayerView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var elapsed: TimeInterval = 0
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private var accentColor: Color {
        if let workoutDay = workoutManager.currentWorkoutDay {
            return Color(hex: workoutDay.colorHex)
        }
        return AppTheme.accent
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top accent line
            Rectangle()
                .fill(accentColor)
                .frame(height: 2)
            
            HStack(spacing: 14) {
                // Workout Icon with pulse animation
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [accentColor, accentColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                    
                    Text(workoutManager.currentSession?.workoutDayName.prefix(1) ?? "W")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(workoutManager.currentSession?.workoutDayName ?? "Workout")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        
                        // Live indicator
                        Circle()
                            .fill(Color(hex: "#00D4AA"))
                            .frame(width: 6, height: 6)
                    }
                    
                    HStack(spacing: 8) {
                        Text(elapsed.formattedDuration)
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(.gray)
                        
                        Text("•")
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("\(workoutManager.completedSetsCount)/\(workoutManager.totalSetsCount) sets")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // Resume Button
                HStack(spacing: 6) {
                    Text("Resume")
                        .font(.system(size: 14, weight: .semibold))
                    Image(systemName: "chevron.up")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(accentColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(accentColor.opacity(0.15))
                .cornerRadius(20)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Color(hex: "#0A1628")
            )
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.3)) {
                    workoutManager.resume()
                }
            }
        }
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
