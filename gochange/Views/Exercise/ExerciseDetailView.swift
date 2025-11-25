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
                
                // History Section
                historySection
                
                // Notes Section
                notesSection
            }
            .padding()
        }
        .background(AppTheme.background)
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
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
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(muscleGroupColor)
                    .cornerRadius(20)
                
                Spacer()
                
                if let workoutDay = exercise.workoutDay {
                    Text("Day \(workoutDay.dayNumber): \(workoutDay.name)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Default Sets/Reps
            HStack(spacing: 24) {
                StatBox(title: "Default Sets", value: "\(exercise.defaultSets)")
                StatBox(title: "Default Reps", value: exercise.defaultReps)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
    
    // MARK: - Media Section
    private var mediaSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Form Reference")
                    .font(.headline)
                
                Spacer()
                
                PhotosPicker(
                    selection: $selectedPhotoItem,
                    matching: .any(of: [.images, .videos])
                ) {
                    Label(exercise.mediaURL == nil ? "Add" : "Change", systemImage: "plus.circle.fill")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.accent)
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
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
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
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("No form reference added")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Add a photo or video to remember proper form")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Personal Records")
                .font(.headline)
            
            HStack(spacing: 12) {
                PRCard(
                    title: "Heaviest",
                    value: heaviestWeight != nil ? String(format: "%.1f lbs", heaviestWeight!) : "--",
                    icon: "scalemass.fill",
                    color: .orange
                )
                
                PRCard(
                    title: "Most Reps",
                    value: mostReps != nil ? "\(mostReps!)" : "--",
                    icon: "repeat.circle.fill",
                    color: .green
                )
                
                PRCard(
                    title: "Best Volume",
                    value: bestVolume != nil ? formatVolume(bestVolume!) : "--",
                    icon: "chart.bar.fill",
                    color: .blue
                )
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
    
    // MARK: - History Section
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent History")
                .font(.headline)
            
            if exerciseHistory.isEmpty {
                Text("No history yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                ForEach(exerciseHistory.prefix(5)) { log in
                    ExerciseHistoryRow(log: log, sessionDate: sessionDate(for: log))
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
    
    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(.headline)
            
            TextEditor(text: $notesText)
                .frame(minHeight: 80)
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .onChange(of: notesText) { _, newValue in
                    exercise.notes = newValue.isEmpty ? nil : newValue
                    try? modelContext.save()
                }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
    
    // MARK: - Computed Properties
    private var muscleGroupColor: Color {
        switch exercise.muscleGroup.lowercased() {
        case "chest": return .red
        case "back": return .blue
        case "shoulders": return .orange
        case "biceps": return .purple
        case "triceps": return .pink
        case "quads", "hamstrings", "glutes": return .green
        case "calves": return .teal
        case "core": return .yellow
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

// MARK: - Stat Box
struct StatBox: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - PR Card
struct PRCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - Exercise History Row
struct ExerciseHistoryRow: View {
    let log: ExerciseLog
    let sessionDate: Date?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let date = sessionDate {
                Text(date.formatted(as: "MMM d, yyyy"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 8) {
                ForEach(log.sets.filter { $0.isCompleted }) { set in
                    Text("\(set.weight != nil ? String(format: "%.0f", set.weight!) : "-") × \(set.actualReps ?? 0)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let exercise = Exercise(name: "Bench Press", defaultSets: 3, defaultReps: "8", muscleGroup: "Chest")
    
    return NavigationStack {
        ExerciseDetailView(exercise: exercise)
    }
    .modelContainer(for: [Exercise.self, WorkoutSession.self])
}

