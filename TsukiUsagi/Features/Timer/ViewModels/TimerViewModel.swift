//
//  TimerViewModel.swift
//  TsukiUsagi
//
//  Created by azu-azu on 2025/06/12.
//

import Combine
import SwiftUI
import UIKit
import Foundation

enum TimerRunState: String {
    case idle
    case running
    case paused
}

/// Pomodoro ロジックと履歴保存、通知送信を司る ViewModel
@MainActor
final class TimerViewModel: ObservableObject {

    // MARK: - Dependencies

    private let engine: TimerEngineable
    private let notificationService: PhaseNotificationServiceable
    private let hapticService: HapticServiceable
    private let historyService: SessionHistoryServiceable
    private let persistenceManager: TimerPersistenceManageable
    private let formatter: TimeFormatterUtilable
    private let dateProvider: DateProviding
    private let streakManager: StreakManager

    // MARK: - Managers

    private let animationController: any TimerAnimationControllerProtocol
    private let statePersistenceManager: TimerStatePersistenceManager
    private let notificationAndHapticManager: TimerNotificationAndHapticManager
    private let sessionManager: TimerSessionManager
    private let stateManager: TimerStateManager
    private let displayManager: TimerDisplayManager

    // MARK: - Published Properties (Delegated to Managers)

    @Published var timeRemaining: Int = 0
    @Published var isRunning: Bool = false
    @Published private(set) var runState: TimerRunState = .idle
    @Published var isWorkSession: Bool = true
    @Published var isSessionFinished = false
    @Published private(set) var startTime: Date?
    @Published private(set) var endTime: Date?
    @Published var flashStars = false
    @Published private(set) var lastBackgroundDate: Date?
    @Published var shouldSuppressAnimation = false
    @Published var shouldSuppressSessionFinishedAnimation = false

    // User-configurable
    @AppStorage("activityLabel") var activityLabel: String = "Work"
    @AppStorage("subtitleLabel") var subtitleLabel: String = ""
    @AppStorage("workMinutes") var workMinutes: Int = 25
    @AppStorage("breakMinutes") private var breakMinutes: Int = 5

    // 🔔 START アニメ用トリガー
    let startPulse = PassthroughSubject<Void, Never>()
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    var actualSessionMinutes: Int {
        guard let start = startTime, let end = endTime else { return 1 }
        let diff = Calendar.current.dateComponents([.minute], from: start, to: end)
        let minutes = diff.minute ?? 0
        return max(minutes, 1)
    }

    var workLengthMinutes: Int { workMinutes }

    var canForceFinish: Bool {
        isWorkSession && startTime != nil
    }

    // MARK: - Initialization

    init(
        engine: TimerEngineable,
        notificationService: PhaseNotificationServiceable,
        hapticService: HapticServiceable,
        historyService: SessionHistoryServiceable,
        persistenceManager: TimerPersistenceManageable,
        formatter: TimeFormatterUtilable,
        streakManager: StreakManager = StreakManager(),
        dateProvider: DateProviding = SystemDateProvider(),
        animationController: (any TimerAnimationControllerProtocol)? = nil
    ) {
        self.engine = engine
        self.notificationService = notificationService
        self.hapticService = hapticService
        self.formatter = formatter
        self.historyService = historyService
        self.persistenceManager = persistenceManager
        self.streakManager = streakManager
        self.dateProvider = dateProvider

        // Initialize managers
        self.animationController = animationController ?? TimerAnimationController(hapticService: hapticService)
        self.statePersistenceManager = TimerStatePersistenceManager(
            persistenceManager: persistenceManager,
            dateProvider: dateProvider
        )
        self.notificationAndHapticManager = TimerNotificationAndHapticManager(
            notificationService: notificationService,
            hapticService: hapticService
        )
        self.sessionManager = TimerSessionManager(
            historyService: historyService,
            streakManager: streakManager,
            dateProvider: dateProvider
        )
        self.stateManager = TimerStateManager(
            engine: engine,
            formatter: formatter,
            dateProvider: dateProvider,
            defaultWorkMinutes: 25 // デフォルト値を使用
        )
        self.displayManager = TimerDisplayManager(formatter: formatter)

        setupBindings()
        setupEngineCallbacks()
        
        // 設定済みの作業時間でPersistenceManagerとStateManagerを初期化
        persistenceManager.initializeWithWorkMinutes(workMinutes)
        stateManager.initializeWithWorkMinutes(workMinutes)
    }

    // MARK: - Setup Methods

    private func setupBindings() {
        // Bind to state manager
        stateManager.$timeRemaining.assign(to: &$timeRemaining)
        stateManager.$isRunning.assign(to: &$isRunning)
        stateManager.$runState.assign(to: &$runState)
        stateManager.$isWorkSession.assign(to: &$isWorkSession)
        stateManager.$isSessionFinished.assign(to: &$isSessionFinished)

        // Bind to session manager
        sessionManager.$startTime.assign(to: &$startTime)
        sessionManager.$endTime.assign(to: &$endTime)

        // Bind to animation controller (cast to concrete type to access @Published properties)
        if let concreteController = animationController as? TimerAnimationController {
            concreteController.$flashStars.assign(to: &$flashStars)
            concreteController.$shouldSuppressAnimation.assign(to: &$shouldSuppressAnimation)
            concreteController.$shouldSuppressSessionFinishedAnimation.assign(to: &$shouldSuppressSessionFinishedAnimation)
            
            // Sync startPulse from animation controller to TimerViewModel
            concreteController.startPulse.subscribe(startPulse).store(in: &cancellables)
        }
    }

    private func setupEngineCallbacks() {
        engine.onTick = { [weak self] seconds in
            self?.stateManager.timeRemaining = seconds
        }

        engine.onSessionCompleted = { [weak self] sessionInfo in
            self?.handleSessionCompleted(sessionInfo)
        }
    }

    // MARK: - Public Methods

    /// タイマー開始
    func startTimer() {
        // quiet moon画面からのstart時は、時間を設定してから開始
        let targetTime = isSessionFinished ? workLengthMinutes * 60 : timeRemaining
        
        guard targetTime > 0 else { return }

        sessionManager.startSession(
            isWorkSession: isWorkSession,
            activityLabel: activityLabel,
            subtitleLabel: subtitleLabel
        )

        // 時間を設定してからstartTimerを呼ぶ
        stateManager.timeRemaining = targetTime
        // quiet moon画面からのstart時は、isWorkSessionをtrueに設定
        if isSessionFinished {
            stateManager.isWorkSession = true
        }
        stateManager.startTimer()
        animationController.triggerStartAnimations()
        notificationAndHapticManager.sendStartNotification()

        // Send start pulse
        startPulse.send()
    }

    /// タイマー一時停止
    func pauseTimer() {
        stateManager.pauseTimer()
        notificationAndHapticManager.triggerLightHaptic()
    }

    /// タイマー再開
    func resumeTimer() {
        stateManager.resumeTimer()
        animationController.triggerStartAnimations()
        notificationAndHapticManager.sendStartNotification()
    }

    /// タイマー停止（完全停止 - セッションリセット）
    func stopTimer() {
        stateManager.stopTimer()
        sessionManager.resetSession()
    }

    /// タイマーリセット
    func resetTimer(to seconds: Int) {
        stateManager.resetTimer(to: seconds)
        sessionManager.resetSession()
        animationController.resetAnimationState()
    }
    
    /// タイマーのみリセット（セッション情報は保持）
    func resetTimerOnly(to seconds: Int) {
        stateManager.resetTimer(to: seconds)
        animationController.resetAnimationState()
    }

    /// セッション完了処理
    func handleSessionCompleted(_ sessionInfo: TimerSessionInfo) {
        sessionManager.completeSession(
            isWorkSession: isWorkSession,
            activityLabel: activityLabel,
            subtitleLabel: subtitleLabel
        )

        stateManager.handleSessionCompleted(sessionInfo)
        animationController.triggerSessionFinishedAnimations()
        notificationAndHapticManager.triggerHeavyHaptic()
        
        // セッション終了通知を送信
        if isWorkSession {
            notificationService.finalizeWorkPhase()
        } else {
            notificationService.finalizeBreakPhase()
        }
    }

    /// 強制終了
    func forceFinish() {
        guard canForceFinish else { return }

        sessionManager.completeSession(
            isWorkSession: isWorkSession,
            activityLabel: activityLabel,
            subtitleLabel: subtitleLabel
        )

        stateManager.stopTimer()
        stateManager.setSessionFinished(true) // セッション完了状態を設定
        stateManager.setWorkSession(false) // 作業セッションを終了
        animationController.triggerSessionFinishedAnimations()
        notificationAndHapticManager.triggerHeavyHaptic()
    }

    /// セッション完了状態をリセット
    func resetSessionFinished() {
        stateManager.resetSessionFinished()
    }

    /// タイマー状態を保存
    func saveTimerState() {
        statePersistenceManager.saveTimerState(
            timeRemaining: timeRemaining,
            isRunning: isRunning,
            runState: runState,
            isWorkSession: isWorkSession,
            endAt: sessionManager.endAt
        )
    }

    /// タイマー状態を復元
    func restoreTimerState() {
        // タイマーが実行中の場合は復元しない
        if isRunning {
            return
        }
        
        let result = statePersistenceManager.restoreTimerState()

        switch result {
        case .success(let timeRemaining, let isRunning, let runState, let isWorkSession, let endAt):
            stateManager.restoreState(
                timeRemaining: timeRemaining,
                isRunning: isRunning,
                runState: runState,
                isWorkSession: isWorkSession
            )

            if let endAt = endAt {
                sessionManager.setEndAt(endAt)
            }

        case .failed:
            // 復元失敗時はデフォルト状態
            stateManager.resetTimer(to: workMinutes * 60)

        case .noData:
            // データがない場合は何もしない
            break
        }
    }

    /// 復元が必要かどうかを判定
    func shouldRestore() -> Bool {
        return statePersistenceManager.shouldRestore()
    }

    /// 復元後の自動再開が必要かどうかを判定
    func shouldAutoResume() -> Bool {
        return statePersistenceManager.shouldAutoResume()
    }

    /// 永続化から復元後、必要なら残り秒数でエンジンを再開
    func startFromRestoredIfNeeded() {
        guard runState == .running, timeRemaining > 0 else { return }

        let now = dateProvider.now()
        if let endAt = sessionManager.endAt, endAt > now {
            let remaining = max(0, Int(ceil(endAt.timeIntervalSince(now))))
            if remaining > 0 {
                stateManager.timeRemaining = remaining
                stateManager.startTimer()
            }
        }
    }

    /// アプリがバックグラウンドに移行
    func applicationDidEnterBackground() {
        lastBackgroundDate = dateProvider.now()
        saveTimerState()
    }

    /// アプリがフォアグラウンドに復帰
    func applicationWillEnterForeground() {
        if shouldRestore() {
            restoreTimerState()
            if shouldAutoResume() {
                startFromRestoredIfNeeded()
            }
        }
    }

    /// アニメーション抑制を設定
    func setAnimationSuppression(_ suppress: Bool) {
        animationController.setAnimationSuppression(suppress)
        notificationAndHapticManager.setAnimationSuppression(suppress)
    }

    /// セッション完了アニメーション抑制を設定
    func setSessionFinishedAnimationSuppression(_ suppress: Bool) {
        animationController.setSessionFinishedAnimationSuppression(suppress)
        notificationAndHapticManager.setSessionFinishedAnimationSuppression(suppress)
    }

    /// 設定変更後のリフレッシュ
    func refreshAfterSettingsChange() {
        // 設定変更後の処理（必要に応じて実装）
        // 現在は空の実装
    }

    /// プレビュー状態を設定（テスト用）
    func _setPreviewState(startTime: Date, isWorkSession: Bool, isRunning: Bool) {
        self.startTime = startTime
        self.isWorkSession = isWorkSession
        self.isRunning = isRunning
    }

    /// 時間表示文字列を取得
    func formatTime(_ seconds: Int) -> String {
        return displayManager.timeDisplayString(for: seconds)
    }

    /// アプリがバックグラウンドに移行
    func appDidEnterBackground() {
        applicationDidEnterBackground()
    }

    /// アプリがフォアグラウンドに復帰
    func appWillEnterForeground() {
        applicationWillEnterForeground()
    }

    /// 終了時刻を設定
    func setEndTime(_ endTime: Date?) {
        sessionManager.setEndAt(endTime)
    }

    /// 作業セッションを強制終了
    func forceFinishWorkSession() {
        forceFinish()
    }

    /// 開始時刻のフォーマット済み文字列
    var formattedStartTime: String {
        guard let startTime = startTime else { return "" }
        return TimeFormatters.formatTime(date: startTime)
    }

    /// 終了時刻のフォーマット済み文字列
    var formattedEndTime: String {
        guard let endTime = endTime else { return "" }
        return TimeFormatters.formatTime(date: endTime)
    }
}
