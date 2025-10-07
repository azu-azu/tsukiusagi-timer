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
        return true
    }

    // This function will be called when the app is in the foreground
    func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // 提示直前に、前フェーズ delivered を整頓
        NotificationManager.shared.clearPreviousPhaseDeliveredForIncoming(identifier: notification.request.identifier)
        // Display the notification as a banner and play a sound (also list + badge)
#if DEBUG
        if #available(iOS 14.0, *) {
            let logger = Logger(subsystem: "jp.tsukiusagi.timer", category: "notification")
            logger.info("🌙TSK \(Self.isoNow(), privacy: .public) FG willPresent WILL-PRESENT {}")
        } else {
            print("🌙TSK \(Self.isoNow()) FG willPresent WILL-PRESENT {}")
        }
#endif
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

#if DEBUG
        if #available(iOS 14.0, *) {
            let logger = Logger(subsystem: "jp.tsukiusagi.timer", category: "notification")
            let state: String
            switch UIApplication.shared.applicationState {
            case .active: state = "FG"
            case .background: state = "BG"
            case .inactive: state = "IN"
            @unknown default: state = "UK"
            }
            let id = response.notification.request.identifier
            let action = response.actionIdentifier
            logger.info("🌙TSK \(Self.isoNow(), privacy: .public) \(state, privacy: .public) didReceive DID-RECEIVE {id:\(id, privacy: .public), action:\(action, privacy: .public)}")
        } else {
            print("🌙TSK \(Self.isoNow()) didReceive DID-RECEIVE {}")
        }
#endif
        completionHandler()
    }
}

#if DEBUG
extension AppDelegate {
    fileprivate static func isoNow() -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.string(from: Date())
    }
}
#endif
