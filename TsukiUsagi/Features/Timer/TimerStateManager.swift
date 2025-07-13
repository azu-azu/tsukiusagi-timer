import Combine
import Foundation
import SwiftUI

/// タイマーの状態管理を担当するManager
final class TimerStateManager: ObservableObject {
    @Published var timeRemaining: Int
    @Published var isRunning: Bool = false
    @Published var isWorkSession: Bool = true
    @Published var isSessionFinished = false
    @Published private(set) var startTime: Date?
    @Published private(set) var endTime: Date?

    // セッションごとのworkMinutesを保存
    private var sessionWorkMinutes: Int?
    // 実作業秒数
    private var actualWorkedSeconds: Int = 0
    // 最後に再開した時刻
    private var lastResumedTime: Date?

    // User-configurable
    @AppStorage("workMinutes") private var workMinutes: Int = 25
    @AppStorage("breakMinutes") private var breakMinutes: Int = 5 {
        didSet {
            if breakMinutes < 1 {
                breakMinutes = 1
            }
        }
    }

    // 内部
    private var timer: Timer?

    // 実際のセッション時間を分で計算
    var actualSessionMinutes: Int {
        guard let start = startTime, let end = endTime else { return 1 }
        let diff = Calendar.current.dateComponents([.minute], from: start, to: end)
        let minutes = diff.minute ?? 0
        return max(minutes, 1)
    }

    init() {
        let minutes = UserDefaults.standard.integer(forKey: "workMinutes")
        _timeRemaining = Published(initialValue: minutes > 0 ? minutes * 60 : 25 * 60)
    }

    /// 設定変更を即反映（STOP中だけ）
    func refreshAfterSettingsChange() {
        guard !isRunning else { return }
        let minutes = isWorkSession ? workMinutes : breakMinutes
        timeRemaining = minutes * 60
    }

    /// タイマーを開始する共通処理
    private func startTimerInternal() {
        isRunning = true
        timer = Timer.scheduledTimer(
            withTimeInterval: 1.0,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
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

        startTimerInternal()
    }

    /// タイマー再開
    func resumeTimer() {
        guard !isRunning else { return }
        guard lastResumedTime == nil else { return } // すでに再開中なら何もしない

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

    /// タイマー更新処理
    @MainActor
    private func tick() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        }
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
}
