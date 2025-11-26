import SwiftUI
import SwiftData
import UniformTypeIdentifiers

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
            ScrollView {
                VStack(spacing: 20) {
                    // Units Section
                    SettingsSection(title: "UNITS") {
                        SettingsRow(icon: "scalemass", iconColor: Color(hex: "#FF6B35")) {
                            HStack {
                                Text("Weight Unit")
                                    .foregroundColor(.white)
                                Spacer()
                                Picker("", selection: $weightUnit) {
                                    Text("lbs").tag("lbs")
                                    Text("kg").tag("kg")
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 120)
                            }
                        }
                    }
                    
                    // Rest Timer Section
                    SettingsSection(title: "REST TIMER") {
                        VStack(spacing: 16) {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: "#00D4AA").opacity(0.15))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "timer")
                                        .foregroundColor(Color(hex: "#00D4AA"))
                                }
                                
                                Text("Default Duration")
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text("\(Int(restTimerDuration))s")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(hex: "#00D4AA"))
                            }
                            
                            Slider(value: $restTimerDuration, in: 30...180, step: 15)
                                .tint(Color(hex: "#00D4AA"))
                        }
                        .padding(16)
                    }
                    
                    // Feedback Section
                    SettingsSection(title: "FEEDBACK") {
                        SettingsRow(icon: "hand.tap", iconColor: Color(hex: "#BA68C8")) {
                            Toggle(isOn: $hapticFeedback) {
                                Text("Haptic Feedback")
                                    .foregroundColor(.white)
                            }
                            .tint(Color(hex: "#00D4AA"))
                        }
                    }
                    
                    // Library Section
                    SettingsSection(title: "LIBRARY") {
                        NavigationLink(destination: ExerciseLibraryView()) {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: "#00D4AA").opacity(0.15))
                                        .frame(width: 36, height: 36)
                                    
                                    Image(systemName: "figure.strengthtraining.traditional")
                                        .font(.system(size: 15))
                                        .foregroundColor(Color(hex: "#00D4AA"))
                                }
                                
                                Text("Exercise Library")
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text("\(workoutDays.flatMap { $0.exercises }.count)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.gray.opacity(0.5))
                            }
                            .padding(16)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Data Management Section
                    SettingsSection(title: "DATA MANAGEMENT") {
                        VStack(spacing: 0) {
                            SettingsButton(icon: "square.and.arrow.up", iconColor: Color(hex: "#64B5F6"), title: "Export Data") {
                                exportWorkoutData()
                            }
                            
                            Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1).padding(.leading, 52)
                            
                            SettingsButton(icon: "square.and.arrow.down", iconColor: Color(hex: "#4DB6AC"), title: "Import Data") {
                                showingImportSheet = true
                            }
                            
                            Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1).padding(.leading, 52)
                            
                            SettingsButton(icon: "arrow.counterclockwise", iconColor: Color(hex: "#FF6B6B"), title: "Reset to Defaults", isDestructive: true) {
                                showingResetAlert = true
                            }
                        }
                    }
                    
                    // Stats Section
                    SettingsSection(title: "STATISTICS") {
                        VStack(spacing: 0) {
                            SettingsInfoRow(icon: "flame.fill", iconColor: Color(hex: "#FF6B35"), title: "Total Workouts", value: "\(sessions.filter { $0.isCompleted }.count)")
                            
                            Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1).padding(.leading, 52)
                            
                            SettingsInfoRow(icon: "dumbbell.fill", iconColor: Color(hex: "#7CB9A8"), title: "Exercises", value: "\(workoutDays.flatMap { $0.exercises }.count)")
                            
                            Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1).padding(.leading, 52)
                            
                            SettingsInfoRow(icon: "externaldrive.fill", iconColor: Color(hex: "#64B5F6"), title: "Media Storage", value: mediaService.formattedStorageSize())
                        }
                    }
                    
                    // About Section
                    SettingsSection(title: "ABOUT") {
                        VStack(spacing: 0) {
                            SettingsInfoRow(icon: "info.circle.fill", iconColor: .gray, title: "Version", value: "1.0.0")
                            
                            Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1).padding(.leading, 52)
                            
                            SettingsButton(icon: "chevron.left.forwardslash.chevron.right", iconColor: Color(hex: "#00D4AA"), title: "View Source Code") {
                                if let url = URL(string: "https://github.com") {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
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
            .toolbar(.hidden, for: .navigationBar)
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

// MARK: - Settings Section
struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .tracking(1.5)
                .foregroundColor(.gray)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                content
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
}

// MARK: - Settings Row
struct SettingsRow<Content: View>: View {
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: Content
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(iconColor)
            }
            
            content
        }
        .padding(16)
    }
}

// MARK: - Settings Button
struct SettingsButton: View {
    let icon: String
    let iconColor: Color
    let title: String
    var isDestructive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 15))
                        .foregroundColor(iconColor)
                }
                
                Text(title)
                    .foregroundColor(isDestructive ? Color(hex: "#FF6B6B") : .white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.gray.opacity(0.5))
            }
            .padding(16)
        }
    }
}

// MARK: - Settings Info Row
struct SettingsInfoRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(iconColor)
            }
            
            Text(title)
                .foregroundColor(.white)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
        }
        .padding(16)
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
