import SwiftUI
import SwiftData

struct CalendarView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \RestDay.date, order: .reverse) private var restDays: [RestDay]

    @State private var selectedDate: Date = Date()
    @State private var displayedMonth: Date = Date()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Calendar
                    CalendarGrid(
                        displayedMonth: $displayedMonth,
                        selectedDate: $selectedDate,
                        sessions: sessions,
                        restDays: restDays
                    )

                    // Sessions and Rest Days for selected date
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text(selectedDate.formatted(as: "EEEE, MMMM d"))
                                .font(.headline)
                                .foregroundColor(.white)

                            Spacer()

                            if !sessionsOnDate.isEmpty {
                                Text("\(sessionsOnDate.count) workout\(sessionsOnDate.count > 1 ? "s" : "")")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            } else if restDayOnDate != nil {
                                Text("Rest Day")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }

                        // Show rest day if exists
                        if let restDay = restDayOnDate {
                            RestDayRowView(restDay: restDay)
                        }

                        // Show workouts if they exist
                        if sessionsOnDate.isEmpty && restDayOnDate == nil {
                            emptyStateView
                        } else if !sessionsOnDate.isEmpty {
                            VStack(spacing: 12) {
                                ForEach(sessionsOnDate) { session in
                                    NavigationLink(destination: SessionDetailView(session: session)) {
                                        SessionRowView(session: session)
                                    }
                                    .buttonStyle(ScaleButtonStyle())
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
                .padding(.horizontal, 20)
                .padding(.top, 20)
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
            .toolbar(.hidden, for: .navigationBar)
        }
    }
    
    private var sessionsOnDate: [WorkoutSession] {
        sessions.filter { session in
            Calendar.current.isDate(session.date, inSameDayAs: selectedDate) && session.isCompleted
        }
    }

    private var restDayOnDate: RestDay? {
        restDays.first { restDay in
            Calendar.current.isDate(restDay.date, inSameDayAs: selectedDate)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.system(size: 32))
                    .foregroundColor(.gray)
            }
            
            VStack(spacing: 4) {
                Text("No Workouts")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("No workouts logged on this date")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

// MARK: - Calendar Grid
struct CalendarGrid: View {
    @Binding var displayedMonth: Date
    @Binding var selectedDate: Date
    let sessions: [WorkoutSession]
    let restDays: [RestDay]

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
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                Text(displayedMonth.formatted(as: "MMMM yyyy"))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button {
                    withAnimation {
                        displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            
            // Days of Week Header
            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 11, weight: .bold))
                        .tracking(0.5)
                        .foregroundColor(.gray)
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
                            sessions: sessionsForDate(date),
                            restDay: restDayForDate(date)
                        )
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedDate = date
                            }
                        }
                    } else {
                        Color.clear
                            .frame(height: 50)
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

    private func restDayForDate(_ date: Date) -> RestDay? {
        restDays.first { restDay in
            calendar.isDate(restDay.date, inSameDayAs: date)
        }
    }
}

// MARK: - Calendar Day View
struct CalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let sessions: [WorkoutSession]
    let restDay: RestDay?

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 4) {
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 16, weight: isSelected ? .bold : .regular))
                .foregroundColor(textColor)

            // Rest day indicator or workout dots
            if restDay != nil, sessions.isEmpty {
                Image(systemName: "figure.mind.and.body")
                    .font(.system(size: 10))
                    .foregroundColor(.green)
            } else {
                // Workout dots
                HStack(spacing: 2) {
                    ForEach(sessions.prefix(3)) { session in
                        Circle()
                            .fill(AppConstants.WorkoutColors.color(for: session.workoutDayName))
                            .frame(width: 6, height: 6)
                    }
                }
            }
        }
        .frame(height: 50)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isToday ? Color(hex: "#00D4AA") : Color.clear, lineWidth: 2)
        )
    }
    
    private var textColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return Color(hex: "#00D4AA")
        } else {
            return .white
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return Color(hex: "#00D4AA")
        } else if !sessions.isEmpty {
            return Color.white.opacity(0.08)
        } else {
            return Color.clear
        }
    }
}

// MARK: - Session Row View
struct SessionRowView: View {
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
                    .frame(width: 50, height: 50)
                
                Text(session.workoutDayName.prefix(1).uppercased())
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(accentColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(session.workoutDayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    Label(session.startTime.formatted(as: "h:mm a"), systemImage: "clock")
                    
                    if let duration = session.duration {
                        Label(duration.formattedDuration, systemImage: "timer")
                    }
                }
                .font(.caption)
                .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.gray)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.03))
        )
    }
}

// MARK: - Rest Day Row View
struct RestDayRowView: View {
    let restDay: RestDay

    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: "figure.mind.and.body")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.green)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Rest Day - \(restDay.type.rawValue.capitalized)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                HStack(spacing: 8) {
                    if restDay.sleepDuration != nil {
                        Label(restDay.formattedSleepDuration, systemImage: "bed.double.fill")
                    }

                    Label("Recovery: \(Int(restDay.recoveryScore * 100))%", systemImage: "heart.fill")
                }
                .font(.caption)
                .foregroundColor(.gray)
            }

            Spacer()

            Text(restDay.recoveryStatus.emoji)
                .font(.title2)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.03))
        )
    }
}

#Preview {
    CalendarView()
        .modelContainer(for: WorkoutSession.self)
}
