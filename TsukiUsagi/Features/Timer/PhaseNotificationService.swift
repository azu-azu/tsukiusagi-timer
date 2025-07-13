import Foundation

protocol PhaseNotificationServiceable: AnyObject {
    func sendStartNotification()
    func cancelNotification()
    func scheduleSessionEndNotification(after seconds: Int, phase: PomodoroPhase)
    func sendPhaseChangeNotification(for phase: PomodoroPhase)
    func cancelSessionEndNotification()
    func finalizeWorkPhase()
    func finalizeBreakPhase()
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

    func sendPhaseChangeNotification(for phase: PomodoroPhase) {
        // フェーズ切り替え通知ロジック
    }

    func cancelSessionEndNotification() {
        // セッション終了通知キャンセルロジック
    }

    func finalizeWorkPhase() {
        hapticService.heavyImpact()
        sendPhaseChangeNotification(for: .breakTime)
    }

    func finalizeBreakPhase() {
        hapticService.heavyImpact()
        sendPhaseChangeNotification(for: .focus)
    }
}
