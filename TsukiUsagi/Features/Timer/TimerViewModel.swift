//
//  TimerViewModel.swift
//  TsukiUsagi
//
//  Created by azu-azu on 2025/06/12.
//

import Combine
import SwiftUI
import UIKit

// 1. 各Serviceable/Engineableのimport
import Foundation

/// Pomodoro ロジックと履歴保存、通知送信を司る ViewModel
final class TimerViewModel: ObservableObject {
    // 2. DIプロパティ
    private let engine: TimerEngineable
    private let notificationService: PhaseNotificationServiceable
    private let hapticService: HapticServiceable
    private let historyService: SessionHistoryServiceable
    private let persistenceManager: TimerPersistenceManageable
    private let formatter: TimeFormatterUtilable

    // 3. @PublishedなどUIバインディング用プロパティ
    @Published var timeRemaining: Int = 0
    @Published var isRunning: Bool = false
    @Published var isWorkSession: Bool = true
    @Published var isSessionFinished = false
    @Published private(set) var startTime: Date?
    @Published private(set) var endTime: Date?
    @Published var flashStars = false
    @Published private(set) var lastBackgroundDate: Date?
    @Published var shouldSuppressAnimation = false
    @Published var shouldSuppressSessionFinishedAnimation = false

    // User-configurable
    @AppStorage("activityLabel") private var activityLabel: String = "Work"
    @AppStorage("subtitleLabel") private var subtitleLabel: String = ""
    @AppStorage("workMinutes") private var workMinutes: Int = 25
    @AppStorage("breakMinutes") private var breakMinutes: Int = 5

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

    // 4. DIイニシャライザ
    init(
        engine: TimerEngineable,
        notificationService: PhaseNotificationServiceable,
        hapticService: HapticServiceable,
        historyService: SessionHistoryServiceable,
        persistenceManager: TimerPersistenceManageable,
        formatter: TimeFormatterUtilable
    ) {
        self.engine = engine
        self.notificationService = notificationService
        self.hapticService = hapticService
        self.historyService = historyService
        self.persistenceManager = persistenceManager
        self.formatter = formatter

        // 5. EngineのonTickでViewModelのtimeRemainingを更新
        self.engine.onTick = { [weak self] seconds in
            DispatchQueue.main.async {
                self?.timeRemaining = seconds
            }
        }

        // 6. EngineのonSessionCompletedでセッション完了処理
        self.engine.onSessionCompleted = { [weak self] sessionInfo in
            Task { @MainActor in
                await self?.handleSessionCompleted(sessionInfo)
            }
        }
    }

    // MARK: - Public API

    /// 設定変更を即反映（STOP中だけ）
    func refreshAfterSettingsChange() {
        guard !isRunning else { return }
        let minutes = isWorkSession ? workMinutes : breakMinutes
        timeRemaining = minutes * 60
    }

    // 6. タイマー制御はengine経由
    @MainActor
    func startTimer(seconds: Int) async {
        await engine.start(seconds: seconds)
        isRunning = engine.isRunning
    }
    func pauseTimer() {
        engine.pause()
        isRunning = engine.isRunning
    }
    func resumeTimer() {
        engine.resume()
        isRunning = engine.isRunning
    }
    func stopTimer() {
        engine.stop()
        isRunning = engine.isRunning
    }
    func resetTimer(to seconds: Int) {
        engine.reset(to: seconds)
        isRunning = engine.isRunning
    }

    /// タイマーリセット
    func resetTimer() {
        stopTimer()
        isRunning = false
        isWorkSession = true
        timeRemaining = workMinutes * 60
        isSessionFinished = false
        startTime = nil
        endTime = nil
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
                historyService.add(parameters: parameters)
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

    // 7. 通知・ハプティック・履歴保存・フォーマットもServiceable経由
    func sendStartNotification() {
        notificationService.sendStartNotification()
    }
    func triggerHeavyHaptic() {
        hapticService.heavyImpact()
    }
    func addSessionHistory(parameters: AddSessionParameters) {
        historyService.add(parameters: parameters)
    }
    func formatTime(_ seconds: Int) -> String {
        formatter.format(seconds: seconds)
    }
    func formatDate(_ date: Date?) -> String {
        formatter.format(date: date)
    }

    // プライベート
    private func formatTime(_ date: Date?) -> String {
        formatter.format(date: date)
    }

    var formattedStartTime: String { formatDate(startTime) }
    var formattedEndTime: String { formatDate(endTime) }

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

    /// セッション完了時の処理（Engineコールバックから呼ばれる）
    @MainActor
    private func handleSessionCompleted(_ sessionInfo: TimerSessionInfo) async {
        // UI状態更新
        startTime = sessionInfo.startTime
        endTime = sessionInfo.endTime
        isSessionFinished = true
        isRunning = false

        // 履歴保存
        let parameters = AddSessionParameters(
            start: sessionInfo.startTime,
            end: sessionInfo.endTime,
            phase: sessionInfo.phase == .focus ? .focus : .breakTime,
            activity: activityLabel,
            subtitle: subtitleLabel,
            memo: nil
        )
        historyService.add(parameters: parameters)

        // フェーズ別後処理
        if sessionInfo.phase == .focus {
            notificationService.finalizeWorkPhase()
            isWorkSession = false
        } else {
            notificationService.finalizeBreakPhase()
            isWorkSession = true
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
            notificationService.scheduleSessionEndNotification(
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
        notificationService.cancelSessionEndNotification()
        let originalRemaining = timeRemaining
        timeRemaining = max(originalRemaining - elapsed, 0)

        if timeRemaining <= 0 {
            // 0になった時刻を計算
            let sessionEndDate = last.addingTimeInterval(TimeInterval(originalRemaining))
            endTime = sessionEndDate
            // セッション完了処理はEngineのコールバックで行われる
        } else {
            shouldSuppressAnimation = true
            shouldSuppressSessionFinishedAnimation = true
            resumeTimer()
        }
        lastBackgroundDate = nil
    }
}
