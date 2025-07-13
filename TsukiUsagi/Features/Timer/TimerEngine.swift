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

    func start(seconds: Int) {
        print("TimerEngine: start called with \(seconds) seconds")
        stop()
        timeRemaining = seconds
        isRunning = true
        sessionStartTime = Date()
        actualWorkedSeconds = 0
        lastResumedTime = Date()

        timerTask?.cancel()
        timerTask = Task { @MainActor in
            while timeRemaining > 0 && !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒

                if Task.isCancelled { break }

                timeRemaining -= 1
                onTick?(timeRemaining)

                if timeRemaining <= 0 {
                    isRunning = false
                    onSessionCompleted?(TimerSessionInfo(
                        startTime: sessionStartTime ?? Date(),
                        endTime: Date(),
                        phase: isWorkSession ? .focus : .breakTime,
                        actualWorkedSeconds: actualWorkedSeconds
                    ))
                    break
                }
            }
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

#if targetEnvironment(simulator)
/// Simulator用のモックTimerEngine
/// SimulatorではTask.sleepが正しく動作しない場合があるため、DispatchQueue.main.asyncAfterを使用
final class MockTimerEngine: TimerEngineable {
    private(set) var timeRemaining: Int = 0
    private(set) var isRunning: Bool = false
    private var sessionStartTime: Date?
    private var actualWorkedSeconds: Int = 0
    private var isWorkSession: Bool = true
    private var timer: Timer?

    var onTick: ((Int) -> Void)?
    var onSessionCompleted: ((TimerSessionInfo) -> Void)?

    func start(seconds: Int) {
        print("🔥 MockTimerEngine: start called with \(seconds) seconds")
        stop()
        timeRemaining = seconds
        isRunning = true
        print("🔥 MockTimerEngine: isRunning set to \(isRunning)")
        sessionStartTime = Date()
        actualWorkedSeconds = 0

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] t in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                    print("🔥 MockTimerEngine tick: \(self.timeRemaining)")
                    self.onTick?(self.timeRemaining)
                    if self.timeRemaining <= 0 {
                        t.invalidate()
                        self.isRunning = false
                        print("🔥 MockTimerEngine: session completed")
                        self.onSessionCompleted?(TimerSessionInfo(
                            startTime: self.sessionStartTime ?? Date(),
                            endTime: Date(),
                            phase: self.isWorkSession ? .focus : .breakTime,
                            actualWorkedSeconds: seconds
                        ))
                    }
                }
            }
        }
    }

    func pause() {
        print("🔥 MockTimerEngine: pause called")
        timer?.invalidate()
        isRunning = false
    }

    func resume() {
        print("🔥 MockTimerEngine: resume called")
        guard !isRunning, timeRemaining > 0 else { return }
        isRunning = true
        start(seconds: timeRemaining)
    }

    func stop() {
        print("🔥 MockTimerEngine: stop called")
        timer?.invalidate()
        isRunning = false
        timeRemaining = 0
    }

    func reset(to seconds: Int) {
        print("🔥 MockTimerEngine: reset called with \(seconds) seconds")
        stop()
        timeRemaining = seconds
        onTick?(timeRemaining)
    }
}
#endif
