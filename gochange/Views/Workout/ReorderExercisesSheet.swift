import SwiftUI

struct ReorderExercisesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var workoutManager: WorkoutManager
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(workoutManager.exerciseLogs) { log in
                    HStack {
                        Text(log.exerciseName)
                            .font(.system(size: 16, weight: .medium))
                        Spacer()
                        if let count = log.sets.count {
                            Text("\(count) sets")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onMove { source, destination in
                    workoutManager.moveExercise(from: source, to: destination)
                }
            }
            .environment(\.editMode, .constant(.active)) // Force edit mode for drag handles
            .navigationTitle("Reorder Exercises")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
