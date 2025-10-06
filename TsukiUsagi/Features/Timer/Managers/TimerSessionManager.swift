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
    func startSession(isWorkSession: Bool, activityLabel: String, subtitleLabel: String) {
        startTime = dateProvider.now()
        endTime = nil
    }

    /// セッション完了
    func completeSession(
        isWorkSession: Bool,
        activityLabel: String,
        subtitleLabel: String,
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
            activity: activityLabel,
            subtitle: subtitleLabel,
            memo: memo,
            completedSilently: completedSilently
        )
        historyService.add(parameters: parameters)

        // Record streak if this was a work session
        if isWorkSession {
            streakManager.recordTimerUsage()
        }
    }

    /// セッション終了時刻を設定
    func setEndAt(_ endAt: Date?) {
        self.endAt = endAt
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
        subtitleLabel: String,
        completedSilently: Bool = false
    ) {
        endTime = end

        // 履歴に保存
        let parameters = AddSessionParameters(
            start: startTime ?? end,
            end: end,
            phase: isWorkSession ? .focus : .breakTime,
            activity: activityLabel,
            subtitle: subtitleLabel,
            memo: nil,
            completedSilently: completedSilently
        )
        historyService.add(parameters: parameters)

        // Record streak if this was a work session
        if isWorkSession {
            streakManager.recordTimerUsage()
        }
    }
}
