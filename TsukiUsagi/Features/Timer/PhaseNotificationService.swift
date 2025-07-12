import Foundation

protocol PhaseNotificationServiceable: AnyObject {
    func sendStartNotification()
    func cancelNotification()
    func scheduleSessionEndNotification(after seconds: Int, phase: PomodoroPhase)
}

final class PhaseNotificationService: PhaseNotificationServiceable {
    private let hapticService: HapticServiceable
    // NotificationManager等もここで保持

    init(hapticService: HapticServiceable) {
        self.hapticService = hapticService
    }

    func sendStartNotification() {
        hapticService.heavyImpact()
        // 通知送信ロジック
    }

    func cancelNotification() {
        // 通知キャンセルロジック
    }

    func scheduleSessionEndNotification(after seconds: Int, phase: PomodoroPhase) {
        // セッション終了通知スケジューリングロジック
    }
}
