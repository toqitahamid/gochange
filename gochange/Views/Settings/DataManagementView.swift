import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct DataManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var workoutDays: [WorkoutDay]
    @Query private var sessions: [WorkoutSession]
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingExportSheet = false
    @State private var showingImportSheet = false
    @State private var showingResetAlert = false
    @State private var exportData: Data?
    
    private let dataService = DataService()
    private let mediaService = MediaService()
    
    var body: some View {
        List {
            Section {
                Button {
                    exportWorkoutData()
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(Color(hex: "#64B5F6"))
                        Text("Export Data")
                            .foregroundColor(.primary)
                    }
                }
                
                Button {
                    showingImportSheet = true
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                            .foregroundColor(Color(hex: "#4DB6AC"))
                        Text("Import Data")
                            .foregroundColor(.primary)
                    }
                }
            }
            
            Section {
                NavigationLink(destination: WatchSyncDebugView()) {
                    HStack {
                        Image(systemName: "applewatch")
                            .foregroundColor(Color(hex: "#9C27B0"))
                        Text("Watch Sync Debug")
                    }
                }
            }
            
            Section(header: Text("STATISTICS")) {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(Color(hex: "#FF6B35"))
                    Text("Total Workouts")
                        .foregroundColor(.primary)
                    Spacer()
                    Text("\(sessions.filter { $0.isCompleted }.count)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: "dumbbell.fill")
                        .foregroundColor(Color(hex: "#7CB9A8"))
                    Text("Exercises")
                        .foregroundColor(.primary)
                    Spacer()
                    Text("\(workoutDays.flatMap { $0.exercises }.count)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: "externaldrive.fill")
                        .foregroundColor(Color(hex: "#64B5F6"))
                    Text("Media Storage")
                        .foregroundColor(.primary)
                    Spacer()
                    Text(mediaService.formattedStorageSize())
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            Section {
                Button {
                    showingResetAlert = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                            .foregroundColor(Color(hex: "#FF6B6B"))
                        Text("Reset to Defaults")
                            .foregroundColor(Color(hex: "#FF6B6B"))
                    }
                }
            }
        }
        .navigationTitle("Data Management")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(hex: "#F2F2F7"))
        .scrollContentBackground(.hidden)
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

#Preview {
    NavigationStack {
        DataManagementView()
            .modelContainer(for: [WorkoutDay.self, WorkoutSession.self])
    }
}
