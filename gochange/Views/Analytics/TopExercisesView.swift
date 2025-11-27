import SwiftUI

/// View displaying top exercises stats
struct TopExercisesView: View {
    let exercises: [ExerciseStats]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top Exercises")
                .font(.headline)
                .foregroundColor(.white)

            if exercises.isEmpty {
                emptyStateView
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
                        TopExerciseRow(rank: index + 1, exercise: exercise)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 40))
                .foregroundColor(.gray)

            Text("No exercise data yet")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

struct TopExerciseRow: View {
    let rank: Int
    let exercise: ExerciseStats

    var body: some View {
        HStack(spacing: 12) {
            // Rank
            ZStack {
                Circle()
                    .fill(rankColor.opacity(0.15))
                    .frame(width: 28, height: 28)
                
                Text("\(rank)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(rankColor)
            }

            // Name
            Text(exercise.exerciseName)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()

            // Stats
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(exercise.count) workouts")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("\(exercise.totalReps) reps")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
    }

    private var rankColor: Color {
        switch rank {
        case 1: return Color(hex: "#FFD700") // Gold
        case 2: return Color(hex: "#C0C0C0") // Silver
        case 3: return Color(hex: "#CD7F32") // Bronze
        default: return Color(hex: "#00D4AA")
        }
    }
}

#Preview {
    let sampleData = [
        ExerciseStats(exerciseName: "Bench Press", count: 12, totalVolume: 5000, totalReps: 120),
        ExerciseStats(exerciseName: "Squat", count: 10, totalVolume: 8000, totalReps: 100),
        ExerciseStats(exerciseName: "Deadlift", count: 8, totalVolume: 9000, totalReps: 80)
    ]

    return TopExercisesView(exercises: sampleData)
        .padding()
        .background(Color.black)
}
