import Foundation
import SwiftUI

protocol TimerPersistenceManageable: AnyObject {
    // Core persisted values
    var timeRemaining: Int { get set }           // snapshot seconds; used for paused/idle
    var isRunning: Bool { get set }              // legacy flag; derived from runState
    var isWorkSession: Bool { get set }

    // New robust state
    var runStateRaw: String? { get set }         // "idle" | "running" | "paused"
    var endAtEpoch: Double? { get set }          // seconds since 1970 when running
    var remainingAtPause: Int? { get set }       // seconds at pause

    func saveTimerState()
    func restoreTimerState()
    func initializeWithWorkMinutes(_ minutes: Int)
}

/// バックグラウンド対応と状態永続化を担当するManager
final class TimerPersistenceManager: ObservableObject, TimerPersistenceManageable {
    @Published var timeRemaining: Int
    @Published var isRunning: Bool = false
    @Published var isWorkSession: Bool = true
    @Published private(set) var lastBackgroundDate: Date?

    // --- Persistent timer state for background/kill recovery ---
    private enum TimerPersistKeys {
        static let remainingSeconds = "remainingSeconds"
        static let isRunning = "isRunning"
        static let backgroundTimestamp = "backgroundTimestamp"
        static let isWorkSession = "isWorkSession"
        static let endAtTimestamp = "endAtTimestamp" // legacy
        static let runState = "timerRunState"
        static let endAtEpoch = "timerEndAtEpoch"
        static let remainingAtPause = "timerRemainingAtPause"
    }

    @AppStorage(TimerPersistKeys.remainingSeconds) private var storedRemainingSeconds: Int = 0
    @AppStorage(TimerPersistKeys.isRunning) private var storedIsRunning: Bool = false
    @AppStorage(TimerPersistKeys.backgroundTimestamp) private var storedBackgroundTimestamp: Double = 0
    @AppStorage(TimerPersistKeys.isWorkSession) private var storedIsWorkSession: Bool = true
    // Legacy absolute timestamp (kept for backward compatibility)
    @AppStorage(TimerPersistKeys.endAtTimestamp) private var storedEndAtTimestamp: Double = 0
    // New fields
    @AppStorage(TimerPersistKeys.runState) private var storedRunState: String = ""
    @AppStorage(TimerPersistKeys.endAtEpoch) private var storedEndAtEpoch: Double = 0
    @AppStorage(TimerPersistKeys.remainingAtPause) private var storedRemainingAtPause: Int = 0

    // MARK: - Protocol bridging properties
    var runStateRaw: String? {
        get { storedRunState.isEmpty ? nil : storedRunState }
        set { storedRunState = newValue ?? "" }
    }
    var endAtEpoch: Double? {
        get { storedEndAtEpoch > 0 ? storedEndAtEpoch : nil }
        set { storedEndAtEpoch = newValue ?? 0 }
    }
    var remainingAtPause: Int? {
        get { storedRemainingAtPause > 0 ? storedRemainingAtPause : nil }
        set { storedRemainingAtPause = newValue ?? 0 }
    }

    init() {
        // アプリ起動時は0で開始（initializeWithWorkMinutesで正しい時間が設定される）
        self.timeRemaining = 0
        self.isRunning = false
        self.isWorkSession = true

        // 古い永続化データをクリア（アプリ起動時は常にリセット）
        clearPersistedState()
    }

    /// 設定済みの作業時間で初期化
    func initializeWithWorkMinutes(_ minutes: Int) {
        self.timeRemaining = minutes * 60
        self.isRunning = false
        self.isWorkSession = true
        clearPersistedState()
    }

    /// 永続化された状態をクリア
    private func clearPersistedState() {
        storedRemainingSeconds = 0
        storedIsRunning = false
        storedIsWorkSession = true
        storedBackgroundTimestamp = 0
        storedEndAtTimestamp = 0
        storedRunState = ""
        storedEndAtEpoch = 0
        storedRemainingAtPause = 0
    }

    func saveTimerState() {
        storedRemainingSeconds = timeRemaining
        storedIsRunning = isRunning
        storedIsWorkSession = isWorkSession
        storedBackgroundTimestamp = Date().timeIntervalSince1970
        // Note: runState/endAtEpoch/remainingAtPause are written by caller via protocol properties
    }

    func restoreTimerState() {
        isWorkSession = storedIsWorkSession
        // Primary: use new fields if present
        if !storedRunState.isEmpty {
            // Derive isRunning from runState
            isRunning = storedRunState == "running"
            if storedRunState == "running", storedEndAtEpoch > 0 {
                let nowTs = Date().timeIntervalSince1970
                let remain = Int(floor(max(0, storedEndAtEpoch - nowTs)))
                timeRemaining = remain
            } else if storedRunState == "paused" {
                timeRemaining = max(0, storedRemainingAtPause)
                isRunning = false
            } else {
                timeRemaining = max(0, storedRemainingSeconds)
                isRunning = false
            }
            return
        }
        // Fallback: legacy behavior (pre-runState)
        if storedIsRunning && storedEndAtTimestamp > 0 {
            let nowTs = Date().timeIntervalSince1970
            let remain = Int(floor(max(0, storedEndAtTimestamp - nowTs)))
            timeRemaining = remain
            isRunning = remain > 0
        } else {
            timeRemaining = max(0, storedRemainingSeconds)
            isRunning = false
        }
    }

    // MARK: - Background Handling

    /// バックグラウンドへ
    func appDidEnterBackground() { /* Responsibility moved to ViewModel */ }

    /// フォアグラウンド復帰
    @MainActor
    func appWillEnterForeground() { /* Responsibility moved to ViewModel */ }
}
