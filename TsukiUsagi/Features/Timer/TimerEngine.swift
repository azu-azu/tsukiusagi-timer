import Foundation

/// タイマー制御の責務のみを持つプロトコル
protocol TimerEngineable: AnyObject {
    var timeRemaining: Int { get }
    var isRunning: Bool { get }
    var onTick: ((Int) -> Void)? { get set }
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
    var onTick: ((Int) -> Void)?

    func start(seconds: Int) async {
        stop()
        timeRemaining = seconds
        isRunning = true
        timerTask = Task {
            while !Task.isCancelled && timeRemaining > 0 && isRunning {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard isRunning else { break }
                timeRemaining -= 1
                onTick?(timeRemaining)
            }
            isRunning = false
        }
    }

    func pause() {
        isRunning = false
        timerTask?.cancel()
        timerTask = nil
    }

    func resume() {
        guard !isRunning, timeRemaining > 0 else { return }
        isRunning = true
        timerTask = Task {
            while !Task.isCancelled && timeRemaining > 0 && isRunning {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard isRunning else { break }
                timeRemaining -= 1
                onTick?(timeRemaining)
            }
            isRunning = false
        }
    }

    func stop() {
        isRunning = false
        timerTask?.cancel()
        timerTask = nil
    }

    func reset(to seconds: Int) {
        stop()
        timeRemaining = seconds
        onTick?(timeRemaining)
    }
}
