import SwiftUI
import SwiftData

struct ExerciseSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \WorkoutDay.dayNumber) private var workoutDays: [WorkoutDay]
    
    let onSelect: (Exercise) -> Void
    
    @State private var searchText = ""
    @State private var selectedMuscleGroup: String?
    
    var body: some View {
        NavigationStack {
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
                                        Button {
                                            onSelect(exercise)
                                            dismiss()
                                        } label: {
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
                                .clipShape(RoundedRectangle(cornerRadius: 24))
                                .background(
                                    RoundedRectangle(cornerRadius: 24)
                                        .fill(Color.white)
                                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .background(Color(hex: "#F5F5F7").ignoresSafeArea())
            .navigationTitle("Select Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search exercises")
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
}
