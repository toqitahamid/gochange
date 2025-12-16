import SwiftUI
import SwiftData

@main
struct GoChangeApp: App {
    let modelContainer: ModelContainer
    @StateObject private var workoutManager = WorkoutManager()
    
    init() {
        do {
            let schema = Schema([
                WorkoutDay.self,
                Exercise.self,
                WorkoutSession.self,
                ExerciseLog.self,
                SetLog.self,
                RestDay.self,
                RecoveryMetrics.self
            ])

            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )

            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            
            // Seed default data if first launch
            seedDefaultDataIfNeeded()
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onAppear {
                    workoutManager.setModelContext(modelContainer.mainContext)
                    
                    // Restore active workout state if any
                    workoutManager.checkForActiveWorkout()
                    
                    // Initialize Watch Connectivity
                    WatchConnectivityService.shared.setModelContext(modelContainer.mainContext)
                }
        }
        .modelContainer(modelContainer)
        .environmentObject(workoutManager)
    }
    
    private func seedDefaultDataIfNeeded() {
        let context = modelContainer.mainContext
        
        // 1. Fetch existing workouts
        let descriptor = FetchDescriptor<WorkoutDay>()
        let existingWorkouts = (try? context.fetch(descriptor)) ?? []
        let existingNames = Set(existingWorkouts.map { $0.name })
        
        // 2. Get all default workouts
        let defaultWorkouts = DefaultWorkoutData.createDefaultWorkouts()
        
        // 3. Add missing ones
        var addedCount = 0
        for workout in defaultWorkouts {
            if !existingNames.contains(workout.name) {
                context.insert(workout)
                addedCount += 1
            }
        }
        
        // 4. Save if changes made
        if addedCount > 0 {
            try? context.save()
            print("Seeded \(addedCount) new default workouts.")
        }
    }
}

