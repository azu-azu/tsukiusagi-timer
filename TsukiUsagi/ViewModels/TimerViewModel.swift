//
//  TimerViewModel.swift
//  TsukiUsagi
//
//  Created by azu-azu on 2025/06/12.
//

import Foundation
import Combine
import SwiftUI

final class TimerViewModel: ObservableObject {
    // 完了フラグ
    @Published var isSessionFinished = false

    // MARK: - User-configurable values
    @AppStorage("workMinutes")  private var workMinutes: Int = 25
    @AppStorage("breakMinutes") private var breakMinutes: Int = 5

    // MARK: - Published state
    @Published var timeRemaining: Int = 0
    @Published var isRunning: Bool = false
    @Published var isWorkSession: Bool = true   // true = focus, false = break

    // MARK: - Timer internals
    private var timer: Timer?
    private var sessionStart: Date?

    // MARK: - Dependency
    let historyVM: HistoryViewModel

    // MARK: - Public API
    init(historyVM: HistoryViewModel) {
        self.historyVM = historyVM
    }

    func startTimer() {
        guard !isRunning else { return }
        isRunning = true

        // セッションの長さをセット
        timeRemaining = (isWorkSession ? workMinutes : breakMinutes) * 60
        sessionStart = Date()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    func resetTimer() {
        stopTimer()
        timeRemaining = (isWorkSession ? workMinutes : breakMinutes) * 60
    }

    func formatTime() -> String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Private helpers
    private func tick() {
        DispatchQueue.main.async {
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                self.sessionCompleted()
            }
        }
    }

    private func sessionCompleted() {
        stopTimer()
        isSessionFinished = true

        // Save history
        if let start = sessionStart {
            let end = Date()
            let phase = isWorkSession ? PomodoroPhase.focus : PomodoroPhase.breakTime
            historyVM.add(start: start, end: end, phase: phase)
        }

        // 次は休憩↔︎作業を切り替える
        isWorkSession.toggle()

        // 次のフェーズを通知
        let nextPhase: PomodoroPhase = isWorkSession ? .focus : .breakTime
        NotificationManager.shared.sendPhaseChangeNotification(for: nextPhase)

        // 次のセッションを自動的に開始する
        // 続けるか判断する時間がほしい場合も多いので、デフォルトでは手動スタートにする
        // startTimer()
    }
}
