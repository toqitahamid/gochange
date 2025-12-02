import SwiftUI
import SwiftData

struct PreviousWorkoutHistorySheet: View {
    let exerciseId: UUID
    let exerciseName: String
    let accentColor: Color
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var historyData: [WorkoutHistoryEntry] = []

    struct WorkoutHistoryEntry: Identifiable {
        let id = UUID()
        let date: Date
        let sets: [SetData]

        struct SetData: Identifiable {
            let id = UUID()
            let setNumber: Int
            let weight: Double?
            let reps: Int?
            let setType: SetLog.SetType
            let isCompleted: Bool
        }

        var totalVolume: Double {
            sets.compactMap { set in
                guard let weight = set.weight, let reps = set.reps else { return nil }
                return weight * Double(reps)
            }.reduce(0, +)
        }

        var completedSets: Int {
            sets.filter { $0.isCompleted }.count
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    if historyData.isEmpty {
                        emptyStateView
                    } else {
                        ForEach(historyData) { entry in
                            historyEntryCard(entry)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color(hex: "#F5F5F7"))
            .navigationTitle("Previous Workouts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.gray.opacity(0.6))
                    }
                }
            }
        }
        .onAppear {
            loadHistoryData()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.3))

            Text("No History Yet")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primary)

            Text("Complete this exercise to see your workout history")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.top, 100)
    }

    private func historyEntryCard(_ entry: WorkoutHistoryEntry) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)

                    Text(entry.date.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Volume Badge
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Volume")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                    Text(String(format: "%.0f lbs", entry.totalVolume))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(accentColor)
                }
            }

            Divider()

            // Sets List
            VStack(spacing: 8) {
                ForEach(entry.sets) { set in
                    HStack {
                        // Set Type Badge
                        HStack(spacing: 6) {
                            Image(systemName: set.setType.icon)
                                .font(.system(size: 10, weight: .semibold))
                            Text("Set \(set.setNumber)")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(Color(hex: set.setType.color))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(Color(hex: set.setType.color).opacity(0.12))
                        )

                        Spacer()

                        // Weight x Reps
                        if let weight = set.weight, let reps = set.reps {
                            Text("\(Int(weight)) × \(reps)")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)
                        } else {
                            Text("—")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.secondary)
                        }

                        // Completion Indicator
                        Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 18))
                            .foregroundColor(set.isCompleted ? Color(hex: "#00D4AA") : .gray.opacity(0.3))
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }

    private func loadHistoryData() {
        // Fetch all completed workout sessions
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate<WorkoutSession> { session in
                session.isCompleted
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        guard let sessions = try? modelContext.fetch(descriptor) else { return }

        // Filter sessions that contain this exercise and map to history entries
        historyData = sessions.compactMap { session in
            // Find exercise log for this exercise in the session
            guard let exerciseLog = session.exerciseLogs.first(where: { $0.exerciseId == exerciseId }) else {
                return nil
            }

            let setData = exerciseLog.sets.map { setLog in
                WorkoutHistoryEntry.SetData(
                    setNumber: setLog.setNumber,
                    weight: setLog.weight,
                    reps: setLog.actualReps,
                    setType: setLog.setType,
                    isCompleted: setLog.isCompleted
                )
            }

            return WorkoutHistoryEntry(date: session.date, sets: setData)
        }
        .prefix(10) // Show last 10 workouts
        .map { $0 }
    }
}
