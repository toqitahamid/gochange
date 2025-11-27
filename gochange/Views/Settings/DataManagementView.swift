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
        ScrollView {
            VStack(spacing: 20) {
                // Data Actions Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("DATA ACTIONS")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                    
                    VStack(spacing: 0) {
                        Button {
                            exportWorkoutData()
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(Color(hex: "#64B5F6"))
                                Text("Export Data")
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding(20)
                        }
                        
                        Divider()
                            .background(Color.gray.opacity(0.1))
                            .padding(.leading, 20)
                        
                        Button {
                            showingImportSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                    .foregroundColor(Color(hex: "#4DB6AC"))
                                Text("Import Data")
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding(20)
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(24)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    )
                }
                
                // Debug Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("DEBUG")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                    
                    NavigationLink(destination: WatchSyncDebugView()) {
                        HStack {
                            Image(systemName: "applewatch")
                                .foregroundColor(Color(hex: "#9C27B0"))
                            Text("Watch Sync Debug")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .padding(20)
                    }
                    .background(Color.white)
                    .cornerRadius(24)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    )
                }
                
                // Statistics Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("STATISTICS")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 0) {
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
                        .padding(20)
                        
                        Divider()
                            .background(Color.gray.opacity(0.1))
                            .padding(.leading, 20)
                        
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
                        .padding(20)
                        
                        Divider()
                            .background(Color.gray.opacity(0.1))
                            .padding(.leading, 20)
                        
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
                        .padding(20)
                    }
                    .background(Color.white)
                    .cornerRadius(24)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    )
                }
                
                // Reset Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("DANGER ZONE")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                    
                    Button {
                        showingResetAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                                .foregroundColor(Color(hex: "#FF6B6B"))
                            Text("Reset to Defaults")
                                .foregroundColor(Color(hex: "#FF6B6B"))
                            Spacer()
                        }
                        .padding(20)
                    }
                    .background(Color.white)
                    .cornerRadius(24)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color(hex: "#FF6B6B").opacity(0.2), lineWidth: 1)
                    )
                }
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .navigationTitle("Data Management")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(hex: "#F5F5F7").ignoresSafeArea())
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

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        DataManagementView()
            .modelContainer(for: [WorkoutDay.self, WorkoutSession.self])
    }
}
