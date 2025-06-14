import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            if !granted {
                print("通知が許可されていません")
            }
        }
    }

    func sendPhaseChangeNotification(for phase: PomodoroPhase) {
        let content = UNMutableNotificationContent()
        content.title = (phase == .focus) ? "Break Time!" : "Focus Again!"
        content.body = (phase == .focus) ? "おつかれさま。少し休憩しよか ☕️" : "そろそろ集中モードにもどろか 🌕"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }
}