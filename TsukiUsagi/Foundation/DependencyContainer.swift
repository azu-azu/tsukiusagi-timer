import Foundation

@MainActor
final class DependencyContainer {
    // Services
    let timerEngine: TimerEngineable
    let hapticService: HapticService
    let notificationService: PhaseNotificationServiceable
    let formatter: TimeFormatterUtil
    let historyService: SessionHistoryServiceable
    let persistenceManager: TimerPersistenceManager

    // ViewModels
    let historyVM: HistoryViewModel
    let timerVM: TimerViewModel
    let sessionManager: SessionManager

    init() {
        // --- Services ---
        self.timerEngine = TimerEngine()
        self.hapticService = HapticService()
        self.formatter = TimeFormatterUtil()
        self.notificationService = PhaseNotificationService(hapticService: hapticService)
        self.historyService = SessionHistoryService(formatter: formatter)
        self.persistenceManager = TimerPersistenceManager()

        // --- ViewModels ---
        self.historyVM = HistoryViewModel()
        self.timerVM = TimerViewModel(
            engine: timerEngine,
            notificationService: notificationService,
            hapticService: hapticService,
            historyService: historyService,
            persistenceManager: persistenceManager,
            formatter: formatter
        )
        self.sessionManager = SessionManager()
    }
}
