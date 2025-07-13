import Foundation

/// セッション情報を表す構造体
enum TimerSessionPhase {
    case focus
    case breakTime
}

struct TimerSessionInfo {
    let startTime: Date
    let endTime: Date
    let phase: TimerSessionPhase
    let actualWorkedSeconds: Int
}

/// タイマー制御の責務のみを持つプロトコル
protocol TimerEngineable: AnyObject {
    var timeRemaining: Int { get }
    var isRunning: Bool { get }
    var onTick: ((Int) -> Void)? { get set }
    var onSessionCompleted: ((TimerSessionInfo) -> Void)? { get set }
    func start(seconds: Int) async
    func pause()
    func resume()
    func stop()
    func reset(to seconds: Int)
}

/// 純粋なタイマー制御ロジックのみを担当するクラス
final class TimerEngine: TimerEngineable {
    private(set) var timeRemaining: Int = 0
    private(set) var isRunning: Bool = false
    private var timerTask: Task<Void, Never>?
    private var pausedAt: Date?
    private var lastTickDate: Date?
    private var sessionStartTime: Date?
    private var actualWorkedSeconds: Int = 0
    private var lastResumedTime: Date?
    private var isWorkSession: Bool = true

    var onTick: ((Int) -> Void)?
    var onSessionCompleted: ((TimerSessionInfo) -> Void)?

    func start(seconds: Int) async {
        stop()
        timeRemaining = seconds
        isRunning = true
        sessionStartTime = Date()
        actualWorkedSeconds = 0
        lastResumedTime = Date()

        timerTask = Task {
            while !Task.isCancelled && timeRemaining > 0 && isRunning {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard isRunning else { break }
                timeRemaining -= 1
                onTick?(timeRemaining)
            }

            if timeRemaining <= 0 {
                await handleSessionCompleted()
            }
            isRunning = false
        }
    }

    func pause() {
        isRunning = false
        timerTask?.cancel()
        timerTask = nil

        // 実作業時間を更新
        if let resumedAt = lastResumedTime {
            actualWorkedSeconds += Int(Date().timeIntervalSince(resumedAt))
            lastResumedTime = nil
        }
    }

    func resume() {
        guard !isRunning, timeRemaining > 0 else { return }
        isRunning = true
        lastResumedTime = Date()

        timerTask = Task {
            while !Task.isCancelled && timeRemaining > 0 && isRunning {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard isRunning else { break }
                timeRemaining -= 1
                onTick?(timeRemaining)
            }

            if timeRemaining <= 0 {
                await handleSessionCompleted()
            }
            isRunning = false
        }
    }

    func stop() {
        isRunning = false
        timerTask?.cancel()
        timerTask = nil

        // 実作業時間を更新
        if let resumedAt = lastResumedTime {
            actualWorkedSeconds += Int(Date().timeIntervalSince(resumedAt))
            lastResumedTime = nil
        }
    }

    func reset(to seconds: Int) {
        stop()
        timeRemaining = seconds
        sessionStartTime = Date()
        actualWorkedSeconds = 0
        lastResumedTime = Date()
        onTick?(timeRemaining)
    }

    // MARK: - Private Methods

    @MainActor
    private func handleSessionCompleted() async {
        let endTime = Date()

        // 最後のPause漏れ対策
        if let resumedAt = lastResumedTime {
            actualWorkedSeconds += Int(endTime.timeIntervalSince(resumedAt))
            lastResumedTime = nil
        }

        guard let startTime = sessionStartTime else { return }

        let sessionInfo = TimerSessionInfo(
            startTime: startTime,
            endTime: endTime,
            phase: isWorkSession ? .focus : .breakTime,
            actualWorkedSeconds: actualWorkedSeconds
        )

        onSessionCompleted?(sessionInfo)
    }
}
