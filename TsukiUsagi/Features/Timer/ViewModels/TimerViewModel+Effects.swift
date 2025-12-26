//
//  TimerViewModel+Effects.swift
//  TsukiUsagi
//
//  Effect execution for TimerViewModel.
//  Effects are side effects that don't modify state directly.
//

import Foundation

@MainActor
extension TimerViewModel {

    // MARK: - Effect Execution

    /// 副作用を実行する
    /// Effectsは状態を直接変更しない。変更が必要な場合はsend(_:)を呼ぶ
    func executeEffect(_ effect: TimerEffect) async {
        switch effect {
        case .triggerLightHaptic, .triggerHeavyHaptic:
            executeHapticEffect(effect)
        case .triggerStartAnimations, .triggerSessionFinishedAnimations, .resetAnimationState:
            executeAnimationEffect(effect)
        case .scheduleSessionEndNotification, .cancelNotification, .ensureFocusNotification, .sendStartNotification:
            executeNotificationEffect(effect)
        case .startLiveActivity, .updateLiveActivity, .endLiveActivity:
            await executeLiveActivityEffect(effect)
        case .saveTimerState:
            executePersistenceEffect()
        case .saveSessionHistory:
            executeHistoryEffect(effect)
        }
    }

    /// 複数の副作用を順次実行する
    func executeEffects(_ effects: [TimerEffect]) async {
        for effect in effects {
            await executeEffect(effect)
        }
    }

    // MARK: - Effect Handlers (Private)

    private func executeHapticEffect(_ effect: TimerEffect) {
        switch effect {
        case .triggerLightHaptic:
            notificationAndHapticManager.triggerLightHaptic()
        case .triggerHeavyHaptic:
            notificationAndHapticManager.triggerHeavyHaptic()
        default:
            break
        }
    }

    private func executeAnimationEffect(_ effect: TimerEffect) {
        switch effect {
        case .triggerStartAnimations:
            animationController.triggerStartAnimations()
        case .triggerSessionFinishedAnimations:
            animationController.triggerSessionFinishedAnimations()
        case .resetAnimationState:
            animationController.resetAnimationState()
        default:
            break
        }
    }

    private func executeNotificationEffect(_ effect: TimerEffect) {
        switch effect {
        case let .scheduleSessionEndNotification(at, phase, timeSensitive):
            notificationService.scheduleSessionEndNotification(at: at, phase: phase, timeSensitive: timeSensitive)
        case let .cancelNotification(phase):
            notificationService.cancelSessionEnd(for: phase)
        case let .ensureFocusNotification(breakEndAt, timeSensitive):
            notificationService.ensureFocusAt(breakEndAt: breakEndAt, timeSensitive: timeSensitive)
        case .sendStartNotification:
            notificationAndHapticManager.sendStartNotification()
        default:
            break
        }
    }

    private func executeLiveActivityEffect(_ effect: TimerEffect) async {
        switch effect {
        case let .startLiveActivity(sessionKind, endsAt):
            await LiveActivityManager.shared.startActivity(sessionKind: sessionKind, endsAt: endsAt)
        case let .updateLiveActivity(isPaused, newEndsAt, remainingSeconds):
            await LiveActivityManager.shared.updateActivity(
                isPaused: isPaused,
                newEndsAt: newEndsAt,
                remainingSeconds: remainingSeconds
            )
        case let .endLiveActivity(finalEndsAt):
            await LiveActivityManager.shared.endActivity(finalEndsAt: finalEndsAt)
        default:
            break
        }
    }

    private func executePersistenceEffect() {
        statePersistenceManager.saveTimerState(
            timeRemaining: timeRemaining,
            isRunning: isRunning,
            runState: runState,
            isWorkSession: isWorkSession,
            endAt: sessionManager.endAt
        )
    }

    private func executeHistoryEffect(_ effect: TimerEffect) {
        guard case let .saveSessionHistory(endTime, isWorkSession, activityLabel, taskLabel, isSilent) = effect else {
            return
        }
        sessionManager.handleExpiredSession(
            end: endTime,
            isWorkSession: isWorkSession,
            activityLabel: activityLabel,
            taskLabel: taskLabel,
            completedSilently: isSilent
        )
    }
}
