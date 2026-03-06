import SwiftUI
import SwiftData

struct EditWorkoutDayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var workoutDay: WorkoutDay

    @State private var showingAddExercise = false
    @State private var editMode: EditMode = .inactive
    @State private var editingExercise: Exercise?

    // Unified color scheme
    private let primaryAccent = Color(hex: "#6B7280")
    private let secondaryAccent = Color(hex: "#4B5563")

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Workout Info Card
                    workoutInfoCard

                    // Exercise List Card
                    exerciseListCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
            .background(Color(hex: "#F5F5F7").ignoresSafeArea())
            .navigationTitle("Edit Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveChanges()
                        dismiss()
                    }
                    .foregroundStyle(primaryAccent)
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingAddExercise) {
                AddExerciseView(workoutDay: workoutDay)
            }
            .sheet(item: $editingExercise) { exercise in
                EditExerciseView(exercise: exercise)
            }
        }
    }

    // MARK: - Workout Info Card

    private var workoutInfoCard: some View {
        VStack(spacing: 0) {
            // Icon and Basic Info Section
            HStack(spacing: 16) {
                // Workout Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [primaryAccent, secondaryAccent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)

                    Image(systemName: workoutIcon)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(.white)
                        .symbolRenderingMode(.hierarchical)
                }
                .shadow(color: primaryAccent.opacity(0.3), radius: 12, x: 0, y: 6)

                // Workout Name
                VStack(alignment: .leading, spacing: 8) {
                    Text("WORKOUT NAME")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.5)
                        .foregroundStyle(.secondary)

                    TextField("Name", text: $workoutDay.name)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .textFieldStyle(.plain)
                }
            }
            .padding(20)

            // Divider
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, Color.gray.opacity(0.12), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .padding(.horizontal, 20)

            // Settings Row
            VStack(spacing: 0) {
                // Day Number
                HStack {
                    Label("Day Number", systemImage: "number.circle.fill")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.primary)

                    Spacer()

                    // Custom stepper with modern design
                    HStack(spacing: 12) {
                        Button {
                            if workoutDay.dayNumber > 1 {
                                workoutDay.dayNumber -= 1
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(workoutDay.dayNumber > 1 ? primaryAccent : primaryAccent.opacity(0.3))
                        }
                        .disabled(workoutDay.dayNumber <= 1)

                        Text("\(workoutDay.dayNumber)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                            .frame(minWidth: 30)

                        Button {
                            if workoutDay.dayNumber < 7 {
                                workoutDay.dayNumber += 1
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(workoutDay.dayNumber < 7 ? primaryAccent : primaryAccent.opacity(0.3))
                        }
                        .disabled(workoutDay.dayNumber >= 7)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

                // Subtle divider
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 1)
                    .padding(.leading, 52)

                // Color Picker
                HStack {
                    Label("Accent Color", systemImage: "paintpalette.fill")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.primary)

                    Spacer()

                    ColorPicker("", selection: colorBinding)
                        .labelsHidden()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - Exercise List Card

    private var exerciseListCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("EXERCISES")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.8)
                    .foregroundStyle(.secondary.opacity(0.8))

                Spacer()

                // Edit mode toggle
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        editMode = editMode == .active ? .inactive : .active
                    }
                } label: {
                    Text(editMode == .active ? "Done" : "Reorder")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(primaryAccent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(primaryAccent.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 4)

            // Exercise rows
            VStack(spacing: 0) {
                if workoutDay.exercises.isEmpty {
                    // Empty state
                    VStack(spacing: 12) {
                        Image(systemName: "dumbbell")
                            .font(.system(size: 40))
                            .foregroundStyle(.tertiary)
                            .padding(.top, 20)

                        Text("No exercises yet")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.secondary)

                        Text("Add exercises to build your workout")
                            .font(.system(size: 14))
                            .foregroundStyle(.tertiary)
                            .padding(.bottom, 20)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    ForEach(Array(workoutDay.exercises.sorted { $0.sortOrder < $1.sortOrder }.enumerated()), id: \.element.id) { index, exercise in
                        Button {
                            if editMode == .inactive {
                                editingExercise = exercise
                            }
                        } label: {
                            EditableExerciseRow(
                                exercise: exercise,
                                index: index + 1,
                                primaryColor: primaryAccent,
                                isEditing: editMode == .active
                            )
                        }
                        .buttonStyle(.plain)

                        if exercise.id != workoutDay.exercises.last?.id {
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.clear, Color.gray.opacity(0.12), Color.clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(height: 1)
                                .padding(.leading, editMode == .active ? 74 : 64)
                        }
                    }
                    .onDelete(perform: deleteExercises)
                    .onMove(perform: moveExercises)
                }

                // Add Exercise Button
                Button {
                    showingAddExercise = true
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(primaryAccent.opacity(0.12))
                                .frame(width: 44, height: 44)

                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(primaryAccent)
                        }

                        Text("Add Exercise")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(primaryAccent)

                        Spacer()
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
        }
        .environment(\.editMode, $editMode)
    }

    // MARK: - Computed Properties

    private var workoutIcon: String {
        let name = workoutDay.name.lowercased()
        if name.contains("push") { return "figure.strengthtraining.traditional" }
        if name.contains("pull") { return "figure.rower" }
        if name.contains("leg") { return "figure.walk" }
        if name.contains("full") { return "figure.cross.training" }
        if name.contains("cardio") || name.contains("run") { return "figure.run" }
        if name.contains("arm") { return "figure.arms.open" }
        if name.contains("shoulder") { return "figure.flexibility" }
        if name.contains("core") || name.contains("ab") { return "figure.core.training" }
        return "dumbbell.fill"
    }

    private var colorBinding: Binding<Color> {
        Binding(
            get: { Color(hex: workoutDay.colorHex) },
            set: { workoutDay.colorHex = $0.toHex() ?? "#6B7280" }
        )
    }

    // MARK: - Methods

    private func deleteExercises(at offsets: IndexSet) {
        for index in offsets {
            let exercise = workoutDay.exercises[index]
            modelContext.delete(exercise)
        }
        workoutDay.exercises.remove(atOffsets: offsets)
        saveChanges()
    }

    private func moveExercises(from source: IndexSet, to destination: Int) {
        workoutDay.exercises.move(fromOffsets: source, toOffset: destination)
        for (index, exercise) in workoutDay.exercises.enumerated() {
            exercise.sortOrder = index
        }
        saveChanges()
    }

    private func saveChanges() {
        try? modelContext.save()
    }
}

// MARK: - Edit Exercise View

struct EditExerciseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var exercise: Exercise

    private let muscleGroups = ["Chest", "Back", "Shoulders", "Biceps", "Triceps", "Quads", "Hamstrings", "Glutes", "Calves", "Core", "Full Body"]
    private let primaryAccent = Color(hex: "#6B7280")
    private let secondaryAccent = Color(hex: "#4B5563")

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Exercise Name Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("EXERCISE NAME")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1.5)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)

                        TextField("Exercise name", text: $exercise.name)
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .padding(20)
                            .background(Color.gray.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal, 20)
                            .padding(.bottom, 8)
                    }
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    )

                    // Muscle Group Picker Card
                    VStack(spacing: 16) {
                        HStack {
                            Text("MUSCLE GROUP")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(1.5)
                                .foregroundStyle(.secondary)

                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                        Picker("Muscle Group", selection: $exercise.muscleGroup) {
                            ForEach(muscleGroups, id: \.self) { group in
                                Text(group).tag(group)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                    }
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    )

                    // Sets & Reps Card
                    VStack(spacing: 0) {
                        HStack {
                            Text("DEFAULT VALUES")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(1.5)
                                .foregroundStyle(.secondary)

                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 16)

                        // Sets
                        HStack {
                            Label("Sets", systemImage: "square.stack.3d.up.fill")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.primary)

                            Spacer()

                            HStack(spacing: 12) {
                                Button {
                                    if exercise.defaultSets > 1 {
                                        exercise.defaultSets -= 1
                                    }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundStyle(exercise.defaultSets > 1 ? primaryAccent : primaryAccent.opacity(0.3))
                                }
                                .disabled(exercise.defaultSets <= 1)

                                Text("\(exercise.defaultSets)")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundStyle(.primary)
                                    .frame(minWidth: 30)

                                Button {
                                    if exercise.defaultSets < 10 {
                                        exercise.defaultSets += 1
                                    }
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundStyle(exercise.defaultSets < 10 ? primaryAccent : primaryAccent.opacity(0.3))
                                }
                                .disabled(exercise.defaultSets >= 10)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)

                        Rectangle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 1)
                            .padding(.leading, 52)

                        // Reps
                        HStack {
                            Label("Reps", systemImage: "repeat")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.primary)

                            Spacer()

                            TextField("Reps", text: $exercise.defaultReps)
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(primaryAccent)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.default)
                                .frame(width: 80)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .padding(.bottom, 8)
                    }
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    )

                    // Notes Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("NOTES")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1.5)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)

                        TextEditor(text: Binding(
                            get: { exercise.notes ?? "" },
                            set: { exercise.notes = $0.isEmpty ? nil : $0 }
                        ))
                        .font(.system(size: 15))
                        .foregroundStyle(.primary)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 120)
                        .padding(16)
                        .background(Color.gray.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                    }
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
            .background(Color(hex: "#F5F5F7").ignoresSafeArea())
            .navigationTitle("Edit Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveChanges()
                        dismiss()
                    }
                    .foregroundStyle(primaryAccent)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func saveChanges() {
        try? modelContext.save()
    }
}

// MARK: - Add Exercise View

struct AddExerciseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let workoutDay: WorkoutDay

    @State private var name = ""
    @State private var muscleGroup = "Chest"
    @State private var defaultSets = 3
    @State private var defaultReps = "10"

    private let muscleGroups = ["Chest", "Back", "Shoulders", "Biceps", "Triceps", "Quads", "Hamstrings", "Glutes", "Calves", "Core", "Full Body"]
    private let primaryAccent = Color(hex: "#6B7280")
    private let secondaryAccent = Color(hex: "#4B5563")

    // Common exercise presets
    private let exercisePresets: [(name: String, muscle: String, sets: Int, reps: String)] = [
        ("Bench Press", "Chest", 3, "8-10"),
        ("Squats", "Quads", 4, "8-12"),
        ("Deadlift", "Back", 3, "5-8"),
        ("Pull-ups", "Back", 3, "8-12"),
        ("Shoulder Press", "Shoulders", 3, "10-12"),
        ("Bicep Curls", "Biceps", 3, "12-15")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 20) {
                        // Header Card
                        headerCard

                        // Quick Presets
                        if name.isEmpty {
                            quickPresetsCard
                        }

                        // Exercise Name Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("EXERCISE NAME")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1.5)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)

                        TextField("Exercise name", text: $name)
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .padding(20)
                            .background(Color.gray.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal, 20)
                            .padding(.bottom, 8)
                    }
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    )

                    // Muscle Group Selector Card
                    VStack(spacing: 16) {
                        HStack {
                            Text("MUSCLE GROUP")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(1.5)
                                .foregroundStyle(.secondary)

                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                        // Visual muscle group pills
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(muscleGroups, id: \.self) { group in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        muscleGroup = group
                                    }
                                } label: {
                                    VStack(spacing: 8) {
                                        Image(systemName: iconForMuscleGroup(group))
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundStyle(muscleGroup == group ? .white : primaryAccent)

                                        Text(group)
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(muscleGroup == group ? .white : .primary)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.8)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        muscleGroup == group ?
                                        AnyShapeStyle(LinearGradient(
                                            colors: [primaryAccent, secondaryAccent],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )) :
                                        AnyShapeStyle(Color.gray.opacity(0.08))
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(muscleGroup == group ? Color.clear : Color.gray.opacity(0.15), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                    }
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    )

                    // Sets & Reps Card
                    VStack(spacing: 0) {
                        HStack {
                            Text("DEFAULT VALUES")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(1.5)
                                .foregroundStyle(.secondary)

                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 16)

                        // Sets
                        HStack {
                            Label("Sets", systemImage: "square.stack.3d.up.fill")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.primary)

                            Spacer()

                            HStack(spacing: 12) {
                                Button {
                                    if defaultSets > 1 {
                                        defaultSets -= 1
                                    }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundStyle(defaultSets > 1 ? primaryAccent : primaryAccent.opacity(0.3))
                                }
                                .disabled(defaultSets <= 1)

                                Text("\(defaultSets)")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundStyle(.primary)
                                    .frame(minWidth: 30)

                                Button {
                                    if defaultSets < 10 {
                                        defaultSets += 1
                                    }
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundStyle(defaultSets < 10 ? primaryAccent : primaryAccent.opacity(0.3))
                                }
                                .disabled(defaultSets >= 10)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)

                        Rectangle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 1)
                            .padding(.leading, 52)

                        // Reps
                        HStack {
                            Label("Reps", systemImage: "repeat")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.primary)

                            Spacer()

                            TextField("Reps", text: $defaultReps)
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(primaryAccent)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.default)
                                .frame(width: 80)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .padding(.bottom, 8)
                    }
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 120)
            }
            .background(Color(hex: "#F5F5F7").ignoresSafeArea())

            // Sticky Bottom Button
            VStack {
                Spacer()

                // Gradient fade
                LinearGradient(
                    colors: [
                        Color(hex: "#F5F5F7").opacity(0),
                        Color(hex: "#F5F5F7").opacity(0.95),
                        Color(hex: "#F5F5F7")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 60)

                // Add Button
                Button {
                    addExercise()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20, weight: .semibold))

                        Text("Add Exercise")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: name.isEmpty ? [Color.gray, Color.gray.opacity(0.8)] : [primaryAccent, secondaryAccent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .shadow(color: (name.isEmpty ? Color.gray : primaryAccent).opacity(0.3), radius: 12, x: 0, y: 6)
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(name.isEmpty)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .background(Color(hex: "#F5F5F7"))
            }
        }
        .navigationTitle("Add Exercise")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundStyle(.secondary)
            }
        }
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [primaryAccent.opacity(0.2), primaryAccent.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)

                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(primaryAccent)
            }

            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text("New Exercise")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Text("Add to \(workoutDay.name)")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - Quick Presets Card

    private var quickPresetsCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("QUICK ADD")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("Popular exercises")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(exercisePresets, id: \.name) { preset in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            name = preset.name
                            muscleGroup = preset.muscle
                            defaultSets = preset.sets
                            defaultReps = preset.reps
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: iconForMuscleGroup(preset.muscle))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(primaryAccent)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(preset.name)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)

                                Text("\(preset.sets) × \(preset.reps)")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                        .padding(12)
                        .background(Color.gray.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - Helper Functions

    private func iconForMuscleGroup(_ group: String) -> String {
        switch group.lowercased() {
        case "chest": return "figure.strengthtraining.traditional"
        case "back": return "figure.rower"
        case "shoulders": return "figure.flexibility"
        case "biceps": return "figure.arms.open"
        case "triceps": return "figure.arms.open"
        case "quads": return "figure.walk"
        case "hamstrings": return "figure.walk"
        case "glutes": return "figure.walk"
        case "calves": return "figure.walk"
        case "core": return "figure.core.training"
        case "full body": return "figure.cross.training"
        default: return "dumbbell.fill"
        }
    }

    private func addExercise() {
        let exercise = Exercise(
            name: name,
            defaultSets: defaultSets,
            defaultReps: defaultReps,
            muscleGroup: muscleGroup
        )
        workoutDay.exercises.append(exercise)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Color Extension for Hex
extension Color {
    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components else { return nil }

        let r = components[0]
        let g = components.count > 1 ? components[1] : r
        let b = components.count > 2 ? components[2] : r

        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}

#Preview {
    let workoutDay = WorkoutDay(
        name: "Push",
        dayNumber: 1,
        colorHex: "#6B7280",
        exercises: [
            Exercise(name: "Bench Press", defaultSets: 3, defaultReps: "8", muscleGroup: "Chest"),
            Exercise(name: "Shoulder Press", defaultSets: 3, defaultReps: "10", muscleGroup: "Shoulders")
        ]
    )

    return EditWorkoutDayView(workoutDay: workoutDay)
        .modelContainer(for: [WorkoutDay.self, Exercise.self])
}
