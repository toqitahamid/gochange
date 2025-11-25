import SwiftUI
import SwiftData

struct HistoryListView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    
    @State private var selectedFilter: WorkoutFilter = .all
    @State private var searchText = ""
    
    enum WorkoutFilter: String, CaseIterable {
        case all = "All"
        case push = "Push"
        case pull = "Pull"
        case legs = "Legs"
        case fullbody = "Fullbody"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(WorkoutFilter.allCases, id: \.self) { filter in
                            FilterPill(
                                title: filter.rawValue,
                                isSelected: selectedFilter == filter,
                                color: colorFor(filter)
                            ) {
                                withAnimation {
                                    selectedFilter = filter
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                .background(Color.white)
                
                Divider()
                
                // Sessions List
                if filteredSessions.isEmpty {
                    emptyStateView
                } else {
                    List {
                        ForEach(groupedSessions.keys.sorted().reversed(), id: \.self) { monthKey in
                            Section(header: Text(monthKey)) {
                                ForEach(groupedSessions[monthKey] ?? []) { session in
                                    NavigationLink(destination: SessionDetailView(session: session)) {
                                        HistoryRowView(session: session)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(AppTheme.background)
            .navigationTitle("History")
            .searchable(text: $searchText, prompt: "Search workouts")
        }
    }
    
    private var filteredSessions: [WorkoutSession] {
        var result = sessions.filter { $0.isCompleted }
        
        if selectedFilter != .all {
            result = result.filter { $0.workoutDayName == selectedFilter.rawValue }
        }
        
        if !searchText.isEmpty {
            result = result.filter { session in
                session.workoutDayName.localizedCaseInsensitiveContains(searchText) ||
                session.exerciseLogs.contains { log in
                    log.exerciseName.localizedCaseInsensitiveContains(searchText)
                }
            }
        }
        
        return result
    }
    
    private var groupedSessions: [String: [WorkoutSession]] {
        Dictionary(grouping: filteredSessions) { session in
            session.date.formatted(as: "MMMM yyyy")
        }
    }
    
    private func colorFor(_ filter: WorkoutFilter) -> Color {
        switch filter {
        case .all: return AppTheme.accent
        case .push: return AppConstants.WorkoutColors.push
        case .pull: return AppConstants.WorkoutColors.pull
        case .legs: return AppConstants.WorkoutColors.legs
        case .fullbody: return AppConstants.WorkoutColors.fullbody
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Workout History")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Complete your first workout to see it here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.background)
    }
}

// MARK: - Filter Pill
struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? color : Color.gray.opacity(0.1))
                .cornerRadius(20)
        }
    }
}

// MARK: - History Row View
struct HistoryRowView: View {
    let session: WorkoutSession
    
    var body: some View {
        HStack(spacing: 12) {
            // Workout Type Indicator
            RoundedRectangle(cornerRadius: 4)
                .fill(AppConstants.WorkoutColors.color(for: session.workoutDayName))
                .frame(width: 4)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(session.workoutDayName)
                    .font(.headline)
                
                Text(session.date.formatted(as: "MMM d, yyyy"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if let duration = session.duration {
                    Text(duration.formattedDuration)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Text("\(session.exerciseLogs.count) exercises")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HistoryListView()
        .modelContainer(for: WorkoutSession.self)
}

