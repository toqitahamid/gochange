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
                    
                    // Initialize Watch Connectivity
                    WatchConnectivityService.shared.setModelContext(modelContainer.mainContext)
                }
        }
        .modelContainer(modelContainer)
        .environmentObject(workoutManager)
    }
    
    private func seedDefaultDataIfNeeded() {
        let context = modelContainer.mainContext
        
        let descriptor = FetchDescriptor<WorkoutDay>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0
        
        if existingCount == 0 {
            let defaultWorkouts = DefaultWorkoutData.createDefaultWorkouts()
            for workout in defaultWorkouts {
                context.insert(workout)
            }
            try? context.save()
        }
    }
}

