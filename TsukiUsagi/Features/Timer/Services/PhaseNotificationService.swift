import Foundation
import UserNotifications
#if DEBUG
import os
import UIKit
#endif

protocol PhaseNotificationServiceable: AnyObject {
    func sendStartNotification()
    func cancelNotification()
    func scheduleSessionEndNotification(after seconds: Int, phase: PomodoroPhase)
    func scheduleSessionEndNotification(at endAt: Date, phase: PomodoroPhase, timeSensitive: Bool)
    func rescheduleEnd(at endAt: Date, phase: PomodoroPhase, timeSensitive: Bool)
    func sendPhaseChangeNotification(for phase: PomodoroPhase)
    func cancelSessionEndNotification()
    func finalizeWorkPhase()
    func finalizeBreakPhase()

    // 権限管理
    func ensureAuthorizationIfNeeded(completion: @escaping (Bool) -> Void)
}

final class PhaseNotificationService: PhaseNotificationServiceable {
    private let hapticService: HapticServiceable
    private let notificationManager: NotificationManager

    // 競合対策：最新のリスケジュールタスクを管理
    private var latestRescheduleWork: Task<Void, Never>?

    init(hapticService: HapticServiceable) {
        self.hapticService = hapticService
        self.notificationManager = NotificationManager.shared
    }

    func sendStartNotification() {
        hapticService.heavyImpact()
        // 開始時の通知は無効化（ユーザーリクエストにより不要）
        // notificationManager.sendPhaseChangeNotification(for: .focus)
    }

    func cancelNotification() {
        // 全ての通知をキャンセル
        notificationManager.cancelSessionEndNotification()
    }

    func scheduleSessionEndNotification(after seconds: Int, phase: PomodoroPhase) {
        // 予約の衝突を防ぐため、これから張るIDの pending のみを取消
        // debug log removed
        let id = notificationManager.id(for: phase)
        notificationManager.cancelSessionEndNotifications(ids: [id], removeDelivered: false, removePending: true)
        // バックグラウンド時の終了時刻通知をスケジューリング（後方互換性）
        notificationManager.scheduleSessionEndNotification(after: seconds, phase: phase)
    }

    func scheduleSessionEndNotification(at endAt: Date, phase: PomodoroPhase, timeSensitive: Bool) {
        // 予約の衝突を防ぐため、これから張るIDの pending のみを取消
        // debug log removed
        let focusId = notificationManager.id(for: .focus)
        let breakId = notificationManager.id(for: .breakTime)
        // まず全フェーズの pending を整理（過去予約の取りこぼし防止）
        notificationManager.cancelSessionEndNotifications(
            ids: [focusId, breakId],
            removeDelivered: false,
            removePending: true
        )
        // FG での再START時、同フェーズの古い delivered が残っていると抑制される場合があるため整理
        if phase == .breakTime, UIApplication.shared.applicationState == .active {
            notificationManager.clearLastDelivered(for: .breakTime)
        }
        // 絶対時刻での通知スケジューリング
        notificationManager.scheduleSessionEndNotification(at: endAt, phase: phase, timeSensitive: timeSensitive)
    }

    func rescheduleEnd(at endAt: Date, phase: PomodoroPhase, timeSensitive: Bool) {
        // 競合対策：既存のリスケジュールタスクをキャンセル
        latestRescheduleWork?.cancel()

        // 最新のリスケジュールタスクを開始
        latestRescheduleWork = Task { @MainActor in
            // 300ms debounce
            try? await Task.sleep(nanoseconds: 300_000_000)

            // キャンセルしてから再スケジュール
            // debug log removed
            let focusId = notificationManager.id(for: .focus)
            let breakId = notificationManager.id(for: .breakTime)
            notificationManager.cancelSessionEndNotifications(
                ids: [focusId, breakId],
                removeDelivered: false,
                removePending: true
            )
            if phase == .breakTime,
               UIApplication.shared.applicationState == .active
            {
                notificationManager.clearLastDelivered(for: .breakTime)
            }
            notificationManager.scheduleSessionEndNotification(at: endAt, phase: phase, timeSensitive: timeSensitive)
        }
    }

    func sendPhaseChangeNotification(for phase: PomodoroPhase) {
        // フェーズ切り替え通知を即座に送信
        notificationManager.sendPhaseChangeNotification(for: phase)
    }

    func cancelSessionEndNotification() {
        // セッション終了通知をキャンセル（既定: pending のみ）
        // debug log removed
        notificationManager.cancelSessionEndNotifications()
    }

    func finalizeWorkPhase() {
        hapticService.heavyImpact()
        sendPhaseChangeNotification(for: .breakTime)
    }

    func finalizeBreakPhase() {
        hapticService.heavyImpact()
        sendPhaseChangeNotification(for: .focus)
    }

    // MARK: - Authorization Management

    /// 通知権限を確認し、必要に応じて要求する
    func ensureAuthorizationIfNeeded(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional:
                completion(true)
            case .denied:
                completion(false)
            case .notDetermined:
                // 初回権限要求
                UNUserNotificationCenter.current().requestAuthorization(
                    options: [.alert, .sound, .badge]
                ) { granted, error in
                    if let error = error {
                        #if DEBUG
                        print("🔔 通知許可リクエストでエラー: \(error.localizedDescription)")
                        #endif
                        completion(false)
                    } else {
                        #if DEBUG
                        print("🔔 通知許可: \(granted ? "承認" : "拒否")")
                        #endif
                        completion(granted)
                    }
                }
            case .ephemeral:
                // 一時的な許可（App Clip等）は有効として扱う
                completion(true)
            @unknown default:
                completion(false)
            }
        }
    }
}

// debug helpers removed
