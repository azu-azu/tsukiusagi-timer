import UserNotifications

public final class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("通知の許可リクエストでエラーが発生しました: \(error.localizedDescription)")
                completion(false)
                return
            }
            completion(granted)
        }
    }

    func checkNotificationStatus(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus == .authorized)
            }
        }
    }

    func sendPhaseChangeNotification(for phase: PomodoroPhase) {
        checkNotificationStatus { isAuthorized in
            guard isAuthorized else {
                print("通知が許可されていません")
                return
            }

            let content = UNMutableNotificationContent()
            content.title = (phase == .focus) ? "Break Time!" : "Focus Again!"
            content.body = (phase == .focus) ? "おつかれさま。少し休憩しよか ☕️" : "そろそろ集中モードにもどろか 🌕"
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("通知の送信に失敗しました: \(error.localizedDescription)")
                } else {
                    print("通知を送信しました")
                }
            }
        }
    }
}