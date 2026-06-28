import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let status = await center.notificationSettings()
        guard status.authorizationStatus == .notDetermined else {
            return status.authorizationStatus == .authorized
        }
        return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    func scheduleMorningReminder(hour: Int, minute: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["morning_diary"])

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let content = UNMutableNotificationContent()
        content.title = "Good morning"
        content.body = "Take 2 minutes to log last night's sleep while it's fresh."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "morning_diary", content: content, trigger: trigger)
        center.add(request)
    }

    func scheduleWindDownReminder(bedHour: Int, bedMinute: Int, minutesBefore: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["wind_down"])

        var totalMinutes = bedHour * 60 + bedMinute - minutesBefore
        if totalMinutes < 0 { totalMinutes += 24 * 60 }
        let reminderHour = totalMinutes / 60
        let reminderMinute = totalMinutes % 60

        var components = DateComponents()
        components.hour = reminderHour
        components.minute = reminderMinute

        let content = UNMutableNotificationContent()
        content.title = "Wind-down time"
        content.body = "Your prescribed bedtime is in \(minutesBefore) minutes. Start your wind-down routine."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "wind_down", content: content, trigger: trigger)
        center.add(request)
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
