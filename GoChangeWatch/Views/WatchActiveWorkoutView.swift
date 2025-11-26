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
        VStack(spacing: 8) {
            if let exercise = workoutManager.currentExercise {
                // Exercise name
                Text(exercise.name)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                // Set info
                HStack {
                    Text("Set \(workoutManager.currentSetIndex + 1)")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("of \(exercise.defaultSets)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Divider()
                
                // Weight and Reps input
                SetInputView(
                    weight: $workoutManager.currentWeight,
                    reps: $workoutManager.currentReps,
                    weightUnit: workoutManager.weightUnit
                )
                
                // Complete Set Button
                Button(action: {
                    workoutManager.completeSet()
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Complete")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            } else {
                Text("Workout Complete!")
                    .font(.headline)
                
                Button("Finish") {
                    workoutManager.endWorkout()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Overview Tab
    
    private var overviewTab: some View {
        VStack(spacing: 12) {
            // Workout name
            Text(workoutManager.workoutDayName)
                .font(.headline)
                .foregroundColor(Color(hex: workoutManager.workoutColorHex))
            
            // Progress
            HStack {
                VStack {
                    Text("\(workoutManager.completedSets)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Sets")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack {
                    Text("\(workoutManager.currentExerciseIndex + 1)/\(workoutManager.totalExercises)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Exercise")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack {
                    Text(workoutManager.elapsedTimeString)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Time")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            
            // Heart rate if available
            if let heartRate = workoutManager.currentHeartRate {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                    Text("\(Int(heartRate)) BPM")
                        .font(.headline)
                }
            }
        }
        .padding()
    }
    
    // MARK: - Controls Tab
    
    private var controlsTab: some View {
        VStack(spacing: 16) {
            // Skip exercise
            Button(action: {
                workoutManager.skipExercise()
            }) {
                HStack {
                    Image(systemName: "forward.fill")
                    Text("Skip Exercise")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            
            // Previous exercise
            Button(action: {
                workoutManager.previousExercise()
            }) {
                HStack {
                    Image(systemName: "backward.fill")
                    Text("Previous")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(workoutManager.currentExerciseIndex == 0)
            
            // End workout
            Button(action: {
                showingEndConfirmation = true
            }) {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                    Text("End Workout")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.red)
        }
        .padding()
    }
}

#Preview {
    WatchActiveWorkoutView()
        .environmentObject(WatchWorkoutManager())
}

