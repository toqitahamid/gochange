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
    @State private var currentExerciseIndex: Int = 0
    @State private var showingRestTimerAlert = false
    @State private var showingSetConflictAlert = false
    @State private var pendingSetStart: PendingSetStart?
    
    private struct PendingSetStart {
        let exerciseIndex: Int
        let setIndex: Int
    }
    
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
        ZStack {
            if !workoutManager.isMinimized {
                // Full Workout View
                VStack(spacing: 0) {
                    // Sheet-style Header
                    workoutHeaderBar

                    // Swipe-based Exercise Navigation
                    TabView(selection: $currentExerciseIndex) {
                        ForEach(Array(workoutManager.exerciseLogs.enumerated()), id: \.element.id) { index, exerciseLog in
                            ExerciseWorkoutCard(
                                exerciseLog: $workoutManager.exerciseLogs[index],
                                exercise: getExercise(for: exerciseLog),
                                accentColor: accentColor,
                                exerciseNumber: index + 1,
                                totalExercises: workoutManager.exerciseLogs.count,
                                previousSets: workoutManager.previousSetData[exerciseLog.exerciseId] ?? [],
                                suggestion: workoutManager.suggestions[exerciseLog.exerciseId],
                                activeSetTimer: workoutManager.activeSetTimer,
                                onAddSet: {
                                    addSet(to: index)
                                },
                                onRemoveSet: { setIndex in
                                    removeSet(at: setIndex, from: index)
                                },
                                onToggleSetCompletion: { setIndex in
                                    workoutManager.toggleSetCompletion(exerciseIndex: index, setIndex: setIndex)
                                },
                                onPlaySet: { setIndex in
                                    if workoutManager.activeSetTimer != nil {
                                        pendingSetStart = PendingSetStart(exerciseIndex: index, setIndex: setIndex)
                                        showingSetConflictAlert = true
                                    } else if workoutManager.activeRestTimer != nil {
                                        pendingSetStart = PendingSetStart(exerciseIndex: index, setIndex: setIndex)
                                        showingRestTimerAlert = true
                                    } else {
                                        workoutManager.startSetTimer(exerciseIndex: index, setIndex: setIndex)
                                    }
                                },
                                onPauseSet: {
                                    workoutManager.pauseSetTimer()
                                }
                            )
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
                .background(AppColors.background.ignoresSafeArea())
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            // Swipe down to minimize
                            if value.translation.height > 100 {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    workoutManager.minimize()
                                }
                            }
                        }
                )
            }
            
            // Unified Miniplayer (shown when minimized OR when set/rest timer is active)
            if workoutManager.isMinimized || workoutManager.activeSetTimer != nil || workoutManager.activeRestTimer != nil {
                VStack {
                    Spacer()
                    WorkoutMiniplayer(
                        workoutDayName: workoutDay.name,
                        exerciseName: getCurrentExerciseName(),
                        workoutStartTime: workoutManager.startTime ?? Date(),
                        workoutIsPaused: workoutManager.isPaused,
                        setTimerState: workoutManager.activeSetTimer,
                        restTimerState: workoutManager.activeRestTimer,
                        currentHeartRate: workoutManager.currentHeartRate,
                        accentColor: accentColor,
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
                    .padding(.horizontal, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .zIndex(10)
            }
        }
        .background(AppColors.background.ignoresSafeArea())
        .toolbar(.hidden, for: .tabBar)
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
        .alert("Stop Rest Timer?", isPresented: $showingRestTimerAlert) {
            Button("Cancel", role: .cancel) {
                pendingSetStart = nil
            }
            Button("Start Set") {
                if let pending = pendingSetStart {
                    workoutManager.stopRestTimer()
                    workoutManager.startSetTimer(exerciseIndex: pending.exerciseIndex, setIndex: pending.setIndex)
                    pendingSetStart = nil
                }
            }
        } message: {
            Text("A rest timer is currently running. Do you want to stop it and start your set?")
        }
        .alert("Stop Current Set?", isPresented: $showingSetConflictAlert) {
            Button("Cancel", role: .cancel) {
                pendingSetStart = nil
            }
            Button("Stop & Start New") {
                if let pending = pendingSetStart {
                    workoutManager.stopSetTimer()
                    workoutManager.stopRestTimer() // Cancel the auto-rest that stopSetTimer starts
                    workoutManager.startSetTimer(exerciseIndex: pending.exerciseIndex, setIndex: pending.setIndex)
                    pendingSetStart = nil
                }
            }
        } message: {
            Text("A set is currently running. Do you want to stop it and start this one?")
        }
        .alert("Error Saving Workout", isPresented: $workoutManager.showingSaveError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(workoutManager.dataSaveError?.localizedDescription ?? "Unknown error occurred.")
        }
        .onAppear {
            currentExerciseIndex = 0
        }
        .onChange(of: completedSetsCount) { oldValue, newValue in
            // Live activity update is handled in WorkoutManager
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
            .presentationDetents([.large])
        }
        .fullScreenCover(isPresented: $workoutManager.showingSummary) {
            if let summary = workoutManager.workoutSummary {
                WorkoutSummaryView(
                    summary: summary,
                    accentColor: workoutManager.summaryAccentColor,
                    onDismiss: {
                        workoutManager.dismissSummary()
                    }
                )
            }
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    // MARK: - Computed Properties

    private var workoutHeaderBar: some View {
        VStack(spacing: 0) {
            // Top Bar
            ZStack {
                // Center: Workout Name
                Text(workoutDay.name.uppercased())
                    .font(.system(size: 14, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .padding(.horizontal, 60) // Avoid overlapping with side items
                
                // Left & Right Items
                HStack {
                    // Timer
                    if let startTime = workoutManager.startTime {
                        WorkoutElapsedTime(startTime: startTime)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(20)
                    }
                    
                    Spacer()
                    
                    // Close Button
                    Button {
                        showingCancelAlert = true
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color.gray)
                            .frame(width: 32, height: 32)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 16)
            
            // Controls Row
            HStack {
                // Pause/Resume
                Button {
                    workoutManager.togglePause()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: workoutManager.isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 14))
                        Text(workoutManager.isPaused ? "Resume" : "Pause")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(20)
                }
                
                Spacer()
                
                // Complete Button
                Button {
                    showingRPEInput = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                        Text("Finish Workout")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(workoutManager.canComplete ? AppColors.success : Color.gray)
                    )
                }
                .disabled(!workoutManager.canComplete)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            
            // Divider
            Rectangle()
                .fill(Color.gray.opacity(0.15))
                .frame(height: 1)
        }
        .background(AppColors.surface)
    }

    // MARK: - Methods
    
    private func getExercise(for log: ExerciseLog) -> Exercise? {
        workoutDay.exercises.first { $0.id == log.exerciseId }
    }
    
    private func getCurrentExerciseName() -> String? {
        // If there's an active set timer, use that exercise
        if let setTimer = workoutManager.activeSetTimer {
            return setTimer.exerciseName
        }
        // Otherwise use the current exercise from the tab view
        if currentExerciseIndex < workoutManager.exerciseLogs.count {
            return workoutManager.exerciseLogs[currentExerciseIndex].exerciseName
        }
        return nil
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

// MARK: - Workout Timer Display (Large format for header)
struct WorkoutTimerDisplay: View {
    let startTime: Date
    let isPaused: Bool
    @State private var elapsed: TimeInterval = 0
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        Text(elapsed.formattedDuration)
            .font(.system(size: 40, weight: .bold, design: .rounded))
            .foregroundColor(.primary)
            .opacity(isPaused ? 0.5 : 1.0)
            .onReceive(timer) { _ in
                if !isPaused {
                    elapsed = Date().timeIntervalSince(startTime)
                }
            }
    }
}

// MARK: - Workout Elapsed Time (Small format)
struct WorkoutElapsedTime: View {
    let startTime: Date
    @State private var elapsed: TimeInterval = 0

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Text(elapsed.formattedDuration)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.secondary)
            .onReceive(timer) { _ in
                elapsed = Date().timeIntervalSince(startTime)
            }
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
                                .foregroundColor(AppColors.error)
                            
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

                    
                    // Notes Button
                    Button(action: onNotesTap) {
                        HStack(spacing: 6) {
                            Image(systemName: hasNotes ? "note.text" : "note.text.badge.plus")
                                .font(.system(size: 14))
                            Text("Notes")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(hasNotes ? AppColors.success : .gray)
                    }
                }
            }
        }
        .padding(AppLayout.cardPadding)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
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
                                    .foregroundColor(AppColors.success)
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
                            .foregroundColor(isFullyCompleted ? AppColors.success : .secondary)
                        
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
                            .foregroundColor(exerciseLog.notes != nil ? AppColors.success : .gray)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                .stroke(
                    isFullyCompleted ? AppColors.success.opacity(0.3) : Color.gray.opacity(0.1),
                    lineWidth: 1
                )
        )
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
                        .foregroundColor(AppColors.success.opacity(0.7))
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
                        .stroke(setLog.isCompleted ? AppColors.success : AppColors.textTertiary, lineWidth: 2)
                        .frame(width: 28, height: 28)

                    if setLog.isCompleted {
                        Circle()
                            .fill(AppColors.success)
                            .frame(width: 28, height: 28)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .frame(width: 44, alignment: .center)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            setLog.isCompleted ?
            AppColors.success.opacity(0.08) :
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
                        .foregroundColor(AppColors.textPrimary)
                        .frame(minHeight: 150)
                        .padding(16)
                        .background(AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppLayout.miniRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppLayout.miniRadius)
                                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                        )
                    
                    Text("Add any notes about this workout - how you felt, adjustments made, etc.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.top, 20)
            .background(AppColors.background.ignoresSafeArea())
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
                        .foregroundColor(AppColors.textPrimary)
                        .frame(minHeight: 150)
                        .padding(16)
                        .background(AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppLayout.miniRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppLayout.miniRadius)
                                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                        )
                    
                    Text("Add notes specific to \(exerciseName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.top, 20)
            .background(AppColors.background.ignoresSafeArea())
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

