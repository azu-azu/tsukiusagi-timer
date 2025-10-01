import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // This function will be called when the app is in the foreground
    func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent _: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Display the notification as a banner and play a sound
        completionHandler([.banner, .sound])
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

        completionHandler()
    }
}
