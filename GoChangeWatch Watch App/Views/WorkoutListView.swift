import SwiftUI

struct WorkoutListView: View {
    @EnvironmentObject var workoutManager: WatchWorkoutManager
    @EnvironmentObject var connectivityManager: WatchConnectivityManager
    
    var body: some View {
        NavigationStack {
            Group {
                if connectivityManager.workoutDays.isEmpty {
                    emptyState
                } else {
                    workoutList
                }
            }
            .navigationTitle("GoChange")
        }
    }
    
    // MARK: - Workout List
    
    private var workoutList: some View {
        List(connectivityManager.workoutDays) { workoutDay in
            WorkoutDayRow(workoutDay: workoutDay) {
                workoutManager.startWorkout(workoutDay: workoutDay)
            }
        }
        .listStyle(.carousel)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "iphone.and.arrow.forward")
                .font(.system(size: 36))
                .foregroundColor(.gray)
            
            Text("Open GoChange on iPhone")
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Text("Sync workouts to get started")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Workout Day Row

struct WorkoutDayRow: View {
    let workoutDay: WatchWorkoutDay
    let onStart: () -> Void
    
    var body: some View {
        Button(action: onStart) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Circle()
                        .fill(Color(hex: workoutDay.colorHex))
                        .frame(width: 12, height: 12)
                    
                    Text("Day \(workoutDay.dayNumber)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                Text(workoutDay.name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack {
                    Image(systemName: "dumbbell.fill")
                        .font(.caption2)
                    Text("\(workoutDay.exercises.count) exercises")
                        .font(.caption2)
                }
                .foregroundColor(.gray)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Color Extension for Watch

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    WorkoutListView()
        .environmentObject(WatchWorkoutManager())
        .environmentObject(WatchConnectivityManager.shared)
}

