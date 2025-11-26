import SwiftUI
import SwiftData

struct SessionDetailView: View {
    let session: WorkoutSession
    
    @Environment(\.dismiss) private var dismiss
    
    private var accentColor: Color {
        AppConstants.WorkoutColors.color(for: session.workoutDayName)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Card
                headerCard
                
                // Stats Cards
                statsRow
                
                // Exercise Logs
                exerciseSection
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
        .background(
            LinearGradient(
                colors: [Color.black, Color(hex: "#0A1628")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationTitle(session.workoutDayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
    }
    
    // MARK: - Header Card
    private var headerCard: some View {
        VStack(spacing: 20) {
            // Workout Icon
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [accentColor, accentColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Text(session.workoutDayName.prefix(1).uppercased())
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .shadow(color: accentColor.opacity(0.4), radius: 16, y: 8)
            
            VStack(spacing: 6) {
                Text(session.workoutDayName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(session.date.formatted(as: "EEEE, MMMM d, yyyy"))
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text(session.startTime.formatted(as: "h:mm a"))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [accentColor.opacity(0.3), accentColor.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
    
    // MARK: - Stats Row
    private var statsRow: some View {
        HStack(spacing: 10) {
            SessionStatCard(
                title: "Duration",
                value: session.duration?.formattedDuration ?? "--",
                icon: "timer",
                color: Color(hex: "#64B5F6")
            )
            
            SessionStatCard(
                title: "Exercises",
                value: "\(session.exerciseLogs.count)",
                icon: "dumbbell.fill",
                color: Color(hex: "#BA68C8")
            )
            
            SessionStatCard(
                title: "Sets",
                value: "\(totalSets)",
                icon: "checkmark.circle.fill",
                color: Color(hex: "#00D4AA")
            )
            
            SessionStatCard(
                title: "Volume",
                value: formatVolume(totalVolume),
                icon: "scalemass.fill",
                color: Color(hex: "#FF6B35")
            )
        }
    }
    
    // MARK: - Exercise Section
    private var exerciseSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("EXERCISES")
                .font(.system(size: 12, weight: .bold))
                .tracking(1.5)
                .foregroundColor(.gray)
                .padding(.horizontal, 4)
            
            VStack(spacing: 12) {
                ForEach(session.exerciseLogs.sorted { $0.order < $1.order }) { exerciseLog in
                    SessionExerciseDetailCard(exerciseLog: exerciseLog)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var totalSets: Int {
        session.exerciseLogs.reduce(0) { $0 + $1.sets.filter { $0.isCompleted }.count }
    }
    
    private var totalVolume: Double {
        session.exerciseLogs.reduce(0) { total, log in
            total + log.sets.reduce(0) { setTotal, set in
                if set.isCompleted, let weight = set.weight, let reps = set.actualReps {
                    return setTotal + (weight * Double(reps))
                }
                return setTotal
            }
        }
    }
    
    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fk", volume / 1000)
        }
        return String(format: "%.0f", volume)
    }
}

// MARK: - Session Stat Card
struct SessionStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Session Exercise Detail Card
struct SessionExerciseDetailCard: View {
    let exerciseLog: ExerciseLog
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Exercise Name
            Text(exerciseLog.exerciseName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
            
            // Sets Table
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("SET")
                        .frame(width: 40, alignment: .leading)
                    Text("WEIGHT")
                        .frame(width: 80, alignment: .center)
                    Text("REPS")
                        .frame(width: 50, alignment: .center)
                    Text("RIR")
                        .frame(width: 40, alignment: .center)
                    Spacer()
                }
                .font(.system(size: 10, weight: .bold))
                .tracking(0.5)
                .foregroundColor(.gray.opacity(0.6))
                .padding(.bottom, 10)
                
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 1)
                
                // Rows
                ForEach(exerciseLog.sets.sorted { $0.setNumber < $1.setNumber }) { setLog in
                    if setLog.isCompleted {
                        HStack {
                            Text("\(setLog.setNumber)")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(width: 40, alignment: .leading)
                            
                            Text(setLog.weight != nil ? "\(String(format: "%.1f", setLog.weight!)) \(setLog.weightUnit.rawValue)" : "-")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .frame(width: 80, alignment: .center)
                            
                            Text(setLog.actualReps != nil ? "\(setLog.actualReps!)" : "-")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .frame(width: 50, alignment: .center)
                            
                            Text(setLog.rir != nil ? "\(setLog.rir!)" : "-")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(setLog.rir != nil ? AppConstants.RIR.color(for: setLog.rir!) : .gray)
                                .frame(width: 40, alignment: .center)
                            
                            Spacer()
                        }
                        .padding(.vertical, 10)
                    }
                }
            }
            
            // Notes
            if let notes = exerciseLog.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top, 4)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

#Preview {
    let session = WorkoutSession(date: Date(), workoutDayId: UUID(), workoutDayName: "Push")
    
    return NavigationStack {
        SessionDetailView(session: session)
    }
}
