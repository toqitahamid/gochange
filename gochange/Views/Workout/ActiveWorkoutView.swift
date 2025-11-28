import SwiftUI
import SwiftData
import Combine

struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var workoutManager: WorkoutManager
    @AppStorage("weightUnit") private var weightUnit: String = "lbs"
    
    let workoutDay: WorkoutDay
    
    @State private var showingCompletionAlert = false
    @State private var showingCancelAlert = false
    @State private var showingRPEInput = false
    @State private var rpeValue: Double = 7.0
    @State private var expandedExercise: UUID?
    
    // Track completed sets for live activity
    private var completedSetsCount: Int {
        workoutManager.completedSetsCount
    }
    
    private var totalSetsCount: Int {
        workoutManager.totalSetsCount
    }
    
    init(workoutDay: WorkoutDay) {
        self.workoutDay = workoutDay
    }
    
    private var accentColor: Color {
        Color(hex: workoutDay.colorHex)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Navigation Bar
            HStack {
                HStack(spacing: 12) {
                    // Minimize button - allows browsing the app
                    Button {
                        withAnimation {
                            workoutManager.minimize()
                        }
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 36, height: 36)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    // Cancel button - discards workout
                    Button {
                        showingCancelAlert = true
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(hex: "#FF6B6B"))
                    }
                }
                
                Spacer()
                
                Text(workoutDay.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button {
                    showingRPEInput = true
                } label: {
                    Text("Complete")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(workoutManager.canComplete ? Color(hex: "#00D4AA") : .gray)
                }
                .disabled(!workoutManager.canComplete)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
            .overlay(
                Rectangle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 1)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            )
            
            ScrollView {
                VStack(spacing: 16) {
                    // Timer Card with Rest Button and Notes
                    if let startTime = workoutManager.startTime {
                        WorkoutTimerCard(
                            startTime: startTime,
                            accentColor: accentColor,
                            currentHeartRate: workoutManager.currentHeartRate,
                            onRestTap: {
                                workoutManager.showingRestTimer = true
                            },
                            onNotesTap: {
                                workoutManager.showingSessionNotes = true
                            },
                            hasNotes: !workoutManager.sessionNotes.isEmpty
                        )
                    }
                    
                    // Exercise List
                    ForEach(Array(workoutManager.exerciseLogs.enumerated()), id: \.element.id) { index, exerciseLog in
                        ExerciseLogCard(
                            exerciseLog: $workoutManager.exerciseLogs[index],
                            exercise: getExercise(for: exerciseLog),
                            accentColor: accentColor,
                            isExpanded: expandedExercise == exerciseLog.id,
                            previousSets: workoutManager.previousSetData[exerciseLog.exerciseId] ?? [],
                            onToggleExpand: {
                                withAnimation(.easeInOut(duration: 0.25)) {
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
                            },
                            onToggleSetCompletion: { setIndex in
                                workoutManager.toggleSetCompletion(exerciseIndex: index, setIndex: setIndex)
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 120) // Extra padding for tab bar
            }
        }
        .background(Color(hex: "#F5F5F7").ignoresSafeArea())
        .toolbar(.visible, for: .tabBar)
        .alert("Cancel Workout?", isPresented: $showingCancelAlert) {
            Button("Keep Going", role: .cancel) { }
            Button("Discard", role: .destructive) {
                workoutManager.cancel()
            }
        } message: {
            Text("Your progress will not be saved.")
        }
        .alert("Complete Workout?", isPresented: $showingCompletionAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Complete") {
                workoutManager.complete()
            }
        } message: {
            Text("Great job! This workout will be saved to your history.")
        }
        .onAppear {
            if expandedExercise == nil {
                expandedExercise = workoutManager.exerciseLogs.first?.id
            }
        }
        .onChange(of: completedSetsCount) { oldValue, newValue in
            // Live activity update is handled in WorkoutManager
        }
        .sheet(isPresented: $workoutManager.showingRestTimer) {
            RestTimerView(isPresented: $workoutManager.showingRestTimer)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $workoutManager.showingSessionNotes) {
            SessionNotesSheet(notes: $workoutManager.sessionNotes)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingRPEInput) {
            RPEInputSheet(rpe: $rpeValue) {
                showingRPEInput = false
                workoutManager.complete(rpe: rpeValue)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    // MARK: - Live Activity
    // Moved to WorkoutManager
    
    // MARK: - Computed Properties
    // Moved to WorkoutManager
    
    // MARK: - Methods
    // setupExerciseLogs moved to WorkoutManager
    
    private func getExercise(for log: ExerciseLog) -> Exercise? {
        workoutDay.exercises.first { $0.id == log.exerciseId }
    }
    
    private func addSet(to exerciseIndex: Int) {
        let exercise = getExercise(for: workoutManager.exerciseLogs[exerciseIndex])
        workoutManager.addSet(to: exerciseIndex, defaultReps: exercise?.defaultReps ?? "10")
    }
    
    private func removeSet(at setIndex: Int, from exerciseIndex: Int) {
        workoutManager.removeSet(at: setIndex, from: exerciseIndex)
    }
    
    private func completeWorkout() {
        // Moved to WorkoutManager
    }
}

// MARK: - Workout Timer Card
struct WorkoutTimerCard: View {
    let startTime: Date
    let accentColor: Color
    var currentHeartRate: Double? = nil
    let onRestTap: () -> Void
    let onNotesTap: () -> Void
    let hasNotes: Bool
    @State private var elapsed: TimeInterval = 0
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("WORKOUT TIME")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.5)
                        .foregroundColor(.secondary)
                    
                    Text(elapsed.formattedDuration)
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    if let heartRate = currentHeartRate {
                        HStack(spacing: 6) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "#FF3B30"))
                            
                            Text("\(Int(heartRate)) BPM")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        .padding(.top, 4)
                        .transition(.opacity.combined(with: .scale))
                    }
                }
                
                Spacer()
                
                VStack(spacing: 10) {
                    // Rest Timer Button
                    Button(action: onRestTap) {
                        HStack(spacing: 8) {
                            Image(systemName: "timer")
                                .font(.system(size: 16))
                            Text("Rest")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [accentColor, accentColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(25)
                        .shadow(color: accentColor.opacity(0.4), radius: 8, y: 4)
                    }
                    
                    // Notes Button
                    Button(action: onNotesTap) {
                        HStack(spacing: 6) {
                            Image(systemName: hasNotes ? "note.text" : "note.text.badge.plus")
                                .font(.system(size: 14))
                            Text("Notes")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(hasNotes ? Color(hex: "#00D4AA") : .gray)
                    }
                }
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        )
        .onReceive(timer) { _ in
            elapsed = Date().timeIntervalSince(startTime)
        }
    }
}

// MARK: - Exercise Log Card
struct ExerciseLogCard: View {
    @Binding var exerciseLog: ExerciseLog
    let exercise: Exercise?
    let accentColor: Color
    let isExpanded: Bool
    let previousSets: [PreviousSetInfo]
    let onToggleExpand: () -> Void
    let onAddSet: () -> Void
    let onRemoveSet: (Int) -> Void
    let onToggleSetCompletion: (Int) -> Void
    
    @State private var showingNotes = false
    
    private var completedSets: Int {
        exerciseLog.sets.filter { $0.isCompleted }.count
    }
    
    private var isFullyCompleted: Bool {
        completedSets == exerciseLog.sets.count && exerciseLog.sets.count > 0
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: onToggleExpand) {
                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(exerciseLog.exerciseName)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            if exerciseLog.notes != nil {
                                Image(systemName: "note.text")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "#00D4AA"))
                            }
                        }
                        
                        if let exercise = exercise {
                            Text("\(exercise.muscleGroup) • \(exercise.defaultSets) × \(exercise.defaultReps)")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Completion indicator
                    HStack(spacing: 8) {
                        Text("\(completedSets)/\(exerciseLog.sets.count)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(isFullyCompleted ? Color(hex: "#00D4AA") : .secondary)
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                            .rotationEffect(.degrees(isExpanded ? -180 : 0))
                    }
                }
                .padding(16)
            }
            .buttonStyle(.plain)
            
            // Expanded Content
            if isExpanded {
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 1)
                
                VStack(spacing: 0) {
                    // Set Headers
                    HStack(spacing: 0) {
                        Text("SET")
                            .frame(width: 40, alignment: .center)
                        Text("TARGET")
                            .frame(width: 55, alignment: .center)
                        Text("WEIGHT")
                            .frame(maxWidth: .infinity, alignment: .center)
                        Text("REPS")
                            .frame(width: 55, alignment: .center)
                        Text("RIR")
                            .frame(width: 50, alignment: .center)
                        Spacer()
                            .frame(width: 44)
                    }
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.5)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    
                    // Set Rows
                    ForEach(Array(exerciseLog.sets.enumerated()), id: \.element.id) { index, _ in
                        let previousSet = previousSets.first { $0.setNumber == exerciseLog.sets[index].setNumber }
                        SetInputRow(
                            setLog: $exerciseLog.sets[index],
                            accentColor: accentColor,
                            previousSet: previousSet,
                            onRemove: exerciseLog.sets.count > 1 ? { onRemoveSet(index) } : nil,
                            onToggleCompletion: { onToggleSetCompletion(index) }
                        )
                    }
                    
                    // Bottom Row with Add Set and Notes
                    HStack {
                        Button(action: onAddSet) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 16))
                                Text("Add Set")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(accentColor)
                        }
                        
                        Spacer()
                        
                        Button {
                            showingNotes = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: exerciseLog.notes != nil ? "note.text" : "note.text.badge.plus")
                                    .font(.system(size: 14))
                                Text("Notes")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(exerciseLog.notes != nil ? Color(hex: "#00D4AA") : .gray)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    isFullyCompleted ? Color(hex: "#00D4AA").opacity(0.3) : Color.gray.opacity(0.15),
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .sheet(isPresented: $showingNotes) {
            ExerciseNotesSheet(exerciseName: exerciseLog.exerciseName, notes: $exerciseLog.notes)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Set Input Row
struct SetInputRow: View {
    @Binding var setLog: SetLog
    let accentColor: Color
    let previousSet: PreviousSetInfo?
    let onRemove: (() -> Void)?
    let onToggleCompletion: () -> Void
    
    @State private var weightText: String = ""
    @State private var repsText: String = ""
    
    private var previousDataText: String? {
        guard let prev = previousSet,
              let weight = prev.weight,
              let reps = prev.reps else { return nil }
        return "\(Int(weight))×\(reps)"
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Set Number
            Text("\(setLog.setNumber)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .frame(width: 40, alignment: .center)
            
            // Target Reps with Previous Data
            VStack(spacing: 2) {
                Text(setLog.targetReps)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                
                if let prevText = previousDataText {
                    Text(prevText)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color(hex: "#00D4AA").opacity(0.7))
                }
            }
            .frame(width: 55, alignment: .center)
            
            // Weight Input
            HStack(spacing: 4) {
                TextField("0", text: $weightText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 50)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .onChange(of: weightText) { _, newValue in
                        setLog.weight = Double(newValue)
                    }
                
                Text(setLog.weightUnit.rawValue)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            
            // Actual Reps
            TextField("0", text: $repsText)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: 44)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .onChange(of: repsText) { _, newValue in
                    setLog.actualReps = Int(newValue)
                }
                .frame(width: 55, alignment: .center)
            
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
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(setLog.rir != nil ? accentColor : .secondary)
                    .frame(width: 36)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            .frame(width: 50, alignment: .center)
            
            // Complete Button
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    onToggleCompletion()
                }
            } label: {
                ZStack {
                    Circle()
                        .stroke(setLog.isCompleted ? Color(hex: "#00D4AA") : Color.white.opacity(0.2), lineWidth: 2)
                        .frame(width: 28, height: 28)
                    
                    if setLog.isCompleted {
                        Circle()
                            .fill(Color(hex: "#00D4AA"))
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.black)
                    }
                }
            }
            .frame(width: 44, alignment: .center)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            setLog.isCompleted ?
            Color(hex: "#00D4AA").opacity(0.08) :
            Color.clear
        )
        .onAppear {
            if let weight = setLog.weight {
                weightText = String(format: "%.0f", weight)
            }
            if let reps = setLog.actualReps {
                repsText = String(reps)
            }
        }
    }
}

// MARK: - Session Notes Sheet
struct SessionNotesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var notes: String
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("WORKOUT NOTES")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(1.5)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $notes)
                        .scrollContentBackground(.hidden)
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                        .frame(minHeight: 150)
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                        )
                    
                    Text("Add any notes about this workout - how you felt, adjustments made, etc.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.top, 20)
            .background(Color(hex: "#F5F5F7").ignoresSafeArea())
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Exercise Notes Sheet
struct ExerciseNotesSheet: View {
    @Environment(\.dismiss) private var dismiss
    let exerciseName: String
    @Binding var notes: String?
    @State private var localNotes: String = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("EXERCISE NOTES")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(1.5)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $localNotes)
                        .scrollContentBackground(.hidden)
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                        .frame(minHeight: 150)
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                        )
                    
                    Text("Add notes specific to \(exerciseName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.top, 20)
            .background(Color(hex: "#F5F5F7").ignoresSafeArea())
            .navigationTitle(exerciseName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        notes = localNotes.isEmpty ? nil : localNotes
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                localNotes = notes ?? ""
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

