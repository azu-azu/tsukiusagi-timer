//
//  TimerEffect.swift
//  TsukiUsagi
//
//  Side effects produced by TimerViewModel.
//  Effects are pure descriptions of work to be done.
//  The actual execution is handled by executeEffect(_:).
//

import Foundation

/// TimerViewModelが発行する副作用
/// 状態変更後に実行されるべき外部処理を記述する
enum TimerEffect: Equatable {
    // MARK: - Haptics
    /// 軽いハプティックフィードバック（一時停止時など）
    case triggerLightHaptic
    /// 重いハプティックフィードバック（セッション完了時など）
    case triggerHeavyHaptic

    // MARK: - Animations
    /// 開始アニメーションを発火（パルス、星の輝きなど）
    case triggerStartAnimations
    /// セッション完了アニメーションを発火
    case triggerSessionFinishedAnimations
    /// アニメーション状態をリセット
    case resetAnimationState

    // MARK: - Notifications
    /// セッション終了通知をスケジュール
    case scheduleSessionEndNotification(at: Date, phase: PomodoroPhase, timeSensitive: Bool)
    /// 通知をキャンセル（フェーズ指定）
    case cancelNotification(phase: PomodoroPhase)
    /// Focus通知を冪等に予約（Break終了時用）
    case ensureFocusNotification(breakEndAt: Date, timeSensitive: Bool)
    /// 開始通知を送信
    case sendStartNotification

    // MARK: - Live Activity
    /// Live Activityを開始
    case startLiveActivity(sessionKind: String, endsAt: Date)
    /// Live Activityを更新
    case updateLiveActivity(isPaused: Bool, newEndsAt: Date, remainingSeconds: Int?)
    /// Live Activityを終了
    case endLiveActivity(finalEndsAt: Date?)

    // MARK: - Persistence
    /// タイマー状態を永続化
    case saveTimerState

    // MARK: - Session History
    /// セッション履歴を保存
    case saveSessionHistory(
        endTime: Date,
        isWorkSession: Bool,
        activityLabel: String,
        taskLabel: String,
        isSilent: Bool
    )

    // MARK: - Equatable
    static func == (lhs: TimerEffect, rhs: TimerEffect) -> Bool {
        switch (lhs, rhs) {
        case (.triggerLightHaptic, .triggerLightHaptic),
             (.triggerHeavyHaptic, .triggerHeavyHaptic),
             (.triggerStartAnimations, .triggerStartAnimations),
             (.triggerSessionFinishedAnimations, .triggerSessionFinishedAnimations),
             (.resetAnimationState, .resetAnimationState),
             (.sendStartNotification, .sendStartNotification),
             (.saveTimerState, .saveTimerState):
            return true

        case let (.scheduleSessionEndNotification(d1, p1, t1), .scheduleSessionEndNotification(d2, p2, t2)):
            return d1 == d2 && p1 == p2 && t1 == t2

        case let (.cancelNotification(p1), .cancelNotification(p2)):
            return p1 == p2

        case let (.ensureFocusNotification(d1, t1), .ensureFocusNotification(d2, t2)):
            return d1 == d2 && t1 == t2

        case let (.startLiveActivity(k1, e1), .startLiveActivity(k2, e2)):
            return k1 == k2 && e1 == e2

        case let (.updateLiveActivity(p1, e1, r1), .updateLiveActivity(p2, e2, r2)):
            return p1 == p2 && e1 == e2 && r1 == r2

        case let (.endLiveActivity(e1), .endLiveActivity(e2)):
            return e1 == e2

        case let (.saveSessionHistory(e1, w1, a1, t1, s1), .saveSessionHistory(e2, w2, a2, t2, s2)):
            return e1 == e2 && w1 == w2 && a1 == a2 && t1 == t2 && s1 == s2

        default:
            return false
        }
    }
}
