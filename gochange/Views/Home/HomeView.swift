import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var workoutManager: WorkoutManager
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \WorkoutDay.dayNumber) private var workoutDays: [WorkoutDay]
    
    @State private var suggestedWorkout: WorkoutDay?
    @State private var cachedStreak: Int = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Card
                    headerCard

                    // Suggested Workout Card
                    if let suggested = suggestedWorkout {
                        suggestedWorkoutCard(suggested)
                    }

                    // Weekly Progress
                    weeklyProgressCard

                    // Recent Workouts
                    recentWorkoutsSection
                }
                .padding()
            }
            .background(AppTheme.background)
            .navigationTitle("Workout Tracker")
            .onAppear {
                updateSuggestedWorkout()
                calculateStreak()
            }
            .onChange(of: sessions.count) { _, _ in
                calculateStreak()
                updateSuggestedWorkout()
            }
        }
    }
    
    // MARK: - Header Card
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(greeting)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(Date().formatted(as: "EEEE, MMM d"))
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                // Streak Badge
                streakBadge
            }
        }
        .padding(20)
        .background(AppTheme.primaryGradient)
        .cornerRadius(20)
    }
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default: return "Good Evening"
        }
    }
    
    private var streakBadge: some View {
        VStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .font(.title)
                .foregroundColor(.orange)

            Text("\(cachedStreak)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("week streak")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(12)
        .background(Color.white.opacity(0.2))
        .cornerRadius(12)
    }
    
    // MARK: - Suggested Workout
    private func suggestedWorkoutCard(_ workout: WorkoutDay) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Next Workout")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Image(systemName: "sparkles")
                    .foregroundColor(.yellow)
            }
            
            HStack(spacing: 16) {
                // Workout Icon
                Circle()
                    .fill(Color(hex: workout.colorHex).opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(workout.name.prefix(1))
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: workout.colorHex))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Day \(workout.dayNumber): \(workout.name)")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("\(workout.exercises.count) exercises")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Button {
                workoutManager.start(workoutDay: workout)
            } label: {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Start Workout")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(hex: workout.colorHex))
                .cornerRadius(12)
            }
        }
        .padding(20)
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
    }
    
    // MARK: - Weekly Progress
    private var weeklyProgressCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("This Week")
                .font(.headline)
            
            HStack(spacing: 12) {
                ForEach(workoutDays) { day in
                    let isCompleted = isWorkoutCompletedThisWeek(day)
                    
                    VStack(spacing: 8) {
                        Circle()
                            .fill(isCompleted ? Color(hex: day.colorHex) : Color.gray.opacity(0.2))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: isCompleted ? "checkmark" : "dumbbell.fill")
                                    .foregroundColor(isCompleted ? .white : .gray)
                            )
                        
                        Text(day.name)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(isCompleted ? .primary : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppTheme.accent)
                        .frame(width: geometry.size.width * weeklyProgressPercentage, height: 8)
                }
            }
            .frame(height: 8)
            
            Text("\(workoutsThisWeek)/4 workouts completed")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
    }
    
    // MARK: - Recent Workouts
    private var recentWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Workouts")
                .font(.headline)
            
            if recentSessions.isEmpty {
                emptyStateView
            } else {
                ForEach(recentSessions) { session in
                    RecentSessionRow(session: session)
                }
            }
        }
        .padding(20)
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.run")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("No workouts yet")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Start your first workout to see it here")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }
    
    // MARK: - Computed Properties
    private var recentSessions: [WorkoutSession] {
        Array(sessions.filter { $0.isCompleted }.prefix(5))
    }
    
    private var workoutsThisWeek: Int {
        let startOfWeek = Date().startOfWeek
        return sessions.filter { session in
            session.isCompleted && session.date >= startOfWeek
        }.count
    }
    
    private var weeklyProgressPercentage: CGFloat {
        CGFloat(min(workoutsThisWeek, 4)) / 4.0
    }
    
    private func calculateStreak() {
        // Optimized streak calculation - runs once on appear instead of on every render
        var streak = 0
        var currentWeek = Date().startOfWeek
        let calendar = Calendar.current

        // Group completed sessions by week first (single pass)
        var sessionsByWeek: [Date: Set<String>] = [:]
        for session in sessions where session.isCompleted {
            let weekStart = session.date.startOfWeek
            sessionsByWeek[weekStart, default: []].insert(session.workoutDayName)
        }

        // Check consecutive weeks
        for _ in 0..<52 { // Safety limit
            if let uniqueDays = sessionsByWeek[currentWeek], uniqueDays.count >= 4 {
                streak += 1
                guard let previousWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: currentWeek) else { break }
                currentWeek = previousWeek
            } else if currentWeek < Date().startOfWeek {
                // Past week didn't have 4 workouts, stop counting
                break
            } else {
                // Current week hasn't completed 4 yet, check previous week
                guard let previousWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: currentWeek) else { break }
                currentWeek = previousWeek
            }
        }

        cachedStreak = streak
    }
    
    private func isWorkoutCompletedThisWeek(_ workoutDay: WorkoutDay) -> Bool {
        let startOfWeek = Date().startOfWeek
        return sessions.contains { session in
            session.isCompleted &&
            session.workoutDayId == workoutDay.id &&
            session.date >= startOfWeek
        }
    }
    
    private func updateSuggestedWorkout() {
        suggestedWorkout = SchedulingService.suggestNextWorkout(
            sessions: sessions,
            workoutDays: workoutDays
        )
    }
}

// MARK: - Recent Session Row
struct RecentSessionRow: View {
    let session: WorkoutSession
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(AppConstants.WorkoutColors.color(for: session.workoutDayName).opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(session.workoutDayName.prefix(1))
                        .fontWeight(.semibold)
                        .foregroundColor(AppConstants.WorkoutColors.color(for: session.workoutDayName))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(session.workoutDayName)
                    .fontWeight(.medium)
                
                Text(session.date.formatted(as: "MMM d, yyyy"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let duration = session.duration {
                Text(duration.formattedDuration)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [WorkoutDay.self, WorkoutSession.self])
}

