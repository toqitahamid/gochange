import SwiftUI
import SwiftData

struct PreviousWorkoutHistorySheet: View {
    let exerciseId: UUID
    let exerciseName: String
    let accentColor: Color
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("weightUnit") private var weightUnit: String = "lbs"

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
            let rir: Int?
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
            .background(Color.white)
            .navigationTitle("Last workout on \(historyData.first?.date.formatted(date: .abbreviated, time: .omitted) ?? "")")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18))
                            .foregroundColor(.primary)
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
        VStack(spacing: 0) {
            // Column Headers
            HStack(spacing: 0) {
                Text("SET")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 60, alignment: .leading)
                
                Text(weightUnit.uppercased())
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 80, alignment: .center)
                
                Spacer()
                
                Text("REPS")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 80, alignment: .center)
                
                Text("RIR")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 50, alignment: .center)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
            
            // Set Rows
            VStack(spacing: 0) {
                ForEach(Array(entry.sets.enumerated()), id: \.element.id) { index, set in
                    HStack(spacing: 0) {
                        // SET indicator
                        Group {
                            switch set.setType {
                            case .normal:
                                Text("\(set.setNumber)")
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(.primary)
                                
                            case .warmup:
                                ZStack {
                                    Circle()
                                        .stroke(Color.orange, lineWidth: 2)
                                        .frame(width: 28, height: 28)
                                    
                                    Image(systemName: "flame.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.orange)
                                }
                                
                            case .cooldown:
                                Image(systemName: "snowflake")
                                    .font(.system(size: 16))
                                    .foregroundColor(.blue)
                                
                            case .failure:
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.red)
                                
                            case .dropset:
                                Image(systemName: "arrow.down.right")
                                    .font(.system(size: 16))
                                    .foregroundColor(.purple)
                            }
                        }
                        .frame(width: 60)
                        
                        // Weight
                        Text(set.weight != nil ? "\(Int(set.weight!))" : "-")
                            .font(.system(size: 17))
                            .foregroundColor(.primary)
                            .frame(width: 80)
                        
                        Spacer()
                        
                        // Reps
                        Text(set.reps != nil ? "x\(set.reps!)" : "-")
                            .font(.system(size: 17))
                            .foregroundColor(.primary)
                            .frame(width: 80)
                        
                        // RIR
                        Text(set.rir != nil ? "\(set.rir!)" : "-")
                            .font(.system(size: 17))
                            .foregroundColor(.primary)
                            .frame(width: 50)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(set.isCompleted ? AppColors.background : Color.white)
                    
                    if index < entry.sets.count - 1 {
                        Divider()
                            .padding(.leading, 20)
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
        }
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
                    rir: setLog.rir,
                    setType: setLog.setType,
                    isCompleted: setLog.isCompleted
                )
            }

            return WorkoutHistoryEntry(date: session.date, sets: setData)
        }
        .prefix(1) // Show only the last workout
        .map { $0 }
    }
}
