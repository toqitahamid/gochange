import SwiftUI
import SwiftData

struct WatchSyncDebugView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var watchService = WatchConnectivityService.shared
    
    var body: some View {
        List {
            Section("Watch Connection Status") {
                HStack {
                    Text("Session Active")
                    Spacer()
                    Image(systemName: watchService.isSessionActive ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(watchService.isSessionActive ? .green : .red)
                }
                
                HStack {
                    Text("Watch Paired")
                    Spacer()
                    Image(systemName: watchService.isPaired ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(watchService.isPaired ? .green : .red)
                }
                
                HStack {
                    Text("Watch App Installed")
                    Spacer()
                    Image(systemName: watchService.isWatchAppInstalled ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(watchService.isWatchAppInstalled ? .green : .red)
                }
                
                HStack {
                    Text("Watch Reachable")
                    Spacer()
                    Image(systemName: watchService.isReachable ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(watchService.isReachable ? .green : .red)
                }
            }
            
            Section("Actions") {
                Button {
                    Task {
                        watchService.setModelContext(modelContext)
                        await watchService.fetchAndSendWorkoutDays()
                    }
                } label: {
                    Label("Sync Workouts to Watch", systemImage: "arrow.triangle.2.circlepath")
                }
            }
        }
        .navigationTitle("Watch Sync Debug")
        .onAppear {
            watchService.setModelContext(modelContext)
        }
    }
}

#Preview {
    NavigationStack {
        WatchSyncDebugView()
    }
}
