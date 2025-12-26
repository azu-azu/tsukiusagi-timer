//
//  TimerEvent.swift
//  TsukiUsagi
//
//  Event-driven architecture for TimerViewModel.
//  All state changes flow through these events.
//

import Foundation

/// TimerViewModelへの入力イベント
/// 状態変更はすべてこのenumを経由する
enum TimerEvent: Equatable {
    // MARK: - User Actions
    /// STARTボタンタップ（idle/paused/quietMoon状態から）
    case startTapped
    /// PAUSEボタンタップ
    case pauseTapped
    /// 強制終了（Stop & Save）
    case forceFinishTapped
    /// タイマーリセット
    case resetRequested(seconds: Int, keepSession: Bool)

    // MARK: - Session Lifecycle
    /// セッション自然完了（エンジンからのコールバック）
    case sessionCompleted(TimerSessionInfo)
    /// セッション完了状態のリセット
    case sessionFinishedReset

    // MARK: - App Lifecycle
    /// アプリがバックグラウンドへ
    case appDidEnterBackground
    /// アプリがフォアグラウンドへ
    case appWillEnterForeground

    // MARK: - Settings
    /// 設定変更後のリフレッシュ
    case settingsChanged

    // MARK: - Equatable
    static func == (lhs: TimerEvent, rhs: TimerEvent) -> Bool {
        switch (lhs, rhs) {
        case (.startTapped, .startTapped),
             (.pauseTapped, .pauseTapped),
             (.forceFinishTapped, .forceFinishTapped),
             (.sessionFinishedReset, .sessionFinishedReset),
             (.appDidEnterBackground, .appDidEnterBackground),
             (.appWillEnterForeground, .appWillEnterForeground),
             (.settingsChanged, .settingsChanged):
            return true
        case let (.resetRequested(s1, k1), .resetRequested(s2, k2)):
            return s1 == s2 && k1 == k2
        case let (.sessionCompleted(i1), .sessionCompleted(i2)):
            return i1.endTime == i2.endTime && i1.isSilent == i2.isSilent
        default:
            return false
        }
    }
}
