//
//  TimerController.swift
//  TsukiUsagi
//
//  Created by azu-azu on 2025/06/12.
//

//
//  TimerViewModel.swift
//  TsukiUsagi
//

import Foundation
import Combine
import SwiftUI

/// Pomodoro ロジックと履歴保存、通知送信を司る ViewModel
final class TimerViewModel: ObservableObject {

    // MARK: – Published 状態
    @Published var timeRemaining: Int      = 0          // 残り秒
    @Published var isRunning:     Bool     = false      // 走っているか
    @Published var isWorkSession: Bool     = true       // true = focus, false = break
    @Published var isSessionFinished       = false      // 終了フラグ（View 切替に使用）
    @Published private(set) var startTime: Date?        // セッション開始時刻

    // MARK: – User-configurable
    @AppStorage("workMinutes")  private var workMinutes:  Int = 25
    @AppStorage("breakMinutes") private var breakMinutes: Int = 5

    // MARK: – 内部
    private var timer: Timer?
    private let historyVM: HistoryViewModel

    // MARK: – Init
    init(historyVM: HistoryViewModel) {
        self.historyVM = historyVM
    }

    // MARK: – 公開 API
    func startTimer() {
        guard !isRunning else { return }

        isRunning          = true
        isSessionFinished  = false
        startTime          = Date()                       // ★ 開始時刻を記録
        timeRemaining      = (isWorkSession ? workMinutes : breakMinutes) * 60

        timer = Timer.scheduledTimer(withTimeInterval: 1.0,
                                    repeats: true) { [weak self] _ in
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
        timeRemaining     = (isWorkSession ? workMinutes : breakMinutes) * 60
        isSessionFinished = false
        startTime         = nil
    }

    /// “MM:SS” 表示用
    func formatTime() -> String {
        let m = timeRemaining / 60, s = timeRemaining % 60
        return String(format: "%02d:%02d", m, s)
    }

    /// “HH:mm” の開始時刻文字列（開始前は "--:--"）
    var formattedStartTime: String {
        guard let start = startTime else { return "--:--" }
        return TimerViewModel.startFormatter.string(from: start)
    }

    // MARK: – プライベート
    private func tick() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            sessionCompleted()
        }
    }

    private func sessionCompleted() {
        stopTimer()
        isSessionFinished = true

        // 履歴保存
        if let start = startTime {
            historyVM.add(
                start: start,
                end:   Date(),
                phase: isWorkSession ? .focus : .breakTime
            )
        }

        // 次フェーズへトグル
        isWorkSession.toggle()

        // 通知送信
        NotificationManager.shared
            .sendPhaseChangeNotification(for: isWorkSession ? .focus : .breakTime)

        // ★ 次セッションはユーザが Start を押すまで待つ
    }

    // MARK: – Static helpers
    private static let startFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()
}
