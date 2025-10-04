//
//  TimerLifecycleCoordinator.swift
//  TsukiUsagi
//
//  Created by Kazumi on 2025/10/04.
//

import Foundation

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
        isSessionFinished: Bool,
        isBackgroundCompleted: Bool,
        timeRemaining: Int,
        isRunning: Bool,
        isWorkSession: Bool,
        startTime: Date?,
        handleCompleted: (TimerSessionInfo) -> Void
    ) {
        notificationAndHapticManager.appWillEnterForeground()

        // まだ完了処理していないが、すでに時間切れで停止している場合はここで完了処理
        if !isSessionFinished && !isBackgroundCompleted && timeRemaining <= 0 && !isRunning {
            let sessionInfo = TimerSessionInfo(
                startTime: startTime ?? dateProvider.now(),
                endTime: dateProvider.now(),
                phase: isWorkSession ? .focus : .breakTime,
                actualWorkedSeconds: 0
            )
            handleCompleted(sessionInfo)
            return
        }

        // バックグラウンドで完了していない場合のみ復元・再始動
        if !isSessionFinished {
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
