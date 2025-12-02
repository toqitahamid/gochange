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
    let onAddSet: () -> Void
    let onRemoveSet: (Int) -> Void
    let onToggleSetCompletion: (Int) -> Void

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
        .background(Color(hex: "#F5F5F7"))
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
            // Superset/Circuit Indicator (if grouped)
            if let groupType = exerciseLog.groupType {
                HStack(spacing: 8) {
                    Image(systemName: groupType.icon)
                        .font(.system(size: 12, weight: .semibold))
                    Text(groupType.displayName)
                        .font(.system(size: 13, weight: .bold))
                        .tracking(1.2)
                    Spacer()
                }
                .foregroundColor(Color(hex: groupType.color))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: groupType.color).opacity(0.12))
                )
            }

            // Progress Indicator
            HStack(spacing: 8) {
                ForEach(0..<totalExercises, id: \.self) { index in
                    Circle()
                        .fill(index < exerciseNumber - 1 ? Color(hex: "#00D4AA") :
                              index == exerciseNumber - 1 ? accentColor :
                              Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }

                Spacer()

                Text("Exercise \(exerciseNumber) of \(totalExercises)")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.2)
                    .foregroundColor(.secondary)

                // Previous Workout Button
                Button {
                    showingHistory = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Previous")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(accentColor.opacity(0.12))
                    )
                }
            }

            // Exercise Name and Info
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(exerciseLog.exerciseName)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)

                    Spacer()

                    // Three-dots menu
                    Menu {
                        Button {
                            // TODO: Implement replace exercise
                        } label: {
                            Label("Replace Exercise", systemImage: "arrow.triangle.2.circlepath")
                        }

                        Button {
                            // TODO: Implement reorder (move up/down)
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
                            // TODO: Implement delete exercise
                        } label: {
                            Label("Delete Exercise", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.gray.opacity(0.6))
                    }
                }

                if let exercise = exercise {
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Text(exercise.muscleGroup)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }

                        Text("•")
                            .foregroundColor(.secondary)

                        HStack(spacing: 4) {
                            Text("\(completedSets)/\(exerciseLog.sets.count)")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(completedSets == exerciseLog.sets.count ? Color(hex: "#00D4AA") : .secondary)
                            Text("sets complete")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - Set List Section

    private var setListSection: some View {
        VStack(spacing: 0) {
            // Section Header
            HStack {
                Text("SETS")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.8)
                    .foregroundColor(.secondary)

                Spacer()
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 12)

            // Set Cards
            VStack(spacing: 12) {
                ForEach(Array(exerciseLog.sets.enumerated()), id: \.element.id) { index, _ in
                    let previousSet = previousSets.first { $0.setNumber == exerciseLog.sets[index].setNumber }
                    SetInputCard(
                        setLog: $exerciseLog.sets[index],
                        accentColor: accentColor,
                        previousSet: previousSet,
                        onRemove: exerciseLog.sets.count > 1 ? { onRemoveSet(index) } : nil,
                        onToggleCompletion: { onToggleSetCompletion(index) }
                    )
                }
            }
        }
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
