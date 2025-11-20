//
//  TimerStateManager.swift
//  TsukiUsagi
//
//  Created by Azu on 2025/01/01.
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
        dateProvider: DateProviding,
        defaultWorkMinutes: Int = 25
    ) {
        self.engine = engine
        self.formatter = formatter
        self.dateProvider = dateProvider

        // 初期値は0（initializeWithWorkMinutesで正しい時間が設定される）
        self.timeRemaining = 0

        // Note: engine.onTick と engine.onSessionCompleted は TimerViewModel.setupEngineCallbacks() で一元管理される
    }

    // MARK: - State Management

    /// タイマー開始
    func startTimer() {
        guard timeRemaining > 0 else { return }

        runState = .running
        isSessionFinished = false // セッション完了状態をリセット
        engine.start(seconds: timeRemaining)
        isRunning = engine.isRunning
    }

    /// タイマー一時停止
    func pauseTimer() {
        runState = .paused
        engine.pause()
        isRunning = engine.isRunning
    }

    /// タイマー再開
    func resumeTimer() {
        guard timeRemaining > 0 else { return }

        runState = .running
        engine.resume()
        isRunning = engine.isRunning
    }

    /// タイマー停止
    func stopTimer() {
        runState = .idle
        engine.stop()
        isRunning = engine.isRunning
    }

    /// タイマーリセット
    func resetTimer(to seconds: Int) {
        timeRemaining = seconds
        runState = .idle
        isSessionFinished = false
        engine.reset(to: seconds)
        isRunning = engine.isRunning
    }

    /// セッション完了処理
    func handleSessionCompleted(_ sessionInfo: TimerSessionInfo) {
        isSessionFinished = true
        // isWorkSessionは変更しない（完了したセッションの種類を保持）
        timeRemaining = 0
        runState = .idle
        // セッション完了時は確実にisRunningをfalseに設定
        isRunning = false
        engine.stop()
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

    /// セッション完了状態を設定
    func setSessionFinished(_ finished: Bool) {
        isSessionFinished = finished
    }

    /// 作業セッション状態を設定
    func setWorkSession(_ isWork: Bool) {
        isWorkSession = isWork
    }

    /// セッション完了状態をリセット
    func resetSessionFinished() {
        isSessionFinished = false
    }

    /// 設定済みの作業時間で初期化
    func initializeWithWorkMinutes(_ minutes: Int) {
        timeRemaining = minutes * 60
        isRunning = false
        runState = .idle
        isWorkSession = true
        isSessionFinished = false
    }
}
