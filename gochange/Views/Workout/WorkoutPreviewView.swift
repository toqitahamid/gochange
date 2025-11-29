import SwiftUI
import SwiftData

struct WorkoutPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var workoutManager: WorkoutManager

    let workoutDay: WorkoutDay

    @State private var showingEditSheet = false

    // Unified color scheme
    private let primaryAccent = Color(hex: "#6B7280")
    private let secondaryAccent = Color(hex: "#4B5563")

    var body: some View {
        ZStack {
            // Main Content
            ScrollView {
                VStack(spacing: 20) {
                    // Workout Header Card
                    workoutHeaderCard

                    // Exercise List
                    exerciseListSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 120) // Extra padding to account for sticky button
            }
            .background(Color(hex: "#F5F5F7").ignoresSafeArea())

            // Sticky Bottom Button
            VStack {
                Spacer()

                stickyStartButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(hex: "#F5F5F7").opacity(0),
                                Color(hex: "#F5F5F7").opacity(0.95),
                                Color(hex: "#F5F5F7")
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea(edges: .bottom)
                    )
            }
        }
        .navigationTitle(workoutDay.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingEditSheet = true
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(primaryAccent.gradient)
                        .symbolRenderingMode(.hierarchical)
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditWorkoutDayView(workoutDay: workoutDay)
        }
        .toolbar(.visible, for: .tabBar)
    }
    
    // MARK: - Header Card
    private var workoutHeaderCard: some View {
        VStack(spacing: 0) {
            // Compact Top Section with Icon and Title
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

                // Workout Info
                VStack(alignment: .leading, spacing: 4) {
                    Text("DAY \(workoutDay.dayNumber)")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.5)
                        .foregroundStyle(primaryAccent.opacity(0.7))

                    Text(workoutDay.name)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 18)
            .background(
                LinearGradient(
                    colors: [Color.white, Color.white.opacity(0.98)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

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

            // Stats Row
            HStack(spacing: 0) {
                StatBadge(
                    value: "\(workoutDay.exercises.count)",
                    label: "Exercises"
                )

                Rectangle()
                    .fill(Color.gray.opacity(0.12))
                    .frame(width: 1, height: 28)

                StatBadge(
                    value: "\(totalSets)",
                    label: "Sets"
                )

                Rectangle()
                    .fill(Color.gray.opacity(0.12))
                    .frame(width: 1, height: 28)

                StatBadge(
                    value: estimatedDuration,
                    label: "Est. min"
                )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.white.opacity(0.5))
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Exercise List Section
    private var exerciseListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("EXERCISES")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.8)
                    .foregroundStyle(.secondary.opacity(0.8))

                Spacer()

                Text("\(workoutDay.exercises.count)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(primaryAccent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(primaryAccent.opacity(0.12))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(Array(workoutDay.exercises.enumerated()), id: \.element.id) { index, exercise in
                    NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                        ExercisePreviewRow(
                            exercise: exercise,
                            index: index + 1,
                            primaryColor: primaryAccent
                        )
                    }
                    .buttonStyle(.plain)

                    if index < workoutDay.exercises.count - 1 {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.clear, Color.gray.opacity(0.12), Color.clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 1)
                            .padding(.leading, 64)
                    }
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
    }
    
    // MARK: - Sticky Start Button
    private var stickyStartButton: some View {
        Button {
            workoutManager.start(workoutDay: workoutDay)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 22))
                    .symbolRenderingMode(.hierarchical)

                Text("Start Workout")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [primaryAccent, secondaryAccent],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: primaryAccent.opacity(0.35), radius: 20, x: 0, y: 8)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        Color.white.opacity(0.25),
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
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
    
    private var totalSets: Int {
        workoutDay.exercises.reduce(0) { $0 + $1.defaultSets }
    }
    
    private var estimatedDuration: String {
        // Rough estimate: 2 min per set including rest
        let minutes = totalSets * 2
        return "\(minutes)"
    }
}

// MARK: - Exercise Preview Row
struct ExercisePreviewRow: View {
    let exercise: Exercise
    let index: Int
    let primaryColor: Color

    var body: some View {
        HStack(spacing: 16) {
            // Number Badge
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [primaryColor.opacity(0.15), primaryColor.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                Text("\(index)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(primaryColor)
            }

            // Exercise Info
            VStack(alignment: .leading, spacing: 6) {
                Text(exercise.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary.opacity(0.8))

                        Text(exercise.muscleGroup)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }

                    Text("•")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary.opacity(0.5))

                    HStack(spacing: 4) {
                        Image(systemName: "repeat")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(primaryColor.opacity(0.7))

                        Text("\(exercise.defaultSets) × \(exercise.defaultReps)")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(primaryColor)
                    }
                }
            }

            Spacer(minLength: 8)

            // Chevron to indicate tappable
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.quaternary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
    }
}

// MARK: - Stat Badge
struct StatBadge: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary.opacity(0.9))
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    let workoutDay = WorkoutDay(
        name: "Pull",
        dayNumber: 2,
        colorHex: "#7CB9A8",
        exercises: [
            Exercise(name: "Lat Pulldown", defaultSets: 3, defaultReps: "12", muscleGroup: "Back"),
            Exercise(name: "Dumbbell Rows", defaultSets: 3, defaultReps: "12", muscleGroup: "Back"),
            Exercise(name: "Rear Delt Flyes", defaultSets: 3, defaultReps: "15", muscleGroup: "Shoulders"),
            Exercise(name: "Bicep Curls", defaultSets: 3, defaultReps: "15", muscleGroup: "Biceps")
        ]
    )
    
    return WorkoutPreviewView(workoutDay: workoutDay)
        .environmentObject(WorkoutManager())
}

