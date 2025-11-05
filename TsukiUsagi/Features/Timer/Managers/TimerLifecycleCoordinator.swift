//
//  TimerLifecycleCoordinator.swift
//  TsukiUsagi
//
//  Created by Azu on 2025/10/04.
//

import Foundation
#if DEBUG
import os
#endif

// Live Activity終了処理のため
@preconcurrency import ActivityKit

struct TimerForegroundParams {
    let isSessionFinished: Bool
    let isBackgroundCompleted: Bool
    let timeRemaining: Int
    let isRunning: Bool
    let isWorkSession: Bool
    let startTime: Date?
}

@MainActor
final class TimerLifecycleCoordinator {

    private let statePersistenceManager: TimerStatePersistenceManager
    private let notificationAndHapticManager: TimerNotificationAndHapticManager
    private let dateProvider: DateProviding
    private let sessionManager: TimerSessionManager
    private let stateManager: TimerStateManager

    init(
        statePersistenceManager: TimerStatePersistenceManager,
        notificationAndHapticManager: TimerNotificationAndHapticManager,
        dateProvider: DateProviding,
        sessionManager: TimerSessionManager,
        stateManager: TimerStateManager
    ) {
        self.statePersistenceManager = statePersistenceManager
        self.notificationAndHapticManager = notificationAndHapticManager
        self.dateProvider = dateProvider
        self.sessionManager = sessionManager
        self.stateManager = stateManager
    }

    // MARK: - Background

    func didEnterBackground(
        timeRemaining: Int,
        isRunning: Bool
    ) -> (isBackgroundCompleted: Bool, lastBackgroundDate: Date) {
        let now = dateProvider.now()
#if DEBUG
        // debug log removed
#endif
        notificationAndHapticManager.appDidEnterBackground()
        let isCompletedInBackground = (timeRemaining <= 0 && isRunning)
        return (isCompletedInBackground, now)
    }

    // MARK: - Foreground

    func willEnterForeground(
        params: TimerForegroundParams,
        handleCompleted: (TimerSessionInfo) -> Void
    ) {
#if DEBUG
        // debug log removed
#endif
        notificationAndHapticManager.appWillEnterForeground()

        // Task 1: 状態復元。Paused時は残り時間を再計算しない（ドリフト防止）。
        if !params.isSessionFinished {
            restoreTimerState()
        }

        // Task 4: Add immediate completion when expired (endAt を唯一の真実として判定)
        if !params.isSessionFinished, let endAt = sessionManager.endAt {
            let now = dateProvider.now()
            if now >= endAt {
                #if DEBUG
                // debug log removed
                #endif

                // ✅ FG復帰時の即時Live Activity終了（handleSessionCompletedより先に実行）
                // BG滞留中のカウントアップを防ぐため、最初のフレームで確実に終了
                Task { @MainActor in
                    await LiveActivityManager.shared.endActivity(finalEndsAt: endAt)
                }

                // 一度だけ画面内で静かな完了チップを表示するための通知
                NotificationCenter.default.post(name: Notification.Name("TimerSilentCompleted"), object: nil)

                let start = sessionManager.startTime ?? params.startTime ?? now
                let sessionInfo = TimerSessionInfo(
                    startTime: start,
                    endTime: endAt, // 終了の事実は endAt に一致させる
                    phase: stateManager.isWorkSession ? .focus : .breakTime,
                    actualWorkedSeconds: 0,
                    isSilent: true
                )
                handleCompleted(sessionInfo)
                return
            }
        }

        // Task 5: Running 中のみタイマー再起動（状態は restoreTimerState で確定済み）
        if !params.isSessionFinished, stateManager.runState == .running, let endAt = sessionManager.endAt {
            let now = dateProvider.now()
            if endAt > now {
                // Engine に再起動を伝える（タイマーは1本のみ）
                // Engine 側で整合済みのため、ここでは処理不要
            }
        }
    }

    // MARK: - Private (restore orchestration)

    /// endAt から残り秒数を導出（負値は0に、端数は切り上げ）
    private func remainingSeconds(until endAt: Date, now: Date) -> Int {
        // Keep in sync with WidgetKit (.timer) which visually floors to current second
        return max(0, Int(floor(endAt.timeIntervalSince(now))))
    }

    private func restoreTimerState() {
        let result = statePersistenceManager.restoreTimerState()

        switch result {
        case .success(let timeRemaining, let isRunning, let runState, let isWorkSession, let endAt):
            stateManager.restoreState(
                timeRemaining: timeRemaining,
                isRunning: isRunning,
                runState: runState,
                isWorkSession: isWorkSession
            )
            // 既にアプリ内で最新の endAt が設定されている場合は、復元値で上書きしない
            if sessionManager.endAt == nil, let endAt = endAt {
                sessionManager.setEndAt(endAt)
                #if DEBUG
                #endif
            } else if endAt != nil, sessionManager.endAt != nil {
                #if DEBUG
                #endif
            }

        case .failed:
            // 復元失敗時はデフォルト状態（workMinutesはVM側初期化でセット済み前提のためここでは触らない）
            break

        case .noData:
            break
        }
    }

    private func startFromRestoredIfNeeded() {
        let now = dateProvider.now()
        if let endAt = sessionManager.endAt, endAt > now {
            let remaining = remainingSeconds(until: endAt, now: now)
            if remaining > 0 {
                stateManager.timeRemaining = remaining
                stateManager.startTimer()
                #if DEBUG
                #endif
            }
        }
    }
}
