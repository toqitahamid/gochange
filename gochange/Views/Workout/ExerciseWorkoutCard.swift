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
        .background(Color.white)
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
        VStack(spacing: 16) {
            // Top Row: Progress & Previous
            HStack {
                // Progress Dots
                HStack(spacing: 6) {
                    ForEach(0..<totalExercises, id: \.self) { index in
                        Circle()
                            .fill(index < exerciseNumber - 1 ? Color(hex: "#00D4AA") :
                                  index == exerciseNumber - 1 ? accentColor :
                                  Color.gray.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
                }
                
                Spacer()
                
                // Previous Workout Button
                Button {
                    showingHistory = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 12, weight: .semibold))
                        Text("History")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(accentColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(accentColor.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
            
            // Exercise Info
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Text(exerciseLog.exerciseName)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer()
                    
                    // Menu Button
                    Menu {
                        Button {
                            // TODO: Implement replace exercise
                        } label: {
                            Label("Replace Exercise", systemImage: "arrow.triangle.2.circlepath")
                        }
                        
                        Button {
                            // TODO: Implement reorder
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
                            // TODO: Implement delete
                        } label: {
                            Label("Delete Exercise", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.gray)
                            .frame(width: 32, height: 32)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                
                if let exercise = exercise {
                    HStack(spacing: 12) {
                        // Muscle Group Badge
                        HStack(spacing: 6) {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.system(size: 10))
                            Text(exercise.muscleGroup.uppercased())
                                .font(.system(size: 10, weight: .bold))
                                .tracking(1)
                        }
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                        
                        // Set Completion Status
                        HStack(spacing: 4) {
                            Text("\(completedSets)/\(exerciseLog.sets.count)")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(completedSets == exerciseLog.sets.count ? Color(hex: "#00D4AA") : .secondary)
                            Text("sets")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.06), radius: 15, x: 0, y: 5)
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
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
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
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1.5)
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
                .foregroundColor(exerciseLog.notes != nil ? Color(hex: "#00D4AA") : .gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
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
            // Column Headers
            HStack(spacing: 0) {
                Text("SET")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 50, alignment: .leading)
                
                Text(weightUnit.uppercased())
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 90, alignment: .center)
                
                Text("REPS")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 90, alignment: .center)
                
                Text("RIR")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 60, alignment: .center)
                
                Spacer()
                    .frame(width: 44) // For the play button column
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)

            // Set Rows
            VStack(spacing: 0) {
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
                            .padding(.leading, 20)
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
        }
    }
}
