import SwiftUI
import SwiftData

struct RestDayLoggingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedDate = Date()
    @State private var restDayType: RestDayType = .complete
    @State private var quality: Int = 3
    @State private var energyLevel: Int = 3
    @State private var stressLevel: Int = 3
    @State private var notes: String = ""
    @State private var selectedMuscles: Set<String> = []

    @State private var isSyncingSleep = false
    @State private var sleepData: SleepData?

    private let muscleGroups = ["Chest", "Back", "Shoulders", "Biceps", "Triceps", "Legs", "Glutes", "Core", "Forearms"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Date") {
                    DatePicker("Rest Day", selection: $selectedDate, displayedComponents: .date)
                }

                Section("Rest Day Type") {
                    Picker("Type", selection: $restDayType) {
                        Text("Complete Rest").tag(RestDayType.complete)
                        Text("Active Recovery").tag(RestDayType.active)
                        Text("Scheduled Rest").tag(RestDayType.scheduled)
                        Text("Recovery Day").tag(RestDayType.recovery)
                    }
                    .pickerStyle(.menu)

                    Text(restDayTypeDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Sleep Data") {
                    if let sleep = sleepData {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Total Sleep")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(sleep.formattedTotal)
                                    .font(.headline)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Quality")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(sleep.qualityPercentage)%")
                                    .font(.headline)
                                    .foregroundStyle(sleepQualityColor(sleep.quality))
                            }
                        }

                        HStack {
                            sleepStageView("Deep", duration: sleep.formattedDeep, color: .indigo)
                            Divider()
                            sleepStageView("REM", duration: sleep.formattedREM, color: .purple)
                            Divider()
                            sleepStageView("Core", duration: sleep.formattedCore, color: .blue)
                        }
                        .frame(height: 60)
                    } else {
                        Button(action: syncSleepData) {
                            HStack {
                                if isSyncingSleep {
                                    ProgressView()
                                } else {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                }
                                Text("Sync from HealthKit")
                            }
                        }
                        .disabled(isSyncingSleep)
                    }
                }

                Section("How Do You Feel?") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Overall Quality")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 12) {
                            ForEach(1...5, id: \.self) { rating in
                                RatingButton(
                                    rating: rating,
                                    currentRating: quality,
                                    label: qualityLabel(rating)
                                ) {
                                    quality = rating
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Energy Level")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 12) {
                            ForEach(1...5, id: \.self) { rating in
                                RatingButton(
                                    rating: rating,
                                    currentRating: energyLevel,
                                    emoji: energyEmoji(rating)
                                ) {
                                    energyLevel = rating
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Stress Level")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 12) {
                            ForEach(1...5, id: \.self) { rating in
                                RatingButton(
                                    rating: rating,
                                    currentRating: stressLevel,
                                    emoji: stressEmoji(rating)
                                ) {
                                    stressLevel = rating
                                }
                            }
                        }
                    }
                }

                Section("Muscle Soreness") {
                    if selectedMuscles.isEmpty {
                        Text("No sore muscles selected")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(selectedMuscles).sorted(), id: \.self) { muscle in
                            HStack {
                                Text(muscle)
                                Spacer()
                                Button(action: { selectedMuscles.remove(muscle) }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                    }

                    Menu {
                        ForEach(muscleGroups.filter { !selectedMuscles.contains($0) }, id: \.self) { muscle in
                            Button(muscle) {
                                selectedMuscles.insert(muscle)
                            }
                        }
                    } label: {
                        Label("Add Sore Muscle", systemImage: "plus.circle.fill")
                    }
                    .disabled(selectedMuscles.count >= muscleGroups.count)
                }

                Section("Notes") {
                    TextField("How was your rest day?", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Log Rest Day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveRestDay()
                    }
                }
            }
        }
    }

    private var restDayTypeDescription: String {
        switch restDayType {
        case .complete:
            return "Full rest with no physical activity"
        case .active:
            return "Light activity like walking, yoga, or stretching"
        case .scheduled:
            return "Planned rest day in your training program"
        case .recovery:
            return "Recovery from overtraining or injury"
        }
    }

    private func sleepStageView(_ label: String, duration: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(duration)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }

    private func sleepQualityColor(_ quality: Double) -> Color {
        if quality >= 0.8 {
            return .green
        } else if quality >= 0.6 {
            return .blue
        } else if quality >= 0.4 {
            return .orange
        } else {
            return .red
        }
    }

    private func qualityLabel(_ rating: Int) -> String {
        switch rating {
        case 1: return "Poor"
        case 2: return "Fair"
        case 3: return "Good"
        case 4: return "Great"
        case 5: return "Excellent"
        default: return ""
        }
    }

    private func energyEmoji(_ rating: Int) -> String {
        switch rating {
        case 1: return "🔋"
        case 2: return "😴"
        case 3: return "😐"
        case 4: return "😊"
        case 5: return "⚡️"
        default: return ""
        }
    }

    private func stressEmoji(_ rating: Int) -> String {
        switch rating {
        case 1: return "😌"
        case 2: return "🙂"
        case 3: return "😐"
        case 4: return "😰"
        case 5: return "😫"
        default: return ""
        }
    }

    private func syncSleepData() {
        isSyncingSleep = true

        Task {
            sleepData = await HealthKitService.shared.getSleepData(for: selectedDate)
            isSyncingSleep = false
        }
    }

    private func saveRestDay() {
        RecoveryService.shared.logRestDay(
            date: selectedDate,
            type: restDayType,
            notes: notes.isEmpty ? nil : notes,
            quality: quality,
            musclesSore: Array(selectedMuscles),
            energyLevel: energyLevel,
            stressLevel: stressLevel,
            context: modelContext
        )

        // If we have sleep data, update the rest day with it
        if let sleep = sleepData {
            Task {
                await RecoveryService.shared.syncSleepToRestDay(context: modelContext)
            }
        }

        dismiss()
    }
}

struct RatingButton: View {
    let rating: Int
    let currentRating: Int
    var label: String?
    var emoji: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                if let emoji = emoji {
                    Text(emoji)
                        .font(.title2)
                } else {
                    Text("\(rating)")
                        .font(.headline)
                }

                if let label = label {
                    Text(label)
                        .font(.caption2)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(rating == currentRating ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(rating == currentRating ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RestDayLoggingView()
        .modelContainer(for: [RestDay.self, RecoveryMetrics.self])
}
