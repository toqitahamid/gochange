import SwiftUI
import SwiftData

struct WorkoutPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var workoutManager: WorkoutManager
    
    let workoutDay: WorkoutDay
    
    @State private var showingEditSheet = false
    
    private var accentColor: Color {
        Color(hex: workoutDay.colorHex)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Workout Header Card
                workoutHeaderCard
                
                // Exercise List
                exerciseListSection
                
                // Start Button
                startButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 100)
        }
        .background(Color(hex: "#F5F5F7").ignoresSafeArea())
        .navigationTitle(workoutDay.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingEditSheet = true
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditWorkoutDayView(workoutDay: workoutDay)
        }
        .toolbar(.visible, for: .tabBar)
    }
    
    // MARK: - Header Card
    private var workoutHeaderCard: some View {
        VStack(spacing: 20) {
            // Workout Icon
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [accentColor, accentColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Text(workoutDay.name.prefix(1).uppercased())
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .shadow(color: accentColor.opacity(0.3), radius: 15, y: 8)
            
            // Workout Info
            VStack(spacing: 8) {
                Text("DAY \(workoutDay.dayNumber)")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(accentColor)
                
                Text(workoutDay.name)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            // Stats Row
            HStack(spacing: 32) {
                VStack(spacing: 4) {
                    Text("\(workoutDay.exercises.count)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("Exercises")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 1, height: 40)
                
                VStack(spacing: 4) {
                    Text("\(totalSets)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("Sets")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 1, height: 40)
                
                VStack(spacing: 4) {
                    Text(estimatedDuration)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("Est. min")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        )
    }
    
    // MARK: - Exercise List Section
    private var exerciseListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("EXERCISES")
                .font(.system(size: 12, weight: .bold))
                .tracking(1.5)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                ForEach(Array(workoutDay.exercises.enumerated()), id: \.element.id) { index, exercise in
                    NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                        ExercisePreviewRow(
                            exercise: exercise,
                            index: index + 1,
                            accentColor: accentColor
                        )
                    }
                    .buttonStyle(.plain)
                    
                    if index < workoutDay.exercises.count - 1 {
                        Rectangle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 1)
                            .padding(.leading, 60)
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.gray.opacity(0.15), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
    
    // MARK: - Start Button
    private var startButton: some View {
        Button {
            workoutManager.start(workoutDay: workoutDay)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "play.fill")
                    .font(.system(size: 18))
                
                Text("Start Workout")
                    .font(.system(size: 18, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [accentColor, accentColor.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .shadow(color: accentColor.opacity(0.5), radius: 16, y: 8)
        }
        .buttonStyle(ScaleButtonStyle())
        .padding(.top, 8)
    }
    
    // MARK: - Computed Properties
    private var totalSets: Int {
        workoutDay.exercises.reduce(0) { $0 + $1.defaultSets }
    }
    
    private var estimatedDuration: String {
        // Rough estimate: 2 min per set including rest
        let minutes = totalSets * 2
        return "\(minutes)"
    }
}

// MARK: - Exercise Preview Row
struct ExercisePreviewRow: View {
    let exercise: Exercise
    let index: Int
    let accentColor: Color
    
    var body: some View {
        HStack(spacing: 14) {
            // Number Badge
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Text("\(index)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(accentColor)
            }
            
            // Exercise Info
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                HStack(spacing: 8) {
                    Text(exercise.muscleGroup)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text("\(exercise.defaultSets) × \(exercise.defaultReps)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(accentColor.opacity(0.8))
                }
            }
            
            Spacer()
            
            // Chevron to indicate tappable
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

#Preview {
    let workoutDay = WorkoutDay(
        name: "Pull",
        dayNumber: 2,
        colorHex: "#7CB9A8",
        exercises: [
            Exercise(name: "Lat Pulldown", defaultSets: 3, defaultReps: "12", muscleGroup: "Back"),
            Exercise(name: "Dumbbell Rows", defaultSets: 3, defaultReps: "12", muscleGroup: "Back"),
            Exercise(name: "Rear Delt Flyes", defaultSets: 3, defaultReps: "15", muscleGroup: "Shoulders"),
            Exercise(name: "Bicep Curls", defaultSets: 3, defaultReps: "15", muscleGroup: "Biceps")
        ]
    )
    
    return WorkoutPreviewView(workoutDay: workoutDay)
        .environmentObject(WorkoutManager())
}

