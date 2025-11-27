import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var workoutDays: [WorkoutDay]
    
    var body: some View {
        NavigationStack {
            List {
                // General Section
                Section(header: Text("GENERAL")) {
                    NavigationLink(destination: AccountSettingsView()) {
                        Label("Account", systemImage: "person.circle.fill")
                            .foregroundColor(.primary)
                    }
                    
                    NavigationLink(destination: CustomizationSettingsView()) {
                        Label("Customization", systemImage: "slider.horizontal.3")
                            .foregroundColor(.primary)
                    }
                    
                    NavigationLink(destination: NotificationSettingsView()) {
                        Label("Notifications", systemImage: "bell.fill")
                            .foregroundColor(.primary)
                    }
                }
                
                // Data Section
                Section(header: Text("DATA")) {
                    NavigationLink(destination: DataSourcesView()) {
                        Label("Data Sources", systemImage: "externaldrive.fill")
                            .foregroundColor(.primary)
                    }
                    
                    NavigationLink(destination: DataManagementView()) {
                        Label("Data Management", systemImage: "folder.fill")
                            .foregroundColor(.primary)
                    }
                }
                
                // Resources Section
                Section(header: Text("RESOURCES")) {
                    NavigationLink(destination: RecoveryDashboardView()) {
                        Label("Recovery Dashboard", systemImage: "heart.text.square.fill")
                            .foregroundColor(.primary)
                    }
                    
                    NavigationLink(destination: AnalyticsDashboardView()) {
                        Label("Advanced Analytics", systemImage: "chart.bar.xaxis")
                            .foregroundColor(.primary)
                    }
                    
                    NavigationLink(destination: ExerciseLibraryView()) {
                        Label {
                            HStack {
                                Text("Exercise Library")
                                Spacer()
                                Text("\(workoutDays.flatMap { $0.exercises }.count)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        } icon: {
                            Image(systemName: "figure.strengthtraining.traditional")
                        }
                        .foregroundColor(.primary)
                    }
                }
                
                // About Section
                Section(header: Text("ABOUT")) {
                    HStack {
                        Label("Version", systemImage: "info.circle.fill")
                            .foregroundColor(.primary)
                        Spacer()
                        Text("1.0.0")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Button {
                        if let url = URL(string: "https://github.com") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("View Source Code", systemImage: "chevron.left.forwardslash.chevron.right")
                            .foregroundColor(.primary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(hex: "#F2F2F7"))
            .scrollContentBackground(.hidden)
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [WorkoutDay.self, WorkoutSession.self])
}
