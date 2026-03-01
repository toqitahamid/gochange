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
    @State private var animateProgress = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerView
                    
                    // Weekly Progress Card
                    WeeklyProgressCard(
                        completedCount: completedThisWeekCount,
                        totalCount: max(workoutDays.count, 1),
                        progress: weeklyProgress,
                        workoutDays: workoutDays,
                        sessions: sessions
                    )
                    
                    // Workout List
                    VStack(spacing: 16) {
                        if workoutDays.isEmpty {
                            ContentUnavailableView(
                                "No Workouts",
                                systemImage: "dumbbell.fill",
                                description: Text("Create your first workout day to get started.")
                            )
                            .padding(.top, 40)
                        } else {
                            ForEach(workoutDays) { workoutDay in
                                NavigationLink(destination: WorkoutPreviewView(workoutDay: workoutDay)) {
                                    WorkoutDayCard(
                                        workoutDay: workoutDay,
                                        isCompleted: isCompletedThisWeek(workoutDay)
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
                        }
                        
                        // Add Workout Card (Liquid Glass)
                        Button {
                            showingAddWorkout = true
                        } label: {
                            AddWorkoutGlassCard()
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        // Exercise Library Link
                        NavigationLink(destination: ExerciseLibraryView()) {
                            ExerciseLibraryRow()
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 100)
            }
            .background(AppColors.background.ignoresSafeArea())
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
    
    // MARK: - Header
    private var headerView: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Workout")
                    .font(.system(size: 34, weight: .bold, design: .default))
                    .foregroundColor(.primary)
                Text("Your Training Plan")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            NavigationLink(destination: WorkoutAnalyticsView()) {
                Image(systemName: "chart.xyaxis.line")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
            }
        }
    }

    // MARK: - Computed Properties
    private var completedThisWeekCount: Int {
        workoutDays.filter { isCompletedThisWeek($0) }.count
    }

    private var weeklyProgress: Double {
        guard !workoutDays.isEmpty else { return 0 }
        return Double(completedThisWeekCount) / Double(workoutDays.count)
    }
    
    private func deleteWorkoutDay(_ workoutDay: WorkoutDay) {
        modelContext.delete(workoutDay)
        try? modelContext.save()
    }
    
    // Check if a workout is completed in the current week (starting Monday)
    private func isCompletedThisWeek(_ workoutDay: WorkoutDay) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        // Find the start of the current week (assuming Monday start)
        guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else { return false }
        
        return sessions.contains { session in
            session.workoutDayId == workoutDay.id &&
            session.isCompleted &&
            session.date >= startOfWeek
        }
    }
}

// MARK: - Weekly Progress Card
struct WeeklyProgressCard: View {
    let completedCount: Int
    let totalCount: Int
    let progress: Double
    let workoutDays: [WorkoutDay]
    let sessions: [WorkoutSession]
    
    var body: some View {
        HStack(spacing: 20) {
            // Left Content
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("WEEKLY GOAL")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                        .tracking(0.5)
                    
                    Text("\(completedCount)/\(totalCount)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(motivationalText)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                // Stepper Lines
                HStack(spacing: 0) {
                    ForEach(0..<min(5, max(totalCount, 1)), id: \.self) { index in
                        HStack(spacing: 0) {
                            // Dot
                            ZStack {
                                if index < completedCount {
                                    Circle()
                                        .fill(Color(hex: "00C896")) // Mint
                                        .frame(width: 20, height: 20)
                                        .overlay(
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.white)
                                        )
                                } else {
                                    Circle()
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                                        .frame(width: 20, height: 20)
                                }
                            }
                            
                            // Line
                            if index < min(5, totalCount) - 1 {
                                Rectangle()
                                    .fill(index < completedCount ? Color(hex: "00C896") : Color.gray.opacity(0.2))
                                    .frame(height: 2)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
            }
            
            Spacer()
            
            // Progress Ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.1), lineWidth: 12)
                    .frame(width: 100, height: 100)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [Color(hex: "00C896"), Color(hex: "2DD4BF")], // Mint to Teal
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: Color(hex: "00C896").opacity(0.3), radius: 8, x: 0, y: 4)
                
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.white)
                .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 5)
        )
    }
    
    private var motivationalText: String {
        if progress >= 1.0 { return "Goal Reached!" }
        if progress >= 0.5 { return "Keep pushing!" }
        return "Let's go!"
    }
}

// MARK: - Workout Day Card
struct WorkoutDayCard: View {
    let workoutDay: WorkoutDay
    let isCompleted: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(iconColor.opacity(0.1)) // Soft background matching icon color
                    .frame(width: 56, height: 56)
                
                Image(systemName: iconName)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            // Text Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(workoutDay.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    if isCompleted {
                        Text("DONE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color(hex: "00C896")))
                    }
                }
                
                HStack(spacing: 6) {
                    Text("DAY \(workoutDay.dayNumber)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary.opacity(0.5))
                        
                    Text("\(workoutDay.exercises.count) Exercises")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        // Badge style for exercise count
                        .background(Capsule().fill(Color.gray.opacity(0.1))) 
                }
            }
            
            Spacer()
            
            // Chevron is implicit interaction hint, keeping clean by removing or making subtle
            // Removed chevron for cleaner look as per design images often having none or very subtle
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
    
    private var iconName: String {
        let name = workoutDay.name.lowercased()
        if name.contains("push") { return "figure.strengthtraining.traditional" }
        if name.contains("pull") { return "figure.rower" }
        if name.contains("leg") { return "figure.walk" }
        return "dumbbell.fill" // Default
    }
    
    private var iconColor: Color {
        let name = workoutDay.name.lowercased()
        if name.contains("push") { return Color.orange }
        if name.contains("pull") { return Color.indigo }
        if name.contains("leg") { return Color(hex: "343A40") } // Dark Asphalt
        return Color.blue
    }
}

// MARK: - Add Workout Glass Card (Liquid Glass)
struct AddWorkoutGlassCard: View {
    var body: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(.white)
                    .shadow(radius: 2) // Subtle shadow for depth
                
                Text("Add Workout")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white)
                    .shadow(radius: 1)
            }
            Spacer()
        }
        .padding(.vertical, 32)
        .background(
            // Frosted Glass Effect
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .opacity(0.9) // Enhance visibility
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        // Add a subtle gradient stroke to enhance the "liquid" edge
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.6), .white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
    }
}

// MARK: - Exercise Library Row (Simple Link)
struct ExerciseLibraryRow: View {
    var body: some View {
        HStack {
            Image(systemName: "books.vertical.fill")
                .foregroundColor(.secondary)
            Text("Exercise Library")
                .font(.system(size: 17))
                .foregroundColor(.primary)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Helper for Buttons
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Add Workout Day View
struct AddWorkoutDayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \WorkoutDay.dayNumber) private var existingWorkouts: [WorkoutDay]
    
    @State private var name = ""
    @State private var dayNumber = 1
    
    // Unified accent color for all workouts
    private let accentColor = Color(hex: "#2D3748")
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Workout Details") {
                    TextField("Workout Name", text: $name)
                        .textInputAutocapitalization(.words)
                    
                    Stepper("Day \(dayNumber)", value: $dayNumber, in: 1...7)
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
                                .foregroundColor(accentColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(accentColor.opacity(0.15))
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
            colorHex: "#2D3748", // Consistent slate accent color
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
