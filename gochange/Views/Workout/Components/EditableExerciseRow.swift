import SwiftUI

/// An exercise row component for the edit mode of workout days
/// Shows numbered badge, exercise info, and optional drag handle when editing
struct EditableExerciseRow: View {
    let exercise: Exercise
    let index: Int
    let primaryColor: Color
    let isEditing: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Show drag handle when editing
            if isEditing {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.tertiary)
                    .padding(.leading, 8)
            }

            // Number Badge (same as WorkoutPreviewView)
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [primaryColor.opacity(0.15), primaryColor.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                Text("\(index)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(primaryColor)
            }

            // Exercise Info
            VStack(alignment: .leading, spacing: 6) {
                Text(exercise.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary.opacity(0.8))

                        Text(exercise.muscleGroup)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }

                    Text("•")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary.opacity(0.5))

                    HStack(spacing: 4) {
                        Image(systemName: "repeat")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(primaryColor.opacity(0.7))

                        Text("\(exercise.defaultSets) × \(exercise.defaultReps)")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(primaryColor)
                    }
                }
            }

            Spacer(minLength: 8)

            // Edit indicator
            Image(systemName: "pencil.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(primaryColor.opacity(0.6))
                .symbolRenderingMode(.hierarchical)
        }
        .padding(.horizontal, isEditing ? 10 : 18)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
    }
}

#Preview {
    VStack(spacing: 0) {
        EditableExerciseRow(
            exercise: Exercise(
                name: "Bench Press",
                defaultSets: 3,
                defaultReps: "8-10",
                muscleGroup: "Chest"
            ),
            index: 1,
            primaryColor: Color(hex: "#6B7280"),
            isEditing: false
        )

        Rectangle()
            .fill(Color.gray.opacity(0.1))
            .frame(height: 1)
            .padding(.leading, 64)

        EditableExerciseRow(
            exercise: Exercise(
                name: "Shoulder Press",
                defaultSets: 3,
                defaultReps: "10-12",
                muscleGroup: "Shoulders"
            ),
            index: 2,
            primaryColor: Color(hex: "#6B7280"),
            isEditing: true
        )
    }
    .background(Color.white)
    .clipShape(RoundedRectangle(cornerRadius: 24))
    .padding()
    .background(Color(hex: "#F5F5F7"))
}
