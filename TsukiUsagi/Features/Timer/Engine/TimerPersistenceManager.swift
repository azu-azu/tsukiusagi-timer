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
    }

    @AppStorage(TimerPersistKeys.remainingSeconds) private var storedRemainingSeconds: Int = 0
    @AppStorage(TimerPersistKeys.isRunning) private var storedIsRunning: Bool = false
    @AppStorage(TimerPersistKeys.backgroundTimestamp) private var storedBackgroundTimestamp: Double = 0
    @AppStorage(TimerPersistKeys.isWorkSession) private var storedIsWorkSession: Bool = true

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
    }

    func restoreTimerState() {
        timeRemaining = storedRemainingSeconds
        isRunning = storedIsRunning
        isWorkSession = storedIsWorkSession
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
