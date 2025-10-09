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
    let engine: TimerEngineable
    let notificationService: PhaseNotificationServiceable
    let hapticService: HapticServiceable
    let historyService: SessionHistoryServiceable
    let persistenceManager: TimerPersistenceManageable
    let formatter: TimeFormatterUtilable
    let dateProvider: DateProviding
    let streakManager: StreakManager

    // MARK: - Managers
    let animationController: any TimerAnimationControllerProtocol
    let statePersistenceManager: TimerStatePersistenceManager
    let notificationAndHapticManager: TimerNotificationAndHapticManager
    let sessionManager: TimerSessionManager
    let stateManager: TimerStateManager
    let displayManager: TimerDisplayManager
    let lifecycleCoordinator: TimerLifecycleCoordinator

    // MARK: - Published Properties (Delegated to Managers)
    @Published var timeRemaining: Int = 0
    @Published var isRunning: Bool = false
    @Published private(set) var runState: TimerRunState = .idle
    @Published var isWorkSession: Bool = true
    @Published var isSessionFinished = false
    @Published var isBackgroundCompleted = false
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
    @AppStorage("breakMinutes") var breakMinutes: Int = 5

    // 🔔 START アニメ用トリガー
    let startPulse = PassthroughSubject<Void, Never>()

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    /// 編集・自然完了いずれでも、開始〜終了の分数を丸め規約に従って算出
    /// 近似規約: 最近接、ちょうど0.5は切り上げ（ties away from zero）
    var actualSessionMinutes: Int {
        guard let start = startTime, let end = endTime else { return 0 }
        let seconds = end.timeIntervalSince(start)
        let minutes = (seconds / 60.0).rounded(.toNearestOrAwayFromZero)
        return max(0, Int(minutes))
    }

    /// Final表示の単一真実源（hasEndTime）
    var hasRecordedEndTime: Bool { endTime != nil }

    /// 未来のFinalかどうか（UIバッジ等で利用）
    var isFutureFinal: Bool {
        guard let end = endTime else { return false }
        return end > dateProvider.now()
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
        self.lifecycleCoordinator = TimerLifecycleCoordinator(
            statePersistenceManager: statePersistenceManager,
            notificationAndHapticManager: notificationAndHapticManager,
            dateProvider: dateProvider,
            sessionManager: sessionManager,
            stateManager: stateManager
        )

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
            concreteController.$shouldSuppressSessionFinishedAnimation
                .assign(to: &$shouldSuppressSessionFinishedAnimation)

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

    // MARK: - Public Methods are implemented in TimerViewModel+SessionControl

    /// 現在のタイマー状態を永続化
    func saveTimerState() {
        statePersistenceManager.saveTimerState(
            timeRemaining: timeRemaining,
            isRunning: isRunning,
            runState: runState,
            isWorkSession: isWorkSession,
            endAt: sessionManager.endAt
        )
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
        // 表示系に最新値を反映
        displayManager.setWorkMinutes(workMinutes)
        displayManager.setBreakMinutes(breakMinutes)

        // アイドル中は即時に残り時間を最新のworkMinutesに合わせる（初回起動直後の変更も含む）
        if runState == .idle && !isRunning && !isSessionFinished {
            stateManager.resetTimer(to: workMinutes * 60)
        }
    }

    /// プレビュー状態を設定（テスト用）
    func _setPreviewState(startTime: Date, isWorkSession: Bool, isRunning: Bool) {
        self.startTime = startTime
        self.isWorkSession = isWorkSession
        self.isRunning = isRunning
    }

    // formatting implemented in extension

    /// アプリがバックグラウンドに移行
    func appDidEnterBackground() {
        saveTimerState()
        let result = lifecycleCoordinator.didEnterBackground(
            timeRemaining: timeRemaining,
            isRunning: isRunning
        )
        lastBackgroundDate = result.lastBackgroundDate
        isBackgroundCompleted = result.isBackgroundCompleted
    }

    /// アプリがフォアグラウンドに復帰
    func appWillEnterForeground() {
        let params = TimerForegroundParams(
            isSessionFinished: isSessionFinished,
            isBackgroundCompleted: isBackgroundCompleted,
            timeRemaining: timeRemaining,
            isRunning: isRunning,
            isWorkSession: isWorkSession,
            startTime: startTime
        )
        lifecycleCoordinator.willEnterForeground(
            params: params
        ) { [weak self] info in
            self?.handleSessionCompleted(info)
        }
    }

    // MARK: - Private Helpers are implemented in TimerViewModel+SessionControl

    // 表示系のフォーマットはUI側で実施
}
