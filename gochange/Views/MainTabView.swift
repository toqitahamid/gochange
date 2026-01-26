import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    @State private var showingActiveWorkout = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main Content Area
            TabView(selection: $selectedTab) {
                JournalView()
                    .tag(0)
                
                WorkoutDaySelectionView()
                    .tag(1)
                
                PerformanceAnalyticsView()
                    .tag(2)
            }
            .tint(AppTheme.accent)
            // Hide native tab bar
            .toolbar(.hidden, for: .tabBar)
            
            // Custom Elements Layer (Miniplayer + Tab Bar)
            VStack(spacing: 0) {
                Spacer()
                
                // Miniplayer
                if workoutManager.isWorkoutActive && workoutManager.isMinimized {
                    if let workoutDay = workoutManager.currentWorkoutDay {
                        WorkoutMiniplayer(
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
                        .padding(.bottom, 12)
                        .padding(.horizontal, 16)
                        .transition(.move(edge: .bottom))
                    }
                }
                
                // Floating Tab Bar
                CustomTabBar(selectedTab: $selectedTab)
                    .padding(.bottom, 34) // Bottom safe area offset
            }
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showingActiveWorkout, onDismiss: {
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
            if workoutManager.isWorkoutActive && !workoutManager.isMinimized {
                showingActiveWorkout = true
            }
        }
    }
    
    private func getCurrentExerciseName() -> String? {
        if let setTimer = workoutManager.activeSetTimer {
            return setTimer.exerciseName
        }
        if !workoutManager.exerciseLogs.isEmpty {
            return workoutManager.exerciseLogs.first?.exerciseName
        }
        return nil
    }
}

// MARK: - Custom Floating Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            // Home
            TabBarItem(
                icon: "house.fill",
                label: "Journal",
                isSelected: selectedTab == 0
            ) {
                selectedTab = 0
            }
            
            // Workout
            TabBarItem(
                icon: "dumbbell.fill",
                label: "Workout",
                isSelected: selectedTab == 1
            ) {
                selectedTab = 1
            }
            
            // Analytics
            TabBarItem(
                icon: "chart.xyaxis.line",
                label: "Fitness",
                isSelected: selectedTab == 2
            ) {
                selectedTab = 2
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 40)
    }
}

struct TabBarItem: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(isSelected ? AppColors.primary : AppColors.textSecondary)
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    MainTabView()
}

