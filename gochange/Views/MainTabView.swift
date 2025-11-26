import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab - shows active workout if running, else HomeView
            Group {
                if workoutManager.isWorkoutActive && !workoutManager.isMinimized,
                   let workoutDay = workoutManager.currentWorkoutDay {
                    ActiveWorkoutView(workoutDay: workoutDay)
                } else {
                    HomeView()
                }
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)
            
            // Workout Tab - shows active workout if running
            Group {
                if workoutManager.isWorkoutActive && !workoutManager.isMinimized,
                   let workoutDay = workoutManager.currentWorkoutDay {
                    ActiveWorkoutView(workoutDay: workoutDay)
                } else {
                    WorkoutDaySelectionView()
                }
            }
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
            
            SettingsView()
                .tabItem {
                    Label("More", systemImage: "ellipsis")
                }
                .tag(4)
        }
        .tint(AppTheme.accent)
        .safeAreaInset(edge: .bottom) {
            if workoutManager.isWorkoutActive && workoutManager.isMinimized {
                MiniPlayerView()
                    .transition(.move(edge: .bottom))
            }
        }
        .onChange(of: workoutManager.isWorkoutActive) { _, isActive in
            // Switch to workout tab when starting a workout
            if isActive && !workoutManager.isMinimized {
                selectedTab = 1
            }
        }
        .onChange(of: workoutManager.isMinimized) { _, isMinimized in
            // Stay on current tab when minimizing/maximizing
        }
        .onAppear {
            workoutManager.setModelContext(modelContext)
        }
    }
}

#Preview {
    MainTabView()
}

