import SwiftUI
import SwiftData

struct ExerciseLibraryView: View {
    @Query(sort: \WorkoutDay.dayNumber) private var workoutDays: [WorkoutDay]
    
    @State private var searchText = ""
    @State private var selectedMuscleGroup: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Muscle Group Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(
                            title: "All",
                            isSelected: selectedMuscleGroup == nil
                        ) {
                            selectedMuscleGroup = nil
                        }
                        
                        ForEach(allMuscleGroups, id: \.self) { group in
                            FilterChip(
                                title: group,
                                isSelected: selectedMuscleGroup == group
                            ) {
                                selectedMuscleGroup = group
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                .background(AppTheme.cardBackground)
                
                Divider()
                
                // Exercise List
                List {
                    ForEach(groupedExercises.keys.sorted(), id: \.self) { workoutName in
                        Section(header: workoutSectionHeader(workoutName)) {
                            ForEach(groupedExercises[workoutName] ?? []) { exercise in
                                NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                                    ExerciseRowView(exercise: exercise)
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .background(AppTheme.background)
            .navigationTitle("Exercises")
            .searchable(text: $searchText, prompt: "Search exercises")
        }
    }
    
    // MARK: - Computed Properties
    private var allExercises: [Exercise] {
        workoutDays.flatMap { $0.exercises }
    }
    
    private var filteredExercises: [Exercise] {
        var result = allExercises
        
        if let muscleGroup = selectedMuscleGroup {
            result = result.filter { $0.muscleGroup == muscleGroup }
        }
        
        if !searchText.isEmpty {
            result = result.filter { exercise in
                exercise.name.localizedCaseInsensitiveContains(searchText) ||
                exercise.muscleGroup.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return result
    }
    
    private var groupedExercises: [String: [Exercise]] {
        Dictionary(grouping: filteredExercises) { exercise in
            exercise.workoutDay?.name ?? "Unknown"
        }
    }
    
    private var allMuscleGroups: [String] {
        Array(Set(allExercises.map { $0.muscleGroup })).sorted()
    }
    
    private func workoutSectionHeader(_ workoutName: String) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(AppConstants.WorkoutColors.color(for: workoutName))
                .frame(width: 10, height: 10)
            
            Text(workoutName)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? AppTheme.accent : Color.gray.opacity(0.1))
                .cornerRadius(16)
        }
    }
}

// MARK: - Exercise Row View
struct ExerciseRowView: View {
    let exercise: Exercise
    
    var body: some View {
        HStack(spacing: 12) {
            // Muscle Group Icon
            Circle()
                .fill(muscleGroupColor.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: muscleGroupIcon)
                        .foregroundColor(muscleGroupColor)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 8) {
                    Label(exercise.muscleGroup, systemImage: "figure.strengthtraining.traditional")
                    
                    Text("•")
                    
                    Text("\(exercise.defaultSets) × \(exercise.defaultReps)")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if exercise.mediaURL != nil {
                Image(systemName: "play.circle.fill")
                    .foregroundColor(AppTheme.accent)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var muscleGroupColor: Color {
        switch exercise.muscleGroup.lowercased() {
        case "chest": return .red
        case "back": return .blue
        case "shoulders": return .orange
        case "biceps": return .purple
        case "triceps": return .pink
        case "quads", "hamstrings", "glutes": return .green
        case "calves": return .teal
        case "core": return .yellow
        default: return .gray
        }
    }
    
    private var muscleGroupIcon: String {
        switch exercise.muscleGroup.lowercased() {
        case "chest": return "figure.arms.open"
        case "back": return "figure.walk"
        case "shoulders": return "figure.boxing"
        case "biceps", "triceps": return "figure.strengthtraining.functional"
        case "quads", "hamstrings", "glutes", "calves": return "figure.run"
        case "core": return "figure.core.training"
        default: return "figure.mixed.cardio"
        }
    }
}

#Preview {
    ExerciseLibraryView()
        .modelContainer(for: WorkoutDay.self)
}

