import ActivityKit
import Foundation

class RestTimerActivityManager {
    static let shared = RestTimerActivityManager()
    
    private var activity: Activity<RestTimerAttributes>?
    
    private init() {}
    
    func start(endTime: Date) {
        // End any existing activity first
        end()
        
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        let attributes = RestTimerAttributes(timerName: "Rest Timer")
        let contentState = RestTimerAttributes.ContentState(endTime: endTime)
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil)
            )
            self.activity = activity
            print("Requested Rest Timer Live Activity: \(activity.id)")
        } catch {
            print("Error requesting Live Activity: \(error.localizedDescription)")
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
