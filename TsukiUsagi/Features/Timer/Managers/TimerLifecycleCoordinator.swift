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

        // まだ完了処理していないが、すでに時間切れで停止している場合はここで完了処理
        if !params.isSessionFinished && !params.isBackgroundCompleted &&
           params.timeRemaining <= 0 && !params.isRunning {
            let sessionInfo = TimerSessionInfo(
                startTime: params.startTime ?? dateProvider.now(),
                endTime: dateProvider.now(),
                phase: params.isWorkSession ? .focus : .breakTime,
                actualWorkedSeconds: 0
            )
            handleCompleted(sessionInfo)
            return
        }

        // バックグラウンドで完了していない場合のみ復元・再始動
        if !params.isSessionFinished {
            restoreTimerState()
            if stateManager.runState == .running && stateManager.timeRemaining > 0 {
                startFromRestoredIfNeeded()
            }
        }
    }

    // MARK: - Private (restore orchestration)

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
            if let endAt = endAt { sessionManager.setEndAt(endAt) }

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
            let remaining = max(0, Int(ceil(endAt.timeIntervalSince(now))))
            if remaining > 0 {
                stateManager.timeRemaining = remaining
                stateManager.startTimer()
            }
        }
    }
}
