#if DEBUG
import Foundation

@MainActor
final class MockTimerEngine: TimerEngineable {
    var timeRemaining: Int = 0
    var isRunning: Bool = false
    var onTick: ((Int) -> Void)?
    var onSessionCompleted: ((TimerSessionInfo) -> Void)?
    func start(seconds: Int) {
        isRunning = true
        timeRemaining = seconds
        // 即時に数回のtickを発行
        onTick?(seconds - 1)
        onTick?(seconds - 2)
        onTick?(seconds - 3)
    }
    func pause() { isRunning = false }
    func resume() { isRunning = true }
    func stop() { isRunning = false }
    func reset(to seconds: Int) { timeRemaining = seconds; onTick?(seconds) }
}

@MainActor
final class MockDependencyContainer {
    // Services (必要に応じて他もモック化)
    let timerEngine: TimerEngineable = MockTimerEngine()
    let hapticService = HapticService()
    let formatter = TimeFormatterUtil()
    let notificationService: PhaseNotificationServiceable
    let historyService: SessionHistoryServiceable
    let persistenceManager = TimerPersistenceManager()
    let dateProvider: DateProviding

    // ViewModels
    let historyVM = HistoryViewModel()
    let timerVM: TimerViewModel
    let sessionManager = SessionManager()

    init(dateProvider: DateProviding = SystemDateProvider()) {
        self.dateProvider = dateProvider
        self.notificationService = PhaseNotificationService(hapticService: hapticService)
        self.historyService = SessionHistoryService(formatter: formatter, historyVM: historyVM)
        self.timerVM = TimerViewModel(
            engine: timerEngine,
            notificationService: notificationService,
            hapticService: hapticService,
            historyService: historyService,
            persistenceManager: persistenceManager,
            formatter: formatter,
            dateProvider: dateProvider
        )
    }
}

#if DEBUG
struct FixedDateProvider: DateProviding { let fixed: Date; func now() -> Date { fixed } }
#endif
#endif
