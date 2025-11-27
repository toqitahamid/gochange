import SwiftUI

struct WorkoutDetailView: View {
    let workoutDay: WatchWorkoutDay
    @EnvironmentObject var workoutManager: WatchWorkoutManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                // Header
                VStack(spacing: Spacing.sm) {
                    Circle()
                        .fill(Color(hex: workoutDay.colorHex))
                        .frame(width: 12, height: 12)
                        .shadow(color: Color(hex: workoutDay.colorHex).opacity(0.5), radius: 4)
                    
                    Text("DAY \(workoutDay.dayNumber)")
                        .font(.captionPrimary)
                        .foregroundColor(.white.opacity(0.8))
                        .tracking(1)
                    
                    Text(workoutDay.name)
                        .font(.titlePrimary)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, Spacing.md)
                
                // Stats
                HStack(spacing: Spacing.lg) {
                    VStack(spacing: Spacing.xs) {
                        Text("\(workoutDay.exercises.count)")
                            .font(.titleSecondary)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("Exercises")
                            .font(.captionSecondary)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Divider()
                        .overlay(Color.white.opacity(0.2))
                    
                    VStack(spacing: Spacing.xs) {
                        Text("~45")
                            .font(.titleSecondary)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("Minutes")
                            .font(.captionSecondary)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.vertical, Spacing.md)
                .frame(maxWidth: .infinity)
                .glassCard(opacity: 0.1)
                
                // Exercise List
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("EXERCISES")
                        .font(.captionPrimary)
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(1)
                        .padding(.leading, Spacing.xs)
                    
                    ForEach(Array(workoutDay.exercises.enumerated()), id: \.element.id) { index, exercise in
                        HStack(spacing: Spacing.md) {
                            Text("\(index + 1)")
                                .font(.captionPrimary)
                                .foregroundColor(.white.opacity(0.4))
                                .frame(width: 20)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(exercise.name)
                                    .font(.bodyPrimary)
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                
                                Text("\(exercise.defaultSets) sets • \(exercise.defaultReps) reps")
                                    .font(.captionSecondary)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        .padding(Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .glassCard(opacity: 0.05)
                    }
                }
                
                // Start Button
                Button(action: {
                    withAnimation(.smoothSpring) {
                        workoutManager.startWorkout(workoutDay: workoutDay)
                    }
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("START WORKOUT")
                    }
                }
                .buttonStyle(PrimaryButtonStyle(color: Color(hex: workoutDay.colorHex)))
                .padding(.top, Spacing.md)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xl)
        }
        .background(
            ZStack {
                Color.black.ignoresSafeArea()
                
                // Ambient background gradient
                Color.workoutGradient(hex: workoutDay.colorHex, style: .subtle)
                    .opacity(0.3)
                    .ignoresSafeArea()
            }
        )
    }
}

#Preview {
    NavigationView {
        WorkoutDetailView(
            workoutDay: WatchWorkoutDay(
                id: UUID(),
                name: "Upper Body Power",
                dayNumber: 1,
                colorHex: "#00D4AA",
                exercises: [
                    WatchExercise(id: UUID(), name: "Bench Press", defaultSets: 3, defaultReps: "8-12", muscleGroup: "Chest"),
                    WatchExercise(id: UUID(), name: "Pull Ups", defaultSets: 3, defaultReps: "8-12", muscleGroup: "Back")
                ]
            )
        )
        .environmentObject(WatchWorkoutManager())
    }
}
