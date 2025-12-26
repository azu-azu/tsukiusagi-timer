//
//  TimerViewModel+SessionControl.swift
//  TsukiUsagi
//
//  Extracted session control APIs to reduce TimerViewModel size.
//  Public API uses send(_:) for event-driven architecture.
//

import Foundation
import UIKit

@MainActor
extension TimerViewModel {

    // MARK: - Public API (Event-driven)

    /// タイマー開始
    func startTimer() async {
        await send(.startTapped)
    }

    /// タイマー一時停止
    func pauseTimer() async {
        await send(.pauseTapped)
    }

    /// タイマー再開
    func resumeTimer() async {
        // resumeはstartTappedと同じ（paused状態からの開始）
        await send(.startTapped)
    }

    /// タイマー停止（完全停止 - セッションリセット）
    func stopTimer() async {
        await send(.resetRequested(seconds: workMinutes * 60, keepSession: false))
    }

    /// タイマーリセット
    func resetTimer(to seconds: Int) async {
        await send(.resetRequested(seconds: seconds, keepSession: false))
    }

    /// タイマーリセット（セッション保持の有無を選択）
    func resetTimer(to seconds: Int, keepSession: Bool) async {
        await send(.resetRequested(seconds: seconds, keepSession: keepSession))
    }

    /// 強制終了
    func forceFinish() async {
        await send(.forceFinishTapped)
    }

    /// セッション完了状態をリセット
    func resetSessionFinished() {
        Task { await send(.sessionFinishedReset) }
    }

    // MARK: - Internal Implementation

    /// タイマー一時停止（内部実装）
    func pauseTimerInternal() async {
        stateManager.pauseTimer()
        notificationAndHapticManager.triggerLightHaptic()
        // 通知をキャンセル（一時停止中は直近フェーズのみを取り消す）
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

    /// タイマーリセット（内部実装）
    func resetTimerInternal(to seconds: Int, keepSession: Bool) async {
        // アニメーション抑制を設定（リセット時の不要なアニメーション発火を防ぐ）
        animationController.setAnimationSuppression(true)

        stateManager.resetTimer(to: seconds)
        if !keepSession {
            sessionManager.resetSession()
            clearQuietMoonMessage()
        }
        animationController.resetAnimationState()
        // フェーズごとにキャンセル（グローバルCancelを避ける）
        notificationService.cancelSessionEnd(for: .focus)
        notificationService.cancelSessionEnd(for: .breakTime)

        // Live Activity終了
        await LiveActivityManager.shared.endActivity()

        // アニメーション抑制を解除（次の操作で正常にアニメーションが発火するように）
        animationController.setAnimationSuppression(false)
    }

    /// セッション完了処理（内部実装 - send(.sessionCompleted)から呼ばれる）
    func handleSessionCompleted(_ sessionInfo: TimerSessionInfo) async {
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

        // Live Activity終了（元の終了時刻を維持）
        await LiveActivityManager.shared.endActivity(finalEndsAt: sessionManager.endAt)

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

    /// 強制終了（内部実装）
    func forceFinishInternal() async {
        guard startTime != nil && !isSessionFinished else { return }
        guard canForceFinish else { return }

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
        // 前回のタイマー設定値が残らないように明示的に0にリセット
        stateManager.timeRemaining = 0
        runState = .idle
        endTime = nil

        // 3) 通知の掃除は開始/再開時は行わない（フェーズ粒度の掃除はスケジューラ側で実施）

        // 4) アニメの状態クリア
        animationController.resetAnimationState()

        // 5) 新しいセッション識別子で世界を張る
        sessionId = UUID()

        // 6) セッションマネージャーのリセット
        sessionManager.resetSession()

        // 7) アニメーション購読の再確立（cancellables.removeAll()で解除された購読を復元）
        reestablishBindings()
    }

    /// Quiet Moon状態からの専用開始処理
    func startFromQuietMoon() async {
        performCompleteStateReset()

        // 購読の確立を確実にするため、次の実行ループまで待機
        await Task.yield()

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

        // アニメーションを発火
        // 注意: triggerStartAnimations()内でanimationController.startPulse.send()が呼ばれるため、
        // reestablishBindings()で購読が確立されていれば、timerVM.startPulseに転送される
        animationController.triggerStartAnimations()
        notificationAndHapticManager.sendStartNotification()

        // 終了時刻を設定し、次フェーズの通知を連鎖で予約
        // Engineと同じ秒境界にアラインして、SOTを統一
        let now = dateProvider.now()
        let alignedStart = Date(timeIntervalSince1970: ceil(now.timeIntervalSince1970))
        let endAt = alignedStart.addingTimeInterval(TimeInterval(workLengthMinutes * 60))
        sessionManager.setEndAt(endAt)

        // Live Activity開始
        await LiveActivityManager.shared.startActivity(
            sessionKind: activityLabel,
            endsAt: endAt
        )

        // Work→Rest と Rest→Focus を開始時点で個別に予約（BG優先度適用）
        scheduleChainNotifications(workEndAt: endAt)
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
        stateManager.startTimer()
        animationController.triggerStartAnimations()
        notificationAndHapticManager.sendStartNotification()

        // 終了時刻を設定し、次フェーズの通知を連鎖で予約
        // Engineと同じ秒境界にアラインして、SOTを統一
        let now = dateProvider.now()
        let alignedStart = Date(timeIntervalSince1970: ceil(now.timeIntervalSince1970))
        let endAt = alignedStart.addingTimeInterval(TimeInterval(targetTime))
        sessionManager.setEndAt(endAt)

        // Live Activity開始
        await LiveActivityManager.shared.startActivity(
            sessionKind: activityLabel,
            endsAt: endAt
        )

        // 次のセッションの種類に応じて連鎖/冪等予約
        if isWorkSession {
            // Work→Rest と Rest→Focus を開始時点で個別に予約（BG優先度適用）
            scheduleChainNotifications(workEndAt: endAt)
        } else {
            // Break中開始（稀）: Focusのみ冪等予約
            notificationService.ensureFocusAt(
                breakEndAt: endAt,
                timeSensitive: true
            )
        }
    }

    // MARK: - Private Helpers
    /// Start時にWorkへ強制統一（Break完了残留を潰す）
    /// 仕様: セッション完了直後は必ずWorkセッションから開始する
    private func ensureWorkOnStart() {
        if isSessionFinished || !isWorkSession {
            stateManager.setWorkSession(true)
        }
    }

    /// Work→Rest と Rest→Focus の通知を連鎖で予約（重複排除のため共通化）
    private func scheduleChainNotifications(workEndAt: Date) {
        let breakEndAt = workEndAt.addingTimeInterval(TimeInterval(breakMinutes * 60))
        let isBG = UIApplication.shared.applicationState != .active
        // Rest（break）は BG では timeSensitive: false
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
    }

    private func updateQuietMoonMessage(forCompletedWorkSession completedWorkSession: Bool) {
        if completedWorkSession {
            assignQuietMoonMessageIfNeeded()
        } else {
            clearQuietMoonMessage()
        }
    }
}
