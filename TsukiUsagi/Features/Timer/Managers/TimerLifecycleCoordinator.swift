//
//  TimerLifecycleCoordinator.swift
//  TsukiUsagi
//
//  Created by Azu on 2025/10/04.
//

import Foundation

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
        notificationAndHapticManager.appDidEnterBackground()
        let isCompletedInBackground = (timeRemaining <= 0 && isRunning)
        return (isCompletedInBackground, now)
    }

    // MARK: - Foreground

    func willEnterForeground(
        params: TimerForegroundParams,
        handleCompleted: (TimerSessionInfo) -> Void
    ) {
        notificationAndHapticManager.appWillEnterForeground()

        // Task 1: Pre-update state before UI render
        // 復帰直後に endAt を基準に timeRemaining を確定させ、
        // 最初のフレームから正しい残り時間（0を含む）を描画できるようにする。
        if !params.isSessionFinished {
            // 状態復元を先に実施
            restoreTimerState()

            // endAt から残り時間を導出して即時反映（UI先行安定）
            if let endAt = sessionManager.endAt {
                let now = dateProvider.now()
                let remaining = remainingSeconds(until: endAt, now: now)
                stateManager.timeRemaining = remaining
                #if DEBUG
                #endif
            }
        }

        // Task 4: Add immediate completion when expired (endAt を唯一の真実として判定)
        if !params.isSessionFinished, let endAt = sessionManager.endAt {
            let now = dateProvider.now()
            if now >= endAt {
                #if DEBUG
                #endif
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

        // バックグラウンドで完了していない場合のみ再始動の判定（復元は上で済み）
        if !params.isSessionFinished {
            // 再始動の判定も endAt ベースに統一
            if stateManager.runState == .running, let endAt = sessionManager.endAt {
                let now = dateProvider.now()
                let remaining = remainingSeconds(until: endAt, now: now)
                if remaining > 0 {
                    #if DEBUG
                    #endif
                    startFromRestoredIfNeeded()
                } else {
                    #if DEBUG
                    #endif
                }
            } else {
                #if DEBUG
                #endif
            }
        }
    }

    // MARK: - Private (restore orchestration)

    /// endAt から残り秒数を導出（負値は0に、端数は切り上げ）
    private func remainingSeconds(until endAt: Date, now: Date) -> Int {
        return max(0, Int(ceil(endAt.timeIntervalSince(now))))
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
            } else if let persisted = endAt, let current = sessionManager.endAt {
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
