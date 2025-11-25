import SwiftUI
import SwiftData

struct CalendarView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    
    @State private var selectedDate: Date = Date()
    @State private var displayedMonth: Date = Date()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Calendar
                CalendarGrid(
                    displayedMonth: $displayedMonth,
                    selectedDate: $selectedDate,
                    sessions: sessions
                )
                
                Divider()
                
                // Sessions for selected date
                VStack(alignment: .leading, spacing: 12) {
                    Text(selectedDate.formatted(as: "EEEE, MMMM d"))
                        .font(.headline)
                        .padding(.horizontal)
                        .padding(.top, 16)
                    
                    if sessionsOnDate.isEmpty {
                        emptyStateView
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(sessionsOnDate) { session in
                                    NavigationLink(destination: SessionDetailView(session: session)) {
                                        SessionRowView(session: session)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .frame(maxHeight: .infinity)
            }
            .background(AppTheme.background)
            .navigationTitle("Calendar")
        }
    }
    
    private var sessionsOnDate: [WorkoutSession] {
        sessions.filter { session in
            Calendar.current.isDate(session.date, inSameDayAs: selectedDate) && session.isCompleted
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("No Workouts")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("No workouts logged on this date")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Calendar Grid
struct CalendarGrid: View {
    @Binding var displayedMonth: Date
    @Binding var selectedDate: Date
    let sessions: [WorkoutSession]
    
    private let calendar = Calendar.current
    private let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    var body: some View {
        VStack(spacing: 16) {
            // Month Navigation
            HStack {
                Button {
                    withAnimation {
                        displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                }
                
                Spacer()
                
                Text(displayedMonth.formatted(as: "MMMM yyyy"))
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button {
                    withAnimation {
                        displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                }
            }
            .padding(.horizontal)
            
            // Days of Week Header
            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar Days
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(Array(daysInMonth.enumerated()), id: \.offset) { index, date in
                    if let date = date {
                        CalendarDayView(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            sessions: sessionsForDate(date)
                        )
                        .onTapGesture {
                            withAnimation {
                                selectedDate = date
                            }
                        }
                    } else {
                        Color.clear
                            .frame(height: 50)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(AppTheme.cardBackground)
    }
    
    private var daysInMonth: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
              let firstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }
        
        var days: [Date?] = []
        var currentDate = firstWeek.start
        
        // Fill in leading empty days
        while currentDate < monthInterval.start {
            days.append(nil)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        // Fill in days of the month
        while currentDate < monthInterval.end {
            days.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        // Fill in trailing empty days to complete the grid
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
    
    private func sessionsForDate(_ date: Date) -> [WorkoutSession] {
        sessions.filter { session in
            calendar.isDate(session.date, inSameDayAs: date) && session.isCompleted
        }
    }
}

// MARK: - Calendar Day View
struct CalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let sessions: [WorkoutSession]
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 16, weight: isSelected ? .bold : .regular))
                .foregroundColor(textColor)
            
            // Workout dots
            HStack(spacing: 2) {
                ForEach(sessions.prefix(3)) { session in
                    Circle()
                        .fill(AppConstants.WorkoutColors.color(for: session.workoutDayName))
                        .frame(width: 6, height: 6)
                }
            }
        }
        .frame(height: 50)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isToday ? AppTheme.accent : Color.clear, lineWidth: 2)
        )
    }
    
    private var textColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return AppTheme.accent
        } else {
            return .primary
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return AppTheme.accent
        } else if !sessions.isEmpty {
            return Color.gray.opacity(0.1)
        } else {
            return Color.clear
        }
    }
}

// MARK: - Session Row View
struct SessionRowView: View {
    let session: WorkoutSession
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(AppConstants.WorkoutColors.color(for: session.workoutDayName).opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(session.workoutDayName.prefix(1))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(AppConstants.WorkoutColors.color(for: session.workoutDayName))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(session.workoutDayName)
                    .font(.headline)
                
                HStack(spacing: 8) {
                    Label(session.startTime.formatted(as: "h:mm a"), systemImage: "clock")
                    
                    if let duration = session.duration {
                        Label(duration.formattedDuration, systemImage: "timer")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

#Preview {
    CalendarView()
        .modelContainer(for: WorkoutSession.self)
}

