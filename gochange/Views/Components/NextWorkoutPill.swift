import SwiftUI
import SwiftData

struct NextWorkoutPill: View {
    @Query(sort: \WorkoutDay.dayNumber) private var workouts: [WorkoutDay]
    
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(AppColors.success) // Mint success color
                    .frame(width: 32, height: 32)
                
                Image(systemName: "figure.run")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 0) {
                Text("Next Workout")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(nextWorkoutText)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            Image(systemName: "chevron.down")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding(.leading, 6)
        .padding(.trailing, 16)
        .padding(.vertical, 6)
        .background(Color.white)
        .cornerRadius(22)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var nextWorkoutText: String {
        guard !workouts.isEmpty else { return "No Workouts" }
        
        // Find next workout based on current day
        // Assuming dayNumber 1 = Monday, 7 = Sunday to match typical schedule
        // Calendar.current.component(.weekday) returns 1 = Sunday, 2 = Monday
        let calendar = Calendar.current
        let todayWeekday = calendar.component(.weekday, from: Date())
        
        // Convert Sunday=1...Saturday=7 to Monday=1...Sunday=7
        let currentDayISO = todayWeekday == 1 ? 7 : todayWeekday - 1
        
        // Find first workout with dayNumber > currentDayISO
        if let next = workouts.first(where: { $0.dayNumber > currentDayISO }) {
            return "\(next.name) • \(dayName(for: next.dayNumber))"
        }
        
        // Wrap around to first workout of the week
        if let first = workouts.first {
            return "\(first.name) • \(dayName(for: first.dayNumber))"
        }
        
        return "No Plan"
    }
    
    private func dayName(for number: Int) -> String {
        switch number {
        case 1: return "Monday"
        case 2: return "Tuesday"
        case 3: return "Wednesday"
        case 4: return "Thursday"
        case 5: return "Friday"
        case 6: return "Saturday"
        case 7: return "Sunday"
        default: return "Day \(number)"
        }
    }
}
