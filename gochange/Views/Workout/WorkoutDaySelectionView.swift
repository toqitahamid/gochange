import SwiftUI
import SwiftData

struct WorkoutDaySelectionView: View {
    @Query(sort: \WorkoutDay.dayNumber) private var workoutDays: [WorkoutDay]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    
    @State private var selectedWorkoutDay: WorkoutDay?
    @State private var showingActiveWorkout = false
    
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
                            showingActiveWorkout = true
                        }
                    }
                }
                .padding()
            }
            .background(AppTheme.background)
            .navigationTitle("Workouts")
            .fullScreenCover(isPresented: $showingActiveWorkout) {
                if let workoutDay = selectedWorkoutDay {
                    ActiveWorkoutView(workoutDay: workoutDay)
                }
            }
        }
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

#Preview {
    WorkoutDaySelectionView()
        .modelContainer(for: [WorkoutDay.self, WorkoutSession.self])
}

