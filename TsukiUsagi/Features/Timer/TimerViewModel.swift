//
//  TimerViewModel.swift
//  TsukiUsagi
//
//  Created by azu-azu on 2025/06/12.
//

import Combine
import Foundation
import SwiftUI
import UIKit

/// Pomodoro ロジックと履歴保存、通知送信を司る ViewModel
final class TimerViewModel: ObservableObject {
    // Published 状態
    @Published var timeRemaining: Int
    @Published var isRunning: Bool = false
    @Published var isWorkSession: Bool = true
    @Published var isSessionFinished = false
    @Published private(set) var startTime: Date?
    @Published private(set) var endTime: Date?
    @Published var flashStars = false
    @Published private(set) var lastBackgroundDate: Date?
    @Published var shouldSuppressAnimation = false
    @Published var shouldSuppressSessionFinishedAnimation = false

    // セッションごとのworkMinutesを保存
    private var sessionWorkMinutes: Int?
    // 実作業秒数
    private var actualWorkedSeconds: Int = 0
    // 最後に再開した時刻
    private var lastResumedTime: Date?

    // User-configurable
    @AppStorage("activityLabel") private var activityLabel: String = "Work"
    @AppStorage("subtitleLabel") private var subtitleLabel: String = ""
    @AppStorage("workMinutes") private var workMinutes: Int = 25
    @AppStorage("breakMinutes") private var breakMinutes: Int = 5

    // 内部
    private var timer: Timer?
    private let historyVM: HistoryViewModel
    // --- 追加: 永続化マネージャ ---
    private let persistenceManager = TimerPersistenceManager()

    // 🔔 START アニメ用トリガー
    let startPulse = PassthroughSubject<Void, Never>()

    // 実際のセッション時間を分で計算
    var actualSessionMinutes: Int {
        guard let start = startTime, let end = endTime else { return 1 }
        let diff = Calendar.current.dateComponents([.minute], from: start, to: end)
        let minutes = diff.minute ?? 0
        return max(minutes, 1)
    }

    var workLengthMinutes: Int { workMinutes }

    // Init
    init(historyVM: HistoryViewModel, activityLabel: String = "Work", subtitleLabel: String = "") {
        self.historyVM = historyVM

        // AppStorage を self にアクセスせず使う方法
        let minutes = UserDefaults.standard.integer(forKey: "workMinutes")
        _timeRemaining = Published(initialValue: minutes > 0 ? minutes * 60 : 25 * 60)

        // プレビュー用の初期値をセット（本番ではデフォルト値）
        self.activityLabel = activityLabel
        self.subtitleLabel = subtitleLabel
    }

    // MARK: - Public API

    /// 設定変更を即反映（STOP中だけ）
    func refreshAfterSettingsChange() {
        guard !isRunning else { return }
        let minutes = isWorkSession ? workMinutes : breakMinutes
        timeRemaining = minutes * 60
    }

    /// タイマー開始
    func startTimer() {
        guard !isRunning else { return }

        stopTimer()

        // ★ ここで必ず初期化する
        startTime = nil
        endTime = nil

        // 新しいセッション開始
        if isSessionFinished {
            isWorkSession = true
            // セッション開始時のworkMinutesを保存
            sessionWorkMinutes = workMinutes
            timeRemaining = workMinutes * 60
            startTime = Date()
            endTime = nil
            isSessionFinished = false
            actualWorkedSeconds = 0
            lastResumedTime = Date()
        } else if startTime == nil {
            // セッション初回開始
            let minutes = isWorkSession ? workMinutes : breakMinutes
            sessionWorkMinutes = isWorkSession ? workMinutes : breakMinutes
            timeRemaining = minutes * 60
            startTime = Date()
            endTime = nil
            actualWorkedSeconds = 0
            lastResumedTime = Date()
        } else {
            // ポーズ再開
            resumeTimer()
            return
        }

        // 3) 走り出す
        triggerStartAnimations()
        shouldSuppressAnimation = false

        startTimerInternal()
    }

    /// タイマー再開
    func resumeTimer() {
        guard !isRunning else { return }
        guard lastResumedTime == nil else { return } // すでに再開中なら何もしない

        // diamondアニメーション発火を追加
        triggerStartAnimations()

        lastResumedTime = Date()
        isRunning = true
        startTimerInternal()
    }

    /// タイマー一時停止
    func pauseTimer() {
        guard isRunning else { return }
        if let resumedAt = lastResumedTime {
            actualWorkedSeconds += Int(Date().timeIntervalSince(resumedAt))
            lastResumedTime = nil
        }
        stopTimer()
    }

    /// タイマー停止
    func stopTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        // Pause相当の処理
        if let resumedAt = lastResumedTime {
            actualWorkedSeconds += Int(Date().timeIntervalSince(resumedAt))
            lastResumedTime = nil
        }
    }

    /// タイマーリセット
    func resetTimer() {
        stopTimer()
        isRunning = false
        isWorkSession = true
        let minutes = sessionWorkMinutes ?? workMinutes
        timeRemaining = minutes * 60
        isSessionFinished = false
        startTime = nil
        endTime = nil
        actualWorkedSeconds = 0
        lastResumedTime = nil
    }

    /// 強制終了（Stopボタン用）
    func forceFinishWorkSession() async {
        endTime = Date()
        // ★ startTime が残っているうちに履歴保存
        if let start = startTime, let end = endTime {
            await MainActor.run {
                let parameters = AddSessionParameters(
                    start: start,
                    end: end,
                    phase: .focus,
                    activity: activityLabel,
                    subtitle: subtitleLabel,
                    memo: nil
                )
                historyVM.add(parameters: parameters)
            }
        }
        stopTimer()
        isSessionFinished = true
        isWorkSession = false
    }

    /// 外部からendTimeを更新するためのメソッド
    func setEndTime(_ date: Date) {
        endTime = date
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

    // 公開getter
    public var currentActivityLabel: String { activityLabel }
    public var currentSubtitleLabel: String { subtitleLabel }

    /// タイマー状態を永続化
    @MainActor
    func saveTimerState() {
        persistenceManager.timeRemaining = timeRemaining
        persistenceManager.isRunning = isRunning
        persistenceManager.isWorkSession = isWorkSession
        persistenceManager.saveTimerState()
    }
    /// タイマー状態を復元
    @MainActor
    func restoreTimerState() {
        persistenceManager.restoreTimerState()
        timeRemaining = persistenceManager.timeRemaining
        isRunning = persistenceManager.isRunning
        isWorkSession = persistenceManager.isWorkSession
    }

    // MARK: - Private Methods

    /// タイマーを開始する共通処理
    private func startTimerInternal() {
        isRunning = true
        timer = Timer.scheduledTimer(
            withTimeInterval: 1.0,
            repeats: true
        ) { [weak self] _ in
            Task { await self?.tick() }
        }
    }

    /// タイマー更新処理
    @MainActor
    private func tick() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            Task { [weak self] in await self?.sessionCompleted() }
        }
    }

    /// セッション完了処理
    @MainActor
    private func sessionCompleted(sendNotification: Bool = true) async {
        stopTimer()
        // セッション終了時刻を記録（既にセットされていれば上書きしない）
        if endTime == nil {
            endTime = Date()
        }
        // 最後のPause漏れ対策
        if let resumedAt = lastResumedTime {
            actualWorkedSeconds += Int(endTime!.timeIntervalSince(resumedAt))
            lastResumedTime = nil
        }
        // 履歴に本フェーズを保存
        if let start = startTime, let end = endTime {
            await MainActor.run {
                let parameters = AddSessionParameters(
                    start: start,
                    end: end,
                    phase: isWorkSession ? .focus : .breakTime,
                    activity: activityLabel,
                    subtitle: subtitleLabel,
                    memo: nil
                )
                historyVM.add(parameters: parameters)
            }
        }
        // フェーズ別後処理
        if isWorkSession {
            finalizeWork(sendNotification: sendNotification)
        } else {
            finalizeBreak(sendNotification: sendNotification)
        }
    }

    /// Work終了後に呼ぶまとめ関数
    private func finalizeWork(sendNotification: Bool = true) {
        HapticManager.shared.heavyImpact()
        if sendNotification {
            NotificationManager.shared.sendPhaseChangeNotification(for: .breakTime)
        }

        isSessionFinished = true
        isRunning = false
        isWorkSession = false

        // 休憩タイマーを"見えないまま"走らせる
        var secondsLeft = breakMinutes * 60
        print("📝 secondsLeft  =", secondsLeft)
        timer = Timer.scheduledTimer(
            withTimeInterval: 1.0,
            repeats: true
        ) { [weak self] t in
            guard let self else { return }
            secondsLeft -= 1
            if secondsLeft <= 0 {
                t.invalidate()
                self.timer = nil
                self.finalizeBreak(sendNotification: sendNotification)
            }
        }
    }

    /// 休憩終了後に呼ぶまとめ関数
    private func finalizeBreak(sendNotification: Bool = true) {
        HapticManager.shared.heavyImpact()
        if sendNotification {
            NotificationManager.shared.sendPhaseChangeNotification(for: .focus)
        }
    }

    /// diamondアニメーションとstartPulseアニメーションを発火
    private func triggerStartAnimations() {
        if !shouldSuppressAnimation {
            flashStars.toggle()
            DispatchQueue.main.async {
                self.startPulse.send()
            }
        }
    }

    // MARK: - Background Handling

    /// バックグラウンドへ
    func appDidEnterBackground() {
        lastBackgroundDate = Date()
        if isRunning {
            // Pause相当の処理
            if let resumedAt = lastResumedTime {
                actualWorkedSeconds += Int(Date().timeIntervalSince(resumedAt))
                lastResumedTime = nil
            }
            NotificationManager.shared.scheduleSessionEndNotification(
                after: timeRemaining,
                phase: isWorkSession ? .focus : .breakTime
            )
        }
        stopTimer()
    }

    /// フォアグラウンド復帰
    @MainActor
    func appWillEnterForeground() {
        guard let last = lastBackgroundDate else { return }

        let elapsed = Int(Date().timeIntervalSince(last))
        NotificationManager.shared.cancelSessionEndNotification()
        let originalRemaining = timeRemaining
        timeRemaining = max(originalRemaining - elapsed, 0)
        // 実作業時間に加算
        actualWorkedSeconds += min(elapsed, originalRemaining)

        if timeRemaining <= 0 {
            // 0になった時刻を計算
            let sessionEndDate = last.addingTimeInterval(TimeInterval(originalRemaining))
            endTime = sessionEndDate
            Task { [weak self] in await self?.sessionCompleted(sendNotification: false) }
        } else {
            shouldSuppressAnimation = true
            shouldSuppressSessionFinishedAnimation = true
            resumeTimer()
        }
        lastBackgroundDate = nil
    }
}
