import Foundation
import WatchConnectivity
import Combine
import SwiftData

/// Service for communication between iPhone and Apple Watch
/// Handles sending workout data to watch and receiving completed workouts back
class WatchConnectivityService: NSObject, ObservableObject {
    static let shared = WatchConnectivityService()
    
    @Published var isReachable = false
    @Published var isPaired = false
    @Published var isWatchAppInstalled = false
    
    private var session: WCSession?
    private var modelContext: ModelContext?
    
    // Callback for when a workout is received from the watch
    var onWorkoutReceived: (([String: Any]) -> Void)?
    
    // MARK: - Initialization
    
    override private init() {
        super.init()
        setupSession()
    }
    
    private func setupSession() {
        guard WCSession.isSupported() else {
            print("WatchConnectivity is not supported on this device")
            return
        }
        
        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }
    
    // MARK: - Session State
    
    var isSessionActive: Bool {
        session?.activationState == .activated
    }
    
    // MARK: - Send Data to Watch
    
    /// Send workout days to the Apple Watch
    func sendWorkoutDays(_ workoutDays: [WorkoutDayTransfer]) {
        guard let session = session,
              session.activationState == .activated else {
            print("❌ Cannot send data: Session not activated")
            return
        }
        
        guard session.isWatchAppInstalled else {
            print("❌ Cannot send data: Watch app not installed")
            return
        }
        
        print("📤 Preparing to send \(workoutDays.count) workout days to watch")
        print("   isPaired: \(session.isPaired)")
        print("   isReachable: \(session.isReachable)")
        print("   isWatchAppInstalled: \(session.isWatchAppInstalled)")
        
        do {
            let data = try JSONEncoder().encode(workoutDays)
            let message: [String: Any] = [
                "type": "workoutDays",
                "data": data
            ]
            
            // Always update application context for persistence
            try session.updateApplicationContext(message)
            print("✅ Updated application context with \(workoutDays.count) workouts")
            
            // Also send immediate message if watch is reachable
            if session.isReachable {
                session.sendMessage(message, replyHandler: { response in
                    print("✅ Watch acknowledged receipt: \(response)")
                }) { error in
                    print("⚠️ Error sending immediate message: \(error.localizedDescription)")
                }
            }
        } catch {
            print("❌ Error encoding workout days: \(error)")
        }
    }
    
    
    /// Send a message to the watch
    func sendMessage(_ message: [String: Any], replyHandler: (([String: Any]) -> Void)? = nil) {
        guard let session = session,
              session.activationState == .activated,
              session.isReachable else {
            print("Cannot send message: Watch not reachable")
            return
        }
        
        session.sendMessage(message, replyHandler: replyHandler) { error in
            print("Error sending message: \(error.localizedDescription)")
        }
    }
    
    /// Transfer a file to the watch
    func transferFile(_ fileURL: URL, metadata: [String: Any]? = nil) {
        guard let session = session,
              session.activationState == .activated,
              session.isWatchAppInstalled else {
            print("Cannot transfer file: Watch app not available")
            return
        }
        
        session.transferFile(fileURL, metadata: metadata)
    }
    
    /// Update the application context (persisted data)
    func updateApplicationContext(_ context: [String: Any]) {
        guard let session = session,
              session.activationState == .activated else {
            return
        }
        
        do {
            try session.updateApplicationContext(context)
        } catch {
            print("Error updating application context: \(error)")
        }
    }
    
    // MARK: - Model Context Setup
    
    /// Set the model context for fetching workout data
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        
        // Send workout days immediately if watch is already connected
        if isSessionActive && isWatchAppInstalled {
            Task {
                await fetchAndSendWorkoutDays()
            }
        }
    }
    
    /// Fetch workout days from SwiftData and send to watch
    @MainActor
    func fetchAndSendWorkoutDays() async {
        print("🔄 Fetching workout days for watch...")
        
        guard let context = modelContext else {
            print("❌ Model context not set")
            return
        }
        
        do {
            let descriptor = FetchDescriptor<WorkoutDay>(
                sortBy: [SortDescriptor(\.dayNumber, order: .forward)]
            )
            let workoutDays = try context.fetch(descriptor)
            
            print("📊 Found \(workoutDays.count) workout days in database")
            
            // Convert to transfer models
            let transferDays = workoutDays.map { WorkoutDayTransfer(from: $0) }
            
            // Send to watch
            sendWorkoutDays(transferDays)
            
        } catch {
            print("❌ Error fetching workout days: \(error)")
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityService: WCSessionDelegate {
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isPaired = session.isPaired
            self.isWatchAppInstalled = session.isWatchAppInstalled
            self.isReachable = session.isReachable
        }
        
        if let error = error {
            print("WCSession activation failed: \(error.localizedDescription)")
        } else {
            print("WCSession activated with state: \(activationState.rawValue)")
            print("isPaired: \(session.isPaired), isWatchAppInstalled: \(session.isWatchAppInstalled)")
            
            // Automatically send workout data when session activates
            if activationState == .activated && session.isWatchAppInstalled {
                Task {
                    await self.fetchAndSendWorkoutDays()
                }
            }
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("WCSession became inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("WCSession deactivated")
        // Reactivate for switching watches
        session.activate()
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
            print("WCSession reachability changed: \(session.isReachable)")
        }
        
        // Automatically sync when watch becomes reachable
        if session.isReachable {
            Task {
                await self.fetchAndSendWorkoutDays()
            }
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
        case "requestWorkoutDays":
            // Watch is requesting workout days - fetch and send them
            Task {
                await self.fetchAndSendWorkoutDays()
            }
            
        case "completedWorkout":
            // Workout completed on watch - process and save
            if let workoutData = message["workout"] as? [String: Any] {
                DispatchQueue.main.async {
                    self.onWorkoutReceived?(workoutData)
                }
            }
            
        case "heartRateUpdate":
            // Real-time heart rate from watch during workout
            if let heartRate = message["heartRate"] as? Double {
                NotificationCenter.default.post(
                    name: .watchHeartRateUpdate,
                    object: nil,
                    userInfo: ["heartRate": heartRate]
                )
            }
            
        case "workoutStarted":
            // Watch started a workout
            NotificationCenter.default.post(
                name: .watchWorkoutStarted,
                object: nil,
                userInfo: message
            )
            
        case "workoutEnded":
            // Watch ended a workout
            NotificationCenter.default.post(
                name: .watchWorkoutEnded,
                object: nil,
                userInfo: message
            )
            
        default:
            print("Unknown message type: \(type)")
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let watchHeartRateUpdate = Notification.Name("watchHeartRateUpdate")
    static let watchWorkoutStarted = Notification.Name("watchWorkoutStarted")
    static let watchWorkoutEnded = Notification.Name("watchWorkoutEnded")
}

// MARK: - Transfer Models

/// Simplified workout day for transfer to watch
struct WorkoutDayTransfer: Codable {
    let id: UUID
    let name: String
    let dayNumber: Int
    let colorHex: String
    let exercises: [ExerciseTransfer]
    
    init(from workoutDay: WorkoutDay) {
        self.id = workoutDay.id
        self.name = workoutDay.name
        self.dayNumber = workoutDay.dayNumber
        self.colorHex = workoutDay.colorHex
        self.exercises = workoutDay.exercises.map { ExerciseTransfer(from: $0) }
    }
}

/// Simplified exercise for transfer to watch
struct ExerciseTransfer: Codable {
    let id: UUID
    let name: String
    let defaultSets: Int
    let defaultReps: String
    let muscleGroup: String
    
    init(from exercise: Exercise) {
        self.id = exercise.id
        self.name = exercise.name
        self.defaultSets = exercise.defaultSets
        self.defaultReps = exercise.defaultReps
        self.muscleGroup = exercise.muscleGroup
    }
}

/// Completed workout from watch
struct WatchWorkoutTransfer: Codable {
    let workoutDayId: UUID
    let workoutDayName: String
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval
    let exerciseLogs: [WatchExerciseLogTransfer]
    let averageHeartRate: Double?
    let maxHeartRate: Double?
    let activeCalories: Double?
}

/// Exercise log from watch
struct WatchExerciseLogTransfer: Codable {
    let exerciseId: UUID
    let exerciseName: String
    let order: Int
    let sets: [WatchSetLogTransfer]
}

/// Set log from watch
struct WatchSetLogTransfer: Codable {
    let setNumber: Int
    let targetReps: String
    let actualReps: Int?
    let weight: Double?
    let weightUnit: String
    let isCompleted: Bool
}

