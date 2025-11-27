import SwiftUI
import WatchConnectivity

@main
struct GoChangeWatchApp: App {
    @StateObject private var workoutManager = WatchWorkoutManager()
    @StateObject private var connectivityManager = WatchConnectivityManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(workoutManager)
                .environmentObject(connectivityManager)
        }
    }
}

// MARK: - Content View

struct ContentView: View {
    @EnvironmentObject var workoutManager: WatchWorkoutManager
    
    var body: some View {
        if workoutManager.isWorkoutActive {
            WatchActiveWorkoutView()
        } else {
            WorkoutListView()
        }
    }
}

