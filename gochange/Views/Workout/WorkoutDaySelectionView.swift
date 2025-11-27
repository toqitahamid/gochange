import SwiftUI
import SwiftData

struct WorkoutDaySelectionView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var workoutManager: WorkoutManager
    @Query(sort: \WorkoutDay.dayNumber) private var workoutDays: [WorkoutDay]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    
    @State private var editingWorkoutDay: WorkoutDay?
    @State private var showingAddWorkout = false
    @State private var selectedWorkout: WorkoutDay?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Weekly Progress Header
                    weeklyProgressHeader
                    
                    // Workout Cards
                    VStack(spacing: 16) {
                        ForEach(workoutDays) { workoutDay in
                            NavigationLink(destination: WorkoutPreviewView(workoutDay: workoutDay)) {
                                WorkoutDayCardContent(
                                    workoutDay: workoutDay,
                                    lastCompleted: lastCompletedDate(for: workoutDay),
                                    isCompletedThisWeek: isCompletedThisWeek(workoutDay)
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())
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
                        
                        // Add New Workout Button
                        AddWorkoutCard {
                            showingAddWorkout = true
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 100)
            }
            .background(Color(hex: "#F5F5F7").ignoresSafeArea())
            .preferredColorScheme(.light)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $editingWorkoutDay) { workoutDay in
                EditWorkoutDayView(workoutDay: workoutDay)
            }
            .sheet(isPresented: $showingAddWorkout) {
                AddWorkoutDayView()
            }
        }
    }
    
    // MARK: - Weekly Progress Header
    private var weeklyProgressHeader: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("This Week")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(completedThisWeekCount)/\(workoutDays.count) Complete")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Circular progress
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.1), lineWidth: 6)
                        .frame(width: 56, height: 56)
                    
                    Circle()
                        .trim(from: 0, to: weeklyProgress)
                        .stroke(
                            LinearGradient(
                                colors: [Color.blue, Color.cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 56, height: 56)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(weeklyProgress * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            }
            
            // Day indicators
            HStack(spacing: 8) {
                ForEach(workoutDays) { day in
                    let completed = isCompletedThisWeek(day)
                    VStack(spacing: 6) {
                        Circle()
                            .fill(completed ? Color(hex: day.colorHex) : Color.gray.opacity(0.1))
                            .frame(width: 12, height: 12)
                            .overlay(
                                completed ?
                                Image(systemName: "checkmark")
                                    .font(.system(size: 6, weight: .bold))
                                    .foregroundColor(.white) : nil
                            )
                        
                        Text("D\(day.dayNumber)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(completed ? Color(hex: day.colorHex) : .secondary)
                    }
                    
                    if day.id != workoutDays.last?.id {
                        Rectangle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 1)
                    }
                }
            }
            .padding(.horizontal, 8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Computed Properties
    private var completedThisWeekCount: Int {
        workoutDays.filter { isCompletedThisWeek($0) }.count
    }
    
    private var weeklyProgress: CGFloat {
        guard !workoutDays.isEmpty else { return 0 }
        return CGFloat(completedThisWeekCount) / CGFloat(workoutDays.count)
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

// MARK: - Workout Day Card Content (for NavigationLink)
struct WorkoutDayCardContent: View {
    let workoutDay: WorkoutDay
    let lastCompleted: Date?
    let isCompletedThisWeek: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Left: Workout Icon
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .frame(width: 60, height: 60)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    )
                
                if isCompletedThisWeek {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color.green)
                } else {
                    Image(systemName: routineIcon)
                        .font(.system(size: 24))
                        .foregroundColor(Color.blue)
                }
            }
            
            // Center: Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("DAY \(workoutDay.dayNumber)")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.2)
                        .foregroundColor(Color.blue)
                    
                    if isCompletedThisWeek {
                        Text("DONE")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(0.5)
                            .foregroundColor(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                
                Text(workoutDay.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                HStack(spacing: 12) {
                    Label("\(workoutDay.exercises.count) Exercises", systemImage: "dumbbell.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Right: Chevron (indicates navigation)
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.gray.opacity(0.4))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private var routineIcon: String {
        let name = workoutDay.name.lowercased()
        if name.contains("push") { return "figure.strengthtraining.traditional" }
        if name.contains("pull") { return "figure.rower" }
        if name.contains("leg") { return "figure.walk" }
        if name.contains("full") { return "figure.cross.training" }
        if name.contains("cardio") || name.contains("run") { return "figure.run" }
        return "dumbbell.fill"
    }
    
    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Add Workout Card
struct AddWorkoutCard: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Plus Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.05))
                        .frame(width: 70, height: 70)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    style: StrokeStyle(lineWidth: 2, dash: [6])
                                )
                                .foregroundColor(Color.gray.opacity(0.3))
                        )
                    
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(Color.blue)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text("Add Workout")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Create a new workout day")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gray.opacity(0.5))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                style: StrokeStyle(lineWidth: 1, dash: [8])
                            )
                            .foregroundColor(Color.gray.opacity(0.2))
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
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

