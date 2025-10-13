//
//  TimerViewModel+SessionControl.swift
//  TsukiUsagi
//
//  Extracted session control APIs to reduce TimerViewModel size.
//

import Foundation

@MainActor
extension TimerViewModel {

    /// タイマー開始
    func startTimer() {
        startTimerFromAnyState()
    }

    /// タイマー一時停止
    func pauseTimer() {
        stateManager.pauseTimer()
        notificationAndHapticManager.triggerLightHaptic()
        // 通知をキャンセル（一時停止中は通知不要）
        // debug log removed
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
            // 現在のフェーズに応じて再スケジュール（連鎖/冪等）
            if isWorkSession {
                let workEndAt = endAt
                let breakEndAt = workEndAt.addingTimeInterval(TimeInterval(breakMinutes * 60))
                notificationService.scheduleChainedSessionEnds(
                    workEndAt: workEndAt,
                    breakEndAt: breakEndAt,
                    timeSensitive: true
                )
            } else {
                notificationService.ensureFocusAt(
                    breakEndAt: endAt,
                    timeSensitive: true
                )
            }
        }
    }

    /// タイマー停止（完全停止 - セッションリセット）
    func stopTimer() {
        // debug log removed
        stateManager.stopTimer()
        sessionManager.resetSession()
        notificationService.cancelSessionEndNotification()
        clearQuietMoonMessage()
    }

    /// タイマーリセット
    func resetTimer(to seconds: Int) {
        resetTimer(to: seconds, keepSession: false)
    }

    /// タイマーリセット（セッション保持の有無を選択）
    func resetTimer(to seconds: Int, keepSession: Bool) {
        // debug log removed
        stateManager.resetTimer(to: seconds)
        if keepSession {
            // セッション情報は保持
        } else {
            sessionManager.resetSession()
            clearQuietMoonMessage()
        }
        animationController.resetAnimationState()
        notificationService.cancelSessionEndNotification()
    }

    /// セッション完了処理
    func handleSessionCompleted(_ sessionInfo: TimerSessionInfo) {
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
        notificationService.cancelSessionEndNotification()

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
    func forceFinish() {
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

        // スケジュール済みの通知をキャンセル
        notificationService.cancelSessionEndNotification()

        updateQuietMoonMessage(forCompletedWorkSession: completedWasWorkSession)
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

        // 3) 通知の掃除（prefix一致で全削除）
        notificationService.cancelSessionEndAll()

        // 4) アニメの状態クリア
        animationController.resetAnimationState()

        // 5) 新しいセッション識別子で世界を張る
        sessionId = UUID()

        // 6) セッションマネージャーのリセット
        sessionManager.resetSession()
    }

    /// Quiet Moon状態からの専用開始処理
    func startFromQuietMoon() {
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

        // Work→Rest と Rest→Focus を開始時点で連鎖予約
        let workEndAt = endAt
        let breakEndAt = workEndAt.addingTimeInterval(TimeInterval(breakMinutes * 60))
        notificationService.scheduleChainedSessionEnds(
            workEndAt: workEndAt,
            breakEndAt: breakEndAt,
            timeSensitive: true
        )

        // Send start pulse
        startPulse.send()
    }

    /// 状態に応じた分岐処理でタイマー開始（新しいエントリポイント）
    func startTimerFromAnyState() {
        if isSessionFinished {
            startFromQuietMoon()
            return
        }
        startTimerNormalFlow()
    }

    /// 通常のタイマー開始フロー（既存のstartTimer()の内容）
    private func startTimerNormalFlow() {
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
        // 次のセッションの種類に応じて連鎖/冪等予約
        if isWorkSession {
            // Work→Rest と Rest→Focus を開始時点で連鎖予約
            let workEndAt = endAt
            let breakEndAt = workEndAt.addingTimeInterval(TimeInterval(breakMinutes * 60))
            notificationService.scheduleChainedSessionEnds(
                workEndAt: workEndAt,
                breakEndAt: breakEndAt,
                timeSensitive: true
            )
        } else {
            // Break中開始（稀）: Focusのみ冪等予約
            notificationService.ensureFocusAt(
                breakEndAt: endAt,
                timeSensitive: true
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
