import SwiftUI
import SwiftData

struct NotificationSettingsView: View {
    @StateObject private var notificationService = NotificationService.shared
    @Query private var workoutDays: [WorkoutDay]
    @State private var showingReminderSettings = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Notification Status Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("NOTIFICATIONS")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                    
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
                                Spacer()
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
                    } else if notificationService.isAuthorized {
                        VStack(spacing: 0) {
                            HStack {
                                Text("Status")
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("Enabled")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(hex: "#00D4AA"))
                            }
                            .padding(20)
                            
                            Divider()
                                .background(Color.gray.opacity(0.1))
                                .padding(.leading, 20)
                            
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
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notifications Disabled")
                                .foregroundColor(.primary)
                            Text("Enable in Settings app")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .background(Color.white)
                        .cornerRadius(24)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                        )
                    }
                }
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(hex: "#F5F5F7").ignoresSafeArea())
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
