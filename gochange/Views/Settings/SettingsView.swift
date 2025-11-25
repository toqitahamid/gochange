import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var workoutDays: [WorkoutDay]
    @Query private var sessions: [WorkoutSession]
    
    @AppStorage("weightUnit") private var weightUnit: String = "lbs"
    @AppStorage("restTimerDuration") private var restTimerDuration: Double = 90
    @AppStorage("hapticFeedback") private var hapticFeedback: Bool = true
    
    @State private var showingExportSheet = false
    @State private var showingImportSheet = false
    @State private var showingResetAlert = false
    @State private var exportData: Data?
    
    private let dataService = DataService()
    private let mediaService = MediaService()
    
    var body: some View {
        NavigationStack {
            List {
                // Units Section
                Section("Units") {
                    Picker("Weight Unit", selection: $weightUnit) {
                        Text("Pounds (lbs)").tag("lbs")
                        Text("Kilograms (kg)").tag("kg")
                    }
                }
                
                // Timer Section
                Section("Rest Timer") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Default Duration")
                            Spacer()
                            Text("\(Int(restTimerDuration))s")
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $restTimerDuration, in: 30...180, step: 15) {
                            Text("Rest Timer")
                        }
                    }
                }
                
                // Feedback Section
                Section("Feedback") {
                    Toggle("Haptic Feedback", isOn: $hapticFeedback)
                }
                
                // Data Section
                Section("Data Management") {
                    Button {
                        exportWorkoutData()
                    } label: {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }
                    
                    Button {
                        showingImportSheet = true
                    } label: {
                        Label("Import Data", systemImage: "square.and.arrow.down")
                    }
                    
                    Button(role: .destructive) {
                        showingResetAlert = true
                    } label: {
                        Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                    }
                }
                
                // Stats Section
                Section("Statistics") {
                    HStack {
                        Text("Total Workouts")
                        Spacer()
                        Text("\(sessions.filter { $0.isCompleted }.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Exercises")
                        Spacer()
                        Text("\(workoutDays.flatMap { $0.exercises }.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Media Storage")
                        Spacer()
                        Text(mediaService.formattedStorageSize())
                            .foregroundColor(.secondary)
                    }
                }
                
                // About Section
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://github.com")!) {
                        Label("View Source Code", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingExportSheet) {
                if let data = exportData {
                    ShareSheet(activityItems: [data])
                }
            }
            .fileImporter(
                isPresented: $showingImportSheet,
                allowedContentTypes: [.json]
            ) { result in
                handleImport(result)
            }
            .alert("Reset All Data?", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    resetToDefaults()
                }
            } message: {
                Text("This will delete all your workout history and reset exercises to defaults. This action cannot be undone.")
            }
        }
    }
    
    private func exportWorkoutData() {
        if let data = dataService.exportData(workoutDays: workoutDays, sessions: sessions) {
            exportData = data
            showingExportSheet = true
        }
    }
    
    private func handleImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            
            do {
                let data = try Data(contentsOf: url)
                try dataService.importData(from: data, context: modelContext)
            } catch {
                print("Import error: \(error)")
            }
        case .failure(let error):
            print("File selection error: \(error)")
        }
    }
    
    private func resetToDefaults() {
        // Delete all sessions
        for session in sessions {
            modelContext.delete(session)
        }
        
        // Delete all workout days
        for day in workoutDays {
            modelContext.delete(day)
        }
        
        // Recreate default workouts
        let defaultWorkouts = DefaultWorkoutData.createDefaultWorkouts()
        for workout in defaultWorkouts {
            modelContext.insert(workout)
        }
        
        try? modelContext.save()
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView()
        .modelContainer(for: [WorkoutDay.self, WorkoutSession.self])
}

