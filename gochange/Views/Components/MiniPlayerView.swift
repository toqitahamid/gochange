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
    
    private var completedSets: Int {
        workoutManager.completedSetsCount
    }
    
    private var totalSets: Int {
        workoutManager.totalSetsCount
    }
    
    var body: some View {
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
                        Text(workoutManager.currentWorkoutDay?.name ?? "Workout")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        // Live indicator
                        Circle()
                            .fill(Color(hex: "#00D4AA"))
                            .frame(width: 6, height: 6)
                    }
                    
                    HStack(spacing: 8) {
                        Text(elapsed.formattedDuration)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("\(completedSets)/\(totalSets) sets")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
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
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -2)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.15), lineWidth: 1)
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
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
