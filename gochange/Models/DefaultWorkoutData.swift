import Foundation

struct DefaultWorkoutData {
    static func createDefaultWorkouts() -> [WorkoutDay] {
        return [
            // Day 1 - Push
            WorkoutDay(
                name: "Push",
                dayNumber: 1,
                colorHex: "#7CB9A8",  // Teal
                exercises: [
                    Exercise(name: "Incline Bench Press", defaultSets: 3, defaultReps: "8", muscleGroup: "Chest"),
                    Exercise(name: "Dumbbell Overhead Press", defaultSets: 3, defaultReps: "12", muscleGroup: "Shoulders"),
                    Exercise(name: "Machine Chest", defaultSets: 3, defaultReps: "12", muscleGroup: "Chest"),
                    Exercise(name: "Shoulder Side Laterals", defaultSets: 3, defaultReps: "15", muscleGroup: "Shoulders"),
                    Exercise(name: "Tricep Pushdowns", defaultSets: 3, defaultReps: "15", muscleGroup: "Triceps")
                ]
            ),
            
            // Day 2 - Pull
            WorkoutDay(
                name: "Pull",
                dayNumber: 2,
                colorHex: "#9B59B6",  // Purple
                exercises: [
                    Exercise(name: "Lat Pulldown", defaultSets: 3, defaultReps: "12", muscleGroup: "Back"),
                    Exercise(name: "Machine Rows", defaultSets: 3, defaultReps: "12", muscleGroup: "Back"),
                    Exercise(name: "Dumbbell Rows", defaultSets: 3, defaultReps: "12", muscleGroup: "Back"),
                    Exercise(name: "Rear Delt Flyes", defaultSets: 3, defaultReps: "15", muscleGroup: "Shoulders"),
                    Exercise(name: "Bicep Curls", defaultSets: 3, defaultReps: "15", muscleGroup: "Biceps")
                ]
            ),
            
            // Day 3 - Legs
            WorkoutDay(
                name: "Legs",
                dayNumber: 3,
                colorHex: "#5DADE2",  // Light Blue
                exercises: [
                    Exercise(name: "Squat", defaultSets: 3, defaultReps: "6-8", muscleGroup: "Quads"),
                    Exercise(name: "Dumbbell RDL", defaultSets: 3, defaultReps: "8", muscleGroup: "Hamstrings"),
                    Exercise(name: "Leg Press", defaultSets: 3, defaultReps: "12", muscleGroup: "Quads"),
                    Exercise(name: "Leg Extensions", defaultSets: 3, defaultReps: "12", muscleGroup: "Quads"),
                    Exercise(name: "Leg Curl", defaultSets: 3, defaultReps: "12", muscleGroup: "Hamstrings")
                ]
            ),
            
            // Day 4 - Fullbody
            WorkoutDay(
                name: "Fullbody",
                dayNumber: 4,
                colorHex: "#85C1E9",  // Sky Blue
                exercises: [
                    Exercise(name: "Squat", defaultSets: 2, defaultReps: "8", muscleGroup: "Quads"),
                    Exercise(name: "Barbell Bench Press", defaultSets: 3, defaultReps: "8", muscleGroup: "Chest"),
                    Exercise(name: "Cable Rows", defaultSets: 3, defaultReps: "12", muscleGroup: "Back"),
                    Exercise(name: "Underhand Lat Pulldown", defaultSets: 3, defaultReps: "12", muscleGroup: "Back"),
                    Exercise(name: "Tricep Overhead Extensions", defaultSets: 3, defaultReps: "12", muscleGroup: "Triceps"),
                    Exercise(name: "Hammer Curl", defaultSets: 3, defaultReps: "12", muscleGroup: "Biceps")
                ]
            ),
            
            // Cardio - Running
            WorkoutDay(
                name: "Running",
                dayNumber: 5,
                colorHex: "#FF6B6B",  // Red/Coral
                exercises: [
                    Exercise(name: "Warm Up Walk", defaultSets: 1, defaultReps: "5 min", muscleGroup: "Cardio"),
                    Exercise(name: "Jogging", defaultSets: 1, defaultReps: "20 min", muscleGroup: "Cardio"),
                    Exercise(name: "Sprints", defaultSets: 5, defaultReps: "30 sec", muscleGroup: "Cardio"),
                    Exercise(name: "Cool Down Walk", defaultSets: 1, defaultReps: "5 min", muscleGroup: "Cardio")
                ]
            ),
            
            // Cardio - Cycling
            WorkoutDay(
                name: "Cycling",
                dayNumber: 6,
                colorHex: "#4ECDC4",  // Teal
                exercises: [
                    Exercise(name: "Steady State Cycling", defaultSets: 1, defaultReps: "30 min", muscleGroup: "Cardio"),
                    Exercise(name: "Hill Climbs", defaultSets: 3, defaultReps: "5 min", muscleGroup: "Cardio")
                ]
            ),
            
            // Cardio - Walking
            WorkoutDay(
                name: "Walking",
                dayNumber: 7,
                colorHex: "#FFD93D",  // Yellow
                exercises: [
                    Exercise(name: "Brisk Walk", defaultSets: 1, defaultReps: "30 min", muscleGroup: "Cardio")
                ]
            )
        ]
    }
}

