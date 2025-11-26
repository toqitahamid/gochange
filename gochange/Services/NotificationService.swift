import Foundation
import UserNotifications
import SwiftUI
import Combine

/// Service for managing local notifications
class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    @Published var isAuthorized = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    private let center = UNUserNotificationCenter.current()
    
    private init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func checkAuthorizationStatus() {
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                self.isAuthorized = granted
                self.authorizationStatus = granted ? .authorized : .denied
            }
            return granted
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }
    
    // MARK: - Rest Timer Notification
    
    func scheduleRestTimerNotification(endTime: Date) {
        guard isAuthorized else { return }
        
        // Cancel any existing rest timer notifications
        center.removePendingNotificationRequests(withIdentifiers: ["rest-timer"])
        
        let content = UNMutableNotificationContent()
        content.title = "Rest Complete"
        content.body = "Time to start your next set!"
        content.sound = .default
        content.categoryIdentifier = "REST_TIMER"
        
        let timeInterval = endTime.timeIntervalSinceNow
        guard timeInterval > 0 else { return }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: "rest-timer", content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule rest timer notification: \(error)")
            }
        }
    }
    
    func cancelRestTimerNotification() {
        center.removePendingNotificationRequests(withIdentifiers: ["rest-timer"])
    }
    
    // MARK: - Workout Reminders
    
    func scheduleWorkoutReminder(weekday: Int, hour: Int, minute: Int, workoutName: String) {
        guard isAuthorized else { return }
        
        let identifier = "workout-reminder-\(weekday)"
        
        // Cancel existing reminder for this day
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        
        let content = UNMutableNotificationContent()
        content.title = "Time to Workout!"
        content.body = "It's \(workoutName) day. Let's crush it! 💪"
        content.sound = .default
        content.categoryIdentifier = "WORKOUT_REMINDER"
        
        var dateComponents = DateComponents()
        dateComponents.weekday = weekday  // 1 = Sunday, 2 = Monday, etc.
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule workout reminder: \(error)")
            }
        }
    }
    
    func cancelWorkoutReminder(weekday: Int) {
        let identifier = "workout-reminder-\(weekday)"
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    func cancelAllWorkoutReminders() {
        let identifiers = (1...7).map { "workout-reminder-\($0)" }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    // MARK: - Get Scheduled Reminders
    
    func getScheduledReminders() async -> [Int: (hour: Int, minute: Int)] {
        let requests = await center.pendingNotificationRequests()
        var reminders: [Int: (hour: Int, minute: Int)] = [:]
        
        for request in requests {
            if request.identifier.hasPrefix("workout-reminder-"),
               let trigger = request.trigger as? UNCalendarNotificationTrigger,
               let weekday = trigger.dateComponents.weekday,
               let hour = trigger.dateComponents.hour,
               let minute = trigger.dateComponents.minute {
                reminders[weekday] = (hour, minute)
            }
        }
        
        return reminders
    }
}

// MARK: - Workout Reminder Data
struct WorkoutReminderSchedule: Identifiable, Codable {
    var id: Int { weekday }
    let weekday: Int
    var isEnabled: Bool
    var hour: Int
    var minute: Int
    var workoutName: String
    
    var weekdayName: String {
        let formatter = DateFormatter()
        formatter.weekdaySymbols = Calendar.current.weekdaySymbols
        return formatter.weekdaySymbols[weekday - 1]
    }
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(hour):\(String(format: "%02d", minute))"
    }
}

