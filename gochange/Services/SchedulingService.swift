import Foundation

/// Service for intelligent workout scheduling
struct SchedulingService {
    /// Suggests the next workout based on:
    /// 1. Which workouts haven't been done in current cycle
    /// 2. Time since last completion of each workout type
    /// 3. Optimal rest periods between similar muscle groups
    static func suggestNextWorkout(sessions: [WorkoutSession], workoutDays: [WorkoutDay]) -> WorkoutDay? {
        guard !workoutDays.isEmpty else { return nil }
        
        // Get sessions from the current week
        let startOfWeek = Date().startOfWeek
        let recentSessions = sessions.filter { session in
            session.isCompleted && session.date >= startOfWeek
        }
        
        // Find which workout types haven't been done this week
        let completedDayIds = Set(recentSessions.map { $0.workoutDayId })
        let incompleteDays = workoutDays.filter { !completedDayIds.contains($0.id) }
        
        // If there are incomplete workouts this week, return the lowest numbered one
        if let nextIncomplete = incompleteDays.sorted(by: { $0.dayNumber < $1.dayNumber }).first {
            return nextIncomplete
        }
        
        // All workouts done this week - suggest based on time since last completion
        return suggestBasedOnRecency(sessions: sessions, workoutDays: workoutDays)
    }
    
    /// Suggests workout based on which one was done longest ago
    private static func suggestBasedOnRecency(sessions: [WorkoutSession], workoutDays: [WorkoutDay]) -> WorkoutDay? {
        var lastCompletedDates: [UUID: Date] = [:]
        
        for session in sessions where session.isCompleted {
            if lastCompletedDates[session.workoutDayId] == nil {
                lastCompletedDates[session.workoutDayId] = session.date
            } else if let existing = lastCompletedDates[session.workoutDayId], session.date > existing {
                lastCompletedDates[session.workoutDayId] = session.date
            }
        }
        
        // Sort workout days by last completed date (oldest first)
        let sortedDays = workoutDays.sorted { day1, day2 in
            let date1 = lastCompletedDates[day1.id] ?? Date.distantPast
            let date2 = lastCompletedDates[day2.id] ?? Date.distantPast
            return date1 < date2
        }
        
        return sortedDays.first
    }
    
    /// Calculates the optimal rest period between workouts
    /// Returns true if enough rest has been taken
    static func hasAdequateRest(lastSession: WorkoutSession?, workoutDay: WorkoutDay) -> Bool {
        guard let lastSession = lastSession else { return true }
        
        let hoursSinceLastWorkout = Date().timeIntervalSince(lastSession.date) / 3600
        
        // Different muscle groups need different rest periods
        // Same muscle group: 48-72 hours recommended
        // Different muscle groups: 24 hours minimum
        
        if lastSession.workoutDayName == workoutDay.name {
            // Same workout type - need at least 48 hours
            return hoursSinceLastWorkout >= 48
        } else {
            // Different workout type - check for muscle group overlap
            // For simplicity, require at least 24 hours between any workouts
            return hoursSinceLastWorkout >= 24
        }
    }
    
    /// Get streak count (consecutive weeks with all 4 workouts)
    static func calculateStreak(sessions: [WorkoutSession]) -> Int {
        var streak = 0
        var weekStart = Date().startOfWeek
        
        // Go back week by week
        for _ in 0..<52 { // Max 1 year
            let weekEnd = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: weekStart)!
            
            let weekSessions = sessions.filter { session in
                session.isCompleted &&
                session.date >= weekStart &&
                session.date < weekEnd
            }
            
            let uniqueWorkoutTypes = Set(weekSessions.map { $0.workoutDayName })
            
            // Check if this is the current week
            let isCurrentWeek = weekStart == Date().startOfWeek
            
            if uniqueWorkoutTypes.count >= 4 {
                streak += 1
            } else if !isCurrentWeek {
                // Past week without 4 workouts breaks the streak
                break
            }
            
            weekStart = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: weekStart)!
        }
        
        return streak
    }
}

