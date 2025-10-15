import UIKit
import UserNotifications
#if DEBUG
import os
#endif

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        migrateSubtitleLabelIfNeeded()
        return true
    }

    // This function will be called when the app is in the foreground
    func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // 提示直前は「前フェーズ delivered のみ」を整理（同フェーズはスケジュール時に整理済み）
        NotificationManager.shared.clearPreviousPhaseDeliveredOnly(forIncoming: notification.request.identifier)
        // Display the notification as a banner and play a sound (also list + badge)
        completionHandler([.banner, .list, .sound, .badge])
    }

    // This function will be called when the user taps on a notification or notification action
    func userNotificationCenter(
        _: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Handle notification action
        if response.actionIdentifier == "OPEN_TIMER" {
            // Deep Link: タイマー画面に遷移
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenTimerFromNotification"),
                object: nil
            )
        }

        // debug log removed
        completionHandler()
    }
}

// debug helpers removed

// MARK: - One-time Migration (subtitleLabel -> taskLabel)
private func migrateSubtitleLabelIfNeeded() {
    let defaults = UserDefaults.standard
    let currentTask = defaults.string(forKey: "taskLabel") ?? ""
    if currentTask.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
       let legacy = defaults.string(forKey: "subtitleLabel"),
       !legacy.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        defaults.set(legacy, forKey: "taskLabel")
        // Keep legacy one more version; removal handled in a later cleanup
    }
}
