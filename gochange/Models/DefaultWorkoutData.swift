import Foundation

struct DefaultWorkoutData {
    static func createDefaultWorkouts() -> [WorkoutDay] {
        func ordered(_ exercises: [Exercise]) -> [Exercise] {
            exercises.enumerated().forEach { i, e in e.sortOrder = i }
            return exercises
        }

        return [
            // Day 1 - Push
            WorkoutDay(
                name: "Push",
                dayNumber: 1,
                colorHex: "#7CB9A8",  // Teal
                exercises: ordered([
                    Exercise(name: "Incline Bench Press", defaultSets: 3, defaultReps: "8", muscleGroup: "Chest"),
                    Exercise(name: "Dumbbell Overhead Press", defaultSets: 3, defaultReps: "12", muscleGroup: "Shoulders"),
                    Exercise(name: "Machine Chest", defaultSets: 3, defaultReps: "12", muscleGroup: "Chest"),
                    Exercise(name: "Shoulder Side Laterals", defaultSets: 3, defaultReps: "15", muscleGroup: "Shoulders"),
                    Exercise(name: "Tricep Pushdowns", defaultSets: 3, defaultReps: "15", muscleGroup: "Triceps")
                ])
            ),
            
            // Day 2 - Pull
            WorkoutDay(
                name: "Pull",
                dayNumber: 2,
                colorHex: "#9B59B6",  // Purple
                exercises: ordered([
                    Exercise(name: "Lat Pulldown", defaultSets: 3, defaultReps: "12", muscleGroup: "Back"),
                    Exercise(name: "Machine Rows", defaultSets: 3, defaultReps: "12", muscleGroup: "Back"),
                    Exercise(name: "Dumbbell Rows", defaultSets: 3, defaultReps: "12", muscleGroup: "Back"),
                    Exercise(name: "Rear Delt Flyes", defaultSets: 3, defaultReps: "15", muscleGroup: "Shoulders"),
                    Exercise(name: "Bicep Curls", defaultSets: 3, defaultReps: "15", muscleGroup: "Biceps")
                ])
            ),
            
            // Day 3 - Legs
            WorkoutDay(
                name: "Legs",
                dayNumber: 3,
                colorHex: "#5DADE2",  // Light Blue
                exercises: ordered([
                    Exercise(name: "Squat", defaultSets: 3, defaultReps: "8", muscleGroup: "Quads"),
                    Exercise(name: "Dumbbell RDL", defaultSets: 3, defaultReps: "8", muscleGroup: "Hamstrings"),
                    Exercise(name: "Leg Press", defaultSets: 3, defaultReps: "12", muscleGroup: "Quads"),
                    Exercise(name: "Leg Extensions", defaultSets: 3, defaultReps: "12", muscleGroup: "Quads"),
                    Exercise(name: "Leg Curl", defaultSets: 3, defaultReps: "12", muscleGroup: "Hamstrings")
                ])
            ),
            
            // Day 4 - Fullbody
            WorkoutDay(
                name: "Fullbody",
                dayNumber: 4,
                colorHex: "#85C1E9",  // Sky Blue
                exercises: ordered([
                    Exercise(name: "Squat", defaultSets: 2, defaultReps: "8", muscleGroup: "Quads"),
                    Exercise(name: "Barbell Bench Press", defaultSets: 3, defaultReps: "8", muscleGroup: "Chest"),
                    Exercise(name: "Cable Rows", defaultSets: 3, defaultReps: "12", muscleGroup: "Back"),
                    Exercise(name: "Underhand Lat Pulldown", defaultSets: 3, defaultReps: "12", muscleGroup: "Back"),
                    Exercise(name: "Tricep Overhead Extensions", defaultSets: 3, defaultReps: "12", muscleGroup: "Triceps"),
                    Exercise(name: "Hammer Curl", defaultSets: 3, defaultReps: "12", muscleGroup: "Biceps")
                ])
            ),
            
            // Cardio - Running
            WorkoutDay(
                name: "Running",
                dayNumber: 5,
                colorHex: "#FF6B6B",  // Red/Coral
                exercises: ordered([
                    Exercise(name: "Warm Up Walk", defaultSets: 1, defaultReps: "5 min", muscleGroup: "Cardio"),
                    Exercise(name: "Jogging", defaultSets: 1, defaultReps: "20 min", muscleGroup: "Cardio"),
                    Exercise(name: "Sprints", defaultSets: 5, defaultReps: "30 sec", muscleGroup: "Cardio"),
                    Exercise(name: "Cool Down Walk", defaultSets: 1, defaultReps: "5 min", muscleGroup: "Cardio")
                ])
            ),
            
            // Cardio - Cycling
            WorkoutDay(
                name: "Cycling",
                dayNumber: 6,
                colorHex: "#4ECDC4",  // Teal
                exercises: ordered([
                    Exercise(name: "Steady State Cycling", defaultSets: 1, defaultReps: "30 min", muscleGroup: "Cardio"),
                    Exercise(name: "Hill Climbs", defaultSets: 3, defaultReps: "5 min", muscleGroup: "Cardio")
                ])
            ),
            
            // Cardio - Walking
            WorkoutDay(
                name: "Walking",
                dayNumber: 7,
                colorHex: "#FFD93D",  // Yellow
                exercises: ordered([
                    Exercise(name: "Brisk Walk", defaultSets: 1, defaultReps: "30 min", muscleGroup: "Cardio")
                ])
            )
        ]
    }
}

