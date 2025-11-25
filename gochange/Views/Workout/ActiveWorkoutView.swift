import SwiftUI
import SwiftData
import Combine

struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let workoutDay: WorkoutDay
    
    @State private var session: WorkoutSession
    @State private var exerciseLogs: [ExerciseLog] = []
    @State private var startTime = Date()
    @State private var showingCompletionAlert = false
    @State private var showingCancelAlert = false
    @State private var expandedExercise: UUID?
    
    init(workoutDay: WorkoutDay) {
        self.workoutDay = workoutDay
        self._session = State(initialValue: WorkoutSession(
            date: Date(),
            workoutDayId: workoutDay.id,
            workoutDayName: workoutDay.name
        ))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Timer Card
                    WorkoutTimerCard(startTime: startTime)
                    
                    // Exercise List
                    ForEach(Array(exerciseLogs.enumerated()), id: \.element.id) { index, exerciseLog in
                        ExerciseLogCard(
                            exerciseLog: $exerciseLogs[index],
                            exercise: getExercise(for: exerciseLog),
                            isExpanded: expandedExercise == exerciseLog.id,
                            onToggleExpand: {
                                withAnimation {
                                    if expandedExercise == exerciseLog.id {
                                        expandedExercise = nil
                                    } else {
                                        expandedExercise = exerciseLog.id
                                    }
                                }
                            },
                            onAddSet: {
                                addSet(to: index)
                            },
                            onRemoveSet: { setIndex in
                                removeSet(at: setIndex, from: index)
                            }
                        )
                    }
                }
                .padding()
            }
            .background(AppTheme.background)
            .navigationTitle(workoutDay.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingCancelAlert = true
                    }
                    .foregroundColor(.red)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Complete") {
                        showingCompletionAlert = true
                    }
                    .fontWeight(.semibold)
                    .disabled(!canComplete)
                }
            }
            .alert("Cancel Workout?", isPresented: $showingCancelAlert) {
                Button("Keep Going", role: .cancel) { }
                Button("Discard", role: .destructive) {
                    dismiss()
                }
            } message: {
                Text("Your progress will not be saved.")
            }
            .alert("Complete Workout?", isPresented: $showingCompletionAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Complete") {
                    completeWorkout()
                }
            } message: {
                Text("Great job! This workout will be saved to your history.")
            }
            .onAppear {
                setupExerciseLogs()
            }
        }
    }
    
    // MARK: - Computed Properties
    private var canComplete: Bool {
        exerciseLogs.contains { log in
            log.sets.contains { $0.isCompleted }
        }
    }
    
    // MARK: - Methods
    private func setupExerciseLogs() {
        exerciseLogs = workoutDay.exercises.enumerated().map { index, exercise in
            let log = ExerciseLog(
                exerciseId: exercise.id,
                exerciseName: exercise.name,
                order: index
            )
            
            // Create sets based on default
            for setNum in 1...exercise.defaultSets {
                let setLog = SetLog(
                    setNumber: setNum,
                    targetReps: exercise.defaultReps
                )
                log.sets.append(setLog)
            }
            
            return log
        }
        
        // Expand first exercise by default
        expandedExercise = exerciseLogs.first?.id
    }
    
    private func getExercise(for log: ExerciseLog) -> Exercise? {
        workoutDay.exercises.first { $0.id == log.exerciseId }
    }
    
    private func addSet(to exerciseIndex: Int) {
        let exercise = getExercise(for: exerciseLogs[exerciseIndex])
        let newSetNumber = exerciseLogs[exerciseIndex].sets.count + 1
        let newSet = SetLog(
            setNumber: newSetNumber,
            targetReps: exercise?.defaultReps ?? "10"
        )
        exerciseLogs[exerciseIndex].sets.append(newSet)
    }
    
    private func removeSet(at setIndex: Int, from exerciseIndex: Int) {
        guard exerciseLogs[exerciseIndex].sets.count > 1 else { return }
        exerciseLogs[exerciseIndex].sets.remove(at: setIndex)
        
        // Renumber remaining sets
        for (index, _) in exerciseLogs[exerciseIndex].sets.enumerated() {
            exerciseLogs[exerciseIndex].sets[index].setNumber = index + 1
        }
    }
    
    private func completeWorkout() {
        session.endTime = Date()
        session.duration = session.endTime?.timeIntervalSince(session.startTime)
        session.isCompleted = true
        
        // Attach exercise logs to session
        for log in exerciseLogs {
            session.exerciseLogs.append(log)
        }
        
        modelContext.insert(session)
        try? modelContext.save()
        
        dismiss()
    }
}

// MARK: - Workout Timer Card
struct WorkoutTimerCard: View {
    let startTime: Date
    @State private var elapsed: TimeInterval = 0
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Workout Time")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(elapsed.formattedDuration)
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Image(systemName: "timer")
                .font(.title)
                .foregroundColor(AppTheme.accent)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        .onReceive(timer) { _ in
            elapsed = Date().timeIntervalSince(startTime)
        }
    }
}

// MARK: - Exercise Log Card
struct ExerciseLogCard: View {
    @Binding var exerciseLog: ExerciseLog
    let exercise: Exercise?
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    let onAddSet: () -> Void
    let onRemoveSet: (Int) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: onToggleExpand) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(exerciseLog.exerciseName)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if let exercise = exercise {
                            Text("\(exercise.muscleGroup) • \(exercise.defaultSets) × \(exercise.defaultReps)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Completion indicator
                    let completedSets = exerciseLog.sets.filter { $0.isCompleted }.count
                    Text("\(completedSets)/\(exerciseLog.sets.count)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(completedSets == exerciseLog.sets.count ? .green : .secondary)
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .buttonStyle(.plain)
            
            // Expanded Content
            if isExpanded {
                Divider()
                
                VStack(spacing: 8) {
                    // Set Headers
                    HStack(spacing: 8) {
                        Text("SET")
                            .frame(width: 35)
                        Text("TARGET")
                            .frame(width: 50)
                        Text("WEIGHT")
                            .frame(width: 70)
                        Text("REPS")
                            .frame(width: 50)
                        Text("RIR")
                            .frame(width: 50)
                        Spacer()
                            .frame(width: 40)
                    }
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Set Rows
                    ForEach(Array(exerciseLog.sets.enumerated()), id: \.element.id) { index, _ in
                        SetInputRow(
                            setLog: $exerciseLog.sets[index],
                            onRemove: exerciseLog.sets.count > 1 ? { onRemoveSet(index) } : nil
                        )
                    }
                    
                    // Add Set Button
                    Button(action: onAddSet) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Set")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.accent)
                    }
                    .padding(.vertical, 8)
                }
                .padding(.bottom, 12)
            }
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

// MARK: - Set Input Row
struct SetInputRow: View {
    @Binding var setLog: SetLog
    let onRemove: (() -> Void)?
    
    @State private var weightText: String = ""
    @State private var repsText: String = ""
    
    var body: some View {
        HStack(spacing: 8) {
            // Set Number
            Text("\(setLog.setNumber)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .frame(width: 35)
            
            // Target Reps
            Text(setLog.targetReps)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 50)
            
            // Weight Input
            HStack(spacing: 2) {
                TextField("0", text: $weightText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 50)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: weightText) { _, newValue in
                        setLog.weight = Double(newValue)
                    }
                
                Text(setLog.weightUnit.rawValue)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 70)
            
            // Actual Reps
            TextField("0", text: $repsText)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .frame(width: 50)
                .textFieldStyle(.roundedBorder)
                .onChange(of: repsText) { _, newValue in
                    setLog.actualReps = Int(newValue)
                }
            
            // RIR Picker
            Menu {
                ForEach(0...5, id: \.self) { rir in
                    Button {
                        setLog.rir = rir
                    } label: {
                        Label(AppConstants.RIR.label(for: rir), systemImage: setLog.rir == rir ? "checkmark" : "")
                    }
                }
            } label: {
                Text(setLog.rir != nil ? "\(setLog.rir!)" : "-")
                    .font(.subheadline)
                    .frame(width: 50)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))
                    .cornerRadius(6)
            }
            
            // Complete Button
            Button {
                withAnimation {
                    setLog.isCompleted.toggle()
                }
            } label: {
                Image(systemName: setLog.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(setLog.isCompleted ? .green : .gray)
            }
            .frame(width: 40)
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(setLog.isCompleted ? Color.green.opacity(0.05) : Color.clear)
        .onAppear {
            if let weight = setLog.weight {
                weightText = String(format: "%.1f", weight)
            }
            if let reps = setLog.actualReps {
                repsText = String(reps)
            }
        }
        .swipeActions(edge: .trailing) {
            if let onRemove = onRemove {
                Button(role: .destructive, action: onRemove) {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}

#Preview {
    let workoutDay = WorkoutDay(
        name: "Push",
        dayNumber: 1,
        colorHex: "#7CB9A8",
        exercises: [
            Exercise(name: "Bench Press", defaultSets: 3, defaultReps: "8", muscleGroup: "Chest"),
            Exercise(name: "Shoulder Press", defaultSets: 3, defaultReps: "10", muscleGroup: "Shoulders")
        ]
    )
    
    return ActiveWorkoutView(workoutDay: workoutDay)
        .modelContainer(for: [WorkoutSession.self, ExerciseLog.self, SetLog.self])
}

