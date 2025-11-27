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
            
            FitnessView()
                .tabItem {
                    Label("Fitness", systemImage: "chart.bar.fill")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("More", systemImage: "ellipsis")
                }
                .tag(3)
        }
        .tint(AppTheme.accent)
        .overlay(alignment: .bottom) {
            if workoutManager.isWorkoutActive && workoutManager.isMinimized {
                MiniPlayerView()
                    .padding(.bottom, 49) // Standard tab bar height
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

