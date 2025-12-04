import ActivityKit
import Foundation

class WorkoutActivityManager {
    static let shared = WorkoutActivityManager()
    
    private var activity: Activity<WorkoutActivityAttributes>?
    private var startTime: Date?
    
    // Current state tracking
    private var currentExerciseName: String?
    private var isPaused: Bool = false
    private var completedSets: Int = 0
    private var totalSets: Int = 0
    private var exerciseCount: Int = 0
    
    // Rest timer state
    private var restEndTime: Date?
    private var restTotalDuration: TimeInterval?
    private var restAfterSetNumber: Int?
    
    private init() {}
    
    func start(workoutName: String, workoutColor: String, exerciseCount: Int, totalSets: Int, currentExerciseName: String? = nil) {
        self.exerciseCount = exerciseCount
        self.totalSets = totalSets
        self.currentExerciseName = currentExerciseName
        self.completedSets = 0
        self.isPaused = false
        self.restEndTime = nil
        
        Task.detached { [weak self] in
            await self?.startActivity(
                workoutName: workoutName,
                workoutColor: workoutColor,
                exerciseCount: exerciseCount,
                totalSets: totalSets,
                currentExerciseName: currentExerciseName
            )
        }
    }
    
    @MainActor
    private func startActivity(workoutName: String, workoutColor: String, exerciseCount: Int, totalSets: Int, currentExerciseName: String?) async {
        print("🏋️ WorkoutActivityManager: Starting unified workout activity...")
        
        // End any existing activity first
        if let existingActivity = activity {
            await existingActivity.end(nil, dismissalPolicy: .immediate)
            self.activity = nil
            self.startTime = nil
        }

        // End orphaned activities
        for activity in Activity<WorkoutActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        
        let authInfo = ActivityAuthorizationInfo()
        guard authInfo.areActivitiesEnabled else {
            print("🔴 WorkoutActivityManager: Activities are NOT enabled!")
            return
        }
        
        let attributes = WorkoutActivityAttributes(
            workoutName: workoutName,
            workoutColor: workoutColor
        )
        
        self.startTime = Date()
        let contentState = WorkoutActivityAttributes.ContentState(
            startTime: self.startTime!,
            exerciseCount: exerciseCount,
            completedSets: 0,
            totalSets: totalSets,
            currentExerciseName: currentExerciseName,
            isPaused: false,
            restEndTime: nil,
            restTotalDuration: nil,
            restAfterSetNumber: nil
        )
        
        do {
            let newActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil),
                pushType: nil
            )
            self.activity = newActivity
            print("🏋️ WorkoutActivityManager: ✅ SUCCESS! Activity ID: \(newActivity.id)")
        } catch {
            print("🔴 WorkoutActivityManager: Error: \(error)")
        }
    }
    
    func update(completedSets: Int, totalSets: Int, exerciseCount: Int, currentExerciseName: String? = nil, isPaused: Bool = false) {
        self.completedSets = completedSets
        self.totalSets = totalSets
        self.exerciseCount = exerciseCount
        self.currentExerciseName = currentExerciseName
        self.isPaused = isPaused
        
        pushUpdate()
    }
    
    // MARK: - Rest Timer Integration
    
    func startRestTimer(endTime: Date, totalDuration: TimeInterval, afterSetNumber: Int, exerciseName: String) {
        self.restEndTime = endTime
        self.restTotalDuration = totalDuration
        self.restAfterSetNumber = afterSetNumber
        self.currentExerciseName = exerciseName
        
        pushUpdate()
    }
    
    func stopRestTimer() {
        self.restEndTime = nil
        self.restTotalDuration = nil
        self.restAfterSetNumber = nil
        
        pushUpdate()
    }
    
    private func pushUpdate() {
        guard let activity = activity, let startTime = startTime else { return }
        
        Task {
            let contentState = WorkoutActivityAttributes.ContentState(
                startTime: startTime,
                exerciseCount: exerciseCount,
                completedSets: completedSets,
                totalSets: totalSets,
                currentExerciseName: currentExerciseName,
                isPaused: isPaused,
                restEndTime: restEndTime,
                restTotalDuration: restTotalDuration,
                restAfterSetNumber: restAfterSetNumber
            )
            await activity.update(
                ActivityContent(state: contentState, staleDate: nil)
            )
        }
    }
    
    func end() {
        guard let activity = activity else { return }
        
        Task {
            let contentState = activity.content.state
            await activity.end(
                ActivityContent(state: contentState, staleDate: nil),
                dismissalPolicy: .immediate
            )
            await MainActor.run {
                self.activity = nil
                self.startTime = nil
                self.restEndTime = nil
            }
        }
    }
}
