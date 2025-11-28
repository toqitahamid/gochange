import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var workoutDays: [WorkoutDay]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // General Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("GENERAL")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 20)
                            .padding(.top, 4)
                        
                        VStack(spacing: 0) {
                            NavigationLink(destination: AccountSettingsView()) {
                                HStack {
                                    Image(systemName: "person.circle.fill")
                                        .foregroundColor(Color(hex: "#4DB6AC"))
                                    Text("Account")
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }
                                .padding(20)
                            }
                            
                            Divider()
                                .background(Color.gray.opacity(0.1))
                                .padding(.leading, 20)
                            
                            NavigationLink(destination: CustomizationSettingsView()) {
                                HStack {
                                    Image(systemName: "slider.horizontal.3")
                                        .foregroundColor(Color(hex: "#FFB74D"))
                                    Text("Customization")
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }
                                .padding(20)
                            }
                            
                            Divider()
                                .background(Color.gray.opacity(0.1))
                                .padding(.leading, 20)
                            
                            NavigationLink(destination: NotificationSettingsView()) {
                                HStack {
                                    Image(systemName: "bell.fill")
                                        .foregroundColor(Color(hex: "#FF6B6B"))
                                    Text("Notifications")
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
                    }
                    
                    // Data Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("DATA")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 0) {
                            NavigationLink(destination: DataSourcesView()) {
                                HStack {
                                    Image(systemName: "externaldrive.fill")
                                        .foregroundColor(Color(hex: "#64B5F6"))
                                    Text("Data Sources")
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }
                                .padding(20)
                            }
                            
                            Divider()
                                .background(Color.gray.opacity(0.1))
                                .padding(.leading, 20)
                            
                            NavigationLink(destination: DataManagementView()) {
                                HStack {
                                    Image(systemName: "folder.fill")
                                        .foregroundColor(Color(hex: "#9575CD"))
                                    Text("Data Management")
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
                    }
                    

                    
                    // About Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("ABOUT")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 0) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(Color(hex: "#64B5F6"))
                                Text("Version")
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("1.0.0")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            .padding(20)
                            
                            Divider()
                                .background(Color.gray.opacity(0.1))
                                .padding(.leading, 20)
                            
                            Button {
                                if let url = URL(string: "https://github.com") {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                                        .foregroundColor(Color(hex: "#9575CD"))
                                    Text("View Source Code")
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
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
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(hex: "#F5F5F7").ignoresSafeArea())
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [WorkoutDay.self, WorkoutSession.self])
}
