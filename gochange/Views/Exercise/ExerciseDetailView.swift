import SwiftUI
import SwiftData
import PhotosUI
import AVKit

struct ExerciseDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    
    @Bindable var exercise: Exercise
    
    @State private var showingMediaPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingNotes = false
    @State private var notesText = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                headerSection
                
                // Media Section
                mediaSection
                
                // Stats Section
                statsSection
                
                // Progress Chart
                if !progressDataPoints.isEmpty {
                    ProgressChartView(
                        exerciseName: exercise.name,
                        dataPoints: progressDataPoints
                    )
                }
                
                // History Section
                historySection
                
                // Notes Section
                notesSection
            }
            .padding(.horizontal, 20)
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
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .onAppear {
            notesText = exercise.notes ?? ""
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Muscle Group Badge
            HStack {
                Label(exercise.muscleGroup, systemImage: "figure.strengthtraining.traditional")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(muscleGroupColor)
                    )
                
                Spacer()
                
                if let workoutDay = exercise.workoutDay {
                    Text("Day \(workoutDay.dayNumber): \(workoutDay.name)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
            
            // Default Sets/Reps
            HStack(spacing: 12) {
                ExerciseStatBox(title: "Default Sets", value: "\(exercise.defaultSets)")
                ExerciseStatBox(title: "Default Reps", value: exercise.defaultReps)
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
    
    // MARK: - Media Section
    private var mediaSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Form Reference")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                PhotosPicker(
                    selection: $selectedPhotoItem,
                    matching: .any(of: [.images, .videos])
                ) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text(exercise.mediaURL == nil ? "Add" : "Change")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#00D4AA"))
                }
                .onChange(of: selectedPhotoItem) { _, newItem in
                    Task {
                        await loadMedia(from: newItem)
                    }
                }
            }
            
            if let mediaURL = exercise.mediaURL, let mediaType = exercise.mediaType {
                mediaPreview(url: mediaURL, type: mediaType)
            } else {
                emptyMediaPlaceholder
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
    
    private func mediaPreview(url: String, type: Exercise.MediaType) -> some View {
        Group {
            if type == .video {
                if let videoURL = URL(string: url) {
                    VideoPlayer(player: AVPlayer(url: videoURL))
                        .frame(height: 200)
                        .cornerRadius(12)
                }
            } else {
                if let data = FileManager.default.contents(atPath: url),
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .cornerRadius(12)
                }
            }
        }
    }
    
    private var emptyMediaPlaceholder: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 24))
                    .foregroundColor(.gray)
            }
            
            Text("No form reference added")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Text("Add a photo or video to remember proper form")
                .font(.caption)
                .foregroundColor(.gray.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PERSONAL RECORDS")
                .font(.system(size: 12, weight: .bold))
                .tracking(1.5)
                .foregroundColor(.gray)
                .padding(.horizontal, 4)
            
            HStack(spacing: 10) {
                ExercisePRCard(
                    title: "Heaviest",
                    value: heaviestWeight != nil ? String(format: "%.1f lbs", heaviestWeight!) : "--",
                    icon: "scalemass.fill",
                    color: Color(hex: "#FF6B35")
                )
                
                ExercisePRCard(
                    title: "Most Reps",
                    value: mostReps != nil ? "\(mostReps!)" : "--",
                    icon: "repeat.circle.fill",
                    color: Color(hex: "#00D4AA")
                )
                
                ExercisePRCard(
                    title: "Best Volume",
                    value: bestVolume != nil ? formatVolume(bestVolume!) : "--",
                    icon: "chart.bar.fill",
                    color: Color(hex: "#64B5F6")
                )
            }
        }
    }
    
    // MARK: - History Section
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RECENT HISTORY")
                .font(.system(size: 12, weight: .bold))
                .tracking(1.5)
                .foregroundColor(.gray)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                if exerciseHistory.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 28))
                            .foregroundColor(.gray)
                        
                        Text("No history yet")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                } else {
                    ForEach(Array(exerciseHistory.prefix(5).enumerated()), id: \.element.id) { index, log in
                        ExerciseHistoryRowView(log: log, sessionDate: sessionDate(for: log))
                        
                        if index < min(exerciseHistory.count - 1, 4) {
                            Rectangle()
                                .fill(Color.white.opacity(0.08))
                                .frame(height: 1)
                        }
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("NOTES")
                .font(.system(size: 12, weight: .bold))
                .tracking(1.5)
                .foregroundColor(.gray)
                .padding(.horizontal, 4)
            
            TextEditor(text: $notesText)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 80)
                .padding(12)
                .background(Color.white.opacity(0.05))
                .foregroundColor(.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .onChange(of: notesText) { _, newValue in
                    exercise.notes = newValue.isEmpty ? nil : newValue
                    try? modelContext.save()
                }
        }
    }
    
    // MARK: - Computed Properties
    private var muscleGroupColor: Color {
        switch exercise.muscleGroup.lowercased() {
        case "chest": return Color(hex: "#E57373")
        case "back": return Color(hex: "#64B5F6")
        case "shoulders": return Color(hex: "#FFB74D")
        case "biceps": return Color(hex: "#BA68C8")
        case "triceps": return Color(hex: "#F06292")
        case "quads", "hamstrings", "glutes": return Color(hex: "#00D4AA")
        case "calves": return Color(hex: "#4DB6AC")
        case "core": return Color(hex: "#FFD54F")
        default: return .gray
        }
    }
    
    private var exerciseHistory: [ExerciseLog] {
        sessions
            .flatMap { $0.exerciseLogs }
            .filter { $0.exerciseId == exercise.id }
    }
    
    private func sessionDate(for log: ExerciseLog) -> Date? {
        sessions.first { $0.exerciseLogs.contains { $0.id == log.id } }?.date
    }
    
    private var heaviestWeight: Double? {
        exerciseHistory
            .flatMap { $0.sets }
            .filter { $0.isCompleted }
            .compactMap { $0.weight }
            .max()
    }
    
    private var mostReps: Int? {
        exerciseHistory
            .flatMap { $0.sets }
            .filter { $0.isCompleted }
            .compactMap { $0.actualReps }
            .max()
    }
    
    private var bestVolume: Double? {
        exerciseHistory.map { log in
            log.sets.reduce(0) { total, set in
                if set.isCompleted, let weight = set.weight, let reps = set.actualReps {
                    return total + (weight * Double(reps))
                }
                return total
            }
        }.max()
    }
    
    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fk", volume / 1000)
        }
        return String(format: "%.0f", volume)
    }
    
    private var progressDataPoints: [ProgressDataPoint] {
        // Group exercise logs by session date and create data points
        var dataPoints: [ProgressDataPoint] = []
        
        for session in sessions.filter({ $0.isCompleted }).reversed() {
            guard let log = session.exerciseLogs.first(where: { $0.exerciseId == exercise.id }) else {
                continue
            }
            
            let completedSets = log.sets.filter { $0.isCompleted }
            guard !completedSets.isEmpty else { continue }
            
            let maxWeight = completedSets.compactMap { $0.weight }.max() ?? 0
            let totalReps = completedSets.compactMap { $0.actualReps }.reduce(0, +)
            let totalVolume = completedSets.reduce(0.0) { total, set in
                if let weight = set.weight, let reps = set.actualReps {
                    return total + (weight * Double(reps))
                }
                return total
            }
            
            dataPoints.append(ProgressDataPoint(
                date: session.date,
                maxWeight: maxWeight,
                totalVolume: totalVolume,
                totalReps: totalReps
            ))
        }
        
        return dataPoints
    }
    
    // MARK: - Methods
    private func loadMedia(from item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                let mediaService = MediaService()
                let isVideo = item.supportedContentTypes.contains(.movie)
                let type: Exercise.MediaType = isVideo ? .video : .image
                
                if let path = mediaService.saveMedia(data: data, type: type, for: exercise.id) {
                    exercise.mediaURL = path
                    exercise.mediaType = type
                    try? modelContext.save()
                }
            }
        } catch {
            print("Error loading media: \(error)")
        }
    }
}

// MARK: - Exercise Stat Box
struct ExerciseStatBox: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
        )
    }
}

// MARK: - Exercise PR Card
struct ExercisePRCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Exercise History Row View
struct ExerciseHistoryRowView: View {
    let log: ExerciseLog
    let sessionDate: Date?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let date = sessionDate {
                Text(date.formatted(as: "MMM d, yyyy"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(log.sets.filter { $0.isCompleted }) { set in
                        Text("\(set.weight != nil ? String(format: "%.0f", set.weight!) : "-") × \(set.actualReps ?? 0)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(6)
                    }
                }
            }
        }
        .padding(14)
    }
}

#Preview {
    let exercise = Exercise(name: "Bench Press", defaultSets: 3, defaultReps: "8", muscleGroup: "Chest")
    
    return NavigationStack {
        ExerciseDetailView(exercise: exercise)
    }
    .modelContainer(for: [Exercise.self, WorkoutSession.self])
}
