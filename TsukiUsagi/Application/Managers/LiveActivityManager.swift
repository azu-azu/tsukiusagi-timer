//
//  LiveActivityManager.swift
//  TsukiUsagi
//
//  Created by Kazumi on 2025/01/19.
//

import ActivityKit
import Foundation

/// Live Activity を管理するシングルトン
///
/// TimerViewModel からタイマーのライフサイクルに応じて
/// Live Activity を開始・更新・終了する
@MainActor
final class LiveActivityManager {
    // MARK: - Singleton
    static let shared = LiveActivityManager()

    // MARK: - Private Properties

    /// 現在実行中のActivityインスタンス
    private var currentActivity: Activity<TimerActivityAttributes>?

    // MARK: - Private Initialization

    private init() {}

    // MARK: - Public Methods

    /// タイマー開始時にLive Activityを起動
    ///
    /// - Parameters:
    ///   - sessionKind: セッション種別（"Work", "Study", "Read", "Break"など）
    ///   - endsAt: タイマー終了予定時刻
    func startActivity(sessionKind: String, endsAt: Date) async {
        // Live Activityが無効化されている場合は静かにスキップ
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        // 既存のActivityがあれば終了（単一化ポリシー）
        await endActivityIfNeeded(finalEndsAt: nil)

        // 新しいActivityを作成
        let attributes = TimerActivityAttributes(sessionKind: sessionKind)
        let contentState = TimerActivityAttributes.ContentState(endsAt: endsAt, isPaused: false)
        do {
            currentActivity = try await Activity<TimerActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil)
            )
        } catch {
            currentActivity = nil
        }
    }

    /// Pause/Resume時にActivityを更新
    ///
    /// - Parameters:
    ///   - isPaused: 一時停止中かどうか
    ///   - newEndsAt: 新しい終了予定時刻
    func updateActivity(isPaused: Bool, newEndsAt: Date, remainingSeconds: Int? = nil) async {
        guard let activity = currentActivity else { return }
        let contentState = TimerActivityAttributes.ContentState(
            endsAt: newEndsAt,
            isPaused: isPaused,
            remainingSeconds: remainingSeconds
        )
        await activity.update(.init(state: contentState, staleDate: nil))
    }

    /// タイマー完了/キャンセル時にActivityを終了
    /// - Parameter finalEndsAt: 終了時の最終的なendsAt（元の終了時刻を維持）。nilの場合は現在のActivityのendsAtを使用
    func endActivity(finalEndsAt: Date? = nil) async {
        await endActivityIfNeeded(finalEndsAt: finalEndsAt)
    }

    // MARK: - Private Helpers

    /// 既存のActivityがある場合は終了
    private func endActivityIfNeeded(finalEndsAt: Date? = nil) async {
        guard let activity = currentActivity else { return }
        let dismissPolicy: ActivityUIDismissalPolicy = .immediate
        // 終了時は元のendsAtを維持（Date()に上書きしない）＋isFinishedをtrueにする
        let preservedEndsAt = finalEndsAt ?? activity.content.state.endsAt
        let currentContentState = TimerActivityAttributes.ContentState(
            endsAt: preservedEndsAt,
            isPaused: false,
            remainingSeconds: nil,
            isFinished: true
        )
        await activity.end(.init(state: currentContentState, staleDate: nil), dismissalPolicy: dismissPolicy)
        currentActivity = nil
    }
}
