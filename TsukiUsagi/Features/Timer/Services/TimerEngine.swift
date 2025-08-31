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
@MainActor
protocol TimerEngineable: AnyObject {
    var timeRemaining: Int { get }
    var isRunning: Bool { get }
    var onTick: ((Int) -> Void)? { get set }
    var onSessionCompleted: ((TimerSessionInfo) -> Void)? { get set }
    func start(seconds: Int)
    func pause()
    func resume()
    func stop()
    func reset(to seconds: Int)
}

/// 純粋なタイマー制御ロジックのみを担当するクラス
@MainActor
final class TimerEngine: TimerEngineable {
    private(set) var timeRemaining: Int = 0
    private(set) var isRunning: Bool = false
    private var timer: Timer?
    private var sessionStartTime: Date?
    private var actualWorkedSeconds: Int = 0
    private var lastResumedTime: Date?
    private var isWorkSession: Bool = true

    // Drift-free countdown support
    private var endAt: Date?
    private var pausedRemaining: Int?

    var onTick: ((Int) -> Void)?
    var onSessionCompleted: ((TimerSessionInfo) -> Void)?

    func start(seconds: Int) {
        stop()
        guard seconds > 0 else { return }
        isRunning = true
        sessionStartTime = Date()
        actualWorkedSeconds = 0
        lastResumedTime = Date()
        pausedRemaining = nil
        endAt = Date().addingTimeInterval(TimeInterval(seconds))

        scheduleTimer()
        tick() // reflect immediately
    }

    private func tick() {
        guard isRunning, let endAt else { return }
        let remain = max(0, Int(endAt.timeIntervalSinceNow.rounded()))
        if remain != timeRemaining {
            timeRemaining = remain
            onTick?(timeRemaining)
        }
        if remain <= 0 {
            handleSessionCompleted()
        }
    }

    func pause() {
        guard isRunning else { return }
        // fix remaining before pausing
        tick()
        pausedRemaining = timeRemaining
        isRunning = false
        timer?.invalidate()
        timer = nil
        if let resumedAt = lastResumedTime {
            actualWorkedSeconds += Int(Date().timeIntervalSince(resumedAt))
            lastResumedTime = nil
        }
    }

    func resume() {
        guard !isRunning else { return }
        let remain = pausedRemaining ?? timeRemaining
        guard remain > 0 else { return }
        isRunning = true
        lastResumedTime = Date()
        endAt = Date().addingTimeInterval(TimeInterval(remain))
        pausedRemaining = nil
        scheduleTimer()
        tick()
    }

    func stop() {
        isRunning = false
        timer?.invalidate()
        timer = nil
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
        endAt = Date().addingTimeInterval(TimeInterval(seconds))
        onTick?(timeRemaining)
    }

    private func handleSessionCompleted() {
        stop()
        let endTime = Date()
        if let resumedAt = lastResumedTime {
            actualWorkedSeconds += Int(endTime.timeIntervalSince(resumedAt))
            lastResumedTime = nil
        }
        guard let startTime = sessionStartTime else {
            return
        }
        let sessionInfo = TimerSessionInfo(
            startTime: startTime,
            endTime: endTime,
            phase: isWorkSession ? .focus : .breakTime,
            actualWorkedSeconds: actualWorkedSeconds
        )
        onSessionCompleted?(sessionInfo)
    }

    // MARK: - Helpers
    private func scheduleTimer() {
        timer?.invalidate()
        let t = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }
}
