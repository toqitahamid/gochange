import Foundation
import WatchConnectivity
import Combine

/// Connectivity manager for the Watch side of communication
class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    
    @Published var workoutDays: [WatchWorkoutDay] = []
    @Published var isConnected = false
    
    private var session: WCSession?
    
    override private init() {
        super.init()
        setupSession()
    }
    
    private func setupSession() {
        guard WCSession.isSupported() else { return }
        
        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }
    
    // MARK: - Send to iPhone
    
    func sendMessage(_ message: [String: Any], replyHandler: (([String: Any]) -> Void)? = nil) {
        guard let session = session,
              session.isReachable else {
            // Queue message for later
            return
        }
        
        session.sendMessage(message, replyHandler: replyHandler) { error in
            print("Error sending message: \(error)")
        }
    }
    
    func requestWorkoutDays() {
        sendMessage(["type": "requestWorkoutDays"]) { response in
            // Handle response
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isConnected = activationState == .activated
        }
        
        // Request workout days on activation
        if activationState == .activated {
            requestWorkoutDays()
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isConnected = session.isReachable
        }
    }
    
    // MARK: - Receiving Data
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handleReceivedMessage(message)
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        handleReceivedMessage(message)
        replyHandler(["status": "received"])
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        handleReceivedMessage(applicationContext)
    }
    
    private func handleReceivedMessage(_ message: [String: Any]) {
        guard let type = message["type"] as? String else { return }
        
        switch type {
        case "workoutDays":
            if let data = message["data"] as? Data {
                do {
                    let days = try JSONDecoder().decode([WatchWorkoutDay].self, from: data)
                    DispatchQueue.main.async {
                        self.workoutDays = days
                    }
                } catch {
                    print("Error decoding workout days: \(error)")
                }
            }
            
        default:
            print("Unknown message type: \(type)")
        }
    }
}

// MARK: - Watch Data Models

struct WatchWorkoutDay: Codable, Identifiable {
    let id: UUID
    let name: String
    let dayNumber: Int
    let colorHex: String
    let exercises: [WatchExercise]
}

struct WatchExercise: Codable, Identifiable {
    let id: UUID
    let name: String
    let defaultSets: Int
    let defaultReps: String
    let muscleGroup: String
}

