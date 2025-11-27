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
            print("⚠️ iPhone not reachable, cannot send message")
            return
        }
        
        print("📤 Sending message to iPhone: \(message)")
        session.sendMessage(message, replyHandler: replyHandler) { error in
            print("❌ Error sending message: \(error.localizedDescription)")
        }
    }
    
    func requestWorkoutDays() {
        print("🔄 Requesting workout days from iPhone...")
        sendMessage(["type": "requestWorkoutDays"]) { response in
            print("✅ Received response from iPhone: \(response)")
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isConnected = activationState == .activated
        }
        
        if let error = error {
            print("❌ Watch session activation error: \(error)")
        } else {
            print("✅ Watch session activated with state: \(activationState.rawValue)")
        }
        
        // Request workout days on activation
        if activationState == .activated {
            print("📤 Requesting workout days from iPhone...")
            requestWorkoutDays()
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isConnected = session.isReachable
        }
        print("📱 iPhone reachability changed: \(session.isReachable)")
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
        print("📩 Watch received message with keys: \(message.keys)")
        
        guard let type = message["type"] as? String else {
            print("❌ No 'type' field in message")
            return
        }
        
        print("📩 Message type: \(type)")
        
        switch type {
        case "workoutDays":
            print("🏋️ Processing workoutDays message...")
            if let data = message["data"] as? Data {
                print("📊 Data size: \(data.count) bytes")
                do {
                    let days = try JSONDecoder().decode([WatchWorkoutDay].self, from: data)
                    print("✅ Successfully decoded \(days.count) workout days")
                    for (index, day) in days.enumerated() {
                        print("  Day \(index + 1): \(day.name) with \(day.exercises.count) exercises")
                    }
                    DispatchQueue.main.async {
                        self.workoutDays = days
                        print("✅ Updated workoutDays array on main thread")
                    }
                } catch {
                    print("❌ Error decoding workout days: \(error)")
                }
            } else {
                print("❌ No 'data' field found or wrong type. Message contents: \(message)")
            }
            
        default:
            print("⚠️ Unknown message type: \(type)")
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

