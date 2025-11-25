import SwiftUI
import SwiftData

struct SessionDetailView: View {
    let session: WorkoutSession
    
    @Environment(\.dismiss) private var dismiss
    
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
            .padding()
        }
        .background(AppTheme.background)
        .navigationTitle(session.workoutDayName)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Header Card
    private var headerCard: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(AppConstants.WorkoutColors.color(for: session.workoutDayName).opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay(
                    Text(session.workoutDayName.prefix(1))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(AppConstants.WorkoutColors.color(for: session.workoutDayName))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(session.workoutDayName)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(session.date.formatted(as: "EEEE, MMMM d, yyyy"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(session.startTime.formatted(as: "h:mm a"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(20)
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
    
    // MARK: - Stats Row
    private var statsRow: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Duration",
                value: session.duration?.formattedDuration ?? "--",
                icon: "timer",
                color: .blue
            )
            
            StatCard(
                title: "Exercises",
                value: "\(session.exerciseLogs.count)",
                icon: "dumbbell.fill",
                color: .purple
            )
            
            StatCard(
                title: "Total Sets",
                value: "\(totalSets)",
                icon: "checkmark.circle.fill",
                color: .green
            )
            
            StatCard(
                title: "Volume",
                value: formatVolume(totalVolume),
                icon: "scalemass.fill",
                color: .orange
            )
        }
    }
    
    // MARK: - Exercise Section
    private var exerciseSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Exercises")
                .font(.headline)
            
            ForEach(session.exerciseLogs.sorted { $0.order < $1.order }) { exerciseLog in
                ExerciseDetailCard(exerciseLog: exerciseLog)
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

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(AppTheme.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

// MARK: - Exercise Detail Card
struct ExerciseDetailCard: View {
    let exerciseLog: ExerciseLog
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Exercise Name
            Text(exerciseLog.exerciseName)
                .font(.headline)
            
            // Sets Table
            VStack(spacing: 4) {
                // Header
                HStack {
                    Text("SET")
                        .frame(width: 40, alignment: .leading)
                    Text("WEIGHT")
                        .frame(width: 70, alignment: .center)
                    Text("REPS")
                        .frame(width: 50, alignment: .center)
                    Text("RIR")
                        .frame(width: 40, alignment: .center)
                    Spacer()
                }
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                
                Divider()
                
                // Rows
                ForEach(exerciseLog.sets.sorted { $0.setNumber < $1.setNumber }) { setLog in
                    if setLog.isCompleted {
                        HStack {
                            Text("\(setLog.setNumber)")
                                .fontWeight(.medium)
                                .frame(width: 40, alignment: .leading)
                            
                            Text(setLog.weight != nil ? "\(String(format: "%.1f", setLog.weight!)) \(setLog.weightUnit.rawValue)" : "-")
                                .frame(width: 70, alignment: .center)
                            
                            Text(setLog.actualReps != nil ? "\(setLog.actualReps!)" : "-")
                                .frame(width: 50, alignment: .center)
                            
                            Text(setLog.rir != nil ? "\(setLog.rir!)" : "-")
                                .frame(width: 40, alignment: .center)
                                .foregroundColor(setLog.rir != nil ? AppConstants.RIR.color(for: setLog.rir!) : .secondary)
                            
                            Spacer()
                        }
                        .font(.subheadline)
                        .padding(.vertical, 4)
                    }
                }
            }
            
            // Notes
            if let notes = exerciseLog.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

#Preview {
    let session = WorkoutSession(date: Date(), workoutDayId: UUID(), workoutDayName: "Push")
    
    return NavigationStack {
        SessionDetailView(session: session)
    }
}

