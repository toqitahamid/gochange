import SwiftUI
import SwiftData
import Combine

/// View model for calendar-related operations
@MainActor
class CalendarViewModel: ObservableObject {
    private let modelContext: ModelContext
    
    @Published var sessions: [WorkoutSession] = []
    @Published var selectedDate: Date = Date()
    @Published var displayedMonth: Date = Date()
    
    private let calendar = Calendar.current
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadSessions()
    }
    
    func loadSessions() {
        do {
            let descriptor = FetchDescriptor<WorkoutSession>(
                predicate: #Predicate { $0.isCompleted },
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            sessions = try modelContext.fetch(descriptor)
        } catch {
            print("Error loading sessions: \(error)")
        }
    }
    
    // MARK: - Navigation
    
    func previousMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }
    
    func nextMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }
    
    func goToToday() {
        displayedMonth = Date()
        selectedDate = Date()
    }
    
    // MARK: - Session Queries
    
    func sessions(for date: Date) -> [WorkoutSession] {
        sessions.filter { session in
            calendar.isDate(session.date, inSameDayAs: date)
        }
    }
    
    var sessionsForSelectedDate: [WorkoutSession] {
        sessions(for: selectedDate)
    }
    
    func hasWorkout(on date: Date) -> Bool {
        sessions.contains { session in
            calendar.isDate(session.date, inSameDayAs: date)
        }
    }
    
    func workoutTypes(on date: Date) -> [String] {
        sessions(for: date).map { $0.workoutDayName }
    }
    
    // MARK: - Calendar Generation
    
    var daysInMonth: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
              let firstWeekday = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }
        
        var days: [Date?] = []
        var currentDate = firstWeekday.start
        
        // Leading empty days
        while currentDate < monthInterval.start {
            days.append(nil)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        // Days of the month
        while currentDate < monthInterval.end {
            days.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        // Trailing empty days
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
    
    // MARK: - Statistics
    
    var sessionsThisMonth: Int {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth) else {
            return 0
        }
        
        return sessions.filter { session in
            session.date >= monthInterval.start && session.date < monthInterval.end
        }.count
    }
    
    var workoutDaysThisMonth: Int {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth) else {
            return 0
        }
        
        let sessionsInMonth = sessions.filter { session in
            session.date >= monthInterval.start && session.date < monthInterval.end
        }
        
        let uniqueDays = Set(sessionsInMonth.map { calendar.startOfDay(for: $0.date) })
        return uniqueDays.count
    }
    
    var monthTitle: String {
        displayedMonth.formatted(as: "MMMM yyyy")
    }
    
    func isSelected(_ date: Date) -> Bool {
        calendar.isDate(date, inSameDayAs: selectedDate)
    }
    
    func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }
}

