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
    @Published var timeRemaining: Int        // 残り秒
    @Published var isRunning:     Bool     = false      // 走っているか
    @Published var isWorkSession: Bool     = true       // true = focus, false = break
    @Published var isSessionFinished       = false      // 終了フラグ（View 切替に使用）
    @Published private(set) var startTime: Date?        // セッション開始時刻
    @Published private(set) var endTime: Date?          // セッション終了時刻
    @Published var flashStars = false
    @Published private(set) var lastBackgroundDate: Date? = nil
    private var wasRunningBeforeBackground = false
    private var savedRemainingSeconds: Int? = nil

    // アプリに戻ってきた時にstartアニメを発火しない
    private var shouldSuppressAnimation = false
    @Published var shouldSuppressSessionFinishedAnimation = false

    var workLengthMinutes: Int { workMinutes }

    // 実際のセッション時間を分で計算
    var actualSessionMinutes: Int {
        guard let start = startTime else { return workMinutes }

        let endTime = self.endTime ?? Date()
        let duration = endTime.timeIntervalSince(start)
        return max(Int(duration) / 60, 1) // 最低1分
    }

    // User-configurable
    @AppStorage("activityLabel") private var activityLabel: String = "Work"
    @AppStorage("detailLabel")   private var detailLabel:   String = ""
    @AppStorage("workMinutes")  private var workMinutes:  Int = 25
    @AppStorage("breakMinutes") private var breakMinutes: Int = 5 {
        didSet {
            if breakMinutes < 1 {
                breakMinutes = 1 // ← ここで保証！
            }
        }
    }

    // --- Persistent timer state for background/kill recovery ---
    private enum TimerPersistKeys {
        static let remainingSeconds = "remainingSeconds"
        static let isRunning        = "isRunning"
        static let backgroundTimestamp = "backgroundTimestamp"
        static let isWorkSession    = "isWorkSession"
    }

    @AppStorage(TimerPersistKeys.remainingSeconds) private var storedRemainingSeconds: Int = 0
    @AppStorage(TimerPersistKeys.isRunning)        private var storedIsRunning: Bool = false
    @AppStorage(TimerPersistKeys.backgroundTimestamp) private var storedBackgroundTimestamp: Double = 0
    @AppStorage(TimerPersistKeys.isWorkSession)    private var storedIsWorkSession: Bool = true

    /// 設定変更を即反映（STOP中だけ）
    func refreshAfterSettingsChange() {
        guard !isRunning else { return }
        let minutes = isWorkSession ? workMinutes : breakMinutes
        timeRemaining = minutes * 60
    }

    // 内部
    private var timer: Timer?
    private let historyVM: HistoryViewModel

    // 🔔 START アニメ用トリガー
    let startPulse = PassthroughSubject<Void, Never>()

    // MARK: - State Persistence
    func saveTimerState() {
        storedRemainingSeconds = timeRemaining
        storedIsRunning        = isRunning
        storedBackgroundTimestamp = Date().timeIntervalSince1970
        storedIsWorkSession    = isWorkSession
    }

    func restoreTimerState() {
        guard storedIsRunning else { return }
        let elapsed = Int(Date().timeIntervalSince1970 - storedBackgroundTimestamp)
        let left = max(storedRemainingSeconds - elapsed, 0)
        isWorkSession = storedIsWorkSession
        timeRemaining = left
        isRunning = left > 0
        if left == 0 {
            // セッション完了処理を即実行（UI固まり防止）
            sessionCompleted()
        }
    }

    // Init
    init(historyVM: HistoryViewModel) {
        self.historyVM = historyVM

        // AppStorage を self にアクセスせず使う方法
        let minutes = UserDefaults.standard.integer(forKey: "workMinutes")
        _timeRemaining = Published(initialValue: minutes > 0 ? minutes * 60 : 25 * 60)

        // --- Restore timer state if needed ---
        restoreTimerState()
    }

    // 公開 API
    func startTimer() {
        guard !isRunning else { return }

        stopTimer()

        // 2) これは「新しいセッション」か？ (= 最後のセッションが完了しているか)
        if isSessionFinished {
            isWorkSession     = true
            timeRemaining     = workMinutes * 60
            startTime         = Date()
            endTime           = nil
            isSessionFinished = false
        } else if startTime == nil {
            timeRemaining = (isWorkSession ? workMinutes : breakMinutes) * 60
            startTime     = Date()
            endTime       = nil
        }
        // それ以外 (= ポーズ再開) は timeRemaining や startTime を触らない

        // 3) 走り出す
        if !shouldSuppressAnimation {
            flashStars.toggle()
            DispatchQueue.main.async {
                self.startPulse.send()
            }
        }
        shouldSuppressAnimation = false

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
        // ここで必ず Work セッションに戻す
        isWorkSession = true

        // Work のデフォルト時間にリセット
        timeRemaining     = workMinutes * 60
        isSessionFinished = false
        startTime         = nil
        endTime           = nil
    }

    // Stopボタン用：work終了→break画面へ
    func forceFinishWorkSession() {
        stopTimer()
        endTime = Date()
        isSessionFinished = true
        isWorkSession = false
    }

    /// "MM:SS" 表示用
    func formatTime() -> String {
        TimeFormatters.formatTime(seconds: timeRemaining)
    }

    // プライベート
    private func formatTime(_ date: Date?) -> String {
        TimeFormatters.formatTime(date: date)
    }

    var formattedStartTime: String { formatTime(startTime) }
    var formattedEndTime: String { formatTime(endTime) }

    // プライベート
    private func tick() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            sessionCompleted()
        }
    }

    // 終了
    private func sessionCompleted(sendNotification: Bool = true) {
        stopTimer()

        // セッション終了時刻を記録（既にセットされていれば上書きしない）
        if endTime == nil {
            endTime = Date()
        }

        // 履歴に本フェーズを保存
        if let start = startTime, let end = endTime {
            historyVM.add(
                start:    start,
                end:      end,
                phase:    isWorkSession ? .focus : .breakTime,
                activity: activityLabel,
                detail:   detailLabel,
                memo:     nil
            )
        }

        // フェーズ別後処理
        if isWorkSession {
            finalizeWork(sendNotification: sendNotification)
        } else {
            finalizeBreak(sendNotification: sendNotification)
        }
    }

    // Work終了後に呼ぶまとめ関数
    private func finalizeWork(sendNotification: Bool = true) {
        buzz()
        if sendNotification {
            NotificationManager.shared.sendPhaseChangeNotification(for: .breakTime)
        }

        isSessionFinished = true
        isRunning         = false       // ← ボタンは Stop 表示させない
        isWorkSession     = false       // ← ブレイクモードへ

        // 休憩タイマーを"見えないまま"走らせる
        var secondsLeft = breakMinutes * 60  // 表示は更新しない
        print("📝 secondsLeft  =", secondsLeft)
        timer = Timer.scheduledTimer(withTimeInterval: 1.0,
                                    repeats: true) { [weak self] t in
            guard let self else { return }
            secondsLeft -= 1
            if secondsLeft <= 0 {
                t.invalidate()
                self.timer = nil
                self.finalizeBreak(sendNotification: sendNotification)
            }
        }
    }

    // 休憩終了後に呼ぶまとめ関数
    private func finalizeBreak(sendNotification: Bool = true) {
        buzz()
        if sendNotification {
            NotificationManager.shared.sendPhaseChangeNotification(for: .focus)
        }
        // 状態は何も変更しない
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

    // バックグラウンドへ
    func appDidEnterBackground() {
        wasRunningBeforeBackground = isRunning          // ↙︎ 動いてたか保存
        lastBackgroundDate = Date()
        savedRemainingSeconds = timeRemaining
        if isRunning {
            NotificationManager.shared.scheduleSessionEndNotification(after: timeRemaining, phase: isWorkSession ? .focus : .breakTime)
        }
        stopTimer()                                     // 一旦止める
    }

    // フォアグラウンド復帰
    func appWillEnterForeground() {
        guard let last = lastBackgroundDate,
            wasRunningBeforeBackground else { return }

        let elapsed = Int(Date().timeIntervalSince(last))
        NotificationManager.shared.cancelSessionEndNotification()
        let originalRemaining = savedRemainingSeconds ?? timeRemaining
        timeRemaining = max(originalRemaining - elapsed, 0)

        if timeRemaining <= 0 {
            // 0になった時刻を計算
            let sessionEndDate = last.addingTimeInterval(TimeInterval(originalRemaining))
            endTime = sessionEndDate
            sessionCompleted(sendNotification: false)
        } else {
            shouldSuppressAnimation = true
            shouldSuppressSessionFinishedAnimation = true
            startTimer()
        }
        lastBackgroundDate = nil
        wasRunningBeforeBackground = false
        savedRemainingSeconds = nil
    }
}
