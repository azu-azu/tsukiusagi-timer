//
//  TimerViewModel+SessionControl.swift
//  TsukiUsagi
//
//  Extracted session control APIs to reduce TimerViewModel size.
//

import Foundation
import UIKit

@MainActor
extension TimerViewModel {

    /// タイマー開始
    func startTimer() async {
        await startTimerFromAnyState()
    }

    /// タイマー一時停止
    func pauseTimer() async {
        stateManager.pauseTimer()
        notificationAndHapticManager.triggerLightHaptic()
        // 通知をキャンセル（一時停止中は直近フェーズのみを取り消す）
        // debug log removed
        let phaseToCancel: PomodoroPhase = isWorkSession ? .breakTime : .focus
        notificationService.cancelSessionEnd(for: phaseToCancel)

        // Live Activity更新（一時停止状態を反映）
        if let endAt = sessionManager.endAt {
            let remaining = timeRemaining // 現在の残り秒をスナップショット
            await LiveActivityManager.shared.updateActivity(
                isPaused: true,
                newEndsAt: endAt,
                remainingSeconds: remaining
            )
        }
    }

    /// タイマー再開
    func resumeTimer() async {
        // 再開時はフェーズを強制変更しない（休憩再開を潰さない）
        stateManager.resumeTimer()
        animationController.triggerStartAnimations()
        notificationAndHapticManager.sendStartNotification()

        // 再開時に通知をリスケジューリング
        if timeRemaining > 0 {
            let endAt = dateProvider.now().addingTimeInterval(TimeInterval(timeRemaining))
            sessionManager.setEndAt(endAt)

            // Live Activity更新（再開状態を反映）
            await LiveActivityManager.shared.updateActivity(
                isPaused: false,
                newEndsAt: endAt
            )

            // 現在のフェーズに応じて“次に鳴る1本だけ”を再スケジュール（BG優先度適用）
            if isWorkSession {
                // Work中は break のみを張る（break発火時に次FocusはensureFocusAtで張る）
                let isBG = UIApplication.shared.applicationState != .active
                notificationService.scheduleSessionEndNotification(
                    at: endAt,
                    phase: .breakTime,
                    timeSensitive: isBG ? false : true
                )
            } else {
                // Break中開始（稀）: Focusのみ冪等予約
                let isBG = UIApplication.shared.applicationState != .active
                notificationService.ensureFocusAt(
                    breakEndAt: endAt,
                    timeSensitive: isBG ? true : true
                )
            }
        }
    }

    /// タイマー停止（完全停止 - セッションリセット）
    func stopTimer() async {
        // debug log removed
        stateManager.stopTimer()
        sessionManager.resetSession()
        // フェーズごとにキャンセル（グローバルCancelを避ける）
        notificationService.cancelSessionEnd(for: .focus)
        notificationService.cancelSessionEnd(for: .breakTime)
        clearQuietMoonMessage()

        // Live Activity終了
        await LiveActivityManager.shared.endActivity()
    }

    /// タイマーリセット
    func resetTimer(to seconds: Int) async {
        await resetTimer(to: seconds, keepSession: false)
    }

    /// タイマーリセット（セッション保持の有無を選択）
    func resetTimer(to seconds: Int, keepSession: Bool) async {
        // debug log removed
        stateManager.resetTimer(to: seconds)
        if keepSession {
            // セッション情報は保持
        } else {
            sessionManager.resetSession()
            clearQuietMoonMessage()
        }
        animationController.resetAnimationState()
        // フェーズごとにキャンセル（グローバルCancelを避ける）
        notificationService.cancelSessionEnd(for: .focus)
        notificationService.cancelSessionEnd(for: .breakTime)

        // Live Activity終了
        await LiveActivityManager.shared.endActivity()
    }

    /// セッション完了処理
    func handleSessionCompleted(_ sessionInfo: TimerSessionInfo) async {
        // debug log removed
        let completedWasWorkSession = isWorkSession
        // 保存のSoT（真実）は endAt/セッション情報の endTime を優先
        sessionManager.handleExpiredSession(
            end: sessionInfo.endTime,
            isWorkSession: isWorkSession,
            activityLabel: activityLabel,
            taskLabel: taskLabel,
            completedSilently: sessionInfo.isSilent
        )

        stateManager.handleSessionCompleted(sessionInfo)
        animationController.triggerSessionFinishedAnimations()
        notificationAndHapticManager.triggerHeavyHaptic()

        // ペンディング予約の重複を避けるためキャンセル
        let completedPhase: PomodoroPhase = completedWasWorkSession ? .focus : .breakTime
        notificationService.cancelSessionEndSafely(for: completedPhase)

        // Live Activity終了
        await LiveActivityManager.shared.endActivity()

        // 即時通知は送らない（開始時に予約済みのため、完了時は重複を避ける）

        // FG冪等: Work完了時に Focusのみを再確認・再予約（BGで既に張られていてもOK）
        if isWorkSession {
            let breakEndAt = dateProvider.now().addingTimeInterval(TimeInterval(breakMinutes * 60))
            notificationService.ensureFocusAt(
                breakEndAt: breakEndAt,
                timeSensitive: true
            )
        }

        updateQuietMoonMessage(forCompletedWorkSession: completedWasWorkSession)

        // それからフェーズをトグル
        if isWorkSession {
            stateManager.setWorkSession(false) // Work → Break
        } else {
            stateManager.setWorkSession(true)  // Break → Work
        }
    }

    /// 強制終了
    func forceFinish() async {
        guard startTime != nil && !isSessionFinished else { return }
        guard canForceFinish else { return }
        // debug log removed

        let completedWasWorkSession = isWorkSession
        sessionManager.completeSession(
            isWorkSession: isWorkSession,
            activityLabel: activityLabel,
            taskLabel: taskLabel
        )

        stateManager.stopTimer()
        stateManager.setSessionFinished(true) // セッション完了状態を設定
        stateManager.setWorkSession(false) // 作業セッションを終了
        animationController.triggerSessionFinishedAnimations()
        notificationAndHapticManager.triggerHeavyHaptic()

        // スケジュール済みの通知をフェーズごとにキャンセル
        notificationService.cancelSessionEnd(for: .focus)
        notificationService.cancelSessionEnd(for: .breakTime)
        updateQuietMoonMessage(forCompletedWorkSession: completedWasWorkSession)

        // Live Activity終了
        await LiveActivityManager.shared.endActivity()
    }

    /// セッション完了状態をリセット
    func resetSessionFinished() {
        stateManager.resetSessionFinished()
    }

    /// 終了時刻を設定（旧API）
    /// - Warning: UI更新用途では使用しないこと。代わりに applyEditedEndTime(_:) を使用
    @available(
        *,
        deprecated,
        message: "Use applyEditedEndTime(_:) for UI updates. This method previously updated endAt only."
    )
    func setEndTime(_ endTime: Date?) {
        if let endTime { applyEditedEndTime(endTime) }
    }

    /// 編集確定後の終了時刻をUIに即時反映（Quiet Moon用のSSOT: endTime を更新）
    func applyEditedEndTime(_ editedEnd: Date) {
        sessionManager.overrideEndTime(editedEnd)
    }

    /// 時間表示文字列を取得
    func formatTime(_ seconds: Int) -> String {
        return displayManager.timeDisplayString(for: seconds)
    }

    /// 完全な状態リセット（Quiet Moon状態からのSTART用）
    func performCompleteStateReset() {
        // 0) UI分岐を速攻で開放
        isSessionFinished = false

        // 1) 旧購読の全破棄
        cancellables.removeAll()

        // 2) エンジン停止・状態クリア
        stateManager.stopTimer()
        stateManager.resetSessionFinished()
        runState = .idle
        endTime = nil

        // 3) 通知の掃除は開始/再開時は行わない（フェーズ粒度の掃除はスケジューラ側で実施）

        // 4) アニメの状態クリア
        animationController.resetAnimationState()

        // 5) 新しいセッション識別子で世界を張る
        sessionId = UUID()

        // 6) セッションマネージャーのリセット
        sessionManager.resetSession()
    }

    /// Quiet Moon状態からの専用開始処理
    func startFromQuietMoon() async {
        performCompleteStateReset()

        // Workセッションとして開始
        ensureWorkOnStart()
        clearQuietMoonMessage()

        sessionManager.startSession(
            isWorkSession: isWorkSession,
            activityLabel: activityLabel,
            taskLabel: taskLabel
        )

        // 時間を設定してからstartTimerを呼ぶ
        stateManager.timeRemaining = workLengthMinutes * 60
        stateManager.startTimer()
        animationController.triggerStartAnimations()
        notificationAndHapticManager.sendStartNotification()

        // 終了時刻を設定し、次フェーズの通知を連鎖で予約
        let endAt = dateProvider.now().addingTimeInterval(TimeInterval(workLengthMinutes * 60))
        sessionManager.setEndAt(endAt)

        // Live Activity開始
        await LiveActivityManager.shared.startActivity(
            sessionKind: activityLabel,
            endsAt: endAt
        )

        // Work→Rest と Rest→Focus を開始時点で個別に予約（BG優先度適用）
        let workEndAt = endAt
        let breakEndAt = workEndAt.addingTimeInterval(TimeInterval(breakMinutes * 60))
        let isBG = UIApplication.shared.applicationState != .active
        // Rest（break）は BG では .active（= timeSensitive: false）
        notificationService.scheduleSessionEndNotification(
            at: workEndAt,
            phase: .breakTime,
            timeSensitive: isBG ? false : true
        )
        // Focus は BG でも timeSensitive: true
        notificationService.scheduleSessionEndNotification(
            at: breakEndAt,
            phase: .focus,
            timeSensitive: true
        )

        // Send start pulse
        startPulse.send()
    }

    /// 状態に応じた分岐処理でタイマー開始（新しいエントリポイント）
    func startTimerFromAnyState() async {
        if isSessionFinished {
            await startFromQuietMoon()
            return
        }
        await startTimerNormalFlow()
    }

    /// 通常のタイマー開始フロー（既存のstartTimer()の内容）
    private func startTimerNormalFlow() async {
        // debug log removed
        // アイドル時は最新のworkMinutesを採用、進行/一時停止中は残り秒数を尊重
        let targetTime: Int = (runState == .idle) ? workLengthMinutes * 60 : timeRemaining

        guard targetTime > 0 else { return }

        ensureWorkOnStart()
        clearQuietMoonMessage()

        sessionManager.startSession(
            isWorkSession: isWorkSession,
            activityLabel: activityLabel,
            taskLabel: taskLabel
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

        // 終了時刻を設定し、次フェーズの通知を連鎖で予約
        let endAt = dateProvider.now().addingTimeInterval(TimeInterval(targetTime))
        sessionManager.setEndAt(endAt)

        // Live Activity開始
        await LiveActivityManager.shared.startActivity(
            sessionKind: activityLabel,
            endsAt: endAt
        )

        // 次のセッションの種類に応じて連鎖/冪等予約
        if isWorkSession {
            // Work→Rest と Rest→Focus を開始時点で個別に予約（BG優先度適用）
            let workEndAt = endAt
            let breakEndAt = workEndAt.addingTimeInterval(TimeInterval(breakMinutes * 60))
            let isBG = UIApplication.shared.applicationState != .active
            notificationService.scheduleSessionEndNotification(
                at: workEndAt,
                phase: .breakTime,
                timeSensitive: isBG ? false : true
            )
            notificationService.scheduleSessionEndNotification(
                at: breakEndAt,
                phase: .focus,
                timeSensitive: true
            )
        } else {
            // Break中開始（稀）: Focusのみ冪等予約
            let isBG = UIApplication.shared.applicationState != .active
            notificationService.ensureFocusAt(
                breakEndAt: endAt,
                timeSensitive: isBG ? true : true
            )
        }
        // Send start pulse
        startPulse.send()
    }

    // MARK: - Private Helpers
    /// Start時にWorkへ強制統一（Break完了残留を潰す）
    private func ensureWorkOnStart() {
        if isSessionFinished || !isWorkSession {
            stateManager.setWorkSession(true)
        }
    }

    private func updateQuietMoonMessage(forCompletedWorkSession completedWorkSession: Bool) {
        if completedWorkSession {
            assignQuietMoonMessageIfNeeded()
        } else {
            clearQuietMoonMessage()
        }
    }
}
