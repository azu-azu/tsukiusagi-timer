//
//  TimerViewModel+SessionControl.swift
//  TsukiUsagi
//
//  Extracted session control APIs to reduce TimerViewModel size.
//

import Foundation
import Combine

@MainActor
extension TimerViewModel {

    /// タイマー開始
    func startTimer() {
        // quiet moon画面からのstart時は、時間を設定してから開始
        let targetTime = isSessionFinished ? workLengthMinutes * 60 : timeRemaining

        guard targetTime > 0 else { return }

        ensureWorkOnStart()

        sessionManager.startSession(
            isWorkSession: isWorkSession,
            activityLabel: activityLabel,
            subtitleLabel: subtitleLabel
        )

        // 時間を設定してからstartTimerを呼ぶ
        stateManager.timeRemaining = targetTime
        // セッション完了状態をリセット
        if isSessionFinished {
            stateManager.resetSessionFinished() // セッション完了状態をリセット
            isBackgroundCompleted = false // バックグラウンド完了フラグをリセット
        }
        stateManager.startTimer()
        animationController.triggerStartAnimations()
        notificationAndHapticManager.sendStartNotification()

        // バックグラウンド時の通知をスケジューリング（即座通知で代用するため無効化）
        let endAt = dateProvider.now().addingTimeInterval(TimeInterval(targetTime))
        sessionManager.setEndAt(endAt)
        // 次のセッションの種類に基づいて通知フェーズを決定
        let phase: PomodoroPhase = isWorkSession ? .breakTime : .focus
        // ★ 開始時にのみ次フェーズを予約（cancel→addはサービス側で実施）
        notificationService.scheduleSessionEndNotification(
            at: endAt,
            phase: phase,
            timeSensitive: true
        )

        // Send start pulse
        startPulse.send()
    }

    /// タイマー一時停止
    func pauseTimer() {
        stateManager.pauseTimer()
        notificationAndHapticManager.triggerLightHaptic()
        // 通知をキャンセル（一時停止中は通知不要）
        notificationService.cancelSessionEndNotification()
    }

    /// タイマー再開
    func resumeTimer() {
        // 再開時はフェーズを強制変更しない（休憩再開を潰さない）
        stateManager.resumeTimer()
        animationController.triggerStartAnimations()
        notificationAndHapticManager.sendStartNotification()

        // 再開時に通知をリスケジューリング
        if timeRemaining > 0 {
            let endAt = dateProvider.now().addingTimeInterval(TimeInterval(timeRemaining))
            sessionManager.setEndAt(endAt)
            // 次のセッションの種類に基づいて通知フェーズを決定
            let phase: PomodoroPhase = isWorkSession ? .breakTime : .focus
            notificationService.rescheduleEnd(
                at: endAt,
                phase: phase,
                timeSensitive: true
            )
        }
    }

    /// タイマー停止（完全停止 - セッションリセット）
    func stopTimer() {
        stateManager.stopTimer()
        sessionManager.resetSession()
        notificationService.cancelSessionEndNotification()
    }

    /// タイマーリセット
    func resetTimer(to seconds: Int) {
        resetTimer(to: seconds, keepSession: false)
    }

    /// タイマーリセット（セッション保持の有無を選択）
    func resetTimer(to seconds: Int, keepSession: Bool) {
        stateManager.resetTimer(to: seconds)
        if keepSession {
            // セッション情報は保持
        } else {
            sessionManager.resetSession()
        }
        animationController.resetAnimationState()
        notificationService.cancelSessionEndNotification()
    }

    /// セッション完了処理
    func handleSessionCompleted(_ sessionInfo: TimerSessionInfo) {
        sessionManager.completeSession(
            isWorkSession: isWorkSession,
            activityLabel: activityLabel,
            subtitleLabel: subtitleLabel
        )

        stateManager.handleSessionCompleted(sessionInfo)
        animationController.triggerSessionFinishedAnimations()
        notificationAndHapticManager.triggerHeavyHaptic()

        // ペンディング予約の重複を避けるためキャンセル
        notificationService.cancelSessionEndNotification()

        // 即時通知は送らない（開始時に予約済みのため、完了時は重複を避ける）

        // ★ Work完了直後に、Break終了（= 次のFocus）を絶対時刻で予約
        if isWorkSession {
            let breakEndAt = dateProvider.now().addingTimeInterval(TimeInterval(breakMinutes * 60))
            notificationService.scheduleSessionEndNotification(
                at: breakEndAt,
                phase: .focus,
                timeSensitive: true
            )
        }

        // それからフェーズをトグル
        if isWorkSession {
            stateManager.setWorkSession(false) // Work → Break
        } else {
            stateManager.setWorkSession(true)  // Break → Work
        }
    }

    /// 強制終了
    func forceFinish() {
        guard canForceFinish else { return }

        sessionManager.completeSession(
            isWorkSession: isWorkSession,
            activityLabel: activityLabel,
            subtitleLabel: subtitleLabel
        )

        stateManager.stopTimer()
        stateManager.setSessionFinished(true) // セッション完了状態を設定
        stateManager.setWorkSession(false) // 作業セッションを終了
        animationController.triggerSessionFinishedAnimations()
        notificationAndHapticManager.triggerHeavyHaptic()

        // スケジュール済みの通知をキャンセル
        notificationService.cancelSessionEndNotification()
    }

    /// セッション完了状態をリセット
    func resetSessionFinished() {
        stateManager.resetSessionFinished()
    }

    /// 終了時刻を設定
    func setEndTime(_ endTime: Date?) {
        sessionManager.setEndAt(endTime)
    }

    /// 時間表示文字列を取得
    func formatTime(_ seconds: Int) -> String {
        return displayManager.timeDisplayString(for: seconds)
    }

    // MARK: - Private Helpers
    /// Start時にWorkへ強制統一（Break完了残留を潰す）
    private func ensureWorkOnStart() {
        if isSessionFinished || !isWorkSession {
            stateManager.setWorkSession(true)
        }
    }
}


