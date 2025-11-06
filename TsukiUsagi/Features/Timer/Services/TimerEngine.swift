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
    // 復帰時の静かな完了かどうか（デフォルトはfalse）
    let isSilent: Bool
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

    // 初回減算ゲート（単調時計; uptime秒）
    private var displayGateUptime: TimeInterval?
    private var tickEpoch: UInt64 = 0

    var onTick: ((Int) -> Void)?
    var onSessionCompleted: ((TimerSessionInfo) -> Void)?

    func start(seconds: Int) {
        guard seconds > 0 else { return }
        stop()
        isRunning = true
        sessionStartTime = Date()
        actualWorkedSeconds = 0
        lastResumedTime = Date()
        pausedRemaining = nil

        // 秒境界にアラインして endAt を設定
        let now = Date()
        let alignedStart = Date(timeIntervalSince1970: ceil(now.timeIntervalSince1970))
        endAt = alignedStart.addingTimeInterval(TimeInterval(seconds))
        timeRemaining = seconds // 正しい残り時間を設定

        // 初回減算の猶予（必ず1秒見せる）※単調時計で管理
        // onTick?(seconds)を呼ぶ前に設定して、その後のtick()呼び出しを確実にブロック
        let currentUptime = ProcessInfo.processInfo.systemUptime
        displayGateUptime = currentUptime + 1.0

        // 初回発火を次の整数秒+1秒後に設定
        let firstFireAt = alignedStart.addingTimeInterval(1.0)
        scheduleTimer(firstFireAt: firstFireAt)

        // 初期値（設定値）をそのまま表示するため、tick()は呼ばずにonTickのみ呼び出す
        // displayGateUptimeが設定されているので、この直後にtick()が呼ばれてもブロックされる
        // 1秒後のタイマー更新から実際の残り時間が計算される
        onTick?(seconds)
    }

    private func tick() {
        guard isRunning, let endAt else { return }

        // 表示ゲート：onTick直後は最低1秒は絶対に減らさない（単調時計）
        // systemUptimeがgateに到達するまでは何も更新しない
        if let gate = displayGateUptime {
            let currentUptime = ProcessInfo.processInfo.systemUptime
            if currentUptime < gate {
                // まだ1秒経過していないので、何も更新しない
                return
            }
            // 1秒経過したので、ゲートを解除
            displayGateUptime = nil
        }

        // 遅延tickでも "2秒飛び" にならないように ceil にする
        // わずかな遅延でも次の整数秒までは現在の残り秒を保つ
        let remain = max(0, Int(ceil(endAt.timeIntervalSinceNow)))
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

        // 秒境界にアラインして endAt を設定
        let now = Date()
        let alignedStart = Date(timeIntervalSince1970: ceil(now.timeIntervalSince1970))
        endAt = alignedStart.addingTimeInterval(TimeInterval(remain))
        timeRemaining = remain // 正しい残り時間を設定
        pausedRemaining = nil

        // 再開時も初回減算は1秒後から（単調時計）
        // onTick?(remain)を呼ぶ前に設定して、その後のtick()呼び出しを確実にブロック
        let currentUptime = ProcessInfo.processInfo.systemUptime
        displayGateUptime = currentUptime + 1.0

        // 初回発火を次の整数秒+1秒後に設定
        let firstFireAt = alignedStart.addingTimeInterval(1.0)
        scheduleTimer(firstFireAt: firstFireAt)
        // 初期値（設定値）をそのまま表示するため、tick()は呼ばずにonTickのみ呼び出す
        // displayGateUptimeが設定されているので、この直後にtick()が呼ばれてもブロックされる
        // 1秒後のタイマー更新から実際の残り時間が計算される
        onTick?(remain)
    }

    func stop() {
        // タイマーは常に無効化（実行中/停止中に関わらず）
        timer?.invalidate()
        timer = nil

        if isRunning, let resumedAt = lastResumedTime {
            actualWorkedSeconds += Int(Date().timeIntervalSince(resumedAt))
        }
        isRunning = false
        lastResumedTime = nil
        endAt = nil
        pausedRemaining = nil

        // 世代更新で古いtickを無視
        tickEpoch &+= 1
        // 初回減算猶予クリア
        displayGateUptime = nil
    }

    func reset(to seconds: Int) {
        stop()
        timeRemaining = seconds
        sessionStartTime = Date()
        actualWorkedSeconds = 0
        lastResumedTime = Date()

        // 秒境界にアラインして endAt を設定
        let now = Date()
        let alignedStart = Date(timeIntervalSince1970: ceil(now.timeIntervalSince1970))
        endAt = alignedStart.addingTimeInterval(TimeInterval(seconds))

        // リセット直後も1秒はそのまま見せる（単調時計）
        displayGateUptime = ProcessInfo.processInfo.systemUptime + 1.0

        // 初期値はそのまま見せる（1秒後から更新）
        onTick?(seconds)
    }

    private func handleSessionCompleted() {
        stop()
        let endTime = Date()
        guard let startTime = sessionStartTime else {
            return
        }
        let sessionInfo = TimerSessionInfo(
            startTime: startTime,
            endTime: endTime,
            phase: isWorkSession ? .focus : .breakTime,
            actualWorkedSeconds: actualWorkedSeconds,
            isSilent: false
        )
        onSessionCompleted?(sessionInfo)
    }

    // MARK: - Helpers
    private func scheduleTimer(firstFireAt: Date? = nil) {
        // 新世代に更新
        tickEpoch &+= 1
        let myEpoch = tickEpoch

        timer?.invalidate()

        guard let firstFireAt = firstFireAt else {
            // 通常の1秒間隔タイマー
            scheduleRepeatingTimer(epoch: myEpoch)
            return
        }

        // 初回発火時刻を指定して、初回発火後に通常の1秒間隔タイマーに切り替え
        let now = Date()
        var delay = max(0.0, firstFireAt.timeIntervalSince(now))

        // delayが0に近い場合（即時発火を避けるため）、最小1.0秒を確保
        // displayGateUptimeの設定（uptime + 1.0秒）より前に発火しないようにする
        if delay < 1.0 {
            delay = 1.0
        }

        // 初回発火用のタイマー（一度だけ）
        let firstTimer = Timer(timeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.tickEpoch == myEpoch else { return }
                self.tick()
                // 以降 1秒間隔
                self.scheduleRepeatingTimer(epoch: myEpoch)
            }
        }
        firstTimer.tolerance = 0.05
        RunLoop.main.add(firstTimer, forMode: .common)
        timer = firstTimer
    }

    private func scheduleRepeatingTimer(epoch myEpoch: UInt64) {
        let t = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.tickEpoch == myEpoch else { return }
                self.tick()
            }
        }
        t.tolerance = 0.05
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }
}
