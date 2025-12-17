import Foundation
import UserNotifications
import UIKit
#if DEBUG
import os
#endif

protocol PhaseNotificationServiceable: AnyObject {
    func sendStartNotification()
    func cancelSessionEnd(for phase: PomodoroPhase)
    func scheduleSessionEndNotification(after seconds: Int, phase: PomodoroPhase)
    func scheduleSessionEndNotification(at endAt: Date, phase: PomodoroPhase, timeSensitive: Bool)
    func rescheduleEnd(at endAt: Date, phase: PomodoroPhase, timeSensitive: Bool)
    // 連鎖（2本）予約: Work終了とBreak終了（=次Focus）を同時に張る
    func scheduleChainedSessionEnds(workEndAt: Date, breakEndAt: Date, timeSensitive: Bool)
    // 冪等Focus予約: Break終了時刻に対してFocusのみを再予約
    func ensureFocusAt(breakEndAt: Date, timeSensitive: Bool)
    func sendPhaseChangeNotification(for phase: PomodoroPhase)
    func cancelSessionEndAll()
    func cancelSessionEndSafely(for completedPhase: PomodoroPhase)
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
        // 開始時のpushは不要なため送信しない（仕様）
    }

    func cancelSessionEnd(for phase: PomodoroPhase) {
        notificationManager.removePending(for: phase)
    }

    /// 連鎖の2本（break+focus）が同時にpendingのときは何も消さない
    func cancelSessionEndSafely(for completedPhase: PomodoroPhase) {
        Task {
            let center = UNUserNotificationCenter.current()
            let pending = await center.pendingNotificationRequests()
            let countSessionEnd = pending.filter { $0.identifier.hasPrefix("SessionEnd.") }.count
            if countSessionEnd >= 2 {
                return
            }
            notificationManager.removePending(for: completedPhase)
        }
    }

    func scheduleSessionEndNotification(after seconds: Int, phase: PomodoroPhase) {
        // 予約の衝突を防ぐため、これから張るフェーズのみを取消
        // debug log removed
        notificationManager.removePending(for: phase)
        // バックグラウンド時の終了時刻通知をスケジューリング（後方互換性）
        notificationManager.scheduleSessionEndNotification(after: seconds, phase: phase)
    }

    func scheduleSessionEndNotification(at endAt: Date, phase: PomodoroPhase, timeSensitive: Bool) {
        // 予約の衝突を防ぐため、これから張るフェーズのみを取消
        // debug log removed
        notificationManager.removePending(for: phase)
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
            notificationManager.removePending(for: phase)
            if phase == .breakTime,
               UIApplication.shared.applicationState == .active {
                notificationManager.clearLastDelivered(for: .breakTime)
            }
            notificationManager.scheduleSessionEndNotification(at: endAt, phase: phase, timeSensitive: timeSensitive)
        }
    }

    // MARK: - Chained / Idempotent APIs

    func scheduleChainedSessionEnds(workEndAt: Date, breakEndAt: Date, timeSensitive: Bool) {
        // 初回にprefix掃除→掃除なしで2本を順次予約
        notificationManager.scheduleChainedSessionEnds(
            workEndAt: workEndAt,
            breakEndAt: breakEndAt,
            timeSensitive: timeSensitive
        )
    }

    func ensureFocusAt(breakEndAt: Date, timeSensitive: Bool) {
        notificationManager.scheduleFocusAfterClearingPending(at: breakEndAt, timeSensitive: timeSensitive)
    }

    func sendPhaseChangeNotification(for phase: PomodoroPhase) {
        // フェーズ切り替え通知を即座に送信
        notificationManager.sendPhaseChangeNotification(for: phase)
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

    /// 通知権限を確認し、必要に応じて要求する（timeSensitive 含む統一フロー）
    func ensureAuthorizationIfNeeded(completion: @escaping (Bool) -> Void) {
        Task {
            let ok = await NotificationPermissionManager.shared.ensureUnifiedAuthorization(openSettingsIfNeeded: true)
            completion(ok)
        }
    }

    func cancelSessionEndAll() {
        notificationManager.cancelSessionEndAll()
    }
}

// debug helpers removed
