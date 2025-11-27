import SwiftUI

struct WatchActiveWorkoutView: View {
    @EnvironmentObject var workoutManager: WatchWorkoutManager
    @State private var showingEndConfirmation = false
    
    var body: some View {
        TabView {
            // Current Exercise Tab
            currentExerciseTab
            
            // Overview Tab
            overviewTab
            
            // Controls Tab
            controlsTab
        }
        .tabViewStyle(.verticalPage)
        .navigationBarBackButtonHidden(true)
        .confirmationDialog("End Workout?", isPresented: $showingEndConfirmation) {
            Button("End Workout", role: .destructive) {
                workoutManager.endWorkout()
            }
            Button("Cancel", role: .cancel) { }
        }
    }
    
    // MARK: - Current Exercise Tab
    
    private var currentExerciseTab: some View {
        ZStack {
            // Full-screen gradient background
            Color.workoutGradient(hex: workoutManager.workoutColorHex, style: .vibrant)
                .ignoresSafeArea()
            
            VStack(spacing: Spacing.lg) {
                // Header
                VStack(spacing: Spacing.xs) {
                    if let exercise = workoutManager.currentExercise {
                        Text(exercise.name)
                            .font(.titleSecondary)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                        
                        Text("SET \(workoutManager.currentSetIndex + 1) OF \(exercise.defaultSets)")
                            .font(.captionPrimary)
                            .foregroundColor(.white.opacity(0.8))
                            .tracking(1)
                    }
                }
                .padding(.top, Spacing.sm)
                
                // Input Controls
                SetInputView(
                    weight: $workoutManager.currentWeight,
                    reps: $workoutManager.currentReps,
                    weightUnit: workoutManager.weightUnit
                )
                
                Spacer()
                
                // Complete Button
                if workoutManager.currentExercise != nil {
                    Button(action: {
                        withAnimation(.smoothSpring) {
                            workoutManager.completeSet()
                        }
                    }) {
                        HStack {
                            Image(systemName: "checkmark")
                                .fontWeight(.bold)
                            Text("COMPLETE SET")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle(color: .white.opacity(0.2)))
                } else {
                    // Workout Complete State
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "trophy.fill")
                            .font(.displayLarge)
                            .foregroundColor(.yellow)
                            .symbolEffect(.bounce, options: .repeating)
                        
                        Text("Workout Complete!")
                            .font(.titlePrimary)
                            .foregroundColor(.white)
                        
                        Button("Finish") {
                            workoutManager.endWorkout()
                        }
                        .buttonStyle(PrimaryButtonStyle(color: .white))
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, Spacing.md)
        }
    }
    
    // MARK: - Overview Tab
    
    private var overviewTab: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: Spacing.lg) {
                // Header
                Text(workoutManager.workoutDayName)
                    .font(.titleSecondary)
                    .foregroundColor(Color(hex: workoutManager.workoutColorHex))
                
                // Stats Grid
                HStack(spacing: Spacing.md) {
                    StatCard(
                        value: "\(workoutManager.completedSets)",
                        label: "SETS"
                    )
                    
                    StatCard(
                        value: "\(workoutManager.currentExerciseIndex + 1)/\(workoutManager.totalExercises)",
                        label: "EXERCISE"
                    )
                }
                
                StatCard(
                    value: workoutManager.elapsedTimeString,
                    label: "TIME",
                    isWide: true
                )
                
                // Heart Rate
                if let heartRate = workoutManager.currentHeartRate {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .symbolEffect(.pulse)
                        Text("\(Int(heartRate)) BPM")
                            .font(.titlePrimary)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .padding(.vertical, Spacing.md)
                    .padding(.horizontal, Spacing.xl)
                    .glassCard(cornerRadius: CornerRadius.xl)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Controls Tab
    
    private var controlsTab: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: Spacing.lg) {
                Text("CONTROLS")
                    .font(.captionPrimary)
                    .foregroundColor(.gray)
                    .tracking(2)
                
                // Pause / Resume
                Button(action: {
                    withAnimation {
                        if workoutManager.isPaused {
                            workoutManager.resumeWorkout()
                        } else {
                            workoutManager.pauseWorkout()
                        }
                    }
                }) {
                    Label(
                        workoutManager.isPaused ? "Resume" : "Pause",
                        systemImage: workoutManager.isPaused ? "play.fill" : "pause.fill"
                    )
                }
                .buttonStyle(SecondaryButtonStyle())
                
                // End Workout
                Button(action: {
                    showingEndConfirmation = true
                }) {
                    Label("End Workout", systemImage: "xmark.circle.fill")
                }
                .buttonStyle(SecondaryButtonStyle())
                .tint(.red)
                
                Divider()
                    .overlay(Color.white.opacity(0.2))
                    .padding(.vertical, Spacing.sm)
                
                // Navigation Controls
                HStack(spacing: Spacing.md) {
                    Button(action: {
                        withAnimation { workoutManager.previousExercise() }
                    }) {
                        Image(systemName: "backward.fill")
                            .font(.titleSecondary)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(workoutManager.currentExerciseIndex == 0)
                    
                    Button(action: {
                        withAnimation { workoutManager.skipExercise() }
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.titleSecondary)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
            .padding()
        }
    }
}

// MARK: - Stat Card Component

struct StatCard: View {
    let value: String
    let label: String
    var isWide: Bool = false
    
    var body: some View {
        VStack(spacing: Spacing.xs) {
            Text(value)
                .font(.displayMedium)
                .foregroundColor(.white)
            
            Text(label)
                .font(.captionSecondary)
                .foregroundColor(.white.opacity(0.6))
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.lg)
        .glassCard()
    }
}

#Preview {
    WatchActiveWorkoutView()
        .environmentObject(WatchWorkoutManager())
}

