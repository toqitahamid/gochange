import SwiftUI
import SwiftData

struct NotificationSettingsView: View {
    @StateObject private var notificationService = NotificationService.shared
    @Query private var workoutDays: [WorkoutDay]
    @State private var showingReminderSettings = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            Section {
                if !notificationService.isAuthorized && notificationService.authorizationStatus == .notDetermined {
                    Button {
                        Task {
                            await notificationService.requestAuthorization()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "bell.badge")
                                .foregroundColor(Color(hex: "#FFD54F"))
                            Text("Enable Notifications")
                                .foregroundColor(.primary)
                        }
                    }
                } else if notificationService.isAuthorized {
                    HStack {
                        Text("Status")
                            .foregroundColor(.primary)
                        Spacer()
                        Text("Enabled")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "#00D4AA"))
                    }
                    
                    Button {
                        showingReminderSettings = true
                    } label: {
                        HStack {
                            Text("Workout Reminders")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notifications Disabled")
                            .foregroundColor(.primary)
                        Text("Enable in Settings app")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(hex: "#F2F2F7"))
        .scrollContentBackground(.hidden)
        .sheet(isPresented: $showingReminderSettings) {
            ReminderSettingsView(workoutDays: workoutDays)
        }
        .onAppear {
            notificationService.checkAuthorizationStatus()
        }
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
            .modelContainer(for: [WorkoutDay.self])
    }
}
