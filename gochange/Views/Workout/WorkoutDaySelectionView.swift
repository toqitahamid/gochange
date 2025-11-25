import SwiftUI
import SwiftData

struct WorkoutDaySelectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutDay.dayNumber) private var workoutDays: [WorkoutDay]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    
    @State private var selectedWorkoutDay: WorkoutDay?
    @State private var editingWorkoutDay: WorkoutDay?
    @State private var showingAddWorkout = false
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(workoutDays) { workoutDay in
                        WorkoutDayCard(
                            workoutDay: workoutDay,
                            lastCompleted: lastCompletedDate(for: workoutDay),
                            isCompletedThisWeek: isCompletedThisWeek(workoutDay)
                        )
                        .onTapGesture {
                            selectedWorkoutDay = workoutDay
                        }
                        .contextMenu {
                            Button {
                                editingWorkoutDay = workoutDay
                            } label: {
                                Label("Edit Workout", systemImage: "pencil")
                            }
                            
                            Button(role: .destructive) {
                                deleteWorkoutDay(workoutDay)
                            } label: {
                                Label("Delete Workout", systemImage: "trash")
                            }
                        }
                    }
                    
                    // Add New Workout Card
                    AddWorkoutCard {
                        showingAddWorkout = true
                    }
                }
                .padding()
            }
            .background(AppTheme.background)
            .navigationTitle("Workouts")
            .fullScreenCover(item: $selectedWorkoutDay) { workoutDay in
                ActiveWorkoutView(workoutDay: workoutDay)
            }
            .sheet(item: $editingWorkoutDay) { workoutDay in
                EditWorkoutDayView(workoutDay: workoutDay)
            }
            .sheet(isPresented: $showingAddWorkout) {
                AddWorkoutDayView()
            }
        }
    }
    
    private func deleteWorkoutDay(_ workoutDay: WorkoutDay) {
        modelContext.delete(workoutDay)
        try? modelContext.save()
    }
    
    private func lastCompletedDate(for workoutDay: WorkoutDay) -> Date? {
        sessions.first { session in
            session.workoutDayId == workoutDay.id && session.isCompleted
        }?.date
    }
    
    private func isCompletedThisWeek(_ workoutDay: WorkoutDay) -> Bool {
        let startOfWeek = Date().startOfWeek
        return sessions.contains { session in
            session.workoutDayId == workoutDay.id &&
            session.isCompleted &&
            session.date >= startOfWeek
        }
    }
}

// MARK: - Workout Day Card
struct WorkoutDayCard: View {
    let workoutDay: WorkoutDay
    let lastCompleted: Date?
    let isCompletedThisWeek: Bool
    
    private var accentColor: Color {
        Color(hex: workoutDay.colorHex)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Day \(workoutDay.dayNumber)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(accentColor.opacity(0.15))
                    .cornerRadius(6)
                
                Spacer()
                
                if isCompletedThisWeek {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            
            // Title
            Text(workoutDay.name)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            // Exercise List Preview
            VStack(alignment: .leading, spacing: 4) {
                ForEach(workoutDay.exercises.prefix(3)) { exercise in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(accentColor)
                            .frame(width: 4, height: 4)
                        Text(exercise.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                if workoutDay.exercises.count > 3 {
                    Text("+ \(workoutDay.exercises.count - 3) more")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Last Completed
            if let date = lastCompleted {
                HStack {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(relativeDate(date))
                        .font(.caption2)
                }
                .foregroundColor(.secondary)
            } else {
                Text("Not completed yet")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .frame(height: 200)
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(accentColor.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: accentColor.opacity(0.1), radius: 8, y: 4)
    }
    
    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Add Workout Card
struct AddWorkoutCard: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(AppTheme.accent)
                
                Text("Add Workout")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Create a new workout day")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .background(AppTheme.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppTheme.accent.opacity(0.3), lineWidth: 2)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Add Workout Day View
struct AddWorkoutDayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \WorkoutDay.dayNumber) private var existingWorkouts: [WorkoutDay]
    
    @State private var name = ""
    @State private var dayNumber = 1
    @State private var selectedColor = Color(hex: "#7CB9A8")
    
    private let presetColors: [Color] = [
        Color(hex: "#7CB9A8"), // Sage green
        Color(hex: "#E57373"), // Red
        Color(hex: "#64B5F6"), // Blue
        Color(hex: "#FFB74D"), // Orange
        Color(hex: "#BA68C8"), // Purple
        Color(hex: "#4DB6AC"), // Teal
        Color(hex: "#F06292"), // Pink
        Color(hex: "#AED581"), // Light green
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Workout Details") {
                    TextField("Workout Name", text: $name)
                        .textInputAutocapitalization(.words)
                    
                    Stepper("Day \(dayNumber)", value: $dayNumber, in: 1...7)
                }
                
                Section("Color") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
                        ForEach(presetColors, id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: selectedColor == color ? 3 : 0)
                                )
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                    .padding(.vertical, 8)
                    
                    ColorPicker("Custom Color", selection: $selectedColor)
                }
                
                Section {
                    // Preview Card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Preview")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("Day \(dayNumber)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(selectedColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(selectedColor.opacity(0.15))
                                .cornerRadius(6)
                            
                            Spacer()
                        }
                        
                        Text(name.isEmpty ? "Workout Name" : name)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(name.isEmpty ? .secondary : .primary)
                    }
                    .padding()
                    .background(AppTheme.cardBackground)
                    .cornerRadius(12)
                }
            }
            .navigationTitle("New Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createWorkout()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                // Suggest next day number
                if let maxDay = existingWorkouts.map({ $0.dayNumber }).max() {
                    dayNumber = maxDay + 1
                }
            }
        }
    }
    
    private func createWorkout() {
        let workout = WorkoutDay(
            name: name,
            dayNumber: dayNumber,
            colorHex: selectedColor.toHex() ?? "#7CB9A8",
            exercises: []
        )
        modelContext.insert(workout)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    WorkoutDaySelectionView()
        .modelContainer(for: [WorkoutDay.self, WorkoutSession.self])
}

