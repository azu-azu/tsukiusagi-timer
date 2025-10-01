//
//  TimerStateManager.swift
//  TsukiUsagi
//
//  Created by Kazumi on 2025/01/01.
//

import Foundation
import Combine

/// タイマー状態管理を担当するManager
@MainActor
final class TimerStateManager: ObservableObject {

    // MARK: - Published Properties

    @Published var timeRemaining: Int = 0
    @Published var isRunning: Bool = false
    @Published private(set) var runState: TimerRunState = .idle
    @Published var isWorkSession: Bool = true
    @Published var isSessionFinished = false

    // MARK: - Dependencies

    private let engine: TimerEngineable
    private let formatter: TimeFormatterUtilable
    private let dateProvider: DateProviding

    // MARK: - Initialization

    init(
        engine: TimerEngineable,
        formatter: TimeFormatterUtilable,
        dateProvider: DateProviding
    ) {
        self.engine = engine
        self.formatter = formatter
        self.dateProvider = dateProvider

        setupEngineBindings()
    }

    // MARK: - Engine Bindings

    private func setupEngineBindings() {
        engine.onTick = { [weak self] remaining in
            self?.timeRemaining = remaining
        }

        engine.onSessionCompleted = { [weak self] sessionInfo in
            self?.handleSessionCompleted(sessionInfo)
        }
    }

    // MARK: - State Management

    /// タイマー開始
    func startTimer() {
        guard timeRemaining > 0 else { return }

        isRunning = true
        runState = .running
        engine.start(seconds: timeRemaining)
    }

    /// タイマー一時停止
    func pauseTimer() {
        isRunning = false
        runState = .paused
        engine.pause()
    }

    /// タイマー再開
    func resumeTimer() {
        guard timeRemaining > 0 else { return }

        isRunning = true
        runState = .running
        engine.resume()
    }

    /// タイマー停止
    func stopTimer() {
        isRunning = false
        runState = .idle
        engine.stop()
    }

    /// タイマーリセット
    func resetTimer(to seconds: Int) {
        timeRemaining = seconds
        isRunning = false
        runState = .idle
        isSessionFinished = false
        engine.reset(to: seconds)
    }

    /// セッション完了処理
    func handleSessionCompleted(_ sessionInfo: TimerSessionInfo) {
        isSessionFinished = true
        isWorkSession = false
        timeRemaining = 0
        isRunning = false
        runState = .idle
    }

    /// 状態を復元
    func restoreState(
        timeRemaining: Int,
        isRunning: Bool,
        runState: TimerRunState,
        isWorkSession: Bool
    ) {
        self.timeRemaining = timeRemaining
        self.isRunning = isRunning
        self.runState = runState
        self.isWorkSession = isWorkSession
    }

    /// セッション完了状態をリセット
    func resetSessionFinished() {
        isSessionFinished = false
    }
}
