import SwiftUI
import SwiftData

@main
struct GoChangeApp: App {
    let modelContainer: ModelContainer
    @StateObject private var workoutManager = WorkoutManager()
    
    // Check if iCloud sync is enabled from UserDefaults
    // Note: This is read at launch time - app restart required for changes
    private static var iCloudSyncEnabled: Bool {
        UserDefaults.standard.bool(forKey: "iCloudSyncEnabled")
    }
    
    init() {
        do {
            let schema = Schema([
                WorkoutDay.self,
                Exercise.self,
                WorkoutSession.self,
                ExerciseLog.self,
                SetLog.self
            ])
            
            // Configure CloudKit sync if enabled
            // IMPORTANT: Requires iCloud capability enabled in Xcode:
            // 1. Select project > Signing & Capabilities
            // 2. Add iCloud capability
            // 3. Check "CloudKit" and create container: iCloud.com.toqitahamid.gochange
            // 4. Add Background Modes > Remote notifications
            let modelConfiguration: ModelConfiguration
            
            if Self.iCloudSyncEnabled {
                // Use CloudKit for sync across devices
                modelConfiguration = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    cloudKitDatabase: .private("iCloud.com.toqitahamid.gochange")
                )
            } else {
                // Local-only storage
                modelConfiguration = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false
                )
            }
            
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

