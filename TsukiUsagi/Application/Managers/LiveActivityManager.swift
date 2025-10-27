//
//  LiveActivityManager.swift
//  TsukiUsagi
//
//  Created by Kazumi on 2025/01/19.
//

import ActivityKit
import Foundation

/// Live Activity のデータモデル（Main App用）
///
/// Widget Extensionと共有するため、同じ構造を定義
struct TimerActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var endsAt: Date
        var isPaused: Bool
    }

    var sessionKind: String
}

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
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            #if DEBUG
            print("🌙 LiveActivity: Skipped (not enabled)")
            #endif
            return
        }

        // 既存のActivityがあれば終了（単一化ポリシー）
        await endActivityIfNeeded()

        // 新しいActivityを作成
        let attributes = TimerActivityAttributes(sessionKind: sessionKind)
        let contentState = TimerActivityAttributes.ContentState(endsAt: endsAt, isPaused: false)

        do {
            currentActivity = try await Activity<TimerActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil)
            )
            #if DEBUG
            print("🌙 LiveActivity: Started (\(sessionKind), endsAt: \(endsAt))")
            #endif
        } catch {
            currentActivity = nil
            #if DEBUG
            print("🌙 LiveActivity: Failed to start → \(error)")
            #endif
        }
    }

    /// Pause/Resume時にActivityを更新
    ///
    /// - Parameters:
    ///   - isPaused: 一時停止中かどうか
    ///   - newEndsAt: 新しい終了予定時刻
    func updateActivity(isPaused: Bool, newEndsAt: Date) async {
        guard let activity = currentActivity else { return }

        let contentState = TimerActivityAttributes.ContentState(
            endsAt: newEndsAt,
            isPaused: isPaused
        )

        await activity.update(.init(state: contentState, staleDate: nil))

        #if DEBUG
        print("🌙 LiveActivity: Updated (paused: \(isPaused), newEndsAt: \(newEndsAt))")
        #endif
    }

    /// タイマー完了/キャンセル時にActivityを終了
    func endActivity() async {
        await endActivityIfNeeded()
    }

    // MARK: - Private Helpers

    /// 既存のActivityがある場合は終了
    private func endActivityIfNeeded() async {
        guard let activity = currentActivity else { return }

        let dismissPolicy: ActivityUIDismissalPolicy = .immediate
        let currentContentState = TimerActivityAttributes.ContentState(
            endsAt: Date(),
            isPaused: false
        )
        await activity.end(.init(state: currentContentState, staleDate: nil), dismissalPolicy: dismissPolicy)
        currentActivity = nil

        #if DEBUG
        print("🌙 LiveActivity: Ended")
        #endif
    }
}

