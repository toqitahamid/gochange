import Foundation

protocol NotificationProviding {
    func requestAuthorization() async
    func scheduleRestTimerNotification(endTime: Date)
    func cancelRestTimerNotification()
    func scheduleWorkoutReminder(weekday: Int, hour: Int, minute: Int, workoutName: String)
    func cancelWorkoutReminder(weekday: Int)
}
