import ActivityKit
import Foundation

class RestTimerActivityManager {
    static let shared = RestTimerActivityManager()
    
    private var activity: Activity<RestTimerAttributes>?
    
    private init() {}
    
    func start(endTime: Date) {
        print("🟢 RestTimerActivityManager: Attempting to start activity...")
        print("🟢 RestTimerActivityManager: End time = \(endTime)")
        
        // End any existing activity first
        if activity != nil {
            print("🟢 RestTimerActivityManager: Ending existing activity first...")
            end()
        }
        
        let authInfo = ActivityAuthorizationInfo()
        print("🟢 RestTimerActivityManager: Activities Enabled: \(authInfo.areActivitiesEnabled)")
        print("🟢 RestTimerActivityManager: Frequent Push Enabled: \(authInfo.frequentPushesEnabled)")
        
        guard authInfo.areActivitiesEnabled else {
            print("🔴 RestTimerActivityManager: Activities are NOT enabled!")
            print("🔴 Please check: Settings → Your App → Live Activities")
            return
        }
        
        let attributes = RestTimerAttributes(timerName: "Rest Timer")
        let contentState = RestTimerAttributes.ContentState(endTime: endTime)
        
        do {
            print("🟢 RestTimerActivityManager: Requesting activity...")
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil),
                pushType: nil  // No push updates needed for local timer
            )
            self.activity = activity
            print("🟢 RestTimerActivityManager: ✅ SUCCESS! Activity ID: \(activity.id)")
            print("🟢 RestTimerActivityManager: Activity State: \(activity.activityState)")
        } catch let error as ActivityAuthorizationError {
            print("🔴 RestTimerActivityManager: Authorization Error: \(error)")
        } catch {
            print("🔴 RestTimerActivityManager: Error: \(error)")
            print("🔴 RestTimerActivityManager: Error Type: \(type(of: error))")
        }
    }
    
    func update(endTime: Date) {
        Task {
            let contentState = RestTimerAttributes.ContentState(endTime: endTime)
            await activity?.update(
                ActivityContent(state: contentState, staleDate: nil)
            )
        }
    }
    
    func end() {
        Task {
            let contentState = RestTimerAttributes.ContentState(endTime: Date())
            await activity?.end(
                ActivityContent(state: contentState, staleDate: nil),
                dismissalPolicy: .immediate
            )
            activity = nil
        }
    }
}
