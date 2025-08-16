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
    let dateProvider: DateProviding

    init() {
        // --- Services ---
        self.timerEngine = TimerEngine()
        self.hapticService = HapticService()
        self.formatter = TimeFormatterUtil()
        self.notificationService = PhaseNotificationService(hapticService: hapticService)
        // ViewModels を先に初期化できないため、ダミーで初期化して後で差し替えるように見えるが
        // この順序だと循環するため、まず先に HistoryViewModel を作ってから Service を作る
        // → 下のViewModels初期化順序を入れ替える
        self.persistenceManager = TimerPersistenceManager()
        self.dateProvider = SystemDateProvider()

        // --- ViewModels ---
        self.historyVM = HistoryViewModel()
        // --- Services that depend on ViewModels ---
        self.historyService = SessionHistoryService(formatter: formatter, historyVM: historyVM)

        self.timerVM = TimerViewModel(
            engine: timerEngine,
            notificationService: notificationService,
            hapticService: hapticService,
            historyService: historyService,
            persistenceManager: persistenceManager,
            formatter: formatter,
            streakManager: StreakManager(),
            dateProvider: dateProvider
        )
        self.sessionManager = SessionManager()
    }
}
