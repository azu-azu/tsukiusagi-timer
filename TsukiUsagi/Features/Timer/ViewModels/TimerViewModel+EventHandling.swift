//
//  TimerViewModel+EventHandling.swift
//  TsukiUsagi
//
//  Event dispatch and handling for TimerViewModel.
//  All external interactions should go through send(_:).
//

import Foundation

@MainActor
extension TimerViewModel {

    // MARK: - Event Dispatch

    /// イベントを受け取り、適切なハンドラーにディスパッチする
    /// 外部からの状態変更はすべてこのメソッドを経由する
    func send(_ event: TimerEvent) async {
        switch event {
        case .startTapped:
            await handleStartTapped()

        case .pauseTapped:
            await handlePauseTapped()

        case .forceFinishTapped:
            await handleForceFinishTapped()

        case let .resetRequested(seconds, keepSession):
            await handleResetRequested(seconds: seconds, keepSession: keepSession)

        case let .sessionCompleted(sessionInfo):
            await handleSessionCompletedEvent(sessionInfo)

        case .sessionFinishedReset:
            handleSessionFinishedReset()

        case .appDidEnterBackground:
            handleAppDidEnterBackground()

        case .appWillEnterForeground:
            handleAppWillEnterForeground()

        case .settingsChanged:
            handleSettingsChanged()
        }
    }

    // MARK: - Event Handlers (Private)

    private func handleStartTapped() async {
        await startTimerFromAnyState()
    }

    private func handlePauseTapped() async {
        await pauseTimerInternal()
    }

    private func handleForceFinishTapped() async {
        await forceFinishInternal()
    }

    private func handleResetRequested(seconds: Int, keepSession: Bool) async {
        await resetTimerInternal(to: seconds, keepSession: keepSession)
    }

    private func handleSessionCompletedEvent(_ sessionInfo: TimerSessionInfo) async {
        await handleSessionCompleted(sessionInfo)
    }

    private func handleSessionFinishedReset() {
        stateManager.resetSessionFinished()
    }

    private func handleAppDidEnterBackground() {
        saveTimerState()
        let result = lifecycleCoordinator.didEnterBackground(
            timeRemaining: timeRemaining,
            isRunning: isRunning
        )
        lastBackgroundDate = result.lastBackgroundDate
        isBackgroundCompleted = result.isBackgroundCompleted
    }

    private func handleAppWillEnterForeground() {
        let params = TimerForegroundParams(
            isSessionFinished: isSessionFinished,
            isBackgroundCompleted: isBackgroundCompleted,
            timeRemaining: timeRemaining,
            isRunning: isRunning,
            isWorkSession: isWorkSession,
            startTime: startTime
        )
        lifecycleCoordinator.willEnterForeground(
            params: params
        ) { [weak self] info in
            Task { @MainActor [weak self] in
                await self?.handleSessionCompleted(info)
            }
        }

        // 復帰直後の1ステップ（サイレント再始動）
        if runState == .running {
            if let endAt = sessionManager.endAt {
                let now = dateProvider.now()
                let remain = max(0, Int(floor(endAt.timeIntervalSince(now))))
                stateManager.timeRemaining = remain
                if remain == 0 {
                    stateManager.stopTimer()
                    return
                }
            }
            if !stateManager.isRunning {
                stateManager.resumeTimer()
            }
        }
    }

    private func handleSettingsChanged() {
        displayManager.setWorkMinutes(workMinutes)
        displayManager.setBreakMinutes(breakMinutes)

        if runState == .idle && !isRunning && !isSessionFinished {
            stateManager.resetTimer(to: workMinutes * 60)
        }
    }
}
