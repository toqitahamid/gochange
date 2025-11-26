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
                    // Hero Header
                    heroHeader

                    // Suggested Workout Card
                    if let suggested = suggestedWorkout {
                        suggestedWorkoutCard(suggested)
                    }

                    // Stats Row
                    statsRow

                    // Weekly Progress
                    weeklyProgressCard

                    // Recent Workouts
                    recentWorkoutsSection
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
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
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
    
    // MARK: - Hero Header
    private var heroHeader: some View {
        VStack(spacing: 20) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(greeting)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(Date().formatted(as: "EEEE, MMM d"))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Streak Badge
                streakBadge
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#1a1a2e"), Color(hex: "#16213e")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
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
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#FF6B35"), Color(hex: "#F7931E")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: Color(hex: "#FF6B35").opacity(0.4), radius: 12, y: 4)
                
                Image(systemName: "flame.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
            
            Text("\(cachedStreak)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("WEEKS")
                .font(.system(size: 9, weight: .bold))
                .tracking(1.5)
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Stats Row
    private var statsRow: some View {
        HStack(spacing: 12) {
            HomeStatCard(
                icon: "flame.fill",
                value: "\(totalWorkouts)",
                label: "Total",
                color: Color(hex: "#FF6B35")
            )
            
            HomeStatCard(
                icon: "calendar",
                value: "\(workoutsThisWeek)",
                label: "This Week",
                color: Color(hex: "#00D4AA")
            )
            
            HomeStatCard(
                icon: "trophy.fill",
                value: "\(cachedStreak)",
                label: "Streak",
                color: Color(hex: "#FFD700")
            )
        }
    }
    
    // MARK: - Suggested Workout
    private func suggestedWorkoutCard(_ workout: WorkoutDay) -> some View {
        let accentColor = Color(hex: workout.colorHex)
        let totalSets = workout.exercises.reduce(0) { $0 + $1.defaultSets }
        let estimatedMins = totalSets * 2
        
        return NavigationLink(destination: WorkoutPreviewView(workoutDay: workout)) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#FFD700"))
                        
                        Text("UP NEXT")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1.5)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Text("Day \(workout.dayNumber)")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1)
                        .foregroundColor(accentColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(accentColor.opacity(0.15))
                        .cornerRadius(6)
                }
                
                HStack(spacing: 16) {
                    // Workout Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [accentColor, accentColor.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 64, height: 64)
                        
                        Text(workout.name.prefix(1).uppercased())
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .shadow(color: accentColor.opacity(0.4), radius: 8, y: 4)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(workout.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        HStack(spacing: 12) {
                            Label("\(workout.exercises.count) exercises", systemImage: "dumbbell.fill")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Label("~\(estimatedMins) min", systemImage: "clock")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gray)
                }
            }
            .padding(20)
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
        .buttonStyle(ScaleButtonStyle())
    }
    
    // MARK: - Weekly Progress
    private var weeklyProgressCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Weekly Progress")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(workoutsThisWeek)/\(workoutDays.count)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#00D4AA"))
            }
            
            // Day circles
            HStack(spacing: 0) {
                ForEach(workoutDays) { day in
                    let isCompleted = isWorkoutCompletedThisWeek(day)
                    let accentColor = Color(hex: day.colorHex)
                    
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(isCompleted ? accentColor : Color.white.opacity(0.1))
                                .frame(width: 48, height: 48)
                            
                            if isCompleted {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                            } else {
                                Text(day.name.prefix(1).uppercased())
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.gray)
                            }
                        }
                        .shadow(color: isCompleted ? accentColor.opacity(0.4) : .clear, radius: 8, y: 4)
                        
                        Text(day.name)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(isCompleted ? .white : .gray)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#00D4AA"), Color(hex: "#00B894")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * weeklyProgressPercentage, height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Recent Workouts
    private var recentWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                if !recentSessions.isEmpty {
                    Text("\(recentSessions.count) workouts")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            if recentSessions.isEmpty {
                emptyStateView
            } else {
                VStack(spacing: 12) {
                    ForEach(recentSessions) { session in
                        RecentSessionRow(session: session)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "figure.run")
                    .font(.system(size: 32))
                    .foregroundColor(.gray)
            }
            
            VStack(spacing: 4) {
                Text("No workouts yet")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Complete your first workout to see it here")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
    
    // MARK: - Computed Properties
    private var recentSessions: [WorkoutSession] {
        Array(sessions.filter { $0.isCompleted }.prefix(5))
    }
    
    private var totalWorkouts: Int {
        sessions.filter { $0.isCompleted }.count
    }
    
    private var workoutsThisWeek: Int {
        let startOfWeek = Date().startOfWeek
        return sessions.filter { session in
            session.isCompleted && session.date >= startOfWeek
        }.count
    }
    
    private var weeklyProgressPercentage: CGFloat {
        guard !workoutDays.isEmpty else { return 0 }
        return CGFloat(min(workoutsThisWeek, workoutDays.count)) / CGFloat(workoutDays.count)
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

// MARK: - Home Stat Card
struct HomeStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 11, weight: .medium))
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

// MARK: - Recent Session Row
struct RecentSessionRow: View {
    let session: WorkoutSession
    
    private var accentColor: Color {
        AppConstants.WorkoutColors.color(for: session.workoutDayName)
    }
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 46, height: 46)
                
                Text(session.workoutDayName.prefix(1).uppercased())
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(accentColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(session.workoutDayName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(session.date.formatted(as: "MMM d, yyyy"))
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            if let duration = session.duration {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 11))
                    Text(duration.formattedDuration)
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.gray)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.05))
                .cornerRadius(8)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.03))
        )
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [WorkoutDay.self, WorkoutSession.self])
}

