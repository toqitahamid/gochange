import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    @State private var showingActiveWorkout = false

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
            
            FitnessView()
                .tabItem {
                    Label("Fitness", systemImage: "chart.bar.fill")
                }
                .tag(2)
        }
        .tint(AppTheme.accent)
        .overlay(alignment: .bottom) {
            if workoutManager.isWorkoutActive && workoutManager.isMinimized {
                MiniPlayerView()
                    .padding(.bottom, 49) // Standard tab bar height
                    .transition(.move(edge: .bottom))
            }
        }
        .sheet(isPresented: $showingActiveWorkout, onDismiss: {
            // When sheet is dismissed by swipe, minimize the workout
            if workoutManager.isWorkoutActive {
                workoutManager.minimize()
            }
        }) {
            if let workoutDay = workoutManager.currentWorkoutDay {
                ActiveWorkoutView(workoutDay: workoutDay)
            }
        }
        .onChange(of: workoutManager.isWorkoutActive) { _, isActive in
            showingActiveWorkout = isActive && !workoutManager.isMinimized
        }
        .onChange(of: workoutManager.isMinimized) { _, isMinimized in
            if workoutManager.isWorkoutActive {
                showingActiveWorkout = !isMinimized
            }
        }
        .onAppear {
            workoutManager.setModelContext(modelContext)
            // Check if workout is already active
            if workoutManager.isWorkoutActive && !workoutManager.isMinimized {
                showingActiveWorkout = true
            }
        }
    }
}

#Preview {
    MainTabView()
}

