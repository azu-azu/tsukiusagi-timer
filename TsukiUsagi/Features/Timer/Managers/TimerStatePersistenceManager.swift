//
//  TimerStatePersistenceManager.swift
//  TsukiUsagi
//
//  Created by Kazumi on 2025/01/01.
//

import Foundation
import Combine

/// タイマーの永続化と復元を担当するManager
@MainActor
final class TimerStatePersistenceManager: ObservableObject {

    // MARK: - Dependencies

    private let persistenceManager: TimerPersistenceManageable
    private let dateProvider: DateProviding

    // MARK: - Published Properties

    @Published private(set) var isRestoring = false

    // MARK: - Initialization

    init(
        persistenceManager: TimerPersistenceManageable,
        dateProvider: DateProviding
    ) {
        self.persistenceManager = persistenceManager
        self.dateProvider = dateProvider
    }

    // MARK: - Public Methods

    /// タイマー状態を保存
    func saveTimerState(
        timeRemaining: Int,
        isRunning: Bool,
        runState: TimerRunState,
        isWorkSession: Bool,
        endAt: Date?
    ) {
        persistenceManager.timeRemaining = timeRemaining
        persistenceManager.isRunning = isRunning
        persistenceManager.runStateRaw = runState.rawValue
        persistenceManager.isWorkSession = isWorkSession
        persistenceManager.endAtEpoch = endAt?.timeIntervalSince1970
        persistenceManager.saveTimerState()
    }

    /// タイマー状態を復元
    func restoreTimerState() -> TimerRestoreResult {
        isRestoring = true
        defer { isRestoring = false }

        let timeRemaining = persistenceManager.timeRemaining
        let isRunning = persistenceManager.isRunning
        let runStateRaw = persistenceManager.runStateRaw
        let isWorkSession = persistenceManager.isWorkSession
        let endAtEpoch = persistenceManager.endAtEpoch

        // 復元データの検証
        guard timeRemaining > 0,
              let runStateRaw = runStateRaw,
              let runState = TimerRunState(rawValue: runStateRaw) else {
            return TimerRestoreResult.failed
        }

        let endAt = endAtEpoch != nil && endAtEpoch! > 0 ? Date(timeIntervalSince1970: endAtEpoch!) : nil

        return TimerRestoreResult.success(
            timeRemaining: timeRemaining,
            isRunning: isRunning,
            runState: runState,
            isWorkSession: isWorkSession,
            endAt: endAt
        )
    }

    /// 復元が必要かどうかを判定
    func shouldRestore() -> Bool {
        return persistenceManager.timeRemaining > 0 &&
               persistenceManager.runStateRaw != TimerRunState.idle.rawValue
    }

    /// 復元後の自動再開が必要かどうかを判定
    func shouldAutoResume() -> Bool {
        guard shouldRestore() else { return false }

        let runStateRaw = persistenceManager.runStateRaw
        let endAtEpoch = persistenceManager.endAtEpoch

        // 実行中状態で、終了時刻が未来の場合は自動再開
        if let runStateRaw = runStateRaw,
           runStateRaw == TimerRunState.running.rawValue,
           let endAtEpoch = endAtEpoch,
           endAtEpoch > 0 {
            let endAt = Date(timeIntervalSince1970: endAtEpoch)
            return endAt > dateProvider.now()
        }

        return false
    }

    /// 状態をクリア
    func clearState() {
        persistenceManager.timeRemaining = 0
        persistenceManager.isRunning = false
        persistenceManager.runStateRaw = TimerRunState.idle.rawValue
        persistenceManager.isWorkSession = true
        persistenceManager.endAtEpoch = nil
    }
}

// MARK: - Supporting Types

/// タイマー復元結果
enum TimerRestoreResult {
    case success(
        timeRemaining: Int,
        isRunning: Bool,
        runState: TimerRunState,
        isWorkSession: Bool,
        endAt: Date?
    )
    case failed
    case noData
}
