import SwiftUI
import SwiftData

struct ExerciseWorkoutCard: View {
    @Binding var exerciseLog: ExerciseLog
    let exercise: Exercise?
    let accentColor: Color
    let exerciseNumber: Int
    let totalExercises: Int
    let previousSets: [PreviousSetInfo]
    let suggestion: OverloadSuggestion?
    let activeSetTimer: SetTimerState? // To check if a set is playing
    let onAddSet: () -> Void
    let onRemoveSet: (Int) -> Void
    let onToggleSetCompletion: (Int) -> Void
    let onPlaySet: (Int) -> Void
    let onPauseSet: () -> Void // Callback to pause the active timer
    
    // Exercise Management Callbacks
    let onDeleteExercise: () -> Void
    let onReorderExercise: () -> Void
    let onReplaceExercise: () -> Void

    @State private var showingNotes = false
    @State private var showingHistory = false

    private var completedSets: Int {
        exerciseLog.sets.filter { $0.isCompleted }.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Exercise Header Section
                exerciseHeaderSection

                // Mini Progress Chart
                ExerciseMiniChart(
                    exerciseId: exerciseLog.exerciseId,
                    accentColor: accentColor
                )

                // Comparison Metrics
                ComparisonMetricsRow(
                    currentSets: exerciseLog.sets,
                    previousSets: previousSets,
                    accentColor: accentColor
                )

                // Progressive Overload Suggestion
                if let suggestion = suggestion {
                    ProgressiveOverloadBanner(suggestion: suggestion)
                }

                // Set List Section
                setListSection

                // Exercise Actions
                exerciseActionsRow
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(AppColors.background)
        .sheet(isPresented: $showingNotes) {
            ExerciseNotesSheet(exerciseName: exerciseLog.exerciseName, notes: $exerciseLog.notes)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingHistory) {
            PreviousWorkoutHistorySheet(
                exerciseId: exerciseLog.exerciseId,
                exerciseName: exerciseLog.exerciseName,
                accentColor: accentColor
            )
        }
    }

    // MARK: - Exercise Header Section

    private var exerciseHeaderSection: some View {
        VStack(spacing: 0) {
            // Top accent bar
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(accentColor)
                    .frame(width: 4, height: 40)

                VStack(alignment: .leading, spacing: 2) {
                    // Exercise number label
                    Text("EXERCISE \(exerciseNumber) OF \(totalExercises)")
                        .font(AppFonts.label(10))
                        .tracking(1.5)
                        .foregroundColor(AppColors.textTertiary)

                    // Progress indicator
                    HStack(spacing: 4) {
                        ForEach(0..<totalExercises, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(index < exerciseNumber ? accentColor : AppColors.textTertiary.opacity(0.3))
                                .frame(height: 3)
                        }
                    }
                }
                .padding(.leading, 12)

                Spacer()

                // History Button
                Button {
                    showingHistory = true
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(accentColor)
                    .frame(width: 36, height: 36)
                    .background(accentColor.opacity(0.1))
                    .clipShape(Circle())
                }

                // Menu Button
                Menu {
                    Button {
                        onReplaceExercise()
                    } label: {
                        Label("Replace Exercise", systemImage: "arrow.triangle.2.circlepath")
                    }

                    Button {
                        onReorderExercise()
                    } label: {
                        Label("Reorder Exercise", systemImage: "arrow.up.arrow.down")
                    }

                    Button {
                        showingNotes = true
                    } label: {
                        Label("Add Notes", systemImage: "note.text")
                    }

                    Divider()

                    Button(role: .destructive) {
                        onDeleteExercise()
                    } label: {
                        Label("Delete Exercise", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(Color.gray.opacity(0.08))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider()
                .padding(.horizontal, 16)

            // Exercise Name & Details
            VStack(alignment: .leading, spacing: 12) {
                Text(exerciseLog.exerciseName)
                    .font(AppFonts.title(26))
                    .foregroundColor(AppColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                if let exercise = exercise {
                    HStack(spacing: 10) {
                        // Muscle Group Badge
                        HStack(spacing: 5) {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.system(size: 11, weight: .semibold))
                            Text(exercise.muscleGroup.uppercased())
                                .font(AppFonts.label(11))
                                .tracking(0.8)
                        }
                        .foregroundColor(accentColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(accentColor.opacity(0.1))
                        .clipShape(Capsule())

                        // Set Completion Status
                        HStack(spacing: 4) {
                            Image(systemName: completedSets == exerciseLog.sets.count ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(completedSets == exerciseLog.sets.count ? AppColors.success : AppColors.textTertiary)

                            Text("\(completedSets)/\(exerciseLog.sets.count) sets")
                                .font(AppFonts.label(12))
                                .foregroundColor(completedSets == exerciseLog.sets.count ? AppColors.success : AppColors.textSecondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            completedSets == exerciseLog.sets.count ?
                            AppColors.success.opacity(0.1) :
                            Color.gray.opacity(0.08)
                        )
                        .clipShape(Capsule())

                        // Notes indicator
                        if exerciseLog.notes != nil {
                            Image(systemName: "note.text")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AppColors.success)
                                .frame(width: 28, height: 28)
                                .background(AppColors.success.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 20)
        }
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - Set List Section

    private var setListSection: some View {
        SetListSectionView(
            exerciseLog: $exerciseLog,
            exerciseIndex: exerciseNumber - 1,
            previousSets: previousSets,
            accentColor: accentColor,
            activeSetTimer: activeSetTimer,
            onRemoveSet: onRemoveSet,
            onToggleSetCompletion: onToggleSetCompletion,
            onPlaySet: onPlaySet,
            onPauseSet: onPauseSet
        )
    }

    // MARK: - Exercise Actions Row

    private var exerciseActionsRow: some View {
        HStack(spacing: 12) {
            // Add Set Button
            Button(action: onAddSet) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                    Text("Add Set")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(accentColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppLayout.miniRadius))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.miniRadius)
                        .stroke(accentColor.opacity(0.2), lineWidth: 1.5)
                )
            }

            // Previous Button
            Button {
                showingHistory = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 16))
                    Text("Previous")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(AppColors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppLayout.miniRadius))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.miniRadius)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                )
            }

            // Exercise Notes Button
            Button {
                showingNotes = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: exerciseLog.notes != nil ? "note.text" : "note.text.badge.plus")
                        .font(.system(size: 16))
                    Text("Notes")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(exerciseLog.notes != nil ? AppColors.success : AppColors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppLayout.miniRadius))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.miniRadius)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
            }
        }
    }
}

// MARK: - Set List Section View
struct SetListSectionView: View {
    @Binding var exerciseLog: ExerciseLog
    let exerciseIndex: Int
    let previousSets: [PreviousSetInfo]
    let accentColor: Color
    let activeSetTimer: SetTimerState?
    let onRemoveSet: (Int) -> Void
    let onToggleSetCompletion: (Int) -> Void
    let onPlaySet: (Int) -> Void
    let onPauseSet: () -> Void
    
    @AppStorage("weightUnit") private var weightUnit: String = "lbs"
    
    var body: some View {
        VStack(spacing: 0) {
            // Column Headers (inside the card)
            HStack(spacing: 0) {
                Text("SET")
                    .font(AppFonts.label(10))
                    .tracking(1)
                    .foregroundColor(AppColors.textTertiary)
                    .frame(width: 50, alignment: .leading)

                Text(weightUnit.uppercased())
                    .font(AppFonts.label(10))
                    .tracking(1)
                    .foregroundColor(AppColors.textTertiary)
                    .frame(width: 90, alignment: .center)

                Text("REPS")
                    .font(AppFonts.label(10))
                    .tracking(1)
                    .foregroundColor(AppColors.textTertiary)
                    .frame(width: 90, alignment: .center)

                Text("RIR")
                    .font(AppFonts.label(10))
                    .tracking(1)
                    .foregroundColor(AppColors.textTertiary)
                    .frame(width: 60, alignment: .center)

                Spacer()
                    .frame(width: 44) // For the play button column
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider()
                .padding(.horizontal, 16)

            // Set Rows
            ForEach(Array(exerciseLog.sets.enumerated()), id: \.element.id) { index, _ in
                let previousSet = previousSets.first { $0.setNumber == exerciseLog.sets[index].setNumber }

                // Check if this specific set is playing
                let isPlaying = activeSetTimer?.exerciseIndex == exerciseIndex &&
                                activeSetTimer?.setIndex == index &&
                                activeSetTimer?.isPaused == false

                SetInputCard(
                    setLog: $exerciseLog.sets[index],
                    accentColor: accentColor,
                    previousSet: previousSet,
                    isPlaying: isPlaying,
                    weightUnit: weightUnit,
                    onRemove: exerciseLog.sets.count > 1 ? { onRemoveSet(index) } : nil,
                    onToggleCompletion: { onToggleSetCompletion(index) },
                    onPlaySet: { onPlaySet(index) },
                    onPauseSet: onPauseSet,
                    onUpdateWeight: { newWeight, newUnit, applyToNext in
                        // Update unit if changed
                        if newUnit != weightUnit {
                            weightUnit = newUnit
                        }

                        // Apply to next sets if requested
                        if applyToNext {
                            for i in (index + 1)..<exerciseLog.sets.count {
                                exerciseLog.sets[i].weight = newWeight
                            }
                        }
                    }
                )

                if index < exerciseLog.sets.count - 1 {
                    Divider()
                        .padding(.horizontal, 16)
                }
            }
        }
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}
