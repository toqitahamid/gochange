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
                    // Premium Header
                    premiumHeader
                    
                    // Weekly Progress Header
                    weeklyProgressHeader
                    
                    // Workout Cards
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
                                    WorkoutDayCardContent(
                                        workoutDay: workoutDay,
                                        lastCompleted: lastCompletedDate(for: workoutDay),
                                        isCompletedThisWeek: isCompletedThisWeek(workoutDay)
                                    )
                                }
                                .buttonStyle(PremiumCardButtonStyle())
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
                        
                        // Add New Workout Button - Floating Glass Style
                        AddWorkoutCard {
                            showingAddWorkout = true
                        }
                        
                        // Exercise Library Card
                        NavigationLink(destination: ExerciseLibraryView()) {
                            ExerciseLibraryCard()
                        }
                        .buttonStyle(PremiumCardButtonStyle())
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
            .onAppear {
                withAnimation(.bouncy(duration: 0.6).delay(0.2)) {
                    animateProgress = true
                }
            }
        }
    }
    
    // MARK: - Premium Header
    private var premiumHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Workout")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text("Your Training Plan")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
            Spacer()

            NavigationLink(destination: FitnessAnalyticsView()) {
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white.opacity(0.5), lineWidth: 0.5)
                    )
            }
        }
    }
    
    // MARK: - Weekly Progress Header
    private var weeklyProgressHeader: some View {
        VStack(spacing: 24) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("WEEKLY GOAL")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.5)
                        .foregroundColor(.secondary.opacity(0.8))

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(completedThisWeekCount)")
                            .font(.system(size: 48, weight: .black, design: .rounded))
                            .foregroundColor(.primary)
                            .contentTransition(.numericText())

                        Text("/ \(workoutDays.count)")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary.opacity(0.5))
                    }

                    HStack(spacing: 6) {
                        Text(progressMessage)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(progressColor)

                        if weeklyProgress >= 1.0 {
                            Image(systemName: "sparkles")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(progressColor)
                                .symbolEffect(.bounce, value: animateProgress)
                        }
                    }
                }

                Spacer()

                // Enhanced Circular progress
                ZStack {
                    // Background ring
                    Circle()
                        .stroke(Color.gray.opacity(0.1), lineWidth: 12)
                        .frame(width: 88, height: 88)

                    // Animated progress ring with gradient
                    Circle()
                        .trim(from: 0, to: animateProgress ? weeklyProgress : 0)
                        .stroke(
                            AngularGradient(
                                colors: [progressColor.opacity(0.6), progressColor, progressColor.opacity(0.8)],
                                center: .center,
                                startAngle: .degrees(-90),
                                endAngle: .degrees(270)
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 88, height: 88)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: progressColor.opacity(0.4), radius: 8, x: 0, y: 4)

                    VStack(spacing: 0) {
                        Text("\(Int(weeklyProgress * 100))")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundColor(.primary)
                            .contentTransition(.numericText())
                        Text("%")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                }
            }
            
            // Premium Day indicators
            HStack(spacing: 0) {
                ForEach(Array(workoutDays.enumerated()), id: \.element.id) { index, day in
                    let completed = isCompletedThisWeek(day)

                    VStack(spacing: 8) {
                        ZStack {
                            if completed {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [progressColor, progressColor.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 32, height: 32)
                                    .shadow(color: progressColor.opacity(0.4), radius: 6, x: 0, y: 3)

                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .heavy))
                                    .foregroundColor(.white)
                            } else {
                                Circle()
                                    .fill(Color.gray.opacity(0.08))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 2)
                                    )
                            }
                        }
                        .scaleEffect(animateProgress && completed ? 1.0 : (completed ? 0.8 : 1.0))
                        .animation(.bouncy(duration: 0.5).delay(Double(index) * 0.1), value: animateProgress)

                        Text("D\(day.dayNumber)")
                            .font(.system(size: 12, weight: completed ? .bold : .medium))
                            .foregroundColor(completed ? progressColor : .secondary.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)

                    if index < workoutDays.count - 1 {
                        Rectangle()
                            .fill(
                                completed && isCompletedThisWeek(workoutDays[index + 1]) ?
                                LinearGradient(
                                    colors: [progressColor.opacity(0.5), progressColor.opacity(0.3)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ) :
                                LinearGradient(
                                    colors: [Color.gray.opacity(0.15), Color.gray.opacity(0.15)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 3)
                            .cornerRadius(1.5)
                            .padding(.top, -24)
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.gray.opacity(0.08), lineWidth: 1)
                )
        )
    }
    
    private var progressMessage: String {
        if weeklyProgress >= 1.0 { return "Goal Complete!" }
        if weeklyProgress >= 0.7 { return "Almost there!" }
        if weeklyProgress >= 0.4 { return "Keep pushing!" }
        return "Let's get started!"
    }

    private var progressColor: Color {
        if weeklyProgress >= 1.0 { return Color(hex: "#00D4AA") }
        if weeklyProgress >= 0.7 { return Color(hex: "#007AFF") }
        if weeklyProgress >= 0.4 { return Color(hex: "#FF9500") }
        return Color(hex: "#8E8E93")
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

// MARK: - Premium Card Button Style
struct PremiumCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.bouncy(duration: 0.3), value: configuration.isPressed)
    }
}

// MARK: - Workout Day Card Content
struct WorkoutDayCardContent: View {
    let workoutDay: WorkoutDay
    let lastCompleted: Date?
    let isCompletedThisWeek: Bool

    var body: some View {
        HStack(spacing: 16) {
            // Left: Workout Icon with enhanced styling
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        isCompletedThisWeek ?
                        LinearGradient(
                            colors: [Color.green.opacity(0.15), Color.green.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [Color(hex: "#2D3748").opacity(0.12), Color(hex: "#2D3748").opacity(0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)

                if isCompletedThisWeek {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 26, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.green, Color.green.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                } else {
                    Image(systemName: routineIcon)
                        .font(.system(size: 26, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "#2D3748"), Color(hex: "#2D3748").opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }

            // Center: Info with refined typography
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text("DAY \(workoutDay.dayNumber)")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.0)
                        .foregroundColor(Color(hex: "#2D3748"))

                    if isCompletedThisWeek {
                        Text("DONE")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(0.5)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.green, Color.green.opacity(0.85)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                    }
                }

                Text(workoutDay.name)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)

                Label("\(workoutDay.exercises.count) Exercises", systemImage: "dumbbell.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Right: Chevron with subtle styling
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.gray.opacity(0.35))
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.gray.opacity(0.08), lineWidth: 1)
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

// MARK: - Scale Button Style (kept for compatibility)
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Exercise Library Card
struct ExerciseLibraryCard: View {
    var body: some View {
        HStack(spacing: 16) {
            // Icon with gradient
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#2D3748").opacity(0.12), Color(hex: "#2D3748").opacity(0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)

                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "#2D3748"), Color(hex: "#2D3748").opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text("Exercise Library")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)

                Text("Browse and manage exercises")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.gray.opacity(0.35))
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.gray.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

// MARK: - Add Workout Card (Floating Glass Style)
struct AddWorkoutCard: View {
    let onTap: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            onTap()
        }) {
            HStack(spacing: 16) {
                // Plus Icon with glass background
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 64, height: 64)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.6), Color.white.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: Color(hex: "#2D3748").opacity(0.15), radius: 8, x: 0, y: 4)

                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "#2D3748"), Color(hex: "#2D3748").opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text("Add Workout")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)

                    Text("Create a new workout day")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.gray.opacity(0.35))
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.5), Color.gray.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
            )
        }
        .buttonStyle(PremiumCardButtonStyle())
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
