import SwiftUI
import SwiftData

struct HistoryListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    
    @State private var selectedFilter: WorkoutFilter = .all
    @State private var searchText = ""
    @State private var sessionToDelete: WorkoutSession?
    @State private var showingDeleteAlert = false
    
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
                // Search Bar
                HStack(spacing: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                        
                        TextField("Search workouts or exercises", text: $searchText)
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                            .autocorrectionDisabled()
                        
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Filter Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(WorkoutFilter.allCases, id: \.self) { filter in
                            HistoryFilterPill(
                                title: filter.rawValue,
                                isSelected: selectedFilter == filter,
                                color: colorFor(filter)
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedFilter = filter
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 16)
                }
                
                // Sessions List
                ScrollView {
                    if filteredSessions.isEmpty {
                        emptyStateView
                            .padding(.top, 60)
                    } else {
                        LazyVStack(spacing: 24) {
                            ForEach(groupedSessions.keys.sorted().reversed(), id: \.self) { monthKey in
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(monthKey.uppercased())
                                        .font(.system(size: 12, weight: .bold))
                                        .tracking(1.5)
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 4)
                                    
                                    VStack(spacing: 10) {
                                        ForEach(groupedSessions[monthKey] ?? []) { session in
                                            NavigationLink(destination: SessionDetailView(session: session)) {
                                                HistoryRowView(session: session)
                                            }
                                            .buttonStyle(ScaleButtonStyle())
                                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                                Button(role: .destructive) {
                                                    sessionToDelete = session
                                                    showingDeleteAlert = true
                                                } label: {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
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
            .alert("Delete Workout?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {
                    sessionToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let session = sessionToDelete {
                        deleteSession(session)
                    }
                }
            } message: {
                Text("This will permanently delete this workout session and all its data. This action cannot be undone.")
            }
        }
    }
    
    private func deleteSession(_ session: WorkoutSession) {
        modelContext.delete(session)
        try? modelContext.save()
        sessionToDelete = nil
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
        case .all: return Color(hex: "#00D4AA")
        case .push: return AppConstants.WorkoutColors.push
        case .pull: return AppConstants.WorkoutColors.pull
        case .legs: return AppConstants.WorkoutColors.legs
        case .fullbody: return AppConstants.WorkoutColors.fullbody
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
            }
            
            VStack(spacing: 8) {
                Text("No Workout History")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Complete your first workout to see it here")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - History Filter Pill
struct HistoryFilterPill: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .white : .gray)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? color : Color.white.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? color.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
                )
        }
    }
}

// MARK: - History Row View
struct HistoryRowView: View {
    let session: WorkoutSession
    
    private var accentColor: Color {
        AppConstants.WorkoutColors.color(for: session.workoutDayName)
    }
    
    var body: some View {
        HStack(spacing: 14) {
            // Workout Type Indicator & Icon
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
                
                Text(session.date.formatted(as: "MMM d, yyyy"))
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if let duration = session.duration {
                    Text(duration.formattedDuration)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Text("\(session.exerciseLogs.count) exercises")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

#Preview {
    HistoryListView()
        .modelContainer(for: WorkoutSession.self)
}
