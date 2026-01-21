import Foundation

@MainActor
final class DependencyContainer {
    // Services
    let timerEngine: TimerEngineable
    let hapticService: HapticService
    let notificationService: PhaseNotificationServiceable
    let formatter: TimeFormatterUtil
    let persistenceManager: TimerPersistenceManager

    // ViewModels
    let historyVM: HistoryViewModel
    let timerVM: TimerViewModel
    let sessionManager: SessionManager
    let dateProvider: DateProviding

    init() {
        // --- Services ---
        self.timerEngine = TimerEngine()
        self.hapticService = HapticService()
        self.formatter = TimeFormatterUtil()
        self.notificationService = PhaseNotificationService(hapticService: hapticService)
        self.persistenceManager = TimerPersistenceManager()
        self.dateProvider = SystemDateProvider()

        // --- ViewModels ---
        // HistoryViewModel conforms to SessionHistoryServiceable directly
        // No reverse dependency: TimerVM → HistoryVM (correct direction)
        self.historyVM = HistoryViewModel()

        self.timerVM = TimerViewModel(
            engine: timerEngine,
            notificationService: notificationService,
            hapticService: hapticService,
            historyService: historyVM,  // HistoryViewModel as SessionHistoryServiceable
            persistenceManager: persistenceManager,
            formatter: formatter,
            streakManager: StreakManager(),
            dateProvider: dateProvider
        )
        self.sessionManager = SessionManager()
    }
}
