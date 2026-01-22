//
//  TimerViewModel.swift
//  TsukiUsagi
//
//  Created by azu-azu on 2025/06/12.
//

import Combine
import SwiftUI
import UIKit

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
    @Published var runState: TimerRunState = .idle
    @Published var isWorkSession: Bool = true
    @Published var isSessionFinished = false
    @Published var isBackgroundCompleted = false
    @Published private(set) var startTime: Date?
    @Published var endTime: Date?
    @Published var flashStars = false
    @Published var lastBackgroundDate: Date?
    @Published var shouldSuppressAnimation = false
    @Published var shouldSuppressSessionFinishedAnimation = false
    @Published private(set) var quietMoonMessage: MoonMessageEntry?

    // MARK: - Session Management
    @Published var sessionId: UUID = UUID()

    func assignQuietMoonMessageIfNeeded() {
        guard quietMoonMessage == nil else { return }
        quietMoonMessage = MoonMessage.random()
    }

    func clearQuietMoonMessage() {
        quietMoonMessage = nil
    }

    // User-configurable
    @AppStorage("activityLabel") var activityLabel: String = "Work"
    @AppStorage("taskLabel") var taskLabel: String = ""
    @AppStorage("workMinutes") var workMinutes: Int = 25
    @AppStorage("breakMinutes") var breakMinutes: Int = 5

    // 🔔 START アニメ用トリガー
    let startPulse = PassthroughSubject<Void, Never>()

    // MARK: - Private Properties
    var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties
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
        // quiet moon では「リセットできる」が正解
        // 進行中の"強制終了"は従来通り Work のみ許可
        isSessionFinished || (isWorkSession && startTime != nil && !isSessionFinished)
    }

    /// Reset Timerボタン用：quiet moon状態でも有効（新しいセッション開始のため）
    var canResetNow: Bool {
        isSessionFinished || startTime != nil
    }

    /// Stop (Save)ボタン用：進行中のみ有効（すでに完了済みでは意味がない）
    var canStopNow: Bool {
        startTime != nil && !isSessionFinished
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
            concreteController.startPulse
                .sink { [weak self] _ in
                    self?.startPulse.send()
                }
                .store(in: &cancellables)
        }
    }

    /// アニメーション購読を再確立（performCompleteStateReset後用）
    ///
    /// `performCompleteStateReset()`で`cancellables.removeAll()`により
    /// 購読が解除された後、必要な購読を復元するために使用
    func reestablishBindings() {
        // stateManagerの購読を再確立（performCompleteStateResetで削除されたため）
        stateManager.$timeRemaining.assign(to: &$timeRemaining)
        stateManager.$isRunning.assign(to: &$isRunning)
        stateManager.$runState.assign(to: &$runState)
        stateManager.$isWorkSession.assign(to: &$isWorkSession)
        stateManager.$isSessionFinished.assign(to: &$isSessionFinished)

        // sessionManagerの購読を再確立
        sessionManager.$startTime.assign(to: &$startTime)
        sessionManager.$endTime.assign(to: &$endTime)

        // アニメーション購読を再確立
        guard let controller = animationController as? TimerAnimationController else { return }
        // startPulse を ViewModel 側に橋渡し
        controller.startPulse
            .sink { [weak self] _ in
                self?.startPulse.send()
            }
            .store(in: &cancellables)

        controller.$flashStars.assign(to: &$flashStars)
        controller.$shouldSuppressAnimation.assign(to: &$shouldSuppressAnimation)
        controller.$shouldSuppressSessionFinishedAnimation
            .assign(to: &$shouldSuppressSessionFinishedAnimation)
    }

    private func setupEngineCallbacks() {
        engine.onTick = { [weak self] seconds in
            self?.stateManager.timeRemaining = seconds
        }

        engine.onSessionCompleted = { [weak self] sessionInfo in
            Task { @MainActor [weak self] in
                await self?.handleSessionCompleted(sessionInfo)
            }
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

    /// セッション完了アニメーション抑制フラグをクリア（View用）
    /// animationControllerが管理元のため、直接プロパティを変更せずこのメソッドを使用
    func clearSessionFinishedAnimationSuppression() {
        animationController.setSessionFinishedAnimationSuppression(false)
        notificationAndHapticManager.setSessionFinishedAnimationSuppression(false)
    }

    /// 星点滅フラグをクリア（View用）
    /// animationControllerが管理元のため、直接プロパティを変更せずこのメソッドを使用
    func clearFlashStars() {
        animationController.resetAnimationState()
    }

    /// 設定変更後のリフレッシュ
    func refreshAfterSettingsChange() {
        Task { await send(.settingsChanged) }
    }

    /// プレビュー状態を設定（テスト用）
    func _setPreviewState(startTime: Date, isWorkSession: Bool, isRunning: Bool) {
        // sessionManagerに設定（バインディング経由でself.startTimeも更新される）
        sessionManager._setPreviewStartTime(startTime)
        self.isWorkSession = isWorkSession
        self.isRunning = isRunning
    }

    // formatting implemented in extension

    /// アプリがバックグラウンドに移行
    func appDidEnterBackground() {
        Task { await send(.appDidEnterBackground) }
    }

    /// アプリがフォアグラウンドに復帰
    func appWillEnterForeground() {
        Task { await send(.appWillEnterForeground) }
    }

    // MARK: - Private Helpers are implemented in TimerViewModel+SessionControl

    // 表示系のフォーマットはUI側で実施
}
