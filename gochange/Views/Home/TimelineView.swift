import SwiftUI

struct TimelineView: View {
    let workouts: [WorkoutSession]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Timeline")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.leading, 4)
            
            if workouts.isEmpty {
                Text("No recent activity")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(workouts) { workout in
                        NavigationLink(destination: SessionDetailView(session: workout)) {
                            TimelineItem(workout: workout)
                        }
                        .buttonStyle(PlainButtonStyle()) // Keep the custom card style
                    }
                }
            }
        }
    }
}

struct TimelineItem: View {
    let workout: WorkoutSession
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon with Badge
            ZStack(alignment: .bottomTrailing) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    
                    Image(systemName: "figure.strengthtraining.traditional")
                        .foregroundColor(.orange)
                        .font(.system(size: 24))
                }
                .frame(width: 56, height: 56)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
                
                // Badge (Set Count)
                Text("\(totalSets)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                            .overlay(
                                Capsule()
                                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .offset(x: 4, y: 4)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.workoutDayName.isEmpty ? "Strength Training" : workout.workoutDayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(workout.date.formatted(date: .numeric, time: .shortened))
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Arrow
            Image(systemName: "arrow.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.gray.opacity(0.6))
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                )
        }
    }
    
    private var totalSets: Int {
        workout.exerciseLogs.reduce(0) { $0 + $1.sets.filter { $0.isCompleted }.count }
    }
}

#Preview {
    ZStack {
        Color(hex: "#F2F2F7").ignoresSafeArea()
        TimelineView(workouts: [])
            .padding()
    }
}
