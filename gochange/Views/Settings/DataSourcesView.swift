import SwiftUI
import HealthKit

struct DataSourcesView: View {
    @StateObject private var healthKitService = HealthKitService.shared
    @AppStorage("healthKitEnabled") private var healthKitEnabled: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Health Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("HEALTH")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                    
                    if healthKitService.isHealthKitAvailable {
                        if !healthKitService.isAuthorized && healthKitService.authorizationStatus == .notDetermined {
                            Button {
                                Task {
                                    let authorized = await healthKitService.requestAuthorization()
                                    if authorized {
                                        healthKitEnabled = true
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "heart.fill")
                                        .foregroundColor(Color(hex: "#FF6B6B"))
                                    Text("Connect Apple Health")
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
                        } else if healthKitService.isAuthorized {
                            VStack(spacing: 0) {
                                Toggle("Sync to Apple Health", isOn: $healthKitEnabled)
                                    .tint(Color(hex: "#00D4AA"))
                                    .padding(20)
                                
                                Divider()
                                    .background(Color.gray.opacity(0.1))
                                    .padding(.leading, 20)
                                
                                Button {
                                    if let url = URL(string: "x-apple-health://") {
                                        UIApplication.shared.open(url)
                                    }
                                } label: {
                                    HStack {
                                        Text("Open Health App")
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
                        } else {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Health Access Denied")
                                    .foregroundColor(.primary)
                                Text("Enable in Settings > Privacy > Health")
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
                    } else {
                        Text("HealthKit not available")
                            .foregroundColor(.secondary)
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
                
                // Apple Watch Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("APPLE WATCH")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Watch App")
                                .foregroundColor(.primary)
                            if WatchConnectivityService.shared.isPaired {
                                if WatchConnectivityService.shared.isWatchAppInstalled {
                                    Text("Installed & Connected")
                                        .font(.caption)
                                        .foregroundColor(Color(hex: "#00D4AA"))
                                } else {
                                    Text("Not Installed")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            } else {
                                Text("No Watch Paired")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        
                        if WatchConnectivityService.shared.isPaired && !WatchConnectivityService.shared.isWatchAppInstalled {
                            Divider()
                                .background(Color.gray.opacity(0.1))
                                .padding(.leading, 20)
                            
                            Button {
                                if let url = URL(string: "itms-watch://") {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                HStack {
                                    Text("Install Watch App")
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }
                                .padding(20)
                            }
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
        .navigationTitle("Data Sources")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(hex: "#F5F5F7").ignoresSafeArea())
        .onAppear {
            healthKitService.checkAuthorizationStatus()
        }
    }
}

#Preview {
    NavigationStack {
        DataSourcesView()
    }
}
