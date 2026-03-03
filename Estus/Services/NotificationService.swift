import UserNotifications

enum NotificationService {
    private static let morningID = "estus_morning_reminder"
    private static let eveningID = "estus_evening_reminder"

    // MARK: - Authorization

    @discardableResult
    static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    // MARK: - Scheduling

    static func scheduleNotifications(for profile: UserProfile) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [morningID, eveningID])

        if profile.morningReminderEnabled {
            let content = UNMutableNotificationContent()
            content.title = "Estus"
            content.body = "Time to take your AM supplements!"
            content.sound = .default

            let comps = Calendar.current.dateComponents([.hour, .minute], from: profile.morningReminderTime)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            let request = UNNotificationRequest(identifier: morningID, content: content, trigger: trigger)
            center.add(request)
        }

        if profile.eveningReminderEnabled {
            let content = UNMutableNotificationContent()
            content.title = "Estus"
            content.body = "Time for your PM supplements!"
            content.sound = .default

            let comps = Calendar.current.dateComponents([.hour, .minute], from: profile.eveningReminderTime)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            let request = UNNotificationRequest(identifier: eveningID, content: content, trigger: trigger)
            center.add(request)
        }
    }

    // MARK: - Cancellation

    static func cancelAllNotifications() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [morningID, eveningID])
    }

    // MARK: - Re-verification

    static func verifyAndReschedule(for profile: UserProfile) async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        if settings.authorizationStatus == .authorized {
            scheduleNotifications(for: profile)
        } else {
            cancelAllNotifications()
        }
    }
}
