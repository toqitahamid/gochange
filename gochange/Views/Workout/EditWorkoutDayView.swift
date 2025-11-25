import SwiftUI
import SwiftData

struct EditWorkoutDayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var workoutDay: WorkoutDay
    
    @State private var showingAddExercise = false
    @State private var editMode: EditMode = .inactive
    
    var body: some View {
        NavigationStack {
            List {
                // Workout Day Info Section
                Section("Workout Info") {
                    HStack {
                        Text("Name")
                        Spacer()
                        TextField("Workout Name", text: $workoutDay.name)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Day Number")
                        Spacer()
                        Stepper("\(workoutDay.dayNumber)", value: $workoutDay.dayNumber, in: 1...7)
                    }
                    
                    ColorPicker("Color", selection: colorBinding)
                }
                
                // Exercises Section
                Section {
                    ForEach(workoutDay.exercises) { exercise in
                        NavigationLink {
                            EditExerciseView(exercise: exercise)
                        } label: {
                            EditExerciseRowView(exercise: exercise)
                        }
                    }
                    .onDelete(perform: deleteExercises)
                    .onMove(perform: moveExercises)
                    
                    Button {
                        showingAddExercise = true
                    } label: {
                        Label("Add Exercise", systemImage: "plus.circle.fill")
                            .foregroundColor(AppTheme.accent)
                    }
                } header: {
                    HStack {
                        Text("Exercises")
                        Spacer()
                        EditButton()
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Edit \(workoutDay.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveChanges()
                        dismiss()
                    }
                }
            }
            .environment(\.editMode, $editMode)
            .sheet(isPresented: $showingAddExercise) {
                AddExerciseView(workoutDay: workoutDay)
            }
        }
    }
    
    private var colorBinding: Binding<Color> {
        Binding(
            get: { Color(hex: workoutDay.colorHex) },
            set: { workoutDay.colorHex = $0.toHex() ?? "#7CB9A8" }
        )
    }
    
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
        saveChanges()
    }
    
    private func saveChanges() {
        try? modelContext.save()
    }
}

// MARK: - Edit Exercise Row View
struct EditExerciseRowView: View {
    let exercise: Exercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(exercise.name)
                .font(.headline)
            
            HStack(spacing: 8) {
                Label(exercise.muscleGroup, systemImage: "figure.strengthtraining.traditional")
                Text("•")
                Text("\(exercise.defaultSets) × \(exercise.defaultReps)")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Edit Exercise View
struct EditExerciseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var exercise: Exercise
    
    private let muscleGroups = ["Chest", "Back", "Shoulders", "Biceps", "Triceps", "Quads", "Hamstrings", "Glutes", "Calves", "Core", "Full Body"]
    
    var body: some View {
        Form {
            Section("Exercise Details") {
                TextField("Exercise Name", text: $exercise.name)
                
                Picker("Muscle Group", selection: $exercise.muscleGroup) {
                    ForEach(muscleGroups, id: \.self) { group in
                        Text(group).tag(group)
                    }
                }
            }
            
            Section("Defaults") {
                Stepper("Sets: \(exercise.defaultSets)", value: $exercise.defaultSets, in: 1...10)
                
                HStack {
                    Text("Reps")
                    Spacer()
                    TextField("Reps", text: $exercise.defaultReps)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.default)
                        .frame(width: 80)
                }
            }
            
            Section("Notes") {
                TextEditor(text: Binding(
                    get: { exercise.notes ?? "" },
                    set: { exercise.notes = $0.isEmpty ? nil : $0 }
                ))
                .frame(minHeight: 100)
            }
        }
        .navigationTitle("Edit Exercise")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: exercise.name) { _, _ in saveChanges() }
        .onChange(of: exercise.muscleGroup) { _, _ in saveChanges() }
        .onChange(of: exercise.defaultSets) { _, _ in saveChanges() }
        .onChange(of: exercise.defaultReps) { _, _ in saveChanges() }
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
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise Details") {
                    TextField("Exercise Name", text: $name)
                    
                    Picker("Muscle Group", selection: $muscleGroup) {
                        ForEach(muscleGroups, id: \.self) { group in
                            Text(group).tag(group)
                        }
                    }
                }
                
                Section("Defaults") {
                    Stepper("Sets: \(defaultSets)", value: $defaultSets, in: 1...10)
                    
                    HStack {
                        Text("Reps")
                        Spacer()
                        TextField("Reps", text: $defaultReps)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.default)
                            .frame(width: 80)
                    }
                }
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addExercise()
                    }
                    .disabled(name.isEmpty)
                }
            }
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
        colorHex: "#7CB9A8",
        exercises: [
            Exercise(name: "Bench Press", defaultSets: 3, defaultReps: "8", muscleGroup: "Chest")
        ]
    )
    
    return EditWorkoutDayView(workoutDay: workoutDay)
        .modelContainer(for: [WorkoutDay.self, Exercise.self])
}

