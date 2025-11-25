import ActivityKit
import Foundation

class WorkoutActivityManager {
    static let shared = WorkoutActivityManager()
    
    private var activity: Activity<WorkoutActivityAttributes>?
    private var startTime: Date?
    
    private init() {}
    
    func start(workoutName: String, workoutColor: String, exerciseCount: Int, totalSets: Int) {
        // Run in a detached task to avoid blocking UI
        Task.detached { [weak self] in
            await self?.startActivity(
                workoutName: workoutName,
                workoutColor: workoutColor,
                exerciseCount: exerciseCount,
                totalSets: totalSets
            )
        }
    }
    
    @MainActor
    private func startActivity(workoutName: String, workoutColor: String, exerciseCount: Int, totalSets: Int) async {
        print("🏋️ WorkoutActivityManager: Starting workout activity...")
        
        // End any existing activity first and WAIT for it to complete
        if let existingActivity = activity {
            print("🏋️ WorkoutActivityManager: Ending existing activity first...")
            let contentState = existingActivity.content.state
            await existingActivity.end(
                ActivityContent(state: contentState, staleDate: nil),
                dismissalPolicy: .immediate
            )
            self.activity = nil
            self.startTime = nil
        }
        
        // Also end any orphaned activities from previous app runs
        for activity in Activity<WorkoutActivityAttributes>.activities {
            let contentState = activity.content.state
            await activity.end(
                ActivityContent(state: contentState, staleDate: nil),
                dismissalPolicy: .immediate
            )
        }
        
        let authInfo = ActivityAuthorizationInfo()
        print("🏋️ WorkoutActivityManager: Activities Enabled: \(authInfo.areActivitiesEnabled)")
        
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
            totalSets: totalSets
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
    
    func update(completedSets: Int, totalSets: Int, exerciseCount: Int) {
        guard let activity = activity, let startTime = startTime else { return }
        
        Task {
            let contentState = WorkoutActivityAttributes.ContentState(
                startTime: startTime,
                exerciseCount: exerciseCount,
                completedSets: completedSets,
                totalSets: totalSets
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
            }
        }
    }
    
}
