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

enum TimerRunState: String {
    case idle
    case running
    case paused
}

/// Pomodoro ロジックと履歴保存、通知送信を司る ViewModel
@MainActor
final class TimerViewModel: ObservableObject {
    // 2. DIプロパティ
    private let engine: TimerEngineable
    private let notificationService: PhaseNotificationServiceable
    private let hapticService: HapticServiceable
    private let historyService: SessionHistoryServiceable
    private let persistenceManager: TimerPersistenceManageable
    private let formatter: TimeFormatterUtilable
    private let dateProvider: DateProviding

    // Streak tracking - @StateObjectではなく通常のプロパティに変更
    private let streakManager: StreakManager

    // 3. @PublishedなどUIバインディング用プロパティ
    @Published var timeRemaining: Int = 0
    @Published var isRunning: Bool = false
    @Published private(set) var runState: TimerRunState = .idle
    @Published var isWorkSession: Bool = true
    @Published var isSessionFinished = false
    @Published private(set) var startTime: Date?
    @Published private(set) var endTime: Date?
    private var endAt: Date?
    // 復元中ロック（この間は保存/初期化を抑止）
    private var isRestoring = false
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

    // Stopボタンの有効判定
    var canForceFinish: Bool {
        isWorkSession && startTime != nil
    }

    // 4. DIイニシャライザ - StreakManagerもDIで受け取るように変更
    init(
        engine: TimerEngineable,
        notificationService: PhaseNotificationServiceable,
        hapticService: HapticServiceable,
        historyService: SessionHistoryServiceable,
        persistenceManager: TimerPersistenceManageable,
        formatter: TimeFormatterUtilable,
        streakManager: StreakManager = StreakManager(), // デフォルト値を提供
        dateProvider: DateProviding = SystemDateProvider()
    ) {
        // 3. Engine設定
        self.engine = engine
        self.notificationService = notificationService
        self.hapticService = hapticService
        self.formatter = formatter
        self.historyService = historyService
        self.persistenceManager = persistenceManager
        self.streakManager = streakManager
        self.dateProvider = dateProvider

        // 4. Engineのコールバック設定（notificationService初期化後）
        self.engine.onTick = { [weak self] seconds in
            guard let self else { return }
            guard self.runState == .running else { return }
            self.timeRemaining = seconds
        }
        self.engine.onSessionCompleted = { [weak self] sessionInfo in
            guard let self else { return }
            // Ignore delayed completion when not actively running (e.g., after pause/restore)
            guard self.runState == .running else { return }
            self.handleSessionCompleted(sessionInfo)
        }

        // Simulator用：UserDefaultsの初期値を強制設定
        #if targetEnvironment(simulator)
        if UserDefaults.standard.integer(forKey: "workMinutes") == 0 {
            UserDefaults.standard.set(25, forKey: "workMinutes")
        }
        if UserDefaults.standard.integer(forKey: "breakMinutes") == 0 {
            UserDefaults.standard.set(5, forKey: "breakMinutes")
        }
        #endif

        // 最優先で復元し、その結果に応じて初期化/再開を判断
        self.isRestoring = true
        self.restoreTimerState()
        switch self.runState {
        case .running:
            self.shouldSuppressAnimation = true
            self.startFromRestoredIfNeeded()
            // 起動時リカバリ：進行中セッションがあれば通知を再スケジュール
            self.recoverNotificationIfNeeded()
        case .paused:
            // 保持した残り秒数のまま静止。初期化しない
            break
        case .idle:
            // ここでは初期化しない（本当にゼロの判定は restore 側で実施）
            break
        }
        self.isRestoring = false
    }

    // MARK: - Public API

    /// 設定変更を即反映（STOP中だけ）
    func refreshAfterSettingsChange() {
        // Idle かつ復元完了後のみ初期時間を更新（paused は維持）
        guard runState == .idle, !isRestoring else { return }

        let minutes = isWorkSession ? workMinutes : breakMinutes
        let newTimeRemaining = minutes * 60

        timeRemaining = newTimeRemaining
    }

    // 6. タイマー制御はengine経由
    func startTimer(seconds: Int) {
        // If paused, treat start as resume to preserve remaining time
        if runState == .paused, timeRemaining > 0 {
            resumeTimer()
            return
        }
        // セッション完了状態をクリア（重要：これを最初に行う）
        if isSessionFinished {
            isSessionFinished = false
        }

        // timeRemainingが0の場合は設定値で初期化
        let actualSeconds = seconds > 0 ? seconds : workMinutes * 60

        let now = dateProvider.now()
        startTime = now
        isWorkSession = true
        isRunning = true
        timeRemaining = actualSeconds
        endAt = now.addingTimeInterval(TimeInterval(actualSeconds))
        runState = .running

        // アニメーション抑制フラグをリセット
        shouldSuppressAnimation = false

        // MainActorで確実に実行
        Task { @MainActor in
            self.engine.start(seconds: actualSeconds)

            let newIsRunning = self.engine.isRunning
            self.isRunning = newIsRunning

            // アニメーションを発火
            self.triggerStartAnimations()
            // Persist state
            self.saveTimerState()
        }
    }

    func pauseTimer() {
        guard runState == .running else { return }
        // Recompute remaining from endAt for accuracy
        let now = dateProvider.now()
        if let endAt { timeRemaining = max(0, Int(ceil(endAt.timeIntervalSince(now)))) }
        endAt = nil
        engine.pause()
        isRunning = false
        runState = .paused
        // Persist explicit paused snapshot immediately (stronger than generic save)
        persistenceManager.remainingAtPause = timeRemaining
        persistenceManager.runStateRaw = TimerRunState.paused.rawValue
        persistenceManager.endAtEpoch = nil
        saveTimerState()
    }

    func resumeTimer() {
        guard runState == .paused, timeRemaining > 0 else { return }
        let now = dateProvider.now()
        endAt = now.addingTimeInterval(TimeInterval(timeRemaining))
        runState = .running
        isRunning = true
        engine.start(seconds: timeRemaining)
        saveTimerState()
    }

    func stopTimer() {
        engine.stop()
        isRunning = false
        runState = .idle
        endAt = nil
        saveTimerState()
    }

    func resetTimer(to seconds: Int) {
        engine.reset(to: seconds)
        isRunning = engine.isRunning
        runState = .idle
        endAt = nil
        saveTimerState()
    }

    /// タイマーリセット
    func resetTimer() {
        stopTimer()

        // 状態を正しい順序でリセット
        isRunning = false
        isSessionFinished = false  // 先にfalseにする
        isWorkSession = true      // その後でtrueにする
        // Resetは明示操作のみ初期化。pause復帰と混ざらない
        timeRemaining = workMinutes * 60
        startTime = nil
        endTime = nil
    }

    /// 強制終了（Stopボタン用）
    func forceFinishWorkSession() {
        endTime = dateProvider.now()
        // ★ startTime が残っているうちに履歴保存
        if let start = startTime, let end = endTime {
            let parameters = AddSessionParameters(
                start: start,
                end: end,
                phase: .focus,
                activity: activityLabel,
                subtitle: subtitleLabel,
                memo: nil
            )
            historyService.add(parameters: parameters)

            // Record streak for manually finished work session
            streakManager.recordTimerUsage()
        }
        stopTimer()
        isSessionFinished = true
        isWorkSession = false  // QuietMoon表示のために必要
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
    public var currentStreakManager: StreakManager { streakManager }

    /// タイマー状態を永続化
    @MainActor
    func saveTimerState() {
        #if DEBUG
        print("🔍 saveTimerState: 開始 - runState=\(runState), endAt=\(endAt?.description ?? "nil"), timeRemaining=\(timeRemaining)")
        #endif
        
        // 復元中は保存しない：一瞬の初期化値で上書きする事故を防止
        if isRestoring { 
            #if DEBUG
            print("🔍 saveTimerState: 復元中のため保存をスキップ")
            #endif
            return 
        }
        
        persistenceManager.timeRemaining = timeRemaining
        persistenceManager.isRunning = (runState == .running)
        persistenceManager.isWorkSession = isWorkSession
        persistenceManager.runStateRaw = runState.rawValue
        
        #if DEBUG
        print("🔍 saveTimerState: 基本状態保存 - runStateRaw=\(runState.rawValue), isRunning=\(runState == .running)")
        #endif
        
        switch runState {
        case .running:
            if let endAt { 
                persistenceManager.endAtEpoch = endAt.timeIntervalSince1970
                #if DEBUG
                print("🔍 saveTimerState: .running - endAtEpoch=\(endAt.timeIntervalSince1970)")
                #endif
            }
            persistenceManager.remainingAtPause = nil
        case .paused:
            persistenceManager.endAtEpoch = nil
            persistenceManager.remainingAtPause = timeRemaining
            #if DEBUG
            print("🔍 saveTimerState: .paused - remainingAtPause=\(timeRemaining)")
            #endif
        case .idle:
            persistenceManager.endAtEpoch = nil
            persistenceManager.remainingAtPause = nil
            #if DEBUG
            print("🔍 saveTimerState: .idle - 全クリア")
            #endif
        }
        persistenceManager.saveTimerState()
        
        #if DEBUG
        print("🔍 saveTimerState: 完了")
        #endif
    }

    /// タイマー状態を復元
    @MainActor
    func restoreTimerState() {
        print("🔍 restoreTimerState: 開始")
        
        persistenceManager.restoreTimerState()
        isWorkSession = persistenceManager.isWorkSession
        
        print("🔍 restoreTimerState: persistenceManager.runStateRaw=\(persistenceManager.runStateRaw ?? "nil")")
        print("🔍 restoreTimerState: persistenceManager.endAtEpoch=\(persistenceManager.endAtEpoch ?? 0)")
        print("🔍 restoreTimerState: persistenceManager.remainingAtPause=\(persistenceManager.remainingAtPause ?? 0)")
        
        // まず宣言ベースの runState を参照
        var restored = TimerRunState(rawValue: persistenceManager.runStateRaw ?? "")
        print("🔍 restoreTimerState: 宣言ベースの復元=\(restored?.rawValue ?? "nil")")
        
        // フォールバック推定：runState欠損時でも痕跡から推定
        if restored == nil {
            print("🔍 restoreTimerState: フォールバック推定開始")
            if let ts = persistenceManager.endAtEpoch, ts > 0 {
                restored = .running
                print("🔍 restoreTimerState: endAtEpochから.runningに推定")
            } else if let rp = persistenceManager.remainingAtPause, rp > 0 {
                restored = .paused
                print("🔍 restoreTimerState: remainingAtPauseから.pausedに推定")
            } else {
                restored = .idle
                print("🔍 restoreTimerState: .idleに推定")
            }
        }
        let state = restored ?? .idle
        runState = state
        
        print("🔍 restoreTimerState: 最終状態=\(state.rawValue)")
        
        switch state {
        case .running:
            print("🔍 restoreTimerState: .runningケース")
            if let ts = persistenceManager.endAtEpoch {
                let now = dateProvider.now()
                let end = Date(timeIntervalSince1970: ts)
                let remain = max(0, Int(ceil(end.timeIntervalSince(now))))
                print("🔍 restoreTimerState: endAt=\(end), now=\(now), remain=\(remain)")
                
                if remain > 0 {
                    endAt = end
                    timeRemaining = remain
                    isRunning = true
                    print("🔍 restoreTimerState: タイマー復元成功")
                } else {
                    // 時間切れの場合はセッション完了処理を実行
                    print("🔍 restoreTimerState: 時間切れ - セッション完了処理開始")
                    
                    // セッション完了処理
                    endTime = end
                    let wasWorkSession = isWorkSession  // 変更前に保存
                    isSessionFinished = true
                    isWorkSession = false  // QuietMoon表示のために必要
                    
                    // セッション完了時の処理
                    hapticService.heavyImpact()
                    notificationService.finalizeWorkPhase()
                    
                    // 履歴に保存
                    let parameters = AddSessionParameters(
                        start: startTime ?? end,
                        end: end,
                        phase: wasWorkSession ? .focus : .breakTime,
                        activity: activityLabel,
                        subtitle: subtitleLabel,
                        memo: nil
                    )
                    historyService.add(parameters: parameters)
                    
                    // Record streak if this was a work session
                    if wasWorkSession {
                        streakManager.recordTimerUsage()
                    }
                    
                    // State finalize
                    endAt = nil
                    timeRemaining = 0
                    isRunning = false
                    runState = .idle
                    
                    print("🔍 restoreTimerState: セッション完了処理完了 - isSessionFinished=\(isSessionFinished), isWorkSession=\(isWorkSession)")
                }
            } else {
                // Safety: missing endAt
                endAt = nil
                timeRemaining = 0
                isRunning = false
                runState = .idle
                print("🔍 restoreTimerState: endAtEpochがnilで.idleに変更")
            }
        case .paused:
            print("🔍 restoreTimerState: .pausedケース")
            timeRemaining = max(0, persistenceManager.remainingAtPause ?? 0)
            isRunning = false
            endAt = nil
        case .idle:
            print("🔍 restoreTimerState: .idleケース")
            // Only apply defaults when truly zero (no remaining or anchors anywhere)
            let persistedPause = persistenceManager.remainingAtPause ?? 0
            let persistedEndAt = persistenceManager.endAtEpoch ?? 0
            if timeRemaining == 0 && persistedPause == 0 && persistedEndAt == 0 {
                timeRemaining = workMinutes * 60
            }
            isRunning = false
            endAt = nil
        }
        
        print("🔍 restoreTimerState: 完了 - runState=\(runState), endAt=\(endAt?.description ?? "nil"), timeRemaining=\(timeRemaining)")
    }

    /// 永続化から復元後、必要なら残り秒数でエンジンを再開（起動直後や再アクティブ時用）
    @MainActor
    func startFromRestoredIfNeeded() {
        guard runState == .running, timeRemaining > 0 else { return }
        shouldSuppressAnimation = true
        
        // バックグラウンドから復帰した場合は、既にengine.resume()が呼ばれているため
        // ここでは重複起動を避ける
        if !engine.isRunning {
            // Reset engine first to avoid any residual state before starting
            engine.reset(to: timeRemaining)
            engine.start(seconds: timeRemaining)
        }
        isRunning = true
    }
    
    /// 起動時リカバリ：進行中セッションがあれば通知を再スケジュール
    @MainActor
    private func recoverNotificationIfNeeded() {
        guard runState == .running, let endAt = endAt, endAt > dateProvider.now() else { return }
        
        // デバイス再起動後のリカバリ：通知を再スケジュール
        let phase: PomodoroPhase = isWorkSession ? .focus : .breakTime
        let timeSensitive = UserDefaults.standard.bool(forKey: "time_sensitive_notifications_enabled")
        
        notificationService.scheduleSessionEndNotification(
            at: endAt,
            phase: phase,
            timeSensitive: timeSensitive
        )
        
        print("🔔 起動時リカバリ：通知を再スケジュールしました (\(endAt))")
    }

    // MARK: - Private Methods

    /// セッション完了時の処理（Engineコールバックから呼ばれる）
    private func handleSessionCompleted(_ sessionInfo: TimerSessionInfo) {
        // Safety: drop stale completion if we're no longer running
        guard runState == .running else { 
            print("🔍 handleSessionCompleted: runState != .running, skipping")
            return 
        }
        
        print("🔍 handleSessionCompleted: 開始 - runState=\(runState), isSessionFinished=\(isSessionFinished), isWorkSession=\(isWorkSession)")
        
        isRunning = false
        timeRemaining = 0

        // セッション完了状態を設定（順序重要）
        endTime = sessionInfo.endTime
        isSessionFinished = true
        isWorkSession = false  // QuietMoon表示のために必要

        print("🔍 handleSessionCompleted: 状態更新後 - isSessionFinished=\(isSessionFinished), isWorkSession=\(isWorkSession)")

        // セッション完了時の処理
        hapticService.heavyImpact()
        notificationService.finalizeWorkPhase()

        // 履歴に保存
        let parameters = AddSessionParameters(
            start: sessionInfo.startTime,
            end: sessionInfo.endTime,
            phase: sessionInfo.phase == .focus ? .focus : .breakTime,
            activity: activityLabel,
            subtitle: subtitleLabel,
            memo: nil
        )
        historyService.add(parameters: parameters)

        // Record streak if this was a work session
        if sessionInfo.phase == .focus {
            streakManager.recordTimerUsage()
        }

        // State finalize: drop endAt, set idle, persist via ViewModel API
        runState = .idle
        endAt = nil
        saveTimerState()
        
        print("🔍 handleSessionCompleted: 完了 - runState=\(runState), isSessionFinished=\(isSessionFinished), isWorkSession=\(isWorkSession)")
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
        print("🔍 appDidEnterBackground: 開始 - isRunning=\(isRunning), runState=\(runState), endAt=\(endAt?.description ?? "nil")")
        
        lastBackgroundDate = dateProvider.now()
        if isRunning, let endAt = endAt {
            print("🔍 appDidEnterBackground: 実行中タイマーをバックグラウンド処理")
            
            // バックグラウンド移行時はタイマーエンジンを停止
            // ただし、状態はrunningのまま保持（フォアグラウンド復帰時に再開のため）
            engine.pause()
            
            // endAtを保持（TimerEngineのpause()ではendAtがクリアされるため）
            // 現在の残り時間を正確に計算してendAtを更新
            let now = dateProvider.now()
            let actualRemaining = max(0, Int(ceil(endAt.timeIntervalSince(now))))
            print("🔍 appDidEnterBackground: 元endAt=\(endAt), now=\(now), actualRemaining=\(actualRemaining)")
            
            if actualRemaining > 0 {
                self.endAt = now.addingTimeInterval(TimeInterval(actualRemaining))
                print("🔍 appDidEnterBackground: 新しいendAt=\(self.endAt!)")
            }
            
            // Keep running state; schedule a single end notification using absolute time
            let phase: PomodoroPhase = isWorkSession ? .focus : .breakTime
            let timeSensitive = UserDefaults.standard.bool(forKey: "time_sensitive_notifications_enabled")
            
            notificationService.scheduleSessionEndNotification(
                at: self.endAt!,
                phase: phase,
                timeSensitive: timeSensitive
            )
            
            // 状態を保存（endAtを保持）
            saveTimerState()
            print("🔍 appDidEnterBackground: 状態保存完了")
        } else if runState == .paused {
            print("🔍 appDidEnterBackground: ポーズ状態をバックグラウンド処理")
            // Ensure paused remaining is persisted for robust restoration
            persistenceManager.remainingAtPause = timeRemaining
            persistenceManager.runStateRaw = TimerRunState.paused.rawValue
            persistenceManager.endAtEpoch = nil
            saveTimerState()
        } else {
            print("🔍 appDidEnterBackground: その他の状態 - isRunning=\(isRunning), runState=\(runState)")
        }
        
        print("🔍 appDidEnterBackground: 完了")
    }

    /// フォアグラウンド復帰
    @MainActor
    func appWillEnterForeground() {
        print("🔍 appWillEnterForeground: 開始")
        
        // Preserve pre-restore state to guard against mis-inferred idle
        let prevState = runState
        let prevRemaining = timeRemaining
        
        print("🔍 appWillEnterForeground: prevState=\(prevState), prevRemaining=\(prevRemaining)")
        
        // endAtベースで復元し、状態に応じてのみ再開（復元ロック中は保存禁止）
        isRestoring = true
        restoreTimerState()
        notificationService.cancelSessionEndNotification()
        
        print("🔍 appWillEnterForeground: 復元後 runState=\(runState), endAt=\(endAt?.description ?? "nil")")
        
        switch (prevState, runState) {
        case (.running, .running):
            print("🔍 appWillEnterForeground: (.running, .running) ケース")
            shouldSuppressAnimation = true
            shouldSuppressSessionFinishedAnimation = true
            // バックグラウンドから復帰時は、正確な残り時間で再開
            // engine.pause()で停止していたタイマーを正確な残り時間で再開
            if let endAt = endAt {
                let now = dateProvider.now()
                let actualRemaining = max(0, Int(ceil(endAt.timeIntervalSince(now))))
                print("🔍 appWillEnterForeground: endAt=\(endAt), now=\(now), actualRemaining=\(actualRemaining)")
                
                if actualRemaining > 0 {
                    print("🔍 appWillEnterForeground: タイマー再開")
                    timeRemaining = actualRemaining
                    engine.resume()
                } else {
                    print("🔍 appWillEnterForeground: 時間切れ - セッション完了処理開始")
                    // 時間切れの場合はセッション完了処理
                    // runStateを一時的に.runningに設定してhandleSessionCompletedを実行
                    runState = .running
                    handleSessionCompleted(TimerSessionInfo(
                        startTime: startTime ?? now,
                        endTime: endAt,
                        phase: isWorkSession ? .focus : .breakTime,
                        actualWorkedSeconds: 0
                    ))
                    // runStateはhandleSessionCompleted内で.idleに設定される
                    
                    // 状態更新を確実に反映するため、UIの更新を強制
                    DispatchQueue.main.async {
                        // 状態が正しく更新されていることを確認
                        print("🔍 フォアグラウンド復帰時セッション完了: isSessionFinished=\(self.isSessionFinished), isWorkSession=\(self.isWorkSession)")
                    }
                }
            } else {
                print("🔍 appWillEnterForeground: endAtがnil")
            }
        case (.paused, .idle):
            print("🔍 appWillEnterForeground: (.paused, .idle) ケース")
            // Roll back accidental downgrade idle -> keep paused state and remaining seconds
            runState = .paused
            isRunning = false
            let persisted = persistenceManager.remainingAtPause ?? 0
            timeRemaining = max(prevRemaining, persisted)
        case (.paused, .paused):
            print("🔍 appWillEnterForeground: (.paused, .paused) ケース")
            isRunning = false
        default:
            print("🔍 appWillEnterForeground: default ケース")
            isRunning = false
        }
        lastBackgroundDate = nil
        isRestoring = false
        
        print("🔍 appWillEnterForeground: 完了 - runState=\(runState), isSessionFinished=\(isSessionFinished), isWorkSession=\(isWorkSession)")
    }
}

#if DEBUG
extension TimerViewModel {
    func _setPreviewState(startTime: Date?, isWorkSession: Bool, isRunning: Bool) {
        self.startTime = startTime
        self.isWorkSession = isWorkSession
        self.isRunning = isRunning
    }
}
#endif
