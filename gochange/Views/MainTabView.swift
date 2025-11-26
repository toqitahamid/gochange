import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            WorkoutDaySelectionView()
                .tabItem {
                    Label("Workout", systemImage: "dumbbell.fill")
                }
                .tag(1)
            
            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
                .tag(2)
            
            HistoryListView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
                .tag(3)
            
            ExerciseLibraryView()
                .tabItem {
                    Label("Exercises", systemImage: "list.bullet")
                }
                .tag(4)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(5)
        }
        .tint(AppTheme.accent)
        .safeAreaInset(edge: .bottom) {
            if workoutManager.isWorkoutActive && workoutManager.isMinimized {
                MiniPlayerView()
                    .transition(.move(edge: .bottom))
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { workoutManager.isWorkoutActive && !workoutManager.isMinimized },
            set: { _ in }
        )) {
            if let session = workoutManager.currentSession {
                // We need to reconstruct the WorkoutDay from the session or pass it differently.
                // Since WorkoutSession has workoutDayId and workoutDayName, but ActiveWorkoutView needs WorkoutDay object.
                // For now, let's modify ActiveWorkoutView to accept just the session or fetch the day.
                // OR, simpler: Store the WorkoutDay in WorkoutManager as well.
                if let workoutDay = getWorkoutDay(id: session.workoutDayId) {
                    ActiveWorkoutView(workoutDay: workoutDay)
                } else {
                    // Fallback or error state
                    Text("Error loading workout")
                }
            }
        }
        .onAppear {
            workoutManager.setModelContext(modelContext)
        }
    }
    
    private func getWorkoutDay(id: UUID) -> WorkoutDay? {
        // This is a bit tricky since we don't have direct access to the model context here to fetch easily without a query.
        // However, we can pass the WorkoutDay to the manager when starting.
        // Let's update WorkoutManager to store the current WorkoutDay.
        return workoutManager.currentWorkoutDay
    }
}

#Preview {
    MainTabView()
}

