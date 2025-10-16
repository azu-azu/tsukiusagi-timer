//
//  TimerSessionManager.swift
//  TsukiUsagi
//
//  Created by Azu on 2025/01/01.
//

import Foundation
import Combine

/// タイマーセッション管理を担当するManager
@MainActor
final class TimerSessionManager: ObservableObject {

    // MARK: - Dependencies

    private let historyService: SessionHistoryServiceable
    private let streakManager: StreakManager
    private let dateProvider: DateProviding

    // MARK: - Published Properties

    @Published private(set) var startTime: Date?
    @Published private(set) var endTime: Date?
    @Published private(set) var endAt: Date?

    // MARK: - Initialization

    init(
        historyService: SessionHistoryServiceable,
        streakManager: StreakManager,
        dateProvider: DateProviding
    ) {
        self.historyService = historyService
        self.streakManager = streakManager
        self.dateProvider = dateProvider
    }

    // MARK: - Session Management

    /// セッション開始
    func startSession(isWorkSession: Bool, activityLabel: String, taskLabel: String) {
        startTime = dateProvider.now()
        endTime = nil
    }
    // subtitleLabel overload removed; use taskLabel API only

    /// セッション完了
    func completeSession(
        isWorkSession: Bool,
        activityLabel: String,
        taskLabel: String,
        memo: String? = nil,
        completedSilently: Bool = false
    ) {
        guard let startTime = startTime else { return }

        endTime = dateProvider.now()

        // 履歴に保存
        let parameters = AddSessionParameters(
            start: startTime,
            end: endTime!,
            phase: isWorkSession ? .focus : .breakTime,
            sessionName: activityLabel,
            task: taskLabel,
            memo: memo,
            completedSilently: completedSilently
        )
        historyService.add(parameters: parameters)

        // Record streak if this was a work session
        if isWorkSession {
            streakManager.recordTimerUsage()
        }
    }

    /// セッション終了時刻（予約）を設定
    /// - Note: 通知・連鎖スケジュール用。UIは使用しない（UIのSSOTは endTime）。
    func setEndAt(_ endAt: Date?) {
        self.endAt = endAt
    }

    /// 編集後の終了時刻を UI に即時反映（Quiet Moon / RecordedTimesView 用のSSOT）
    /// - Parameter newEnd: 編集で確定した終了時刻
    /// - Discussion: UI表示は編集値を尊重し、now にはクランプしない（未来も許容）。
    ///               通知スケジュール用の endAt には触れない。
    func overrideEndTime(_ newEnd: Date) {
        guard let start = startTime else { return }
        // UIのSSOTは endTime。開始時刻より前にはならないよう下限のみ保証し、未来は許容する。
        let adjusted = max(newEnd, start)
        if endTime != adjusted {
            endTime = adjusted
        }
    }

    /// セッション状態をリセット
    func resetSession() {
        startTime = nil
        endTime = nil
        endAt = nil
    }

    /// 時間切れセッションの処理
    func handleExpiredSession(
        end: Date,
        isWorkSession: Bool,
        activityLabel: String,
        taskLabel: String,
        completedSilently: Bool = false
    ) {
        endTime = end

        // 履歴に保存
        let parameters = AddSessionParameters(
            start: startTime ?? end,
            end: end,
            phase: isWorkSession ? .focus : .breakTime,
            sessionName: activityLabel,
            task: taskLabel,
            memo: nil,
            completedSilently: completedSilently
        )
        historyService.add(parameters: parameters)

        // Record streak if this was a work session
        if isWorkSession {
            streakManager.recordTimerUsage()
        }
    }

    // subtitleLabel overload removed; use taskLabel API only
}
