import SwiftUI
import SwiftData

struct ExerciseLibraryView: View {
    @Query(sort: \WorkoutDay.dayNumber) private var workoutDays: [WorkoutDay]
    
    @State private var searchText = ""
    @State private var selectedMuscleGroup: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Muscle Group Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ExerciseFilterChip(
                        title: "All",
                        isSelected: selectedMuscleGroup == nil
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedMuscleGroup = nil
                        }
                    }
                    
                    ForEach(allMuscleGroups, id: \.self) { group in
                        ExerciseFilterChip(
                            title: group,
                            isSelected: selectedMuscleGroup == group
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedMuscleGroup = group
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
            }
            
            // Exercise List
            ScrollView {
                LazyVStack(spacing: 24) {
                    ForEach(groupedExercises.keys.sorted(), id: \.self) { workoutName in
                        VStack(alignment: .leading, spacing: 12) {
                            // Section Header
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 6, height: 6)
                                
                                Text(workoutName.uppercased())
                                    .font(.system(size: 11, weight: .bold))
                                    .tracking(1)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 4)
                            
                            VStack(spacing: 0) {
                                ForEach(Array((groupedExercises[workoutName] ?? []).enumerated()), id: \.element.id) { index, exercise in
                                    NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                                        ExerciseLibraryRowView(exercise: exercise)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    if index < (groupedExercises[workoutName]?.count ?? 0) - 1 {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.1))
                                            .frame(height: 1)
                                            .padding(.leading, 60)
                                    }
                                }
                            }
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
        }
        .background(Color(hex: "#F5F5F7").ignoresSafeArea())
        .navigationTitle("Exercises")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search exercises")
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
}

// MARK: - Exercise Filter Chip
struct ExerciseFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .white : .secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? Color(hex: "#00D4AA") : Color.gray.opacity(0.1))
                )
        }
    }
}

// MARK: - Exercise Library Row View
struct ExerciseLibraryRowView: View {
    let exercise: Exercise
    
    var body: some View {
        HStack(spacing: 14) {
            // Muscle Group Icon
            ZStack {
                Circle()
                    .fill(muscleGroupColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: muscleGroupIcon)
                    .font(.system(size: 18))
                    .foregroundColor(muscleGroupColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                HStack(spacing: 8) {
                    Text(exercise.muscleGroup)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text("\(exercise.defaultSets) × \(exercise.defaultReps)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(muscleGroupColor.opacity(0.8))
                }
            }
            
            Spacer()
            
            if exercise.mediaURL != nil {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "#00D4AA"))
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(14)
    }
    
    private var muscleGroupColor: Color {
        switch exercise.muscleGroup.lowercased() {
        case "chest": return Color(hex: "#E57373")
        case "back": return Color(hex: "#64B5F6")
        case "shoulders": return Color(hex: "#FFB74D")
        case "biceps": return Color(hex: "#BA68C8")
        case "triceps": return Color(hex: "#F06292")
        case "quads", "hamstrings", "glutes": return Color(hex: "#00D4AA")
        case "calves": return Color(hex: "#4DB6AC")
        case "core": return Color(hex: "#FFD54F")
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
    NavigationStack {
        ExerciseLibraryView()
    }
    .modelContainer(for: WorkoutDay.self)
}
