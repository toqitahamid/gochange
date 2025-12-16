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
            
            FitnessDashboardView()
                .tabItem {
                    Label("Fitness", systemImage: "chart.bar.fill")
                }
                .tag(2)
        }
        .tint(AppTheme.accent)
        .overlay(alignment: .bottom) {
            if workoutManager.isWorkoutActive && workoutManager.isMinimized {
                if let workoutDay = workoutManager.currentWorkoutDay {
                    UnifiedWorkoutMiniplayer(
                        workoutDayName: workoutDay.name,
                        exerciseName: getCurrentExerciseName(),
                        workoutStartTime: workoutManager.startTime ?? Date(),
                        workoutIsPaused: workoutManager.isPaused,
                        setTimerState: workoutManager.activeSetTimer,
                        restTimerState: workoutManager.activeRestTimer,
                        currentHeartRate: workoutManager.currentHeartRate,
                        accentColor: Color(hex: workoutDay.colorHex),
                        onExpand: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                workoutManager.resume()
                            }
                        },
                        onPauseSession: {
                            workoutManager.pause()
                        },
                        onResumeSession: {
                            workoutManager.resumeWorkout()
                        },
                        onStopSet: {
                            workoutManager.stopSetTimer()
                        }
                    )
                    .padding(.bottom, 49) // Standard tab bar height
                    .transition(.move(edge: .bottom))
                }
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
    
    private func getCurrentExerciseName() -> String? {
        // If there's an active set timer, use that exercise
        if let setTimer = workoutManager.activeSetTimer {
            return setTimer.exerciseName
        }
        // Otherwise use the first exercise or current one
        if !workoutManager.exerciseLogs.isEmpty {
            return workoutManager.exerciseLogs.first?.exerciseName
        }
        return nil
    }
}

#Preview {
    MainTabView()
}

