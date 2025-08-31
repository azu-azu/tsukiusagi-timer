import Foundation
import SwiftUI

protocol TimerPersistenceManageable: AnyObject {
    var timeRemaining: Int { get set }
    var isRunning: Bool { get set }
    var isWorkSession: Bool { get set }
    func saveTimerState()
    func restoreTimerState()
}

/// バックグラウンド対応と状態永続化を担当するManager
final class TimerPersistenceManager: ObservableObject, TimerPersistenceManageable {
    @Published var timeRemaining: Int
    @Published var isRunning: Bool = false
    @Published var isWorkSession: Bool = true
    @Published private(set) var lastBackgroundDate: Date?

    private var wasRunningBeforeBackground = false
    private var savedRemainingSeconds: Int?

    // --- Persistent timer state for background/kill recovery ---
    private enum TimerPersistKeys {
        static let remainingSeconds = "remainingSeconds"
        static let isRunning = "isRunning"
        static let backgroundTimestamp = "backgroundTimestamp"
        static let isWorkSession = "isWorkSession"
        static let endAtTimestamp = "endAtTimestamp"
    }

    @AppStorage(TimerPersistKeys.remainingSeconds) private var storedRemainingSeconds: Int = 0
    @AppStorage(TimerPersistKeys.isRunning) private var storedIsRunning: Bool = false
    @AppStorage(TimerPersistKeys.backgroundTimestamp) private var storedBackgroundTimestamp: Double = 0
    @AppStorage(TimerPersistKeys.isWorkSession) private var storedIsWorkSession: Bool = true
    @AppStorage(TimerPersistKeys.endAtTimestamp) private var storedEndAtTimestamp: Double = 0

    init() {
        self.timeRemaining = 0
        self.isRunning = storedIsRunning
        self.isWorkSession = storedIsWorkSession

        // 初期化後に永続化された値を復元
        self.timeRemaining = storedRemainingSeconds
    }

    func saveTimerState() {
        storedRemainingSeconds = timeRemaining
        storedIsRunning = isRunning
        storedIsWorkSession = isWorkSession
        storedBackgroundTimestamp = Date().timeIntervalSince1970
        // Persist absolute end time for robust restoration across app restarts
        if isRunning && timeRemaining > 0 {
            storedEndAtTimestamp = Date().timeIntervalSince1970 + Double(timeRemaining)
        } else {
            storedEndAtTimestamp = 0
        }
    }

    func restoreTimerState() {
        isWorkSession = storedIsWorkSession
        // If we have an absolute end timestamp and the timer was running,
        // recompute the remaining seconds based on current time.
        if storedIsRunning && storedEndAtTimestamp > 0 {
            let nowTs = Date().timeIntervalSince1970
            let remain = Int(ceil(max(0, storedEndAtTimestamp - nowTs)))
            timeRemaining = remain
            isRunning = remain > 0
        } else {
            // Fallback to the stored remaining seconds (paused or stopped state)
            timeRemaining = max(0, storedRemainingSeconds)
            isRunning = false
        }
    }

    // MARK: - Background Handling

    /// バックグラウンドへ
    func appDidEnterBackground() {
        wasRunningBeforeBackground = isRunning
        lastBackgroundDate = Date()
        savedRemainingSeconds = timeRemaining
        if isRunning {
            NotificationManager.shared.scheduleSessionEndNotification(
                after: timeRemaining,
                phase: isWorkSession ? .focus : .breakTime
            )
        }
    }

    /// フォアグラウンド復帰
    @MainActor
    func appWillEnterForeground() {
        guard let last = lastBackgroundDate,
            wasRunningBeforeBackground else { return }

        let elapsed = Int(Date().timeIntervalSince(last))
        NotificationManager.shared.cancelSessionEndNotification()
        let originalRemaining = savedRemainingSeconds ?? timeRemaining
        timeRemaining = max(originalRemaining - elapsed, 0)

        if timeRemaining <= 0 {
            // 0になった時刻を計算
            _ = last.addingTimeInterval(TimeInterval(originalRemaining))
            // セッション完了処理は呼び出し側で行う
        } else {
            // 再開処理は呼び出し側で行う
        }
        lastBackgroundDate = nil
        wasRunningBeforeBackground = false
        savedRemainingSeconds = nil
    }
}
