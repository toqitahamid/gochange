import SwiftUI

struct WorkoutListView: View {
    @EnvironmentObject var workoutManager: WatchWorkoutManager
    @EnvironmentObject var connectivityManager: WatchConnectivityManager
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.black.ignoresSafeArea()
                
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
        ScrollView {
            VStack(spacing: Spacing.lg) {
                ForEach(connectivityManager.workoutDays) { workoutDay in
                    NavigationLink(destination: WorkoutDetailView(workoutDay: workoutDay)) {
                        WorkoutDayCard(workoutDay: workoutDay) {
                            // Empty action since NavigationLink handles tap
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.lg)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: Spacing.xl) {
            Image(systemName: "iphone.and.arrow.forward")
                .font(.system(size: 50))
                .foregroundColor(.accentGreen)
                .symbolEffect(.pulse, options: .repeating)
            
            VStack(spacing: Spacing.sm) {
                Text("Open GoChange")
                    .font(.titlePrimary)
                    .foregroundColor(.white)
                
                Text("Sync workouts to get started")
                    .font(.bodySecondary)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Color.accentGreen.opacity(0.1), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

// MARK: - Workout Day Card

struct WorkoutDayCard: View {
    let workoutDay: WatchWorkoutDay
    let onStart: () -> Void
    
    var body: some View {
        Button(action: onStart) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Header
                HStack {
                    Circle()
                        .fill(Color(hex: workoutDay.colorHex))
                        .frame(width: 8, height: 8)
                        .shadow(color: Color(hex: workoutDay.colorHex).opacity(0.5), radius: 4)
                    
                    Text("DAY \(workoutDay.dayNumber)")
                        .font(.captionPrimary)
                        .foregroundColor(.white.opacity(0.8))
                        .textCase(.uppercase)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.captionSecondary)
                        .foregroundColor(.white.opacity(0.4))
                }
                
                // Content
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(workoutDay.name)
                        .font(.titlePrimary)
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "dumbbell.fill")
                        Text("\(workoutDay.exercises.count) exercises")
                    }
                    .font(.captionPrimary)
                    .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                ZStack {
                    // Glass background
                    Color.glassBackground
                    
                    // Subtle gradient overlay
                    Color.workoutGradient(hex: workoutDay.colorHex, style: .subtle)
                        .opacity(0.3)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xl))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.xl)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}



#Preview {
    WorkoutListView()
        .environmentObject(WatchWorkoutManager())
        .environmentObject(WatchConnectivityManager.shared)
}
