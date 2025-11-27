import SwiftUI
import HealthKit

struct DataSourcesView: View {
    @StateObject private var healthKitService = HealthKitService.shared
    @AppStorage("healthKitEnabled") private var healthKitEnabled: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            Section(header: Text("HEALTH")) {
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
                            }
                        }
                    } else if healthKitService.isAuthorized {
                        Toggle("Sync to Apple Health", isOn: $healthKitEnabled)
                            .tint(Color(hex: "#00D4AA"))
                        
                        Button {
                            if let url = URL(string: "x-apple-health://") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack {
                                Text("Open Health App")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Health Access Denied")
                                .foregroundColor(.primary)
                            Text("Enable in Settings > Privacy > Health")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    Text("HealthKit not available")
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("APPLE WATCH")) {
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
                
                if WatchConnectivityService.shared.isPaired && !WatchConnectivityService.shared.isWatchAppInstalled {
                    Button {
                        if let url = URL(string: "itms-watch://") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Text("Install Watch App")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Data Sources")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(hex: "#F2F2F7"))
        .scrollContentBackground(.hidden)
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
