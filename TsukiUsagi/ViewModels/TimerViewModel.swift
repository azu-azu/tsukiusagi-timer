//
//  TimerViewModel.swift
//  TsukiUsagi
//
//  Created by azu-azu on 2025/06/12.
//

import Foundation
import Combine
import SwiftUI
import UIKit   // UINotificationFeedbackGeneratorのため

/// Pomodoro ロジックと履歴保存、通知送信を司る ViewModel
final class TimerViewModel: ObservableObject {

    // Published 状態
    @Published var timeRemaining: Int      = 0          // 残り秒
    @Published var isRunning:     Bool     = false      // 走っているか
    @Published var isWorkSession: Bool     = true       // true = focus, false = break
    @Published var isSessionFinished       = false      // 終了フラグ（View 切替に使用）
    @Published private(set) var startTime: Date?        // セッション開始時刻

    // User-configurable
    @AppStorage("workMinutes")  private var workMinutes:  Int = 25
    @AppStorage("breakMinutes") private var breakMinutes: Int = 5

    // 内部
    private var timer: Timer?
    private let historyVM: HistoryViewModel

    // Init
    init(historyVM: HistoryViewModel) {
        self.historyVM = historyVM
    }

    // 公開 API
    func startTimer() {
        guard !isRunning else { return }

        // 1) 裏休憩タイマー or 既存タイマーが残っていても必ず止める
        stopTimer()

        // 2) これは「新しいセッション」か？ (= 最後のセッションが完了しているか)
        if isSessionFinished {
            // 新しい Work を始める
            isWorkSession     = true
            timeRemaining     = workMinutes * 60
            startTime         = Date()            // 新しい開始時刻
            isSessionFinished = false             // フラグをクリア
        } else if startTime == nil {
            // 初回起動やリセット時
            timeRemaining = (isWorkSession ? workMinutes : breakMinutes) * 60
            startTime     = Date()
        }
        // それ以外 (= ポーズ再開) は timeRemaining や startTime を触らない

        // 3) 走り出す
        isRunning = true
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

    // プライベート
    private func tick() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            sessionCompleted()
        }
    }

    // 終了
    private func sessionCompleted() {
        stopTimer()

        // 履歴に本フェーズを保存
        if let start = startTime {
            historyVM.add(start: start, end: Date(), phase: isWorkSession ? .focus : .breakTime)
        }

        // フェーズ別後処理
        if isWorkSession {
            finalizeWork()
        } else {
            finalizeBreak()
        }
    }

    // Work終了後に呼ぶまとめ関数
    private func finalizeWork() {
        // バグ対策 -> 0を拾わないようにする
        let rawBreak = breakMinutes
        let safeBreak = max(rawBreak, 3) // 最小でも 3 分に固定
        print("📝 breakMinutes =", rawBreak, "safe =", safeBreak)

        buzz()
        NotificationManager.shared.sendPhaseChangeNotification(for: .breakTime)

        isSessionFinished = true
        isRunning         = false       // ← ボタンは Stop 表示させない
        isWorkSession     = false       // ← ブレイクモードへ

        // 休憩タイマーを“見えないまま”走らせる
        var secondsLeft = breakMinutes * 60  // 表示は更新しない
        print("📝 secondsLeft  =", secondsLeft)
        timer = Timer.scheduledTimer(withTimeInterval: 1.0,
                                    repeats: true) { [weak self] t in
            guard let self else { return }
            secondsLeft -= 1
            if secondsLeft <= 0 {
                t.invalidate()
                self.timer = nil
                self.finalizeBreak()
            }
        }
    }

    // 休憩終了後に呼ぶまとめ関数
    private func finalizeBreak() {
        buzz()
        NotificationManager.shared.sendPhaseChangeNotification(for: .focus)

        isSessionFinished = false
        isWorkSession     = true            // 作業モードに戻す
        isRunning         = false           // タイマー停止状態
        timeRemaining     = workMinutes * 60
        startTime         = nil
    }

    // ブルッとさせる
    private func buzz(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .heavy) {
        let gen = UIImpactFeedbackGenerator(style: style)
        gen.prepare()
        gen.impactOccurred()
    }

    // コンッとさせる
    // private func buzz(_ type: UINotificationFeedbackGenerator.FeedbackType = .warning) {
    //     let generator = UINotificationFeedbackGenerator()
    //     generator.prepare()
    //     generator.notificationOccurred(type)
    // }

    // Static helpers
    private static let startFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()
}
